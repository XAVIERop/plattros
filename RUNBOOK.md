# Plattr OS – Runbook

Operational guide for common recovery and maintenance tasks.

---

## Stuck outbox (orders not syncing)

**Symptom:** Orders created offline remain in "pending" and never reach the backend.

**In-app recovery:**
1. Ensure the device is **online**.
2. Click **Sync** (in the menu header or Billing view) to trigger `flushOutbox()`.
3. The sync worker runs every ~30s when online; wait a minute and check again.

**What it does:** `flushOutbox` processes pending outbox items, retrying up to 5 times with exponential backoff. Failed items are reset to "pending" before each run via `resetFailedToPending()`.

**If still stuck:** Check browser console for errors. Verify `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, and that `pos-offline-sync` (or direct_table) is reachable. Ensure RLS allows the authenticated user to insert into `orders` and `order_items`.

---

## Failed print jobs (KOT / receipt not printing)

**Symptom:** Print jobs stay in "failed" and never retry.

**In-app recovery:**
1. **Reload the app** – `recoverOfflineOpsQueues()` runs on mount and resets failed jobs to queued.
2. Or go to **Billing** and click **Reprint** on individual failed jobs.
3. The print queue processes automatically when online (~30s interval).

**What it does:** `processPrintQueue` calls `resetFailedPrintJobsToQueued()` before processing, so failed jobs are moved back to "queued" and retried. Up to 3 jobs are processed per run.

**If still failing:**
- Verify `printnode-secure` is deployed and has `PRINTNODE_API_KEY_*` secrets.
- Ensure `cafe_printer_configs` has `printnode_printer_id` for the cafe.
- Check Supabase function logs for `printnode-secure` errors.

---

## Recover queues (bulk reset)

**When to use:** Multiple failed outbox items and/or print jobs; you want to reset all and retry.

**In-app:** Reload the app – `recoverOfflineOpsQueues()` runs automatically on mount.

**What it does:**
- Resets all `outbox` rows with `status = 'failed'` to `status = 'pending'`.
- Resets all `printQueue` rows with `status = 'failed'` to `status = 'queued'`.
- Returns counts of recovered items.

**After recovery:** Sync and print queue will process on the next interval (~30s) or when the user triggers them manually.

---

## Clear local data (nuclear option)

**When:** Corrupt IndexedDB, need a fresh start, or migrating to a new cafe.

**How:** Clear site data for the POS origin:
- Chrome: DevTools → Application → Storage → Clear site data
- Or: `indexedDB.deleteDatabase('bhursas_pos_db')  // DB name unchanged for backward compatibility` in console

**Warning:** All local orders, outbox, and print queue will be lost. Only do this if orders have already synced or are no longer needed.

---

## Quick reference

| Action | Location | Function |
|--------|----------|----------|
| Sync (flush outbox) | Menu header, Billing | `flushOutbox()` |
| Recover queues | On app load | `recoverOfflineOpsQueues()` (auto) |
| Retry single outbox | Billing → Outbox | `retryOutboxItem(id)` |
| Reprint single job | Billing → Print Jobs | `retryPrintJob(id)` |
