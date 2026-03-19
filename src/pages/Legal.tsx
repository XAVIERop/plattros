import { Link } from "react-router-dom";
import "./Landing.css";

const CONTACT_EMAIL = "hello@plattrtechnologies.com";

type LegalPageProps = {
  title: string;
  children: React.ReactNode;
};

function LegalPage({ title, children }: LegalPageProps) {
  return (
    <div className="landing">
      <header className="landing-header">
        <Link to="/landing" className="landing-logo">
          Plattr OS
        </Link>
        <nav className="landing-nav">
          <Link to="/landing">Home</Link>
          <Link to="/pricing">Pricing</Link>
        </nav>
        <Link to="/" className="landing-cta-pill">
          <span className="pulse" />
          Open POS
        </Link>
      </header>
      <main className="landing-legal-main">
        <Link to="/landing" className="landing-legal-back">
          ← Back to home
        </Link>
        <h1>{title}</h1>
        <div className="landing-legal-content">{children}</div>
        <p className="landing-legal-contact">
          Questions? Contact us at{" "}
          <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a>
        </p>
      </main>
    </div>
  );
}

export function Terms() {
  return (
    <LegalPage title="Terms of Service">
      <p>Last updated: March 2026</p>
      <p>
        By using Plattr OS ("Service"), operated by Plattr Technologies LLP, you agree to these Terms.
      </p>
      <p>
        The Service provides point-of-sale, loyalty, and marketing tools for cafes and restaurants.
        You are responsible for your use of the Service and compliance with applicable laws.
      </p>
      <p>
        We may update these Terms from time to time. Continued use after changes constitutes acceptance.
      </p>
      <p>
        For the full terms of service, please contact us at{" "}
        <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a>.
      </p>
    </LegalPage>
  );
}

export function Privacy() {
  return (
    <LegalPage title="Privacy Policy">
      <p>Last updated: March 2026</p>
      <p>
        Plattr Technologies LLP ("we") respects your privacy. This policy describes how we collect,
        use, and protect your information when you use Plattr OS.
      </p>
      <p>
        We collect information you provide (email, business details) and usage data to operate and
        improve the Service. We do not sell your personal information.
      </p>
      <p>
        Data is stored securely on Supabase. Newsletter signups are stored in our database. For
        full details on data handling, retention, and your rights, contact us.
      </p>
      <p>
        For the complete privacy policy, please contact us at{" "}
        <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a>.
      </p>
    </LegalPage>
  );
}

export function Refund() {
  return (
    <LegalPage title="Refund & Cancellation">
      <p>Last updated: March 2026</p>
      <p>
        Plattr OS subscription plans may be cancelled at any time. Refunds are handled on a
        case-by-case basis for subscription fees paid in advance.
      </p>
      <p>
        For refund requests or cancellation support, please contact us at{" "}
        <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a>.
      </p>
    </LegalPage>
  );
}
