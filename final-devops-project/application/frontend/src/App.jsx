import { useCallback, useEffect, useRef, useState } from "react";
import { api } from "./api";

const money = (cents) =>
  new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 2,
  }).format(cents / 100);
const blank = {
  sku: "",
  name: "",
  category: "General",
  reorder_level: 5,
  unit_price_cents: 0,
};
const stateOf = (p) =>
  p.quantity === 0
    ? "Out of stock"
    : p.quantity <= p.reorder_level
      ? "Low stock"
      : "In stock";

function Dialog({ title, onClose, children }) {
  const dialog = useRef(null);
  useEffect(() => {
    dialog.current.showModal();
  }, []);
  return (
    <dialog ref={dialog} onCancel={onClose}>
      <div className="dialog-head">
        <h2>{title}</h2>
        <button
          className="icon-button"
          aria-label="Close dialog"
          onClick={onClose}
        >
          ×
        </button>
      </div>
      {children}
    </dialog>
  );
}

export default function App() {
  const [products, setProducts] = useState([]);
  const [stats, setStats] = useState(null);
  const [movements, setMovements] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [query, setQuery] = useState("");
  const [filter, setFilter] = useState("All products");
  const [view, setView] = useState("Inventory");
  const [modal, setModal] = useState(null);
  const [form, setForm] = useState(blank);
  const [delta, setDelta] = useState(1);
  const [reason, setReason] = useState("");
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState("");

  const load = useCallback(async () => {
    try {
      const [p, s, m] = await Promise.all([
        api.products(),
        api.stats(),
        api.movements(),
      ]);
      setProducts(p);
      setStats(s);
      setMovements(m);
      setError("");
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }, []);
  useEffect(() => {
    load();
  }, [load]);
  const close = () => {
    if (!saving) setModal(null);
  };
  const open = (kind, product = null) => {
    setFormError("");
    setReason("");
    setDelta(1);
    setForm(
      product
        ? {
            sku: product.sku,
            name: product.name,
            category: product.category,
            reorder_level: product.reorder_level,
            unit_price_cents: product.unit_price_cents,
          }
        : { ...blank },
    );
    setModal({ kind, product });
  };
  const submit = async (event) => {
    event.preventDefault();
    setSaving(true);
    setFormError("");
    try {
      if (modal.kind === "movement") {
        await api.move({
          product_id: modal.product.id,
          delta: Number(delta),
          reason,
        });
        setNotice(`Stock movement recorded for ${modal.product.sku}.`);
      } else if (modal.kind === "archive") {
        await api.archive(modal.product.id);
        setNotice("Product archived. Movement history is preserved.");
      } else {
        const data = {
          ...form,
          reorder_level: Number(form.reorder_level),
          unit_price_cents: Number(form.unit_price_cents),
        };
        if (modal.product) delete data.sku;
        await api.save(modal.product?.id, data);
        setNotice(
          modal.product
            ? "Product updated."
            : "Product added. Receive stock to set its opening balance.",
        );
      }
      setModal(null);
      await load();
    } catch (e) {
      setFormError(e.message);
    } finally {
      setSaving(false);
    }
  };
  const visible = products.filter(
    (p) =>
      `${p.name} ${p.sku} ${p.category}`
        .toLowerCase()
        .includes(query.toLowerCase()) &&
      (filter === "All products" || stateOf(p) === filter),
  );
  const change = (event) =>
    setForm({ ...form, [event.target.name]: event.target.value });

  return (
    <div className="shell">
      <aside className="sidebar">
        <a className="brand" href="#">
          <span className="brand-icon">▦</span>stockroom
          <span className="brand-period">.</span>
        </a>
        <div className="workspace">
          <span className="workspace-avatar">MG</span>
          <div>
            <strong>Mayank's workspace</strong>
            <small>Inventory operations</small>
          </div>
        </div>
        <p className="nav-label">WORKSPACE</p>
        <nav aria-label="Main navigation">
          {["Inventory", "Movement history"].map((item, i) => (
            <button
              key={item}
              className={view === item ? "nav-active" : ""}
              onClick={() => setView(item)}
            >
              <span>{i ? "↔" : "▦"}</span>
              {item}
              {!i && stats && <b>{stats.products}</b>}
            </button>
          ))}
        </nav>
        <div className="sidebar-bottom">
          <span className="live-dot" /> Stock you can account for
          <p>Every movement leaves a trail.</p>
          <a href="/docs" target="_blank" rel="noreferrer">
            Explore the API ↗
          </a>
        </div>
      </aside>
      <main>
        <div className="breadcrumb">
          Workspace <span>/</span> {view}
          <span className="owner">
            MG <span>Mayank Gupta</span>
          </span>
        </div>
        <header>
          <div>
            <p className="eyebrow">A CLEAR VIEW OF YOUR STOCK</p>
            <h1>
              {view === "Inventory" ? "Inventory overview" : "Movement history"}
            </h1>
            <p className="subtitle">
              {view === "Inventory"
                ? "Know what you have. See what needs attention."
                : "A permanent record of every receipt and dispatch."}
            </p>
          </div>
          <button className="primary" onClick={() => open("product")}>
            ＋ Add product
          </button>
        </header>
        {error && (
          <div role="alert" className="banner error">
            Could not load inventory: {error}
            <button onClick={load}>Retry</button>
          </div>
        )}
        {notice && (
          <div role="status" className="banner success">
            {notice}
            <button
              aria-label="Dismiss notification"
              onClick={() => setNotice("")}
            >
              ×
            </button>
          </div>
        )}
        <section className="metrics" aria-label="Inventory summary">
          {[
            [
              "Active products",
              stats?.products,
              "Unique SKUs in your catalog",
              "▦",
            ],
            [
              "Units on hand",
              stats?.units,
              "Available across all products",
              "◫",
            ],
            [
              "Needs attention",
              stats?.low_stock,
              "At or below reorder level",
              "↘",
            ],
            [
              "Inventory value",
              stats ? money(stats.inventory_value_cents) : null,
              "Based on current unit prices",
              "₹",
            ],
          ].map(([label, value, sub, icon], i) => (
            <article className={`metric metric-${i}`} key={label}>
              <div>
                <span>{label}</span>
                <i>{icon}</i>
              </div>
              <strong>{value ?? "—"}</strong>
              <small>{sub}</small>
            </article>
          ))}
        </section>
        {view === "Inventory" ? (
          <>
            <section className="inventory-panel">
              <div className="panel-title">
                <div>
                  <h2>
                    Your products <span>{products.length}</span>
                  </h2>
                  <p>A single place to manage your catalog and stock levels.</p>
                </div>
                <button className="text-button" onClick={load}>
                  ↻ Refresh
                </button>
              </div>
              <div className="toolbar">
                <div className="tabs">
                  {["All products", "Low stock", "Out of stock"].map((item) => (
                    <button
                      key={item}
                      className={filter === item ? "selected" : ""}
                      onClick={() => setFilter(item)}
                    >
                      {item}
                    </button>
                  ))}
                </div>
                <label className="search">
                  <span>⌕</span>
                  <input
                    aria-label="Search products"
                    placeholder="Search name, SKU or category…"
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                  />
                </label>
              </div>
              {loading ? (
                <div className="empty">Loading your inventory…</div>
              ) : (
                <div className="table-scroll">
                  <table>
                    <thead>
                      <tr>
                        <th>Product</th>
                        <th>Category</th>
                        <th>Stock level</th>
                        <th>Unit price</th>
                        <th>Status</th>
                        <th>
                          <span className="sr-only">Actions</span>
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {visible.map((p) => (
                        <tr key={p.id}>
                          <td>
                            <div className="product-name">
                              <div className="product-icon">
                                {p.name.slice(0, 2).toUpperCase()}
                              </div>
                              <div>
                                <button
                                  className="name-button"
                                  onClick={() => open("product", p)}
                                >
                                  {p.name}
                                </button>
                                <small>{p.sku}</small>
                              </div>
                            </div>
                          </td>
                          <td>
                            <span className="category">{p.category}</span>
                          </td>
                          <td>
                            <strong className="quantity">{p.quantity}</strong>
                            <span className="units"> units</span>
                            <div className="stock-track">
                              <div
                                style={{
                                  width: `${Math.min(100, (p.quantity / Math.max(1, p.reorder_level * 3)) * 100)}%`,
                                }}
                                className={
                                  p.quantity <= p.reorder_level ? "low" : ""
                                }
                              />
                            </div>
                            <small className="reorder">
                              Reorder at {p.reorder_level}
                            </small>
                          </td>
                          <td className="price">{money(p.unit_price_cents)}</td>
                          <td>
                            <span
                              className={`status status-${p.quantity === 0 ? "empty" : p.quantity <= p.reorder_level ? "low" : "ok"}`}
                            >
                              ● {stateOf(p)}
                            </span>
                          </td>
                          <td>
                            <div className="row-actions">
                              <button
                                className="secondary"
                                onClick={() => open("movement", p)}
                              >
                                Adjust stock
                              </button>
                              <button
                                className="icon-button archive"
                                title="Archive product"
                                aria-label={`Archive ${p.name}`}
                                onClick={() => open("archive", p)}
                              >
                                ×
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  {!visible.length && (
                    <div className="empty">
                      <span>▦</span>
                      <h3>
                        {products.length
                          ? "No matching products"
                          : "Your inventory starts here"}
                      </h3>
                      <p>
                        {products.length
                          ? "Try another search or stock filter."
                          : "Add your first product, then record a stock receipt."}
                      </p>
                      {!products.length && (
                        <button
                          className="primary"
                          onClick={() => open("product")}
                        >
                          Add your first product
                        </button>
                      )}
                    </div>
                  )}
                </div>
              )}
              <footer className="table-footer">
                Showing {visible.length} of {products.length} products
                <span>Quantities update after each movement</span>
              </footer>
            </section>
            <section className="bottom-grid">
              <div className="recent">
                <div className="section-header">
                  <h2>Recent movements</h2>
                  <button
                    className="text-button"
                    onClick={() => setView("Movement history")}
                  >
                    View all →
                  </button>
                </div>
                {movements.slice(0, 4).map((m) => (
                  <div className="movement" key={m.id}>
                    <span
                      className={`movement-icon ${m.delta < 0 ? "out" : ""}`}
                    >
                      {m.delta > 0 ? "↙" : "↗"}
                    </span>
                    <div>
                      <strong>{m.product_name}</strong>
                      <small>{m.reason}</small>
                    </div>
                    <b className={m.delta < 0 ? "negative" : "positive"}>
                      {m.delta > 0 ? "+" : ""}
                      {m.delta}
                    </b>
                  </div>
                ))}
                {!movements.length && (
                  <p className="muted">
                    Receipts and dispatches will appear here.
                  </p>
                )}
              </div>
              <aside className="insight">
                <span className="eyebrow">INVENTORY NOTE</span>
                <h2>
                  {stats?.low_stock
                    ? `${stats.low_stock} products need a closer look.`
                    : "Stay one step ahead."}
                </h2>
                <p>
                  Set a reorder level for each product. Stockroom flags it as
                  soon as the balance reaches that threshold.
                </p>
                <button
                  onClick={() => {
                    setFilter("Low stock");
                    window.scrollTo({ top: 240, behavior: "smooth" });
                  }}
                >
                  Review low stock →
                </button>
              </aside>
            </section>
          </>
        ) : (
          <section className="inventory-panel">
            <div className="panel-title">
              <div>
                <h2>Stock movement ledger</h2>
                <p>Latest 50 entries. Archived products keep their history.</p>
              </div>
              <button className="text-button" onClick={load}>
                ↻ Refresh
              </button>
            </div>
            <div className="table-scroll">
              <table>
                <thead>
                  <tr>
                    <th>Product / SKU</th>
                    <th>Change</th>
                    <th>Balance after</th>
                    <th>Reason</th>
                    <th>Recorded</th>
                  </tr>
                </thead>
                <tbody>
                  {movements.map((m) => (
                    <tr key={m.id}>
                      <td>
                        <strong>{m.product_name}</strong>
                        <small className="block">{m.sku}</small>
                      </td>
                      <td className={m.delta > 0 ? "positive" : "negative"}>
                        {m.delta > 0 ? "+" : ""}
                        {m.delta}
                      </td>
                      <td>{m.quantity_after}</td>
                      <td>{m.reason}</td>
                      <td>{new Date(m.created_at).toLocaleString()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {!movements.length && (
                <div className="empty">No stock movements yet.</div>
              )}
            </div>
          </section>
        )}
        <footer className="page-footer">
          Stockroom · Built by Mayank Gupta
          <span>Inventory, with a little more clarity.</span>
        </footer>
      </main>
      {modal && (
        <Dialog
          title={
            modal.kind === "movement"
              ? "Record a stock movement"
              : modal.kind === "archive"
                ? "Archive product"
                : modal.product
                  ? "Edit product"
                  : "Add a product"
          }
          onClose={close}
        >
          <form onSubmit={submit}>
            {formError && (
              <p className="form-error" role="alert">
                {formError}
              </p>
            )}
            {modal.kind === "archive" ? (
              <p>
                Archive <strong>{modal.product.name}</strong>? Its movement
                history will remain. Products must have zero stock before
                archiving.
              </p>
            ) : modal.kind === "movement" ? (
              <>
                <p className="dialog-description">
                  {modal.product.name} · {modal.product.quantity} units on hand
                </p>
                <label>
                  Quantity change
                  <input
                    required
                    type="number"
                    step="1"
                    min="-1000000"
                    max="1000000"
                    value={delta}
                    onChange={(e) => setDelta(e.target.value)}
                  />
                  <small>
                    Positive to receive stock; negative to dispatch.
                  </small>
                </label>
                <label>
                  Reason
                  <input
                    autoFocus
                    required
                    minLength="3"
                    maxLength="240"
                    placeholder="e.g. Received from supplier"
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                  />
                </label>
              </>
            ) : (
              <>
                <label>
                  Product name
                  <input
                    autoFocus
                    required
                    minLength="2"
                    maxLength="160"
                    name="name"
                    value={form.name}
                    onChange={change}
                    placeholder="e.g. Mechanical keyboard"
                  />
                </label>
                <div className="form-grid">
                  <label>
                    SKU
                    <input
                      required
                      disabled={Boolean(modal.product)}
                      minLength="2"
                      maxLength="40"
                      pattern="[A-Z0-9][A-Z0-9_-]+"
                      name="sku"
                      value={form.sku}
                      onChange={(e) =>
                        setForm({ ...form, sku: e.target.value.toUpperCase() })
                      }
                      placeholder="KB-101"
                    />
                  </label>
                  <label>
                    Category
                    <input
                      required
                      maxLength="60"
                      name="category"
                      value={form.category}
                      onChange={change}
                    />
                  </label>
                </div>
                <div className="form-grid">
                  <label>
                    Unit price (₹)
                    <input
                      type="number"
                      required
                      min="0"
                      max="1000000"
                      step="0.01"
                      value={form.unit_price_cents / 100}
                      onChange={(e) =>
                        setForm({
                          ...form,
                          unit_price_cents: Math.round(
                            Number(e.target.value) * 100,
                          ),
                        })
                      }
                    />
                  </label>
                  <label>
                    Reorder level
                    <input
                      type="number"
                      required
                      min="0"
                      max="1000000"
                      step="1"
                      name="reorder_level"
                      value={form.reorder_level}
                      onChange={change}
                    />
                  </label>
                </div>
                {!modal.product && (
                  <p className="dialog-description">
                    New products start at zero. Record a receipt to add opening
                    stock.
                  </p>
                )}
              </>
            )}
            <div className="dialog-actions">
              <button
                type="button"
                className="secondary"
                disabled={saving}
                onClick={close}
              >
                Cancel
              </button>
              <button className="primary" disabled={saving}>
                {saving
                  ? "Saving…"
                  : modal.kind === "movement"
                    ? "Record movement"
                    : modal.kind === "archive"
                      ? "Archive product"
                      : "Save product"}
              </button>
            </div>
          </form>
        </Dialog>
      )}
    </div>
  );
}
