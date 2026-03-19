import { Link } from "react-router-dom";

const tiers = [
  {
    name: "Starter",
    price: "Free",
    period: "14-day trial",
    features: ["1 cafe", "Unlimited orders", "Offline sync", "Basic analytics"],
    cta: "Start trial",
    href: "/",
    highlighted: false,
  },
  {
    name: "Pro",
    price: "₹999",
    period: "/month",
    features: ["1 cafe", "Loyalty & CRM", "WhatsApp campaigns", "Print (KOT + receipt)", "Priority support"],
    cta: "Get Pro",
    href: "/",
    highlighted: true,
  },
  {
    name: "Enterprise",
    price: "Custom",
    period: "",
    features: ["Multiple cafes", "Custom integrations", "Dedicated support", "SLA"],
    cta: "Contact us",
    href: "mailto:hello@plattrtechnologies.com",
    highlighted: false,
  },
];

export default function Pricing() {
  return (
    <div
      style={{
        minHeight: "100vh",
        background: "linear-gradient(135deg, #0f172a 0%, #1e293b 100%)",
        color: "#f8fafc",
        fontFamily: "system-ui, sans-serif",
        padding: "48px 24px",
      }}
    >
      <div style={{ maxWidth: 1000, margin: "0 auto" }}>
        <div style={{ textAlign: "center", marginBottom: 48 }}>
          <Link to="/landing" style={{ color: "#94a3b8", textDecoration: "none", fontSize: "0.9rem", marginBottom: 16, display: "inline-block" }}>
            ← Back
          </Link>
          <h1 style={{ fontSize: "2.5rem", fontWeight: 700, marginBottom: 8 }}>Pricing</h1>
          <p style={{ color: "#94a3b8", fontSize: "1.1rem" }}>Simple plans for cafes of all sizes.</p>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))", gap: 24, alignItems: "stretch" }}>
          {tiers.map((tier) => (
            <div
              key={tier.name}
              style={{
                padding: 32,
                borderRadius: 16,
                background: tier.highlighted ? "rgba(59, 130, 246, 0.15)" : "rgba(255,255,255,0.05)",
                border: tier.highlighted ? "2px solid #3b82f6" : "1px solid rgba(255,255,255,0.1)",
                display: "flex",
                flexDirection: "column",
              }}
            >
              <h3 style={{ fontSize: "1.25rem", marginBottom: 8 }}>{tier.name}</h3>
              <div style={{ marginBottom: 24 }}>
                <span style={{ fontSize: "2rem", fontWeight: 700 }}>{tier.price}</span>
                <span style={{ color: "#94a3b8", fontSize: "1rem" }}> {tier.period}</span>
              </div>
              <ul style={{ listStyle: "none", padding: 0, margin: "0 0 24px 0", flex: 1 }}>
                {tier.features.map((f) => (
                  <li key={f} style={{ padding: "8px 0", color: "#cbd5e1", display: "flex", alignItems: "center", gap: 8 }}>
                    <span style={{ color: "#22c55e" }}>✓</span> {f}
                  </li>
                ))}
              </ul>
              {tier.href.startsWith("mailto:") ? (
                <a
                  href={tier.href}
                  style={{
                    display: "block",
                    padding: "14px 24px",
                    borderRadius: 10,
                    background: tier.highlighted ? "#3b82f6" : "rgba(255,255,255,0.1)",
                    color: "white",
                    fontWeight: 600,
                    textAlign: "center",
                    textDecoration: "none",
                  }}
                >
                  {tier.cta}
                </a>
              ) : (
                <Link
                  to={tier.href}
                  style={{
                    display: "block",
                    padding: "14px 24px",
                    borderRadius: 10,
                    background: tier.highlighted ? "#3b82f6" : "rgba(255,255,255,0.1)",
                    color: "white",
                    fontWeight: 600,
                    textAlign: "center",
                    textDecoration: "none",
                  }}
                >
                  {tier.cta}
                </Link>
              )}
            </div>
          ))}
        </div>
        <p style={{ textAlign: "center", color: "#64748b", fontSize: "0.85rem", marginTop: 48 }}>
          All plans include offline sync, order management, and kitchen display. No credit card required for trial.
        </p>
      </div>
    </div>
  );
}
