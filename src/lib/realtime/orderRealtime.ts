import { supabase } from "@/lib/supabase/client";

export function subscribeOrderRealtime(cafeId: string, onOrderChange: () => void): () => void {
  const channel = supabase
    .channel(`plattr-orders-${cafeId}`)
    .on(
      "postgres_changes",
      { event: "*", schema: "public", table: "orders", filter: `cafe_id=eq.${cafeId}` },
      () => onOrderChange()
    )
    .subscribe();

  return () => {
    void supabase.removeChannel(channel);
  };
}
