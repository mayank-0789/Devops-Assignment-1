"""Each test uses a fresh database; migrations are exercised in PostgreSQL CI."""
import os
from pathlib import Path
import tempfile

_test_dir = tempfile.TemporaryDirectory(prefix="stockroom-tests-")
os.environ["DATABASE_URL"] = f"sqlite:///{Path(_test_dir.name) / 'test.sqlite3'}"
import pytest
from fastapi.testclient import TestClient
from app.db import Base, engine
from app.main import app


@pytest.fixture(autouse=True)
def fresh_tables():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)
    app.dependency_overrides.clear()


@pytest.fixture
def client():
    with TestClient(app) as client:
        yield client


@pytest.fixture
def sample():
    return {"sku": "KB-101", "name": "Mechanical keyboard", "category": "Peripherals", "unit_price_cents": 450000, "reorder_level": 5}
