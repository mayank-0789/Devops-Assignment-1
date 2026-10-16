import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// In development the Vite dev server proxies /api to the FastAPI backend.
// In production nginx does the same job (see nginx.conf.template).
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: Object.fromEntries(
      ["/api", "/docs", "/openapi.json", "/metrics"].map((path) => [
        path,
        "http://127.0.0.1:8000",
      ]),
    ),
  },
  build: { outDir: "dist", sourcemap: false },
});
