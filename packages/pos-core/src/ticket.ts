export function parseTicketSequence(ticketNo: string): number {
  const match = /^BH-(\d+)$/.exec(ticketNo.trim().toUpperCase());
  if (!match) return 0;
  return Number.parseInt(match[1], 10) || 0;
}

export function getNextTicketNumber(existingOrderNumbers: string[], storedCounter?: number): {
  ticketNo: string;
  nextCounter: number;
} {
  const knownMax = existingOrderNumbers.reduce(
    (max, orderNo) => Math.max(max, parseTicketSequence(orderNo)),
    0
  );
  const safeStored = Number.isFinite(storedCounter) ? Math.max(0, Math.floor(storedCounter || 0)) : 0;
  const nextCounter = Math.max(knownMax, safeStored) + 1;
  return {
    ticketNo: `BH-${String(nextCounter).padStart(3, "0")}`,
    nextCounter
  };
}
