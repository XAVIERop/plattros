import { useState } from "react";
import { useParams } from "react-router-dom";
import { toast } from "sonner";
import { supabase } from "@/lib/supabase/client";

type Step = "phone" | "welcome" | "feedback" | "done";

export default function CheckIn() {
  const { restaurantId } = useParams();
  const [step, setStep] = useState<Step>("phone");
  const [phone, setPhone] = useState("");
  const [rating, setRating] = useState(0);
  const [comment, setComment] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [cafeId, setCafeId] = useState<string | null>(null);
  const [googleReviewUrl, setGoogleReviewUrl] = useState<string | null>(null);
  const [pointsAwarded, setPointsAwarded] = useState(50);

  const referrerPhone = new URLSearchParams(window.location.search).get("ref") || undefined;

  const handlePhoneSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (phone.length < 10) return;
    setLoading(true);
    setError(null);
    try {
      const slug = restaurantId || "";
      const { data: cafe } = await supabase.from("cafes").select("id, google_review_url").eq("slug", slug).maybeSingle();
      if (!cafe?.id) {
        setError("Restaurant not found. Please check the link.");
        return;
      }
      setCafeId(cafe.id);
      setGoogleReviewUrl(cafe.google_review_url || null);
      const { data, error: rpcError } = await supabase.rpc("loyalty_check_in", {
        p_cafe_id: cafe.id,
        p_phone: phone.replace(/\s/g, ""),
        p_referrer_phone: referrerPhone || null,
      });
      if (rpcError) throw rpcError;
      if (data?.success) {
        setPointsAwarded(data.points_awarded ?? 50);
        setStep("welcome");
        toast.success(`You earned +${data.points_awarded ?? 50} points!`);
      } else setError("Check-in failed. Please try again.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Check-in failed");
    } finally {
      setLoading(false);
    }
  };

  const handleFeedback = async () => {
    if (rating === 0 || !cafeId) return;
    setLoading(true);
    setError(null);
    try {
      const { error: rpcError } = await supabase.rpc("loyalty_submit_feedback", {
        p_cafe_id: cafeId,
        p_phone: phone.replace(/\s/g, ""),
        p_rating: rating,
        p_comment: comment || null,
      });
      if (rpcError) throw rpcError;
      setStep("done");
      toast.success("Thank you for your feedback!");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to submit feedback");
    } finally {
      setLoading(false);
    }
  };

  const cardStyle: React.CSSProperties = {
    padding: 24,
    borderRadius: 12,
    backgroundColor: "var(--surface-card, #fff)",
    border: "1px solid var(--border-default, #e2e8f0)",
    boxShadow: "0 1px 3px rgba(0,0,0,0.08)",
  };

  return (
    <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", padding: 16, background: "var(--bg-page, #f8fafc)" }}>
      <div style={{ width: "100%", maxWidth: 360 }}>
        <div style={{ textAlign: "center", marginBottom: 32 }}>
          <h1 style={{ fontSize: "1.25rem", fontWeight: 700, color: "var(--text-primary, #0f172a)" }}>Loyalty Check-In</h1>
          <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: 4 }}>{restaurantId}</p>
        </div>

        {step === "phone" && (
          <form onSubmit={handlePhoneSubmit} style={{ ...cardStyle, display: "flex", flexDirection: "column", gap: 16 }}>
            {error && <p style={{ fontSize: "0.875rem", color: "var(--error, #dc2626)" }}>{error}</p>}
            <div>
              <label htmlFor="phone" style={{ fontSize: "0.875rem", fontWeight: 500, display: "block", marginBottom: 8 }}>Enter your phone number</label>
              <input
                id="phone"
                type="tel"
                placeholder="+91 98765 43210"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                style={{ width: "100%", padding: "10px 12px", borderRadius: 8, border: "1px solid var(--border-default)", fontSize: "1rem" }}
                autoFocus
              />
            </div>
            <button type="submit" disabled={phone.length < 10 || loading} style={{ padding: "10px 16px", borderRadius: 8, background: "var(--primary)", color: "#fff", fontWeight: 600, border: "none", cursor: phone.length >= 10 && !loading ? "pointer" : "not-allowed" }}>
              {loading ? "Checking in…" : "Check In"}
            </button>
          </form>
        )}

        {step === "welcome" && (
          <div style={{ ...cardStyle, textAlign: "center" }}>
            <div style={{ width: 48, height: 48, borderRadius: "50%", background: "var(--success-bg, #ecfdf5)", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 16px", fontSize: "1.25rem" }}>✓</div>
            <h2 style={{ fontSize: "1.125rem", fontWeight: 700, marginBottom: 4 }}>Welcome!</h2>
            <p style={{ fontSize: "0.875rem", color: "var(--text-muted)", marginBottom: 16 }}>You've earned <strong style={{ color: "var(--primary)" }}>+{pointsAwarded}</strong> points</p>
            <button onClick={() => setStep("feedback")} style={{ width: "100%", padding: "10px 16px", borderRadius: 8, background: "var(--primary)", color: "#fff", fontWeight: 600, border: "none", cursor: "pointer", marginBottom: 8 }}>Leave Feedback</button>
            <button onClick={() => setStep("done")} type="button" style={{ fontSize: "0.75rem", color: "var(--text-muted)", background: "none", border: "none", cursor: "pointer", textDecoration: "underline" }}>Skip</button>
          </div>
        )}

        {step === "feedback" && (
          <div style={{ ...cardStyle }}>
            <div style={{ marginBottom: 16 }}>
              <label style={{ fontSize: "0.875rem", fontWeight: 500, display: "block", marginBottom: 8 }}>How was your experience?</label>
              <div style={{ display: "flex", gap: 4 }}>
                {[1, 2, 3, 4, 5].map((s) => (
                  <button key={s} type="button" onClick={() => setRating(s)} style={{ padding: 4, background: "none", border: "none", cursor: "pointer", fontSize: "1.5rem", color: s <= rating ? "var(--primary)" : "var(--border-default)" }}>
                    ★
                  </button>
                ))}
              </div>
            </div>
            <div style={{ marginBottom: 16 }}>
              <label htmlFor="comment" style={{ fontSize: "0.875rem", fontWeight: 500, display: "block", marginBottom: 8 }}>Comment (optional)</label>
              <textarea id="comment" value={comment} onChange={(e) => setComment(e.target.value)} rows={3} placeholder="Tell us about your visit..." style={{ width: "100%", padding: "10px 12px", borderRadius: 8, border: "1px solid var(--border-default)", fontSize: "0.875rem" }} />
            </div>
            {error && <p style={{ fontSize: "0.875rem", color: "var(--error)", marginBottom: 8 }}>{error}</p>}
            <button onClick={handleFeedback} disabled={rating === 0 || loading} style={{ width: "100%", padding: "10px 16px", borderRadius: 8, background: "var(--primary)", color: "#fff", fontWeight: 600, border: "none", cursor: rating && !loading ? "pointer" : "not-allowed" }}>{loading ? "Submitting…" : "Submit"}</button>
          </div>
        )}

        {step === "done" && (
          <div style={{ ...cardStyle, textAlign: "center" }}>
            <h2 style={{ fontSize: "1.125rem", fontWeight: 700, marginBottom: 8 }}>Thank you!</h2>
            <p style={{ fontSize: "0.875rem", color: "var(--text-muted)", marginBottom: 12 }}>See you next time.</p>
            {rating >= 4 && googleReviewUrl && (
              <a href={googleReviewUrl} target="_blank" rel="noopener noreferrer" style={{ display: "inline-block", marginBottom: 12, fontSize: "0.875rem", fontWeight: 500, color: "var(--primary)" }}>Leave us a Google review →</a>
            )}
            <a href={`/reviews/${restaurantId}`} style={{ display: "inline-block", marginBottom: 12, fontSize: "0.875rem", fontWeight: 500, color: "var(--primary)" }}>See what others say →</a>
            <p style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>
              Share with friends — you both get bonus points when they check in.{" "}
              <button type="button" onClick={() => { navigator.clipboard.writeText(`${window.location.origin}/checkin/${restaurantId}?ref=${phone.replace(/\s/g, "")}`); toast.success("Referral link copied!"); }} style={{ color: "var(--primary)", background: "none", border: "none", cursor: "pointer", textDecoration: "underline" }}>Copy referral link</button>
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
