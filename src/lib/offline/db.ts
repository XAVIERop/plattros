import Dexie, { type Table } from "dexie";
import type { DraftOrderLineItem } from "@/lib/offline/menu";

export type OutboxStatus = "pending" | "syncing" | "synced" | "failed";

export interface OfflineOrderDraft {
  id: string;
  ticketNo: string;
  idempotencyKey: string;
  cafeId: string;
  createdByUserId?: string;
  sessionId?: string;
  terminalId?: string;
  orderMode: "delivery" | "dine_in" | "takeaway";
  notes?: string;
  customerName?: string;
  customerPhone?: string;
  deliveryBlock?: string;
  deliveryAddress?: string;
  tableNumber?: string;
  items: DraftOrderLineItem[];
  subtotalAmount?: number;
  discountAmount?: number;
  serviceChargeAmount?: number;
  totalAmount: number;
  paymentMethod: "cash" | "card" | "upi" | "split";
  splitAmounts?: { cash: number; card: number; upi: number };
  createdAt: string;
}

export interface OutboxItem {
  id: string;
  channel: "orders";
  payload: OfflineOrderDraft;
  status: OutboxStatus;
  attempts: number;
  lastError?: string;
  nextRetryAt?: string;
  createdAt: string;
  updatedAt: string;
}

export type PrintJobStatus = "queued" | "printed" | "failed";
export type PrintJobType = "kot" | "bill";
export type PrintStation = "kitchen" | "counter";

export interface PrintQueueItem {
  id: string;
  orderId: string;
  ticketNo: string;
  payload: {
    lines: string[];
    jobType?: PrintJobType;
    station?: PrintStation;
    metadata?: Record<string, unknown>;
  };
  status: PrintJobStatus;
  attempts?: number;
  lastError?: string;
  nextRetryAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface CachedMenuItem {
  id: string;
  name: string;
  price: number;
  category?: string | null;
  isAvailable: boolean;
  updatedAt: string;
}

class BhursasPosDB extends Dexie {
  offlineOrders!: Table<OfflineOrderDraft, string>;
  outbox!: Table<OutboxItem, string>;
  printQueue!: Table<PrintQueueItem, string>;
  menuCache!: Table<CachedMenuItem, string>;

  constructor() {
    super("bhursas_pos_db");

    this.version(4).stores({
      offlineOrders: "id, ticketNo, createdAt",
      outbox: "id, channel, status, createdAt, updatedAt",
      printQueue: "id, orderId, status, createdAt, updatedAt, payload.jobType, payload.station",
      menuCache: "id, name, category, isAvailable, updatedAt"
    });
  }
}

export const db = new BhursasPosDB();
