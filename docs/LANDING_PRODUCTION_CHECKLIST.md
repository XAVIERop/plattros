# Landing Page — Production Readiness Checklist

## ✅ Done

- [x] Hero, features, tools, integrations, stats, testimonials, FAQ, CTA, footer
- [x] Mobile responsive + hamburger menu
- [x] Smooth scroll + reveal-on-scroll
- [x] Digital Wellness design system
- [x] Newsletter form → Supabase `landing_newsletter` table + toast feedback
- [x] SEO meta (description, OG, Twitter) + theme-color
- [x] Contact mailto (hello@plattrtechnologies.com)
- [x] Legal pages: /terms, /privacy, /refund

---

## 🔴 Critical (Must Have)

### 1. SEO & Meta — ✅ Done
- [x] Meta description, OG, Twitter cards, theme-color
- [x] **Canonical URL** — https://plattros.in

### 2. Newsletter Signup — ✅ Done
- [x] Supabase `landing_newsletter` table + RLS
- [x] Toast feedback + loading state

### 3. Contact & Legal Links — ✅ Done
- [x] Contact mailto
- [x] /terms, /privacy, /refund pages

### 4. Broken / Placeholder Links
- [ ] **Blog, About us, Careers** — Still link to /landing; create pages when ready
- [x] **Terms, Privacy, Refund** — Done
- [ ] **"View all testimonials"** — Links to #testimonials; consider dedicated page later

---

## 🟡 Important (Should Have)

### 5. Content
- [ ] **Testimonials** — Replace placeholder quotes with real customer quotes (or remove "Cafe owner" / "Restaurant owner" anonymized ones)
- [ ] **Integration logos** — Replace text placeholders with actual POS/billing logos (Restroworks, Petpooja, DotPe, etc.)
- [ ] **Stats (91%, 73%, 85%)** — Add disclaimer "Based on customer feedback" or source, or use real data

### 6. Accessibility
- [ ] **Focus states** — Ensure all interactive elements have visible focus rings
- [ ] **ARIA labels** — Add `aria-label` to icon-only buttons (e.g. mobile menu)
- [ ] **Skip link** — Add "Skip to content" for keyboard users

### 7. Performance
- [ ] **Font loading** — Add `font-display: swap` to Google Fonts URL to avoid FOIT
- [ ] **Lazy load** — If adding images, use `loading="lazy"`

### 8. Analytics (Optional)
- [ ] **Google Analytics / Plausible** — Track page views, CTA clicks, form submissions

---

## 🟢 Nice to Have

### 9. Favicon & PWA
- [ ] **Favicon** — Ensure `manifest.json` and favicon match landing theme (currently `#0f172a`)
- [ ] **Theme color** — Update `theme-color` in `index.html` to `#FDFCF8` or `#292524` for landing

### 10. Forms
- [ ] **Demo booking** — "Book a demo" could open Calendly embed or form
- [ ] **Honeypot** — Add hidden field to newsletter form for spam protection

---

## Deploy Steps

1. Run migration: `supabase db push` or apply `20260320000001_landing_newsletter.sql`
2. Ensure `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` are set for the landing build
3. Build: `npm run build` (from `apps/bhursas-pos`)
4. Deploy the `dist/` output to Hostinger (static hosting or connect repo)
5. Point plattros.in to the deployed site (DNS: A record or CNAME per Hostinger docs)
