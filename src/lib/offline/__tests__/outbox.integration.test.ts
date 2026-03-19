import { describe, it, expect, beforeEach } from "vitest";
import { enqueueOrderDraft, listPendingOutbox, listRecentOutbox } from "../outbox";
import { db } from "../db";

describe("POS offline outbox integration", () => {
  beforeEach(async () => {
    await db.delete();
    await db.open();
  });

  it("enqueueOrderDraft creates order in offlineOrders, outbox, and printQueue", async () => {
    const draft = {
      id: crypto.randomUUID(),
      ticketNo: "BH-001",
      idempotencyKey: crypto.randomUUID(),
      cafeId: "cafe-123",
      orderMode: "takeaway" as const,
      items: [
        {
          productId: "item-1",
          productName: "Coffee",
          quantity: 2,
          unitPrice: 100,
          lineTotal: 200,
          selections: {},
        },
      ],
      totalAmount: 200,
      paymentMethod: "cash" as const,
      createdAt: new Date().toISOString(),
    };

    await enqueueOrderDraft(draft);

    const pending = await listPendingOutbox(10);
    expect(pending).toHaveLength(1);
    expect(pending[0].payload.ticketNo).toBe("BH-001");
    expect(pending[0].payload.cafeId).toBe("cafe-123");
    expect(pending[0].status).toBe("pending");

    const orders = await db.offlineOrders.toArray();
    expect(orders).toHaveLength(1);
    expect(orders[0].ticketNo).toBe("BH-001");

    const printJobs = await db.printQueue.toArray();
    expect(printJobs).toHaveLength(1);
    expect(printJobs[0].ticketNo).toBe("BH-001");
    expect(printJobs[0].payload.jobType).toBe("kot");
  });

  it("listRecentOutbox returns all outbox items", async () => {
    const draft1 = {
      id: crypto.randomUUID(),
      ticketNo: "BH-001",
      idempotencyKey: crypto.randomUUID(),
      cafeId: "cafe-123",
      orderMode: "dine_in" as const,
      items: [
        { productId: "i1", productName: "A", quantity: 1, unitPrice: 50, lineTotal: 50, selections: {} },
      ],
      totalAmount: 50,
      paymentMethod: "cash" as const,
      createdAt: new Date().toISOString(),
    };
    const draft2 = {
      ...draft1,
      id: crypto.randomUUID(),
      ticketNo: "BH-002",
      idempotencyKey: crypto.randomUUID(),
    };

    await enqueueOrderDraft(draft1);
    await enqueueOrderDraft(draft2);

    const recent = await listRecentOutbox(10);
    expect(recent).toHaveLength(2);
    const tickets = recent.map((r) => r.payload.ticketNo).sort();
    expect(tickets).toEqual(["BH-001", "BH-002"]);
  });
});
