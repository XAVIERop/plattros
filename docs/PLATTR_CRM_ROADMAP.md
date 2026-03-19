# Plattr OS — CRM Features Roadmap

What's built, what's missing, and what to prioritize for CRM.

---

## 1. What's Already Built (CRM-related)

| Feature | Status | Location |
|---------|--------|----------|
| **Unified Customers** | ✅ Done | Orders + loyalty merge; name, phone, spend, order count, tier |
| **Customer tiers** | ✅ Done | foodie / gourmet / connoisseur from profiles or spend |
| **Win-back button** | ✅ Done | Customers table → "Win-back" sends WhatsApp via `whatsapp-automation-runner` |
| **Phone check-in** | ✅ Done | `/checkin/:slug` — QR scan, phone, points, feedback, referral link |
| **Loyalty settings** | ✅ Done | Points ratio, welcome points, referral points, review URLs |
| **Feedback list** | ✅ Done | LoyaltyPanel → Feedback tab; low-rating alerts + "Process now" |
| **Referrals list** | ✅ Done | LoyaltyPanel → Referrals tab (read-only) |
| **QR Code** | ✅ Done | LoyaltyPanel → QR tab; download/print for check-in |
| **Digital receipts** | ✅ Done | WhatsApp receipt on checkout; manual "Receipt" button in customer history |
| **crm_customers view** | ✅ Done | DB view with segment: VIP, Regular, New, At Risk |
| **whatsapp_outbox** | ✅ Done | Table for queued messages; `whatsapp-outbox-processor` |
| **Low-rating alerts** | ✅ Done | `process_low_rating_feedback` RPC queues WhatsApp to staff |

---

## 2. What's Missing / Incomplete

### 2.1 Campaigns (High impact)

| Gap | Description |
|-----|-------------|
| **Create campaign UI** | No form to create campaigns (name, type, message, target segment) |
| **Send campaign** | LoyaltyPanel shows campaigns but no "Create" or "Send" button. Docs say `smooth-task` — use `loyalty-whatsapp-send` instead |
| **Campaign targeting** | Need to select segment (VIP, At Risk, etc.) or customer list before send |
| **Campaign types** | promo, birthday, win_back — UI to pick type and template |

**Backend:** `loyalty-whatsapp-send` exists and sends to `loyalty_customers`. Needs to be wired from POS.

---

### 2.2 Rewards (Medium impact)

| Gap | Description |
|-----|-------------|
| **Add reward UI** | No "Add Reward" dialog. LoyaltyPanel only lists rewards |
| **Reward types** | free_item, discount, voucher — need form (name, type, points_cost) |
| **Redeem at POS** | No flow to redeem points for a reward during checkout |

---

### 2.3 Customer Segmentation (High impact)

| Gap | Description |
|-----|-------------|
| **Segment filter in UI** | `crm_customers` has segment (VIP, Regular, New, At Risk) but Customers view doesn't filter by it |
| **Segment badges** | No visual badge for segment in customer list |
| **At Risk count** | No dashboard widget for "X customers at risk" |
| **Last visit** | Show last order/check-in date in customer list |

---

### 2.4 CRM Actions (High impact)

| Gap | Description |
|-----|-------------|
| **Bulk WhatsApp** | Select multiple customers → send campaign (e.g. "At Risk" segment) |
| **Single customer message** | Send custom WhatsApp to one customer from their detail |
| **Birthday campaigns** | No birthday field or auto-birthday campaign |
| **Notes/tags** | No per-customer notes or custom tags |

---

### 2.5 Analytics & Reporting (Medium impact)

| Gap | Description |
|-----|-------------|
| **Loyalty metrics** | Repeat rate, avg visits, points awarded — not in dashboard |
| **Segment breakdown** | No chart: VIP vs Regular vs New vs At Risk |
| **Campaign performance** | Sent, opened, revenue — columns exist but no data if campaigns not sent |

---

### 2.6 Integration Gaps

| Gap | Description |
|-----|-------------|
| **smooth-task → loyalty-whatsapp-send** | LoyaltyPanel says "Requires smooth-task" — replace with `loyalty-whatsapp-send` |
| **whatsapp_bot_preferences** | Quiet hours, opted_out — ensure customers can opt out |
| **profiles.loyalty_tier** | Tier sync from loyalty — may need manual update or trigger |

---

## 3. Prioritized CRM Checklist

### P0 — Critical (unblock campaigns)

- [x] **Campaign creation UI** — Form: name, type (promo/birthday/win_back), message body
- [x] **Campaign send** — Button to invoke `loyalty-whatsapp-send` with campaign_id; show success/failure
- [ ] **Deploy loyalty-whatsapp-send** — Deploy to Plattr Supabase (yamjjiwifuiuhxzlnqzx); set WHATSAPP_ACCESS_TOKEN, WHATSAPP_PHONE_NUMBER_ID

### P1 — High value

- [x] **Segment filter in Customers** — Dropdown: All / VIP / Regular / New / At Risk
- [x] **Segment badge** — Show segment badge in customer row
- [x] **Add Reward UI** — Dialog: name, type, points_cost, discount_value (for discount type)
- [x] **Bulk send to segment** — Segment dropdown (All, At Risk, Birthday, VIP, New, Regular) when sending campaigns

### P2 — Polish

- [x] **Last visit column** — Show last_order_at or last_check_in_at in customer list
- [x] **At Risk count** — Dashboard KPI: "X customers at risk (no visit 30+ days)"
- [x] **Customer notes** — customer_notes table; Notes section in customer detail panel; Save button
- [x] **Redeem reward at POS** — RedeemRewardSection: redeem points for discount or free item; loyalty_redeem_reward RPC

### P3 — Nice to have

- [x] **Birthday field** — loyalty_customers.birthday; editable in customer detail panel; birthday segment in campaigns
- [x] **Loyalty analytics** — Repeat rate, avg visits, total points in Analytics view (Loyalty Metrics card)
- [ ] **Campaign performance** — Track open/revenue from loyalty_campaign_sends

---

## 4. Quick Reference

| Component | Status | Next action |
|-----------|--------|-------------|
| Campaigns | Read-only | Add Create + Send UI; wire loyalty-whatsapp-send |
| Rewards | Read-only | Add Create Reward dialog |
| Referrals | Read-only | Done (data flows from check-in) |
| Feedback | Read-only + Process | Done |
| Customers | Merge + Win-back | Add segment filter, badges, last visit |
| Segmentation | DB view only | Expose in UI |

---

## 5. Files to Touch

| File | Change |
|------|--------|
| `LoyaltyPanel.tsx` | Campaign create form; Send button; wire loyalty-whatsapp-send |
| `LoyaltyPanel.tsx` | Add Reward dialog |
| `App.tsx` (Customers) | Segment filter; segment badge; last visit column |
| `loyalty-whatsapp-send` | Deploy to Plattr Supabase; ensure secrets |
