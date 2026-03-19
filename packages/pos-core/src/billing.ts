export type DiscountMode = "amount" | "percent";

export interface BillingTotalsInput {
  subtotal: number;
  discountMode: DiscountMode;
  discountInput: number;
  serviceCharge: number;
  /** Extra discount from loyalty reward redemption (₹) */
  rewardDiscount?: number;
}

export interface BillingTotalsResult {
  subtotal: number;
  discountAmount: number;
  serviceChargeAmount: number;
  total: number;
}

export function calculateBillingTotals(input: BillingTotalsInput): BillingTotalsResult {
  const subtotal = Math.max(0, Math.round(input.subtotal));
  const rawDiscount = Math.max(0, input.discountInput || 0);
  const baseDiscount =
    input.discountMode === "percent"
      ? Math.round((subtotal * Math.min(100, rawDiscount)) / 100)
      : Math.round(rawDiscount);
  const rewardDiscount = Math.max(0, Math.round(input.rewardDiscount || 0));
  const discountAmount = baseDiscount + rewardDiscount;
  const serviceChargeAmount = Math.max(0, Math.round(input.serviceCharge || 0));
  const total = Math.max(0, subtotal - discountAmount + serviceChargeAmount);

  return {
    subtotal,
    discountAmount,
    serviceChargeAmount,
    total
  };
}
