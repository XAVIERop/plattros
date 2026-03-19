# Loyalty Loop Integration – Bhursas POS

## Overview

Integrate all Loyalty Loop (Reelo-style) features into Plattr OS so cafe owners get a single product: POS + loyalty in one.

## Loyalty Loop Features (from `loyalty-loop/` app)

| Feature | Tables / RPC | Description |
|---------|--------------|-------------|
| **Phone check-in** | `loyalty_check_in`, `loyalty_customers`, `loyalty_check_ins` | Customers scan QR, enter phone, earn points |
| **Customers** | `loyalty_customers` | List of loyalty customers with visits, points, tags (VIP, Regular, New, At Risk) |
| **Campaigns** | `loyalty_campaigns`, `loyalty_campaign_sends` | Promo, birthday, win-back campaigns; send via WhatsApp (smooth-task) |
| **Rewards** | `loyalty_rewards` | Points-based rewards (free item, discount, voucher) |
| **Referrals** | `loyalty_referrals` | Referrer + referred get bonus points on first check-in |
| **Feedback** | `loyalty_feedback` | Post-check-in ratings and comments |
| **Analytics** | Derived from loyalty tables | Repeat rate, visits, points awarded |
| **QR Code** | – | Generate/download QR for check-in URL |
| **Loyalty Settings** | `loyalty_settings`, `cafes` | Points ratio, welcome points, referral points, review URLs |

## Database (Already Migrated)

- `20260312000001_loyalty_loop_phone_checkin.sql` – loyalty_customers, loyalty_check_ins, loyalty_feedback, loyalty_check_in RPC
- `20260315000001_loyalty_campaigns_rewards_settings.sql` – loyalty_campaigns, loyalty_rewards, loyalty_settings
- `20260315000002_loyalty_reelo_features.sql` – loyalty_campaign_sends, loyalty_referrals, loyalty_settings extensions, loyalty_check_in with referral

## Integration Strategy

### 1. Add Loyalty Views to POS

Plattr OS uses `activeView` state. Add new views:

- `loyalty_customers` – loyalty customer list (or merge into existing `customers`)
- `loyalty_campaigns` – create/send campaigns
- `loyalty_rewards` – manage rewards
- `loyalty_referrals` – referral history
- `loyalty_feedback` – feedback list
- `loyalty_qr` – QR code for check-in
- `loyalty_settings` – points config

### 2. Public Check-In Page

Customers scan QR → `/checkin/:slug` (no auth). Options:

- **A)** Add `react-router-dom`; if path starts with `/checkin/`, render CheckIn component
- **B)** Deploy CheckIn as separate route in same app (e.g. Vite multi-page or router)

### 3. Dependencies

- `@tanstack/react-query` – data fetching (loyalty-loop uses it)
- `qrcode.react` – QR code for loyalty_qr view

### 4. Auth / Cafe Scope

- Use `cafeId` from `useCafeSession` (already in POS)
- All loyalty queries use `cafe_id = cafeId`

### 5. Campaign Sends

- loyalty-loop uses `supabase.functions.invoke("smooth-task", ...)` – ensure this edge function exists or replace with equivalent (e.g. `loyalty-whatsapp-send` or similar)

## Implementation Status

### Done
- **Loyalty nav** – Heart icon in sidebar; "Loyalty" view with sub-tabs
- **LoyaltyPanel** – Campaigns, Rewards, Referrals, Feedback, QR Code, Settings (Customers merged into main Customers view)
- **Unified Customers** – Single customer list merging orders + loyalty_customers; tier from profiles.loyalty_tier (foodie, gourmet, connoisseur)
- **Public Check-In** – `/checkin/:slug` route; phone check-in, feedback, referral link
- **Router** – React Router for CheckIn; QueryClientProvider for React Query
- **Dependencies** – @tanstack/react-query, qrcode.react, react-router-dom

### Remaining
- **Campaign creation/send** – UI to create campaigns and send via smooth-task (or equivalent) edge function
- **Reward creation** – Add Reward dialog (loyalty-loop has it; can be ported)
- **Loyalty analytics** – Optional: extend dashboard with loyalty metrics

## UI / Styling

- Plattr OS uses **vanilla CSS** (no Tailwind)
- Use existing CSS variables: `--text-muted`, `--border-default`, etc.
- Match POS card/panel styles
