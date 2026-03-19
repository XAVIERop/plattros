export type PosOrderStatus =
  | "received"
  | "confirmed"
  | "preparing"
  | "on_the_way"
  | "completed"
  | "cancelled";

export type PosOrderType = "delivery" | "takeaway" | "dine_in" | "table_order" | string;
export type PosPaymentStatus = "pending" | "paid" | "failed" | "refunded" | null;

export interface StatusGuardInput {
  currentStatus: PosOrderStatus;
  targetStatus: PosOrderStatus;
  paymentStatus: PosPaymentStatus;
  orderType: PosOrderType;
}

export function isDineInLike(orderType: PosOrderType): boolean {
  return orderType === "dine_in" || orderType === "table_order";
}

export function canTransitionStatus(input: StatusGuardInput): { ok: boolean; reason?: string } {
  if (input.currentStatus === "cancelled" || input.currentStatus === "completed") {
    return { ok: false, reason: `Cannot update ${input.currentStatus} orders` };
  }

  // Keep parity with secure backend guard used in FoodClub POS.
  if (input.paymentStatus === "pending" && input.targetStatus !== "received" && !isDineInLike(input.orderType)) {
    return { ok: false, reason: "Payment pending" };
  }

  return { ok: true };
}

export function getNextStatus(current: PosOrderStatus): PosOrderStatus | null {
  if (current === "received") return "confirmed";
  if (current === "confirmed") return "preparing";
  if (current === "preparing") return "on_the_way";
  if (current === "on_the_way") return "completed";
  return null;
}
