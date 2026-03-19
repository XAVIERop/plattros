# Plattr OS – Build & Deploy

## Build

From the **monorepo root**:

```bash
npm run plattr:build
```

Or from `apps/bhursas-pos`:

```bash
npm install
npm run build
```

Output: `apps/bhursas-pos/dist/` (static SPA)

## Production env vars

Set these in your hosting platform (Vercel, Netlify, etc.):

| Variable | Required | Description |
|----------|----------|-------------|
| `VITE_SUPABASE_URL` | Yes | Supabase project URL |
| `VITE_SUPABASE_ANON_KEY` | Yes | Supabase anon key |
| `VITE_BHURSAS_SYNC_MODE` | No | `demo`, `edge_function`, or `direct_table` (default: `demo`) |
| `VITE_BHURSAS_CAFE_ID` | No | Default cafe UUID for terminal claim |

## Deploy options

### Vercel (recommended)

1. Create a new Vercel project or add as a separate app in a monorepo.
2. **Root directory:** `apps/bhursas-pos` (or use this folder if deploying Plattr OS as standalone)
3. **Build command:** `npm run build` (run from `apps/bhursas-pos`)
4. **Output directory:** `dist`
5. **Framework preset:** Vite
6. Add env vars in Project Settings → Environment Variables.

For monorepo: if the root has `package.json` with workspaces, use:
- **Build command:** `npm run plattr:build` (from repo root)
- **Root directory:** `.` (repo root)
- **Output directory:** `apps/bhursas-pos/dist`

### Netlify

1. **Base directory:** `apps/bhursas-pos`
2. **Build command:** `npm run build`
3. **Publish directory:** `dist`
4. Add env vars in Site settings → Environment variables.

### Static hosting (S3, Cloudflare Pages, etc.)

1. Run `npm run build` in `apps/bhursas-pos`.
2. Upload contents of `dist/` to your static host.
3. Ensure SPA routing: all routes serve `index.html` (client-side routing).

## Edge functions (required for non-demo)

Deploy all Plattr functions (Plattr Supabase project ref: `yamjjiwifuiuhxzlnqzx`):

```bash
cd apps/bhursas-pos && npm run deploy:functions
```

Or manually:

```bash
npx supabase functions deploy pos-offline-sync --project-ref yamjjiwifuiuhxzlnqzx
npx supabase functions deploy pos-login-bootstrap --project-ref yamjjiwifuiuhxzlnqzx
npx supabase functions deploy printnode-secure --project-ref yamjjiwifuiuhxzlnqzx
npx supabase functions deploy update-order-status-secure --project-ref yamjjiwifuiuhxzlnqzx
npx supabase functions deploy mark-order-payment-received --project-ref yamjjiwifuiuhxzlnqzx
npx supabase functions deploy loyalty-whatsapp-send --project-ref yamjjiwifuiuhxzlnqzx
```

See [ENV.md](./ENV.md) for required secrets (WHATSAPP_ACCESS_TOKEN, WHATSAPP_PHONE_NUMBER_ID for campaigns).

## Production URL

Plattr OS is deployed at **https://pos.mujfoodclub.in**.

When creating a Vercel project:
1. **Root directory:** `apps/bhursas-pos`
2. **Custom domain:** Add `pos.mujfoodclub.in` in Vercel project settings
3. **Env vars:** Set all `VITE_*` variables for Production
