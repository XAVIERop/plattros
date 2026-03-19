# Plattr OS

POS SaaS + plattros.in landing. Standalone repo (extracted from MUJFOODCLUB monorepo).

## Supabase

- **Project:** `yamjjiwifuiuhxzlnqzx`
- **Dashboard:** https://supabase.com/dashboard/project/yamjjiwifuiuhxzlnqzx

## Setup

```bash
cp .env.example .env.local
# Edit .env.local with VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY
npm install
npm run dev
```

## Deploy

- **Vercel:** Connect repo, Root Directory = `.`, set env vars
- **Edge functions:** `npm run deploy:functions`

## Structure

- `src/` – POS app, landing, check-in
- `packages/pos-core/` – Billing, KOT, status logic
- `supabase/` – Migrations and edge functions
