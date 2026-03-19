# Zero Print Cost – Options for Plattr OS

Right now, Plattr OS uses **PrintNode** (cloud) via `printnode-secure`, which charges per print. To get **₹0 print cost**, use one of these approaches.

---

## Option 1: Local Print Server (Recommended)

Use the existing **`server/`** thermal printer service. It talks directly to the printer (USB/network) and costs nothing.

**Setup:**
1. Install deps and run a print server on the same machine as the POS (or on the cafe’s LAN):
   ```bash
   cd server
   npm install express cors node-thermal-printer
   node local-print-server.js   # port 8080
   # or: node thermal-printer-server.js  # port 3001
   ```
2. Configure the server with `PRINTER_IP`, `PRINTER_PORT`, or USB interface in `.env`.
3. Set `VITE_PRINT_SERVER_URL=http://localhost:8080` (or 3001) in the POS `.env.local`.

**Cost:** ₹0 (no cloud service).

---

## Option 2: Direct Network Printer

If the thermal printer has an IP (Wi‑Fi/Ethernet), send ESC/POS directly to it.

**Requirements:**
- `cafe_printer_configs` has `printer_ip` and `printer_port` (e.g. 9100).
- A small local proxy or native app that can open raw TCP sockets (browsers cannot).

**Flow:**
- POS → local proxy (e.g. `localhost:8080`) → printer IP:9100  
- Or POS → Electron/native app → printer IP:9100  

**Cost:** ₹0.

---

## Option 3: Browser Print (`window.print()`)

Use the system print dialog for receipts.

**Pros:** No backend, no cloud, no cost.  
**Cons:** User must choose printer each time; not ideal for KOT; printer must be on the same device.

**Implementation:** Add a “Print via browser” path in `printerAdapter.ts` that opens a hidden iframe with the receipt content and calls `window.print()`.

**Cost:** ₹0.

---

## Option 4: Local Print Agent (Self‑hosted)

Run a small agent on the cafe’s network that:
1. Polls your backend for print jobs (or receives webhooks).
2. Sends them to a local USB/network printer.

Your edge function would write jobs to a table instead of calling PrintNode; the agent reads and prints them.

**Cost:** ₹0 (no PrintNode; only your existing infra).

---

## Implemented: Local Print First

`printerAdapter.ts` now tries the local print server **before** PrintNode:

1. If `VITE_PRINT_SERVER_URL` is set (e.g. `http://localhost:3001`), it sends `POST /print` with `{ content, type }`.
2. On success → done (₹0 cost).
3. On failure or if env not set → fall back to `printnode-secure`.

**To use ₹0 printing:**
1. Run the thermal print server: `cd server && node local-print-server.js` (port 8080) or `node thermal-printer-server.js` (port 3001).
2. Set `VITE_PRINT_SERVER_URL=http://localhost:8080` (or 3001) in the POS `.env.local`.
3. Configure the server with your printer (USB or network via `PRINTER_IP`, `PRINTER_PORT`, etc.).
