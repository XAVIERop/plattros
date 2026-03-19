# Plattr OS – Business Model

---

## 1. Value Proposition

**For cafes:** A POS that works offline, costs less than hardware-heavy solutions, and runs on devices you already have.

| Problem | Solution |
|---------|----------|
| Internet drops during rush | Orders saved locally, sync when back online |
| Expensive terminals | Use any tablet/laptop; no lock-in hardware |
| Complex setup | Claim terminal, add staff, start taking orders in minutes |
| Lost orders when offline | Outbox queues orders; nothing is lost |

---

## 2. Target Customer

| Segment | Profile | Size (India) | Willingness to Pay |
|---------|---------|--------------|--------------------|
| **Campus cafes** | Food court stalls, canteens, kiosks | Large | Low–medium |
| **Standalone cafes** | Single-location coffee shops | Medium | Medium |
| **Small restaurants** | 1–2 outlets, dine-in + takeaway | Large | Medium |
| **Cloud kitchens** | Delivery-only, multi-brand | Growing | Medium–high |

**Primary:** Campus cafes, food courts, small outlets (1–3 terminals).  
**Secondary:** Standalone cafes, small restaurants.

---

## 3. Revenue Model

### Option A: SaaS (Subscription)
- **Monthly:** ₹X per terminal/month
- **Annual:** 2 months free (10 months pay)
- **Pros:** Recurring revenue, predictable
- **Cons:** Churn, need to prove value every month

### Option B: One-Time
- **Setup + licence:** ₹Y one-time
- **Pros:** Simple, no recurring for customer
- **Cons:** No recurring revenue, support cost unclear

### Option C: Hybrid
- **Setup fee:** ₹Z (one-time)
- **Monthly:** ₹X per terminal
- **Optional:** Print credits, premium support
- **Pros:** Balances upfront cash and recurring
- **Cons:** Slightly more complex to explain

### Option D: Transaction-Based
- **Per order:** ₹X per order or % of order value
- **Pros:** Scales with usage
- **Cons:** Harder to predict, can feel expensive at scale

### Recommended: Hybrid (Option C)
- Setup: ₹2,000–5,000 (one-time)
- Monthly: ₹499 / ₹799 / ₹999 (Starter / Growth / Pro)
- Optional: Extra terminals (₹200/terminal), print credits, priority support

---

## 4. Pricing Tiers

| Tier | Price/Month | Terminals | Features |
|------|-------------|-----------|----------|
| **Starter** | ₹499 | 1 | Orders, billing, kitchen display, cash/UPI/card |
| **Growth** | ₹799 | 2 | Everything in Starter + tables, delivery ops, modifiers, print |
| **Pro** | ₹999 | 3 | Everything in Growth + analytics, customers, inventory, priority support |

### Tier Details

**Starter (₹499)**
- 1 terminal
- Order capture, cart, billing
- Kitchen display
- Payment: cash, UPI, card, split
- Offline-first sync
- Basic reporting

**Growth (₹799)**
- 2 terminals
- All Starter features
- Table management
- Delivery ops + rider assignment
- Modifier groups (size, milk, etc.)
- KOT + receipt printing
- Menu organizer

**Pro (₹999)**
- 3 terminals
- All Growth features
- Analytics dashboard
- Customer summary
- Inventory / stock management
- Priority support
- Custom branding

---

## 5. Cost Structure

| Cost | Type | Notes |
|------|------|-------|
| **Hosting** | Fixed | Supabase, Vercel, edge functions |
| **Print** | Variable | PrintNode or similar API costs |
| **Support** | Variable | Time per ticket |
| **Payments** | Variable | % of transaction (gateway) |
| **Sales** | Variable | Direct vs. channel |

**Target:** ~70% gross margin after hosting and support.

---

## 6. Unit Economics (Target)

| Metric | Target |
|--------|--------|
| **CAC** (Customer acquisition cost) | < ₹2,000 |
| **LTV** (Lifetime value) | > ₹10,000 |
| **LTV:CAC** | > 3:1 |
| **Payback period** | < 6 months |
| **Gross margin** | > 70% |

---

## 7. Key Metrics

| Metric | Definition |
|--------|------------|
| **MRR** | Monthly recurring revenue |
| **Churn** | % customers lost per month |
| **ARPU** | Revenue per customer per month |
| **Terminals** | Total active terminals |
| **Orders** | Orders processed (usage proxy) |
| **NPS** | Net promoter score |

---

## 8. Revenue Streams (Summary)

1. **Primary:** Monthly subscription per terminal
2. **Secondary:** Setup/onboarding fee
3. **Optional:** Print credits, premium support, custom branding
4. **Future:** Transaction fees, marketplace

---

## 9. Decision Framework

| Question | Decision |
|----------|----------|
| B2B or B2C? | B2B (cafes, not end consumers) |
| Direct or channel? | Start direct; add channels later |
| India-first? | Yes (campus, food courts, small outlets) |
| Free vs. paid trial? | 14-day free trial, then paid |
| Self-serve or sales-assisted? | Sales-assisted for first 50; then self-serve |

---

## 10. Next: Define Numbers

| Item | Action |
|------|--------|
| **Setup fee** | Set ₹X based on onboarding cost |
| **Monthly price** | Set ₹Y based on value and competition |
| **Trial length** | 14 days recommended |
| **Discounts** | Annual (2 months free), early adopters |
| **Refund policy** | e.g. 7-day money-back |

---

## 11. One-Page Summary

```
PRODUCT:     Offline-first POS for cafes
CUSTOMER:    Campus cafes, food courts, small outlets (1–3 terminals)
VALUE:       Works offline, no hardware lock-in, low cost
REVENUE:     Setup fee + monthly subscription
PRICE:       ₹499 (1 terminal) | ₹799 (2) | ₹999 (3 terminals)
MODEL:       Hybrid SaaS
TARGET:      LTV > ₹10K, CAC < ₹2K, LTV:CAC > 3
```
