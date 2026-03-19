import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/lib/supabase/client";
import { Gift } from "lucide-react";
import type { DraftOrderLineItem } from "@/lib/offline/menu";

function toKey(phone: string) {
  return (phone || "").replace(/\D/g, "").replace(/^91/, "").slice(-10);
}

interface RedeemRewardSectionProps {
  cafeId: string | null;
  customerPhone: string;
  cartItems: DraftOrderLineItem[];
  setCartItems: React.Dispatch<React.SetStateAction<DraftOrderLineItem[]>>;
  redeemedRewardId: string | null;
  setRedeemedRewardId: React.Dispatch<React.SetStateAction<string | null>>;
  onRedeemApplied: (amount: number) => void;
}

export function RedeemRewardSection({
  cafeId,
  customerPhone,
  cartItems,
  setCartItems,
  redeemedRewardId,
  setRedeemedRewardId,
  onRedeemApplied,
}: RedeemRewardSectionProps) {
  const phoneKey = toKey(customerPhone);

  const { data: loyaltyCustomer } = useQuery({
    queryKey: ["loyalty-customer-points", cafeId, phoneKey],
    queryFn: async () => {
      if (!cafeId || phoneKey.length < 10) return null;
      const { data, error } = await supabase.from("loyalty_customers").select("phone, points").eq("cafe_id", cafeId);
      if (error) return null;
      const match = (data || []).find((r) => toKey(r.phone) === phoneKey);
      return match || null;
    },
    enabled: !!cafeId && phoneKey.length >= 10,
  });

  const { data: rewards = [] } = useQuery({
    queryKey: ["loyalty-rewards", cafeId],
    queryFn: async () => {
      if (!cafeId) return [];
      const { data, error } = await supabase.from("loyalty_rewards").select("*").eq("cafe_id", cafeId).eq("active", true);
      if (error) throw error;
      return data || [];
    },
    enabled: !!cafeId,
  });

  const points = loyaltyCustomer?.points ?? 0;
  const affordableRewards = rewards.filter((r) => r.points_cost <= points);

  const handleRedeem = (reward: { id: string; name: string; type: string; points_cost: number; discount_value?: number }) => {
    if (redeemedRewardId) return;
    setRedeemedRewardId(reward.id);
    if (reward.type === "discount") {
      const value = reward.discount_value ?? 20;
      onRedeemApplied(value);
    } else if (reward.type === "free_item") {
      const freeItem: DraftOrderLineItem = {
        productId: `reward-${reward.id}`,
        productName: `[FREE] ${reward.name}`,
        quantity: 1,
        unitPrice: 0,
        lineTotal: 0,
        selections: {},
      };
      setCartItems((prev) => [...prev, freeItem]);
    }
  };

  const handleClear = () => {
    const id = redeemedRewardId;
    setRedeemedRewardId(null);
    onRedeemApplied(0);
    if (id) {
      setCartItems((prev) => prev.filter((i) => i.productId !== `reward-${id}`));
    }
  };

  if (affordableRewards.length === 0 && !redeemedRewardId) return null;

  return (
    <div style={{ marginTop: 12, padding: 12, borderRadius: 8, background: "var(--bg-subtle, #f8fafc)", border: "1px solid var(--border-default)" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 8, fontSize: "0.85rem" }}>
        <Gift size={16} />
        <span style={{ fontWeight: 600 }}>Redeem points</span>
        <span style={{ color: "var(--text-muted)" }}>({points} pts)</span>
      </div>
      {redeemedRewardId ? (
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <span style={{ fontSize: "0.85rem", color: "var(--success, #16a34a)" }}>✓ Reward applied</span>
          <button type="button" className="ghost" onClick={handleClear} style={{ fontSize: "0.8rem" }}>
            Remove
          </button>
        </div>
      ) : (
        <div style={{ display: "flex", flexWrap: "wrap", gap: 6 }}>
          {affordableRewards.map((r) => (
            <button
              key={r.id}
              type="button"
              className="btn-outline"
              onClick={() => handleRedeem(r)}
              style={{ padding: "6px 12px", fontSize: "0.8rem" }}
            >
              {r.name} ({r.points_cost} pts)
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
