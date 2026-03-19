import { describe, expect, it } from "vitest";
import { calculateBillingTotals } from "../billing";
import { canTransitionStatus, getNextStatus } from "../status";
import { getNextTicketNumber, parseTicketSequence } from "../ticket";

describe("pos-core billing", () => {
  it("calculates percent discount totals", () => {
    const totals = calculateBillingTotals({
      subtotal: 1000,
      discountMode: "percent",
      discountInput: 10,
      serviceCharge: 50
    });
    expect(totals.discountAmount).toBe(100);
    expect(totals.total).toBe(950);
  });
});

describe("pos-core status guards", () => {
  it("blocks non-dine-in pending payment progression", () => {
    const result = canTransitionStatus({
      currentStatus: "received",
      targetStatus: "confirmed",
      paymentStatus: "pending",
      orderType: "takeaway"
    });
    expect(result.ok).toBe(false);
  });

  it("allows dine-in pending payment progression", () => {
    const result = canTransitionStatus({
      currentStatus: "received",
      targetStatus: "confirmed",
      paymentStatus: "pending",
      orderType: "dine_in"
    });
    expect(result.ok).toBe(true);
  });
});

describe("pos-core ticketing", () => {
  it("parses and increments BH tickets", () => {
    expect(parseTicketSequence("BH-009")).toBe(9);
    const next = getNextTicketNumber(["BH-009", "BH-011"], 10);
    expect(next.ticketNo).toBe("BH-012");
    expect(next.nextCounter).toBe(12);
  });
});

describe("pos-core status flow", () => {
  it("returns next status chain", () => {
    expect(getNextStatus("received")).toBe("confirmed");
    expect(getNextStatus("on_the_way")).toBe("completed");
    expect(getNextStatus("completed")).toBeNull();
  });
});
