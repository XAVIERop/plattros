export type CoffeeSize = "small" | "medium" | "large";
export type MilkType = "regular" | "skim" | "soy" | "oat" | "almond";

export interface CoffeeProduct {
  id: string;
  name: string;
  basePrice: number;
  category: string;
  availableFrom?: string | null;  // "HH:MM" e.g. "07:00"
  availableUntil?: string | null; // "HH:MM" e.g. "11:00" — null means always available
}

export interface CoffeeSelections {
  size: CoffeeSize;
  milk: MilkType;
  sugarLevel: "no_sugar" | "less" | "regular";
  extraShots: number;
}

/** Generic modifier selections: { modifierGroupId: modifierOptionId } */
export type GenericModifierSelections = Record<string, string>;

/** Selections can be legacy coffee (size, milk, etc.) or generic backend modifiers */
export type ModifierSelections = CoffeeSelections | GenericModifierSelections;

export interface DraftOrderLineItem {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  lineTotal: number;
  selections: ModifierSelections;
}

export const BHURSAS_MENU: CoffeeProduct[] = [
  // Espresso (8)
  { id: "cf_espresso_single", name: "Espresso Single", basePrice: 95, category: "espresso" },
  { id: "cf_espresso_double", name: "Espresso Double", basePrice: 120, category: "espresso" },
  { id: "cf_americano", name: "Americano", basePrice: 120, category: "espresso" },
  { id: "cf_ristretto", name: "Ristretto", basePrice: 110, category: "espresso" },
  { id: "cf_lungo", name: "Lungo", basePrice: 125, category: "espresso" },
  { id: "cf_piccolo", name: "Piccolo", basePrice: 135, category: "espresso" },
  { id: "cf_macchiato", name: "Espresso Macchiato", basePrice: 140, category: "espresso" },
  { id: "cf_cortado", name: "Cortado", basePrice: 145, category: "espresso" },

  // Latte (9)
  { id: "cf_cappuccino", name: "Cappuccino", basePrice: 150, category: "latte" },
  { id: "cf_flat_white", name: "Flat White", basePrice: 165, category: "latte" },
  { id: "cf_cafe_latte", name: "Cafe Latte", basePrice: 160, category: "latte" },
  { id: "cf_mocha", name: "Cafe Mocha", basePrice: 175, category: "latte" },
  { id: "cf_vanilla_latte", name: "Vanilla Latte", basePrice: 185, category: "latte" },
  { id: "cf_hazelnut_latte", name: "Hazelnut Latte", basePrice: 190, category: "latte" },
  { id: "cf_caramel_latte", name: "Caramel Latte", basePrice: 190, category: "latte" },
  { id: "cf_white_mocha", name: "White Mocha", basePrice: 195, category: "latte" },
  { id: "cf_spanish_latte", name: "Spanish Latte", basePrice: 200, category: "latte" },

  // Cold (10)
  { id: "cf_cold_brew", name: "Cold Brew", basePrice: 180, category: "cold" },
  { id: "cf_iced_americano", name: "Iced Americano", basePrice: 165, category: "cold" },
  { id: "cf_iced_latte", name: "Iced Latte", basePrice: 180, category: "cold" },
  { id: "cf_iced_mocha", name: "Iced Mocha", basePrice: 195, category: "cold" },
  { id: "cf_iced_vanilla_latte", name: "Iced Vanilla Latte", basePrice: 200, category: "cold" },
  { id: "cf_affogato", name: "Affogato", basePrice: 210, category: "cold" },
  { id: "cf_tonic_espresso", name: "Espresso Tonic", basePrice: 190, category: "cold" },
  { id: "cf_frappe_classic", name: "Classic Frappe", basePrice: 205, category: "cold" },
  { id: "cf_frappe_mocha", name: "Mocha Frappe", basePrice: 220, category: "cold" },
  { id: "cf_shakerato", name: "Shakerato", basePrice: 185, category: "cold" },

  // Manual (8)
  { id: "cf_pour_over", name: "Pour Over", basePrice: 175, category: "manual" },
  { id: "cf_aeropress", name: "AeroPress", basePrice: 180, category: "manual" },
  { id: "cf_french_press", name: "French Press", basePrice: 185, category: "manual" },
  { id: "cf_chemex", name: "Chemex", basePrice: 195, category: "manual" },
  { id: "cf_v60", name: "V60", basePrice: 190, category: "manual" },
  { id: "cf_siphon", name: "Siphon Brew", basePrice: 225, category: "manual" },
  { id: "cf_kalita_wave", name: "Kalita Wave", basePrice: 195, category: "manual" },
  { id: "cf_clever_dripper", name: "Clever Dripper", basePrice: 185, category: "manual" }
];

const SIZE_MULTIPLIER: Record<CoffeeSize, number> = {
  small: 1,
  medium: 1.2,
  large: 1.4
};

const MILK_SURCHARGE: Record<MilkType, number> = {
  regular: 0,
  skim: 10,
  soy: 20,
  oat: 25,
  almond: 25
};

export function calculateCoffeePrice(product: CoffeeProduct, selections: CoffeeSelections) {
  const coffeeCategories = ["espresso", "latte", "cold", "manual"];
  const isCoffee = coffeeCategories.includes(product.category.toLowerCase());

  if (!isCoffee) {
    return product.basePrice;
  }

  const sizedPrice = product.basePrice * (SIZE_MULTIPLIER[selections.size] || 1);
  const shotsCost = (selections.extraShots || 0) * 20;
  return Math.round(sizedPrice + (MILK_SURCHARGE[selections.milk] || 0) + shotsCost);
}
