import pytest
from sqlalchemy.exc import OperationalError
from app.db import get_db
from app.main import app


def create(client, sample):
    response = client.post("/api/products", json=sample)
    assert response.status_code == 201
    return response.json()["id"]


def move(client, product_id, delta):
    return client.post("/api/movements", json={"product_id": product_id, "delta": delta, "reason": "Warehouse receipt"})


def test_health(client):
    assert client.get("/health").json() == {"status": "healthy"}


def test_readiness(client):
    assert client.get("/ready").status_code == 200


def test_unavailable_database_is_not_ready(client):
    class BrokenDB:
        def execute(self, query):
            raise OperationalError("query", {}, Exception("offline"))
    app.dependency_overrides[get_db] = lambda: BrokenDB()
    assert client.get("/ready").status_code == 503
    assert client.get("/health").status_code == 200


def test_create_and_read(client, sample):
    product_id = create(client, sample)
    product = client.get(f"/api/products/{product_id}").json()
    assert product["sku"] == sample["sku"]
    assert product["quantity"] == 0


def test_duplicate_sku(client, sample):
    create(client, sample)
    assert client.post("/api/products", json=sample).status_code == 409


@pytest.mark.parametrize("change", [{"sku": "bad sku"}, {"name": "  "}, {"unit_price_cents": -1}, {"reorder_level": 1.5}, {"quantity": 4}])
def test_invalid_product(client, sample, change):
    assert client.post("/api/products", json={**sample, **change}).status_code == 422


def test_partial_update(client, sample):
    product_id = create(client, sample)
    response = client.put(f"/api/products/{product_id}", json={"name": "Updated keyboard"})
    assert response.status_code == 200
    assert response.json()["sku"] == sample["sku"]


@pytest.mark.parametrize("change", [{"name": None}, {"quantity": 50}, {"unit_price_cents": -2}])
def test_invalid_update(client, sample, change):
    product_id = create(client, sample)
    assert client.put(f"/api/products/{product_id}", json=change).status_code == 422
    assert client.get(f"/api/products/{product_id}").json()["name"] == sample["name"]


def test_receipt_and_dispatch_have_audit_history(client, sample):
    product_id = create(client, sample)
    assert move(client, product_id, 10).json()["quantity_after"] == 10
    assert move(client, product_id, -3).json()["quantity_after"] == 7
    history = client.get("/api/movements").json()
    assert [m["delta"] for m in history] == [-3, 10]
    assert client.get(f"/api/products/{product_id}").json()["quantity"] == 7


def test_insufficient_stock_rolls_back(client, sample):
    product_id = create(client, sample)
    move(client, product_id, 2)
    assert move(client, product_id, -3).status_code == 409
    assert client.get(f"/api/products/{product_id}").json()["quantity"] == 2
    assert len(client.get("/api/movements").json()) == 1


@pytest.mark.parametrize("delta", [0, 1.5, True, 1000001])
def test_invalid_stock_movement(client, sample, delta):
    assert move(client, create(client, sample), delta).status_code == 422


def test_search_and_low_stock(client, sample):
    first = create(client, sample)
    second = create(client, {**sample, "sku": "MS-102", "name": "Wireless mouse"})
    move(client, second, 12)
    assert [p["id"] for p in client.get("/api/products?low_stock=true").json()] == [first]
    assert [p["id"] for p in client.get("/api/products?q=mouse").json()] == [second]
    assert client.get("/api/products?q=%25").json() == []


def test_stats_use_integer_money(client, sample):
    product_id = create(client, sample)
    move(client, product_id, 3)
    assert client.get("/api/products/stats").json() == {"products": 1, "units": 3, "low_stock": 1, "out_of_stock": 0, "inventory_value_cents": 1350000}


def test_archive_preserves_history(client, sample):
    product_id = create(client, sample)
    move(client, product_id, 3)
    assert client.delete(f"/api/products/{product_id}").status_code == 409
    move(client, product_id, -3)
    assert client.delete(f"/api/products/{product_id}").status_code == 204
    assert client.get(f"/api/products/{product_id}").status_code == 404
    assert client.get("/api/products").json() == []
    assert len(client.get("/api/movements").json()) == 2
    assert move(client, product_id, 2).status_code == 404


def test_missing_product(client):
    assert client.get("/api/products/999").status_code == 404
    assert client.delete("/api/products/999").status_code == 404


def test_metrics(client):
    client.get("/api/products")
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text
