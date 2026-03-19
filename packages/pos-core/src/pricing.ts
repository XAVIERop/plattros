export interface PricingLineItem {
  id: string;
  quantity: number;
  unitPrice: number;
  totalPrice?: number;
}

export interface OfferRule {
  id: string;
  type: "percent" | "flat";
  value: number;
  maxDiscount?: number;
}

export interface LoyaltyRedemption {
  pointsUsed: number;
  currencyValue: number;
}

export interface PricingInput {
  items: PricingLineItem[];
  serviceCharge: number;
  taxPercent: number;
  offers?: OfferRule[];
  loyalty?: LoyaltyRedemption | null;
}

export interface PricingBreakdown {
  subtotal: number;
  offersDiscount: number;
  loyaltyDiscount: number;
  serviceChargeAmount: number;
  taxAmount: number;
  total: number;
}

function roundCurrency(value: number): number {
  return Math.round(value * 100) / 100;
}

export function calculateUnifiedPricing(input: PricingInput): PricingBreakdown {
  const subtotal = roundCurrency(
    input.items.reduce((sum, item) => sum + (item.totalPrice ?? item.unitPrice * item.quantity), 0)
  );

  const offersDiscount = roundCurrency(
    (input.offers || []).reduce((sum, offer) => {
      if (offer.type === "percent") {
        const raw = (subtotal * Math.max(0, offer.value)) / 100;
        const bounded = offer.maxDiscount ? Math.min(raw, offer.maxDiscount) : raw;
        return sum + bounded;
      }
      return sum + Math.max(0, offer.value);
    }, 0)
  );

  const loyaltyDiscount = roundCurrency(Math.max(0, input.loyalty?.currencyValue || 0));
  const afterDiscounts = Math.max(0, subtotal - offersDiscount - loyaltyDiscount);
  const serviceChargeAmount = roundCurrency(Math.max(0, input.serviceCharge || 0));
  const taxableAmount = Math.max(0, afterDiscounts + serviceChargeAmount);
  const taxAmount = roundCurrency((taxableAmount * Math.max(0, input.taxPercent || 0)) / 100);
  const total = roundCurrency(afterDiscounts + serviceChargeAmount + taxAmount);

  return {
    subtotal,
    offersDiscount,
    loyaltyDiscount,
    serviceChargeAmount,
    taxAmount,
    total
  };
}
