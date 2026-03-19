# Product Name & Business Model

A structured guide for naming and monetizing the offline-first POS product.

---

## Part 1: Product Name

### Current State
- **Internal:** Bhursas POS / Bhursa's POS (cafe-specific placeholder)
- **Need:** A product name that works for any cafe, is memorable, and supports branding

### Name Options

| Name | Tagline | Pros | Cons |
|------|---------|------|------|
| **Counter** | "POS that never stops" | Simple, clear, universal | Generic, may conflict with existing apps |
| **Kiosk** | "Offline-first POS for cafes" | Tech-forward, familiar | Can imply self-service only |
| **Chai** | "Your cafe's POS" | Indian, warm, memorable | Might limit to chai/cafe only |
| **ChaiPoint** | "Point of sale, point of service" | Indian + functional | ChaiPoint brand exists |
| **Tapri** | "The tapri POS" | Very Indian, relatable | Informal, might not scale for premium |
| **Reelo** | "Reel in every order" | Unique, short, modern | Needs explanation |
| **FlowPOS** | "Orders flow, even offline" | Describes flow, offline hint | Slightly generic |
| **Bite** | "Quick POS for quick bites" | Short, punchy | Might conflict with food apps |
| **CafeOS** | "Operating system for your cafe" | Clear, professional | "OS" can feel heavy |
| **Spot** | "Your spot for orders" | Simple, flexible | Very generic |
| **Brew** | "Brew orders, not problems" | Cafe vibe, memorable | Coffee-focused |
| **Grid** | "Grid for your cafe" | Modern, tech | Abstract |
| **Kettle** | "Always brewing" | Warm, cafe vibe | Niche |
| **FoodClub POS** | "POS by FoodClub" | Leverages MUJ Food Club brand | Ties to parent; may limit scope |
| **CafeStack** | "Stack your cafe" | Modern, SaaS feel | Slightly long |
| **Plattr OS** ✓ | "Operating system for your cafe" | Platform + matter; modern, professional | — |

### Recommended Shortlist

1. **Counter** — Clean, universal, "POS that never stops" works well
2. **Brew** — Strong cafe vibe, memorable, "Brew orders, not problems"
3. **Reelo** — Unique, ownable, good for loyalty/orders wordplay
4. **FlowPOS** — Clear value (flow + offline), professional
5. **CafeStack** — Modern SaaS, "Stack your cafe" is strong

### Final Decision

**Product Name:** **Plattr OS**  
**Tagline:** *"Operating system for your cafe"* or *"POS that never stops"*

Plattr = platform + matter; OS = operating system. Clean, modern, professional.

---

## Part 2: Business Model

### 2.1 Value Proposition

| Problem | Solution |
|---------|----------|
| Internet drops during rush | Orders saved locally, sync when back online |
| Expensive terminals | Use any tablet/laptop; no lock-in hardware |
| Complex setup | Claim terminal, add staff, start taking orders in minutes |
| Lost orders when offline | Outbox queues orders; nothing is lost |
| Fragmented tools | Orders, menu, tables, delivery, kitchen in one app |

### 2.2 Target Customer

| Segment | Profile | Size (India) | Willingness to Pay |
|---------|---------|--------------|--------------------|
| **Campus cafes** | Food court stalls, canteens, kiosks | Large | Low–medium |
| **Standalone cafes** | Single-location coffee shops | Medium | Medium |
| **Small restaurants** | 1–2 outlets, dine-in + takeaway | Large | Medium |
| **Cloud kitchens** | Delivery-only, multi-brand | Growing | Medium–high |

**Primary:** Campus cafes, food courts, small outlets (1–3 terminals).  
**Secondary:** Standalone cafes, small restaurants.

### 2.3 Competitive Landscape (India)

| Provider | Price Range | Notes |
|----------|-------------|-------|
| **Basic POS** | ₹2,999–6,000/year | Minimal features |
| **Standard POS** | ₹7,000–15,000/year | Inventory + reports |
| **Advanced POS** | ₹15,000–35,000/year | Cloud + integrations |
| **RoyalPOS Bharat** | ₹1,999/year | Basic |
| **RoyalPOS Premium** | ₹5,000–6,500/year | With aggregator integration |
| **possoftware.in** | ₹12,900–24,900 | One-time |

**Our positioning:** Affordable, offline-first, no hardware lock-in. Target ₹499–999/month.

### 2.4 Revenue Model: Hybrid SaaS

| Component | Amount | Notes |
|-----------|--------|-------|
| **Setup fee** | ₹2,000–5,000 (one-time) | Onboarding, training, config |
| **Monthly subscription** | Tier-based (see below) | Primary revenue |
| **Extra terminals** | ₹200/terminal/month | Beyond tier limit |
| **Print credits** | Optional add-on | If usage exceeds base |
| **Priority support** | ₹299/month add-on | Pro tier or standalone |

### 2.5 Pricing Tiers

| Tier | Price/Month | Terminals | Features |
|------|-------------|-----------|----------|
| **Starter** | ₹499 | 1 | Orders, billing, kitchen display, cash/UPI/card, offline sync |
| **Growth** | ₹799 | 2 | + Tables, delivery ops, modifiers, KOT + receipt print |
| **Pro** | ₹999 | 3 | + Analytics, customers, inventory, priority support |

**Annual discount:** 2 months free (pay 10, get 12).

### 2.6 Tier Details

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

### 2.7 Cost Structure

| Cost | Type | Est. Notes |
|------|------|------------|
| **Hosting** | Fixed | Supabase, Vercel, edge functions (~₹2–5K/month at scale) |
| **Print** | Variable | PrintNode or similar API (~₹0.50–1/print) |
| **Support** | Variable | Time per ticket |
| **Payments** | Variable | Gateway % if integrated |
| **Sales** | Variable | Direct vs. channel |

**Target:** ~70% gross margin after hosting and support.

### 2.8 Unit Economics

| Metric | Target |
|--------|--------|
| **CAC** | < ₹2,000 |
| **LTV** | > ₹10,000 |
| **LTV:CAC** | > 3:1 |
| **Payback period** | < 6 months |
| **Gross margin** | > 70% |

### 2.9 Go-to-Market

| Phase | Approach |
|-------|----------|
| **0–50 customers** | Sales-assisted, direct outreach |
| **50–200** | Self-serve + light-touch onboarding |
| **200+** | Channel partners, campus/food court aggregators |

**Trial:** 14-day free trial, no card required.  
**Refund:** 7-day money-back if not satisfied.

### 2.10 Revenue Streams (Summary)

1. **Primary:** Monthly subscription per tier
2. **Secondary:** Setup/onboarding fee
3. **Optional:** Extra terminals, print credits, priority support
4. **Future:** Transaction fees, marketplace, loyalty upsells

---

## Part 3: One-Page Summary

```
PRODUCT:     Plattr OS – Offline-first POS for cafes
CUSTOMER:    Campus cafes, food courts, small outlets (1–3 terminals)
VALUE:       Works offline, no hardware lock-in, low cost
REVENUE:     Setup fee + monthly subscription
PRICE:       ₹499 (1 terminal) | ₹799 (2) | ₹999 (3 terminals)
MODEL:       Hybrid SaaS
TARGET:      LTV > ₹10K, CAC < ₹2K, LTV:CAC > 3
```

---

## Part 4: Next Steps

1. **Name:** Plattr OS ✓
2. **Setup fee:** Set ₹X based on onboarding cost (₹2K–5K range)
3. **Trial:** 14 days, no card
4. **Landing page:** Product name + value prop + pricing
5. **Billing:** Integrate Stripe/Razorpay for subscriptions
