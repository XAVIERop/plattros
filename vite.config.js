import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";
export default defineConfig({
    root: __dirname,
    plugins: [react()],
    server: {
        host: "127.0.0.1",
        port: 8090
    },
    optimizeDeps: {
        entries: [path.resolve(__dirname, "index.html")]
    },
    resolve: {
        alias: {
            "@": path.resolve(__dirname, "./src"),
            "@pos-core": path.resolve(__dirname, "./packages/pos-core/src")
        }
    }
});
