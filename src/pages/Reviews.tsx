import { useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/lib/supabase/client";

export default function Reviews() {
  const { restaurantId } = useParams();

  const { data: reviews = [], isLoading, error } = useQuery({
    queryKey: ["public-reviews", restaurantId],
    queryFn: async () => {
      if (!restaurantId) return [];
      const { data, error: rpcError } = await supabase.rpc("get_public_reviews", {
        p_slug: restaurantId,
      });
      if (rpcError) throw rpcError;
      return (data || []).map((r: { id: string; rating: number; comment: string | null; created_at: string; cafe_name: string | null }) => ({
        ...r,
        date: r.created_at ? new Date(r.created_at).toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" }) : "-",
      }));
    },
    enabled: !!restaurantId,
  });

  const cafeName = reviews[0]?.cafe_name ?? restaurantId;

  if (!restaurantId) {
    return (
      <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", padding: 16, background: "var(--bg-page, #f8fafc)" }}>
        <p style={{ color: "var(--text-muted)" }}>Invalid link. Please use the correct reviews URL.</p>
      </div>
    );
  }

  if (isLoading || (reviews.length === 0 && !error)) {
    return (
      <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", padding: 16, background: "var(--bg-page, #f8fafc)" }}>
        <p style={{ color: "var(--text-muted)" }}>Loading reviews…</p>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", padding: 16, background: "var(--bg-page, #f8fafc)" }}>
        <p style={{ color: "var(--error, #dc2626)" }}>Could not load reviews.</p>
      </div>
    );
  }

  const avgRating = reviews.length > 0 ? (reviews.reduce((s: number, r: { rating: number }) => s + r.rating, 0) / reviews.length).toFixed(1) : "0";
  const positiveCount = reviews.filter((r: { rating: number }) => r.rating >= 4).length;

  return (
    <div style={{ minHeight: "100vh", padding: 24, background: "var(--bg-page, #f8fafc)" }}>
      <div style={{ maxWidth: 560, margin: "0 auto" }}>
        <h1 style={{ fontSize: "1.5rem", fontWeight: 700, color: "var(--text-primary)", marginBottom: 4 }}>
          {cafeName} — Reviews
        </h1>
        <p style={{ fontSize: "0.875rem", color: "var(--text-muted)", marginBottom: 24 }}>
          {reviews.length} reviews · {avgRating} avg · {positiveCount} positive
        </p>

        {reviews.length === 0 ? (
          <p style={{ padding: 24, textAlign: "center", color: "var(--text-muted)" }}>No reviews yet. Be the first to leave feedback!</p>
        ) : (
          <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
            {reviews.map((r: { id: string; rating: number; comment: string | null; date: string }) => (
              <div key={r.id} style={{ padding: 16, borderRadius: 12, border: "1px solid var(--border-default)", background: "var(--surface-card, #fff)", fontSize: "0.875rem" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
                  <span style={{ color: "var(--primary)" }}>{"★".repeat(r.rating)}{"☆".repeat(5 - r.rating)}</span>
                  <span style={{ color: "var(--text-muted)" }}>{r.date}</span>
                </div>
                {r.comment && <p style={{ color: "var(--text-primary)", marginTop: 8 }}>{r.comment}</p>}
              </div>
            ))}
          </div>
        )}

        <p style={{ marginTop: 24, fontSize: "0.75rem", color: "var(--text-muted)", textAlign: "center" }}>
          <a href={`/checkin/${restaurantId}`} style={{ color: "var(--primary)", textDecoration: "underline" }}>
            Check in & leave feedback →
          </a>
        </p>
      </div>
    </div>
  );
}
