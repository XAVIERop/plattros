import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { QRCodeSVG } from "qrcode.react";
import { supabase } from "@/lib/supabase/client";
import { toast } from "sonner";
import {
  Megaphone,
  Gift,
  UserPlus,
  Star,
  QrCode,
  Settings,
  Download,
  Printer,
  Plus,
  Send,
  X,
} from "lucide-react";

type LoyaltyTab = "campaigns" | "rewards" | "referrals" | "feedback" | "qr" | "settings";

interface LoyaltyPanelProps {
  cafeId: string | null;
  onMobileHeader?: (title: string) => void;
}

export function LoyaltyPanel({ cafeId, onMobileHeader }: LoyaltyPanelProps) {
  const [tab, setTab] = useState<LoyaltyTab>("campaigns");
  const queryClient = useQueryClient();

  const tabs: { id: LoyaltyTab; label: string; icon: typeof Megaphone }[] = [
    { id: "campaigns", label: "Campaigns", icon: Megaphone },
    { id: "rewards", label: "Rewards", icon: Gift },
    { id: "referrals", label: "Referrals", icon: UserPlus },
    { id: "feedback", label: "Feedback", icon: Star },
    { id: "qr", label: "QR Code", icon: QrCode },
    { id: "settings", label: "Settings", icon: Settings },
  ];

  const { data: campaigns = [] } = useQuery({
    queryKey: ["loyalty-campaigns", cafeId],
    queryFn: async () => {
      if (!cafeId) return [];
      const { data, error } = await supabase.from("loyalty_campaigns").select("*").eq("cafe_id", cafeId).order("created_at", { ascending: false });
      if (error) throw error;
      return data || [];
    },
    enabled: !!cafeId && tab === "campaigns",
  });

  const { data: rewards = [] } = useQuery({
    queryKey: ["loyalty-rewards", cafeId],
    queryFn: async () => {
      if (!cafeId) return [];
      const { data, error } = await supabase.from("loyalty_rewards").select("*").eq("cafe_id", cafeId);
      if (error) throw error;
      return data || [];
    },
    enabled: !!cafeId && tab === "rewards",
  });

  const { data: referrals = [] } = useQuery({
    queryKey: ["loyalty-referrals", cafeId],
    queryFn: async () => {
      if (!cafeId) return [];
      const { data, error } = await supabase.from("loyalty_referrals").select("*").eq("cafe_id", cafeId).order("created_at", { ascending: false });
      if (error) throw error;
      return data || [];
    },
    enabled: !!cafeId && tab === "referrals",
  });

  const { data: feedbackItems = [] } = useQuery({
    queryKey: ["loyalty-feedback", cafeId],
    queryFn: async () => {
      if (!cafeId) return [];
      const { data, error } = await supabase.from("loyalty_feedback").select("*").eq("cafe_id", cafeId).order("created_at", { ascending: false });
      if (error) throw error;
      return (data || []).map((f) => ({ ...f, date: f.created_at ? new Date(f.created_at).toISOString().slice(0, 10) : "-" }));
    },
    enabled: !!cafeId && tab === "feedback",
  });

  const { data: cafe } = useQuery({
    queryKey: ["cafe", cafeId],
    queryFn: async () => {
      if (!cafeId) return null;
      const { data, error } = await supabase.from("cafes").select("id, name, slug").eq("id", cafeId).single();
      if (error) throw error;
      return data;
    },
    enabled: !!cafeId && tab === "qr",
  });

  const { data: settings, isLoading: settingsLoading } = useQuery({
    queryKey: ["loyalty-settings", cafeId],
    queryFn: async () => {
      if (!cafeId) return null;
      const { data } = await supabase.from("loyalty_settings").select("*").eq("cafe_id", cafeId).maybeSingle();
      return data;
    },
    enabled: !!cafeId && tab === "settings",
  });

  const { data: loyaltyCustomerCount = 0 } = useQuery({
    queryKey: ["loyalty-customers-count", cafeId],
    queryFn: async () => {
      if (!cafeId) return 0;
      const { count, error } = await supabase.from("loyalty_customers").select("*", { count: "exact", head: true }).eq("cafe_id", cafeId);
      if (error) throw error;
      return count ?? 0;
    },
    enabled: !!cafeId && tab === "campaigns",
  });

  const [showCreateCampaign, setShowCreateCampaign] = useState(false);
  const [campaignForm, setCampaignForm] = useState({ name: "", type: "promo" as "promo" | "birthday" | "winback", message_body: "" });
  const [sendingCampaignId, setSendingCampaignId] = useState<string | null>(null);
  const [sendSegment, setSendSegment] = useState<string>("all");

  const [showAddReward, setShowAddReward] = useState(false);
  const [rewardForm, setRewardForm] = useState({ name: "", type: "free_item" as "free_item" | "discount" | "voucher", points_cost: "100", discount_value: "20" });

  const createCampaignMutation = useMutation({
    mutationFn: async () => {
      if (!cafeId || !campaignForm.name.trim()) throw new Error("Name is required");
      const { data, error } = await supabase
        .from("loyalty_campaigns")
        .insert({
          cafe_id: cafeId,
          name: campaignForm.name.trim(),
          type: campaignForm.type,
          status: "draft",
          message_body: campaignForm.message_body.trim() || null,
        })
        .select("id")
        .single();
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["loyalty-campaigns", cafeId] });
      setShowCreateCampaign(false);
      setCampaignForm({ name: "", type: "promo", message_body: "" });
      toast.success("Campaign created.");
    },
    onError: (e) => toast.error(e instanceof Error ? e.message : "Failed to create campaign"),
  });

  const sendCampaignMutation = useMutation({
    mutationFn: async ({ campaignId, segment }: { campaignId: string; segment?: string }) => {
      if (!cafeId) throw new Error("No cafe");
      const { data, error } = await supabase.functions.invoke("loyalty-whatsapp-send", {
        body: { campaign_id: campaignId, cafe_id: cafeId, segment: segment || "all" },
      });
      if (error) throw error;
      const result = data as { success?: boolean; sent?: number; error?: string };
      if (!result?.success && result?.error) throw new Error(result.error);
      return result;
    },
    onSuccess: (result) => {
      queryClient.invalidateQueries({ queryKey: ["loyalty-campaigns", cafeId] });
      setSendingCampaignId(null);
      const sent = (result as { sent?: number }).sent ?? 0;
      toast.success(`Campaign sent to ${sent} customer(s).`);
    },
    onError: (e) => {
      setSendingCampaignId(null);
      toast.error(e instanceof Error ? e.message : "Failed to send campaign");
    },
  });

  const createRewardMutation = useMutation({
    mutationFn: async () => {
      if (!cafeId || !rewardForm.name.trim()) throw new Error("Name is required");
      const points = parseInt(rewardForm.points_cost, 10) || 100;
      if (points < 1) throw new Error("Points must be at least 1");
      const payload: Record<string, unknown> = {
        cafe_id: cafeId,
        name: rewardForm.name.trim(),
        type: rewardForm.type,
        points_cost: points,
        active: true,
      };
      if (rewardForm.type === "discount") {
        payload.discount_value = parseInt(rewardForm.discount_value, 10) || 20;
      }
      const { data, error } = await supabase
        .from("loyalty_rewards")
        .insert(payload as Record<string, unknown>)
        .select("id")
        .single();
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["loyalty-rewards", cafeId] });
      setShowAddReward(false);
      setRewardForm({ name: "", type: "free_item", points_cost: "100", discount_value: "20" });
      toast.success("Reward created.");
    },
    onError: (e) => toast.error(e instanceof Error ? e.message : "Failed to create reward"),
  });

  const checkinUrl = cafe?.slug ? `${window.location.origin}/checkin/${cafe.slug}` : null;

  const handleDownloadQR = () => {
    if (!checkinUrl || !cafe) return;
    const svg = document.querySelector("#loyalty-qr-svg") as SVGSVGElement;
    if (!svg) return;
    const svgData = new XMLSerializer().serializeToString(svg);
    const blob = new Blob([svgData], { type: "image/svg+xml" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `loyalty-checkin-${cafe.slug}.svg`;
    a.click();
    URL.revokeObjectURL(url);
    toast.success("QR code downloaded.");
  };

  const [settingsForm, setSettingsForm] = useState({ spendAmount: "100", pointsAwarded: "10", welcomePoints: "50", referralPoints: "50", googleReviewUrl: "", zomatoReviewUrl: "" });

  useEffect(() => {
    if (settings) {
      setSettingsForm({
        spendAmount: String(settings.spend_amount ?? 100),
        pointsAwarded: String(settings.points_awarded ?? 10),
        welcomePoints: String(settings.welcome_points ?? 50),
        referralPoints: String(settings.referral_points ?? 50),
        googleReviewUrl: settings.google_review_url ?? "",
        zomatoReviewUrl: settings.zomato_review_url ?? "",
      });
    }
  }, [settings]);
  const settingsSaveMutation = useMutation({
    mutationFn: async () => {
      if (!cafeId) throw new Error("No cafe");
      const spend = parseInt(settingsForm.spendAmount, 10) || 100;
      const points = parseInt(settingsForm.pointsAwarded, 10) || 10;
      const welcome = parseInt(settingsForm.welcomePoints, 10) || 50;
      const refPoints = parseInt(settingsForm.referralPoints, 10) || 50;
      await supabase.from("loyalty_settings").upsert(
        { cafe_id: cafeId, spend_amount: spend, points_awarded: points, welcome_points: welcome, referral_points: refPoints, google_review_url: settingsForm.googleReviewUrl.trim() || null, zomato_review_url: settingsForm.zomatoReviewUrl.trim() || null, updated_at: new Date().toISOString() },
        { onConflict: "cafe_id" }
      );
      await supabase.from("cafes").update({ google_review_url: settingsForm.googleReviewUrl.trim() || null, zomato_review_url: settingsForm.zomatoReviewUrl.trim() || null }).eq("id", cafeId);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["loyalty-settings", cafeId] });
      toast.success("Loyalty settings saved.");
    },
  });

  if (!cafeId) {
    return (
      <section className="panel">
        <div className="section-head">
          <h3>Loyalty</h3>
        </div>
        <p style={{ padding: 24, color: "var(--text-muted)" }}>Link your cafe to view loyalty data.</p>
      </section>
    );
  }

  return (
    <section className="panel">
      <div className="section-head" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: 12 }}>
        <h3>Loyalty Loop</h3>
        <div style={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
          {tabs.map((t) => (
            <button
              key={t.id}
              className={tab === t.id ? "btn-primary" : "btn-outline"}
              onClick={() => setTab(t.id)}
              style={{ padding: "6px 12px", fontSize: "0.8rem", display: "flex", alignItems: "center", gap: 6 }}
            >
              <t.icon size={14} />
              {t.label}
            </button>
          ))}
        </div>
      </div>

      {tab === "campaigns" && (
        <div>
          <p style={{ marginBottom: 16, color: "var(--text-muted)", fontSize: "0.875rem" }}>
            Create and send WhatsApp campaigns to loyalty customers. {loyaltyCustomerCount} customer(s) in loyalty program.
          </p>
          {!showCreateCampaign ? (
            <button
              type="button"
              className="btn-primary"
              onClick={() => setShowCreateCampaign(true)}
              style={{ marginBottom: 16, display: "flex", alignItems: "center", gap: 8 }}
            >
              <Plus size={18} /> Create Campaign
            </button>
          ) : (
            <div style={{ marginBottom: 16, padding: 16, borderRadius: 12, border: "1px solid var(--border-default)", background: "var(--bg-subtle, #f8fafc)" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
                <strong>New Campaign</strong>
                <button type="button" className="ghost" onClick={() => setShowCreateCampaign(false)} style={{ padding: 4 }}><X size={18} /></button>
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 500, marginBottom: 4 }}>Name</label>
                  <input
                    type="text"
                    value={campaignForm.name}
                    onChange={(e) => setCampaignForm((f) => ({ ...f, name: e.target.value }))}
                    placeholder="e.g. Weekend Special"
                    style={{ width: "100%", padding: "8px 12px", borderRadius: 8, border: "1px solid var(--border-default)" }}
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 500, marginBottom: 4 }}>Type</label>
                  <select
                    value={campaignForm.type}
                    onChange={(e) => setCampaignForm((f) => ({ ...f, type: e.target.value as "promo" | "birthday" | "winback" }))}
                    style={{ width: "100%", padding: "8px 12px", borderRadius: 8, border: "1px solid var(--border-default)" }}
                  >
                    <option value="promo">Promo</option>
                    <option value="birthday">Birthday</option>
                    <option value="winback">Win-back</option>
                  </select>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 500, marginBottom: 4 }}>Message (optional)</label>
                  <textarea
                    value={campaignForm.message_body}
                    onChange={(e) => setCampaignForm((f) => ({ ...f, message_body: e.target.value }))}
                    placeholder="Hi! 👋 Enjoy 15% off this weekend. Visit us soon!"
                    rows={3}
                    style={{ width: "100%", padding: "8px 12px", borderRadius: 8, border: "1px solid var(--border-default)", resize: "vertical" }}
                  />
                  <p style={{ fontSize: "0.75rem", color: "var(--text-muted)", marginTop: 4 }}>Leave blank to use default message with check-in link.</p>
                </div>
                <button
                  type="button"
                  className="btn-primary"
                  onClick={() => createCampaignMutation.mutate()}
                  disabled={!campaignForm.name.trim() || createCampaignMutation.isPending}
                >
                  {createCampaignMutation.isPending ? "Creating…" : "Create Campaign"}
                </button>
              </div>
            </div>
          )}
          <table className="table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Type</th>
                <th>Status</th>
                <th>Sent</th>
                <th>Opened</th>
                <th>Revenue</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {campaigns.length === 0 && (
                <tr>
                  <td colSpan={7} style={{ textAlign: "center", padding: 24 }}>No campaigns yet. Create one above.</td>
                </tr>
              )}
              {campaigns.map((c) => (
                <tr key={c.id}>
                  <td style={{ fontWeight: 500 }}>{c.name}</td>
                  <td>{c.type}</td>
                  <td>{c.status}</td>
                  <td>{c.sent}</td>
                  <td>{c.opened}</td>
                  <td>AED {Number(c.revenue || 0)}</td>
                  <td>
                    <div style={{ display: "flex", alignItems: "center", gap: 8, flexWrap: "wrap" }}>
                      <select
                        value={sendSegment}
                        onChange={(e) => setSendSegment(e.target.value)}
                        style={{ padding: "4px 8px", fontSize: "0.75rem", borderRadius: 6, border: "1px solid var(--border-default)", minWidth: 90 }}
                      >
                        <option value="all">All</option>
                        <option value="at_risk">At Risk</option>
                        <option value="birthday">Birthday</option>
                        <option value="vip">VIP</option>
                        <option value="new">New</option>
                        <option value="regular">Regular</option>
                      </select>
                      <button
                        type="button"
                        className="btn-outline"
                        onClick={() => {
                          setSendingCampaignId(c.id);
                          sendCampaignMutation.mutate({ campaignId: c.id, segment: sendSegment });
                        }}
                        disabled={sendingCampaignId === c.id || loyaltyCustomerCount === 0}
                        style={{ padding: "4px 10px", fontSize: "0.8rem", display: "flex", alignItems: "center", gap: 4 }}
                      >
                        <Send size={14} />
                        {sendingCampaignId === c.id ? "Sending…" : "Send"}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {tab === "rewards" && (
        <div>
          <p style={{ marginBottom: 16, color: "var(--text-muted)", fontSize: "0.875rem" }}>
            Points-based rewards customers can redeem. Toggle active to enable/disable.
          </p>
          {!showAddReward ? (
            <button
              type="button"
              className="btn-primary"
              onClick={() => setShowAddReward(true)}
              style={{ marginBottom: 16, display: "flex", alignItems: "center", gap: 8 }}
            >
              <Plus size={18} /> Add Reward
            </button>
          ) : (
            <div style={{ marginBottom: 16, padding: 16, borderRadius: 12, border: "1px solid var(--border-default)", background: "var(--bg-subtle, #f8fafc)" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
                <strong>New Reward</strong>
                <button type="button" className="ghost" onClick={() => setShowAddReward(false)} style={{ padding: 4 }}><X size={18} /></button>
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 500, marginBottom: 4 }}>Name</label>
                  <input
                    type="text"
                    value={rewardForm.name}
                    onChange={(e) => setRewardForm((f) => ({ ...f, name: e.target.value }))}
                    placeholder="e.g. Free Chai"
                    style={{ width: "100%", padding: "8px 12px", borderRadius: 8, border: "1px solid var(--border-default)" }}
                  />
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 500, marginBottom: 4 }}>Type</label>
                  <select
                    value={rewardForm.type}
                    onChange={(e) => setRewardForm((f) => ({ ...f, type: e.target.value as "free_item" | "discount" | "voucher" }))}
                    style={{ width: "100%", padding: "8px 12px", borderRadius: 8, border: "1px solid var(--border-default)" }}
                  >
                    <option value="free_item">Free Item</option>
                    <option value="discount">Discount</option>
                    <option value="voucher">Voucher</option>
                  </select>
                </div>
                <div>
                  <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 500, marginBottom: 4 }}>Points Cost</label>
                  <input
                    type="number"
                    min={1}
                    value={rewardForm.points_cost}
                    onChange={(e) => setRewardForm((f) => ({ ...f, points_cost: e.target.value }))}
                    style={{ width: "100%", padding: "8px 12px", borderRadius: 8, border: "1px solid var(--border-default)" }}
                  />
                </div>
                {rewardForm.type === "discount" && (
                  <div>
                    <label style={{ display: "block", fontSize: "0.8rem", fontWeight: 500, marginBottom: 4 }}>Discount (AED)</label>
                    <input
                      type="number"
                      min={1}
                      value={rewardForm.discount_value}
                      onChange={(e) => setRewardForm((f) => ({ ...f, discount_value: e.target.value }))}
                      style={{ width: "100%", padding: "8px 12px", borderRadius: 8, border: "1px solid var(--border-default)" }}
                    />
                  </div>
                )}
                <button
                  type="button"
                  className="btn-primary"
                  onClick={() => createRewardMutation.mutate()}
                  disabled={!rewardForm.name.trim() || createRewardMutation.isPending}
                >
                  {createRewardMutation.isPending ? "Creating…" : "Create Reward"}
                </button>
              </div>
            </div>
          )}
          <table className="table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Type</th>
                <th>Points Cost</th>
                <th>Redemptions</th>
                <th>Active</th>
              </tr>
            </thead>
            <tbody>
              {rewards.length === 0 && (
                <tr>
                  <td colSpan={5} style={{ textAlign: "center", padding: 24 }}>No rewards yet. Add one above.</td>
                </tr>
              )}
              {rewards.map((r) => (
                <tr key={r.id}>
                  <td style={{ fontWeight: 500 }}>{r.name}</td>
                  <td>{r.type.replace("_", " ")}</td>
                  <td>{r.points_cost}</td>
                  <td>{r.redemptions}</td>
                  <td>{r.active ? "Yes" : "No"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {tab === "referrals" && (
        <div>
          <p style={{ marginBottom: 16, color: "var(--text-muted)", fontSize: "0.875rem" }}>Customers earn bonus points when friends check in. {referrals.length} referrals so far.</p>
          <table className="table">
            <thead>
              <tr>
                <th>Referrer</th>
                <th>Referred</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {referrals.length === 0 && (
                <tr>
                  <td colSpan={3} style={{ textAlign: "center", padding: 24 }}>No referrals yet.</td>
                </tr>
              )}
              {referrals.map((r) => (
                <tr key={r.id}>
                  <td style={{ fontFamily: "monospace" }}>{r.referrer_phone}</td>
                  <td style={{ fontFamily: "monospace" }}>{r.referred_phone}</td>
                  <td style={{ color: "var(--text-muted)" }}>{r.created_at ? new Date(r.created_at).toISOString().slice(0, 10) : "-"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {tab === "feedback" && (
        <div>
          {feedbackItems.filter((f) => f.rating <= 2).length > 0 && (
            <div style={{ marginBottom: 16, padding: 12, borderRadius: 8, background: "var(--error-bg, #fef2f2)", border: "1px solid var(--error, #dc2626)", fontSize: "0.875rem" }}>
              <span style={{ color: "var(--error, #dc2626)" }}>⚠️ {feedbackItems.filter((f) => f.rating <= 2).length} low rating(s) — WhatsApp alerts and follow-ups are queued.</span>{" "}
              <button
                type="button"
                onClick={async () => {
                  const { data } = await supabase.rpc("process_low_rating_feedback");
                  queryClient.invalidateQueries({ queryKey: ["loyalty-feedback", cafeId] });
                  toast.success(`Processed ${data ?? 0} low-rating alert(s).`);
                }}
                style={{ marginLeft: 8, padding: "4px 8px", fontSize: "0.75rem", background: "var(--error)", color: "#fff", border: "none", borderRadius: 6, cursor: "pointer" }}
              >
                Process now
              </button>
            </div>
          )}
          {feedbackItems.length > 0 && (
            <p style={{ marginBottom: 16, color: "var(--text-muted)", fontSize: "0.875rem" }}>
              {feedbackItems.length} reviews · {(feedbackItems.reduce((s, f) => s + f.rating, 0) / feedbackItems.length).toFixed(1)} avg · {feedbackItems.filter((f) => f.rating >= 4).length} positive
            </p>
          )}
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
            {feedbackItems.length === 0 && <p style={{ padding: 24, textAlign: "center", color: "var(--text-muted)" }}>No feedback yet.</p>}
            {feedbackItems.map((f) => (
              <div key={f.id} style={{ padding: 16, borderRadius: 12, border: "1px solid var(--border-default)", fontSize: "0.875rem" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
                  <span style={{ fontWeight: 500 }}>Guest</span>
                  <span style={{ color: "var(--text-muted)" }}>{f.date}</span>
                </div>
                <p style={{ color: "var(--text-muted)", fontFamily: "monospace", fontSize: "0.8rem", marginBottom: 4 }}>{f.phone}</p>
                <div style={{ marginBottom: 4 }}>{"★".repeat(f.rating)}{"☆".repeat(5 - f.rating)}</div>
                {f.comment && <p style={{ color: "var(--text-muted)" }}>{f.comment}</p>}
              </div>
            ))}
          </div>
        </div>
      )}

      {tab === "qr" && (
        <div style={{ maxWidth: 400, margin: "0 auto", padding: 24, textAlign: "center" }}>
          {!cafe ? (
            <p style={{ color: "var(--text-muted)" }}>Loading…</p>
          ) : checkinUrl ? (
            <>
              <div style={{ display: "inline-block", padding: 24, background: "#fff", borderRadius: 12, border: "1px solid var(--border-default)", marginBottom: 16 }}>
                <QRCodeSVG id="loyalty-qr-svg" value={checkinUrl} size={220} level="H" />
              </div>
              <p style={{ fontWeight: 600, marginBottom: 4 }}>Scan to Check In</p>
              <p style={{ fontSize: "0.8rem", color: "var(--text-muted)", wordBreak: "break-all", marginBottom: 8 }}>{checkinUrl}</p>
              <a href={`${window.location.origin}/reviews/${cafe.slug}`} target="_blank" rel="noopener noreferrer" style={{ fontSize: "0.8rem", color: "var(--primary)", marginBottom: 16, display: "inline-block" }}>Public reviews page →</a>
              <div style={{ display: "flex", gap: 8, justifyContent: "center" }}>
                <button className="btn-outline" onClick={handleDownloadQR} style={{ display: "flex", alignItems: "center", gap: 6 }}>
                  <Download size={16} /> Download
                </button>
                <button className="btn-primary" onClick={() => window.print()} style={{ display: "flex", alignItems: "center", gap: 6 }}>
                  <Printer size={16} /> Print
                </button>
              </div>
            </>
          ) : (
            <p style={{ color: "var(--text-muted)" }}>Cafe has no slug. Add a slug in Supabase.</p>
          )}
        </div>
      )}

      {tab === "settings" && (
        <div style={{ maxWidth: 480, padding: 24 }}>
          {settingsLoading && <p style={{ color: "var(--text-muted)" }}>Loading…</p>}
          {!settingsLoading && settings !== undefined && (
            <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
              <div>
                <label style={{ display: "block", fontSize: "0.875rem", fontWeight: 500, marginBottom: 12 }}>Points Ratio</label>
                <div style={{ display: "flex", gap: 12, alignItems: "flex-end" }}>
                  <div style={{ flex: 1 }}>
                    <span style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>Every AED spent</span>
                    <input type="number" value={settingsForm.spendAmount} onChange={(e) => setSettingsForm((s) => ({ ...s, spendAmount: e.target.value }))} style={{ width: "100%", padding: "8px 12px", borderRadius: 8, border: "1px solid var(--border-default)", marginTop: 4 }} />
                  </div>
                  <div style={{ flex: 1 }}>
                    <span style={{ fontSize: "0.75rem", color: "var(--text-muted)" }}>Awards</span>
                    <input type="number" value={settingsForm.pointsAwarded} onChange={(e) => setSettingsForm((s) => ({ ...s, pointsAwarded: e.target.value }))} style={{ width: "100%", padding: "8px 12px", borderRadius: 8, border: "1px solid var(--border-default)", marginTop: 4 }} />
                  </div>
                </div>
              </div>
              <div>
                <label style={{ display: "block", fontSize: "0.875rem", fontWeight: 500, marginBottom: 12 }}>Welcome points (per check-in)</label>
                <input type="number" value={settingsForm.welcomePoints} onChange={(e) => setSettingsForm((s) => ({ ...s, welcomePoints: e.target.value }))} style={{ width: "100%", padding: "8px 12px", borderRadius: 8, border: "1px solid var(--border-default)" }} />
              </div>
              <div>
                <label style={{ display: "block", fontSize: "0.875rem", fontWeight: 500, marginBottom: 12 }}>Referral points</label>
                <input type="number" value={settingsForm.referralPoints} onChange={(e) => setSettingsForm((s) => ({ ...s, referralPoints: e.target.value }))} style={{ width: "100%", padding: "8px 12px", borderRadius: 8, border: "1px solid var(--border-default)" }} />
              </div>
              <div>
                <label style={{ display: "block", fontSize: "0.875rem", fontWeight: 500, marginBottom: 12 }}>Google review URL</label>
                <input type="url" value={settingsForm.googleReviewUrl} onChange={(e) => setSettingsForm((s) => ({ ...s, googleReviewUrl: e.target.value }))} placeholder="https://..." style={{ width: "100%", padding: "8px 12px", borderRadius: 8, border: "1px solid var(--border-default)" }} />
              </div>
              <div>
                <label style={{ display: "block", fontSize: "0.875rem", fontWeight: 500, marginBottom: 12 }}>Zomato review URL</label>
                <input type="url" value={settingsForm.zomatoReviewUrl} onChange={(e) => setSettingsForm((s) => ({ ...s, zomatoReviewUrl: e.target.value }))} placeholder="https://..." style={{ width: "100%", padding: "8px 12px", borderRadius: 8, border: "1px solid var(--border-default)" }} />
              </div>
              <button className="btn-primary" onClick={() => settingsSaveMutation.mutate()} disabled={settingsSaveMutation.isPending}>
                {settingsSaveMutation.isPending ? "Saving…" : "Save"}
              </button>
            </div>
          )}
          {settings === null && (
            <div>
              <p style={{ marginBottom: 16, color: "var(--text-muted)" }}>No settings yet. Create default settings:</p>
              <button className="btn-primary" onClick={() => settingsSaveMutation.mutate()} disabled={settingsSaveMutation.isPending}>
                {settingsSaveMutation.isPending ? "Creating…" : "Create Default Settings"}
              </button>
            </div>
          )}
        </div>
      )}
    </section>
  );
}
