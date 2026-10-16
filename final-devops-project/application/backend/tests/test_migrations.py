import os
from pathlib import Path
import sqlite3
import subprocess
import sys


def test_migration_chain_preserves_legacy_schema(tmp_path):
    database = tmp_path / "migration.sqlite3"
    env = {**os.environ, "DATABASE_URL": f"sqlite:///{database}"}
    backend = Path(__file__).resolve().parents[1]
    subprocess.run([sys.executable, "-m", "alembic", "upgrade", "head"], cwd=backend, env=env, check=True, capture_output=True)
    with sqlite3.connect(database) as conn:
        tables = {row[0] for row in conn.execute("SELECT name FROM sqlite_master WHERE type='table'")}
        assert {"products", "movements", "tickets"} <= tables
        assert conn.execute("SELECT version_num FROM alembic_version").fetchone()[0] == "0002_inventory"
