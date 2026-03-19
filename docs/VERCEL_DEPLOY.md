# Deploy Plattr OS to Vercel

## Quick setup

1. **Connect repo** — Go to [vercel.com](https://vercel.com) → New Project → Import your MUJFOODCLUB repo.

2. **Configure project**
   - **Root Directory:** `apps/bhursas-pos` (click Edit, set to this path)
   - **Framework Preset:** Vite (auto-detected)
   - **Build Command:** `npm run build`
   - **Output Directory:** `dist`
   - **Install Command:** Uses monorepo install from `vercel.json` (installs from repo root, then app)

3. **Environment variables** (Settings → Environment Variables)
   - `VITE_SUPABASE_URL` — Your Supabase project URL
   - `VITE_SUPABASE_ANON_KEY` — Supabase anon key

4. **Deploy** — Click Deploy. Vercel will build and deploy.

5. **Custom domain** — After deploy, go to Settings → Domains → Add `plattros.in`. Add both `plattros.in` and `www.plattros.in` if needed. Vercel will show DNS records (A or CNAME).

---

## Monorepo note

The app uses `@pos-core` from `../../packages/pos-core`. With Root Directory = `apps/bhursas-pos`, Vercel still has the full repo, so the path resolves correctly during build.

If you see **"Failed to fetch one or more git submodules"** (this repo has no submodules), go to Project Settings → Git and disable "Include Git Submodules" if that option exists. The warning is usually harmless.

---

## SPA routing

The existing `vercel.json` in `apps/bhursas-pos` already has rewrites so all routes serve `index.html` (React Router works).
