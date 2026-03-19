export interface SimplePrintLineItem {
  productName: string;
  quantity: number;
  lineTotal: number;
}

export interface PrintPayloadInput {
  ticketNo: string;
  orderMode: string;
  items: SimplePrintLineItem[];
  subtotal: number;
  discount: number;
  serviceCharge: number;
  total: number;
}

export function createKotLines(input: PrintPayloadInput): string[] {
  return [
    `Ticket: ${input.ticketNo}`,
    `Mode: ${input.orderMode}`,
    ...input.items.map((item) => `${item.quantity}x ${item.productName} - INR ${item.lineTotal}`),
    `Subtotal: INR ${input.subtotal}`,
    `Discount: INR ${input.discount}`,
    `Service: INR ${input.serviceCharge}`,
    `Total: INR ${input.total}`
  ];
}
