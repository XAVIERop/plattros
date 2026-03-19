import { useCallback, useEffect, useState } from "react";
import { supabase } from "@/lib/supabase/client";

export interface ModifierOption {
  id: string;
  modifierGroupId: string;
  name: string;
  priceModifier: number;
  displayOrder: number;
  isDefault: boolean;
}

export interface ModifierGroup {
  id: string;
  cafeId: string;
  name: string;
  displayOrder: number;
  isRequired: boolean;
  minSelections: number;
  maxSelections: number;
  options: ModifierOption[];
}

export interface MenuItemModifiers {
  menuItemId: string;
  modifierGroups: ModifierGroup[];
}

const SYNC_MODE = import.meta.env.VITE_BHURSAS_SYNC_MODE || "demo";

export function useCafeModifiers(cafeId: string | null) {
  const [modifierGroupsByCafe, setModifierGroupsByCafe] = useState<Record<string, ModifierGroup[]>>({});
  const [menuItemModifiers, setMenuItemModifiers] = useState<Record<string, ModifierGroup[]>>({});
  const [loading, setLoading] = useState(false);

  const fetchModifiers = useCallback(async () => {
    if (!cafeId || SYNC_MODE === "demo") {
      setModifierGroupsByCafe({});
      setMenuItemModifiers({});
      return;
    }

    setLoading(true);
    try {
      const { data: groups, error: groupsErr } = await supabase
        .from("modifier_groups")
        .select("id, cafe_id, name, display_order, is_required, min_selections, max_selections")
        .eq("cafe_id", cafeId)
        .order("display_order", { ascending: true });

      if (groupsErr) {
        console.warn("Modifier groups fetch failed:", groupsErr);
        setModifierGroupsByCafe({});
        setLoading(false);
        return;
      }

      if (!groups || groups.length === 0) {
        setModifierGroupsByCafe({ [cafeId]: [] });
        setLoading(false);
        return;
      }

      const groupIds = groups.map((g) => g.id);
      const { data: options, error: optionsErr } = await supabase
        .from("modifier_options")
        .select("id, modifier_group_id, name, price_modifier, display_order, is_default")
        .in("modifier_group_id", groupIds)
        .order("display_order", { ascending: true });

      if (optionsErr) {
        console.warn("Modifier options fetch failed:", optionsErr);
      }

      const optionsByGroup = (options || []).reduce<Record<string, ModifierOption[]>>((acc, o) => {
        const list = acc[o.modifier_group_id] || [];
        list.push({
          id: o.id,
          modifierGroupId: o.modifier_group_id,
          name: o.name,
          priceModifier: Number(o.price_modifier || 0),
          displayOrder: o.display_order || 0,
          isDefault: o.is_default || false
        });
        acc[o.modifier_group_id] = list;
        return acc;
      }, {});

      const mapped: ModifierGroup[] = groups.map((g) => ({
        id: g.id,
        cafeId: g.cafe_id,
        name: g.name,
        displayOrder: g.display_order || 0,
        isRequired: g.is_required || false,
        minSelections: g.min_selections ?? 1,
        maxSelections: g.max_selections ?? 1,
        options: (optionsByGroup[g.id] || []).sort((a, b) => a.displayOrder - b.displayOrder)
      }));

      setModifierGroupsByCafe((prev) => ({ ...prev, [cafeId]: mapped }));

      const { data: links, error: linksErr } = await supabase
        .from("menu_item_modifier_groups")
        .select("menu_item_id, modifier_group_id")
        .in("modifier_group_id", groupIds);

      if (linksErr) {
        setLoading(false);
        return;
      }

      const byMenuItem: Record<string, ModifierGroup[]> = {};
      (links || []).forEach((link) => {
        const group = mapped.find((g) => g.id === link.modifier_group_id);
        if (group) {
          const list = byMenuItem[link.menu_item_id] || [];
          if (!list.some((g) => g.id === group.id)) list.push(group);
          byMenuItem[link.menu_item_id] = list.sort((a, b) => a.displayOrder - b.displayOrder);
        }
      });
      setMenuItemModifiers(byMenuItem);
    } finally {
      setLoading(false);
    }
  }, [cafeId]);

  useEffect(() => {
    void fetchModifiers();
  }, [fetchModifiers]);

  const getModifiersForItem = useCallback(
    (menuItemId: string): ModifierGroup[] => {
      return menuItemModifiers[menuItemId] || [];
    },
    [menuItemModifiers]
  );

  const calculatePriceWithModifiers = useCallback(
    (basePrice: number, selections: Record<string, string>): number => {
      let total = basePrice;
      Object.entries(selections).forEach(([groupId, optionId]) => {
        const groups = modifierGroupsByCafe[cafeId || ""] || [];
        for (const g of groups) {
          if (g.id === groupId) {
            const opt = g.options.find((o) => o.id === optionId);
            if (opt) total += opt.priceModifier;
            break;
          }
        }
      });
      return Math.round(total);
    },
    [modifierGroupsByCafe, cafeId]
  );

  const getDefaultSelections = useCallback(
    (groups: ModifierGroup[]): Record<string, string> => {
      return groups.reduce<Record<string, string>>((acc, g) => {
        const defaultOpt = g.options.find((o) => o.isDefault) || g.options[0];
        if (defaultOpt) acc[g.id] = defaultOpt.id;
        return acc;
      }, {});
    },
    []
  );

  const getOptionPrice = useCallback(
    (groupId: string, optionId: string): number => {
      const groups = modifierGroupsByCafe[cafeId || ""] || [];
      for (const g of groups) {
        if (g.id === groupId) {
          const opt = g.options.find((o) => o.id === optionId);
          return opt ? opt.priceModifier : 0;
        }
      }
      return 0;
    },
    [modifierGroupsByCafe, cafeId]
  );

  return {
    modifierGroups: modifierGroupsByCafe[cafeId || ""] || [],
    menuItemModifiers,
    getModifiersForItem,
    getDefaultSelections,
    getOptionPrice,
    calculatePriceWithModifiers,
    loading,
    refresh: fetchModifiers
  };
}
