"""Original inventory API: stock changes and their audit entries commit together."""
from fastapi import Depends, FastAPI, HTTPException, Query, Response
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from sqlalchemy import case, func, select, text, update
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session
from app.config import settings
from app.db import get_db
from app.models import Movement, Product
from app.schemas import MovementCreate, MovementOut, ProductCreate, ProductOut, ProductUpdate, Stats

app = FastAPI(title="Stockroom API", version="1.0.0", description="Products, stock movements and low-stock visibility.")
app.add_middleware(CORSMiddleware, allow_origins=settings.cors_origins.split(","), allow_methods=["GET", "POST", "PUT", "DELETE"], allow_headers=["Content-Type"])
Instrumentator(excluded_handlers=["/metrics", "/health", "/ready"]).instrument(app).expose(app, include_in_schema=False)


@app.get("/")
def root():
    return {"app": settings.app_name, "env": settings.app_env, "docs": "/docs"}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.get("/ready")
def ready(response: Response, db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1 FROM products LIMIT 1"))
    except SQLAlchemyError:
        response.status_code = 503
        return {"status": "not ready"}
    return {"status": "ready", "database": "ok"}


@app.get("/api/products", response_model=list[ProductOut])
def list_products(q: str = Query(default="", max_length=160), low_stock: bool = False, db: Session = Depends(get_db)):
    stmt = select(Product).where(Product.archived.is_(False))
    if q:
        stmt = stmt.where(Product.name.icontains(q, autoescape=True) | Product.sku.icontains(q, autoescape=True))
    if low_stock:
        stmt = stmt.where(Product.quantity <= Product.reorder_level)
    return db.scalars(stmt.order_by(Product.id.desc())).all()


@app.get("/api/products/stats", response_model=Stats)
def stats(db: Session = Depends(get_db)):
    row = db.execute(select(
        func.count(Product.id), func.coalesce(func.sum(Product.quantity), 0),
        func.coalesce(func.sum(case((Product.quantity <= Product.reorder_level, 1), else_=0)), 0),
        func.coalesce(func.sum(case((Product.quantity == 0, 1), else_=0)), 0),
        func.coalesce(func.sum(Product.quantity * Product.unit_price_cents), 0),
    ).where(Product.archived.is_(False))).one()
    return Stats(products=row[0], units=row[1], low_stock=row[2], out_of_stock=row[3], inventory_value_cents=row[4])


def active_product(db, product_id):
    product = db.scalar(select(Product).where(Product.id == product_id, Product.archived.is_(False)))
    if product is None:
        raise HTTPException(404, "Product not found")
    return product


@app.get("/api/products/{product_id}", response_model=ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)):
    return active_product(db, product_id)


@app.post("/api/products", response_model=ProductOut, status_code=201)
def create_product(payload: ProductCreate, db: Session = Depends(get_db)):
    product = Product(**payload.model_dump())
    db.add(product)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "SKU already exists, including archived products") from None
    db.refresh(product)
    return product


@app.put("/api/products/{product_id}", response_model=ProductOut)
def update_product(product_id: int, payload: ProductUpdate, db: Session = Depends(get_db)):
    product = active_product(db, product_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(product, field, value)
    db.commit()
    db.refresh(product)
    return product


@app.delete("/api/products/{product_id}", status_code=204)
def archive_product(product_id: int, db: Session = Depends(get_db)):
    active_product(db, product_id)
    # Conditional UPDATE also serializes with stock movements; a read/check/write would race.
    result = db.execute(update(Product).where(Product.id == product_id, Product.archived.is_(False), Product.quantity == 0).values(archived=True))
    if result.rowcount != 1:
        raise HTTPException(409, "Only products with zero stock can be archived")
    db.commit()
    return Response(status_code=204)


@app.get("/api/movements", response_model=list[MovementOut])
def list_movements(limit: int = Query(default=50, ge=1, le=200), db: Session = Depends(get_db)):
    return db.scalars(select(Movement).order_by(Movement.id.desc()).limit(limit)).all()


@app.post("/api/movements", response_model=MovementOut, status_code=201)
def record_movement(payload: MovementCreate, db: Session = Depends(get_db)):
    active_product(db, payload.product_id)
    row = db.execute(update(Product).where(
        Product.id == payload.product_id, Product.archived.is_(False),
        Product.quantity + payload.delta >= 0, Product.quantity + payload.delta <= 1000000,
    ).values(quantity=Product.quantity + payload.delta).returning(Product.quantity, Product.sku, Product.name)).first()
    if row is None:
        raise HTTPException(409, "Insufficient stock, stock limit exceeded, or product archived")
    movement = Movement(**payload.model_dump(), quantity_after=row[0], sku=row[1], product_name=row[2])
    db.add(movement)
    db.commit()
    db.refresh(movement)
    return movement
