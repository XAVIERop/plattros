# Plattr OS – Environment & Secrets

## Client-side (VITE_*)

Set these in `.env.local` (or `.env`). They are bundled into the app at build time.

| Variable | Required | Description |
|----------|----------|-------------|
| `VITE_SUPABASE_URL` | Yes (non-demo) | Supabase project URL |
| `VITE_SUPABASE_ANON_KEY` | Yes (non-demo) | Supabase anon key |
| `VITE_BHURSAS_CAFE_ID` | No | Default cafe UUID for terminal claim |
| `VITE_BHURSAS_TERMINAL_ID` | No | Terminal identifier for multi-device (e.g. A, 1); also settable in Settings |
| `VITE_BHURSAS_SYNC_MODE` | No | `demo` (default), `edge_function`, or `direct_table` |
| `VITE_PRINT_SERVER_URL` | No | Local print server URL (e.g. `http://localhost:3001`) for ₹0 print cost; when set, POS tries this before PrintNode |

## Supabase Edge Function Secrets

These are configured in Supabase Dashboard → Project Settings → Edge Functions → Secrets. **Never** put them in client `.env`.

### Print (`printnode-secure`)

| Secret | Description |
|--------|-------------|
| `PRINTNODE_API_KEY_DEFAULT` | Default PrintNode API key |
| `PRINTNODE_API_KEY_<CAFE>` | Per-cafe keys (e.g. `PRINTNODE_API_KEY_CHATKARA`) |
| `SUPABASE_SERVICE_ROLE_KEY` | Auto-set by Supabase |

### Sync (`pos-offline-sync`)

| Secret | Description |
|--------|-------------|
| `SUPABASE_SERVICE_ROLE_KEY` | Auto-set |
| `WHATSAPP_ACCESS_TOKEN` | Optional: for digital receipt via WhatsApp |
| `WHATSAPP_PHONE_NUMBER_ID` | Optional: WhatsApp Business phone number ID |

### Login bootstrap (`pos-login-bootstrap`)

| Secret | Description |
|--------|-------------|
| `SUPABASE_SERVICE_ROLE_KEY` | Auto-set |

### WhatsApp automation (`whatsapp-automation-runner`)

Used for order updates, receipts, win-back campaigns.

| Secret | Description |
|--------|-------------|
| `WHATSAPP_ACCESS_TOKEN` | Meta WhatsApp Business API token |
| `WHATSAPP_PHONE_NUMBER_ID` | Phone number ID |
| `WHATSAPP_DRY_RUN` | Set to `true` to log without sending |
| `SUPABASE_SERVICE_ROLE_KEY` | Auto-set |

### Loyalty campaigns (`loyalty-whatsapp-send`)

Used for sending campaigns from LoyaltyPanel → Campaigns.

| Secret | Description |
|--------|-------------|
| `WHATSAPP_ACCESS_TOKEN` | Meta WhatsApp Business API token |
| `WHATSAPP_PHONE_NUMBER_ID` | Phone number ID |
| `WHATSAPP_DRY_RUN` | Set to `true` to log without sending |
| `SUPABASE_SERVICE_ROLE_KEY` | Auto-set |

## Database

- `cafe_printer_configs` – must have `printnode_printer_id` for each cafe that prints
- `delivery_riders` – riders for delivery assignment
- `menu_items`, `orders`, `order_items` – standard schema
- `customer_notes` – per-customer notes (cafe_id + phone); run migration `20260319000001_customer_notes.sql`
