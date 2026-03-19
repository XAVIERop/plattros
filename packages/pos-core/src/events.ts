export const PLATFORM_EVENT_TOPICS = {
  orderCreated: "order.created",
  orderStatusChanged: "order.status_changed",
  orderUpdated: "order.updated",
  kitchenBumped: "kitchen.bumped",
  tableSessionUpdated: "table.session_updated",
  offerRedeemed: "offer.redeemed",
  loyaltyCredited: "loyalty.credited",
  notificationQueued: "notification.queued"
} as const;

export type PlatformEventTopic = (typeof PLATFORM_EVENT_TOPICS)[keyof typeof PLATFORM_EVENT_TOPICS];

export interface PlatformEventEnvelope<TPayload> {
  id: string;
  topic: PlatformEventTopic;
  tenantId: string;
  storeId?: string | null;
  occurredAt: string;
  actorId?: string | null;
  payload: TPayload;
}

export function makeEvent<TPayload>(
  topic: PlatformEventTopic,
  tenantId: string,
  payload: TPayload,
  options?: { storeId?: string | null; actorId?: string | null }
): PlatformEventEnvelope<TPayload> {
  return {
    id: crypto.randomUUID(),
    topic,
    tenantId,
    storeId: options?.storeId ?? null,
    actorId: options?.actorId ?? null,
    occurredAt: new Date().toISOString(),
    payload
  };
}
