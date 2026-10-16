"""Create the original Stockroom inventory schema; retain legacy tickets on upgrades."""
from alembic import op
import sqlalchemy as sa
revision = "0002_inventory"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table("products",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("sku", sa.String(40), nullable=False),
        sa.Column("name", sa.String(160), nullable=False),
        sa.Column("category", sa.String(60), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("reorder_level", sa.Integer(), nullable=False),
        sa.Column("unit_price_cents", sa.Integer(), nullable=False),
        sa.Column("archived", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint("quantity >= 0", name="quantity_nonnegative"),
        sa.CheckConstraint("unit_price_cents >= 0", name="price_nonnegative"),
        sa.CheckConstraint("reorder_level >= 0", name="reorder_nonnegative"))
    op.create_index("ix_products_sku", "products", ["sku"], unique=True)
    op.create_table("movements",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("product_id", sa.Integer(), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("sku", sa.String(40), nullable=False),
        sa.Column("product_name", sa.String(160), nullable=False),
        sa.Column("delta", sa.Integer(), nullable=False),
        sa.Column("quantity_after", sa.Integer(), nullable=False),
        sa.Column("reason", sa.String(240), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False))
    op.create_index("ix_movements_product_id", "movements", ["product_id"])


def downgrade():
    op.drop_table("movements")
    op.drop_table("products")
