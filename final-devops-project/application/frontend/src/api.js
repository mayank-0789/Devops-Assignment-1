async function request(path, options = {}) {
  const response = await fetch(path, {
    ...options,
    headers: { "Content-Type": "application/json", ...options.headers },
  });
  if (!response.ok) {
    let message = `Request failed (${response.status})`;
    try {
      const body = await response.json();
      message =
        typeof body.detail === "string"
          ? body.detail
          : body.detail?.map((e) => e.msg).join("; ") || message;
    } catch {
      /* Keep the HTTP error if a proxy returned HTML. */
    }
    throw new Error(message);
  }
  return response.status === 204 ? null : response.json();
}
export const api = {
  products: () => request("/api/products"),
  stats: () => request("/api/products/stats"),
  movements: () => request("/api/movements"),
  save: (id, data) =>
    request(`/api/products${id ? `/${id}` : ""}`, {
      method: id ? "PUT" : "POST",
      body: JSON.stringify(data),
    }),
  archive: (id) => request(`/api/products/${id}`, { method: "DELETE" }),
  move: (data) =>
    request("/api/movements", { method: "POST", body: JSON.stringify(data) }),
};
