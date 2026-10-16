from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field, model_validator


class ProductCreate(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")
    sku: str = Field(min_length=2, max_length=40, pattern=r"^[A-Z0-9][A-Z0-9_-]+$")
    name: str = Field(min_length=2, max_length=160)
    category: str = Field(default="General", min_length=1, max_length=60)
    reorder_level: int = Field(default=5, ge=0, le=1000000, strict=True)
    unit_price_cents: int = Field(default=0, ge=0, le=100000000, strict=True)


class ProductUpdate(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")
    name: str | None = Field(default=None, min_length=2, max_length=160)
    category: str | None = Field(default=None, min_length=1, max_length=60)
    reorder_level: int | None = Field(default=None, ge=0, le=1000000, strict=True)
    unit_price_cents: int | None = Field(default=None, ge=0, le=100000000, strict=True)

    @model_validator(mode="after")
    def reject_nulls(self):
        if any(getattr(self, field) is None for field in self.model_fields_set):
            raise ValueError("Provided fields cannot be null")
        return self


class ProductOut(ProductCreate):
    model_config = ConfigDict(from_attributes=True)
    id: int
    quantity: int
    created_at: datetime


class MovementCreate(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")
    product_id: int = Field(gt=0, strict=True)
    delta: int = Field(ge=-1000000, le=1000000, strict=True)
    reason: str = Field(min_length=3, max_length=240)

    @model_validator(mode="after")
    def nonzero_delta(self):
        if self.delta == 0:
            raise ValueError("Stock movement must change the quantity")
        return self


class MovementOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    product_id: int
    sku: str
    product_name: str
    delta: int
    quantity_after: int
    reason: str
    created_at: datetime


class Stats(BaseModel):
    products: int
    units: int
    low_stock: int
    out_of_stock: int
    inventory_value_cents: int
