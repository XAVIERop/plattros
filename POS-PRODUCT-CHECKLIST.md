# Plattr OS – Product Status & Checklist

Deep-dive of the standalone POS app: **current status**, **gaps**, and a **prioritized checklist** for what’s left.

---

## 1. Current status (what’s built)

### 1.1 App shell & navigation
- [x] Dedicated app (`apps/bhursas-pos` / Plattr OS) separate from MUJFOODCLUB
- [x] Desktop sidebar nav (all views)
- [x] Mobile: bottom tab bar (Home, Menu, Orders, Tables)
- [x] Mobile: hamburger drawer with full module list (gated by rollout flags)
- [x] Shared mobile header (`MobileHeader`) on every view
- [x] Splash screen with auto-dismiss after session load
- [x] Auth gate: sign-in required; optional terminal claim by `cafeId` (localStorage) when no user

### 1.2 Authentication & session
- [x] Supabase Auth: `signIn` / `signOut`
- [x] Profile resolution: `profiles.full_name`, `user_type`, `cafe_id`
- [x] `pos-login-bootstrap` edge function: staff list + today’s preview (earnings, in-progress, ready-to-serve, recent orders) for terminal-claim / PIN flow
- [x] `cafeId` from logged-in user or from `terminalCafeId` (localStorage) when unauthenticated
- [x] **Claim Terminal + PIN flow** – UI has “Claim Terminal” but relies on email/password or pre-set cafe ID

### 1.3 Data layer (offline-first)
- [x] Dexie DB: `offlineOrders`, `outbox`, `printQueue`, `menuCache`
- [x] Outbox: enqueue order draft → pending; sync worker with retry (exponential backoff, max 5 attempts)
- [x] Sync modes: `demo` (no backend), `edge_function` (`pos-offline-sync`), `direct_table` (client upserts `orders` + inserts `order_items`)
- [x] **Edge function `pos-offline-sync`**: upserts `orders` + inserts `order_items` (idempotent by order id); optional WhatsApp receipt
- [x] **`direct_table` mode**: upserts `orders` and inserts `order_items` (same as edge function)

### 1.4 Menu
- [x] `useCafeMenu`: remote `menu_items` by `cafe_id`, with time-based availability (`available_from` / `available_until`)
- [x] Offline: `menuCache` populated on load; fallback to `BHURSAS_MENU` (hardcoded coffee list) when offline and empty cache
- [x] Coffee-first modifiers: size, milk, sugar, extra shots; pricing via `calculateCoffeePrice` (offline menu)
- [x] Categories; search; 2-col mobile grid / horizontal cards

### 1.5 Order capture & billing
- [x] Cart with line items, modifiers, quantity, discount (amount/%), service charge
- [x] Order modes: delivery, dine-in, takeaway (customer/phone/table/delivery fields)
- [x] Payment: cash, card, UPI, split (with split settlement entries)
- [x] `calculateBillingTotals`, `createKotLines`, `getNextTicketNumber` from `@pos-core`
- [x] On “Process”: write to `offlineOrders`, enqueue outbox item, enqueue KOT print job, enqueue bill print job, then `flushOutbox` + `processPrintQueue`
- [x] Parked carts (local state), last-created order ref

### 1.6 Orders list & lifecycle
- [x] `fetchOrders`: Supabase `orders` by `cafe_id` (remote)
- [x] `fetchLocalOrders`: Dexie `offlineOrders` (local-only)
- [x] Merged “active” list: remote + local, with sync status from outbox
- [x] Realtime: `subscribeOrderRealtime(cafeId)` on `orders` table
- [x] Order detail: items from `order_items` + `menu_items` join (`fetchOrderItems`)
- [x] Update status: `update-order-status-secure` (received → confirmed → preparing → on_the_way → completed / cancelled)
- [x] Mark payment received: `mark-order-payment-received`
- [x] Edit order (customer, phone, type, table, items); add/remove items; save to remote or local draft
- [x] Cancel with reason

### 1.7 Kitchen display
- [x] Lanes: New → Preparing → Ready / Dispatch
- [x] Filter by search; quick actions (advance status, print)
- [x] Urgent styling for tickets waiting >10 min

### 1.8 Table management
- [x] Table grid; status (occupied / free / reserved); meta (capacity, reservation, guest)
- [x] Table ops: assign guest, reserve, seat, new order / edit order; transfer, merge; close table; mark clean
- [x] Table detail panel (floating); form for guest/reservation

### 1.9 Delivery ops
- [x] List delivery orders; assign rider (dropdown from delivery_riders); dispatch (status → on_the_way)

### 1.10 Inventory / menu stock (admin)
- [x] List from `menu_items` (admin fetch); toggle availability; schedule (available_from / available_until); clear schedule

### 1.11 Offers, customers, analytics, staff, cafe details
- [x] Offers: list, create (name, type, value), toggle active (API assumed)
- [x] Customers: summary table (name, phone, order count, spend)
- [x] Analytics: KPIs (orders, completed, pending payments, revenue, avg ticket, completion rate); status/type/payment mix; top customers/items
- [x] Staff: list from `cafe_staff` + profiles
- [x] Cafe details: name, phone, location, description; save (API assumed)

### 1.12 History / reporting
- [x] Date range (today, yesterday, custom); report data; export CSV

### 1.13 Billing / sync & print queue (UI)
- [x] Outbox list (status, retry); print queue list; flush outbox, process print queue; retry single item/job
- [x] `processPrintQueue`: calls `printQueuedTicket` → `printnode-secure` (KOT or receipt)
- [x] Print adapter: **requires online**; no local printer driver or offline print buffer

### 1.14 Settings
- [x] Menu management / organizer: search, availability filter, category filter; add item (name, category, price); edit; availability toggle; schedule
- [x] Rollout flags toggles (orders, manualBilling, kitchen, tableManagement, deliveryOps, businessModules)
- [x] Dual-run validation stats; cutover gates (for migration)

### 1.15 Mobile layout (recent)
- [x] Per-view mobile headers; landscape: orders list + detail split; optional bill panel in landscape
- [x] Bottom sheet style cart; floating cart summary on menu

### 1.16 Shared business logic
- [x] `packages/pos-core`: billing, ticket, status, order lifecycle, print lines, pricing, tenancy, events (used for KOT lines, totals, next ticket#, status transitions)

---

## 2. Gaps and limitations

| Area | Gap |
|------|-----|
| **Sync** | Fixed: `direct_table` now inserts `order_items` (same as edge function). |
| **Docs** | Fixed: README has `pos-offline-sync`, `pos-login-bootstrap`, env vars. |
| **Print** | Print is cloud-only (`printnode-secure`). No offline print queue persistence to physical printer when back online (queue exists but no “send to printer when online” guarantee if app was closed). |
| **Auth** | Fixed: Claim Terminal + PIN when no cafe ID; Admin Setup after claim. |
| **Conflict** | Fixed: optimistic concurrency with `updated_at`; refetch on conflict. |
| **Menu** | Modifier catalog is coffee-only in code; no generic modifier set from backend. |
| **Delivery** | Fixed: Rider list from delivery_riders; dropdown to assign. |
| **Offline** | Fixed: Offline banner in Orders view; local orders shown when offline; sync status per order from outbox. |

---

## 3. Checklist – what’s left (prioritized)

### P0 – Critical for production
- [x] **Fix `direct_table` sync**: In `useOfflineSync.ts`, after upserting `orders`, insert `order_items` (same contract as `pos-offline-sync`) — already implemented.
- [x] **Update README**: Replace `bhursas-offline-order-sync` with `pos-offline-sync`; add `pos-login-bootstrap`; document `VITE_BHURSAS_SYNC_MODE` and env vars — README already correct.
- [x] **Print when back online**: `handleOnline` now calls `processPrintQueue`; `resetFailedPrintJobsToQueued` runs before each process so eligible failed jobs retry when back online.

### P1 – Important for reliability & ops
- [x] **Conflict policy**: Optimistic concurrency via `updated_at`; if save affects 0 rows, show "Order was modified elsewhere. Refreshing..." and refetch.
- [x] **Offline orders list**: Offline banner in Orders view ("You're offline — showing local orders. Sync will resume when back online."); remote + local merge with sync status from outbox.
- [x] **Terminal claim / PIN**: Claim Terminal screen when `terminalCafeId` is null; Cafe ID input saves to localStorage; PIN flow + Admin Setup available after claim.

### P2 – Feature completeness
- [x] **Receipt print from queue**: Bill/receipt jobs enqueued and processed; `printnode-secure` resolves `printer_id` from `cafe_printer_configs` when not provided.
- [x] **Menu cache invalidation**: Periodic refresh every 5 min when online (silent) so admin menu updates propagate.
- [x] **Delivery riders**: Replace “RIDER-1” with rider list from delivery_riders; dropdown to assign; delivery_rider_id (UUID) stored on order.
- [x] **Generic modifiers**: Schema (modifier_groups, modifier_options, menu_item_modifier_groups); useCafeModifiers hook; ModifierSelector UI; items with modifiers open selector before add.

### P3 – Polish & scale
- [x] **Shift / session**: Shift session created on login; `session_id` on orders for reporting; persisted to localStorage; synced via pos-offline-sync and direct_table.
- [x] **Audit log**: Log order create, status change, payment, cancel via `log_audit_event` in pos-offline-sync, update-order-status-secure, mark-order-payment-received, and direct_table sync.
- [x] **Multi-terminal**: If multiple devices per cafe, terminal_id on orders; VITE_BHURSAS_TERMINAL_ID or Settings; shown in Dashboard (e.g. “Terminal A”).
- [x] **Tests**: Unit tests for `@pos-core` (existing); integration tests for create order → outbox (enqueueOrderDraft, listPendingOutbox, listRecentOutbox) in `apps/bhursas-pos`.

### P4 – Documentation & DevOps
- [x] **Env template**: `.env.example` with comments; [ENV.md](./ENV.md) documents `VITE_*` and Supabase secrets (print, WhatsApp).
- [x] **Deploy**: [DEPLOY.md](./DEPLOY.md) – build, Vercel/Netlify, env vars.
- [x] **Runbook**: [RUNBOOK.md](./RUNBOOK.md) – flush outbox, reset prints, recover queues.

---

## 4. Quick reference

| Component | Status | Notes |
|-----------|--------|-------|
| Auth | Done | Supabase Auth + profile; bootstrap for preview |
| Menu | Done | Remote + cache + fallback; coffee modifiers |
| Order capture | Done | Cart, billing, split, park |
| Outbox sync | Done | demo / edge_function / direct_table (all insert order_items) |
| Order list | Done | Remote + local merge; realtime |
| Order detail & edit | Done | Items, status, payment, cancel |
| Kitchen | Done | Lanes, actions, print |
| Tables | Done | Grid, guest, reserve, transfer, merge |
| Delivery | Done | List + dispatch; rider dropdown from delivery_riders |
| Inventory | Done | Availability, schedule |
| Offers / Customers / Analytics / Staff / Cafe | Done | List/create/edit where applicable |
| History / Reporting | Done | Range, export CSV |
| Billing / Sync UI | Done | Outbox + print queue, flush, retry |
| Settings | Done | Menu organizer, rollout flags |
| Print | Done | KOT + receipt via printnode-secure; online only |
| Mobile layout | Done | Headers, bottom nav, drawer, landscape splits |
| pos-core | Done | Billing, ticket, status, print lines |

Use this checklist to close P0 first, then P1, and then iterate on P2–P4 as needed.
