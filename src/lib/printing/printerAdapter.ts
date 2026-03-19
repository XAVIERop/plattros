import { supabase } from "@/lib/supabase/client";
import type { PrintQueueItem } from "@/lib/offline/db";

export async function printQueuedTicket(job: PrintQueueItem, cafeId?: string | null) {
  if (!navigator.onLine) {
    throw new Error("Cannot print while offline");
  }
  if (!cafeId) {
    throw new Error("Missing cafeId for secure print routing");
  }

  const payload = {
    action: job.payload.jobType === "bill" ? "print_receipt" : "print_kot",
    cafe_id: cafeId,
    ...(job.payload.jobType === "bill"
      ? { receipt_data: job.payload.lines.join("\n") }
      : { kot_data: job.payload.lines.join("\n") })
  };

  const { data, error } = await supabase.functions.invoke("printnode-secure", {
    body: payload
  });

  if (error) {
    throw error;
  }

  if (!data?.success) {
    throw new Error(data?.error || "Print failed");
  }
}
