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
        Plattr Technologies LLP ("we", "Plattr") respects your privacy. This policy describes how we
        collect, use, and protect your information when you use Plattr OS and related services.
      </p>

      <h2>1. Information We Collect</h2>
      <p>
        We collect information you provide directly and through your use of our services:
      </p>
      <ul>
        <li>
          <strong>Account and business data:</strong> Email, business name, address, phone number,
          and cafe/restaurant details when you sign up or use Plattr OS.
        </li>
        <li>
          <strong>Order and transaction data:</strong> Order history, items, amounts, payment status,
          and related data for point-of-sale and loyalty features.
        </li>
        <li>
          <strong>Customer data:</strong> Phone numbers and loyalty points for customers who use
          your cafe via Plattr (collected when you use our POS or loyalty features).
        </li>
        <li>
          <strong>Newsletter and marketing:</strong> Email addresses when you subscribe via our
          website (e.g. plattros.in).
        </li>
        <li>
          <strong>Usage and technical data:</strong> Browser information, device type, IP address,
          and usage patterns to operate and improve our services.
        </li>
        <li>
          <strong>WhatsApp messaging:</strong> When we send order notifications, receipts, or
          loyalty messages via WhatsApp, we use your phone number and Meta's WhatsApp Business API.
          Message content and delivery status are processed as part of our service.
        </li>
      </ul>

      <h2>2. How We Use Your Information</h2>
      <p>We use the information we collect to:</p>
      <ul>
        <li>Provide and operate Plattr OS (POS, loyalty, order management)</li>
        <li>Send order confirmations, receipts, and status updates via WhatsApp.</li>
        <li>Send loyalty campaigns and promotional messages (with your consent where required)</li>
        <li>Process payments and manage subscriptions</li>
        <li>Improve our services, fix issues, and support you</li>
        <li>Comply with legal obligations</li>
      </ul>
      <p>We do not sell your personal information to third parties.</p>

      <h2>3. Data Storage and Security</h2>
      <p>
        Data is stored securely on Supabase (cloud infrastructure). We use industry-standard security
        measures to protect your data. Access is restricted to authorized personnel.
      </p>

      <h2>4. Data Retention</h2>
      <p>
        We retain your data for as long as your account is active or as needed to provide our
        services. You may request deletion of your data at any time (see below).
      </p>

      <h2>5. Your Rights and Data Deletion</h2>
      <p>
        You have the right to access, correct, or delete your personal data. To request deletion of
        your data, please contact us at{" "}
        <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a> with the subject line "Data
        Deletion Request" and include your email or phone number associated with your account. We
        will process your request within 30 days.
      </p>
      <p>
        For customers of cafes using Plattr (e.g. loyalty points, order history): contact the cafe
        directly or email us at{" "}
        <a href={`mailto:${CONTACT_EMAIL}`}>{CONTACT_EMAIL}</a>.
      </p>

      <h2>6. Third-Party Services</h2>
      <p>
        We use third-party services including Supabase (database), Meta/WhatsApp (messaging), and
        payment processors. Their privacy policies apply to data they process on our behalf.
      </p>

      <h2>7. Cookies and Tracking</h2>
      <p>
        We collect minimal usage data for analytics and service improvement. You can control
        cookies via your browser settings.
      </p>

      <h2>8. Contact</h2>
      <p>
        For privacy-related questions or requests, contact us at{" "}
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
