import { useCallback, useEffect, useState } from "react";
import { BHURSAS_MENU, type CoffeeProduct } from "@/lib/offline/menu";
import { db } from "@/lib/offline/db";
import { supabase } from "@/lib/supabase/client";

const SYNC_MODE = import.meta.env.VITE_BHURSAS_SYNC_MODE || "demo";

// Helper: is a menu item available at the current time?
function isAvailableNow(from?: string | null, until?: string | null): boolean {
  if (!from && !until) return true; // no schedule = always available
  if (!from || !until) return true; // partial schedule = always available
  const now = new Date();
  const pad = (n: number) => String(n).padStart(2, "0");
  const currentTime = `${pad(now.getHours())}:${pad(now.getMinutes())}`;
  // Handle overnight windows (e.g. 22:00 - 02:00)
  if (from <= until) {
    return currentTime >= from && currentTime <= until;
  } else {
    return currentTime >= from || currentTime <= until;
  }
}

function mapRowToProduct(row: {
  id: string;
  name: string;
  price: number;
  category?: string | null;
  available_from?: string | null;
  available_until?: string | null;
}): CoffeeProduct {
  return { 
    id: row.id, 
    name: row.name, 
    basePrice: row.price, 
    category: row.category || "General",
    availableFrom: row.available_from ?? null,
    availableUntil: row.available_until ?? null,
  };
}

export function useCafeMenu(cafeId: string | null) {
  const [menu, setMenu] = useState<CoffeeProduct[]>(BHURSAS_MENU);
  const [loading, setLoading] = useState(true);
  const [source, setSource] = useState<"remote" | "cache" | "fallback">("fallback");

  const loadFromCache = useCallback(async () => {
    const cached = await db.menuCache.toArray();
    if (cached.length > 0) {
      setMenu(
        cached.map((row) => ({
          id: row.id,
          name: row.name,
          basePrice: row.price,
          category: row.category || "General"
        }))
      );
      setSource("cache");
      return true;
    }
    return false;
  }, []);

  const refresh = useCallback(async () => {
    setLoading(true);

    if (SYNC_MODE === "demo") {
      setMenu(BHURSAS_MENU);
      setSource("fallback");
      setLoading(false);
      return;
    }

    if (!navigator.onLine) {
      const hasCache = await loadFromCache();
      if (!hasCache) {
        setMenu(BHURSAS_MENU);
        setSource("fallback");
      }
      setLoading(false);
      return;
    }

    let query = supabase
      .from("menu_items")
      .select("id, name, price, category, available_from, available_until")
      .eq("is_available", true)
      .order("name", { ascending: true });

    if (cafeId) {
      query = query.eq("cafe_id", cafeId);
    }

    const { data, error } = await query;

    if (error || !data || data.length === 0) {
      const hasCache = await loadFromCache();
      if (!hasCache) {
        setMenu(BHURSAS_MENU);
        setSource("fallback");
      }
      setLoading(false);
      return;
    }

    const allMapped = data.map((row) => mapRowToProduct(row));
    const mapped = allMapped.filter((item) =>
      isAvailableNow(item.availableFrom, item.availableUntil)
    );
    setMenu(mapped);
    setSource("remote");

    const now = new Date().toISOString();
    await db.menuCache.clear();
    await db.menuCache.bulkPut(
      mapped.map((item) => ({
        id: item.id,
        name: item.name,
        price: item.basePrice,
        category: item.category,
        isAvailable: true,
        updatedAt: now
      }))
    );

    setLoading(false);
  }, [loadFromCache, cafeId]);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  return {
    menu,
    loading,
    source,
    refresh
  };
}
