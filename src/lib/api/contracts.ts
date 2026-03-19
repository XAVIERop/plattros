export type OrderStatus = "received" | "confirmed" | "preparing" | "on_the_way" | "completed" | "cancelled";

export interface UpdateOrderStatusRequest {
  orderId: string;
  newStatus: OrderStatus;
}

export interface UpdateOrderStatusResponse {
  success: boolean;
  error?: string;
  order?: {
    id: string;
    status: OrderStatus;
  };
}

export interface MarkPaymentReceivedRequest {
  orderId: string;
}

export interface MarkPaymentReceivedResponse {
  success: boolean;
  error?: string;
  order_id?: string;
  payment_status?: "paid";
  already_paid?: boolean;
}
