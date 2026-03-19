import { db } from "@/lib/offline/db";
import { resetFailedPrintJobsToQueued, resetFailedToPending } from "@/lib/offline/outbox";

export interface RecoverySummary {
  recoveredOutbox: number;
  recoveredPrintJobs: number;
}

export async function recoverOfflineOpsQueues(): Promise<RecoverySummary> {
  const [beforeFailedOutbox, beforeFailedPrints] = await Promise.all([
    db.outbox.where("status").equals("failed").count(),
    db.printQueue.where("status").equals("failed").count()
  ]);

  await Promise.all([resetFailedToPending(), resetFailedPrintJobsToQueued()]);

  const [afterFailedOutbox, afterFailedPrints] = await Promise.all([
    db.outbox.where("status").equals("failed").count(),
    db.printQueue.where("status").equals("failed").count()
  ]);

  return {
    recoveredOutbox: Math.max(0, beforeFailedOutbox - afterFailedOutbox),
    recoveredPrintJobs: Math.max(0, beforeFailedPrints - afterFailedPrints)
  };
}
