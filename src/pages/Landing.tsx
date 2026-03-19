import { Link } from "react-router-dom";
import { useEffect, useRef, useState } from "react";
import { toast } from "sonner";
import { supabase } from "@/lib/supabase/client";
import "./Landing.css";

const CONTACT_EMAIL = "hello@plattrtechnologies.com";

const FAQ_ITEMS = [
  {
    q: "What is Plattr OS?",
    a: "Plattr OS is an all-in-one point of sale and customer engagement platform for cafes and restaurants. It combines POS, loyalty programs, WhatsApp marketing, and CRM in a single offline-first system.",
  },
  {
    q: "Who can use Plattr?",
    a: "Any cafe, restaurant, bakery, or food business that wants to grow revenue through loyalty and marketing—without relying on discounting. From single-outlet cafes to multi-location chains.",
  },
  {
    q: "How does the loyalty program work?",
    a: "Customers earn points on every visit. You can set up rewards, tiers, and referral bonuses. Points sync automatically when orders are placed through the POS, and you can send campaigns via WhatsApp.",
  },
  {
    q: "Which POS systems does Plattr integrate with?",
    a: "Plattr includes its own POS. We also integrate with popular billing software—contact us for the full list of supported systems.",
  },
];

const INTEGRATION_NAMES = [
  "Plattr POS",
  "Custom API",
  "Restroworks",
  "Petpooja",
  "DotPe",
  "Quickbill",
  "Billing",
  "POS",
];

const TESTIMONIALS = [
  {
    quote: "Building loyalty without giving discounts.",
    author: "Rahul Singh",
    role: "Founder of The Beer Cafe",
    company: "The Beer Cafe",
  },
  {
    quote: "Plattr transformed how we engage our customers. Repeat visits are up significantly.",
    author: "Cafe owner",
    role: "Multi-outlet cafe",
    company: "Café",
  },
  {
    quote: "Offline-first POS with WhatsApp campaigns—exactly what we needed.",
    author: "Restaurant owner",
    role: "Fine dining",
    company: "Restaurant",
  },
];

export default function Landing() {
  const containerRef = useRef<HTMLDivElement>(null);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [faqOpen, setFaqOpen] = useState<number | null>(null);
  const [newsletterLoading, setNewsletterLoading] = useState(false);

  useEffect(() => {
    document.documentElement.style.scrollBehavior = "smooth";
    return () => {
      document.documentElement.style.scrollBehavior = "";
    };
  }, []);

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const targets = el.querySelectorAll(".landing-reveal");
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) entry.target.classList.add("visible");
        });
      },
      { threshold: 0.1, rootMargin: "0px 0px -50px 0px" }
    );
    targets.forEach((t) => observer.observe(t));
    return () => observer.disconnect();
  }, []);

  const scrollTo = (id: string) => {
    const el = document.getElementById(id);
    el?.scrollIntoView({ behavior: "smooth" });
    setMobileMenuOpen(false);
  };

  const handleNewsletterSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = e.currentTarget;
    const email = (form.elements.namedItem("newsletter-email") as HTMLInputElement)?.value?.trim();
    if (!email) return;
    setNewsletterLoading(true);
    try {
      const { error } = await supabase.from("landing_newsletter").insert({ email, source: "landing_footer" });
      if (error) throw error;
      toast.success("Thanks! You're on the list.");
      form.reset();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Something went wrong";
      if (msg.includes("duplicate") || msg.includes("unique")) {
        toast.info("You're already subscribed.");
      } else {
        toast.error("Couldn't subscribe. Try again or email us directly.");
      }
    } finally {
      setNewsletterLoading(false);
    }
  };

  return (
    <div className="landing" ref={containerRef}>
      <header className="landing-header">
        <Link to="/landing" className="landing-logo">
          Plattr OS
        </Link>
        <nav className="landing-nav">
          <button type="button" onClick={() => scrollTo("features")}>
            Product
          </button>
          <button type="button" onClick={() => scrollTo("solutions")}>
            Solutions
          </button>
          <button type="button" onClick={() => scrollTo("integrations")}>
            Integrations
          </button>
          <button type="button" onClick={() => scrollTo("testimonials")}>
            Testimonials
          </button>
          <button type="button" onClick={() => scrollTo("faq")}>
            FAQ
          </button>
          <Link to="/pricing">Pricing</Link>
        </nav>
        <div className="landing-header-actions">
          <Link to="/" className="landing-cta-pill">
            <span className="pulse" />
            System Online
          </Link>
          <button
            type="button"
            className="landing-mobile-menu-btn"
            aria-label="Toggle menu"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          >
            <span />
            <span />
            <span />
          </button>
        </div>
      </header>

      {/* Mobile menu */}
      <div className={`landing-mobile-menu ${mobileMenuOpen ? "open" : ""}`}>
        <button type="button" onClick={() => scrollTo("features")}>
          Product
        </button>
        <button type="button" onClick={() => scrollTo("solutions")}>
          Solutions
        </button>
        <button type="button" onClick={() => scrollTo("integrations")}>
          Integrations
        </button>
        <button type="button" onClick={() => scrollTo("testimonials")}>
          Testimonials
        </button>
        <button type="button" onClick={() => scrollTo("faq")}>
          FAQ
        </button>
        <Link to="/pricing" onClick={() => setMobileMenuOpen(false)}>
          Pricing
        </Link>
        <Link to="/" onClick={() => setMobileMenuOpen(false)}>
          Open POS
        </Link>
      </div>

      {/* Hero */}
      <section className="landing-hero">
        <div className="landing-hero-bg" aria-hidden="true">
          <div className="landing-blob landing-blob-1" />
          <div className="landing-blob landing-blob-2" />
          <div className="landing-blob landing-blob-3" />
        </div>
        <div className="landing-hero-content landing-reveal">
          <h1>
            Grow your restaurant's revenue <span className="landing-accent">without</span> discounting
          </h1>
          <p>
            Transform first-time diners into loyal regulars with personalized marketing, loyalty programs, and data-driven insights.
          </p>
        </div>
        <p className="landing-trust-bar landing-reveal">Trusted by growing cafes</p>
        <div className="landing-hero-cta">
          <Link to="/" className="landing-hero-cta-btn">
            Try for free
          </Link>
        </div>
        <div className="landing-wave-container">
          <div className="landing-wave-curve" />
        </div>
      </section>

      {/* Features */}
      <section id="features" className="landing-features">
        <h2 className="landing-reveal">How Plattr helps restaurateurs</h2>
        <div className="landing-features-grid">
          <div className="landing-feature-card landing-reveal">
            <div className="landing-feature-card-inner">
              <span className="label">Loyalty program</span>
              <h3>Build a loyal customer base that drives revenue</h3>
              <ul>
                <li>Own your audience by building a community of loyal customers</li>
                <li>Reduce the cost of new customer acquisition through referrals</li>
                <li>Reward loyal customers instead of giving discounts to everyone</li>
              </ul>
              <span className="action-pill">View</span>
            </div>
          </div>
          <div className="landing-feature-card landing-reveal">
            <div className="landing-feature-card-inner">
              <span className="label">Guest experience</span>
              <h3>Turn guest experiences into lasting relationships</h3>
              <ul>
                <li>Engage customers with timely, personalized communication</li>
                <li>Build a strong review loop with real-time feedback alerts</li>
                <li>Address issues early to prevent losing customers</li>
              </ul>
              <span className="action-pill">View</span>
            </div>
          </div>
          <div className="landing-feature-card landing-reveal">
            <div className="landing-feature-card-inner">
              <span className="label">Campaigns</span>
              <h3>Stay top-of-mind — be your customer's #1 choice</h3>
              <ul>
                <li>Send campaigns in under 2 mins with ready-to-use templates</li>
                <li>Launch high-ROI campaigns with minimal effort</li>
                <li>Measure every campaign's performance with ease</li>
              </ul>
              <span className="action-pill">View</span>
            </div>
          </div>
          <div className="landing-feature-card landing-reveal">
            <div className="landing-feature-card-inner">
              <span className="label">Data & insights</span>
              <h3>Make data-driven decisions that boost profitability</h3>
              <ul>
                <li>Centralize data from POS, loyalty, and campaigns</li>
                <li>Predictable sales with customer behavior insights</li>
                <li>Optimize menus based on what sells</li>
              </ul>
              <span className="action-pill">View</span>
            </div>
          </div>
        </div>
      </section>

      {/* All tools */}
      <section className="landing-tools">
        <h2 className="landing-reveal">All the tools you need to grow faster</h2>
        <div className="landing-tools-grid">
          {["Restaurant CRM", "Loyalty program", "Campaigns", "WhatsApp marketing", "QR code", "POS"].map((t) => (
            <div key={t} className="landing-tool landing-reveal">
              {t}
            </div>
          ))}
        </div>
      </section>

      {/* Integrations */}
      <section id="integrations" className="landing-integrations">
        <h2 className="landing-reveal">Integrate with your billing software in under 2 mins</h2>
        <div className="landing-integrations-grid">
          {INTEGRATION_NAMES.map((name) => (
            <div key={name} className="landing-integration-card landing-reveal">
              {name}
            </div>
          ))}
        </div>
      </section>

      {/* Stats */}
      <section id="solutions" className="landing-stats">
        <h2 className="landing-reveal">Why restaurants love Plattr</h2>
        <div className="landing-stats-grid">
          <div className="landing-stat landing-reveal">
            <span className="landing-stat-value">91%</span>
            <h3>More customers</h3>
            <p>Restaurants see more repeat visits with loyalty and referral programs</p>
          </div>
          <div className="landing-stat landing-reveal">
            <span className="landing-stat-value">73%</span>
            <h3>More revenue</h3>
            <p>Data-driven campaigns and personalization drive higher order values</p>
          </div>
          <div className="landing-stat landing-reveal">
            <span className="landing-stat-value">85%</span>
            <h3>Stronger brand</h3>
            <p>Own your audience and build lasting customer relationships</p>
          </div>
        </div>
      </section>

      {/* Testimonials */}
      <section id="testimonials" className="landing-testimonials">
        <h2 className="landing-reveal">Trusted by growing restaurants</h2>
        <div className="landing-testimonials-grid">
          {TESTIMONIALS.map((t, i) => (
            <div key={i} className="landing-testimonial landing-reveal">
              <p className="landing-testimonial-quote">"{t.quote}"</p>
              <p className="landing-testimonial-author">{t.author}</p>
              <p className="landing-testimonial-role">{t.role}</p>
              <span className="landing-testimonial-tag">{t.company}</span>
            </div>
          ))}
        </div>
        <Link to="/landing#testimonials" className="landing-testimonials-cta">
          View all testimonials →
        </Link>
      </section>

      {/* FAQ */}
      <section id="faq" className="landing-faq">
        <h2 className="landing-reveal">FAQ</h2>
        <div className="landing-faq-list">
          {FAQ_ITEMS.map((item, i) => (
            <div
              key={i}
              className={`landing-faq-item ${faqOpen === i ? "open" : ""}`}
              onClick={() => setFaqOpen(faqOpen === i ? null : i)}
            >
              <div className="landing-faq-q">
                <span>{item.q}</span>
                <span className="landing-faq-icon">{faqOpen === i ? "−" : "+"}</span>
              </div>
              <div className="landing-faq-a">
                <p>{item.a}</p>
              </div>
            </div>
          ))}
        </div>
        <div className="landing-faq-cta">
          <p>Do you have more questions?</p>
          <Link to="/pricing" className="landing-faq-demo-btn">
            Book a free demo
          </Link>
        </div>
      </section>

      {/* CTA */}
      <section className="landing-cta-section">
        <h2 className="landing-cta-headline landing-reveal">Try Plattr for free</h2>
        <div className="landing-cta-buttons">
          <Link to="/" className="btn-primary">
            Try for free
          </Link>
          <Link to="/pricing" className="btn-outline">
            Book a demo
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer id="footer" className="landing-footer">
        <div className="landing-footer-newsletter landing-reveal">
          <h3>Stay in the know</h3>
          <p>Building a business can be challenging. Our newsletter can help. We won't spam, promise.</p>
          <form className="landing-newsletter-form" onSubmit={handleNewsletterSubmit}>
            <input
              type="email"
              name="newsletter-email"
              placeholder="Enter your email"
              required
              disabled={newsletterLoading}
            />
            <button type="submit" disabled={newsletterLoading}>
              {newsletterLoading ? "..." : "Subscribe"}
            </button>
          </form>
        </div>
        <p className="landing-footer-quote landing-reveal">
          "Building loyalty without giving discounts."
        </p>
        <div className="landing-footer-grid">
          <div className="landing-footer-col">
            <h4>Product</h4>
            <Link to="/landing#features">Customer campaigns</Link>
            <Link to="/landing#features">WhatsApp marketing</Link>
            <Link to="/landing#features">Loyalty program</Link>
            <Link to="/landing#integrations">Integrations</Link>
            <Link to="/">Open POS</Link>
          </div>
          <div className="landing-footer-col">
            <h4>Success stories</h4>
            <Link to="/landing#testimonials">Case studies</Link>
            <Link to="/landing#testimonials">Testimonials</Link>
          </div>
          <div className="landing-footer-col">
            <h4>Resources</h4>
            <Link to="/landing#faq">FAQ</Link>
            <Link to="/pricing">Pricing</Link>
            <Link to="/landing">Blog</Link>
          </div>
          <div className="landing-footer-col">
            <h4>Company</h4>
            <Link to="/landing">About us</Link>
            <a href={`mailto:${CONTACT_EMAIL}`}>Contact us</a>
            <Link to="/landing">Careers</Link>
          </div>
        </div>
        <div className="landing-footer-bottom">
          <div className="landing-footer-legal">
            <Link to="/terms">Terms of service</Link>
            <Link to="/privacy">Privacy policy</Link>
            <Link to="/refund">Refund & cancellation</Link>
          </div>
          <p className="landing-footer-copy">© 2026 Plattr OS. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
}
