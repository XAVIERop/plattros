import type { PosOrderStatus } from "./status";

export interface PlatformTenant {
  id: string;
  name: string;
  slug: string;
  isActive: boolean;
  createdAt: string;
}

export interface PlatformStore {
  id: string;
  tenantId: string;
  name: string;
  code: string;
  timezone: string;
  currency: string;
  isActive: boolean;
  createdAt: string;
}

export interface PlatformMenuItem {
  id: string;
  tenantId: string;
  storeId: string;
  name: string;
  category: string;
  basePrice: number;
  isAvailable: boolean;
}

export interface PlatformOrderItem {
  id: string;
  menuItemId: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
  notes?: string | null;
}

export interface PlatformOrder {
  id: string;
  tenantId: string;
  storeId: string;
  orderNumber: string;
  channel: "customer_app" | "pos" | "table_qr";
  orderType: "pickup" | "table_dining";
  status: PosOrderStatus;
  paymentStatus: "pending" | "paid" | "failed" | "refunded";
  scheduledFor?: string | null;
  tableNumber?: string | null;
  customerName?: string | null;
  customerPhone?: string | null;
  subtotal: number;
  discountAmount: number;
  taxAmount: number;
  serviceChargeAmount: number;
  totalAmount: number;
  createdAt: string;
}
