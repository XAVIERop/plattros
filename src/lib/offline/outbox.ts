import {
  db,
  type OfflineOrderDraft,
  type PrintJobType,
  type PrintStation,
  type OutboxItem,
  type PrintQueueItem
} from "@/lib/offline/db";
import { createKotLines } from "@pos-core";

function nowIso() {
  return new Date().toISOString();
}

const MAX_RETRY_ATTEMPTS = 5;
const BASE_RETRY_SECONDS = 8;

export async function enqueueOrderDraft(order: OfflineOrderDraft) {
  const ts = nowIso();

  await db.transaction("rw", db.offlineOrders, db.outbox, db.printQueue, async () => {
    await db.offlineOrders.put(order);

    const outboxItem: OutboxItem = {
      id: crypto.randomUUID(),
      channel: "orders",
      payload: order,
      status: "pending",
      attempts: 0,
      createdAt: ts,
      updatedAt: ts
    };

    await db.outbox.put(outboxItem);

    const printLines = createKotLines({
      ticketNo: order.ticketNo,
      orderMode: order.orderMode,
      items: order.items.map((item) => ({
        productName: item.productName,
        quantity: item.quantity,
        lineTotal: item.lineTotal
      })),
      subtotal: order.subtotalAmount ?? order.totalAmount,
      discount: order.discountAmount ?? 0,
      serviceCharge: order.serviceChargeAmount ?? 0,
      total: order.totalAmount
    });

    const printItem: PrintQueueItem = {
      id: crypto.randomUUID(),
      orderId: order.id,
      ticketNo: order.ticketNo,
      payload: {
        lines: printLines,
        jobType: "kot",
        station: "kitchen"
      },
      status: "queued",
      createdAt: ts,
      updatedAt: ts
    };

    await db.printQueue.put(printItem);
  });
}

export async function listPendingOutbox(limit = 20) {
  return db.outbox.where("status").equals("pending").limit(limit).toArray();
}

export async function listRecentOutbox(limit = 100) {
  return db.outbox.orderBy("createdAt").reverse().limit(limit).toArray();
}

export async function markOutboxSyncing(id: string) {
  await db.outbox.update(id, {
    status: "syncing",
    updatedAt: nowIso()
  });
}

export async function markOutboxSynced(id: string) {
  await db.outbox.update(id, {
    status: "synced",
    lastError: undefined,
    nextRetryAt: undefined,
    updatedAt: nowIso()
  });
}

export async function markOutboxFailed(id: string, previousAttempts: number, err: unknown) {
  const message = err instanceof Error ? err.message : String(err);
  const nextAttempts = previousAttempts + 1;
  const retryDelaySeconds = Math.min(240, BASE_RETRY_SECONDS * 2 ** Math.max(0, nextAttempts - 1));
  const nextRetryAt = new Date(Date.now() + retryDelaySeconds * 1000).toISOString();
  await db.outbox.update(id, {
    status: "failed",
    attempts: nextAttempts,
    lastError: message,
    nextRetryAt,
    updatedAt: nowIso()
  });
}

export async function resetFailedToPending() {
  const now = new Date().toISOString();
  const failed = await db.outbox.where("status").equals("failed").toArray();
  await Promise.all(
    failed.map((item) =>
      item.attempts >= MAX_RETRY_ATTEMPTS || (item.nextRetryAt && item.nextRetryAt > now)
        ? Promise.resolve()
        : db.outbox.update(item.id, {
            status: "pending",
            updatedAt: nowIso()
          })
    )
  );
}

export async function retryOutboxItem(id: string) {
  await db.outbox.update(id, {
    status: "pending",
    updatedAt: nowIso()
  });
}

export async function listQueuedPrintJobs(limit = 20) {
  return db.printQueue.where("status").equals("queued").limit(limit).toArray();
}

export async function listRecentPrintJobs(limit = 100) {
  return db.printQueue.orderBy("createdAt").reverse().limit(limit).toArray();
}

export async function markPrintJobPrinted(id: string) {
  await db.printQueue.update(id, {
    status: "printed",
    attempts: 0,
    lastError: undefined,
    nextRetryAt: undefined,
    updatedAt: nowIso()
  });
}

export async function markPrintJobFailed(id: string, previousAttempts = 0, err?: unknown) {
  const nextAttempts = previousAttempts + 1;
  const retryDelaySeconds = Math.min(180, 6 * 2 ** Math.max(0, nextAttempts - 1));
  const nextRetryAt = new Date(Date.now() + retryDelaySeconds * 1000).toISOString();
  const message = err instanceof Error ? err.message : err ? String(err) : "Print failed";
  await db.printQueue.update(id, {
    status: "failed",
    attempts: nextAttempts,
    lastError: message,
    nextRetryAt,
    updatedAt: nowIso()
  });
}

export async function retryPrintJob(id: string) {
  await db.printQueue.update(id, {
    status: "queued",
    nextRetryAt: undefined,
    updatedAt: nowIso()
  });
}

export async function resetFailedPrintJobsToQueued() {
  const now = new Date().toISOString();
  const failed = await db.printQueue.where("status").equals("failed").toArray();
  await Promise.all(
    failed.map((item) =>
      (item.attempts || 0) >= MAX_RETRY_ATTEMPTS || (item.nextRetryAt && item.nextRetryAt > now)
        ? Promise.resolve()
        : db.printQueue.update(item.id, {
            status: "queued",
            updatedAt: nowIso()
          })
    )
  );
}

export async function enqueuePrintJob(params: {
  orderId: string;
  ticketNo: string;
  lines: string[];
  jobType: PrintJobType;
  station: PrintStation;
  metadata?: Record<string, unknown>;
}) {
  const ts = nowIso();
  const printItem: PrintQueueItem = {
    id: crypto.randomUUID(),
    orderId: params.orderId,
    ticketNo: params.ticketNo,
    payload: {
      lines: params.lines,
      jobType: params.jobType,
      station: params.station,
      metadata: params.metadata
    },
    status: "queued",
    createdAt: ts,
    updatedAt: ts
  };
  await db.printQueue.put(printItem);
}
