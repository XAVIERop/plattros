/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SUPABASE_URL: string;
  readonly VITE_SUPABASE_ANON_KEY: string;
  readonly VITE_BHURSAS_SYNC_MODE?: "demo" | "edge_function" | "direct_table";
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
