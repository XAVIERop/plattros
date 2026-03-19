import { useCallback, useEffect, useState } from "react";
import { supabase } from "@/lib/supabase/client";
import {
  listQueuedPrintJobs,
  markPrintJobFailed,
  markPrintJobPrinted,
  listPendingOutbox,
  markOutboxFailed,
  markOutboxSynced,
  markOutboxSyncing,
  resetFailedPrintJobsToQueued,
  resetFailedToPending
} from "@/lib/offline/outbox";
import type { OutboxItem } from "@/lib/offline/db";
import { printQueuedTicket } from "@/lib/printing/printerAdapter";

interface SyncState {
  isOnline: boolean;
  isSyncing: boolean;
  pendingCount: number;
  queuedPrintCount: number;
  lastSyncAt: string | null;
  lastSyncSummary: string | null;
}

const SYNC_INTERVAL_MS = 5000;
const SYNC_MODE = import.meta.env.VITE_BHURSAS_SYNC_MODE || "demo";

async function syncOrderItem(item: OutboxItem) {
  if (SYNC_MODE === "demo") {
    // Demo mode keeps local UX and retry behavior without requiring backend endpoint setup.
    await new Promise((resolve) => setTimeout(resolve, 120));
    return;
  }

  if (SYNC_MODE === "edge_function") {
    const { error } = await supabase.functions.invoke("pos-offline-sync", {
      body: item.payload
    });

    if (error) {
      throw error;
    }
    return;
  }

  // direct_table mode: requires Supabase schema with expected columns (orders, order_items).
  const { error } = await supabase.from("orders").upsert(
    {
      id: item.payload.id,
      cafe_id: item.payload.cafeId,
      user_id: item.payload.createdByUserId,
      order_number: item.payload.ticketNo,
      table_number: item.payload.tableNumber,
      delivery_block: item.payload.deliveryBlock,
      delivery_address: item.payload.deliveryAddress,
      customer_name: item.payload.customerName,
      phone_number: item.payload.customerPhone,
      total_amount: item.payload.totalAmount,
      payment_method: item.payload.paymentMethod,
      status: "received",
      payment_status: item.payload.paymentMethod === "cash" ? "paid" : "pending",
      order_type: item.payload.orderMode
    },
    {
      onConflict: "id"
    }
  );

  if (error) {
    throw error;
  }
}

export function useOfflineSync(cafeId: string | null) {
  const [state, setState] = useState<SyncState>({
    isOnline: navigator.onLine,
    isSyncing: false,
    pendingCount: 0,
    queuedPrintCount: 0,
    lastSyncAt: null,
    lastSyncSummary: null
  });

  const refreshCounts = useCallback(async () => {
    const pending = await listPendingOutbox(200);
    const queuedPrint = await listQueuedPrintJobs(200);
    setState((prev) => ({
      ...prev,
      pendingCount: pending.length,
      queuedPrintCount: queuedPrint.length
    }));
  }, []);

  const flushOutbox = useCallback(async () => {
    if (!navigator.onLine) {
      setState((prev) => ({ ...prev, isOnline: false }));
      return;
    }

    setState((prev) => ({ ...prev, isOnline: true, isSyncing: true }));

    await resetFailedToPending();
    const pendingItems = await listPendingOutbox(50);
    let syncedCount = 0;
    let failedCount = 0;

    for (const item of pendingItems) {
      try {
        await markOutboxSyncing(item.id);
        await syncOrderItem(item);

        await markOutboxSynced(item.id);
        syncedCount += 1;
      } catch (err) {
        await markOutboxFailed(item.id, item.attempts, err);
        failedCount += 1;
      }
    }

    await refreshCounts();
    setState((prev) => ({
      ...prev,
      isSyncing: false,
      lastSyncAt: new Date().toISOString(),
      lastSyncSummary: syncedCount > 0 || failedCount > 0 ? `${syncedCount} synced, ${failedCount} failed` : prev.lastSyncSummary
    }));
  }, [refreshCounts]);

  const markNextPrintPrinted = useCallback(async () => {
    await resetFailedPrintJobsToQueued();
    const jobs = await listQueuedPrintJobs(1);
    if (jobs.length === 0) {
      return;
    }

    await markPrintJobPrinted(jobs[0].id);
    await refreshCounts();
  }, [refreshCounts]);

  const processPrintQueue = useCallback(async () => {
    if (!navigator.onLine) {
      return;
    }

    const jobs = await listQueuedPrintJobs(3);
    if (jobs.length === 0) {
      return;
    }

    for (const job of jobs) {
      try {
        await printQueuedTicket(job, cafeId);
        await markPrintJobPrinted(job.id);
      } catch (error) {
        await markPrintJobFailed(job.id, job.attempts || 0, error);
      }
    }
    await refreshCounts();
  }, [refreshCounts, cafeId]);

  useEffect(() => {
    void refreshCounts();

    const handleOnline = () => {
      setState((prev) => ({ ...prev, isOnline: true }));
      void flushOutbox();
    };

    const handleOffline = () => {
      setState((prev) => ({ ...prev, isOnline: false }));
    };

    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);

    const timer = window.setInterval(() => {
      void flushOutbox();
      void processPrintQueue();
    }, SYNC_INTERVAL_MS);

    return () => {
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
      window.clearInterval(timer);
    };
  }, [flushOutbox, processPrintQueue, refreshCounts]);

  return {
    ...state,
    flushOutbox,
    refreshPendingCount: refreshCounts,
    markNextPrintPrinted,
    processPrintQueue,
    syncMode: SYNC_MODE
  };
}
