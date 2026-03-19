# Plattr OS – Go-Live Readiness

In-depth analysis of what's built, what's left, and when we can make it live.

---

## 1. Executive Summary

| Metric | Status |
|--------|--------|
| **Core POS features** | ✅ 95% complete |
| **Offline sync** | ✅ Done |
| **Print (KOT + receipt)** | ✅ Done (cloud/PrintNode) |
| **Database schema** | ✅ Migrations exist |
| **Edge functions** | ✅ Built (need deploy + CORS) |
| **Branding** | ✅ Updated to Plattr OS |
| **Deployment config** | ⚠️ Needs Plattr OS URL |
| **Billing / trials** | ❌ Not built |
| **Landing page** | ❌ Not built |

**Verdict:** Technically ready for **soft launch** (pilot with 1–2 cafes) in **1–2 weeks**. Full commercial launch needs billing + landing (add 2–4 weeks).

---

## 2. What's Built (Complete)

### 2.1 Core POS
- [x] Order capture (cart, modifiers, discount, service charge)
- [x] Payment: cash, card, UPI, split
- [x] Order modes: dine-in, takeaway, delivery
- [x] Kitchen display (lanes, status, print)
- [x] Table management (grid, guest, reserve, transfer, merge)
- [x] Delivery ops (rider assignment, dispatch)
- [x] Menu management (add/edit, availability, schedule)
- [x] Modifier groups (backend-driven via `modifier_groups`, `modifier_options`)

### 2.2 Offline-First
- [x] Dexie IndexedDB: `offlineOrders`, `outbox`, `printQueue`, `menuCache`
- [x] Outbox sync with retry (exponential backoff, max 5)
- [x] Sync modes: `demo`, `edge_function`, `direct_table`
- [x] `pos-offline-sync` edge function (orders + order_items)
- [x] `direct_table` mode (client upserts)
- [x] Recover queues on app load
- [x] Offline banner in Orders view

### 2.3 Auth & Session
- [x] Supabase Auth (email/password)
- [x] Profile: `full_name`, `user_type`, `cafe_id`
- [x] `pos-login-bootstrap` (staff list, today's preview)
- [x] Claim Terminal + PIN flow
- [x] Shift session (`session_id` on orders)
- [x] Terminal ID (`terminal_id` on orders)

### 2.4 Print
- [x] KOT + receipt via `printnode-secure`
- [x] Print queue with retry
- [x] `cafe_printer_configs` for printer mapping
- [x] Per-cafe PrintNode API keys

### 2.5 Business Features
- [x] Customers (orders + loyalty merge)
- [x] Analytics (KPIs, status mix, top customers/items)
- [x] Offers (list, create, toggle)
- [x] Staff list
- [x] Cafe details
- [x] History / reporting (date range, export CSV)
- [x] Loyalty panel (QR, feedback, low-rating alerts)
- [x] CheckIn page (`/checkin/:restaurantId`)
- [x] Reviews page (`/reviews/:restaurantId`)

### 2.6 Mobile
- [x] Responsive layout
- [x] Bottom nav, hamburger drawer
- [x] Landscape splits
- [x] Floating cart, bottom sheet

### 2.7 Database
- [x] `orders`, `order_items` (with `session_id`, `terminal_id`)
- [x] `modifier_groups`, `modifier_options`, `menu_item_modifier_groups`
- [x] `pos_shift_sessions` (optional)
- [x] `cafe_printer_configs`, `delivery_riders`
- [x] `log_audit_event` RPC
- [x] Migrations applied in main schema

---

## 3. What's Left (Gaps)

### 3.1 Branding (Quick)

| Item | Location | Action |
|------|----------|--------|
| Page title | `index.html` | Change "Bhursa's POS" → "Plattr OS" |
| Package name | `package.json` | Optional: `plattr-os` |
| IndexedDB name | `db.ts` | Optional: `plattr_os_db` (breaking change) |
| Docs | Various | Update Bhursas → Plattr OS |
| Realtime channel | `orderRealtime.ts` | Optional: `plattr-orders-${cafeId}` |

### 3.2 Deployment (Required for Go-Live)

| Item | Status | Action |
|------|--------|--------|
| **Plattr OS URL** | Not set | Decide: `pos.mujfoodclub.in` or `plattros.com` |
| **Vercel/Netlify project** | Uses root config | Create separate project or subpath for Plattr OS |
| **CORS in edge functions** | Only mujfoodclub.in + localhost | Add Plattr OS production URL to `ALLOWED_ORIGINS` |
| **Env vars in hosting** | — | Set `VITE_SUPABASE_*`, `VITE_BHURSAS_SYNC_MODE` |

**Edge functions to update CORS:**
- `pos-offline-sync`
- `pos-login-bootstrap`
- `printnode-secure`
- `update-order-status-secure`
- `mark-order-payment-received`

### 3.3 Optional / Nice-to-Have

| Item | Effort | Notes |
|------|--------|-------|
| **Offline print buffer** | Medium | Queue prints when offline; send when back online (currently requires online) |
| **PWA / install prompt** | Low | Add to home screen for tablet use |
| **Demo cafe** | Low | Seed a demo cafe for trials |
| **Error boundary** | Low | Graceful crash handling |
| **E2E tests** | Medium | Playwright for critical flows |

### 3.4 Commercial (For Paid Launch)

| Item | Effort | Notes |
|------|--------|-------|
| **Landing page** | 1–2 weeks | plattros.com or /pos on mujfoodclub |
| **Pricing page** | 2–3 days | Tiers, FAQ |
| **Billing (Stripe/Razorpay)** | 1–2 weeks | Subscriptions, trials |
| **Trial flow** | 3–5 days | 14-day trial, no card |
| **Onboarding wizard** | 3–5 days | First-time setup guide |

---

## 4. Pre-Launch Checklist

### 4.1 Technical (Must-Do)

- [x] **Branding:** Update `index.html` title to "Plattr OS"
- [x] **Deploy script:** `npm run deploy:functions` in apps/bhursas-pos
- [ ] **Deploy URL:** Decide and register domain (e.g. `pos.mujfoodclub.in`)
- [ ] **CORS:** Add Plattr OS URL to `ALLOWED_ORIGINS` in all POS edge functions
- [ ] **Deploy:** Create Vercel/Netlify project for `apps/bhursas-pos`
- [ ] **Env vars:** Set `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `VITE_BHURSAS_SYNC_MODE=direct_table` (or `edge_function`)
- [ ] **Edge functions:** Deploy `pos-offline-sync`, `pos-login-bootstrap`, `printnode-secure` (if not already)
- [ ] **Migrations:** Ensure all POS migrations are applied (modifier_groups, pos_shift_session, pos_terminal_id, pos_audit_log)
- [ ] **Print:** Verify `cafe_printer_configs` + PrintNode keys for pilot cafe
- [ ] **Smoke test:** Create order → sync → print → status update → payment

### 4.2 Pilot (Soft Launch)

- [ ] Pick 1–2 pilot cafes
- [ ] Create cafe + staff profiles in Supabase
- [ ] Configure `cafe_printer_configs` if printing
- [ ] Train staff on Claim Terminal, order flow, kitchen display
- [ ] Monitor outbox sync, print queue, errors

### 4.3 Commercial (Full Launch)

- [ ] Landing page live
- [ ] Pricing page + checkout
- [ ] 14-day trial flow
- [ ] Support channel (email/WhatsApp)

---

## 5. Timeline Estimate

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| **Week 1: Prep** | 5–7 days | Branding, CORS, deploy URL, Vercel project, smoke test |
| **Week 2: Pilot** | 5–7 days | 1–2 cafes live, feedback, bug fixes |
| **Soft launch** | — | Plattr OS live for pilot cafes |
| **Weeks 3–4: Commercial** | 10–14 days | Landing, pricing, billing, trial flow |
| **Full launch** | — | Self-serve signup, paid tiers |

**Earliest soft launch:** ~2 weeks from now (assuming 1–2 days for branding + CORS + deploy).

---

## 6. Deployment Steps (Quick Reference)

### 6.1 One-Time Setup

1. **Domain:** Add `pos.mujfoodclub.in` (or chosen URL) to DNS.
2. **Vercel:** New project, root = `apps/bhursas-pos`, build = `npm run build`, output = `dist`.
3. **Env vars:** `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `VITE_BHURSAS_SYNC_MODE`, `VITE_BHURSAS_CAFE_ID` (optional).
4. **CORS:** Set `ALLOWED_ORIGINS` in Supabase Edge Function secrets: `https://mujfoodclub.in,https://pos.mujfoodclub.in,http://localhost:8090`.

### 6.2 Deploy Edge Functions

```bash
npx supabase functions deploy pos-offline-sync --project-ref <ref>
npx supabase functions deploy pos-login-bootstrap --project-ref <ref>
npx supabase functions deploy printnode-secure --project-ref <ref>
```

### 6.3 Verify

- Open Plattr OS URL → login → claim terminal (or use cafe ID)
- Add item to cart → Process → check order in Supabase `orders`
- Trigger print → check `printnode-secure` logs

---

## 7. Risk & Mitigation

| Risk | Mitigation |
|------|------------|
| Sync fails in production | Use `direct_table` first (no edge function dependency); add logging |
| Print fails | Verify PrintNode keys; fallback: manual print from Orders |
| RLS blocks inserts | Test with real cafe_staff user; check `orders` RLS policies |
| Offline data loss | Outbox retries; recover on load; document "clear site data" only as last resort |

---

## 8. Summary

**Plattr OS is feature-complete for a pilot.** The remaining work is:

1. **Branding** (1 day)
2. **CORS + deploy URL** (1 day)
3. **Vercel project + env** (1 day)
4. **Pilot onboarding** (3–5 days)

**Go live for pilot: 1–2 weeks.**

**Full commercial launch: +2–4 weeks** (landing, billing, trial).
