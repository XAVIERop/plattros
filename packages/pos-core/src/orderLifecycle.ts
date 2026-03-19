import type { PosOrderStatus } from "./status";

export type UnifiedOrderStage = "new" | "in_progress" | "completed" | "cancelled";

export interface OrderTransitionInput {
  currentStatus: PosOrderStatus;
  action: "start" | "ready" | "complete" | "cancel" | "reopen";
}

const ACTION_MAP: Record<OrderTransitionInput["action"], PosOrderStatus> = {
  start: "preparing",
  ready: "on_the_way",
  complete: "completed",
  cancel: "cancelled",
  reopen: "received"
};

const ALLOWED_TRANSITIONS: Record<PosOrderStatus, OrderTransitionInput["action"][]> = {
  received: ["start", "cancel"],
  confirmed: ["start", "cancel"],
  preparing: ["ready", "cancel"],
  on_the_way: ["complete", "cancel"],
  completed: ["reopen"],
  cancelled: ["reopen"]
};

export function classifyOrderStage(status: PosOrderStatus): UnifiedOrderStage {
  if (status === "completed") return "completed";
  if (status === "cancelled") return "cancelled";
  if (status === "received") return "new";
  return "in_progress";
}

export function getTransitionResult(input: OrderTransitionInput): { ok: boolean; nextStatus?: PosOrderStatus; reason?: string } {
  const allowed = ALLOWED_TRANSITIONS[input.currentStatus] || [];
  if (!allowed.includes(input.action)) {
    return { ok: false, reason: `Action ${input.action} is not allowed from ${input.currentStatus}` };
  }
  return { ok: true, nextStatus: ACTION_MAP[input.action] };
}
