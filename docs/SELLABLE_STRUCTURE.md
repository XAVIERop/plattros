# Bhursas POS – Structure to Make It Sellable

A framework to package and sell the POS as a commercial product to cafes and restaurants.

---

## 1. Product Positioning

| Element | Definition |
|--------|------------|
| **Name** | Plattr OS (or white-label: "[Brand] POS") |
| **Tagline** | "Offline-first POS for cafes. Works when the internet doesn't." |
| **Target** | Single-location cafes, food courts, campus outlets, small restaurants |
| **Differentiator** | Offline-first, no monthly hardware fees, works on any tablet/laptop |

---

## 2. Packaging Tiers

### Starter – ₹499/month
- 1 terminal
- Orders, billing, kitchen display
- Cash/UPI/Card/split
- Offline-first sync, basic reporting

### Growth – ₹799/month
- 2 terminals
- Tables, delivery ops, modifiers
- Print (KOT + receipt)
- Menu organizer

### Pro – ₹999/month
- 3 terminals
- Analytics, customers, inventory
- Priority support
- Custom branding

---

## 3. Pricing Models (choose one or hybrid)

| Model | Pros | Cons |
|-------|------|------|
| **One-time** | Simple, no recurring | No ongoing revenue |
| **Monthly SaaS** | Predictable MRR | Churn risk |
| **Transaction %** | Scales with customer | Harder to explain |
| **Hybrid** | Setup fee + monthly | Common for SMB |

**Suggested:** Setup fee (₹X) + monthly (₹Y/terminal) + optional print credits.

---

## 4. Buyer Journey

```
Awareness → Interest → Trial → Purchase → Onboarding → Success
```

| Stage | Action |
|-------|--------|
| **Awareness** | Landing page, demo video, case study |
| **Interest** | Feature comparison, pricing page |
| **Trial** | 14-day free trial, demo cafe ID |
| **Purchase** | Checkout, contract, payment |
| **Onboarding** | Cafe setup, terminal claim, first order |
| **Success** | Training, support, upsell |

---

## 5. Pre-Sales Assets

| Asset | Purpose |
|-------|---------|
| **Landing page** | Capture leads, explain value |
| **Demo environment** | Live sandbox with sample cafe |
| **Pricing page** | Clear tiers, no surprises |
| **Feature matrix** | vs. competitors (Square, Zomato POS, etc.) |
| **Case study** | "Cafe X cut order errors by Y%" |
| **ROI calculator** | Time saved, errors avoided |

---

## 6. Post-Sale Structure

### Onboarding
- [ ] Welcome email + setup checklist
- [ ] Cafe creation (admin)
- [ ] Terminal claim walkthrough
- [ ] First order flow
- [ ] Print setup (if applicable)

### Support
- [ ] Help center / FAQ
- [ ] Email support (Starter)
- [ ] Chat/phone (Growth+)
- [ ] Dedicated CSM (Pro)

### Billing
- [ ] Invoice generation
- [ ] Payment links (Razorpay/Stripe)
- [ ] Renewal reminders

---

## 7. Technical Requirements for Selling

| Item | Status / Action |
|------|-----------------|
| **Multi-tenant** | Cafes isolated by `cafe_id` |
| **White-label** | Theme (logo, colors) per cafe |
| **Billing integration** | Stripe/Razorpay for subscriptions |
| **Usage metering** | Terminals, orders, prints |
| **Trial flow** | Time-limited or feature-limited |
| **Self-serve signup** | Or sales-assisted only |

---

## 8. Legal & Compliance

- [ ] Terms of Service
- [ ] Privacy Policy
- [ ] Refund policy
- [ ] Data handling (PCI if storing cards)
- [ ] GST invoicing (India)

---

## 9. Go-to-Market Checklist

- [ ] Domain + hosting for marketing site
- [ ] Demo instance (always-on sandbox)
- [ ] Payment gateway for purchases
- [ ] CRM for leads (e.g. HubSpot, Notion)
- [ ] Support ticketing (e.g. Zendesk, Freshdesk)
- [ ] Analytics (conversions, trial → paid)

---

## 10. Quick Wins to Ship First

1. **Landing page** – Single page: problem, solution, CTA
2. **Demo mode** – `VITE_BHURSAS_SYNC_MODE=demo` + sample cafe
3. **Pricing page** – 3 tiers, clear features
4. **Contact form** – "Request demo" or "Start trial"
5. **Onboarding doc** – Step-by-step for new cafes

---

## 11. File Structure (suggested)

```
apps/bhursas-pos/
├── docs/
│   ├── SELLABLE_STRUCTURE.md    (this file)
│   ├── MODIFIERS_SETUP.md
│   ├── ONBOARDING.md            (create)
│   └── PRICING_TIERS.md         (create)
├── marketing/                    (optional, separate repo)
│   ├── landing/
│   ├── pricing/
│   └── case-studies/
└── ...
```

---

## 12. Next Steps (prioritized)

1. **Define pricing** – Tiers + numbers
2. **Build landing page** – Even a simple one
3. **Create demo flow** – One-click trial
4. **Document onboarding** – For first 10 customers
5. **Add billing** – Stripe/Razorpay subscription
6. **Legal docs** – ToS, Privacy, Refund
