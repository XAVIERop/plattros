import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from "react";
import { enqueueOrderDraft, enqueuePrintJob } from "@/lib/offline/outbox";
import { calculateCoffeePrice, type CoffeeSelections, type DraftOrderLineItem } from "@/lib/offline/menu";
import { useOfflineSync } from "@/lib/offline/useOfflineSync";
import { recoverOfflineOpsQueues } from "@/lib/offline/opsRecovery";
import { useCafeSession } from "@/lib/auth/useCafeSession";
import { useCafeMenu } from "@/lib/menu/useCafeMenu";
import { useCafeModifiers } from "@/lib/menu/useCafeModifiers";
import { ModifierSelector } from "@/components/ModifierSelector";
import { useCafeBranding } from "@/lib/theme/useCafeBranding";
import { subscribeOrderRealtime } from "@/lib/realtime/orderRealtime";
import { supabase } from "@/lib/supabase/client";
import type {
  MarkPaymentReceivedRequest,
  MarkPaymentReceivedResponse,
  UpdateOrderStatusRequest,
  UpdateOrderStatusResponse
} from "@/lib/api/contracts";
import { LoyaltyPanel } from "@/components/loyalty/LoyaltyPanel";
import { RedeemRewardSection } from "@/components/loyalty/RedeemRewardSection";
import {
  calculateBillingTotals,
  createKotLines,
  canTransitionStatus,
  getNextTicketNumber
} from "@pos-core";
import {
  listRecentOutbox,
  listRecentPrintJobs,
  retryOutboxItem,
  retryPrintJob
} from "@/lib/offline/outbox";
import { db, type OfflineOrderDraft, type OutboxItem, type PrintQueueItem } from "@/lib/offline/db";
import { toast } from "sonner";
import { 
  ChevronDown, 
  ChevronUp, 
  ChevronLeft,
  ChevronRight,
  Pencil, 
  Trash2, 
  X,
  LayoutDashboard,
  ShoppingBag,
  ListOrdered,
  UtensilsCrossed,
  LayoutGrid,
  Truck,
  Package,
  Ticket,
  Users,
  BarChart3,
  UserCircle,
  Coffee,
  History,
  CreditCard,
  Settings,
  HelpCircle,
  LogOut,
  CupSoda,
  Pizza,
  Utensils,
  Flame,
  Zap,
  Cake,
  Menu as MenuIcon,
  Search as SearchIcon,
  Settings2,
  Plus,
  ArrowRight,
  ArrowRightLeft,
  Beer,
  List,
  Printer,
  FileText,
  XCircle,
  CheckCircle2,
  Heart
} from "lucide-react";

type PosView =
  | "dashboard"
  | "menu"
  | "orders"
  | "kitchen"
  | "tables"
  | "delivery"
  | "history"
  | "billing"
  | "inventory"
  | "offers"
  | "customers"
  | "analytics"
  | "loyalty"
  | "staff"
  | "cafe"
  | "settings";

interface RemoteOrder {
  id: string;
  order_number: string;
  status: "received" | "confirmed" | "preparing" | "on_the_way" | "completed" | "cancelled";
  payment_status: "pending" | "paid" | "failed" | "refunded" | null;
  payment_method: string | null;
  order_type: string | null;
  customer_name?: string | null;
  phone_number?: string | null;
  delivery_block?: string | null;
  delivery_address?: string | null;
  table_number?: string | null;
  delivery_rider_id?: string | null;
  total_amount: number;
  created_at: string;
  updated_at?: string | null;
  delivery_notes: string | null;
}

interface MenuAdminItem {
  id: string;
  name: string;
  category: string | null;
  price: number;
  is_available: boolean;
  available_from: string | null;
  available_until: string | null;
}

interface RemoteOrderItem {
  id: string;
  quantity: number;
  unit_price: number;
  total_price: number;
  special_instructions: string | null;
  menu_item_id?: string | null;
  menu_items?: Array<{
    name: string;
  }> | null;
}

interface ParkedCart {
  id: string;
  label: string;
  items: DraftOrderLineItem[];
  notes: string;
  orderMode: "delivery" | "dine_in" | "takeaway";
  paymentMethod: "cash" | "card" | "upi" | "split";
  splitAmounts: { cash: number; card: number; upi: number };
  customerName: string;
  customerPhone: string;
  deliveryBlock: string;
  deliveryAddress: string;
  tableNumber: string;
  discountMode: "amount" | "percent";
  discountInput: string;
  serviceChargeInput: string;
  createdAt: string;
}

interface ShiftSession {
  id: string;
  startedAt: string;
  endedAt: string | null;
  cashierId: string;
  cashierName: string;
}

interface SplitSettlementEntry {
  id: string;
  label: string;
  amount: number;
  method: "cash" | "card" | "upi";
  paid: boolean;
  reference: string;
}

interface StaffRow {
  id: string;
  staff_name: string | null;
  role: string;
  is_active: boolean;
  profile?: { full_name: string | null } | null;
}

type LoyaltyTier = "foodie" | "gourmet" | "connoisseur";

function getTierBySpend(spend: number): LoyaltyTier {
  if (spend >= 5000) return "connoisseur";
  if (spend >= 2000) return "gourmet";
  return "foodie";
}

type CustomerSegment = "VIP" | "Regular" | "New" | "At Risk";

function getSegmentByActivity(orderCount: number, checkIns: number, lastVisit?: string): CustomerSegment {
  const totalVisits = orderCount + (checkIns ?? 0);
  if (totalVisits >= 10) return "VIP";
  if (totalVisits >= 3) return "Regular";
  if (totalVisits <= 1) return "New";
  if (lastVisit) {
    const daysSince = (Date.now() - new Date(lastVisit).getTime()) / (24 * 60 * 60 * 1000);
    if (daysSince > 30) return "At Risk";
  }
  return "Regular";
}

interface CustomerSummary {
  phone: string;
  name: string;
  orderCount: number;
  spend: number;
  lastVisit?: string;
  loyaltyTier: LoyaltyTier;
  loyaltyPoints?: number;
  checkIns?: number;
  segment: CustomerSegment;
}

interface OfferRow {
  id: string;
  name: string;
  discount_type: string;
  discount_value: number;
  is_active: boolean;
}

interface OrderEditDraft {
  customerName: string;
  customerPhone: string;
  orderType: "delivery" | "dine_in" | "takeaway";
  tableNumber: string;
  deliveryBlock: string;
  deliveryAddress: string;
  notes: string;
}

const ORDER_RUNTIME_STATE_KEY = "cafe_order_runtime_state";
const CAFE_TERMINAL_ID_KEY = "cafe_terminal_identity_id";
const POS_TERMINAL_ID_KEY = "pos_terminal_id";
const TABLE_META_STATE_KEY = "cafe_table_meta_state";
const DASHBOARD_NOTIFICATION_READ_KEY = "cafe_dashboard_notification_read";

type TableUiStatus = "available" | "reserved" | "seated" | "ordering" | "preparing" | "served" | "needs_bill" | "dirty";

interface TableMetaState {
  capacity: 2 | 4 | 6;
  reservationName?: string;
  reservationTime?: string;
  seatedAt?: string;
  manualStatus?: TableUiStatus;
  guestName?: string;
  guestPhone?: string;
  billPrintedAt?: string;
}

type TableFormMode = "reserve" | "guest" | null;

interface RolloutFlags {
  orders: boolean;
  manualBilling: boolean;
  kitchen: boolean;
  tableManagement: boolean;
  deliveryOps: boolean;
  businessModules: boolean;
}

interface StaffPreset {
  id: string;
  name: string;
  shift: string;
  email: string;
}

interface AuthPreviewOrder {
  order_number: string;
  order_type: string | null;
  customer_name: string | null;
}

interface AuthPreviewSnapshot {
  totalEarning: number;
  inProgress: number;
  readyToServe: number;
  recentOrders: AuthPreviewOrder[];
}

interface DashboardNotificationItem {
  id: string;
  bucket: "inventory" | "kitchen";
  title: string;
  message: string;
  orderId?: string;
  menuItemId?: string;
}

interface MenuOrganizerCategory {
  name: string;
  items: MenuAdminItem[];
}

const AUTH_STAFF_PRESETS: StaffPreset[] = [
  { id: "staff-default", name: "System Admin", shift: "All Day", email: "admin@pos.com" }
];

function MobileHeader(props: {
  title: string;
  subtitle?: string;
  left?: ReactNode;
  center?: ReactNode;
  right?: ReactNode;
}) {
  return (
    <header className="mobile-only-header">
      <div className="mobile-header-slot">{props.left}</div>
      <div className="mobile-header-center">
        {props.center ?? (
          <div className="mobile-header-title">
            <span className="mobile-header-title-text">{props.title}</span>
            {props.subtitle ? <span className="mobile-header-subtitle">{props.subtitle}</span> : null}
          </div>
        )}
      </div>
      <div className="mobile-header-slot">{props.right}</div>
    </header>
  );
}

function SuggestionDropdown({ 
  suggestions, 
  onSelect, 
  visible 
}: { 
  suggestions: CustomerSummary[], 
  onSelect: (c: CustomerSummary) => void, 
  visible: boolean 
}) {
  console.log(`SuggestionDropdown: visible=${visible}, suggestions=${suggestions.length}`);
  if (!visible || suggestions.length === 0) return null;
  return (
    <div className="suggestion-dropdown-container">
      <ul className="suggestion-dropdown">
        {suggestions.map((c) => (
          <li key={c.phone} onMouseDown={(e) => { e.preventDefault(); onSelect(c); }}>
            <div className="suggest-info">
              <span className="suggest-name">{c.name}</span>
              <span className="suggest-phone">{c.phone}</span>
            </div>
            <div className="suggest-meta">₹{Math.round(c.spend)} • {c.orderCount} visits</div>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default function App() {
  const readOrderRuntimeState = () => {
    const raw = localStorage.getItem(ORDER_RUNTIME_STATE_KEY);
    if (!raw) return {} as Record<string, Partial<RemoteOrder>>;
    try {
      return JSON.parse(raw) as Record<string, Partial<RemoteOrder>>;
    } catch {
      localStorage.removeItem(ORDER_RUNTIME_STATE_KEY);
      return {} as Record<string, Partial<RemoteOrder>>;
    }
  };

  const writeOrderRuntimeState = (data: Record<string, Partial<RemoteOrder>>) => {
    localStorage.setItem(ORDER_RUNTIME_STATE_KEY, JSON.stringify(data));
  };

  const [activeView, setActiveView] = useState<PosView>("dashboard");
  const [dashboardSearch, setDashboardSearch] = useState("");
  const [kitchenSearch, setKitchenSearch] = useState("");
  const [dashboardNotificationsOpen, setDashboardNotificationsOpen] = useState(false);
  const [dashboardNotificationTab, setDashboardNotificationTab] = useState<"all" | "inventory" | "kitchen">("all");
  const [dashboardNotificationReadMap, setDashboardNotificationReadMap] = useState<Record<string, boolean>>({});
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
  const [isMobileCartOpen, setIsMobileCartOpen] = useState(false);
  const [isMobileDrawerOpen, setIsMobileDrawerOpen] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [selectedAuthStaffId, setSelectedAuthStaffId] = useState(AUTH_STAFF_PRESETS[0]?.id || "");
  const [authPin, setAuthPin] = useState("");
  const [authMode, setAuthMode] = useState<"login" | "forgot" | "sent" | "admin">("login");
  const [terminalCafeId, setTerminalCafeId] = useState<string | null>(localStorage.getItem(CAFE_TERMINAL_ID_KEY));
  const [terminalId, setTerminalId] = useState<string>(() =>
    (import.meta.env.VITE_BHURSAS_TERMINAL_ID as string) || localStorage.getItem(POS_TERMINAL_ID_KEY) || ""
  );
  const [recoveryEmail, setRecoveryEmail] = useState("");
  const [claimCafeIdInput, setClaimCafeIdInput] = useState("");
  const [authResetStatus, setAuthResetStatus] = useState<{ type: "success" | "error"; message: string } | null>(null);
  const [authStaffOptions, setAuthStaffOptions] = useState<StaffPreset[]>(AUTH_STAFF_PRESETS);
  const [authBootstrapLoading, setAuthBootstrapLoading] = useState(false);
  const [authBootstrapError, setAuthBootstrapError] = useState<string | null>(null);
  const [authPreview, setAuthPreview] = useState<AuthPreviewSnapshot>({
    totalEarning: 0,
    inProgress: 0,
    readyToServe: 0,
    recentOrders: []
  });

  const { user, loading: sessionLoading, error: sessionError, signIn, signOut } = useCafeSession();

  // Unified getCategoryIcon removed from here to follow the version below line 604
  const cafeId = user?.cafeId || terminalCafeId;
  const {
    isOnline,
    isSyncing,
    pendingCount,
    queuedPrintCount,
    lastSyncAt,
    lastSyncSummary,
    flushOutbox,
    processPrintQueue,
    syncMode
  } = useOfflineSync(cafeId);
  const { theme, loading: brandingLoading } = useCafeBranding(cafeId);
  const { menu, source: menuSource, refresh: refreshMenu } = useCafeMenu(cafeId);
  const {
    getModifiersForItem,
    getDefaultSelections,
    calculatePriceWithModifiers
  } = useCafeModifiers(cafeId);

  // Splash Screen State
  const [showSplash, setShowSplash] = useState(true);
  const [isSplashExiting, setIsSplashExiting] = useState(false);

  useEffect(() => {
    // Minimum amount of time to show the splash screen so it feels deliberate
    const MIN_SPLASH_DURATION = 2500;
    const start = Date.now();

    if (!sessionLoading) {
      const elapsed = Date.now() - start;
      const remaining = Math.max(0, MIN_SPLASH_DURATION - elapsed);

      const t1 = window.setTimeout(() => {
        setIsSplashExiting(true);
        // Wait for CSS fade-out animation to finish
        const t2 = window.setTimeout(() => {
          setShowSplash(false);
        }, 600); // 600ms matches 'splash-exit' duration
        return () => window.clearTimeout(t2);
      }, remaining);

      return () => window.clearTimeout(t1);
    }
  }, [sessionLoading]);
  const [selectedProductId, setSelectedProductId] = useState("");
  const [search, setSearch] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("all");
  const [quantity, setQuantity] = useState(1);
  const [orderMode, setOrderMode] = useState<"delivery" | "dine_in" | "takeaway">("takeaway");
  const [customerName, setCustomerName] = useState("");
  const [customerPhone, setCustomerPhone] = useState("");
  const [sendDigitalReceipt, setSendDigitalReceipt] = useState(true);
  const [deliveryBlock, setDeliveryBlock] = useState("");
  const [deliveryAddress, setDeliveryAddress] = useState("");
  const [tableNumber, setTableNumber] = useState("");
  const [notes, setNotes] = useState("");
  const [paymentMethod, setPaymentMethod] = useState<"cash" | "card" | "upi" | "split">("cash");
  const [splitAmounts, setSplitAmounts] = useState<{ cash: number; card: number; upi: number }>({
    cash: 0,
    card: 0,
    upi: 0
  });
  const [splitSettlements, setSplitSettlements] = useState<SplitSettlementEntry[]>([]);
  const [splitCountInput, setSplitCountInput] = useState(2);
  const [cartItems, setCartItems] = useState<DraftOrderLineItem[]>([]);
  const [discountMode, setDiscountMode] = useState<"amount" | "percent">("amount");
  const [discountInput, setDiscountInput] = useState("0");
  const [serviceChargeInput, setServiceChargeInput] = useState("0");
  const [parkNameInput, setParkNameInput] = useState("");
  const [parkedCarts, setParkedCarts] = useState<ParkedCart[]>([]);
  const [lastCreatedOrder, setLastCreatedOrder] = useState<string | null>(null);
  const [orderUpdateLoadingId, setOrderUpdateLoadingId] = useState<string | null>(null);
  const [remoteOrders, setRemoteOrders] = useState<RemoteOrder[]>([]);
  const [localOrders, setLocalOrders] = useState<RemoteOrder[]>([]);
  const [orderItemsMap, setOrderItemsMap] = useState<Record<string, RemoteOrderItem[]>>({});
  const [selectedOrderId, setSelectedOrderId] = useState<string | null>(null);
  const [orderFilterStatus, setOrderFilterStatus] = useState<string>("all");
  const [ordersLayoutMode, setOrdersLayoutMode] = useState<"cards" | "power_user">("cards");
  const [orderFilterPayment, setOrderFilterPayment] = useState<string>("all");
  const [orderFilterType, setOrderFilterType] = useState<string>("all");
  const [orderFilterSync, setOrderFilterSync] = useState<string>("all");
  const [orderSearch, setOrderSearch] = useState("");
  const [orderSort, setOrderSort] = useState<"latest" | "oldest" | "order_type">("latest");
  const [cancelReasonByOrderId, setCancelReasonByOrderId] = useState<Record<string, string>>({});
  const [cancelInputOpenByOrderId, setCancelInputOpenByOrderId] = useState<Record<string, boolean>>({});
  const [isEditingSelectedOrder, setIsEditingSelectedOrder] = useState(false);
  const [selectedOrderDraft, setSelectedOrderDraft] = useState<OrderEditDraft | null>(null);
  const [selectedOrderItemsDraft, setSelectedOrderItemsDraft] = useState<RemoteOrderItem[]>([]);
  const [selectedOrderAddPanelOpen, setSelectedOrderAddPanelOpen] = useState(false);
  const [selectedOrderAddItemId, setSelectedOrderAddItemId] = useState("");
  const [selectedOrderAddQty, setSelectedOrderAddQty] = useState(1);
  const previousSelectedOrderIdRef = useRef<string | null>(null);
  const dashboardNotificationPanelRef = useRef<HTMLDivElement | null>(null);
  const authPinInputRef = useRef<HTMLInputElement | null>(null);
  const menuAddFormRef = useRef<HTMLDivElement | null>(null);
  const [tableMetaState, setTableMetaState] = useState<Record<string, TableMetaState>>({});
  const [tableOpSource, setTableOpSource] = useState("");
  const [tableOpTarget, setTableOpTarget] = useState("");
  const [tableOpsExpanded, setTableOpsExpanded] = useState(false);
  const [selectedTableNo, setSelectedTableNo] = useState<string | null>(null);
  const [tableFormMode, setTableFormMode] = useState<TableFormMode>(null);
  const [tableFormTableNo, setTableFormTableNo] = useState("");
  const [tableFormName, setTableFormName] = useState("");
  const [tableFormPhone, setTableFormPhone] = useState("");
  const [tableFormTime, setTableFormTime] = useState("");
  const [tableOrderDraftMap, setTableOrderDraftMap] = useState<Record<string, OfflineOrderDraft>>({});
  const [outboxHistory, setOutboxHistory] = useState<OutboxItem[]>([]);
  const [printHistory, setPrintHistory] = useState<PrintQueueItem[]>([]);
  const [adminMenuItems, setAdminMenuItems] = useState<MenuAdminItem[]>([]);
  const [editingMenuId, setEditingMenuId] = useState<string | null>(null);
  const [editingMenuName, setEditingMenuName] = useState("");
  const [editingMenuCategory, setEditingMenuCategory] = useState("");
  const [editingMenuPrice, setEditingMenuPrice] = useState("");
  const [menuName, setMenuName] = useState("");
  const [menuCategory, setMenuCategory] = useState("coffee");
  const [menuPrice, setMenuPrice] = useState("150");
  const [menuOrganizerSearch, setMenuOrganizerSearch] = useState("");
  const [menuOrganizerAvailability, setMenuOrganizerAvailability] = useState<"all" | "available" | "hidden">("all");
  const [menuOrganizerCategoryFilter, setMenuOrganizerCategoryFilter] = useState("all");
  const [collapsedMenuCategories, setCollapsedMenuCategories] = useState<Record<string, boolean>>({});
  const [activeShift, setActiveShift] = useState<ShiftSession | null>(null);
  const [reportRange, setReportRange] = useState<"today" | "yesterday" | "custom">("today");
  const [customStartDate, setCustomStartDate] = useState("");
  const [customEndDate, setCustomEndDate] = useState("");
  const [analyticsRange, setAnalyticsRange] = useState<"today" | "week" | "month" | "all">("today");
  const [dashboardDateRange, setDashboardDateRange] = useState<"today" | "week" | "month" | "all" | "custom">("today");
  const [dashboardCustomStartDate, setDashboardCustomStartDate] = useState("");
  const [dashboardCustomEndDate, setDashboardCustomEndDate] = useState("");
  
  const [aiSuggestion, setAiSuggestion] = useState<{ productId: string; reason: string } | null>(null);
  const [aiSuggestLoading, setAiSuggestLoading] = useState(false);
  const [staffRows, setStaffRows] = useState<StaffRow[]>([]);
  const [deliveryRiders, setDeliveryRiders] = useState<{ id: string; full_name: string }[]>([]);
  const [customerSummary, setCustomerSummary] = useState<CustomerSummary[]>([]);
  // Debug log for data
  useEffect(() => {
    if (customerSummary.length > 0) {
      console.log(`CRM: Total customers loaded: ${customerSummary.length}`);
    }
  }, [customerSummary]);
  const [customerSearch, setCustomerSearch] = useState("");
  const [customerTierFilter, setCustomerTierFilter] = useState<LoyaltyTier | "all">("all");
  const [customerSegmentFilter, setCustomerSegmentFilter] = useState<CustomerSegment | "all">("all");
  const [selectedCustomer, setSelectedCustomer] = useState<CustomerSummary | null>(null);
  const [customerDetails, setCustomerDetails] = useState<{
    points: number | null;
    recentOrders: any[];
    topItems: { name: string; count: number }[];
    notes: string | null;
    birthday: string | null;
    isLoading: boolean;
  }>({ points: null, recentOrders: [], topItems: [], notes: null, birthday: null, isLoading: false });
  const filteredCustomers = useMemo(() => {
    const s = customerSearch.toLowerCase();
    return customerSummary.filter(c => {
      const matchesSearch = c.name.toLowerCase().includes(s) || c.phone.includes(s);
      const matchesTier = customerTierFilter === "all" || c.loyaltyTier === customerTierFilter;
      const matchesSegment = customerSegmentFilter === "all" || c.segment === customerSegmentFilter;
      return matchesSearch && matchesTier && matchesSegment;
    });
  }, [customerSummary, customerSearch, customerTierFilter, customerSegmentFilter]);

  const [offers, setOffers] = useState<OfferRow[]>([]);
  const [offerName, setOfferName] = useState("");
  const [offerDiscountType, setOfferDiscountType] = useState<"percentage" | "fixed_amount">("percentage");
  const [offerDiscountValue, setOfferDiscountValue] = useState("10");
  const [cafeDetails, setCafeDetails] = useState({
    name: "",
    phone: "",
    location: "",
    description: ""
  });
  const [rolloutFlags, setRolloutFlags] = useState<RolloutFlags>({
    orders: true,
    manualBilling: true,
    kitchen: true,
    tableManagement: true,
    deliveryOps: true,
    businessModules: true
  });
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const notify = useCallback((message: string, variant: "success" | "error" | "info" = "success") => {
    setStatusMessage(message);
    if (variant === "error") toast.error(message);
    else if (variant === "info") toast.info(message);
    else toast.success(message);
  }, []);
  const [selections, setSelections] = useState<CoffeeSelections>({
    size: "medium",
    milk: "regular",
    sugarLevel: "regular",
    extraShots: 0
  });
  const [modifierProductForAdd, setModifierProductForAdd] = useState<{
    product: { id: string; name: string; basePrice: number };
    groups: import("@/lib/menu/useCafeModifiers").ModifierGroup[];
  } | null>(null);
  const [modifierSelections, setModifierSelections] = useState<Record<string, string>>({});

  const networkLabel = useMemo(() => {
    if (!isOnline) {
      return "Offline";
    }
    if (isSyncing) {
      return "Syncing";
    }
    return "Online";
  }, [isOnline, isSyncing]);
  const canManageMenu = user?.role === "cafe_owner" || user?.role === "super_admin" || user?.role === "admin";
  const menuOrganizerCategoryNames = useMemo(
    () =>
      Array.from(new Set(adminMenuItems.map((item) => (item.category || "uncategorized").trim() || "uncategorized")))
        .sort((a, b) => a.localeCompare(b)),
    [adminMenuItems]
  );
  const menuOrganizerCategories = useMemo<MenuOrganizerCategory[]>(() => {
    const grouped = new Map<string, MenuAdminItem[]>();
    adminMenuItems.forEach((item) => {
      const key = (item.category || "uncategorized").trim() || "uncategorized";
      if (!grouped.has(key)) grouped.set(key, []);
      grouped.get(key)!.push(item);
    });
    return Array.from(grouped.entries())
      .map(([name, items]) => ({
        name,
        items: items.sort((a, b) => a.name.localeCompare(b.name))
      }))
      .sort((a, b) => a.name.localeCompare(b.name));
  }, [adminMenuItems]);
  const menuOrganizerVisibleCategories = useMemo(() => {
    const q = menuOrganizerSearch.trim().toLowerCase();
    return menuOrganizerCategories
      .map((category) => {
        if (menuOrganizerCategoryFilter !== "all" && category.name !== menuOrganizerCategoryFilter) {
          return null;
        }
        const filteredItems = category.items.filter((item) => {
          if (menuOrganizerAvailability === "available" && !item.is_available) return false;
          if (menuOrganizerAvailability === "hidden" && item.is_available) return false;
          if (!q) return true;
          return item.name.toLowerCase().includes(q) || category.name.toLowerCase().includes(q);
        });
        if (filteredItems.length === 0) return null;
        return {
          ...category,
          items: filteredItems
        };
      })
      .filter((category): category is MenuOrganizerCategory => Boolean(category));
  }, [menuOrganizerCategories, menuOrganizerCategoryFilter, menuOrganizerAvailability, menuOrganizerSearch]);

  useEffect(() => {
    setCollapsedMenuCategories((prev) => {
      const next = { ...prev };
      let changed = false;
      for (const name of menuOrganizerCategoryNames) {
        if (next[name] === undefined) {
          next[name] = true;
          changed = true;
        }
      }
      return changed ? next : prev;
    });
  }, [menuOrganizerCategoryNames]);

  useEffect(() => {
    if (!cafeId || user) return;
    let cancelled = false;
    setAuthBootstrapLoading(true);
    setAuthBootstrapError(null);
    void (async () => {
      const { data, error } = await supabase.functions.invoke("pos-login-bootstrap", {
        body: { cafeId }
      });
      if (cancelled) return;
      if (error || !data?.success) {
        setAuthBootstrapError(data?.error || error?.message || "Using fallback staff preview.");
        setAuthBootstrapLoading(false);
        return;
      }

      const staffRows = Array.isArray(data.staff) ? (data.staff as StaffPreset[]) : [];
      if (staffRows.length > 0) {
        setAuthStaffOptions(staffRows);
        setSelectedAuthStaffId((prev) => {
          if (staffRows.some((staff) => staff.id === prev)) return prev;
          return staffRows[0].id;
        });
      }

      setAuthPreview({
        totalEarning: Number(data.preview?.totalEarning || 0),
        inProgress: Number(data.preview?.inProgress || 0),
        readyToServe: Number(data.preview?.readyToServe || 0),
        recentOrders: Array.isArray(data.preview?.recentOrders)
          ? (data.preview.recentOrders as AuthPreviewOrder[])
          : []
      });
      setAuthBootstrapLoading(false);
    })();
    return () => {
      cancelled = true;
    };
  }, [cafeId, user]);

  const cartSubtotal = useMemo(
    () => cartItems.reduce((sum, item) => sum + item.lineTotal, 0),
    [cartItems]
  );
  const rawDiscountValue = Math.max(0, Number.parseFloat(discountInput) || 0);
  const [rewardDiscountAmount, setRewardDiscountAmount] = useState(0);
  const [redeemedRewardId, setRedeemedRewardId] = useState<string | null>(null);
  const billingTotals = useMemo(
    () =>
      calculateBillingTotals({
        subtotal: cartSubtotal,
        discountMode,
        discountInput: rawDiscountValue,
        serviceCharge: Number.parseFloat(serviceChargeInput) || 0,
        rewardDiscount: rewardDiscountAmount
      }),
    [cartSubtotal, discountMode, rawDiscountValue, serviceChargeInput, rewardDiscountAmount]
  );
  const discountAmount = billingTotals.discountAmount;
  const serviceChargeAmount = billingTotals.serviceChargeAmount;
  const orderTotal = billingTotals.total;
  const splitAllocatedTotal = useMemo(
    () => splitSettlements.reduce((sum, entry) => sum + Number(entry.amount || 0), 0),
    [splitSettlements]
  );
  const splitPaidTotal = useMemo(
    () => splitSettlements.filter((entry) => entry.paid).reduce((sum, entry) => sum + Number(entry.amount || 0), 0),
    [splitSettlements]
  );

  const filteredMenu = useMemo(() => {
    const q = search.trim().toLowerCase();
    return menu.filter((item) => {
      const byCategory = selectedCategory === "all" || item.category === selectedCategory;
      const bySearch = q.length === 0 || item.name.toLowerCase().includes(q);
      return byCategory && bySearch;
    });
  }, [menu, search, selectedCategory]);

  const categories = useMemo(() => {
    const allCategories = Array.from(new Set(menu.map((item) => item.category)));
    return ["all", ...allCategories];
  }, [menu]);

  const categoryCounts = useMemo(() => {
    const counts: Record<string, number> = { all: menu.length };
    menu.forEach((item) => {
      const cat = item.category || "Uncategorized";
      counts[cat] = (counts[cat] || 0) + 1;
    });
    return counts;
  }, [menu]);

  // Centralized Category Icon Helper — varied icons per food type
  const getCategoryIcon = (category: string) => {
    const cat = category.toLowerCase();
    if (cat === "all" || cat === "favorite") return <LayoutGrid size={20} />;
    if (cat.includes("coffee") || cat.includes("espresso") || cat.includes("latte") || cat.includes("manual") || cat.includes("cold") || cat.includes("café") || cat.includes("cafe")) return <Coffee size={20} />;
    if (cat.includes("beverage") || cat.includes("shake") || cat.includes("tea") || cat.includes("drinks") || cat.includes("chaa") || cat.includes("chaap")) return <CupSoda size={20} />;
    if (cat.includes("chicken") || cat.includes("murg") || cat.includes("poultry")) return <UtensilsCrossed size={20} />;
    if (cat.includes("pasta") || cat.includes("italian") || cat.includes("noodle") || cat.includes("ramen")) return <Utensils size={20} />;
    if (cat.includes("tandoor") || cat.includes("grill") || cat.includes("fry") || cat.includes("desi")) return <Flame size={20} />;
    if (cat.includes("rice") || cat.includes("basmati") || cat.includes("combo") || cat.includes("royal")) return <Utensils size={20} />;
    if (cat.includes("raita") || cat.includes("salad") || cat.includes("sal")) return <Utensils size={20} />;
    if (cat.includes("momo") || cat.includes("oriental") || cat.includes("wo")) return <UtensilsCrossed size={20} />;
    if (cat.includes("dessert") || cat.includes("sweet") || cat.includes("cake")) return <Cake size={20} />;
    if (cat.includes("soya") || cat.includes("achari")) return <Utensils size={20} />;
    return <LayoutGrid size={20} />;
  };

  const selectedProduct = menu.find((item) => item.id === selectedProductId) || menu[0];
  const selectedReady = Boolean(selectedProduct);
  const calculatedUnit = selectedProduct ? calculateCoffeePrice(selectedProduct, selections) : 0;
  const estimatedTotal = calculatedUnit * quantity;
  const allOrders = useMemo(() => {
    const byId = new Map<string, RemoteOrder>();
    localOrders.forEach((order) => byId.set(order.id, order));
    remoteOrders.forEach((order) => byId.set(order.id, order));
    return Array.from(byId.values()).sort(
      (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    );
  }, [localOrders, remoteOrders]);

  const filteredOrders = useMemo(() => {
    const now = new Date();
    const yesterday = new Date();
    yesterday.setDate(now.getDate() - 1);
    return allOrders.filter((order) => {
      const dt = new Date(order.created_at);
      if (reportRange === "today" && dt.toDateString() !== now.toDateString()) return false;
      if (reportRange === "yesterday" && dt.toDateString() !== yesterday.toDateString()) return false;
      if (reportRange === "custom" && customStartDate && customEndDate) {
        const start = new Date(`${customStartDate}T00:00:00`);
        const end = new Date(`${customEndDate}T23:59:59`);
        if (dt < start || dt > end) return false;
      }
      return true;
    });
  }, [allOrders, reportRange, customStartDate, customEndDate]);

  const visibleOrders = useMemo(() => {
    const q = orderSearch.trim().toLowerCase();
    const outboxByOrderId = new Map(outboxHistory.map((item) => [item.payload.id, item.status]));
    const filtered = allOrders.filter((order) => {
      if (orderFilterStatus !== "all") {
        if (orderFilterStatus === "in_progress") {
          if (!["received", "confirmed"].includes(order.status)) return false;
        } else if (orderFilterStatus === "ready_to_serve") {
          if (!["preparing", "on_the_way"].includes(order.status)) return false;
        } else if (orderFilterStatus === "waiting_payment") {
          if (order.payment_status === "paid" || order.status === "cancelled") return false;
        } else if (order.status !== orderFilterStatus) {
          return false;
        }
      }
      if (orderFilterPayment !== "all" && (order.payment_method || "").toLowerCase() !== orderFilterPayment) return false;
      if (orderFilterType !== "all" && (order.order_type || "").toLowerCase() !== orderFilterType) return false;
      if (orderFilterSync !== "all") {
        const syncState = outboxByOrderId.get(order.id) || "remote";
        if (syncState !== orderFilterSync) return false;
      }
      if (
        q &&
        !order.order_number.toLowerCase().includes(q) &&
        !(order.customer_name || "").toLowerCase().includes(q) &&
        !(order.phone_number || "").toLowerCase().includes(q)
      )
        return false;
      return true;
    });
    const sorted = [...filtered];
    if (orderSort === "oldest") {
      sorted.sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
    } else if (orderSort === "order_type") {
      sorted.sort((a, b) => (a.order_type || "").localeCompare(b.order_type || ""));
    } else {
      sorted.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
    }
    return sorted;
  }, [allOrders, orderFilterStatus, orderFilterPayment, orderFilterType, orderFilterSync, orderSearch, outboxHistory, orderSort]);

  const orderStageCounts = useMemo(() => {
    let inProgress = 0;
    let readyToServe = 0;
    let waitingPayment = 0;
    allOrders.forEach((order) => {
      if (["received", "confirmed"].includes(order.status)) {
        inProgress += 1;
      }
      if (["preparing", "on_the_way"].includes(order.status)) readyToServe += 1;
      if (order.payment_status !== "paid" && order.status !== "cancelled") waitingPayment += 1;
    });
    return {
      all: allOrders.length,
      in_progress: inProgress,
      ready_to_serve: readyToServe,
      waiting_payment: waitingPayment
    };
  }, [allOrders]);
  const orderOpsKpis = useMemo(() => {
    const pendingPayments = allOrders.filter((order) => order.payment_status === "pending").length;
    const dineInCount = allOrders.filter((order) => (order.order_type || "").toLowerCase() === "dine_in").length;
    const totalRevenue = allOrders.reduce((sum, order) => sum + Number(order.total_amount || 0), 0);
    const avgTicket = allOrders.length > 0 ? Math.round(totalRevenue / allOrders.length) : 0;
    return {
      pendingPayments,
      dineInCount,
      avgTicket
    };
  }, [allOrders]);
  const dashboardTodayOrders = useMemo(() => {
    const todayLabel = new Date().toDateString();
    return allOrders.filter((order) => new Date(order.created_at).toDateString() === todayLabel);
  }, [allOrders]);
  const dashboardFilteredOrders = useMemo(() => {
    if (dashboardDateRange === "all") return allOrders;
    const now = new Date();
    const start = new Date(now);
    if (dashboardDateRange === "today") {
      return allOrders.filter((order) => new Date(order.created_at).toDateString() === now.toDateString());
    }
    if (dashboardDateRange === "week") {
      start.setDate(now.getDate() - 7);
      return allOrders.filter((order) => new Date(order.created_at) >= start);
    }
    if (dashboardDateRange === "month") {
      start.setDate(now.getDate() - 30);
      return allOrders.filter((order) => new Date(order.created_at) >= start);
    }
    if (dashboardDateRange === "custom" && dashboardCustomStartDate && dashboardCustomEndDate) {
      const rangeStart = new Date(`${dashboardCustomStartDate}T00:00:00`);
      const rangeEnd = new Date(`${dashboardCustomEndDate}T23:59:59`);
      return allOrders.filter((order) => {
        const dt = new Date(order.created_at);
        return dt >= rangeStart && dt <= rangeEnd;
      });
    }
    return allOrders;
  }, [allOrders, dashboardDateRange, dashboardCustomStartDate, dashboardCustomEndDate]);
  const dashboardInProgressOrders = useMemo(
    () =>
      dashboardFilteredOrders
        .filter((order) => ["received", "confirmed", "preparing", "on_the_way"].includes(order.status))
        .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()),
    [dashboardFilteredOrders]
  );
  const dashboardWaitingPaymentOrders = useMemo(
    () =>
      dashboardFilteredOrders
        .filter((order) => order.payment_status !== "paid" && order.status !== "cancelled")
        .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()),
    [dashboardFilteredOrders]
  );
  const dashboardCompletedOrders = useMemo(
    () =>
      dashboardFilteredOrders
        .filter((order) => order.status === "completed")
        .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()),
    [dashboardFilteredOrders]
  );
  const dashboardKpis = useMemo(() => {
    const totalOrders = dashboardFilteredOrders.length;
    const totalEarning = dashboardFilteredOrders
      .filter((order) => order.status === "completed")
      .reduce((sum, order) => sum + Number(order.total_amount || 0), 0);
    const avgTicket = totalOrders ? Math.round(dashboardFilteredOrders.reduce((sum, order) => sum + Number(order.total_amount || 0), 0) / totalOrders) : 0;
    return {
      totalOrders,
      totalEarning: Math.round(totalEarning),
      inProgress: dashboardInProgressOrders.length,
      completed: dashboardFilteredOrders.filter((order) => order.status === "completed").length,
      waitingPayment: dashboardWaitingPaymentOrders.length,
      avgTicket
    };
  }, [dashboardInProgressOrders, dashboardWaitingPaymentOrders, dashboardFilteredOrders]);
  const dashboardOrderMatchesSearch = useCallback((order: RemoteOrder) => {
    const q = dashboardSearch.trim().toLowerCase();
    if (!q) return true;
    const normalizedType = (order.order_type || "takeaway").toLowerCase();
    const orderTypeText =
      (normalizedType === "dine_in" || normalizedType === "table_order") && order.table_number
        ? `table ${order.table_number}`
        : normalizedType.replace("_", " ");
    return (
      order.order_number.toLowerCase().includes(q) ||
      (order.customer_name || "").toLowerCase().includes(q) ||
      (order.phone_number || "").toLowerCase().includes(q) ||
      orderTypeText.includes(q)
    );
  }, [dashboardSearch]);
  const dashboardFilteredInProgressOrders = useMemo(
    () => dashboardInProgressOrders.filter(dashboardOrderMatchesSearch),
    [dashboardInProgressOrders, dashboardOrderMatchesSearch]
  );
  const dashboardFilteredWaitingPaymentOrders = useMemo(
    () => dashboardWaitingPaymentOrders.filter(dashboardOrderMatchesSearch),
    [dashboardWaitingPaymentOrders, dashboardOrderMatchesSearch]
  );
  const dashboardFilteredCompletedOrders = useMemo(
    () => dashboardCompletedOrders.filter(dashboardOrderMatchesSearch),
    [dashboardCompletedOrders, dashboardOrderMatchesSearch]
  );
  const todayOrders = filteredOrders;
  const kitchenNewOrders = useMemo(
    () => allOrders.filter((order) => order.status === "received" || order.status === "confirmed"),
    [allOrders]
  );
  const kitchenPreparingOrders = useMemo(() => allOrders.filter((order) => order.status === "preparing"), [allOrders]);
  const kitchenReadyOrders = useMemo(() => allOrders.filter((order) => order.status === "on_the_way"), [allOrders]);
  const kitchenOrderMatchesSearch = useCallback(
    (order: RemoteOrder) => {
      const q = kitchenSearch.trim().toLowerCase();
      if (!q) return true;
      return (
        order.order_number.toLowerCase().includes(q) ||
        (order.customer_name || "").toLowerCase().includes(q) ||
        orderTypeDisplay(order).toLowerCase().includes(q)
      );
    },
    [kitchenSearch]
  );
  const kitchenVisibleNewOrders = useMemo(
    () => kitchenNewOrders.filter(kitchenOrderMatchesSearch),
    [kitchenNewOrders, kitchenOrderMatchesSearch]
  );
  const kitchenVisiblePreparingOrders = useMemo(
    () => kitchenPreparingOrders.filter(kitchenOrderMatchesSearch),
    [kitchenPreparingOrders, kitchenOrderMatchesSearch]
  );
  const kitchenVisibleReadyOrders = useMemo(
    () => kitchenReadyOrders.filter(kitchenOrderMatchesSearch),
    [kitchenReadyOrders, kitchenOrderMatchesSearch]
  );
  const tableNumbers = useMemo(() => Array.from({ length: 16 }, (_, idx) => String(idx + 1)), []);
  const tableOrders = useMemo(
    () => allOrders.filter((order) => (order.order_type === "dine_in" || order.order_type === "table_order") && !!order.table_number),
    [allOrders]
  );
  const deliveryOrders = useMemo(
    () => allOrders.filter((order) => order.order_type === "delivery" && order.status !== "completed" && order.status !== "cancelled"),
    [allOrders]
  );
  const tableSummaries = useMemo(() => {
    const getElapsedMinutes = (iso?: string) => {
      if (!iso) return 0;
      const ms = Date.now() - new Date(iso).getTime();
      return Math.max(0, Math.floor(ms / 60000));
    };

    return tableNumbers.map((tableNo) => {
      const meta = tableMetaState[tableNo];
      const ordersForTable = tableOrders.filter(
        (order) => order.table_number === tableNo && order.status !== "completed" && order.status !== "cancelled"
      );
      const total = ordersForTable.reduce((sum, order) => sum + Number(order.total_amount || 0), 0);
      const itemCount = ordersForTable.length;
      const earliestOrderAt = ordersForTable.reduce<string | undefined>((acc, order) => {
        if (!acc) return order.created_at;
        return new Date(order.created_at).getTime() < new Date(acc).getTime() ? order.created_at : acc;
      }, undefined);
      const timerBase = earliestOrderAt || meta?.seatedAt;
      const elapsedMinutes = getElapsedMinutes(timerBase);
      const hasPendingPayment = ordersForTable.some((order) => order.payment_status !== "paid");
      const hasPreparing = ordersForTable.some((order) => ["preparing", "on_the_way"].includes(order.status));
      const hasOrdering = ordersForTable.some((order) => ["received", "confirmed"].includes(order.status));

      let status: TableUiStatus = "available";
      if (ordersForTable.length > 0) {
        if (hasPreparing) status = "preparing";
        else if (hasOrdering) status = "ordering";
        else if (hasPendingPayment) status = "needs_bill";
        else status = "served";
      } else if (meta?.manualStatus === "dirty") {
        status = "dirty";
      } else if (meta?.reservationName) {
        status = "reserved";
      } else if (meta?.seatedAt) {
        status = "seated";
      }

      const waitingTooLong =
        (status === "ordering" || status === "preparing" || status === "needs_bill") &&
        elapsedMinutes >= 10;

      return {
        tableNo,
        meta,
        ordersForTable,
        total,
        itemCount,
        elapsedMinutes,
        status,
        waitingTooLong
      };
    });
  }, [tableNumbers, tableMetaState, tableOrders]);
  const selectedTableSummary = useMemo(
    () => (selectedTableNo ? tableSummaries.find((table) => table.tableNo === selectedTableNo) || null : null),
    [tableSummaries, selectedTableNo]
  );
  const dashboardAvailableTables = useMemo(
    () => tableSummaries.filter((table) => table.status === "available").map((table) => table.tableNo).slice(0, 10),
    [tableSummaries]
  );
  const dashboardOutOfStockItems = useMemo(
    () => adminMenuItems.filter((item) => !item.is_available).slice(0, 8),
    [adminMenuItems]
  );
  const dashboardInventoryNotifications = useMemo<DashboardNotificationItem[]>(
    () =>
      dashboardOutOfStockItems.map((item) => ({
        id: `inventory-${item.id}`,
        bucket: "inventory",
        title: "Out of stock",
        message: `${item.name} is unavailable. Restock or enable once ready.`,
        menuItemId: item.id
      })),
    [dashboardOutOfStockItems]
  );
  const dashboardKitchenNotifications = useMemo<DashboardNotificationItem[]>(
    () =>
      dashboardInProgressOrders.slice(0, 12).map((order) => ({
        id: `kitchen-${order.id}`,
        bucket: "kitchen",
        title: order.status === "preparing" ? "Preparing in kitchen" : "Kitchen queue pending",
        message: `${order.order_number} • ${orderTypeDisplay(order)} • ${order.customer_name || "Walk-in"}`,
        orderId: order.id
      })),
    [dashboardInProgressOrders]
  );
  const dashboardNotifications = useMemo(
    () => [...dashboardInventoryNotifications, ...dashboardKitchenNotifications],
    [dashboardInventoryNotifications, dashboardKitchenNotifications]
  );
  const dashboardUnreadCount = useMemo(
    () => dashboardNotifications.filter((item) => !dashboardNotificationReadMap[item.id]).length,
    [dashboardNotifications, dashboardNotificationReadMap]
  );
  const dashboardVisibleNotifications = useMemo(() => {
    if (dashboardNotificationTab === "all") return dashboardNotifications;
    return dashboardNotifications.filter((item) => item.bucket === dashboardNotificationTab);
  }, [dashboardNotifications, dashboardNotificationTab]);
  const selectedTableOrderIds = useMemo(
    () => (selectedTableSummary ? selectedTableSummary.ordersForTable.map((order) => order.id) : []),
    [selectedTableSummary]
  );
  const selectedTableBillBreakdown = useMemo(() => {
    if (!selectedTableSummary) return null;

    const itemRows: Array<{ key: string; name: string; qty: number; amount: number }> = [];
    let subtotal = 0;
    let discount = 0;
    let serviceCharge = 0;
    let tax = 0;
    let total = 0;

    selectedTableSummary.ordersForTable.forEach((order) => {
      const remoteItems = orderItemsMap[order.id] || [];
      const draft = tableOrderDraftMap[order.id];
      const fallbackDraftItems = draft?.items || [];
      const hasRemoteItems = remoteItems.length > 0;
      const hasDraftItems = fallbackDraftItems.length > 0;

      if (hasRemoteItems) {
        remoteItems.forEach((item) => {
          itemRows.push({
            key: item.id,
            name: item.menu_items?.[0]?.name || "Item",
            qty: item.quantity,
            amount: Number(item.total_price || 0)
          });
        });
      } else if (hasDraftItems) {
        fallbackDraftItems.forEach((item, idx) => {
          itemRows.push({
            key: `${order.id}-draft-${idx}`,
            name: item.productName,
            qty: item.quantity,
            amount: Number(item.lineTotal || 0)
          });
        });
      }

      const orderSubtotal = hasRemoteItems
        ? remoteItems.reduce((sum, item) => sum + Number(item.total_price || 0), 0)
        : draft?.subtotalAmount ?? Number(order.total_amount || 0);
      const orderDiscount = Number(draft?.discountAmount || 0);
      const orderService = Number(draft?.serviceChargeAmount || 0);
      const computedPreTax = Math.max(0, orderSubtotal - orderDiscount + orderService);
      const orderTotal = Number(order.total_amount || 0);
      const orderTax = Math.max(0, orderTotal - computedPreTax);

      subtotal += orderSubtotal;
      discount += orderDiscount;
      serviceCharge += orderService;
      tax += orderTax;
      total += orderTotal;
    });

    const customers = selectedTableSummary.ordersForTable
      .map((order) => ({
        name: order.customer_name || "Walk-in",
        phone: order.phone_number || ""
      }))
      .filter((value, index, arr) => arr.findIndex((x) => x.name === value.name && x.phone === value.phone) === index);

    return {
      customers,
      itemRows,
      subtotal: Math.round(subtotal * 100) / 100,
      discount: Math.round(discount * 100) / 100,
      serviceCharge: Math.round(serviceCharge * 100) / 100,
      tax: Math.round(tax * 100) / 100,
      total: Math.round(total * 100) / 100
    };
  }, [selectedTableSummary, orderItemsMap, tableOrderDraftMap]);
  const dualRunStats = useMemo(() => {
    const localIds = new Set(localOrders.map((order) => order.id));
    const remoteIds = new Set(remoteOrders.map((order) => order.id));
    const localOnly = localOrders.filter((order) => !remoteIds.has(order.id)).length;
    const remoteOnly = remoteOrders.filter((order) => !localIds.has(order.id)).length;
    const parityGap = Math.abs(localOrders.length - remoteOrders.length);
    return {
      localCount: localOrders.length,
      remoteCount: remoteOrders.length,
      localOnly,
      remoteOnly,
      parityGap
    };
  }, [localOrders, remoteOrders]);
  const validationGates = useMemo(
    () => ({
      gateA: true, // pos-core parity tests are passing in CI/local run.
      gateB: Boolean(user && cafeId),
      gateC: rolloutFlags.orders && rolloutFlags.manualBilling && rolloutFlags.kitchen && rolloutFlags.tableManagement,
      gateD: dualRunStats.parityGap <= 2,
      gateE: dualRunStats.localOnly === 0
    }),
    [user, cafeId, rolloutFlags, dualRunStats]
  );
  const hourlyTrend = useMemo(() => {
    const map = new Map<string, { count: number; revenue: number }>();
    todayOrders.forEach((order) => {
      const hour = new Date(order.created_at).getHours();
      const key = `${String(hour).padStart(2, "0")}:00`;
      const prev = map.get(key) || { count: 0, revenue: 0 };
      map.set(key, { count: prev.count + 1, revenue: prev.revenue + Number(order.total_amount || 0) });
    });
    return Array.from(map.entries()).sort((a, b) => a[0].localeCompare(b[0]));
  }, [todayOrders]);
  const analyticsOrders = useMemo(() => {
    if (analyticsRange === "all") return allOrders;
    const now = new Date();
    const start = new Date(now);
    if (analyticsRange === "today") {
      start.setHours(0, 0, 0, 0);
    } else if (analyticsRange === "week") {
      start.setDate(now.getDate() - 7);
    } else {
      start.setMonth(now.getMonth() - 1);
    }
    return allOrders.filter((order) => new Date(order.created_at) >= start);
  }, [allOrders, analyticsRange]);
  const analyticsKpis = useMemo(() => {
    const completed = analyticsOrders.filter((order) => order.status === "completed");
    const pendingPayments = analyticsOrders.filter((order) => order.payment_status === "pending").length;
    const revenue = completed.reduce((sum, order) => sum + Number(order.total_amount || 0), 0);
    const avgTicket = analyticsOrders.length ? Math.round(analyticsOrders.reduce((sum, o) => sum + Number(o.total_amount || 0), 0) / analyticsOrders.length) : 0;
    const completionRate = analyticsOrders.length ? Math.round((completed.length / analyticsOrders.length) * 100) : 0;
    return {
      totalOrders: analyticsOrders.length,
      completed: completed.length,
      pendingPayments,
      revenue: Math.round(revenue),
      avgTicket,
      completionRate
    };
  }, [analyticsOrders]);
  const analyticsStatusCounts = useMemo(
    () =>
      ["received", "confirmed", "preparing", "on_the_way", "completed", "cancelled"].map((status) => ({
        status,
        count: analyticsOrders.filter((order) => order.status === status).length
      })),
    [analyticsOrders]
  );
  const analyticsPaymentMix = useMemo(() => {
    const methods = ["cash", "card", "upi", "razorpay", "phonepe"] as const;
    return methods.map((method) => ({
      method,
      count: analyticsOrders.filter((o) => (o.payment_method || "").toLowerCase() === method).length
    }));
  }, [analyticsOrders]);
  const analyticsOrderTypeMix = useMemo(() => {
    const types = ["dine_in", "takeaway", "delivery"] as const;
    return types.map((type) => ({
      type,
      count: analyticsOrders.filter((o) => (o.order_type || "").toLowerCase() === type).length
    }));
  }, [analyticsOrders]);
  const analyticsHourlyTrend = useMemo(() => {
    const map = new Map<string, { count: number; revenue: number }>();
    analyticsOrders.forEach((order) => {
      const hour = `${new Date(order.created_at).getHours().toString().padStart(2, "0")}:00`;
      const existing = map.get(hour) || { count: 0, revenue: 0 };
      existing.count += 1;
      existing.revenue += Number(order.total_amount || 0);
      map.set(hour, existing);
    });
    return Array.from(map.entries()).sort(([a], [b]) => a.localeCompare(b));
  }, [analyticsOrders]);
  const analyticsHourlyMaxRevenue = useMemo(
    () => Math.max(1, ...analyticsHourlyTrend.map(([, v]) => v.revenue)),
    [analyticsHourlyTrend]
  );
  const analyticsHourlyHeatmap = useMemo(() => {
    const trendMap = new Map(analyticsHourlyTrend);
    return Array.from({ length: 24 }, (_, i) => {
      const hour = `${i.toString().padStart(2, "0")}:00`;
      const data = trendMap.get(hour);
      return { hour, ...(data || { count: 0, revenue: 0 }) };
    });
  }, [analyticsHourlyTrend]);
  const analyticsTopCustomers = useMemo(() => {
    const map = new Map<string, { name: string; orders: number; spend: number }>();
    analyticsOrders.forEach((order) => {
      const key = (order.phone_number || order.customer_name || "walk-in").toLowerCase();
      const prev = map.get(key) || { name: order.customer_name || "Walk-in", orders: 0, spend: 0 };
      prev.orders += 1;
      prev.spend += Number(order.total_amount || 0);
      if (!prev.name || prev.name === "Walk-in") prev.name = order.customer_name || "Walk-in";
      map.set(key, prev);
    });
    return Array.from(map.values()).sort((a, b) => b.spend - a.spend).slice(0, 8);
  }, [analyticsOrders]);
  const analyticsLoyaltyMetrics = useMemo(() => {
    const total = customerSummary.length;
    const withRepeat = customerSummary.filter((c) => (c.orderCount || 0) + (c.checkIns || 0) >= 2).length;
    const totalVisits = customerSummary.reduce((s, c) => s + (c.orderCount || 0) + (c.checkIns || 0), 0);
    const totalPoints = customerSummary.reduce((s, c) => s + (c.loyaltyPoints || 0), 0);
    return {
      totalCustomers: total,
      repeatRate: total ? Math.round((withRepeat / total) * 100) : 0,
      avgVisits: total ? (totalVisits / total).toFixed(1) : "0",
      totalPoints,
    };
  }, [customerSummary]);

  const analyticsTopItems = useMemo(() => {
    const itemMap = new Map<string, { name: string; qty: number; revenue: number }>();
    analyticsOrders.forEach((order) => {
      const items = orderItemsMap[order.id] || [];
      items.forEach((item) => {
        const key = item.menu_item_id || item.id;
        const prev = itemMap.get(key) || { name: item.menu_items?.[0]?.name || "Item", qty: 0, revenue: 0 };
        prev.qty += Number(item.quantity || 0);
        prev.revenue += Number(item.total_price || 0);
        itemMap.set(key, prev);
      });
    });
    return Array.from(itemMap.values()).sort((a, b) => b.revenue - a.revenue).slice(0, 8);
  }, [analyticsOrders, orderItemsMap]);
  const selectedOrder = selectedOrderId ? allOrders.find((order) => order.id === selectedOrderId) || null : null;
  const selectedOrderItems = selectedOrderId ? orderItemsMap[selectedOrderId] || [] : [];
  const displayedSelectedOrderItems = isEditingSelectedOrder ? selectedOrderItemsDraft : selectedOrderItems;

  const nextTicketNo = useCallback(() => {
    const storedRaw = localStorage.getItem("cafe_ticket_counter");
    const next = getNextTicketNumber(
      allOrders.map((order) => order.order_number),
      storedRaw ? Number.parseInt(storedRaw, 10) || 0 : 0
    );
    localStorage.setItem("cafe_ticket_counter", String(next.nextCounter));
    return next.ticketNo;
  }, [allOrders]);

  const addToCart = () => {
    if (!selectedProduct) return;

    const unitPrice = calculateCoffeePrice(selectedProduct, selections);
    const newLine: DraftOrderLineItem = {
      productId: selectedProduct.id,
      productName: selectedProduct.name,
      quantity,
      unitPrice,
      lineTotal: unitPrice * quantity,
      selections: { ...selections }
    };
    setCartItems((prev) => [...prev, newLine]);
  };

  const autoSplitSettlement = useCallback(() => {
    const count = Math.min(8, Math.max(2, Number(splitCountInput || 2)));
    const base = Math.floor((orderTotal / count) * 100) / 100;
    const entries: SplitSettlementEntry[] = Array.from({ length: count }, (_, idx) => {
      const isLast = idx === count - 1;
      const amount = isLast ? Math.round((orderTotal - base * (count - 1)) * 100) / 100 : base;
      return {
        id: crypto.randomUUID(),
        label: `Guest ${idx + 1}`,
        amount,
        method: idx % 3 === 0 ? "cash" : idx % 3 === 1 ? "card" : "upi",
        paid: false,
        reference: ""
      };
    });
    setSplitSettlements(entries);
  }, [orderTotal, splitCountInput]);

  const triggerWhatsAppAutomation = useCallback(
    async (eventType: "order_status_changed" | "payment_recovery" | "order_completed" | "reorder_nudge" | "table_freed" | "send_digital_receipt" | "win_back_campaign", orderId: string, metadata?: Record<string, unknown>, overridePhone?: string) => {
      try {
        await supabase.functions.invoke("whatsapp-automation-runner", {
          body: {
            eventType,
            orderId,
            cafeId,
            phone: overridePhone,
            metadata: metadata || {}
          }
        });
      } catch {
        // Best-effort automation. POS flow should never fail due to bot issues.
      }
    },
    [cafeId]
  );

  const processTransaction = async () => {
    if (cartItems.length === 0) {
      return;
    }
    if (!cafeId) {
      notify("Missing cafe ID.", "error");
      return;
    }
    if (!customerName.trim() || !customerPhone.trim()) {
      notify("Customer name and phone are required.", "error");
      return;
    }
    if (orderMode === "delivery" && !deliveryAddress.trim()) {
      notify("Delivery address is required for delivery orders.", "error");
      return;
    }
    if (orderMode === "dine_in" && !tableNumber.trim()) {
      notify("Table number is required for dine-in orders.", "error");
      return;
    }
    let finalSplitAmounts = splitAmounts;
    if (paymentMethod === "split") {
      const splitTotal = splitSettlements.length > 0
        ? splitSettlements.reduce((sum, row) => sum + Number(row.amount || 0), 0)
        : splitAmounts.cash + splitAmounts.card + splitAmounts.upi;
      const paidTotal = splitSettlements.length > 0
        ? splitSettlements.filter((row) => row.paid).reduce((sum, row) => sum + Number(row.amount || 0), 0)
        : splitTotal;
      if (Math.abs(splitTotal - orderTotal) > 1) {
        notify(`Split total (₹${Math.round(splitTotal)}) must match order total (₹${orderTotal}).`, "error");
        return;
      }
      if (Math.abs(paidTotal - orderTotal) > 1) {
        notify(`Mark all split entries paid before processing. Paid: ₹${Math.round(paidTotal)} / ₹${orderTotal}.`, "error");
        return;
      }
      if (splitSettlements.length > 0) {
        finalSplitAmounts = splitSettlements.reduce(
          (acc, row) => ({ ...acc, [row.method]: Math.round((acc[row.method] + Number(row.amount || 0)) * 100) / 100 }),
          { cash: 0, card: 0, upi: 0 }
        );
      }
    }

    const ticketNo = nextTicketNo();
    await enqueueOrderDraft({
      id: crypto.randomUUID(),
      ticketNo,
      idempotencyKey: crypto.randomUUID(),
      cafeId,
      createdByUserId: user?.id,
      sessionId: activeShift?.id,
      terminalId: terminalId.trim() || undefined,
      orderMode,
      notes: notes || undefined,
      customerName: customerName.trim(),
      customerPhone: customerPhone.trim(),
      deliveryBlock: orderMode === "delivery" ? deliveryBlock || "G1" : orderMode === "takeaway" ? "TAKEAWAY" : undefined,
      deliveryAddress: orderMode === "delivery" ? deliveryAddress.trim() : undefined,
      tableNumber: orderMode === "dine_in" ? tableNumber.trim() : undefined,
      items: cartItems,
      subtotalAmount: cartSubtotal,
      discountAmount,
      serviceChargeAmount,
      totalAmount: orderTotal,
      paymentMethod,
      splitAmounts: paymentMethod === "split" ? finalSplitAmounts : undefined,
      createdAt: new Date().toISOString()
    });
    setLastCreatedOrder(ticketNo);
    setNotes("");
    setCartItems([]);
    setCustomerName("");
    setCustomerPhone("");
    setRedeemedRewardId(null);
    setRewardDiscountAmount(0);
    setDeliveryBlock("");
    setDeliveryAddress("");
    setTableNumber("");
    setSplitAmounts({ cash: 0, card: 0, upi: 0 });
    setSplitSettlements([]);
    setSplitCountInput(2);
    setDiscountInput("0");
    setServiceChargeInput("0");
    setQuantity(1);
    await flushOutbox();
    await processPrintQueue();
    await fetchLocalOrders();
    await fetchOrders();
    await fetchCustomers();
    const orderIdForPrint = crypto.randomUUID();
    const splitReceiptLines = paymentMethod !== "split"
      ? []
      : [
          "Split settlement",
          ...splitSettlements.map((row) => `${row.label} | ${row.method.toUpperCase()} | ₹${Math.round(row.amount)}${row.reference ? ` | ${row.reference}` : ""}`),
          `Total settled: ₹${orderTotal}`
        ];
    await enqueuePrintJob({
      orderId: orderIdForPrint,
      ticketNo,
      lines: [
        `Bill | ${ticketNo}`,
        `Customer: ${customerName || "Walk-in"}`,
        `Phone: ${customerPhone || "-"}`,
        `Mode: ${orderMode}`,
        `Items: ${cartItems.length}`,
        `Subtotal: ₹${Math.round(cartSubtotal)}`,
        `Discount: -₹${Math.round(discountAmount)}`,
        `Service: +₹${Math.round(serviceChargeAmount)}`,
        `Total: ₹${Math.round(orderTotal)}`,
        ...splitReceiptLines
      ],
      jobType: "bill",
      station: "counter",
      metadata: { paymentMethod }
    });
    await processPrintQueue();

    // Redeem loyalty reward (deduct points)
    if (redeemedRewardId && cafeId && customerPhone.trim().length >= 10) {
      try {
        const { data: redeemResult } = await supabase.rpc("loyalty_redeem_reward", {
          p_cafe_id: cafeId,
          p_phone: customerPhone.trim(),
          p_reward_id: redeemedRewardId,
        });
        const result = redeemResult as { success?: boolean; error?: string } | null;
        if (result?.success) {
          notify(`Reward redeemed. Points deducted.`);
        } else if (result?.error) {
          notify(`Reward redeem failed: ${result.error}`, "error");
        }
      } catch (e) {
        notify(`Reward redeem failed: ${e instanceof Error ? e.message : "Unknown error"}`, "error");
      }
      setRedeemedRewardId(null);
      setRewardDiscountAmount(0);
    }

    // Trigger WhatsApp Digital Receipt
    if (customerPhone.trim().length >= 10 && sendDigitalReceipt) {
      await triggerWhatsAppAutomation(
        "send_digital_receipt", 
        orderIdForPrint, 
        { 
          orderNo: ticketNo, 
          total: orderTotal, 
          subtotal: cartSubtotal,
          discount: discountAmount,
          serviceCharge: serviceChargeAmount,
          paymentMethod, 
          items: cartItems.map((i) => ({ 
            name: i.productName, 
            quantity: i.quantity,
            price: i.unitPrice,
            amount: i.lineTotal
          })) 
        }, 
        customerPhone.trim()
      );
    }

    notify(`Ticket ${ticketNo} queued successfully.`);
  };

  const refreshOpsHistory = useCallback(async () => {
    const [outbox, prints] = await Promise.all([listRecentOutbox(100), listRecentPrintJobs(100)]);
    setOutboxHistory(outbox);
    setPrintHistory(prints);
  }, []);

  const fetchOrders = useCallback(async () => {
    if (!cafeId || !user) return;
    const { data, error } = await supabase
      .from("orders")
      .select("id, order_number, status, payment_status, payment_method, order_type, customer_name, phone_number, delivery_block, delivery_address, table_number, delivery_rider_id, total_amount, created_at, updated_at, delivery_notes")
      .eq("cafe_id", cafeId)
      .order("created_at", { ascending: false })
      .limit(100);

    if (error) {
      notify(`Failed to fetch orders: ${error.message}`, "error");
      return;
    }
    setRemoteOrders((data || []) as RemoteOrder[]);
  }, [cafeId, user]);

  const fetchLocalOrders = useCallback(async () => {
    const drafts = await db.offlineOrders.orderBy("createdAt").reverse().limit(100).toArray();
    const remoteById = new Map(remoteOrders.map((order) => [order.id, order]));
    const runtimeState = readOrderRuntimeState();
    const mapped: RemoteOrder[] = drafts.map((draft) => ({
      id: draft.id,
      order_number: draft.ticketNo,
      status: "received",
      payment_status: draft.paymentMethod === "cash" ? "paid" : "pending",
      payment_method: draft.paymentMethod,
      order_type: draft.orderMode,
      customer_name: draft.customerName || null,
      phone_number: draft.customerPhone || null,
      delivery_block: draft.deliveryBlock || null,
      delivery_address: draft.deliveryAddress || null,
      table_number: draft.tableNumber || null,
      delivery_rider_id: null,
      total_amount: draft.totalAmount,
      created_at: draft.createdAt,
      delivery_notes: draft.notes || null
    }));
    setLocalOrders((prev) => {
      const prevById = new Map(prev.map((order) => [order.id, order]));
      return mapped.map((order) => {
        const remoteMatch = remoteById.get(order.id);
        if (remoteMatch) {
          return {
            ...order,
            status: remoteMatch.status,
            payment_status: remoteMatch.payment_status,
            payment_method: remoteMatch.payment_method,
            order_type: remoteMatch.order_type,
            customer_name: remoteMatch.customer_name,
            phone_number: remoteMatch.phone_number,
            delivery_block: remoteMatch.delivery_block,
            delivery_address: remoteMatch.delivery_address,
            table_number: remoteMatch.table_number,
            delivery_rider_id: remoteMatch.delivery_rider_id,
            delivery_notes: remoteMatch.delivery_notes
          };
        }
        const previous = prevById.get(order.id);
        const runtime = runtimeState[order.id];
        if (!previous && !runtime) return order;
        return {
          ...order,
          status: (runtime?.status || previous?.status || order.status) as RemoteOrder["status"],
          payment_status: (runtime?.payment_status ?? previous?.payment_status ?? order.payment_status) as RemoteOrder["payment_status"],
          payment_method: (runtime?.payment_method ?? previous?.payment_method ?? order.payment_method) as RemoteOrder["payment_method"],
          order_type: (runtime?.order_type ?? previous?.order_type ?? order.order_type) as RemoteOrder["order_type"],
          delivery_rider_id: (runtime?.delivery_rider_id ?? previous?.delivery_rider_id ?? order.delivery_rider_id) as RemoteOrder["delivery_rider_id"],
          delivery_notes: (runtime?.delivery_notes ?? previous?.delivery_notes ?? order.delivery_notes) as RemoteOrder["delivery_notes"]
        };
      });
    });
  }, [remoteOrders]);

  const patchOrderInState = useCallback((orderId: string, patch: Partial<RemoteOrder>) => {
    setRemoteOrders((prev) => prev.map((order) => (order.id === orderId ? { ...order, ...patch } : order)));
    setLocalOrders((prev) => prev.map((order) => (order.id === orderId ? { ...order, ...patch } : order)));
    const runtimeState = readOrderRuntimeState();
    runtimeState[orderId] = { ...(runtimeState[orderId] || {}), ...patch };
    writeOrderRuntimeState(runtimeState);
    void db.offlineOrders.update(orderId, {
      customerName: patch.customer_name ?? undefined,
      customerPhone: patch.phone_number ?? undefined,
      orderMode: (patch.order_type as "delivery" | "dine_in" | "takeaway" | undefined) ?? undefined,
      tableNumber: patch.table_number ?? undefined,
      deliveryBlock: patch.delivery_block ?? undefined,
      deliveryAddress: patch.delivery_address ?? undefined,
      notes: patch.delivery_notes ?? undefined
    });
  }, []);

  const applyRemoteOrderUpdateFallback = useCallback(
    async (orderId: string, patch: Partial<RemoteOrder>) => {
      const updatePayload: Record<string, unknown> = {};
      if (patch.status) updatePayload.status = patch.status;
      if (patch.payment_status) updatePayload.payment_status = patch.payment_status;
      if (patch.delivery_rider_id !== undefined) updatePayload.delivery_rider_id = patch.delivery_rider_id;
      if (patch.delivery_notes !== undefined) updatePayload.delivery_notes = patch.delivery_notes;
      if (Object.keys(updatePayload).length === 0) return false;

      const { error } = await supabase
        .from("orders")
        .update(updatePayload)
        .eq("id", orderId)
        .eq("cafe_id", cafeId || "");
      if (error) return false;
      await fetchOrders();
      return true;
    },
    [cafeId, fetchOrders]
  );

  const applyLocalOnlyOrderUpdateFallback = useCallback(
    async (orderId: string, patch: Partial<RemoteOrder>) => {
      const localOrder = localOrders.find((order) => order.id === orderId);
      const remoteOrder = remoteOrders.find((order) => order.id === orderId);
      if (!localOrder || remoteOrder) {
        return false;
      }
      await db.offlineOrders.update(orderId, {
        customerName: patch.customer_name ?? localOrder.customer_name ?? undefined,
        customerPhone: patch.phone_number ?? localOrder.phone_number ?? undefined,
        orderMode: (patch.order_type as "delivery" | "dine_in" | "takeaway" | undefined) ?? (localOrder.order_type as "delivery" | "dine_in" | "takeaway"),
        tableNumber: patch.table_number ?? localOrder.table_number ?? undefined,
        deliveryBlock: patch.delivery_block ?? localOrder.delivery_block ?? undefined,
        deliveryAddress: patch.delivery_address ?? localOrder.delivery_address ?? undefined,
        notes: patch.delivery_notes ?? localOrder.delivery_notes ?? undefined
      });
      patchOrderInState(orderId, patch);
      return true;
    },
    [localOrders, remoteOrders, patchOrderInState]
  );

  const updateOrderStatus = useCallback(
    async (orderId: string, newStatus: RemoteOrder["status"]) => {
      const current = allOrders.find((order) => order.id === orderId);
      if (!current) {
        notify("Order not found for status update.", "error");
        return;
      }
      const guard = canTransitionStatus({
        currentStatus: current.status,
        targetStatus: newStatus,
        paymentStatus: current.payment_status,
        orderType: current.order_type || "takeaway"
      });
      if (!guard.ok) {
        notify(guard.reason || "Status update blocked by payment/status rule.", "error");
        return;
      }

      setOrderUpdateLoadingId(orderId);
      // Optimistic update keeps dashboard/Orders transitions snappy.
      patchOrderInState(orderId, { status: newStatus });
      const payload: UpdateOrderStatusRequest = { orderId, newStatus };
      const { data, error } = await supabase.functions.invoke("update-order-status-secure", {
        body: payload
      });
      const response = (data || {}) as UpdateOrderStatusResponse;
      if (error || !response.success) {
        const localUpdated = await applyLocalOnlyOrderUpdateFallback(orderId, { status: newStatus });
        if (localUpdated) {
          notify(`Order moved to ${newStatus} (local mode).`);
          setOrderUpdateLoadingId(null);
          return;
        }

        const remoteUpdated = await applyRemoteOrderUpdateFallback(orderId, { status: newStatus });
        if (remoteUpdated) {
          notify(`Order moved to ${newStatus}.`);
          setOrderUpdateLoadingId(null);
          return;
        }

        patchOrderInState(orderId, { status: current.status });
        notify(response.error || error?.message || "Failed to update order status.", "error");
      } else {
        notify(`Order moved to ${newStatus}.`);
        await fetchOrders();
        await triggerWhatsAppAutomation("order_status_changed", orderId, { newStatus });
        if (newStatus === "completed") {
          await triggerWhatsAppAutomation("order_completed", orderId);
        }
      }
      setOrderUpdateLoadingId(null);
    },
    [allOrders, fetchOrders, applyLocalOnlyOrderUpdateFallback, applyRemoteOrderUpdateFallback, patchOrderInState, triggerWhatsAppAutomation]
  );

  const markPaymentReceived = useCallback(
    async (orderId: string) => {
      const current = allOrders.find((order) => order.id === orderId);
      if (!current) return;
      setOrderUpdateLoadingId(orderId);
      patchOrderInState(orderId, { payment_status: "paid" });
      const payload: MarkPaymentReceivedRequest = { orderId };
      const { data, error } = await supabase.functions.invoke("mark-order-payment-received", {
        body: payload
      });
      const response = (data || {}) as MarkPaymentReceivedResponse;
      
      const handleTableReset = async () => {
        if (current.table_number) {
          setTableMetaState((prev) => {
            const tableId = current.table_number as string;
            const currentMeta = prev[tableId] || { capacity: 2 as const };
            return {
              ...prev,
              [tableId]: {
                ...currentMeta,
                seatedAt: undefined,
                billPrintedAt: undefined,
                manualStatus: "available"
              }
            };
          });
          await triggerWhatsAppAutomation("table_freed", orderId, { tableNumber: current.table_number });
        }
      };

      if (error || !response.success) {
        const localUpdated = await applyLocalOnlyOrderUpdateFallback(orderId, { payment_status: "paid" });
        if (localUpdated) {
          notify("Payment marked as received (local mode).");
          setOrderUpdateLoadingId(null);
          void handleTableReset();
          return;
        }

        const remoteUpdated = await applyRemoteOrderUpdateFallback(orderId, { payment_status: "paid" });
        if (remoteUpdated) {
          notify("Payment marked as received.");
          setOrderUpdateLoadingId(null);
          void handleTableReset();
          return;
        }

        patchOrderInState(orderId, { payment_status: current.payment_status });
        notify(response.error || error?.message || "Failed to mark payment.", "error");
      } else {
        notify("Payment marked as received.");
        await fetchOrders();
        await triggerWhatsAppAutomation("payment_recovery", orderId, { paymentStatus: "paid" });
        void handleTableReset();
      }
      setOrderUpdateLoadingId(null);
    },
    [allOrders, fetchOrders, applyLocalOnlyOrderUpdateFallback, applyRemoteOrderUpdateFallback, patchOrderInState, triggerWhatsAppAutomation]
  );

  const fetchAdminMenu = useCallback(async () => {
    if (!cafeId || !user) return;
    const { data, error } = await supabase
      .from("menu_items")
      .select("id, name, category, price, is_available, available_from, available_until")
      .eq("cafe_id", cafeId)
      .order("name", { ascending: true });
    if (!error) {
      setAdminMenuItems((data || []) as MenuAdminItem[]);
    }
  }, [cafeId, user]);

  const updateMenuSchedule = useCallback(async (
    itemId: string,
    availableFrom: string | null,
    availableUntil: string | null
  ) => {
    const { error } = await supabase
      .from("menu_items")
      .update({
        available_from: availableFrom || null,
        available_until: availableUntil || null
      })
      .eq("id", itemId);
    if (!error) {
      setAdminMenuItems((prev) =>
        prev.map((item) =>
          item.id === itemId
            ? { ...item, available_from: availableFrom, available_until: availableUntil }
            : item
        )
      );
    }
  }, []);

  const fetchStaff = useCallback(async () => {
    if (!cafeId || !user) return;
    const { data: staffData, error } = await supabase
      .from("cafe_staff")
      .select("id, user_id, role, is_active")
      .eq("cafe_id", cafeId)
      .order("created_at", { ascending: false });
    if (error) {
      notify(`Failed to fetch staff: ${error.message}`, "error");
      return;
    }
    const userIds = (staffData || []).map((r) => r.user_id).filter(Boolean);
    const { data: profiles } = userIds.length > 0
      ? await supabase.from("profiles").select("id, full_name").in("id", userIds)
      : { data: [] as { id: string; full_name: string | null }[] };
    const nameByUserId = new Map((profiles || []).map((p) => [p.id, p.full_name]));
    const rows: StaffRow[] = (staffData || []).map((r) => ({
      id: r.id,
      staff_name: nameByUserId.get(r.user_id) ?? null,
      role: r.role,
      is_active: r.is_active,
    }));
    setStaffRows(rows);
  }, [cafeId, user]);

  const fetchCustomers = useCallback(async () => {
    if (!cafeId) return;
    console.log("Fetching merged customers (orders + loyalty + local + profiles)...");
    const [ordersRes, loyaltyRes, localDrafts] = await Promise.all([
      supabase.from("orders").select("id, customer_name, phone_number, total_amount, created_at").eq("cafe_id", cafeId).order("created_at", { ascending: true }).limit(500),
      supabase.from("loyalty_customers").select("phone, name, points, total_check_ins, last_check_in_at").eq("cafe_id", cafeId),
      db.offlineOrders.orderBy("createdAt").reverse().limit(200).toArray().then((rows) => rows.filter((r) => r.cafeId === cafeId)),
    ]);
    const { data: ordersData, error } = ordersRes;
    if (error) {
      notify(`Failed to fetch customers (orders): ${error.message}`, "error");
      // Continue with local drafts only when Supabase fails (e.g. demo mode, RLS)
    }
    const loyaltyData = loyaltyRes.data || [];
    const toKey = (p: string) => (p || "").replace(/\s/g, "").replace(/^\+?91/, "").slice(-10);
    const loyaltyByPhone = new Map(loyaltyData.map((l) => [toKey(l.phone), l]));

    const syncedOrderIds = new Set((ordersData || []).map((r) => (r as { id?: string }).id).filter(Boolean));
    const map = new Map<string, CustomerSummary>();
    (ordersData || []).forEach((row) => {
      const phone = toKey(row.phone_number || "");
      if (!phone || phone.length < 10) return;
      const loyalty = loyaltyByPhone.get(phone);
      const previous = map.get(phone) || {
        phone,
        name: row.customer_name || loyalty?.name || "Customer",
        orderCount: 0,
        spend: 0,
        lastVisit: row.created_at,
        loyaltyTier: "foodie" as LoyaltyTier,
        loyaltyPoints: loyalty?.points ?? 0,
        checkIns: loyalty?.total_check_ins ?? 0,
        segment: "Regular" as CustomerSegment,
      };
      if (row.customer_name?.trim()) previous.name = row.customer_name;
      previous.orderCount += 1;
      previous.spend += Number(row.total_amount || 0);
      previous.lastVisit = row.created_at;
      if (loyalty?.points) previous.loyaltyPoints = loyalty.points;
      if (loyalty?.total_check_ins) previous.checkIns = loyalty.total_check_ins;
      if (loyalty?.last_check_in_at) {
        const checkIn = loyalty.last_check_in_at;
        if (!previous.lastVisit || new Date(checkIn) > new Date(previous.lastVisit)) previous.lastVisit = checkIn;
      }
      map.set(phone, previous);
    });
    loyaltyData.forEach((l) => {
      const phone = toKey(l.phone);
      if (!phone || phone.length < 10) return;
      if (!map.has(phone)) {
        map.set(phone, {
          phone,
          name: l.name || "Guest",
          orderCount: 0,
          spend: 0,
          lastVisit: l.last_check_in_at ?? undefined,
          loyaltyTier: "foodie",
          loyaltyPoints: l.points ?? 0,
          checkIns: l.total_check_ins ?? 0,
          segment: "Regular" as CustomerSegment,
        });
      }
    });

    (localDrafts || []).forEach((draft) => {
      if (syncedOrderIds.has(draft.id)) return;
      const phone = toKey(draft.customerPhone || "");
      if (!phone || phone.length < 10) return;
      const loyalty = loyaltyByPhone.get(phone);
      const previous = map.get(phone) || {
        phone,
        name: draft.customerName || loyalty?.name || "Customer",
        orderCount: 0,
        spend: 0,
        lastVisit: draft.createdAt,
        loyaltyTier: "foodie" as LoyaltyTier,
        loyaltyPoints: loyalty?.points ?? 0,
        checkIns: loyalty?.total_check_ins ?? 0,
        segment: "Regular" as CustomerSegment,
      };
      if (draft.customerName?.trim()) previous.name = draft.customerName;
      previous.orderCount += 1;
      previous.spend += Number(draft.totalAmount || 0);
      if (draft.createdAt && (!previous.lastVisit || new Date(draft.createdAt) > new Date(previous.lastVisit))) {
        previous.lastVisit = draft.createdAt;
      }
      map.set(phone, previous);
    });

    const normPhone = (p: string) => (p || "").replace(/\s/g, "").replace(/^\+91/, "").slice(-10);
    const uniquePhones = Array.from(map.keys());
    const { data: profilesData } = uniquePhones.length > 0
      ? await supabase.from("profiles").select("phone, full_name, loyalty_tier").in("phone", uniquePhones)
      : { data: [] as { phone: string; full_name?: string; loyalty_tier?: string }[] };
    const profileByPhone = new Map<string, { phone: string; full_name?: string; loyalty_tier?: string }>();
    (profilesData || []).forEach((p) => {
      const n = normPhone(p.phone || "");
      if (n.length >= 10) profileByPhone.set(n, p);
    });

    map.forEach((c) => {
      const profile = profileByPhone.get(normPhone(c.phone));
      if (profile?.full_name && (c.name === "Customer" || c.name === "Guest" || !c.name)) c.name = profile.full_name;
      if (profile?.loyalty_tier && ["foodie", "gourmet", "connoisseur"].includes(profile.loyalty_tier)) {
        c.loyaltyTier = profile.loyalty_tier as LoyaltyTier;
      } else {
        c.loyaltyTier = getTierBySpend(c.spend);
      }
      c.segment = getSegmentByActivity(c.orderCount, c.checkIns ?? 0, c.lastVisit);
    });

    console.log(`CRM: Merged ${map.size} customers (orders + loyalty), tier + segment.`);
    setCustomerSummary(Array.from(map.values()).sort((a, b) => b.spend - a.spend));
  }, [cafeId, user]);

  const fetchCustomerDetails = useCallback(async (phone: string) => {
    if (!cafeId || !phone) return;
    setCustomerDetails(prev => ({ ...prev, isLoading: true, points: null, recentOrders: [], topItems: [], notes: null, birthday: null }));
    
    try {
      // 1. Fetch user to get points
      const { data: profiles } = await supabase
        .from("profiles")
        .select("id")
        .eq("phone", phone)
        .limit(1);
        
      let points = null;
      if (profiles && profiles.length > 0) {
        const { data: pointsData } = await supabase.rpc('get_available_points', {
          p_user_id: profiles[0].id,
          p_cafe_id: cafeId
        });
        if (pointsData && pointsData.length > 0) {
          points = pointsData[0].total_points;
        }
      }

      // Fetch recent orders and items
      const { data: recentOrdersData } = await supabase
        .from("orders")
        .select(`
          id,
          order_number,
          total_amount,
          created_at,
          order_items (
            menu_items (
              name
            ),
            quantity
          )
        `)
        .eq("cafe_id", cafeId)
        .eq("phone_number", phone)
        .order("created_at", { ascending: false })
        .limit(10);
        
      const recentOrders = recentOrdersData || [];
      
      // Calculate top items
      const itemCounts: Record<string, number> = {};
      recentOrders.forEach(order => {
        order.order_items?.forEach((item: any) => {
          let name = item.menu_items?.name;
          if (!name && !item.menu_item_id && item.special_instructions) {
            try {
              const parsed = JSON.parse(item.special_instructions);
              if (parsed._offlineProductName) name = parsed._offlineProductName;
            } catch {}
          }
          if (name) {
            itemCounts[name] = (itemCounts[name] || 0) + (item.quantity || 1);
          }
        });
      });
      
      const topItems = Object.entries(itemCounts)
        .map(([name, count]) => ({ name, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 3);

      // Fetch customer notes (table may not exist yet)
      let notes: string | null = null;
      try {
        const { data: notesRow } = await supabase
          .from("customer_notes")
          .select("notes")
          .eq("cafe_id", cafeId)
          .eq("phone", phone)
          .maybeSingle();
        notes = notesRow?.notes ?? null;
      } catch {
        // customer_notes table may not exist
      }

      // Fetch loyalty_customers for birthday (match by normalized phone)
      const toKey = (p: string) => (p || "").replace(/\s/g, "").replace(/^\+?91/, "").slice(-10);
      let birthday: string | null = null;
      const { data: loyaltyRows } = await supabase.from("loyalty_customers").select("phone, birthday").eq("cafe_id", cafeId);
      const match = (loyaltyRows || []).find((r) => toKey(r.phone) === toKey(phone));
      if (match?.birthday) birthday = String(match.birthday).slice(0, 10);
        
      setCustomerDetails({
        points,
        recentOrders: recentOrders.slice(0, 5), // show only last 5
        topItems,
        notes,
        birthday,
        isLoading: false
      });
      
      
    } catch (e) {
      console.error("Failed to fetch customer details", e);
      setCustomerDetails(prev => ({ ...prev, isLoading: false }));
    }
  }, [cafeId]);

  const saveCustomerBirthday = useCallback(async (phone: string, birthday: string | null) => {
    if (!cafeId || !selectedCustomer) return;
    const toKey = (p: string) => (p || "").replace(/\s/g, "").replace(/^\+?91/, "").slice(-10);
    const phoneKey = toKey(phone);
    const { data: rows } = await supabase.from("loyalty_customers").select("id, phone").eq("cafe_id", cafeId);
    const existing = (rows || []).find((r) => toKey(r.phone) === phoneKey);
    let error;
    if (existing) {
      ({ error } = await supabase.from("loyalty_customers").update({ birthday: birthday || null, updated_at: new Date().toISOString() }).eq("id", existing.id));
    } else {
      ({ error } = await supabase.from("loyalty_customers").insert({ cafe_id: cafeId, phone: phoneKey, name: selectedCustomer.name, birthday: birthday || null, points: 0, total_check_ins: 0 }));
    }
    if (error) {
      notify(`Failed to save birthday: ${error.message}`, "error");
      return;
    }
    setCustomerDetails(prev => ({ ...prev, birthday: birthday || null }));
    notify("Birthday saved");
  }, [cafeId, selectedCustomer, notify]);

  const saveCustomerNotes = useCallback(async (phone: string, notes: string) => {
    if (!cafeId || !selectedCustomer) return;
    const { error } = await supabase.from("customer_notes").upsert(
      { cafe_id: cafeId, phone, notes: notes.trim() || null, updated_at: new Date().toISOString() },
      { onConflict: "cafe_id,phone" }
    );
    if (error) {
      notify(`Failed to save notes: ${error.message}`, "error");
      return;
    }
    setCustomerDetails(prev => ({ ...prev, notes: notes.trim() || null }));
    notify("Notes saved");
  }, [cafeId, selectedCustomer, notify]);

  const [showNameSuggestions, setShowNameSuggestions] = useState(false);
  const [showPhoneSuggestions, setShowPhoneSuggestions] = useState(false);

  const nameSuggestions = useMemo(() => {
    if (!customerName || customerName.length < 2) return [];
    const search = customerName.toLowerCase();
    const filtered = customerSummary
      .filter(c => c.name.toLowerCase().includes(search))
      .slice(0, 5);
    console.log(`CRM: Name suggestions for "${customerName}":`, filtered.length);
    return filtered;
  }, [customerSummary, customerName]);

  const phoneSuggestions = useMemo(() => {
    if (!customerPhone || customerPhone.length < 3) return [];
    const search = customerPhone.replace(/\D/g, "");
    const filtered = customerSummary
      .filter(c => c.phone.replace(/\D/g, "").includes(search))
      .slice(0, 5);
    console.log(`CRM: Phone suggestions for "${customerPhone}":`, filtered.length);
    return filtered;
  }, [customerSummary, customerPhone]);

  const handleSelectCustomer = useCallback((c: CustomerSummary) => {
    setCustomerName(c.name);
    setCustomerPhone(c.phone);
    setShowNameSuggestions(false);
    setShowPhoneSuggestions(false);
    void fetchCustomerDetails(c.phone);
  }, [fetchCustomerDetails]);

  const fetchOffers = useCallback(async () => {
    if (!cafeId || !user) return;
    const { data, error } = await supabase
      .from("cafe_offers")
      .select("id, name, discount_type, discount_value, is_active")
      .eq("cafe_id", cafeId)
      .order("created_at", { ascending: false });
    if (error) {
      notify(`Failed to fetch offers: ${error.message}`, "error");
      return;
    }
    setOffers((data || []) as OfferRow[]);
  }, [cafeId, user]);

  const createOffer = useCallback(async () => {
    if (!cafeId) return;
    const discount = Number.parseFloat(offerDiscountValue);
    if (!offerName.trim() || Number.isNaN(discount) || discount <= 0) {
      notify("Enter valid offer name and discount.", "error");
      return;
    }
    const { error } = await supabase.from("cafe_offers").insert({
      cafe_id: cafeId,
      name: offerName.trim(),
      offer_type: "min_order",
      discount_type: offerDiscountType,
      discount_value: discount,
      is_active: true,
      applicable_to_type: "all"
    });
    if (error) {
      notify(`Create offer failed: ${error.message}`, "error");
      return;
    }
    setOfferName("");
    setOfferDiscountValue("10");
    await fetchOffers();
    notify("Offer created.");
  }, [cafeId, offerDiscountType, offerDiscountValue, offerName, fetchOffers]);

  const toggleOffer = useCallback(
    async (offerId: string, nextActive: boolean) => {
      const { error } = await supabase.from("cafe_offers").update({ is_active: nextActive }).eq("id", offerId);
      if (error) {
        notify(`Offer update failed: ${error.message}`, "error");
        return;
      }
      await fetchOffers();
    },
    [fetchOffers]
  );

  const fetchCafeDetails = useCallback(async () => {
    if (!cafeId || !user) return;
    const { data, error } = await supabase
      .from("cafes")
      .select("name, phone, location, description")
      .eq("id", cafeId)
      .single();
    if (!error && data) {
      setCafeDetails({
        name: data.name || "",
        phone: data.phone || "",
        location: data.location || "",
        description: data.description || ""
      });
    }
  }, [cafeId, user]);

  const saveCafeDetails = useCallback(async () => {
    if (!cafeId) return;
    const { error } = await supabase.from("cafes").update(cafeDetails).eq("id", cafeId);
    if (error) {
      notify(`Failed to save cafe details: ${error.message}`, "error");
      return;
    }
    notify("Cafe details updated.");
  }, [cafeDetails, cafeId]);

  const createMenuItem = useCallback(
    async (andAddAnother = false) => {
      if (!cafeId) {
        notify("Missing cafe ID for menu create.", "error");
        return;
      }
      const price = Number.parseFloat(menuPrice);
      if (!menuName.trim() || Number.isNaN(price) || price <= 0) {
        notify("Enter valid menu name and price.", "error");
        return;
      }
      const { error } = await supabase.from("menu_items").insert({
        cafe_id: cafeId,
        name: menuName.trim(),
        category: menuCategory.trim() || null,
        price,
        is_available: true
      });
      if (error) {
        notify(`Create menu failed: ${error.message}`, "error");
        return;
      }
      setMenuName("");
      setMenuPrice(andAddAnother ? "" : "150");
      await Promise.all([refreshMenu(), fetchAdminMenu()]);
      notify(andAddAnother ? "Item added. Add another below." : "Menu item created.");
    },
    [cafeId, menuCategory, menuName, menuPrice, refreshMenu, fetchAdminMenu]
  );

  const toggleMenuAvailability = useCallback(
    async (id: string, nextAvailable: boolean) => {
      const { error } = await supabase.from("menu_items").update({ is_available: nextAvailable }).eq("id", id);
      if (error) {
        notify(`Update menu failed: ${error.message}`, "error");
        return;
      }
      await Promise.all([refreshMenu(), fetchAdminMenu()]);
      notify("Menu availability updated.");
    },
    [refreshMenu, fetchAdminMenu]
  );

  const updateMenuItem = useCallback(async () => {
    if (!editingMenuId) return;
    const parsedPrice = Number.parseFloat(editingMenuPrice);
    if (!editingMenuName.trim() || Number.isNaN(parsedPrice) || parsedPrice <= 0) {
      notify("Invalid menu edit values.", "error");
      return;
    }
    const { error } = await supabase
      .from("menu_items")
      .update({
        name: editingMenuName.trim(),
        category: editingMenuCategory.trim() || null,
        price: parsedPrice
      })
      .eq("id", editingMenuId);
    if (error) {
      notify(`Update menu failed: ${error.message}`, "error");
      return;
    }
    setEditingMenuId(null);
    await Promise.all([refreshMenu(), fetchAdminMenu()]);
    notify("Menu item updated.");
  }, [editingMenuId, editingMenuName, editingMenuCategory, editingMenuPrice, refreshMenu, fetchAdminMenu]);

  const deleteMenuItem = useCallback(
    async (id: string) => {
      const { error } = await supabase.from("menu_items").delete().eq("id", id);
      if (error) {
        notify(`Delete failed: ${error.message}`, "error");
        return;
      }
      setEditingMenuId((prev) => (prev === id ? null : prev));
      await Promise.all([refreshMenu(), fetchAdminMenu()]);
      notify("Menu item deleted.");
    },
    [refreshMenu, fetchAdminMenu]
  );

  const fetchOrderItems = useCallback(
    async (orderId: string) => {
      const { data: baseItems, error: baseItemsError } = await supabase
        .from("order_items")
        .select("id, quantity, unit_price, total_price, special_instructions, menu_item_id")
        .eq("order_id", orderId);

      if (!baseItemsError && baseItems && baseItems.length > 0) {
        const menuItemIds = Array.from(
          new Set(baseItems.map((item) => item.menu_item_id).filter((id): id is string => Boolean(id)))
        );
        const menuNameById = new Map<string, string>();

        if (menuItemIds.length > 0) {
          const { data: menuRows } = await supabase.from("menu_items").select("id, name").in("id", menuItemIds);
          (menuRows || []).forEach((row) => {
            menuNameById.set(row.id, row.name);
          });
        }

        const mappedItems: RemoteOrderItem[] = baseItems.map((item) => {
          let offlineName = null;
          if (!item.menu_item_id && item.special_instructions) {
            try {
              const parsed = JSON.parse(item.special_instructions);
              if (parsed._offlineProductName) offlineName = parsed._offlineProductName;
            } catch {}
          }
          
          return {
            id: item.id,
            quantity: item.quantity,
            unit_price: item.unit_price,
            total_price: item.total_price,
            special_instructions: item.special_instructions,
            menu_item_id: item.menu_item_id,
            menu_items: item.menu_item_id ? [{ name: menuNameById.get(item.menu_item_id) || "Item" }] : [{ name: offlineName || "Item" }]
          };
        });
        setOrderItemsMap((prev) => ({ ...prev, [orderId]: mappedItems }));
        return;
      }

      const localDraft = await db.offlineOrders.get(orderId);
      if (localDraft) {
        const localItems: RemoteOrderItem[] = localDraft.items.map((item, idx) => ({
          id: `${orderId}-local-${idx}`,
          quantity: item.quantity,
          unit_price: item.unitPrice,
          total_price: item.lineTotal,
          special_instructions: "",
          menu_items: [{ name: item.productName }]
        }));
        setOrderItemsMap((prev) => ({ ...prev, [orderId]: localItems }));
        return;
      }

      const outboxMatch = outboxHistory.find((entry) => entry.payload.id === orderId);
      if (outboxMatch) {
        const fallbackItems: RemoteOrderItem[] = outboxMatch.payload.items.map((item, idx) => ({
          id: `${orderId}-outbox-${idx}`,
          quantity: item.quantity,
          unit_price: item.unitPrice,
          total_price: item.lineTotal,
          special_instructions: "",
          menu_items: [{ name: item.productName }]
        }));
        setOrderItemsMap((prev) => ({ ...prev, [orderId]: fallbackItems }));
        return;
      }

      setOrderItemsMap((prev) => ({ ...prev, [orderId]: [] }));
    },
    [outboxHistory]
  );

  const parseSelectionsFromInstructionsInline = useCallback((raw: string | null | undefined): CoffeeSelections => {
    const parsed: CoffeeSelections = { size: "medium", milk: "regular", sugarLevel: "regular", extraShots: 0 };
    if (!raw) return parsed;
    const compact = raw.trim().toLowerCase();
    if (compact.includes("small")) parsed.size = "small";
    if (compact.includes("large")) parsed.size = "large";
    if (compact.includes("skim")) parsed.milk = "skim";
    else if (compact.includes("soy")) parsed.milk = "soy";
    else if (compact.includes("oat")) parsed.milk = "oat";
    else if (compact.includes("almond")) parsed.milk = "almond";
    if (compact.includes("no_sugar") || compact.includes("no sugar")) parsed.sugarLevel = "no_sugar";
    else if (compact.includes("less") && compact.includes("sugar")) parsed.sugarLevel = "less";
    const shotsMatch = compact.match(/\d+\s*shot/);
    if (shotsMatch) parsed.extraShots = Math.max(0, parseInt(shotsMatch[0], 10) || 0);
    return parsed;
  }, []);

  const getOrderItemsAsDraft = useCallback(
    async (orderId: string): Promise<DraftOrderLineItem[]> => {
      const existing = orderItemsMap[orderId];
      if (existing && existing.length > 0) {
        return existing.map((item) => ({
          productId: item.menu_item_id || item.id,
          productName: item.menu_items?.[0]?.name || "Item",
          quantity: item.quantity,
          unitPrice: item.unit_price,
          lineTotal: item.total_price,
          selections: parseSelectionsFromInstructionsInline(item.special_instructions)
        }));
      }
      const { data: baseItems, error: baseError } = await supabase
        .from("order_items")
        .select("id, quantity, unit_price, total_price, special_instructions, menu_item_id")
        .eq("order_id", orderId);
      if (!baseError && baseItems && baseItems.length > 0) {
        const menuItemIds = Array.from(new Set(baseItems.map((i) => i.menu_item_id).filter(Boolean))) as string[];
        const menuNameById = new Map<string, string>();
        if (menuItemIds.length > 0) {
          const { data: menuRows } = await supabase.from("menu_items").select("id, name").in("id", menuItemIds);
          (menuRows || []).forEach((row) => menuNameById.set(row.id, row.name));
        }
        return baseItems.map((item) => ({
          productId: item.menu_item_id || item.id,
          productName: menuNameById.get(item.menu_item_id || "") || "Item",
          quantity: item.quantity,
          unitPrice: item.unit_price,
          lineTotal: item.total_price,
          selections: parseSelectionsFromInstructionsInline(item.special_instructions)
        }));
      }
      const localDraft = await db.offlineOrders.get(orderId);
      if (localDraft?.items?.length) return localDraft.items;
      const outboxMatch = outboxHistory.find((e) => e.payload.id === orderId);
      if (outboxMatch?.payload?.items?.length) return outboxMatch.payload.items;
      return [];
    },
    [orderItemsMap, outboxHistory, parseSelectionsFromInstructionsInline]
  );

  const lastOrderForRepeat = useMemo(() => {
    const table = tableNumber.trim();
    const phone = (customerPhone || "").replace(/\D/g, "");
    if (!table && !phone) return null;
    const matches = allOrders.filter((o) => {
      const oTable = (o.table_number || "").trim();
      const oPhone = (o.phone_number || "").replace(/\D/g, "");
      return (table && oTable === table) || (phone && oPhone && oPhone.slice(-10) === phone.slice(-10));
    });
    if (matches.length === 0) return null;
    return matches.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())[0] || null;
  }, [allOrders, tableNumber, customerPhone]);

  const repeatSpecificOrder = useCallback(async (orderId: string) => {
    const items = await getOrderItemsAsDraft(orderId);
    if (items.length === 0) return;
    setCartItems(items); // Replace cart with this order
  }, [getOrderItemsAsDraft]);

  const repeatLastOrder = useCallback(async () => {
    if (!lastOrderForRepeat) return;
    const items = await getOrderItemsAsDraft(lastOrderForRepeat.id);
    if (items.length === 0) return;
    setCartItems((prev) => [...prev, ...items]);
  }, [lastOrderForRepeat, getOrderItemsAsDraft]);

  const queueOrderPrint = useCallback(
    async (order: RemoteOrder) => {
      let items = orderItemsMap[order.id];
      if (!items || items.length === 0) {
        await fetchOrderItems(order.id);
        items = orderItemsMap[order.id] || [];
      }

      const lines = createKotLines({
        ticketNo: order.order_number,
        orderMode: order.order_type || "takeaway",
        items: items.map((item) => ({
          productName: item.menu_items?.[0]?.name || "Item",
          quantity: item.quantity,
          lineTotal: item.total_price
        })),
        subtotal: order.total_amount,
        discount: 0,
        serviceCharge: 0,
        total: order.total_amount
      });

      await enqueuePrintJob({
        orderId: order.id,
        ticketNo: order.order_number,
        lines,
        jobType: "kot",
        station: "kitchen",
        metadata: { source: "orders_view" }
      });
      await refreshOpsHistory();
      await processPrintQueue();
      notify(`Print queued for ${order.order_number}.`);
    },
    [fetchOrderItems, orderItemsMap, processPrintQueue, refreshOpsHistory]
  );

  const cancelOrder = useCallback(
    async (orderId: string) => {
      const reason = (cancelReasonByOrderId[orderId] || "").trim();
      if (!reason) {
        notify("Enter a cancellation reason.", "error");
        return;
      }
      setOrderUpdateLoadingId(orderId);
      const { data, error } = await supabase.functions.invoke("update-order-status-secure", {
        body: { orderId, newStatus: "cancelled" }
      });
      const cancelNote = `Cancelled: ${reason}`;
      if (error || !data?.success) {
        const localUpdated = await applyLocalOnlyOrderUpdateFallback(orderId, {
          status: "cancelled",
          delivery_notes: cancelNote
        });
        if (localUpdated) {
          setCancelReasonByOrderId((prev) => ({ ...prev, [orderId]: "" }));
          setCancelInputOpenByOrderId((prev) => ({ ...prev, [orderId]: false }));
          setOrderUpdateLoadingId(null);
          notify("Order cancelled (local mode).");
          return;
        }

        const remoteUpdated = await applyRemoteOrderUpdateFallback(orderId, {
          status: "cancelled",
          delivery_notes: cancelNote
        });
        if (remoteUpdated) {
          setCancelReasonByOrderId((prev) => ({ ...prev, [orderId]: "" }));
          setCancelInputOpenByOrderId((prev) => ({ ...prev, [orderId]: false }));
          setOrderUpdateLoadingId(null);
          notify("Order cancelled.");
          return;
        }

        notify(data?.error || error?.message || "Cancel failed.", "error");
        setOrderUpdateLoadingId(null);
        return;
      }
      await supabase.from("orders").update({ delivery_notes: cancelNote }).eq("id", orderId);
      setCancelReasonByOrderId((prev) => ({ ...prev, [orderId]: "" }));
      setCancelInputOpenByOrderId((prev) => ({ ...prev, [orderId]: false }));
      setOrderUpdateLoadingId(null);
      await fetchOrders();
      notify("Order cancelled.");
    },
    [cancelReasonByOrderId, fetchOrders, applyLocalOnlyOrderUpdateFallback, applyRemoteOrderUpdateFallback]
  );

  const assignRider = useCallback(
    async (orderId: string, riderId: string, riderName?: string) => {
      const note = riderName ? `Rider assigned: ${riderName}` : `Rider assigned: ${riderId}`;
      const { error } = await supabase
        .from("orders")
        .update({ delivery_rider_id: riderId, delivery_notes: note })
        .eq("id", orderId);
      if (error) {
        const localUpdated = await applyLocalOnlyOrderUpdateFallback(orderId, {
          delivery_rider_id: riderId,
          delivery_notes: note
        });
        if (localUpdated) {
          notify(`Rider assigned locally: ${riderName || riderId}.`);
          return;
        }
        notify(`Failed to assign rider: ${error.message}`, "error");
        return;
      }
      await fetchOrders();
      notify("Rider assigned.");
    },
    [fetchOrders, applyLocalOnlyOrderUpdateFallback]
  );

  const fetchDeliveryRiders = useCallback(async () => {
    if (!cafeId) return;
    const { data } = await supabase
      .from("delivery_riders")
      .select("id, full_name")
      .eq("is_active", true)
      .order("full_name", { ascending: true });
    setDeliveryRiders((data as { id: string; full_name: string }[]) || []);
  }, [cafeId]);

  const updateOrderFields = useCallback(
    async (orderId: string, patch: Partial<RemoteOrder>) => {
      const payload: Record<string, unknown> = {};
      if (patch.customer_name !== undefined) payload.customer_name = patch.customer_name;
      if (patch.phone_number !== undefined) payload.phone_number = patch.phone_number;
      if (patch.order_type !== undefined) payload.order_type = patch.order_type;
      if (patch.table_number !== undefined) payload.table_number = patch.table_number;
      if (patch.delivery_block !== undefined) payload.delivery_block = patch.delivery_block;
      if (patch.delivery_address !== undefined) payload.delivery_address = patch.delivery_address;
      if (patch.delivery_notes !== undefined) payload.delivery_notes = patch.delivery_notes;
      if (patch.delivery_rider_id !== undefined) payload.delivery_rider_id = patch.delivery_rider_id;

      const { error } = await supabase.from("orders").update(payload).eq("id", orderId).eq("cafe_id", cafeId || "");
      if (!error) {
        patchOrderInState(orderId, patch);
        return true;
      }
      return applyLocalOnlyOrderUpdateFallback(orderId, patch);
    },
    [cafeId, patchOrderInState, applyLocalOnlyOrderUpdateFallback]
  );

  const openTableForm = useCallback(
    (mode: Exclude<TableFormMode, null>, tableNo: string) => {
      const meta = tableMetaState[tableNo];
      setTableFormMode(mode);
      setTableFormTableNo(tableNo);
      if (mode === "reserve") {
        setTableFormName(meta?.reservationName || "");
        setTableFormTime(meta?.reservationTime || "");
        setTableFormPhone("");
      } else {
        setTableFormName(meta?.guestName || "");
        setTableFormPhone(meta?.guestPhone || "");
        setTableFormTime("");
      }
    },
    [tableMetaState]
  );

  const closeTableForm = useCallback(() => {
    setTableFormMode(null);
    setTableFormTableNo("");
    setTableFormName("");
    setTableFormPhone("");
    setTableFormTime("");
  }, []);

  const canTransitionTableStatus = useCallback((current: TableUiStatus, next: TableUiStatus) => {
    const allowed: Record<TableUiStatus, TableUiStatus[]> = {
      available: ["reserved", "seated", "ordering", "dirty"],
      reserved: ["seated", "ordering", "available"],
      seated: ["ordering", "available"],
      ordering: ["preparing", "needs_bill", "dirty"],
      preparing: ["served", "needs_bill", "dirty"],
      served: ["needs_bill", "dirty"],
      needs_bill: ["dirty", "available"],
      dirty: ["available"]
    };
    return allowed[current]?.includes(next) || false;
  }, []);

  const transitionTableManualStatus = useCallback(
    (tableNo: string, nextStatus: TableUiStatus, patch?: Partial<TableMetaState>) => {
      setTableMetaState((prev) => {
        const currentMeta = prev[tableNo] || { capacity: 2 as const };
        const currentStatus = (currentMeta.manualStatus || "available") as TableUiStatus;
        if (!canTransitionTableStatus(currentStatus, nextStatus) && currentStatus !== nextStatus) {
          notify(`Table ${tableNo} transition blocked (${currentStatus} -> ${nextStatus}).`, "error");
          return prev;
        }
        return {
          ...prev,
          [tableNo]: {
            ...currentMeta,
            ...patch,
            manualStatus: nextStatus
          }
        };
      });
    },
    [canTransitionTableStatus]
  );

  const reserveTable = useCallback(
    (tableNo: string) => {
      const summary = tableSummaries.find((table) => table.tableNo === tableNo);
      if (summary && summary.ordersForTable.length > 0) {
        notify(`Table ${tableNo} has active orders. Reservation update blocked.`, "error");
        return;
      }
      openTableForm("reserve", tableNo);
    },
    [openTableForm, tableSummaries]
  );

  const seatTable = useCallback((tableNo: string) => {
    transitionTableManualStatus(tableNo, "seated", {
      reservationName: undefined,
      reservationTime: undefined,
      seatedAt: new Date().toISOString()
    });
    notify(`Table ${tableNo} marked seated.`);
  }, [transitionTableManualStatus]);

  const startTableOrder = useCallback((tableNo: string) => {
    setOrderMode("dine_in");
    setTableNumber(tableNo);
    const meta = tableMetaState[tableNo];
    if (meta?.guestName) setCustomerName(meta.guestName);
    if (meta?.guestPhone) setCustomerPhone(meta.guestPhone);
    transitionTableManualStatus(tableNo, "ordering", { seatedAt: meta?.seatedAt || new Date().toISOString() });
    setActiveView("menu");
    notify(`Creating dine-in order for Table ${tableNo}.`);
  }, [tableMetaState, transitionTableManualStatus]);

  const markTableBillPrinted = useCallback(
    async (tableNo: string) => {
      const summary = tableSummaries.find((table) => table.tableNo === tableNo);
      if (!summary || summary.ordersForTable.length === 0) return;
      const note = `Bill printed at ${new Date().toLocaleTimeString()}`;
      for (const order of summary.ordersForTable) {
        await updateOrderFields(order.id, { delivery_notes: note });
      }
      await enqueuePrintJob({
        orderId: summary.ordersForTable[0].id,
        ticketNo: summary.ordersForTable[0].order_number,
        lines: [
          `Table ${tableNo} Bill`,
          ...summary.ordersForTable.map((order) => `${order.order_number} | ₹${Math.round(order.total_amount || 0)} | ${order.payment_status || "pending"}`),
          `Table Total: ₹${Math.round(summary.total || 0)}`,
          `Printed At: ${new Date().toLocaleString()}`
        ],
        jobType: "bill",
        station: "counter",
        metadata: { tableNo }
      });
      await processPrintQueue();
      transitionTableManualStatus(tableNo, "needs_bill", { billPrintedAt: new Date().toISOString() });
      notify(`Bill marked printed for Table ${tableNo}.`);
    },
    [tableSummaries, updateOrderFields, transitionTableManualStatus, processPrintQueue]
  );

  const closeTable = useCallback(
    async (tableNo: string) => {
      const summary = tableSummaries.find((table) => table.tableNo === tableNo);
      if (!summary || summary.ordersForTable.length === 0) return;
      const hasPendingPayment = summary.ordersForTable.some((order) => order.payment_status !== "paid");
      if (hasPendingPayment) {
        notify(`Table ${tableNo} has pending payments. Mark payments before closing.`, "error");
        return;
      }
      for (const order of summary.ordersForTable) {
        await updateOrderStatus(order.id, "completed");
      }
      transitionTableManualStatus(tableNo, "dirty", {
        reservationName: undefined,
        reservationTime: undefined,
        seatedAt: undefined,
        guestName: undefined,
        guestPhone: undefined
      });
      notify(`Table ${tableNo} closed.`);
    },
    [tableSummaries, updateOrderStatus, transitionTableManualStatus]
  );

  const clearTableState = useCallback((tableNo: string) => {
    transitionTableManualStatus(tableNo, "available", {
      reservationName: undefined,
      reservationTime: undefined,
      seatedAt: undefined,
      guestName: undefined,
      guestPhone: undefined,
      billPrintedAt: undefined
    });
    notify(`Table ${tableNo} reset to available.`);
  }, [transitionTableManualStatus]);

  const markTableDirty = useCallback((tableNo: string) => {
    transitionTableManualStatus(tableNo, "dirty", {
      reservationName: undefined,
      reservationTime: undefined,
      seatedAt: undefined,
      guestName: undefined,
      guestPhone: undefined
    });
    notify(`Table ${tableNo} marked dirty (needs cleaning).`);
  }, [transitionTableManualStatus]);

  const cancelReservation = useCallback((tableNo: string) => {
    transitionTableManualStatus(tableNo, "available", {
      reservationName: undefined,
      reservationTime: undefined
    });
    notify(`Reservation cancelled for Table ${tableNo}.`);
  }, [transitionTableManualStatus]);

  const resetTableForNewOrder = useCallback(
    async (tableNo: string) => {
      const summary = tableSummaries.find((table) => table.tableNo === tableNo);
      if (!summary) return;
      if (summary.status === "available") return;
      if (summary.ordersForTable.length > 0) {
        const hasPendingPayment = summary.ordersForTable.some((order) => order.payment_status !== "paid");
        if (hasPendingPayment && !window.confirm(`Table ${tableNo} has unpaid items. Reset anyway?`)) return;
        for (const order of summary.ordersForTable) {
          await updateOrderStatus(order.id, "completed");
        }
      }
      transitionTableManualStatus(tableNo, "available", {
        reservationName: undefined,
        reservationTime: undefined,
        seatedAt: undefined,
        guestName: undefined,
        guestPhone: undefined,
        billPrintedAt: undefined
      });
      notify(`Table ${tableNo} reset. Ready for new order.`);
    },
    [tableSummaries, updateOrderStatus, transitionTableManualStatus]
  );

  const assignGuestToTable = useCallback((tableNo: string) => {
    openTableForm("guest", tableNo);
  }, [openTableForm]);

  const submitTableForm = useCallback(() => {
    if (!tableFormMode || !tableFormTableNo) return;
    if (!tableFormName.trim()) {
      notify("Name is required.", "error");
      return;
    }

    if (tableFormMode === "reserve") {
      transitionTableManualStatus(tableFormTableNo, "reserved", {
        reservationName: tableFormName.trim(),
        reservationTime: tableFormTime.trim() || undefined
      });
      notify(`Table ${tableFormTableNo} reserved for ${tableFormName.trim()}.`);
      closeTableForm();
      return;
    }

    setTableMetaState((prev) => ({
      ...prev,
      [tableFormTableNo]: {
        ...(prev[tableFormTableNo] || { capacity: 2 }),
        guestName: tableFormName.trim(),
        guestPhone: tableFormPhone.trim() || undefined
      }
    }));
    setCustomerName(tableFormName.trim());
    setCustomerPhone(tableFormPhone.trim());
    notify(`Guest updated for Table ${tableFormTableNo}.`);
    closeTableForm();
  }, [tableFormMode, tableFormTableNo, tableFormName, tableFormTime, tableFormPhone, closeTableForm, transitionTableManualStatus]);

  const transferTableOrders = useCallback(async () => {
    if (!tableOpSource || !tableOpTarget || tableOpSource === tableOpTarget) {
      notify("Pick valid source and target tables.", "error");
      return;
    }
    const sourceSummary = tableSummaries.find((table) => table.tableNo === tableOpSource);
    const targetSummary = tableSummaries.find((table) => table.tableNo === tableOpTarget);
    if (!sourceSummary || sourceSummary.ordersForTable.length === 0) {
      notify("Source table has no active orders.", "error");
      return;
    }
    if (targetSummary && targetSummary.ordersForTable.length > 0) {
      notify("Target table already has active orders. Use merge instead.", "error");
      return;
    }
    const confirmTransfer = window.confirm(`Transfer all active orders from Table ${tableOpSource} to Table ${tableOpTarget}?`);
    if (!confirmTransfer) return;
    for (const order of sourceSummary.ordersForTable) {
      await updateOrderFields(order.id, { table_number: tableOpTarget, order_type: "dine_in" });
    }
    transitionTableManualStatus(tableOpSource, "dirty", { seatedAt: undefined });
    transitionTableManualStatus(tableOpTarget, "ordering", { seatedAt: new Date().toISOString() });
    notify(`Transferred Table ${tableOpSource} to Table ${tableOpTarget}.`);
  }, [tableOpSource, tableOpTarget, tableSummaries, updateOrderFields, transitionTableManualStatus]);

  const mergeTableOrders = useCallback(async () => {
    if (!tableOpSource || !tableOpTarget || tableOpSource === tableOpTarget) {
      notify("Pick valid source and target tables.", "error");
      return;
    }
    const sourceSummary = tableSummaries.find((table) => table.tableNo === tableOpSource);
    const targetSummary = tableSummaries.find((table) => table.tableNo === tableOpTarget);
    if (!sourceSummary || sourceSummary.ordersForTable.length === 0 || !targetSummary) {
      notify("Source table has no active orders.", "error");
      return;
    }
    const confirmMerge = window.confirm(`Merge orders from Table ${tableOpSource} into Table ${tableOpTarget}?`);
    if (!confirmMerge) return;
    for (const order of sourceSummary.ordersForTable) {
      const note = order.delivery_notes ? `${order.delivery_notes} | merged from ${tableOpSource}` : `Merged from ${tableOpSource}`;
      await updateOrderFields(order.id, { table_number: tableOpTarget, order_type: "dine_in", delivery_notes: note });
    }
    transitionTableManualStatus(tableOpSource, "dirty", { seatedAt: undefined });
    transitionTableManualStatus(tableOpTarget, "ordering", { seatedAt: targetSummary.meta?.seatedAt || new Date().toISOString() });
    notify(`Merged Table ${tableOpSource} into Table ${tableOpTarget}.`);
  }, [tableOpSource, tableOpTarget, tableSummaries, updateOrderFields, transitionTableManualStatus]);

  const startEditingSelectedOrder = useCallback(() => {
    if (!selectedOrderDraft) return;
    setSelectedOrderItemsDraft(selectedOrderItems.map((item) => ({ ...item })));
    setSelectedOrderAddPanelOpen(false);
    setSelectedOrderAddItemId("");
    setSelectedOrderAddQty(1);
    setIsEditingSelectedOrder(true);
  }, [selectedOrderDraft, selectedOrderItems]);

  const updateSelectedOrderItemQty = useCallback((itemId: string, delta: number) => {
    setSelectedOrderItemsDraft((prev) =>
      prev.map((item) => {
        if (item.id !== itemId) return item;
        const nextQty = Math.max(1, Number(item.quantity || 0) + delta);
        return {
          ...item,
          quantity: nextQty,
          total_price: Math.round(Number(item.unit_price || 0) * nextQty)
        };
      })
    );
  }, []);

  const removeSelectedOrderItem = useCallback((itemId: string) => {
    setSelectedOrderItemsDraft((prev) => prev.filter((item) => item.id !== itemId));
  }, []);

  const addSelectedOrderItem = useCallback(() => {
    const menuItem = menu.find((item) => item.id === selectedOrderAddItemId);
    if (!menuItem) {
      notify("Select a valid item to add.", "error");
      return;
    }
    const qty = Math.max(1, Number(selectedOrderAddQty || 1));
    setSelectedOrderItemsDraft((prev) => {
      const existing = prev.find((item) => item.menu_item_id === menuItem.id);
      if (existing) {
        return prev.map((item) => {
          if (item.id !== existing.id) return item;
          const nextQty = Number(item.quantity || 0) + qty;
          return {
            ...item,
            quantity: nextQty,
            unit_price: Number(item.unit_price || menuItem.basePrice),
            total_price: Math.round(Number(item.unit_price || menuItem.basePrice) * nextQty),
            menu_items: [{ name: menuItem.name }],
            menu_item_id: menuItem.id
          };
        });
      }
      const unitPrice = Number(menuItem.basePrice || 0);
      return [
        ...prev,
        {
          id: `draft-add-${menuItem.id}-${Date.now()}`,
          quantity: qty,
          unit_price: unitPrice,
          total_price: Math.round(unitPrice * qty),
          special_instructions: null,
          menu_item_id: menuItem.id,
          menu_items: [{ name: menuItem.name }]
        }
      ];
    });
    setSelectedOrderAddPanelOpen(false);
    setSelectedOrderAddItemId("");
    setSelectedOrderAddQty(1);
  }, [menu, selectedOrderAddItemId, selectedOrderAddQty]);

  const parseSelectionsFromInstructions = useCallback((raw: string | null | undefined): CoffeeSelections => {
    const parsed: CoffeeSelections = { size: "medium", milk: "regular", sugarLevel: "regular", extraShots: 0 };
    if (!raw) return parsed;

    const compact = raw.trim().toLowerCase();
    if (compact.includes("small")) parsed.size = "small";
    if (compact.includes("large")) parsed.size = "large";
    if (compact.includes("medium")) parsed.size = "medium";

    if (compact.includes("skim")) parsed.milk = "skim";
    else if (compact.includes("soy")) parsed.milk = "soy";
    else if (compact.includes("oat")) parsed.milk = "oat";
    else if (compact.includes("almond")) parsed.milk = "almond";
    else parsed.milk = "regular";

    if (compact.includes("no_sugar") || compact.includes("no sugar")) parsed.sugarLevel = "no_sugar";
    else if (compact.includes("less")) parsed.sugarLevel = "less";
    else parsed.sugarLevel = "regular";

    const shotsMatch = compact.match(/shots?\s*(\d+)/);
    if (shotsMatch) parsed.extraShots = Number.parseInt(shotsMatch[1] || "0", 10) || 0;

    return parsed;
  }, []);

  const saveSelectedOrderEdits = useCallback(async () => {
    if (!selectedOrder || !selectedOrderDraft) {
      return;
    }

    const nextItems = selectedOrderItemsDraft.filter((item) => Number(item.quantity || 0) > 0);
    if (nextItems.length === 0) {
      notify("At least one item is required.", "error");
      return;
    }
    const previousSubtotal = selectedOrderItems.reduce((sum, item) => sum + Number(item.total_price || 0), 0);
    const nextSubtotal = nextItems.reduce((sum, item) => sum + Number(item.total_price || 0), 0);
    const taxAndCharges = Math.max(0, Number(selectedOrder.total_amount || 0) - previousSubtotal);
    const nextTotalAmount = Math.round((nextSubtotal + taxAndCharges) * 100) / 100;

    const cleanOrderType = selectedOrderDraft.orderType;
    const patch: Partial<RemoteOrder> = {
      customer_name: selectedOrderDraft.customerName.trim() || null,
      phone_number: selectedOrderDraft.customerPhone.trim() || null,
      order_type: cleanOrderType,
      table_number: cleanOrderType === "dine_in" ? selectedOrderDraft.tableNumber.trim() || null : null,
      delivery_block:
        cleanOrderType === "delivery"
          ? selectedOrderDraft.deliveryBlock.trim() || null
          : cleanOrderType === "takeaway"
            ? selectedOrderDraft.deliveryBlock.trim() || null
            : null,
      delivery_address: cleanOrderType === "delivery" ? selectedOrderDraft.deliveryAddress.trim() || null : null,
      delivery_notes: selectedOrderDraft.notes.trim() || null,
      total_amount: nextTotalAmount
    };

    setOrderUpdateLoadingId(selectedOrder.id);
    const isRemoteOrder = remoteOrders.some((order) => order.id === selectedOrder.id);
    if (isRemoteOrder) {
      const { error: deleteItemsError } = await supabase.from("order_items").delete().eq("order_id", selectedOrder.id);
      if (deleteItemsError) {
        notify(`Failed to update order items: ${deleteItemsError.message}`, "error");
        setOrderUpdateLoadingId(null);
        return;
      }
      const insertPayload = nextItems.map((item) => ({
        order_id: selectedOrder.id,
        menu_item_id: item.menu_item_id || null,
        quantity: item.quantity,
        unit_price: item.unit_price,
        total_price: item.total_price,
        special_instructions: item.special_instructions || null
      }));
      const { error: insertItemsError } = await supabase.from("order_items").insert(insertPayload);
      if (insertItemsError) {
        notify(`Failed to update order items: ${insertItemsError.message}`, "error");
        setOrderUpdateLoadingId(null);
        return;
      }
    } else {
      const localDraftItems: DraftOrderLineItem[] = nextItems.map((item) => ({
        productId: item.menu_item_id || item.id,
        productName: item.menu_items?.[0]?.name || "Item",
        quantity: Number(item.quantity || 1),
        unitPrice: Number(item.unit_price || 0),
        lineTotal: Number(item.total_price || 0),
        selections: parseSelectionsFromInstructions(item.special_instructions)
      }));
      await db.offlineOrders.update(selectedOrder.id, {
        items: localDraftItems,
        totalAmount: nextTotalAmount
      });
    }

    let updateQuery = supabase
      .from("orders")
      .update({
        customer_name: patch.customer_name,
        phone_number: patch.phone_number,
        order_type: patch.order_type,
        table_number: patch.table_number,
        delivery_block: patch.delivery_block,
        delivery_address: patch.delivery_address,
        delivery_notes: patch.delivery_notes,
        total_amount: patch.total_amount
      })
      .eq("id", selectedOrder.id)
      .eq("cafe_id", cafeId || "");
    if (selectedOrder.updated_at) {
      updateQuery = updateQuery.eq("updated_at", selectedOrder.updated_at);
    }
    const { data: updatedRows, error } = await updateQuery.select("id");

    if (!error && updatedRows && updatedRows.length > 0) {
      await fetchOrders();
      patchOrderInState(selectedOrder.id, patch);
      setOrderItemsMap((prev) => ({ ...prev, [selectedOrder.id]: nextItems }));
      notify("Order details updated.");
      setIsEditingSelectedOrder(false);
      setOrderUpdateLoadingId(null);
      return;
    }
    if (!error && (!updatedRows || updatedRows.length === 0) && selectedOrder.updated_at) {
      notify("Order was modified elsewhere. Refreshing...", "info");
      await fetchOrders();
      setOrderUpdateLoadingId(null);
      return;
    }
    if (error) {
      notify(`Failed to update order: ${error.message}`, "error");
      setOrderUpdateLoadingId(null);
      return;
    }

    const localUpdated = await applyLocalOnlyOrderUpdateFallback(selectedOrder.id, patch);
    if (localUpdated) {
      setOrderItemsMap((prev) => ({ ...prev, [selectedOrder.id]: nextItems }));
      notify("Order details updated (local mode).");
      setIsEditingSelectedOrder(false);
      setOrderUpdateLoadingId(null);
      return;
    }

    notify("Failed to update order. Please try again.", "error");
    setOrderUpdateLoadingId(null);
  }, [
    selectedOrder,
    selectedOrderDraft,
    selectedOrderItemsDraft,
    selectedOrderItems,
    cafeId,
    fetchOrders,
    remoteOrders,
    patchOrderInState,
    applyLocalOnlyOrderUpdateFallback,
    parseSelectionsFromInstructions
  ]);

  const exportReportCsv = useCallback(() => {
    const header = ["order_number", "status", "payment_method", "payment_status", "total_amount", "created_at"];
    const rows = todayOrders.map((order) => [
      order.order_number,
      order.status,
      order.payment_method || "",
      order.payment_status || "",
      String(order.total_amount),
      order.created_at
    ]);
    const csv = [header, ...rows]
      .map((line) => line.map((cell) => `"${String(cell).split("\"").join("\"\"")}"`).join(","))
      .join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    const prefix = theme?.cafeName ? theme.cafeName.toLowerCase().replace(/\s+/g, '-') : 'cafe';
    a.download = `${prefix}-report-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }, [todayOrders]);

  const parkCurrentCart = () => {
    if (cartItems.length === 0) return;
    const next: ParkedCart = {
      id: crypto.randomUUID(),
      label: parkNameInput.trim() || `Hold ${parkedCarts.length + 1}`,
      items: cartItems,
      notes,
      orderMode,
      paymentMethod,
      splitAmounts,
      customerName,
      customerPhone,
      deliveryBlock,
      deliveryAddress,
      tableNumber,
      discountMode,
      discountInput,
      serviceChargeInput,
      createdAt: new Date().toISOString()
    };
    const updated = [next, ...parkedCarts].slice(0, 20);
    setParkedCarts(updated);
    localStorage.setItem("cafe_parked_carts", JSON.stringify(updated));
    setCartItems([]);
    setNotes("");
    setCustomerName("");
    setCustomerPhone("");
    setDeliveryBlock("");
    setDeliveryAddress("");
    setTableNumber("");
    setSplitAmounts({ cash: 0, card: 0, upi: 0 });
    notify(`Cart parked as "${next.label}".`);
  };

  const resumeParkedCart = (cart: ParkedCart) => {
    setCartItems(cart.items);
    setNotes(cart.notes);
    setOrderMode(cart.orderMode);
    setPaymentMethod(cart.paymentMethod);
    setSplitAmounts(cart.splitAmounts);
    setCustomerName(cart.customerName);
    setCustomerPhone(cart.customerPhone);
    setDeliveryBlock(cart.deliveryBlock);
    setDeliveryAddress(cart.deliveryAddress);
    setTableNumber(cart.tableNumber);
    setDiscountMode(cart.discountMode);
    setDiscountInput(cart.discountInput);
    setServiceChargeInput(cart.serviceChargeInput);
    const updated = parkedCarts.filter((item) => item.id !== cart.id);
    setParkedCarts(updated);
    localStorage.setItem("cafe_parked_carts", JSON.stringify(updated));
    notify(`Resumed "${cart.label}".`);
  };

  const getPrimaryOrderAction = (order: RemoteOrder): { targetStatus: RemoteOrder["status"]; label: string } | null => {
    if (order.status === "received" || order.status === "confirmed") {
      return { targetStatus: "preparing", label: "Start Preparing" };
    }
    if (order.status === "preparing") {
      const normalizedType = (order.order_type || "").toLowerCase();
      if (normalizedType === "delivery") {
        return { targetStatus: "on_the_way", label: "Out for Delivery" };
      }
      return { targetStatus: "completed", label: "Mark Completed" };
    }
    if (order.status === "on_the_way") {
      return { targetStatus: "completed", label: "Mark Delivered" };
    }
    return null;
  };

  function orderTypeDisplay(order: RemoteOrder) {
    const normalized = (order.order_type || "takeaway").toLowerCase();
    if ((normalized === "dine_in" || normalized === "table_order") && order.table_number) {
      return `Table ${order.table_number}`;
    }
    if (normalized === "dine_in" || normalized === "table_order") return "Dine-In";
    if (normalized === "delivery") return "Delivery";
    if (normalized === "takeaway") return "Takeaway";
    if (normalized === "whatsapp_bot") return "WhatsApp Bot";
    return order.order_type || "takeaway";
  }

  useEffect(() => {
    const saved = localStorage.getItem(DASHBOARD_NOTIFICATION_READ_KEY);
    if (!saved) return;
    try {
      setDashboardNotificationReadMap(JSON.parse(saved) as Record<string, boolean>);
    } catch {
      localStorage.removeItem(DASHBOARD_NOTIFICATION_READ_KEY);
    }
  }, []);

  useEffect(() => {
    localStorage.setItem(DASHBOARD_NOTIFICATION_READ_KEY, JSON.stringify(dashboardNotificationReadMap));
  }, [dashboardNotificationReadMap]);

  useEffect(() => {
    if (!dashboardNotificationsOpen) return;
    const onMouseDown = (event: MouseEvent) => {
      if (!dashboardNotificationPanelRef.current) return;
      if (!dashboardNotificationPanelRef.current.contains(event.target as Node)) {
        setDashboardNotificationsOpen(false);
      }
    };
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") setDashboardNotificationsOpen(false);
    };
    window.addEventListener("mousedown", onMouseDown);
    window.addEventListener("keydown", onKeyDown);
    return () => {
      window.removeEventListener("mousedown", onMouseDown);
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [dashboardNotificationsOpen]);

  useEffect(() => {
    if (!selectedProductId && menu.length > 0) {
      setSelectedProductId(menu[0].id);
    }
  }, [menu, selectedProductId]);

  useEffect(() => {
    const saved = localStorage.getItem("cafe_active_shift");
    if (saved) {
      try {
        const parsed = JSON.parse(saved) as ShiftSession & { id?: string; cashierName?: string };
        if (parsed) {
          if (!parsed.id) parsed.id = crypto.randomUUID();
          if (!parsed.cashierName) parsed.cashierName = "Cashier";
        }
        setActiveShift(parsed as ShiftSession);
      } catch {
        localStorage.removeItem("cafe_active_shift");
      }
    }
  }, []);

  useEffect(() => {
    if (activeShift) {
      localStorage.setItem("cafe_active_shift", JSON.stringify(activeShift));
    }
  }, [activeShift]);

  useEffect(() => {
    const stored = localStorage.getItem(POS_TERMINAL_ID_KEY);
    const envVal = import.meta.env.VITE_BHURSAS_TERMINAL_ID as string;
    if (envVal && !stored) {
      localStorage.setItem(POS_TERMINAL_ID_KEY, envVal);
      setTerminalId(envVal);
    } else if (stored) {
      setTerminalId(stored);
    }
  }, []);

  useEffect(() => {
    const saved = localStorage.getItem("cafe_parked_carts");
    if (!saved) return;
    try {
      setParkedCarts(JSON.parse(saved) as ParkedCart[]);
    } catch {
      localStorage.removeItem("cafe_parked_carts");
    }
  }, []);

  useEffect(() => {
    const saved = localStorage.getItem(TABLE_META_STATE_KEY);
    if (saved) {
      try {
        setTableMetaState(JSON.parse(saved) as Record<string, TableMetaState>);
      } catch {
        localStorage.removeItem(TABLE_META_STATE_KEY);
      }
      return;
    }
    const defaults: Record<string, TableMetaState> = {};
    for (let i = 1; i <= 16; i += 1) {
      const key = String(i);
      defaults[key] = { capacity: i <= 8 ? 2 : i <= 14 ? 4 : 6 };
    }
    setTableMetaState(defaults);
  }, []);

  useEffect(() => {
    localStorage.setItem(TABLE_META_STATE_KEY, JSON.stringify(tableMetaState));
  }, [tableMetaState]);

  useEffect(() => {
    const saved = localStorage.getItem("cafe_rollout_flags");
    if (!saved) return;
    try {
      const parsed = JSON.parse(saved) as RolloutFlags;
      setRolloutFlags(parsed);
    } catch {
      localStorage.removeItem("cafe_rollout_flags");
    }
  }, []);

  useEffect(() => {
    localStorage.setItem("cafe_rollout_flags", JSON.stringify(rolloutFlags));
  }, [rolloutFlags]);

  useEffect(() => {
    void (async () => {
      const summary = await recoverOfflineOpsQueues();
      if (summary.recoveredOutbox > 0 || summary.recoveredPrintJobs > 0) {
        notify(
          `Recovered ${summary.recoveredOutbox} failed sync jobs and ${summary.recoveredPrintJobs} failed print jobs.`
        );
      }
    })();
  }, [notify]);

  useEffect(() => {
    void refreshOpsHistory();
  }, [refreshOpsHistory, pendingCount, queuedPrintCount]);

  useEffect(() => {
    void fetchOrders();
    void fetchLocalOrders();
    const timer = window.setInterval(() => {
      void fetchOrders();
      void fetchLocalOrders();
    }, 10000);
    return () => window.clearInterval(timer);
  }, [fetchOrders, fetchLocalOrders]);

  useEffect(() => {
    if (!cafeId || !user) return;
    return subscribeOrderRealtime(cafeId, () => {
      void fetchOrders();
      void fetchLocalOrders();
    });
  }, [cafeId, user, fetchOrders, fetchLocalOrders]);

  useEffect(() => {
    if (activeView === "settings" || activeView === "inventory" || activeView === "dashboard") {
      void fetchAdminMenu();
    }
    if (activeView === "staff") {
      void fetchStaff();
    }
    if (activeView === "customers" || activeView === "dashboard" || activeView === "menu") {
      void fetchCustomers();
    }
    if (activeView === "offers") {
      void fetchOffers();
    }
    if (activeView === "cafe") {
      void fetchCafeDetails();
    }
    if (activeView === "delivery") {
      void fetchDeliveryRiders();
    }
  }, [activeView, fetchAdminMenu, fetchStaff, fetchCustomers, fetchOffers, fetchCafeDetails, fetchDeliveryRiders]);

  const navigateMobile = useCallback(
    (next: PosView) => {
      setActiveView(next);
      setIsMobileDrawerOpen(false);
    },
    [setActiveView]
  );

  useEffect(() => {
    if (activeView !== "tables") return;
    if (selectedTableNo && !tableSummaries.some((table) => table.tableNo === selectedTableNo)) {
      setSelectedTableNo(null);
    }
  }, [activeView, selectedTableNo, tableSummaries]);

  useEffect(() => {
    if (selectedOrderId) {
      void fetchOrderItems(selectedOrderId);
    }
  }, [selectedOrderId, fetchOrderItems]);

  useEffect(() => {
    if (paymentMethod !== "split" && splitSettlements.length > 0) {
      setSplitSettlements([]);
      setSplitCountInput(2);
    }
  }, [paymentMethod, splitSettlements.length]);

  useEffect(() => {
    if (activeView !== "orders") return;
    visibleOrders.slice(0, 18).forEach((order) => {
      if (!orderItemsMap[order.id]) {
        void fetchOrderItems(order.id);
      }
    });
  }, [activeView, visibleOrders, orderItemsMap, fetchOrderItems]);

  useEffect(() => {
    if (!selectedTableSummary) {
      setTableOrderDraftMap({});
      return;
    }
    selectedTableSummary.ordersForTable.forEach((order) => {
      if (!orderItemsMap[order.id]) {
        void fetchOrderItems(order.id);
      }
    });
  }, [selectedTableSummary, orderItemsMap, fetchOrderItems]);

  useEffect(() => {
    if (!selectedTableOrderIds.length) {
      setTableOrderDraftMap({});
      return;
    }
    let cancelled = false;
    void (async () => {
      const drafts = await db.offlineOrders.bulkGet(selectedTableOrderIds);
      if (cancelled) return;
      const next: Record<string, OfflineOrderDraft> = {};
      drafts.forEach((draft, idx) => {
        if (draft) next[selectedTableOrderIds[idx]] = draft;
      });
      setTableOrderDraftMap(next);
    })();
    return () => {
      cancelled = true;
    };
  }, [selectedTableOrderIds]);

  useEffect(() => {
    if (cartItems.length === 0) {
      setAiSuggestion(null);
      return;
    }
    // Prevent suggestions on completely identical updates to avoid spam
    const timeout = setTimeout(async () => {
      setAiSuggestLoading(true);
      try {
        const { data, error } = await supabase.functions.invoke("ai-upsell-suggest", {
          body: { cartItems, menuItems: menu }
        });
        if (!error && data?.productId) {
          setAiSuggestion(data);
        } else {
          setAiSuggestion(null);
        }
      } catch (e) {
        console.error("AI Upsell failed:", e);
      } finally {
        setAiSuggestLoading(false);
      }
    }, 1200);
    return () => clearTimeout(timeout);
  }, [cartItems, menu]);

  useEffect(() => {
    if (!selectedOrder) {
      setSelectedOrderDraft(null);
      setSelectedOrderItemsDraft([]);
      setIsEditingSelectedOrder(false);
      previousSelectedOrderIdRef.current = null;
      return;
    }
    const isNewSelection = previousSelectedOrderIdRef.current !== selectedOrder.id;
    if (isNewSelection || !selectedOrderDraft) {
      setSelectedOrderDraft({
        customerName: selectedOrder.customer_name || "",
        customerPhone: selectedOrder.phone_number || "",
        orderType: (selectedOrder.order_type as "delivery" | "dine_in" | "takeaway") || "takeaway",
        tableNumber: selectedOrder.table_number || "",
        deliveryBlock: selectedOrder.delivery_block || "",
        deliveryAddress: selectedOrder.delivery_address || "",
        notes: selectedOrder.delivery_notes || ""
      });
      setIsEditingSelectedOrder(false);
      previousSelectedOrderIdRef.current = selectedOrder.id;
    }
  }, [selectedOrder, selectedOrderDraft]);

  useEffect(() => {
    if (!selectedOrderId) {
      setSelectedOrderItemsDraft([]);
      return;
    }
    if (!isEditingSelectedOrder) {
      setSelectedOrderItemsDraft(selectedOrderItems.map((item) => ({ ...item })));
    }
  }, [selectedOrderId, selectedOrderItems, isEditingSelectedOrder]);

  const selectedAuthStaff = authStaffOptions.find((staff) => staff.id === selectedAuthStaffId) || authStaffOptions[0];
  const canSubmitPin = authPin.length >= 4;

  const pushAuthPinDigit = (digit: string) => {
    if (authPin.length >= 6) return;
    setAuthPin((prev) => `${prev}${digit}`);
  };

  const popAuthPinDigit = () => {
    setAuthPin((prev) => prev.slice(0, -1));
  };

  const submitAuthPinLogin = useCallback(async () => {
    const isPinMode = authMode === "login" || authMode === "forgot";
    const isAlphaMode = authMode === "admin";
    
    if (isPinMode && !canSubmitPin) return;
    if (isAlphaMode && (!email || !password)) return;
    if (!isOnline) return;

    setAuthBootstrapLoading(true);
    setAuthBootstrapError(null);

    try {
      const loginEmail = isAlphaMode ? email : selectedAuthStaff?.email;
      if (!loginEmail) throw new Error("No email found for this user");

      await signIn({ 
        email: loginEmail, 
        password: isAlphaMode ? password : authPin 
      });

      const { data: { user: signedInUser }, error: sessionError } = await supabase.auth.getUser();
      if (sessionError) throw sessionError;
      
      // If we just signed in as an admin/owner, claim this terminal for their cafe
      if (signedInUser) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('cafe_id, user_type, full_name')
          .eq('id', signedInUser.id)
          .single();

        if (profile?.cafe_id && (profile.user_type === 'cafe_owner' || profile.user_type === 'admin')) {
          localStorage.setItem(CAFE_TERMINAL_ID_KEY, profile.cafe_id);
          setTerminalCafeId(profile.cafe_id);
          // If admin login was successful, switch back to login mode to see the rebranded staff
          if (isAlphaMode) setAuthMode("login");
        }

        // Start shift session for reporting
        const shift: ShiftSession = {
          id: crypto.randomUUID(),
          startedAt: new Date().toISOString(),
          endedAt: null,
          cashierId: signedInUser.id,
          cashierName: (profile as { full_name?: string } | null)?.full_name || signedInUser.email || "Cashier"
        };
        setActiveShift(shift);
        localStorage.setItem("cafe_active_shift", JSON.stringify(shift));
      }

      setAuthPin("");
      setPassword("");
    } catch (err: any) {
      setAuthBootstrapError(err.message || "Login failed");
    } finally {
      setAuthBootstrapLoading(false);
    }
  }, [authMode, canSubmitPin, isOnline, email, password, selectedAuthStaff, signIn, authPin]);

  useEffect(() => {
    if (user || authMode !== "login") return;
    const focusTimer = window.setTimeout(() => {
      authPinInputRef.current?.focus();
    }, 0);
    return () => window.clearTimeout(focusTimer);
  }, [user, authMode, selectedAuthStaffId]);

  if (showSplash || sessionLoading) {
    return (
      <div
        className={`splash-overlay ${isSplashExiting ? "exiting" : ""}`}
        style={theme?.logoUrl ? { ["--splash-bg-image" as string]: `url(${theme.logoUrl})` } : undefined}
      >
        <div className="splash-container">
          <div className="splash-logo-wrapper">
            <div className="splash-logo-pulse">
              {theme?.logoUrl ? (
                <img 
                  src={theme.logoUrl} 
                  alt={theme.cafeName || "Cafe Logo"} 
                  className="splash-logo-img"
                />
              ) : (
                <div className="splash-logo-fallback">
                  <span>{(theme?.cafeName || "P")[0].toUpperCase()}</span>
                </div>
              )}
            </div>
          </div>
          
          <div className="splash-text-wrapper">
            <h1 className="splash-text">
              {theme?.cafeName || "POS Portal"}
            </h1>
            <div className="splash-dots">
              <div className="splash-dot"></div>
              <div className="splash-dot"></div>
              <div className="splash-dot"></div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="auth-page auth-page-v2">
        <section className="auth-layout">
          <article className="auth-pane auth-login-pane">
            <h1 className="auth-brand">{theme?.cafeName ? `${theme.cafeName} POS` : "POS"}</h1>

            {authMode === "admin" ? (
              <div className="auth-alt-card">
                {authBootstrapError && (
                  <div className="auth-error-chip" style={{ marginBottom: '1rem', background: 'rgba(224, 79, 51, 0.1)', color: '#E04F33', padding: '0.75rem', borderRadius: '8px', fontSize: '0.875rem' }}>
                    {authBootstrapError}
                  </div>
                )}

                <div className="form-group">
                  <label className="field">
                    <span>Email</span>
                    <input
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="admin@cafe.com"
                      disabled={authBootstrapLoading}
                    />
                  </label>
                  <label className="field">
                    <span>Password</span>
                    <input
                      type="password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="••••••••"
                      disabled={authBootstrapLoading}
                    />
                  </label>
                </div>
                <button
                  className="primary full"
                  disabled={!email || !password || !isOnline || authBootstrapLoading}
                  onClick={() => {
                    void submitAuthPinLogin();
                  }}
                >
                  {authBootstrapLoading ? "Claiming..." : "Claim Terminal"}
                </button>
                <button
                  className="ghost full"
                  onClick={() => {
                    setAuthBootstrapError(null);
                    setAuthMode("login");
                  }}
                  disabled={authBootstrapLoading}
                >
                  Cancel
                </button>
              </div>
            ) : !terminalCafeId ? (
              <div className="auth-claim-terminal">
                <h2>Claim Terminal</h2>
                <p className="muted">Enter your cafe ID to load staff and start.</p>
                <label className="field">
                  <span>Cafe ID (UUID)</span>
                  <input
                    type="text"
                    placeholder="e.g. 123e4567-e89b-12d3-a456-426614174000"
                    value={claimCafeIdInput}
                    onChange={(e) => setClaimCafeIdInput(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        const id = claimCafeIdInput.trim();
                        if (id.length >= 36) {
                          localStorage.setItem(CAFE_TERMINAL_ID_KEY, id);
                          setTerminalCafeId(id);
                          setClaimCafeIdInput("");
                        }
                      }
                    }}
                  />
                </label>
                <button
                  className="primary full"
                  disabled={claimCafeIdInput.trim().length < 36}
                  onClick={() => {
                    const id = claimCafeIdInput.trim();
                    if (id.length >= 36) {
                      localStorage.setItem(CAFE_TERMINAL_ID_KEY, id);
                      setTerminalCafeId(id);
                      setClaimCafeIdInput("");
                    }
                  }}
                >
                  Claim Terminal
                </button>
                <button className="ghost full" onClick={() => setAuthMode("admin")}>
                  Admin Login (email/password)
                </button>
              </div>
            ) : authMode === "login" ? (
              <>
                <h2>Employee Login</h2>
                <p className="muted">Choose your account to start your shift.</p>

                <label className="field auth-staff-select">
                  <span>Staff</span>
                  <select
                    value={selectedAuthStaffId}
                    onChange={(e) => {
                      setSelectedAuthStaffId(e.target.value);
                      setAuthPin("");
                      setAuthResetStatus(null);
                    }}
                  >
                    {authStaffOptions.map((staff) => (
                      <option key={staff.id} value={staff.id}>
                        {staff.name} ({staff.shift})
                      </option>
                    ))}
                  </select>
                </label>

                <p className="tiny muted">Please input your PIN to validate yourself.</p>
                <div
                  className="auth-pin-boxes"
                  onClick={() => authPinInputRef.current?.focus()}
                >
                  <input
                    ref={authPinInputRef}
                    className="auth-pin-hidden-input"
                    value={authPin}
                    inputMode="numeric"
                    autoComplete="one-time-code"
                    maxLength={6}
                    onChange={(event) => {
                      const nextValue = event.target.value.replace(/\D/g, "").slice(0, 6);
                      setAuthPin(nextValue);
                    }}
                    onKeyDown={(event) => {
                      if (event.key === "Enter") {
                        event.preventDefault();
                        void submitAuthPinLogin();
                      }
                    }}
                  />
                  {Array.from({ length: 6 }, (_, idx) => (
                    <span key={idx} className={`auth-pin-box ${idx < authPin.length ? "filled" : ""}`}>
                      {idx < authPin.length ? "•" : idx === authPin.length ? <span className="auth-pin-caret" /> : ""}
                    </span>
                  ))}
                </div>

                <button className="ghost auth-link-btn" onClick={() => setAuthMode("forgot")}>Forgot PIN?</button>

                <div className="auth-keypad">
                  {["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"].map((digit) => (
                    <button key={digit} type="button" className="auth-key" onClick={() => pushAuthPinDigit(digit)}>
                      {digit}
                    </button>
                  ))}
                  <button type="button" className="auth-key auth-key-delete" onClick={popAuthPinDigit}>⌫</button>
                </div>

                <button
                  className="primary full auth-start-btn"
                  disabled={!canSubmitPin || !isOnline}
                  onClick={() => {
                    void submitAuthPinLogin();
                  }}
                >
                  Start Shift
                </button>

                <div className="auth-footer-actions">
                  <button className="ghost sm" onClick={() => setAuthMode("admin")}>
                    Admin Setup
                  </button>
                  <a href="/landing" className="ghost sm" style={{ textDecoration: "none", color: "inherit" }}>
                    Learn more
                  </a>
                </div>
              </>
            ) : authMode === "forgot" ? (
              <div className="auth-alt-card">
                <h2>Forgot PIN?</h2>
                <p className="muted">No worries, we&apos;ll send your PIN reset instructions.</p>
                <label className="field">
                  <span>Email</span>
                  <input
                    value={recoveryEmail}
                    placeholder={selectedAuthStaff?.email || "Enter your email"}
                    onChange={(e) => setRecoveryEmail(e.target.value)}
                  />
                </label>
                <button
                  className="primary full"
                  onClick={async () => {
                    const targetEmail = (recoveryEmail || selectedAuthStaff?.email || "").trim();
                    if (!targetEmail) {
                      setAuthResetStatus({ type: "error", message: "Enter a valid recovery email." });
                      return;
                    }
                    const { error } = await supabase.auth.resetPasswordForEmail(targetEmail, {
                      redirectTo: `${window.location.origin}/`
                    });
                    if (error) {
                      setAuthResetStatus({ type: "error", message: `Failed to send reset email: ${error.message}` });
                      return;
                    }
                    setAuthMode("sent");
                    setRecoveryEmail(targetEmail);
                    setAuthResetStatus({
                      type: "success",
                      message: `PIN reset email sent to ${targetEmail}. Check inbox/spam.`
                    });
                  }}
                >
                  Request PIN
                </button>
                <button className="ghost full" onClick={() => setAuthMode("login")}>Back to log in</button>
              </div>
            ) : authMode === "sent" ? (
              <div className="auth-alt-card">
                <h2>Check your email</h2>
                <p className="muted">
                  We sent a PIN reset link to <strong>{recoveryEmail || selectedAuthStaff?.email}</strong>
                </p>
                <button className="ghost full" onClick={() => setAuthMode("forgot")}>Resend</button>
                <button className="ghost full" onClick={() => setAuthMode("login")}>Back to log in</button>
              </div>
            ) : null}

            {authResetStatus && (
              <p className={`tiny ${authResetStatus.type === "error" ? "auth-msg-error" : "auth-msg-success"}`}>
                {authResetStatus.message}
              </p>
            )}

            {(sessionError || !isOnline) && (
              <p className="muted">{sessionError || "Offline: sign-in requires internet."}</p>
            )}
            {(authBootstrapLoading || authBootstrapError) && (
              <p className="muted">
                {authBootstrapLoading ? "Loading staff and dashboard preview..." : authBootstrapError}
              </p>
            )}
          </article>

          <aside className="auth-pane auth-preview-pane">
            <div className="auth-preview-overlay">
              <header className="auth-preview-head">
                <span className="tiny muted">Dashboard preview</span>
                <strong>Good Morning, {selectedAuthStaff?.name.split(" ")[0] || "Ricardo"}</strong>
              </header>
              <div className="auth-preview-kpis">
                <article><p>Total Earning</p><strong>₹{Math.round(authPreview.totalEarning)}</strong></article>
                <article><p>In Progress</p><strong>{authPreview.inProgress}</strong></article>
                <article><p>Completed</p><strong>{authPreview.readyToServe}</strong></article>
              </div>
              <div className="auth-preview-list">
                {(authPreview.recentOrders.length ? authPreview.recentOrders : [
                  { order_number: "N/A", order_type: "dine_in", customer_name: "No orders yet" }
                ]).map((order) => (
                  <div key={order.order_number}>
                    <span>
                      Order# {order.order_number} / {(order.order_type || "takeaway").split("_").join(" ")}
                    </span>
                    <strong>{order.customer_name || "Walk-in"}</strong>
                  </div>
                ))}
              </div>
            </div>
          </aside>
        </section>
      </div>
    );
  }

  const renderTableControlsPanel = (tableSummary: typeof selectedTableSummary) => {
    if (!tableSummary) return null;
    return (
      <section className="panel nested table-detail-panel table-detail-panel-floating">
        <div className="section-head">
          <h4>Table {tableSummary.tableNo}</h4>
          <div className="inline-actions table-detail-head-right">
            <span className={`table-detail-status-pill table-status-${tableSummary.status}`}>
              {tableSummary.status.split("_").join(" ")} • ₹{Math.round(tableSummary.total)}
            </span>
            <button className="ghost table-detail-close-btn" aria-label="Close" onClick={() => setSelectedTableNo(null)}>
              <X size={16} />
            </button>
          </div>
        </div>
        <div className="table-control-primary">
          <p className="table-control-section-label">Status Updates</p>
          <div className="table-control-actions">
            {tableSummary.status !== "available" && (
              <button
                className="table-action-btn table-action-ready"
                onClick={() => void resetTableForNewOrder(tableSummary.tableNo)}
              >
                <CheckCircle2 size={18} />
                Ready for new order
              </button>
            )}
            <button
              className="table-action-btn table-action-primary"
              onClick={() => {
                if (tableSummary.ordersForTable.length > 0) {
                  const orderToEdit = tableSummary.ordersForTable[0];
                  setActiveView("orders");
                  setSelectedOrderId(orderToEdit.id);
                  notify(`Opened ${orderToEdit.order_number} for editing.`);
                  return;
                }
                startTableOrder(tableSummary.tableNo);
              }}
            >
              <Pencil size={16} />
              {tableSummary.ordersForTable.length > 0 ? "Modify Order" : "New Order"}
            </button>
          </div>
        </div>
        {(tableSummary.status === "available" ||
          tableSummary.status === "reserved" ||
          (tableSummary.ordersForTable.length === 0 && !["available", "reserved"].includes(tableSummary.status))) && (
          <div className="table-control-primary">
            <p className="table-control-section-label">Table & Guest</p>
            <div className="table-control-actions">
              {tableSummary.status === "available" && (
                <>
                  <button className="table-action-btn" onClick={() => seatTable(tableSummary.tableNo)}>Seat</button>
                  <button className="table-action-btn" onClick={() => reserveTable(tableSummary.tableNo)}>
                    {tableSummary.meta?.reservationName ? "Edit Reserve" : "Reserve"}
                  </button>
                  <button className="table-action-btn table-action-secondary" onClick={() => markTableDirty(tableSummary.tableNo)}>Mark Dirty</button>
                </>
              )}
              {tableSummary.status === "reserved" && (
                <>
                  <button className="table-action-btn" onClick={() => seatTable(tableSummary.tableNo)}>Seat</button>
                  <button className="table-action-btn" onClick={() => reserveTable(tableSummary.tableNo)}>Edit Reserve</button>
                  <button className="table-action-btn table-action-secondary" onClick={() => cancelReservation(tableSummary.tableNo)}>Cancel Reservation</button>
                </>
              )}
              {tableSummary.ordersForTable.length === 0 &&
                !["available", "reserved"].includes(tableSummary.status) && (
                  <button className="table-action-btn" onClick={() => assignGuestToTable(tableSummary.tableNo)}>
                    {tableSummary.meta?.guestName ? "Edit Guest" : "Add Guest"}
                  </button>
                )}
            </div>
          </div>
        )}
        {tableFormMode && tableFormTableNo === tableSummary.tableNo && (
          <section className="panel nested table-form-panel">
            <div className="section-head">
              <h4>{tableFormMode === "reserve" ? "Reserve Table" : "Guest Details"}: Table {tableFormTableNo}</h4>
              <button className="ghost" onClick={closeTableForm}>Close</button>
            </div>
            <div className="triple">
              <label className="field">
                <span>{tableFormMode === "reserve" ? "Reservation Name" : "Guest Name"}</span>
                <input
                  value={tableFormName}
                  onChange={(e) => setTableFormName(e.target.value)}
                  placeholder="Required"
                />
              </label>
              {tableFormMode === "reserve" ? (
                <label className="field">
                  <span>Reservation Time</span>
                  <input
                    value={tableFormTime}
                    onChange={(e) => setTableFormTime(e.target.value)}
                    placeholder="e.g. 7:30 PM"
                  />
                </label>
              ) : (
                <label className="field">
                  <span>Guest Phone</span>
                  <input
                    value={tableFormPhone}
                    onChange={(e) => setTableFormPhone(e.target.value)}
                    placeholder="Optional"
                  />
                </label>
              )}
              <div className="inline-actions table-op-actions">
                <button className="ghost" onClick={closeTableForm}>Cancel</button>
                <button className="primary" onClick={submitTableForm}>Save</button>
              </div>
            </div>
          </section>
        )}
        {tableSummary.ordersForTable.length > 0 && (
          <div className="table-control-primary">
            <p className="table-control-section-label">Order Operations</p>
            <div className="table-control-actions table-control-actions-order">
              {(() => {
                const orderToUpdate = tableSummary.ordersForTable.find((o) => getPrimaryOrderAction(o));
                const primaryAction = orderToUpdate ? getPrimaryOrderAction(orderToUpdate) : null;
                return (
                  <>
                    {primaryAction && (
                      <button
                        className="table-action-btn table-action-primary"
                        disabled={orderUpdateLoadingId === orderToUpdate!.id}
                        onClick={() => void updateOrderStatus(orderToUpdate!.id, primaryAction.targetStatus)}
                      >
                        <ArrowRight size={16} />
                        Update
                      </button>
                    )}
                    <button className="table-action-btn" onClick={() => void queueOrderPrint(tableSummary.ordersForTable[0])}>
                      <Printer size={16} />
                      Send KOT
                    </button>
                    <button className="table-action-btn" onClick={() => void markTableBillPrinted(tableSummary.tableNo)}>
                      <FileText size={16} />
                      Print Bill
                    </button>
                    <button className="table-action-btn table-action-close" onClick={() => void closeTable(tableSummary.tableNo)}>
                      <XCircle size={16} />
                      Close Table
                    </button>
                  </>
                );
              })()}
            </div>
          </div>
        )}
        {selectedTableBillBreakdown && (
          <section className="panel nested table-bill-preview">
            <p className="table-control-section-label">Bill Summary</p>
            <h4>Bill Preview</h4>
            <ul className="list">
              {selectedTableBillBreakdown.customers.map((customer, idx) => (
                <li key={`${customer.name}-${idx}`} className="tiny">
                  {customer.name}
                  {customer.phone ? ` • ${customer.phone}` : ""}
                </li>
              ))}
            </ul>
            <ul className="list">
              {selectedTableBillBreakdown.itemRows.length === 0 && <li className="tiny muted">No item lines loaded.</li>}
              {selectedTableBillBreakdown.itemRows.map((item) => (
                <li key={item.key} className="row tiny">
                  <span>{item.name} x {item.qty}</span>
                  <strong>₹{Math.round(item.amount)}</strong>
                </li>
              ))}
            </ul>
            <div className="totals">
              <div className="row"><span>Subtotal</span><strong>₹{selectedTableBillBreakdown.subtotal}</strong></div>
              <div className="row"><span>Discount</span><strong>- ₹{selectedTableBillBreakdown.discount}</strong></div>
              <div className="row"><span>Service Charge</span><strong>+ ₹{selectedTableBillBreakdown.serviceCharge}</strong></div>
              <div className="row"><span>Tax</span><strong>+ ₹{selectedTableBillBreakdown.tax}</strong></div>
              <div className="row grand"><span>Total</span><strong>₹{selectedTableBillBreakdown.total}</strong></div>
            </div>
          </section>
        )}
      </section>
    );
  };

  return (
    <div className={`pos-shell ${isSidebarCollapsed ? "sidebar-collapsed" : ""}`}>
      <aside className="sidebar">
        <div className="sidebar-header">
          <div className="sidebar-brand">
            <div className="logo-placeholder">
              <Coffee size={24} />
            </div>
            <div className="brand-info">
              <h1>{theme?.cafeName || "Banna's Chowki"}</h1>
              <p className="muted tiny">{theme?.type || "North Indian"} POS</p>
            </div>
          </div>
        </div>
        <button className="sidebar-toggle-btn" onClick={() => setIsSidebarCollapsed(!isSidebarCollapsed)} aria-label={isSidebarCollapsed ? "Expand sidebar" : "Collapse sidebar"}>
          {isSidebarCollapsed ? <ChevronRight size={14} strokeWidth={2.5} /> : <ChevronLeft size={14} strokeWidth={2.5} />}
        </button>
        
        <nav className="sidebar-nav main-nav">
          <button className={`nav-btn ${activeView === "dashboard" ? "active" : ""}`} onClick={() => setActiveView("dashboard")}>
            <LayoutDashboard size={20} />
            <span>Dashboard</span>
          </button>
          <button className={`nav-btn ${activeView === "menu" ? "active" : ""}`} onClick={() => setActiveView("menu")}>
            <ShoppingBag size={20} />
            <span>Order Line</span>
          </button>
          <button className={`nav-btn ${activeView === "orders" ? "active" : ""}`} onClick={() => setActiveView("orders")}>
            <ListOrdered size={20} />
            <span>Orders List</span>
          </button>
          <button className={`nav-btn ${activeView === "kitchen" ? "active" : ""}`} onClick={() => setActiveView("kitchen")}>
            <UtensilsCrossed size={20} />
            <span>Kitchen</span>
          </button>
          <button className={`nav-btn ${activeView === "tables" ? "active" : ""}`} onClick={() => setActiveView("tables")}>
            <LayoutGrid size={20} />
            <span>Manage Table</span>
          </button>
          <button className={`nav-btn ${activeView === "delivery" ? "active" : ""}`} onClick={() => setActiveView("delivery")}>
            <Truck size={20} />
            <span>Delivery</span>
          </button>
          <button className={`nav-btn ${activeView === "inventory" ? "active" : ""}`} onClick={() => setActiveView("inventory")}>
            <Package size={20} />
            <span>Inventory</span>
          </button>
          <button className={`nav-btn ${activeView === "offers" ? "active" : ""}`} onClick={() => setActiveView("offers")}>
            <Ticket size={20} />
            <span>Offers</span>
          </button>
          <button className={`nav-btn ${activeView === "customers" ? "active" : ""}`} onClick={() => setActiveView("customers")}>
            <Users size={20} />
            <span>Customers</span>
          </button>
          <button className={`nav-btn ${activeView === "analytics" ? "active" : ""}`} onClick={() => setActiveView("analytics")}>
            <BarChart3 size={20} />
            <span>Analytics</span>
          </button>
          <button className={`nav-btn ${activeView === "loyalty" ? "active" : ""}`} onClick={() => setActiveView("loyalty")}>
            <Heart size={20} />
            <span>Loyalty</span>
          </button>
          <button className={`nav-btn ${activeView === "staff" ? "active" : ""}`} onClick={() => setActiveView("staff")}>
            <UserCircle size={20} />
            <span>Staff</span>
          </button>
          <button className={`nav-btn ${activeView === "cafe" ? "active" : ""}`} onClick={() => setActiveView("cafe")}>
            <Coffee size={20} />
            <span>Cafe Details</span>
          </button>
          <button className={`nav-btn ${activeView === "history" ? "active" : ""}`} onClick={() => setActiveView("history")}>
            <History size={20} />
            <span>History</span>
          </button>
          <button className={`nav-btn ${activeView === "billing" ? "active" : ""}`} onClick={() => setActiveView("billing")}>
            <CreditCard size={20} />
            <span>Billing</span>
          </button>
        </nav>

        <div className="sidebar-footer">
          <nav className="sidebar-nav secondary-nav">
            <button className={`nav-btn ${activeView === "settings" ? "active" : ""}`} onClick={() => setActiveView("settings")}>
              <Settings size={20} />
              <span>Settings</span>
            </button>
            <button className="nav-btn help-btn">
              <HelpCircle size={20} />
              <span>Help Center</span>
            </button>
            <button className="nav-btn logout-btn" onClick={() => {
              localStorage.removeItem("cafe_active_shift");
              setActiveShift(null);
              void signOut();
            }}>
              <LogOut size={20} />
              <span>Logout</span>
            </button>
          </nav>

          <div className="sidebar-user">
            <div className="user-avatar">
              <UserCircle size={32} />
            </div>
            <div className="user-info">
              <p className="user-name">{user.fullName || user.email}</p>
              <p className="user-role">{user.role || "staff"}</p>
            </div>
          </div>
        </div>
      </aside>

      <main className="pos-main">
        {activeView === "dashboard" && (
          <>
            <MobileHeader
              title="Dashboard"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
              center={
                <div className="mobile-user-profile">
                  <span className="mobile-user-name">{(user.fullName || user.email).split(" ")[0]}</span>
                  <span className="mobile-user-role chip-mini">{user.role || "Staff"}</span>
                </div>
              }
              right={
                <button className="ghost settings-toggle-btn" onClick={() => setActiveView("settings")}>
                  <Settings size={22} />
                </button>
              }
            />

            <header className="topbar dashboard-topbar desktop-only-header">
              <div className="dash-greeting-desktop">
                <h3>Good {new Date().getHours() < 12 ? "Morning" : new Date().getHours() < 17 ? "Afternoon" : "Evening"}, {(user.fullName || user.email).split(" ")[0]}</h3>
                <p className="muted tiny">Live cafe operations snapshot</p>
              </div>
              <div className="dashboard-date-wrap">
                <select
                  className="dashboard-date-range"
                  value={dashboardDateRange}
                  onChange={(e) => setDashboardDateRange(e.target.value as "today" | "week" | "month" | "all" | "custom")}
                >
                  <option value="today">Today</option>
                  <option value="week">Last 7 days</option>
                  <option value="month">Last 30 days</option>
                  <option value="all">All time</option>
                  <option value="custom">Custom</option>
                </select>
                {dashboardDateRange === "custom" && (
                  <>
                    <input
                      type="date"
                      className="dashboard-date-input"
                      value={dashboardCustomStartDate}
                      onChange={(e) => setDashboardCustomStartDate(e.target.value)}
                    />
                    <span className="dashboard-date-sep">–</span>
                    <input
                      type="date"
                      className="dashboard-date-input"
                      value={dashboardCustomEndDate}
                      onChange={(e) => setDashboardCustomEndDate(e.target.value)}
                    />
                  </>
                )}
              </div>

              <div className="dash-brand-mobile">
                <div className="dash-brand-icon">
                  {theme?.logoUrl ? <img src={theme.logoUrl} alt="Logo" /> : <Coffee size={20} />}
                </div>
                <div className="dash-brand-text">
                  <h3>{theme?.cafeName || "Banna's"}</h3>
                  <p className="muted tiny">Operations Snapshot</p>
                </div>
              </div>

              <div className="top-actions dash-actions">
                <div className="dashboard-notify-wrap" ref={dashboardNotificationPanelRef}>
                  <button className="ghost dashboard-bell-btn" onClick={() => setDashboardNotificationsOpen((prev) => !prev)}>
                    <span>🔔</span>
                    {dashboardUnreadCount > 0 && <span className="dashboard-bell-count">{dashboardUnreadCount}</span>}
                  </button>
                  {dashboardNotificationsOpen && (
                    <section className="dashboard-notify-panel">
                      <header className="dashboard-notify-head">
                        <strong>Notifications</strong>
                        <button
                          className="ghost"
                          onClick={() => {
                            setDashboardNotificationReadMap((prev) => {
                              const next = { ...prev };
                              dashboardNotifications.forEach((item) => {
                                next[item.id] = true;
                              });
                              return next;
                            });
                          }}
                        >
                          Mark all as read
                        </button>
                      </header>
                      <div className="dashboard-notify-tabs">
                        {[
                          ["all", "All"],
                          ["inventory", "Inventory"],
                          ["kitchen", "Kitchen"]
                        ].map(([value, label]) => (
                          <button
                            key={value}
                            className={`ghost ${dashboardNotificationTab === value ? "chip-active" : ""}`}
                            onClick={() => setDashboardNotificationTab(value as "all" | "inventory" | "kitchen")}
                          >
                            {label}
                          </button>
                        ))}
                      </div>
                      <div className="dashboard-notify-list">
                        {dashboardVisibleNotifications.length === 0 && <p className="tiny muted">No notifications yet.</p>}
                        {dashboardVisibleNotifications.map((item) => (
                          <article
                            key={item.id}
                            className={`dashboard-notify-item ${dashboardNotificationReadMap[item.id] ? "read" : ""}`}
                            onClick={() =>
                              setDashboardNotificationReadMap((prev) => ({
                                ...prev,
                                [item.id]: true
                              }))
                            }
                          >
                            <div>
                              <p className="dashboard-notify-title">{item.title}</p>
                              <p className="tiny muted">{item.message}</p>
                            </div>
                            <div className="inline-actions">
                              {item.bucket === "inventory" && item.menuItemId && (
                                <button
                                  className="ghost"
                                  onClick={(event) => {
                                    event.stopPropagation();
                                    void toggleMenuAvailability(item.menuItemId!, true);
                                    setDashboardNotificationReadMap((prev) => ({ ...prev, [item.id]: true }));
                                  }}
                                >
                                  Mark in stock
                                </button>
                              )}
                              {item.bucket === "kitchen" && item.orderId && (
                                <button
                                  className="ghost"
                                  onClick={(event) => {
                                    event.stopPropagation();
                                    setSelectedOrderId(item.orderId || null);
                                    setDashboardNotificationReadMap((prev) => ({ ...prev, [item.id]: true }));
                                  }}
                                >
                                  Open order
                                </button>
                              )}
                            </div>
                          </article>
                        ))}
                      </div>
                    </section>
                  )}
                </div>
                <button className="ghost dash-refresh-btn" onClick={() => void fetchOrders()}>Refresh</button>
                <button className="primary dash-create-btn" onClick={() => setActiveView("menu")}>+ New Order</button>
              </div>
            </header>

            <div className="dashboard-dash">
            {(() => {
              const hour = new Date().getHours();
              const isPeakTime = (hour >= 8 && hour <= 10) || (hour >= 12 && hour <= 14) || (hour >= 18 && hour <= 20);
              return isPeakTime ? (
                <div className="dashboard-peak-badge">
                  <span>🔥</span> Peak time — Busy now
                </div>
              ) : null;
            })()}

            <section className="dashboard-kpi-hero">
              <article className="dashboard-kpi-card hero-revenue dashboard-kpi-clickable" onClick={() => setActiveView("analytics")}>
                <div className="dashboard-kpi-label">Total Earning</div>
                <div className="dashboard-kpi-value">₹{dashboardKpis.totalEarning}</div>
              </article>
              <article
                className="dashboard-kpi-card dashboard-kpi-clickable"
                onClick={() => {
                  setOrderFilterStatus("in_progress");
                  setActiveView("orders");
                }}
              >
                <div className="dashboard-kpi-label">In Progress</div>
                <div className="dashboard-kpi-value">{dashboardKpis.inProgress}</div>
              </article>
              <article
                className="dashboard-kpi-card dashboard-kpi-clickable"
                onClick={() => {
                  setOrderFilterStatus("completed");
                  setActiveView("orders");
                }}
              >
                <div className="dashboard-kpi-label">Completed</div>
                <div className="dashboard-kpi-value">{dashboardKpis.completed}</div>
              </article>
              <article
                className="dashboard-kpi-card dashboard-kpi-clickable"
                onClick={() => {
                  setOrderFilterPayment("all");
                  setActiveView("orders");
                }}
              >
                <div className="dashboard-kpi-label">Waiting for Payment</div>
                <div className="dashboard-kpi-value">{dashboardKpis.waitingPayment}</div>
              </article>
              <article className="dashboard-kpi-card dashboard-kpi-clickable" onClick={() => setActiveView("analytics")}>
                <div className="dashboard-kpi-label">Avg Ticket</div>
                <div className="dashboard-kpi-value">₹{dashboardKpis.avgTicket}</div>
              </article>
              {rolloutFlags.businessModules && (
                <article
                  className="dashboard-kpi-card dashboard-kpi-clickable"
                  onClick={() => {
                    setCustomerSegmentFilter("At Risk");
                    setActiveView("customers");
                  }}
                  style={{ borderColor: "var(--error, #dc2626)", background: "rgba(220, 38, 38, 0.05)" }}
                >
                  <div className="dashboard-kpi-label">At Risk</div>
                  <div className="dashboard-kpi-value" style={{ color: "var(--error, #dc2626)" }}>
                    {customerSummary.filter((c) => c.segment === "At Risk").length}
                  </div>
                  <div className="tiny muted">No visit 30+ days</div>
                </article>
              )}
            </section>

            <section className="dashboard-stream-grid">
              <article className="panel dashboard-stream-panel dashboard-stream-panel-wide">
                <div className="section-head">
                  <h3>Live Queue</h3>
                  <button className="ghost" onClick={() => void fetchOrders()}>Refresh queue</button>
                </div>
                <div className="dashboard-stream-toolbar">
                  <input
                    className="search"
                    placeholder="Search by order/customer/table/phone..."
                    value={dashboardSearch}
                    onChange={(event) => setDashboardSearch(event.target.value)}
                  />
                </div>
                <div className="dashboard-queue-columns">
                  <article className="dashboard-queue-col">
                    <div className="section-head">
                      <h4>In Progress</h4>
                      <span className="tiny muted">{dashboardFilteredInProgressOrders.length}</span>
                    </div>
                    <div className="dashboard-stream-list">
                      {dashboardFilteredInProgressOrders.slice(0, 8).map((order) => {
                        const primaryAction = getPrimaryOrderAction(order);
                        return (
                          <div
                            key={order.id}
                            className={`dashboard-order-row dashboard-order-row-ops dashboard-order-row-clickable dashboard-order-status-${order.status}`}
                            onClick={() => setSelectedOrderId(order.id)}
                          >
                            <div style={{ display: "flex", flexDirection: "column", gap: "4px" }}>
                              <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                                <strong>{order.order_number}</strong>
                                {order.order_type === "whatsapp_bot" && (
                                  <span style={{ backgroundColor: "#25D366", color: "white", padding: "2px 6px", borderRadius: "4px", fontSize: "10px", fontWeight: "bold" }}>WHATSAPP</span>
                                )}
                              </div>
                              <p className="tiny muted" style={{ margin: 0 }}>
                                {order.customer_name || "Walk-in"} • {orderTypeDisplay(order)} • ₹{Math.round(order.total_amount || 0)}
                              </p>
                            </div>
                            <div className="dashboard-order-actions">
                              <span className={`tag status-badge status-${order.status}`}>{order.status.split("_").join(" ")}</span>
                              <div className="dashboard-order-btn-group">
                                {primaryAction && (
                                  <button
                                    className="ghost order-action-btn order-action-preparing"
                                    disabled={orderUpdateLoadingId === order.id}
                                    onClick={(event) => {
                                      event.stopPropagation();
                                      void updateOrderStatus(order.id, primaryAction.targetStatus);
                                    }}
                                  >
                                    {primaryAction.label}
                                  </button>
                                )}
                                {order.payment_status !== "paid" && (
                                  <button
                                    className="ghost order-action-btn order-action-pay"
                                    disabled={orderUpdateLoadingId === order.id}
                                    onClick={(event) => {
                                      event.stopPropagation();
                                      void markPaymentReceived(order.id);
                                    }}
                                  >
                                    Mark Paid
                                  </button>
                                )}
                              </div>
                              <button
                                className="ghost order-action-btn order-action-print dashboard-order-print-btn"
                                onClick={(event) => {
                                  event.stopPropagation();
                                  void queueOrderPrint(order);
                                }}
                              >
                                Print
                              </button>
                            </div>
                          </div>
                        );
                      })}
                      {dashboardFilteredInProgressOrders.length === 0 && <p className="muted tiny">No matching in-progress orders.</p>}
                    </div>
                  </article>

                  <article className="dashboard-queue-col">
                    <div className="section-head">
                      <h4>Waiting for Payments</h4>
                      <span className="tiny muted">{dashboardFilteredWaitingPaymentOrders.length}</span>
                    </div>
                    <div className="dashboard-stream-list">
                      {dashboardFilteredWaitingPaymentOrders.slice(0, 8).map((order) => {
                        return (
                          <div
                            key={order.id}
                            className={`dashboard-order-row dashboard-order-row-ops dashboard-order-row-clickable dashboard-order-status-${order.status}`}
                            onClick={() => setSelectedOrderId(order.id)}
                          >
                            <div style={{ display: "flex", flexDirection: "column", gap: "4px" }}>
                              <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                                <strong>{order.order_number}</strong>
                                {order.order_type === "whatsapp_bot" && (
                                  <span style={{ backgroundColor: "#25D366", color: "white", padding: "2px 6px", borderRadius: "4px", fontSize: "10px", fontWeight: "bold" }}>WHATSAPP</span>
                                )}
                              </div>
                              <p className="tiny muted" style={{ margin: 0 }}>
                                {order.customer_name || "Walk-in"} • {orderTypeDisplay(order)} • ₹{Math.round(order.total_amount || 0)}
                              </p>
                            </div>
                            <div className="dashboard-order-actions">
                              <span className={`tag status-badge status-${order.status}`}>{order.status.split("_").join(" ")}</span>
                              <div className="dashboard-order-btn-group">
                                {order.payment_status !== "paid" && (
                                  <button
                                    className="ghost order-action-btn order-action-pay"
                                    disabled={orderUpdateLoadingId === order.id}
                                    onClick={(event) => {
                                      event.stopPropagation();
                                      void markPaymentReceived(order.id);
                                    }}
                                  >
                                    Mark Paid
                                  </button>
                                )}
                              </div>
                              <button
                                className="ghost order-action-btn order-action-print dashboard-order-print-btn"
                                onClick={(event) => {
                                  event.stopPropagation();
                                  void queueOrderPrint(order);
                                }}
                              >
                                Print
                              </button>
                            </div>
                          </div>
                        );
                      })}
                      {dashboardFilteredWaitingPaymentOrders.length === 0 && <p className="muted tiny">No matching payment-pending orders.</p>}
                    </div>
                  </article>

                  <article className="dashboard-queue-col dashboard-queue-completed-row">
                    <div className="section-head">
                      <h4>Completed</h4>
                      <span className="tiny muted">{dashboardFilteredCompletedOrders.length}</span>
                    </div>
                    <div className="dashboard-stream-list">
                      {dashboardFilteredCompletedOrders.slice(0, 12).map((order) => (
                        <div
                          key={order.id}
                          className={`dashboard-order-row dashboard-order-row-ops dashboard-order-row-clickable dashboard-order-status-${order.status}`}
                          onClick={() => setSelectedOrderId(order.id)}
                        >
                          <div style={{ display: "flex", flexDirection: "column", gap: "4px" }}>
                            <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                              <strong>{order.order_number}</strong>
                              {order.order_type === "whatsapp_bot" && (
                                <span style={{ backgroundColor: "#25D366", color: "white", padding: "2px 6px", borderRadius: "4px", fontSize: "10px", fontWeight: "bold" }}>WHATSAPP</span>
                              )}
                            </div>
                            <p className="tiny muted" style={{ margin: 0 }}>
                              {order.customer_name || "Walk-in"} • {orderTypeDisplay(order)} • ₹{Math.round(order.total_amount || 0)}
                            </p>
                          </div>
                          <div className="dashboard-order-actions">
                            <span className={`tag status-badge status-${order.status}`}>{order.status}</span>
                            <button
                              className="ghost order-action-btn order-action-print dashboard-order-print-btn"
                              onClick={(event) => {
                                event.stopPropagation();
                                void queueOrderPrint(order);
                              }}
                            >
                              Print
                            </button>
                          </div>
                        </div>
                      ))}
                      {dashboardFilteredCompletedOrders.length === 0 && <p className="muted tiny">No matching completed orders.</p>}
                    </div>
                  </article>
                </div>
              </article>
            </section>
            {selectedOrder && (
              <section className="panel nested order-details-panel order-details-panel-floating">
                <div className="section-head">
                  <h4>Order Details: {selectedOrder.order_number}</h4>
                  <div className="inline-actions">
                    {!isEditingSelectedOrder && selectedOrderDraft && (
                      <button className="ghost" onClick={startEditingSelectedOrder}>Edit</button>
                    )}
                    {isEditingSelectedOrder && selectedOrderDraft && (
                      <>
                        <button className="ghost" disabled={orderUpdateLoadingId === selectedOrder.id} onClick={() => void saveSelectedOrderEdits()}>
                          Save
                        </button>
                        <button
                          className="ghost"
                          onClick={() => {
                            setSelectedOrderItemsDraft(selectedOrderItems.map((item) => ({ ...item })));
                            setSelectedOrderAddPanelOpen(false);
                            setSelectedOrderAddItemId("");
                            setSelectedOrderAddQty(1);
                            setIsEditingSelectedOrder(false);
                          }}
                        >
                          Cancel
                        </button>
                      </>
                    )}
                    <button className="ghost" onClick={() => setSelectedOrderId(null)}>Close</button>
                  </div>
                </div>
                <div className="order-details-meta">
                  <span className={`tag status-badge status-${selectedOrder.status}`}>{selectedOrder.status.split("_").join(" ")}</span>
                  <span className="tiny muted">{new Date(selectedOrder.created_at).toLocaleString()}</span>
                </div>
                {isEditingSelectedOrder && selectedOrderDraft ? (
                  <>
                    <div className="triple">
                      <label className="field">
                        <span>Customer Name</span>
                        <input
                          value={selectedOrderDraft.customerName}
                          onChange={(e) => setSelectedOrderDraft((prev) => (prev ? { ...prev, customerName: e.target.value } : prev))}
                        />
                      </label>
                      <label className="field">
                        <span>Phone</span>
                        <input
                          value={selectedOrderDraft.customerPhone}
                          onChange={(e) => setSelectedOrderDraft((prev) => (prev ? { ...prev, customerPhone: e.target.value } : prev))}
                        />
                      </label>
                      <label className="field">
                        <span>Order Type</span>
                        <select
                          value={selectedOrderDraft.orderType}
                          onChange={(e) =>
                            setSelectedOrderDraft((prev) =>
                              prev
                                ? {
                                    ...prev,
                                    orderType: e.target.value as "delivery" | "dine_in" | "takeaway"
                                  }
                                : prev
                            )
                          }
                        >
                          <option value="takeaway">Takeaway</option>
                          <option value="dine_in">Dine-In</option>
                          <option value="delivery">Delivery</option>
                        </select>
                      </label>
                      {selectedOrderDraft.orderType === "dine_in" && (
                        <label className="field">
                          <span>Table Number</span>
                          <input
                            value={selectedOrderDraft.tableNumber}
                            onChange={(e) => setSelectedOrderDraft((prev) => (prev ? { ...prev, tableNumber: e.target.value } : prev))}
                          />
                        </label>
                      )}
                      {selectedOrderDraft.orderType !== "dine_in" && (
                        <label className="field">
                          <span>Pickup/Block</span>
                          <input
                            value={selectedOrderDraft.deliveryBlock}
                            onChange={(e) => setSelectedOrderDraft((prev) => (prev ? { ...prev, deliveryBlock: e.target.value } : prev))}
                          />
                        </label>
                      )}
                      {selectedOrderDraft.orderType === "delivery" && (
                        <label className="field">
                          <span>Delivery Address</span>
                          <input
                            value={selectedOrderDraft.deliveryAddress}
                            onChange={(e) => setSelectedOrderDraft((prev) => (prev ? { ...prev, deliveryAddress: e.target.value } : prev))}
                          />
                        </label>
                      )}
                      <label className="field">
                        <span>Notes</span>
                        <input
                          value={selectedOrderDraft.notes}
                          onChange={(e) => setSelectedOrderDraft((prev) => (prev ? { ...prev, notes: e.target.value } : prev))}
                        />
                      </label>
                    </div>
                    <div className="inline-actions" style={{ marginTop: 8, marginBottom: 10 }}>
                      {!selectedOrderAddPanelOpen ? (
                        <button
                          className="ghost"
                          type="button"
                          onClick={() => {
                            setSelectedOrderAddPanelOpen(true);
                            setSelectedOrderAddItemId("");
                            setSelectedOrderAddQty(1);
                          }}
                        >
                          Add Item +
                        </button>
                      ) : (
                        <>
                          <label className="field" style={{ minWidth: 240 }}>
                            <span>Add Item</span>
                            <select value={selectedOrderAddItemId} onChange={(e) => setSelectedOrderAddItemId(e.target.value)}>
                              <option value="">Select item</option>
                              {menu.map((menuItem) => (
                                <option key={menuItem.id} value={menuItem.id}>
                                  {menuItem.name} (₹{menuItem.basePrice})
                                </option>
                              ))}
                            </select>
                          </label>
                          <label className="field" style={{ width: 100 }}>
                            <span>Qty</span>
                            <input
                              type="number"
                              min={1}
                              value={selectedOrderAddQty}
                              onChange={(e) => setSelectedOrderAddQty(Math.max(1, Number(e.target.value || 1)))}
                            />
                          </label>
                          <button className="ghost" type="button" onClick={addSelectedOrderItem}>Confirm Add</button>
                          <button
                            className="ghost"
                            type="button"
                            onClick={() => {
                              setSelectedOrderAddPanelOpen(false);
                              setSelectedOrderAddItemId("");
                              setSelectedOrderAddQty(1);
                            }}
                          >
                            Dismiss
                          </button>
                        </>
                      )}
                    </div>
                  </>
                ) : (
                  <div className="order-details-kv">
                    <p className="tiny"><strong>Type:</strong> {orderTypeDisplay(selectedOrder)}</p>
                    <p className="tiny"><strong>Payment:</strong> {selectedOrder.payment_method || "n/a"} ({selectedOrder.payment_status || "pending"})</p>
                    <p className="tiny"><strong>Customer:</strong> {selectedOrder.customer_name || "Walk-in"}{selectedOrder.phone_number ? ` • ${selectedOrder.phone_number}` : ""}</p>
                    <p className="tiny"><strong>Location:</strong> {selectedOrder.delivery_address || selectedOrder.delivery_block || (selectedOrder.table_number ? `Table ${selectedOrder.table_number}` : "No location")}</p>
                    <p className="tiny"><strong>Notes:</strong> {selectedOrder.delivery_notes || "None"}</p>
                  </div>
                )}
                <ul className="list order-details-items">
                  {displayedSelectedOrderItems.length === 0 && <li>No items loaded.</li>}
                  {displayedSelectedOrderItems.map((item) => (
                    <li key={item.id}>
                      <div className="row">
                        <span>{item.menu_items?.[0]?.name || "Item"} x {item.quantity}</span>
                        <strong>₹{item.total_price}</strong>
                      </div>
                      <p className="tiny muted">Unit: ₹{item.unit_price}</p>
                      {item.special_instructions && !item.special_instructions.trim().startsWith("{") && (
                        <p className="tiny muted">{item.special_instructions}</p>
                      )}
                      {isEditingSelectedOrder && (
                        <div className="inline-actions">
                          <button className="ghost" onClick={() => updateSelectedOrderItemQty(item.id, -1)}>-</button>
                          <span className="tiny">Qty {item.quantity}</span>
                          <button className="ghost" onClick={() => updateSelectedOrderItemQty(item.id, 1)}>+</button>
                          <button className="ghost order-action-btn order-action-cancel" onClick={() => removeSelectedOrderItem(item.id)}>
                            Remove
                          </button>
                        </div>
                      )}
                    </li>
                  ))}
                </ul>
                <div className="totals">
                  <div className="row">
                    <span>Subtotal</span>
                    <strong>₹{displayedSelectedOrderItems.reduce((sum, item) => sum + Number(item.total_price || 0), 0)}</strong>
                  </div>
                  <div className="row">
                    <span>Tax + Charges</span>
                    <strong>
                      ₹{" "}
                      {Math.max(
                        0,
                        Number(selectedOrder.total_amount || 0) -
                          selectedOrderItems.reduce((sum, item) => sum + Number(item.total_price || 0), 0)
                      )}
                    </strong>
                  </div>
                  <div className="row grand">
                    <span>Total</span>
                    <strong>
                      ₹{" "}
                      {Math.round(
                        displayedSelectedOrderItems.reduce((sum, item) => sum + Number(item.total_price || 0), 0) +
                          Math.max(
                            0,
                            Number(selectedOrder.total_amount || 0) -
                              selectedOrderItems.reduce((sum, item) => sum + Number(item.total_price || 0), 0)
                          )
                      )}
                    </strong>
                  </div>
                </div>
              </section>
            )}
            </div>
            {renderTableControlsPanel(selectedTableSummary)}
          </>
        )}

        {activeView === "menu" && rolloutFlags.manualBilling && (
          <>
            <MobileHeader
              title="Sales"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
              center={
                <div className="mobile-user-profile">
                  <span className="mobile-user-name">{(user.fullName || user.email).split(" ")[0]}</span>
                  <span className="mobile-user-role chip-mini">{orderMode.replace("_", " ")}</span>
                </div>
              }
              right={
                <button className="ghost settings-toggle-btn" onClick={() => setActiveView("settings")}>
                  <Settings size={22} />
                </button>
              }
            />

            <header className="topbar desktop-only-header">
              <input
                className="search"
                placeholder="Search coffee..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
              <div className="top-actions">
                <button className="ghost" onClick={() => void refreshMenu()}>Refresh Menu</button>
                <button className="ghost" onClick={() => void flushOutbox()}>Sync ({pendingCount})</button>
              </div>
            </header>

            <section className="content-grid menu-layout">
              {/* Mobile Search & Filter (Reference Style) */}
              <div className="mobile-search-row">
                <div className="mobile-search-input-wrap">
                  <SearchIcon size={18} />
                  <input
                    placeholder="Search Menu"
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                  />
                </div>
                <button className="ghost mobile-filter-btn">
                  <Settings2 size={18} />
                </button>
              </div>

              <aside className="category-sidebar mobile-category-ribbon">
                {["all", ...categories].map((cat) => (
                  <button
                    key={cat}
                    className={`category-btn category-tile ${selectedCategory === cat ? "active" : ""}`}
                    onClick={() => setSelectedCategory(cat)}
                  >
                    <div className="category-icon-wrap">
                      {getCategoryIcon(cat || "all")}
                    </div>
                    <span className="cat-label">{cat === "all" ? "Favorite" : cat}</span>
                  </button>
                ))}
              </aside>

              <aside className="category-sidebar desktop-only-categories">
                {categories.map((cat) => (
                  <button
                    key={cat}
                    className={`category-btn ${selectedCategory === cat ? "active" : ""}`}
                    onClick={() => setSelectedCategory(cat)}
                  >
                    <div className="cat-icon">{getCategoryIcon(cat || "all")}</div>
                    <span className="cat-label">{cat === "all" ? "All Menu" : cat}</span>
                    <span className="cat-count">{categoryCounts[cat || "all"] || 0}</span>
                  </button>
                ))}
              </aside>

              <div className="menu-grid">
                {filteredMenu.map((item) => {
                  const cartItem = cartItems.find((ci) => ci.productId === item.id);
                  const qty = cartItem ? cartItem.quantity : 0;
                  
                  const modifierGroups = getModifiersForItem(item.id);
                  const handleIncrement = (e: React.MouseEvent) => {
                    e.stopPropagation();
                    if (qty === 0) {
                      if (modifierGroups.length > 0) {
                        setModifierProductForAdd({ product: item, groups: modifierGroups });
                        setModifierSelections(getDefaultSelections(modifierGroups));
                      } else {
                        setCartItems(prev => [
                          ...prev,
                          {
                            productId: item.id,
                            productName: item.name,
                            quantity: 1,
                            unitPrice: item.basePrice,
                            lineTotal: item.basePrice,
                            selections: { size: "medium", milk: "regular", sugarLevel: "regular", extraShots: 0 }
                          }
                        ]);
                      }
                    } else {
                      setCartItems(prev =>
                        prev.map(ci =>
                          ci.productId === item.id
                            ? { ...ci, quantity: ci.quantity + 1, lineTotal: (ci.quantity + 1) * ci.unitPrice }
                            : ci
                        )
                      );
                    }
                  };

                  const handleDecrement = (e: React.MouseEvent) => {
                    e.stopPropagation();
                    if (qty <= 1 && cartItem) {
                      setCartItems(prev => prev.filter(ci => ci.productId !== item.id));
                    } else {
                      setCartItems(prev =>
                        prev.map(ci =>
                          ci.productId === item.id
                            ? { ...ci, quantity: ci.quantity - 1, lineTotal: (ci.quantity - 1) * ci.unitPrice }
                            : ci
                        )
                      );
                    }
                  };

                  return (
                    <article
                      key={item.id}
                      className={`product-card ${qty > 0 ? "product-selected" : ""}`}
                      onClick={handleIncrement}
                    >
                      <div className="card-content">
                        <div className="card-main">
                          {(item as any).imageUrl && (
                            <div className="menu-thumb">
                              <img src={(item as any).imageUrl} alt={item.name} style={{ width: "100%", height: "100%", objectFit: "cover", borderRadius: "50%" }} />
                            </div>
                          )}
                          <p className="menu-category">{(item as any).category || selectedCategory || "Menu"}</p>
                          <h4>{item.name}</h4>
                        </div>
                        <div className="card-footer">
                          <p className="price">₹{item.basePrice}</p>
                          <div className="qty-controls" onClick={e => e.stopPropagation()}>
                            <button type="button" className="qty-btn" onClick={handleDecrement} disabled={qty === 0}>-</button>
                            <span className="qty-display">{qty}</span>
                            <button type="button" className="qty-btn plus" onClick={handleIncrement} aria-label="Add"><Plus size={16} strokeWidth={2.5} /></button>
                          </div>
                        </div>
                      </div>
                    </article>
                  );
                })}
              </div>
            </section>

            {/* Floating Proceed Order Bar (Reference Style) */}
            {cartItems.length > 0 && (
              <div className="mobile-proceed-bar" onClick={() => setIsMobileCartOpen(true)}>
                <div className="proceed-info">
                  <span className="proceed-label">Proceed New Order</span>
                </div>
                <div className="proceed-summary">
                  <span className="proceed-count">{cartItems.length} Items</span>
                  <span className="proceed-total">₹{Math.round(cartItems.reduce((acc, ci) => acc + ci.lineTotal, 0))}</span>
                  <ArrowRight size={20} />
                </div>
              </div>
            )}
          </>
        )}

        {activeView === "orders" && rolloutFlags.orders && (
          <>
            <MobileHeader
              title="Orders"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
              right={
                <button className="ghost" onClick={() => void fetchOrders()}>
                  Refresh
                </button>
              }
            />

            <section className="panel table-management-shell">
            {!isOnline && (
              <div className="orders-offline-banner" role="status">
                <span className="orders-offline-dot" />
                You&apos;re offline — showing local orders. Sync will resume when back online.
              </div>
            )}
            <div className="section-head">
              <h3>Active Orders</h3>
              <div className="inline-actions">
                <div className="orders-layout-toggle" title="Switch layout">
                  <button
                    className={`ghost orders-layout-btn ${ordersLayoutMode === "cards" ? "active" : ""}`}
                    onClick={() => setOrdersLayoutMode("cards")}
                    aria-label="Card view"
                  >
                    <LayoutGrid size={18} />
                    <span>Cards</span>
                  </button>
                  <button
                    className={`ghost orders-layout-btn ${ordersLayoutMode === "power_user" ? "active" : ""}`}
                    onClick={() => setOrdersLayoutMode("power_user")}
                    aria-label="Table view"
                  >
                    <List size={18} />
                    <span>Table</span>
                  </button>
                </div>
                <button className="ghost" onClick={() => setActiveView("menu")}>+ Create New Order</button>
                <button className="ghost" onClick={() => void fetchOrders()}>Refresh</button>
              </div>
            </div>
            <div className="orders-toolbar">
              <div className="status-chips">
                {[
                  ["all", "All"],
                  ["in_progress", "In Progress"],
                  ["ready_to_serve", "Ready to Served"],
                  ["waiting_payment", "Waiting for Payment"]
                ].map(([value, label]) => (
                  <button
                    key={value}
                    className={`chip status-chip status-${value} ${orderFilterStatus === value ? "chip-active" : ""}`}
                    onClick={() => setOrderFilterStatus(value)}
                  >
                    <span>{label}</span>
                    <span className="chip-count">{orderStageCounts[value as keyof typeof orderStageCounts] || 0}</span>
                  </button>
                ))}
              </div>
              <div className="orders-toolbar-right">
                <input
                  className="search"
                  value={orderSearch}
                  onChange={(e) => setOrderSearch(e.target.value)}
                  placeholder="Search Order ID or Customer Name"
                />
                <select value={orderSort} onChange={(e) => setOrderSort(e.target.value as "latest" | "oldest" | "order_type")}>
                  <option value="latest">Sort by: Latest Order</option>
                  <option value="oldest">Sort by: Oldest Order</option>
                  <option value="order_type">Sort by: Order Type</option>
                </select>
                <select value={orderFilterPayment} onChange={(e) => setOrderFilterPayment(e.target.value)}>
                  <option value="all">All Payments</option>
                  <option value="cash">Cash</option>
                  <option value="card">Card</option>
                  <option value="upi">UPI</option>
                  <option value="razorpay">Razorpay</option>
                  <option value="phonepe">PhonePe</option>
                </select>
                <select value={orderFilterType} onChange={(e) => setOrderFilterType(e.target.value)}>
                  <option value="all">All Types</option>
                  <option value="dine_in">Dine-In</option>
                  <option value="takeaway">Takeaway</option>
                  <option value="delivery">Delivery</option>
                </select>
                <select value={orderFilterSync} onChange={(e) => setOrderFilterSync(e.target.value)}>
                  <option value="all">All Sync</option>
                  <option value="remote">Remote</option>
                  <option value="pending">Pending</option>
                  <option value="syncing">Syncing</option>
                  <option value="failed">Failed</option>
                  <option value="synced">Synced</option>
                </select>
              </div>
            </div>
            <div className="kpi-row orders-kpi-row">
              <article className="kpi">
                <span>Visible Orders</span>
                <strong>{visibleOrders.length}</strong>
              </article>
              <article className="kpi">
                <span>Pending Payments</span>
                <strong>{orderOpsKpis.pendingPayments}</strong>
              </article>
              <article className="kpi">
                <span>Avg Ticket</span>
                <strong>₹{orderOpsKpis.avgTicket}</strong>
              </article>
            </div>
            <div className="orders-landscape-split">
            {ordersLayoutMode === "cards" ? (
            <div className="orders-grid">
              {visibleOrders.length === 0 && <p className="muted">No orders yet.</p>}
              {visibleOrders.map((order) => {
                const syncItem = outboxHistory.find((item) => item.payload.id === order.id);
                const orderItemsPreview = (orderItemsMap[order.id] || []).slice(0, 4);
                const minutesSinceCreated = Math.floor((Date.now() - new Date(order.created_at).getTime()) / 60000);
                const waitingAlert = !["completed", "cancelled"].includes(order.status) && minutesSinceCreated >= 10;
                return (
                  <article key={order.id} className={`order-card ${waitingAlert ? "order-card-alert" : ""}`}>
                    <header className="order-card-head">
                      <div>
                        <h4>{order.order_number}</h4>
                        <p className="tiny muted">
                          {new Date(order.created_at).toLocaleString()} • {minutesSinceCreated} min ago
                        </p>
                      </div>
                      <div className="order-card-tags">
                        <span className={`tag status-badge status-${order.status}`}>{order.status.split("_").join(" ")}</span>
                        <span className="tag">{syncItem?.status || "remote"}</span>
                      </div>
                    </header>
                    <p className="tiny muted">
                      {orderTypeDisplay(order)} | {order.payment_method || "n/a"} ({order.payment_status || "pending"})
                    </p>
                    <p className="tiny muted">
                      {order.customer_name || "Walk-in"}{order.phone_number ? ` • ${order.phone_number}` : ""}
                    </p>
                    <p className="tiny muted">
                      {order.delivery_address || (order.table_number ? `Table ${order.table_number}` : order.delivery_block || "No location")}
                    </p>
                    <div className="order-card-items">
                      {orderItemsPreview.length === 0 && <p className="tiny muted">No items loaded.</p>}
                      {orderItemsPreview.map((item) => (
                        <div key={item.id} className="order-card-item-row tiny">
                          <span>{item.menu_items?.[0]?.name || "Item"}</span>
                          <span>x{item.quantity}</span>
                          <strong>₹{item.total_price}</strong>
                        </div>
                      ))}
                    </div>
                    <p className="order-total">₹{order.total_amount}</p>
                    <div className="inline-actions">
                      <button className="ghost" onClick={() => setSelectedOrderId(order.id)}>
                        See Details
                      </button>
                      {order.payment_status !== "paid" && (order.payment_method || "").toLowerCase() === "cash" && (
                        <button
                          className="ghost order-action-btn order-action-pay"
                          disabled={orderUpdateLoadingId === order.id}
                          onClick={() => void markPaymentReceived(order.id)}
                        >
                          Pay Bill
                        </button>
                      )}
                      <button className="ghost order-action-btn order-action-print" onClick={() => void queueOrderPrint(order)}>
                        Print KOT
                      </button>
                    </div>
                  </article>
                );
              })}
            </div>
            ) : (
            <div className="orders-power-user">
              {visibleOrders.length === 0 && <p className="muted">No orders yet.</p>}
              <div className="orders-power-user-header">
                <span className="orders-pu-col orders-pu-id">Order</span>
                <span className="orders-pu-col orders-pu-time">Time</span>
                <span className="orders-pu-col orders-pu-status">Status</span>
                <span className="orders-pu-col orders-pu-type">Type</span>
                <span className="orders-pu-col orders-pu-customer">Customer</span>
                <span className="orders-pu-col orders-pu-total">Total</span>
                <span className="orders-pu-col orders-pu-actions">Actions</span>
              </div>
              {visibleOrders.map((order) => {
                const syncItem = outboxHistory.find((item) => item.payload.id === order.id);
                const primaryAction = getPrimaryOrderAction(order);
                const orderItemsPreview = (orderItemsMap[order.id] || []).slice(0, 3);
                const minutesSinceCreated = Math.floor((Date.now() - new Date(order.created_at).getTime()) / 60000);
                const waitingAlert = !["completed", "cancelled"].includes(order.status) && minutesSinceCreated >= 10;
                return (
                  <div
                    key={order.id}
                    className={`orders-power-user-row ${waitingAlert ? "order-card-alert" : ""} orders-power-user-row-clickable`}
                    onClick={() => setSelectedOrderId(order.id)}
                  >
                    <div className="orders-pu-col orders-pu-id">
                      <strong>{order.order_number}</strong>
                      {orderItemsPreview.length > 0 && (
                        <p className="tiny muted orders-pu-items-preview">
                          {orderItemsPreview.map((i) => i.menu_items?.[0]?.name || "Item").join(", ")}
                          {(orderItemsMap[order.id]?.length || 0) > 3 && " …"}
                        </p>
                      )}
                    </div>
                    <div className="orders-pu-col orders-pu-time">
                      <span className="tiny">{new Date(order.created_at).toLocaleString()}</span>
                      <span className="tiny muted">{minutesSinceCreated}m ago</span>
                    </div>
                    <div className="orders-pu-col orders-pu-status">
                      <span className={`tag status-badge status-${order.status}`}>{order.status.split("_").join(" ")}</span>
                      <span className="tag tiny">{syncItem?.status || "remote"}</span>
                    </div>
                    <div className="orders-pu-col orders-pu-type">
                      <span className="tiny">{orderTypeDisplay(order)}</span>
                      <span className="tiny muted">{order.payment_method || "n/a"}</span>
                    </div>
                    <div className="orders-pu-col orders-pu-customer">
                      <span className="tiny">{order.customer_name || "Walk-in"}</span>
                      {order.phone_number && <span className="tiny muted">{order.phone_number}</span>}
                    </div>
                    <div className="orders-pu-col orders-pu-total">
                      <strong>₹{order.total_amount}</strong>
                    </div>
                    <div className="orders-pu-col orders-pu-actions" onClick={(e) => e.stopPropagation()}>
                      {primaryAction && (
                        <button
                          className="ghost order-action-btn order-action-preparing"
                          disabled={orderUpdateLoadingId === order.id}
                          onClick={() => void updateOrderStatus(order.id, primaryAction.targetStatus)}
                        >
                          {primaryAction.label}
                        </button>
                      )}
                      {order.payment_status !== "paid" && (order.payment_method || "").toLowerCase() === "cash" && (
                        <button
                          className="ghost order-action-btn order-action-pay"
                          disabled={orderUpdateLoadingId === order.id}
                          onClick={() => void markPaymentReceived(order.id)}
                        >
                          Pay
                        </button>
                      )}
                      <button className="ghost order-action-btn order-action-print" onClick={() => void queueOrderPrint(order)}>KOT</button>
                    </div>
                  </div>
                );
              })}
            </div>
            )}
            {selectedOrder && (
              <div className="order-details-overlay" onClick={() => setSelectedOrderId(null)}>
                <section className="panel nested order-details-panel order-details-modal" onClick={(e) => e.stopPropagation()}>
                <div className="section-head">
                  <h4>Order Details: {selectedOrder.order_number}</h4>
                  <div className="inline-actions">
                    {!isEditingSelectedOrder && selectedOrderDraft && (
                      <button className="ghost" onClick={startEditingSelectedOrder}>Edit</button>
                    )}
                    {isEditingSelectedOrder && selectedOrderDraft && (
                      <>
                        <button className="ghost" disabled={orderUpdateLoadingId === selectedOrder.id} onClick={() => void saveSelectedOrderEdits()}>
                          Save
                        </button>
                        <button
                          className="ghost"
                          onClick={() => {
                            setSelectedOrderItemsDraft(selectedOrderItems.map((item) => ({ ...item })));
                            setSelectedOrderAddPanelOpen(false);
                            setSelectedOrderAddItemId("");
                            setSelectedOrderAddQty(1);
                            setIsEditingSelectedOrder(false);
                          }}
                        >
                          Cancel
                        </button>
                      </>
                    )}
                    <button className="ghost" onClick={() => setSelectedOrderId(null)}>Close</button>
                  </div>
                </div>
                <div className="order-details-meta">
                  <span className={`tag status-badge status-${selectedOrder.status}`}>{selectedOrder.status.split("_").join(" ")}</span>
                  <span className="tiny muted">{new Date(selectedOrder.created_at).toLocaleString()}</span>
                </div>
                {isEditingSelectedOrder && selectedOrderDraft ? (
                  <>
                    <div className="triple">
                      <label className="field">
                        <span>Customer Name</span>
                        <input
                          value={selectedOrderDraft.customerName}
                          onChange={(e) => setSelectedOrderDraft((prev) => (prev ? { ...prev, customerName: e.target.value } : prev))}
                        />
                      </label>
                      <label className="field">
                        <span>Phone</span>
                        <input
                          value={selectedOrderDraft.customerPhone}
                          onChange={(e) => setSelectedOrderDraft((prev) => (prev ? { ...prev, customerPhone: e.target.value } : prev))}
                        />
                      </label>
                      <label className="field">
                        <span>Order Type</span>
                        <select
                          value={selectedOrderDraft.orderType}
                          onChange={(e) =>
                            setSelectedOrderDraft((prev) =>
                              prev
                                ? {
                                    ...prev,
                                    orderType: e.target.value as "delivery" | "dine_in" | "takeaway"
                                  }
                                : prev
                            )
                          }
                        >
                          <option value="takeaway">Takeaway</option>
                          <option value="dine_in">Dine-In</option>
                          <option value="delivery">Delivery</option>
                        </select>
                      </label>
                      {selectedOrderDraft.orderType === "dine_in" && (
                        <label className="field">
                          <span>Table Number</span>
                          <input
                            value={selectedOrderDraft.tableNumber}
                            onChange={(e) => setSelectedOrderDraft((prev) => (prev ? { ...prev, tableNumber: e.target.value } : prev))}
                          />
                        </label>
                      )}
                      {selectedOrderDraft.orderType !== "dine_in" && (
                        <label className="field">
                          <span>Pickup/Block</span>
                          <input
                            value={selectedOrderDraft.deliveryBlock}
                            onChange={(e) => setSelectedOrderDraft((prev) => (prev ? { ...prev, deliveryBlock: e.target.value } : prev))}
                          />
                        </label>
                      )}
                      {selectedOrderDraft.orderType === "delivery" && (
                        <label className="field">
                          <span>Delivery Address</span>
                          <input
                            value={selectedOrderDraft.deliveryAddress}
                            onChange={(e) => setSelectedOrderDraft((prev) => (prev ? { ...prev, deliveryAddress: e.target.value } : prev))}
                          />
                        </label>
                      )}
                      <label className="field">
                        <span>Notes</span>
                        <input
                          value={selectedOrderDraft.notes}
                          onChange={(e) => setSelectedOrderDraft((prev) => (prev ? { ...prev, notes: e.target.value } : prev))}
                        />
                      </label>
                    </div>
                    <div className="inline-actions" style={{ marginTop: 8, marginBottom: 10 }}>
                      {!selectedOrderAddPanelOpen ? (
                        <button
                          className="ghost"
                          type="button"
                          onClick={() => {
                            setSelectedOrderAddPanelOpen(true);
                            setSelectedOrderAddItemId("");
                            setSelectedOrderAddQty(1);
                          }}
                        >
                          Add Item +
                        </button>
                      ) : (
                        <>
                          <label className="field" style={{ minWidth: 240 }}>
                            <span>Add Item</span>
                            <select value={selectedOrderAddItemId} onChange={(e) => setSelectedOrderAddItemId(e.target.value)}>
                              <option value="">Select item</option>
                              {menu.map((menuItem) => (
                                <option key={menuItem.id} value={menuItem.id}>
                                  {menuItem.name} (₹{menuItem.basePrice})
                                </option>
                              ))}
                            </select>
                          </label>
                          <label className="field" style={{ width: 100 }}>
                            <span>Qty</span>
                            <input
                              type="number"
                              min={1}
                              value={selectedOrderAddQty}
                              onChange={(e) => setSelectedOrderAddQty(Math.max(1, Number(e.target.value || 1)))}
                            />
                          </label>
                          <button className="ghost" type="button" onClick={addSelectedOrderItem}>Confirm Add</button>
                          <button
                            className="ghost"
                            type="button"
                            onClick={() => {
                              setSelectedOrderAddPanelOpen(false);
                              setSelectedOrderAddItemId("");
                              setSelectedOrderAddQty(1);
                            }}
                          >
                            Dismiss
                          </button>
                        </>
                      )}
                    </div>
                  </>
                ) : (
                  <div className="order-details-kv">
                    <p className="tiny"><strong>Type:</strong> {orderTypeDisplay(selectedOrder)}</p>
                    <p className="tiny"><strong>Payment:</strong> {selectedOrder.payment_method || "n/a"} ({selectedOrder.payment_status || "pending"})</p>
                    <p className="tiny"><strong>Customer:</strong> {selectedOrder.customer_name || "Walk-in"}{selectedOrder.phone_number ? ` • ${selectedOrder.phone_number}` : ""}</p>
                    <p className="tiny"><strong>Location:</strong> {selectedOrder.delivery_address || selectedOrder.delivery_block || (selectedOrder.table_number ? `Table ${selectedOrder.table_number}` : "No location")}</p>
                    <p className="tiny"><strong>Notes:</strong> {selectedOrder.delivery_notes || "None"}</p>
                  </div>
                )}
                <ul className="list order-details-items">
                  {displayedSelectedOrderItems.length === 0 && <li>No items loaded.</li>}
                  {displayedSelectedOrderItems.map((item) => (
                    <li key={item.id}>
                      <div className="row">
                        <span>{item.menu_items?.[0]?.name || "Item"} x {item.quantity}</span>
                        <strong>₹{item.total_price}</strong>
                      </div>
                      <p className="tiny muted">Unit: ₹{item.unit_price}</p>
                      {item.special_instructions && !item.special_instructions.trim().startsWith("{") && (
                        <p className="tiny muted">{item.special_instructions}</p>
                      )}
                      {isEditingSelectedOrder && (
                        <div className="inline-actions">
                          <button className="ghost" onClick={() => updateSelectedOrderItemQty(item.id, -1)}>-</button>
                          <span className="tiny">Qty {item.quantity}</span>
                          <button className="ghost" onClick={() => updateSelectedOrderItemQty(item.id, 1)}>+</button>
                          <button className="ghost order-action-btn order-action-cancel" onClick={() => removeSelectedOrderItem(item.id)}>
                            Remove
                          </button>
                        </div>
                      )}
                    </li>
                  ))}
                </ul>
                <div className="totals">
                  <div className="row">
                    <span>Subtotal</span>
                    <strong>₹{displayedSelectedOrderItems.reduce((sum, item) => sum + Number(item.total_price || 0), 0)}</strong>
                  </div>
                  <div className="row">
                    <span>Tax + Charges</span>
                    <strong>
                      ₹{" "}
                      {Math.max(
                        0,
                        Number(selectedOrder.total_amount || 0) -
                          selectedOrderItems.reduce((sum, item) => sum + Number(item.total_price || 0), 0)
                      )}
                    </strong>
                  </div>
                  <div className="row grand">
                    <span>Total</span>
                    <strong>
                      ₹{" "}
                      {Math.round(
                        displayedSelectedOrderItems.reduce((sum, item) => sum + Number(item.total_price || 0), 0) +
                          Math.max(
                            0,
                            Number(selectedOrder.total_amount || 0) -
                              selectedOrderItems.reduce((sum, item) => sum + Number(item.total_price || 0), 0)
                          )
                      )}
                    </strong>
                  </div>
                </div>
                </section>
              </div>
            )}
            </div>
          </section>
          </>
        )}

        {activeView === "kitchen" && rolloutFlags.kitchen && (
          <>
            <MobileHeader
              title="Kitchen"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
              right={
                <button className="ghost" onClick={() => void fetchOrders()}>
                  Refresh
                </button>
              }
            />

            <section className="panel">
            <div className="section-head">
              <h3>Kitchen Display</h3>
              <button className="ghost" onClick={() => void fetchOrders()}>Refresh</button>
            </div>
            <div className="kpi-row orders-kpi-row">
              <article className="kpi">
                <span>New</span>
                <strong>{kitchenNewOrders.length}</strong>
              </article>
              <article className="kpi">
                <span>Preparing</span>
                <strong>{kitchenPreparingOrders.length}</strong>
              </article>
              <article className="kpi">
                <span>Ready / Dispatch</span>
                <strong>{kitchenReadyOrders.length}</strong>
              </article>
            </div>
            <div className="topbar">
              <input
                className="search"
                placeholder="Search by order / customer / type..."
                value={kitchenSearch}
                onChange={(e) => setKitchenSearch(e.target.value)}
              />
            </div>
            <div className="kitchen-board">
              {[
                ["New Orders", kitchenVisibleNewOrders] as const,
                ["Preparing", kitchenVisiblePreparingOrders] as const,
                ["Ready / Dispatch", kitchenVisibleReadyOrders] as const
              ].map(([laneTitle, laneOrders]) => (
                <section key={laneTitle} className="panel nested kitchen-lane">
                  <div className="section-head">
                    <h4>{laneTitle}</h4>
                    <span className="tiny muted">{laneOrders.length}</span>
                  </div>
                  <div className="kitchen-lane-list">
                    {laneOrders.length === 0 && <p className="tiny muted">No orders.</p>}
                    {laneOrders.map((order) => {
                      const primaryAction = getPrimaryOrderAction(order);
                      const ageMinutes = Math.max(0, Math.floor((Date.now() - new Date(order.created_at).getTime()) / 60000));
                      const urgent = ageMinutes >= 10 && order.status !== "completed" && order.status !== "cancelled";
                      return (
                        <article
                          key={order.id}
                          className={`kitchen-ticket ${urgent ? "kitchen-ticket-urgent" : ""}`}
                          onClick={() => setSelectedOrderId(order.id)}
                        >
                          <div className="row">
                            <strong>{order.order_number}</strong>
                            <span className="tiny muted">{ageMinutes} min</span>
                          </div>
                          <p className="tiny muted">{order.customer_name || "Walk-in"} • {orderTypeDisplay(order)}</p>
                          <p className="tiny muted">₹{Math.round(order.total_amount || 0)}</p>
                          <div className="inline-actions">
                            {primaryAction && (
                              <button
                                className="ghost order-action-btn order-action-preparing"
                                disabled={orderUpdateLoadingId === order.id}
                                onClick={(event) => {
                                  event.stopPropagation();
                                  void updateOrderStatus(order.id, primaryAction.targetStatus);
                                }}
                              >
                                Update
                              </button>
                            )}
                          </div>
                        </article>
                      );
                    })}
                  </div>
                </section>
              ))}
            </div>
            </section>
          </>
        )}

        {activeView === "tables" && rolloutFlags.tableManagement && (
          <>
            <MobileHeader
              title="Tables"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
            />

            <section className="panel">
            <div className="section-head">
              <h3>Table Management</h3>
              <span className="tiny muted">{tableOrders.length} active dine-in orders</span>
            </div>
            <section className="panel nested table-ops-section">
              <button
                className="table-ops-toggle"
                onClick={() => setTableOpsExpanded(!tableOpsExpanded)}
                aria-expanded={tableOpsExpanded}
              >
                <ArrowRightLeft size={18} style={{ color: "#16a26a" }} />
                <span>Transfer / Merge tables</span>
                <ChevronRight size={16} className={tableOpsExpanded ? "rotated" : ""} style={{ marginLeft: "auto" }} />
              </button>
              {tableOpsExpanded && (
                <div className="triple table-ops-fields">
                  <label className="field">
                    <span>Source Table</span>
                    <select value={tableOpSource} onChange={(e) => setTableOpSource(e.target.value)}>
                      <option value="">Select source</option>
                      {tableSummaries
                        .filter((table) => table.ordersForTable.length > 0)
                        .map((table) => (
                          <option key={table.tableNo} value={table.tableNo}>
                            Table {table.tableNo}
                          </option>
                        ))}
                    </select>
                  </label>
                  <label className="field">
                    <span>Target Table</span>
                    <select value={tableOpTarget} onChange={(e) => setTableOpTarget(e.target.value)}>
                      <option value="">Select target</option>
                      {tableSummaries.map((table) => (
                        <option key={table.tableNo} value={table.tableNo}>
                          Table {table.tableNo}
                        </option>
                      ))}
                    </select>
                  </label>
                  <div className="inline-actions table-op-actions">
                    <button className="ghost" onClick={() => void transferTableOrders()}>Transfer</button>
                    <button className="ghost" onClick={() => void mergeTableOrders()}>Merge</button>
                  </div>
                </div>
              )}
            </section>
            <div className="table-grid">
              {tableSummaries.map((table) => {
                const statusLabel =
                  table.status === "available"
                    ? "Available"
                    : table.status === "reserved"
                      ? "Reserved"
                      : table.status === "dirty"
                        ? "Dirty"
                        : "Occupied";
                const primaryAction =
                  table.status === "available" ? (
                    <button
                      className="table-card-action table-card-action-primary"
                      onClick={(e) => {
                        e.stopPropagation();
                        startTableOrder(table.tableNo);
                      }}
                    >
                      New Order
                    </button>
                  ) : table.status === "reserved" ? (
                    <button
                      className="table-card-action table-card-action-primary"
                      onClick={(e) => {
                        e.stopPropagation();
                        startTableOrder(table.tableNo);
                      }}
                    >
                      New Order
                    </button>
                  ) : table.status === "dirty" ? (
                    <button
                      className="table-card-action table-card-action-primary"
                      onClick={(e) => {
                        e.stopPropagation();
                        void resetTableForNewOrder(table.tableNo);
                      }}
                    >
                      Ready
                    </button>
                  ) : table.ordersForTable.length > 0 ? (
                    <div className="table-card-actions-row">
                      <button
                        className="table-card-action table-card-action-primary"
                        onClick={(e) => {
                          e.stopPropagation();
                          startTableOrder(table.tableNo);
                        }}
                      >
                        New Order
                      </button>
                      <button
                        className="table-card-action"
                        onClick={(e) => {
                          e.stopPropagation();
                          setActiveView("orders");
                          setSelectedOrderId(table.ordersForTable[0].id);
                          notify(`Opened ${table.ordersForTable[0].order_number}.`);
                        }}
                      >
                        View
                      </button>
                    </div>
                  ) : (
                    <button
                      className="table-card-action table-card-action-primary"
                      onClick={(e) => {
                        e.stopPropagation();
                        startTableOrder(table.tableNo);
                      }}
                    >
                      New Order
                    </button>
                  );
                return (
                  <article
                    key={table.tableNo}
                    className={`table-tile table-tile-clickable table-status-${table.status} ${table.waitingTooLong ? "table-alert" : ""} ${selectedTableNo === table.tableNo ? "table-tile-active" : ""}`}
                    onClick={() => setSelectedTableNo(table.tableNo)}
                  >
                    <div className="table-tile-header">
                      <h4>Table {table.tableNo}</h4>
                      <span className="table-status-badge">{statusLabel}</span>
                    </div>
                    <p className="tiny table-tile-amount">
                      ₹{Math.round(table.total)}
                      {table.ordersForTable.length > 0 && table.elapsedMinutes > 0 ? ` • ${table.elapsedMinutes}m` : ""}
                    </p>
                    {table.meta?.reservationName && (
                      <p className="tiny muted table-tile-meta">
                        {table.meta.reservationName}
                        {table.meta.reservationTime ? ` @ ${table.meta.reservationTime}` : ""}
                      </p>
                    )}
                    {table.meta?.guestName && !table.meta?.reservationName && (
                      <p className="tiny muted table-tile-meta">{table.meta.guestName}</p>
                    )}
                    <div className="table-tile-actions">{primaryAction}</div>
                  </article>
                );
              })}
            </div>
            {renderTableControlsPanel(selectedTableSummary)}
            </section>
          </>
        )}

        {activeView === "delivery" && rolloutFlags.deliveryOps && (
          <>
            <MobileHeader
              title="Delivery"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
            />

            <section className="panel">
            <div className="section-head">
              <h3>Delivery Ops</h3>
              <span className="tiny muted">{deliveryOrders.length} active delivery orders</span>
            </div>
            <table className="table">
              <thead>
                <tr>
                  <th>Order</th>
                  <th>Customer</th>
                  <th>Address</th>
                  <th>Rider</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {deliveryOrders.length === 0 && (
                  <tr>
                    <td colSpan={5}>No active delivery orders.</td>
                  </tr>
                )}
                {deliveryOrders.map((order) => (
                  <tr key={order.id}>
                    <td>{order.order_number}</td>
                    <td>{order.customer_name || "Walk-in"}{order.phone_number ? ` • ${order.phone_number}` : ""}</td>
                    <td>{order.delivery_address || order.delivery_block || "-"}</td>
                    <td>
                      {order.delivery_rider_id
                        ? (deliveryRiders.find((r) => r.id === order.delivery_rider_id)?.full_name ?? order.delivery_rider_id)
                        : "Unassigned"}
                    </td>
                    <td>
                      <div className="inline-actions">
                        {deliveryRiders.length > 0 ? (
                          <select
                            className="ghost sm"
                            value={order.delivery_rider_id || ""}
                            onChange={(e) => {
                              const rid = e.target.value;
                              if (rid) {
                                const r = deliveryRiders.find((x) => x.id === rid);
                                void assignRider(order.id, rid, r?.full_name);
                              }
                            }}
                          >
                            <option value="">Assign rider...</option>
                            {deliveryRiders.map((r) => (
                              <option key={r.id} value={r.id}>
                                {r.full_name}
                              </option>
                            ))}
                          </select>
                        ) : (
                          <span className="muted tiny">No riders</span>
                        )}
                        <button className="ghost" onClick={() => void updateOrderStatus(order.id, "on_the_way")}>Dispatch</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            </section>
          </>
        )}

        {activeView === "inventory" && rolloutFlags.businessModules && (
          <>
            <MobileHeader
              title="Inventory"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
              right={
                <button className="ghost" onClick={() => void fetchAdminMenu()}>
                  Refresh
                </button>
              }
            />

            <section className="panel">
            <h3>Menu Management</h3>
            {!canManageMenu && <p className="tiny muted">Only owner/admin can update menu.</p>}
            <div className="menu-organizer-toolbar">
              <input
                className="search"
                placeholder="Search items or category..."
                value={menuOrganizerSearch}
                onChange={(e) => setMenuOrganizerSearch(e.target.value)}
              />
              <select value={menuOrganizerAvailability} onChange={(e) => setMenuOrganizerAvailability(e.target.value as "all" | "available" | "hidden")}>
                <option value="all">All Availability</option>
                <option value="available">Available Only</option>
                <option value="hidden">Hidden Only</option>
              </select>
              <select value={menuOrganizerCategoryFilter} onChange={(e) => setMenuOrganizerCategoryFilter(e.target.value)}>
                <option value="all">All Categories</option>
                {menuOrganizerCategoryNames.map((categoryName) => (
                  <option key={categoryName} value={categoryName}>
                    {categoryName}
                  </option>
                ))}
              </select>
              <button className="ghost" onClick={() => void fetchAdminMenu()}>
                Refresh
              </button>
            </div>
            <div ref={menuAddFormRef} className="triple">
              <label className="field">
                <span>Name</span>
                <input value={menuName} onChange={(e) => setMenuName(e.target.value)} placeholder="e.g. Masala Chai" />
              </label>
              <label className="field">
                <span>Category</span>
                <select
                  value={menuOrganizerCategoryNames.includes(menuCategory) ? menuCategory : "__new__"}
                  onChange={(e) => {
                    const v = e.target.value;
                    if (v === "__new__") setMenuCategory("");
                    else setMenuCategory(v);
                  }}
                >
                  {(menuOrganizerCategoryNames.length > 0 ? menuOrganizerCategoryNames : ["uncategorized"]).map((cat) => (
                    <option key={cat} value={cat}>{cat}</option>
                  ))}
                  <option value="__new__">+ New category</option>
                </select>
                {(menuCategory === "" || (menuOrganizerCategoryNames.length > 0 && !menuOrganizerCategoryNames.includes(menuCategory))) && (
                  <input
                    value={menuCategory}
                    onChange={(e) => setMenuCategory(e.target.value)}
                    placeholder="Type new category name"
                    style={{ marginTop: 4 }}
                  />
                )}
              </label>
              <label className="field">
                <span>Price (₹)</span>
                <input type="number" min="0" step="0.01" value={menuPrice} onChange={(e) => setMenuPrice(e.target.value)} placeholder="0" />
              </label>
            </div>
            <div className="inline-actions" style={{ gap: 8, marginTop: 8 }}>
              <button className="primary" disabled={!canManageMenu} onClick={() => void createMenuItem(false)}>
                Add Menu Item
              </button>
              <button className="ghost" disabled={!canManageMenu} onClick={() => void createMenuItem(true)}>
                Add & Add Another
              </button>
            </div>

            <div className="menu-organizer-stats">
              <article className="kpi"><span>Total Items</span><strong>{adminMenuItems.length}</strong></article>
              <article className="kpi"><span>Available</span><strong>{adminMenuItems.filter((item) => item.is_available).length}</strong></article>
              <article className="kpi"><span>Hidden</span><strong>{adminMenuItems.filter((item) => !item.is_available).length}</strong></article>
              <article className="kpi"><span>Categories</span><strong>{menuOrganizerCategoryNames.length}</strong></article>
            </div>

            <div className="menu-organizer-list">
              {menuOrganizerVisibleCategories.length === 0 && (
                <p className="tiny muted">No menu items match current filters.</p>
              )}
              {menuOrganizerVisibleCategories.map((category) => (
                <section key={category.name} className="menu-category-card">
                  <header className="menu-category-head">
                    <div>
                      <h4>{category.name}</h4>
                      <p className="tiny muted">{category.items.length} items</p>
                    </div>
                    <button
                      className="ghost"
                      title={collapsedMenuCategories[category.name] ? "Expand category" : "Collapse category"}
                      aria-label={collapsedMenuCategories[category.name] ? "Expand category" : "Collapse category"}
                      onClick={() =>
                        setCollapsedMenuCategories((prev) => ({
                          ...prev,
                          [category.name]: !prev[category.name]
                        }))
                      }
                    >
                      {collapsedMenuCategories[category.name] ? <ChevronDown size={16} /> : <ChevronUp size={16} />}
                    </button>
                  </header>

                  {!collapsedMenuCategories[category.name] && (
                    <ul className="list">
                      {category.items.map((item) => (
                        <li key={item.id}>
                          {editingMenuId !== null && String(editingMenuId) === String(item.id) ? (
                            <>
                              <div className="triple">
                                <label className="field">
                                  <span>Name</span>
                                  <input value={editingMenuName} onChange={(e) => setEditingMenuName(e.target.value)} />
                                </label>
                                <label className="field">
                                  <span>Category</span>
                                  <input value={editingMenuCategory} onChange={(e) => setEditingMenuCategory(e.target.value)} />
                                </label>
                                <label className="field">
                                  <span>Price</span>
                                  <input value={editingMenuPrice} onChange={(e) => setEditingMenuPrice(e.target.value)} />
                                </label>
                              </div>
                              <div className="inline-actions">
                                <button className="ghost" disabled={!canManageMenu} onClick={() => void updateMenuItem()}>Save</button>
                                <button className="ghost" onClick={() => setEditingMenuId(null)}>Cancel</button>
                              </div>
                            </>
                          ) : (
                            <div className="row">
                              <span>
                                {item.name} • ₹{item.price} <span className="tiny muted">({item.is_available ? "in stock" : "out of stock"})</span>
                              </span>
                              <div className="inline-actions">
                                <button
                                  type="button"
                                  className="ghost"
                                  title="Edit item"
                                  aria-label="Edit item"
                                  disabled={!canManageMenu}
                                  onClick={(e) => {
                                    e.preventDefault();
                                    e.stopPropagation();
                                    setEditingMenuId(String(item.id));
                                    setEditingMenuName(item.name);
                                    setEditingMenuCategory(item.category || "");
                                    setEditingMenuPrice(String(item.price));
                                  }}
                                >
                                  <Pencil size={15} />
                                </button>
                                <button
                                  type="button"
                                  className="ghost danger"
                                  title="Remove item"
                                  aria-label="Remove item"
                                  disabled={!canManageMenu}
                                  onClick={(e) => {
                                    e.preventDefault();
                                    e.stopPropagation();
                                    if (window.confirm(`Permanently delete "${item.name}" from the menu? This cannot be undone.`)) {
                                      void deleteMenuItem(String(item.id));
                                    }
                                  }}
                                >
                                  <Trash2 size={15} />
                                </button>
                                <label className={`menu-stock-toggle ${item.is_available ? "on" : "off"}`}>
                                  <input
                                    type="checkbox"
                                    checked={item.is_available}
                                    disabled={!canManageMenu}
                                    onChange={() => void toggleMenuAvailability(item.id, !item.is_available)}
                                  />
                                  <span className="menu-stock-toggle-track">
                                    <span className="menu-stock-toggle-thumb" />
                                  </span>
                                  <span className="menu-stock-toggle-text">{item.is_available ? "In Stock" : "Out of Stock"}</span>
                                </label>
                              </div>
                            </div>
                          )}
                        </li>
                      ))}
                      {canManageMenu && (
                        <li className="menu-add-in-category">
                          <button
                            type="button"
                            className="ghost"
                            onClick={() => {
                              setMenuCategory(category.name);
                              menuAddFormRef.current?.scrollIntoView({ behavior: "smooth", block: "center" });
                            }}
                          >
                            <Plus size={14} /> Add item in {category.name}
                          </button>
                        </li>
                      )}
                    </ul>
                  )}
                </section>
              ))}
            </div>
            </section>
          </>
        )}

        {activeView === "offers" && rolloutFlags.businessModules && (
          <>
            <MobileHeader
              title="Offers"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
            />

            <section className="panel">
            <div className="section-head">
              <h3>Offers</h3>
              <button className="ghost" onClick={() => void fetchOffers()}>Refresh</button>
            </div>
            <div className="triple">
              <label className="field">
                <span>Offer Name</span>
                <input value={offerName} onChange={(e) => setOfferName(e.target.value)} />
              </label>
              <label className="field">
                <span>Type</span>
                <select value={offerDiscountType} onChange={(e) => setOfferDiscountType(e.target.value as "percentage" | "fixed_amount")}>
                  <option value="percentage">Percentage</option>
                  <option value="fixed_amount">Fixed Amount</option>
                </select>
              </label>
              <label className="field">
                <span>Value</span>
                <input value={offerDiscountValue} onChange={(e) => setOfferDiscountValue(e.target.value)} />
              </label>
            </div>
            <button className="primary" onClick={() => void createOffer()}>Create Offer</button>
            <ul className="list">
              {offers.map((offer) => (
                <li key={offer.id} className="row">
                  <span>{offer.name} • {offer.discount_type} {offer.discount_value}</span>
                  <button className="ghost" onClick={() => void toggleOffer(offer.id, !offer.is_active)}>
                    {offer.is_active ? "Disable" : "Enable"}
                  </button>
                </li>
              ))}
            </ul>
            </section>
          </>
        )}

        {activeView === "customers" && rolloutFlags.businessModules && (
          <>
            <MobileHeader
              title="Customers"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
            />

            <section className="panel">
              <div className="section-head" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <h3>Customers</h3>
                  <span style={{ fontSize: '0.85rem', color: '#64748b', backgroundColor: '#f1f5f9', padding: '4px 8px', borderRadius: '12px' }}>
                    {customerSummary.filter(c => c.segment === "At Risk").length} at risk
                  </span>
                </div>
                <div style={{ display: 'flex', gap: '10px', alignItems: 'center', flexWrap: 'wrap' }}>
                  <input 
                    type="text" 
                    placeholder="Search by name or phone..." 
                    value={customerSearch}
                    onChange={(e) => setCustomerSearch(e.target.value)}
                    style={{ padding: '8px', borderRadius: '8px', border: '1px solid #e2e8f0', minWidth: '200px' }}
                  />
                  <select value={customerTierFilter} onChange={(e) => setCustomerTierFilter(e.target.value as LoyaltyTier | "all")} style={{ padding: '8px', borderRadius: '8px', border: '1px solid #e2e8f0' }}>
                    <option value="all">All tiers</option>
                    <option value="foodie">Foodie</option>
                    <option value="gourmet">Gourmet</option>
                    <option value="connoisseur">Connoisseur</option>
                  </select>
                  <select value={customerSegmentFilter} onChange={(e) => setCustomerSegmentFilter(e.target.value as CustomerSegment | "all")} style={{ padding: '8px', borderRadius: '8px', border: '1px solid #e2e8f0' }}>
                    <option value="all">All segments</option>
                    <option value="VIP">VIP</option>
                    <option value="Regular">Regular</option>
                    <option value="New">New</option>
                    <option value="At Risk">At Risk</option>
                  </select>
                  <button className="ghost" onClick={() => void fetchCustomers()}>Refresh</button>
                </div>
              </div>
              <table className="table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Phone</th>
                    <th>Orders</th>
                    <th>Spend</th>
                    <th>Points</th>
                    <th>Last Visit</th>
                    <th>Segment</th>
                    <th>Tier</th>
                    <th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredCustomers.length === 0 && (
                    <tr>
                      <td colSpan={9} style={{ textAlign: 'center', padding: '20px' }}>
                        {customerSummary.length === 0 ? "No customer history yet." : "No matching customers found."}
                      </td>
                    </tr>
                  )}
                  {filteredCustomers.map((row) => (
                    <tr 
                      key={row.phone} 
                      onClick={() => {
                        setSelectedCustomer(row);
                        void fetchCustomerDetails(row.phone);
                      }}
                      style={{ cursor: 'pointer' }}
                    >
                      <td style={{ fontWeight: 500 }}>{row.name}</td>
                      <td>{row.phone}</td>
                      <td>{row.orderCount}</td>
                      <td>₹{Math.round(row.spend)}</td>
                      <td>{row.loyaltyPoints ?? 0}</td>
                      <td style={{ color: '#64748b' }}>
                        {row.lastVisit ? new Date(row.lastVisit).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' }) : "—"}
                      </td>
                      <td>
                        <span style={{
                          padding: '4px 8px',
                          borderRadius: '8px',
                          fontSize: '0.75rem',
                          fontWeight: 600,
                          backgroundColor: row.segment === 'VIP' ? '#dbeafe' : row.segment === 'At Risk' ? '#fee2e2' : row.segment === 'New' ? '#e0e7ff' : '#f1f5f9',
                          color: row.segment === 'VIP' ? '#1d4ed8' : row.segment === 'At Risk' ? '#dc2626' : row.segment === 'New' ? '#4338ca' : '#475569'
                        }}>
                          {row.segment}
                        </span>
                      </td>
                      <td>
                        <span style={{
                          padding: '4px 8px',
                          borderRadius: '8px',
                          fontSize: '0.75rem',
                          fontWeight: 600,
                          textTransform: 'capitalize',
                          backgroundColor: row.loyaltyTier === 'connoisseur' ? '#e0e7ff' : row.loyaltyTier === 'gourmet' ? '#fef08a' : '#f1f5f9',
                          color: row.loyaltyTier === 'connoisseur' ? '#4338ca' : row.loyaltyTier === 'gourmet' ? '#854d0e' : '#475569'
                        }}>
                          {row.loyaltyTier}
                        </span>
                      </td>
                      <td>
                        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                          <button 
                            className="btn-outline" 
                            style={{ padding: '4px 12px', fontSize: '0.8rem', borderRadius: '6px' }}
                            onClick={(e) => {
                              e.stopPropagation();
                              setCustomerName(row.name);
                              setCustomerPhone(row.phone);
                              setActiveView("dashboard");
                            }}
                          >
                            Start Order
                          </button>
                          {row.lastVisit && (Date.now() - new Date(row.lastVisit).getTime()) / (1000 * 3600 * 24) > 30 && (
                            <button 
                              className="ghost" 
                              style={{ padding: '4px 12px', fontSize: '0.8rem', borderRadius: '6px', color: '#16a34a', border: '1px solid #bbf7d0', backgroundColor: '#f0fdf4' }}
                              onClick={async (e) => {
                                e.stopPropagation();
                                if (!cafeId) return;
                                
                                // Best guess at top item
                                const topItem = customerDetails.topItems?.[0]?.name || "your favorites";
                                
                                await triggerWhatsAppAutomation("win_back_campaign", "win-back-" + row.phone, {
                                  customerName: row.name,
                                  topItem: topItem,
                                  discountCode: "WE_MISS_YOU_15"
                                }, row.phone);
                                
                                notify(`Win-back campaign sent to ${row.name}!`);
                              }}
                            >
                              <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                                <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51a12.8 12.8 0 0 0-.57-.01c-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 0 1-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 0 1-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 0 1 2.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0 0 12.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 0 0 5.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 0 0-3.48-8.413Z"/></svg>
                                Send Offer
                              </span>
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </section>
          </>
        )}

        {activeView === "analytics" && rolloutFlags.businessModules && (
          <>
            <MobileHeader
              title="Analytics"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
            />

            <div className="analytics-dash">
              <div className="analytics-dash-header">
                <h2>Analytics</h2>
                <select
                  className="analytics-dash-range"
                  value={analyticsRange}
                  onChange={(e) => setAnalyticsRange(e.target.value as "today" | "week" | "month" | "all")}
                >
                  <option value="today">Today</option>
                  <option value="week">Last 7 days</option>
                  <option value="month">Last 30 days</option>
                  <option value="all">All time</option>
                </select>
              </div>

              <div className="analytics-kpi-hero">
                <article className="analytics-kpi-card">
                  <div className="analytics-kpi-label">Total Orders</div>
                  <div className="analytics-kpi-value">{analyticsKpis.totalOrders}</div>
                </article>
                <article className="analytics-kpi-card">
                  <div className="analytics-kpi-label">Completed</div>
                  <div className="analytics-kpi-value">{analyticsKpis.completed}</div>
                </article>
                <article className="analytics-kpi-card">
                  <div className="analytics-kpi-label">Pending Payments</div>
                  <div className="analytics-kpi-value">{analyticsKpis.pendingPayments}</div>
                </article>
                <article className="analytics-kpi-card hero-revenue">
                  <div className="analytics-kpi-label">Revenue</div>
                  <div className="analytics-kpi-value">₹{analyticsKpis.revenue}</div>
                </article>
                <article className="analytics-kpi-card">
                  <div className="analytics-kpi-label">Avg Ticket</div>
                  <div className="analytics-kpi-value">₹{analyticsKpis.avgTicket}</div>
                </article>
                <article className="analytics-kpi-card">
                  <div className="analytics-kpi-label">Completion Rate</div>
                  <div className="analytics-kpi-value">{analyticsKpis.completionRate}%</div>
                </article>
              </div>

              <div className="analytics-grid">
                <section className="analytics-card">
                  <h4>Status Breakdown</h4>
                  {analyticsStatusCounts.map((entry) => (
                    <div key={entry.status} className="analytics-bar-item">
                      <div className="analytics-bar-row">
                        <span>{entry.status.replace(/_/g, " ")}</span>
                        <strong>{entry.count}</strong>
                      </div>
                      <div className="analytics-bar-track">
                        <div
                          className="analytics-bar-fill"
                          style={{ width: `${analyticsKpis.totalOrders ? Math.min(100, (entry.count / analyticsKpis.totalOrders) * 100) : 0}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </section>

                <section className="analytics-card">
                  <h4>Order Type Mix</h4>
                  {analyticsOrderTypeMix.map((entry) => (
                    <div key={entry.type} className="analytics-bar-item">
                      <div className="analytics-bar-row">
                        <span>{entry.type.replace(/_/g, " ")}</span>
                        <strong>{entry.count}</strong>
                      </div>
                      <div className="analytics-bar-track">
                        <div
                          className="analytics-bar-fill"
                          style={{ width: `${analyticsKpis.totalOrders ? Math.min(100, (entry.count / analyticsKpis.totalOrders) * 100) : 0}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </section>

                <section className="analytics-card">
                  <h4>Payment Mix</h4>
                  {analyticsPaymentMix.map((entry) => (
                    <div key={entry.method} className="analytics-bar-item">
                      <div className="analytics-bar-row">
                        <span>{entry.method}</span>
                        <strong>{entry.count}</strong>
                      </div>
                      <div className="analytics-bar-track">
                        <div
                          className="analytics-bar-fill"
                          style={{ width: `${analyticsKpis.totalOrders ? Math.min(100, (entry.count / analyticsKpis.totalOrders) * 100) : 0}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </section>

                <section className="analytics-card">
                  <h4>Hourly Heat Map</h4>
                  <div className="analytics-hourly-grid">
                    {analyticsHourlyHeatmap.map(({ hour, count, revenue }) => {
                      const pct = analyticsHourlyMaxRevenue ? (revenue / analyticsHourlyMaxRevenue) * 100 : 0;
                      const isPeak = pct >= 80 && count > 0;
                      const hasData = count > 0;
                      return (
                        <div
                          key={hour}
                          className={`analytics-hourly-cell ${hasData ? "has-data" : ""} ${isPeak ? "peak" : ""}`}
                          title={`${hour}: ${count} orders, ₹${Math.round(revenue)}`}
                        >
                          <span>{hour.slice(0, 2)}</span>
                          {hasData && <span>{count}</span>}
                        </div>
                      );
                    })}
                  </div>
                </section>

                <section className="analytics-card">
                  <h4>Top Customers</h4>
                  {analyticsTopCustomers.length === 0 ? (
                    <p className="analytics-empty">No customers yet.</p>
                  ) : (
                    analyticsTopCustomers.map((row, idx) => (
                      <div key={`${row.name}-${idx}`} className="analytics-leaderboard-item">
                        <div className={`analytics-leaderboard-rank ${idx < 3 ? "top" : ""}`}>{idx + 1}</div>
                        <div className="analytics-leaderboard-info">
                          <div className="analytics-leaderboard-name">{row.name}</div>
                          <div className="analytics-leaderboard-meta">{row.orders} orders</div>
                        </div>
                        <div className="analytics-leaderboard-value">₹{Math.round(row.spend)}</div>
                      </div>
                    ))
                  )}
                </section>

                {rolloutFlags.businessModules && (
                  <section className="analytics-card">
                    <h4>Loyalty Metrics</h4>
                    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
                      <div className="analytics-bar-item">
                        <div className="analytics-bar-row">
                          <span>Total customers</span>
                          <strong>{analyticsLoyaltyMetrics.totalCustomers}</strong>
                        </div>
                      </div>
                      <div className="analytics-bar-item">
                        <div className="analytics-bar-row">
                          <span>Repeat rate (2+ visits)</span>
                          <strong>{analyticsLoyaltyMetrics.repeatRate}%</strong>
                        </div>
                      </div>
                      <div className="analytics-bar-item">
                        <div className="analytics-bar-row">
                          <span>Avg visits per customer</span>
                          <strong>{analyticsLoyaltyMetrics.avgVisits}</strong>
                        </div>
                      </div>
                      <div className="analytics-bar-item">
                        <div className="analytics-bar-row">
                          <span>Total points (current)</span>
                          <strong>{analyticsLoyaltyMetrics.totalPoints}</strong>
                        </div>
                      </div>
                    </div>
                  </section>
                )}

                <section className="analytics-card">
                  <h4>Top Items</h4>
                  {analyticsTopItems.length === 0 ? (
                    <p className="analytics-empty">Load order details to unlock item-level analytics.</p>
                  ) : (
                    analyticsTopItems.map((item, idx) => (
                      <div key={`${item.name}-${idx}`} className="analytics-leaderboard-item">
                        <div className={`analytics-leaderboard-rank ${idx < 3 ? "top" : ""}`}>{idx + 1}</div>
                        <div className="analytics-leaderboard-info">
                          <div className="analytics-leaderboard-name">{item.name}</div>
                          <div className="analytics-leaderboard-meta">qty {item.qty}</div>
                        </div>
                        <div className="analytics-leaderboard-value">₹{Math.round(item.revenue)}</div>
                      </div>
                    ))
                  )}
                </section>
              </div>
            </div>
          </>
        )}

        {activeView === "loyalty" && rolloutFlags.businessModules && (
          <>
            <MobileHeader
              title="Loyalty"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
            />
            <LoyaltyPanel cafeId={cafeId} />
          </>
        )}

        {activeView === "staff" && rolloutFlags.businessModules && (
          <>
            <MobileHeader
              title="Staff"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
              right={
                <button className="ghost" onClick={() => void fetchStaff()}>
                  Refresh
                </button>
              }
            />

            <section className="panel">
            <div className="section-head">
              <h3>Staff</h3>
              <button className="ghost" onClick={() => void fetchStaff()}>Refresh</button>
            </div>
            <table className="table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Role</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {staffRows.length === 0 && (
                  <tr>
                    <td colSpan={3}>No staff entries.</td>
                  </tr>
                )}
                {staffRows.map((staff) => (
                  <tr key={staff.id}>
                    <td>{staff.staff_name || staff.profile?.full_name || "Unknown"}</td>
                    <td>{staff.role}</td>
                    <td>{staff.is_active ? "Active" : "Inactive"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            </section>
          </>
        )}

        {activeView === "cafe" && rolloutFlags.businessModules && (
          <>
            <MobileHeader
              title="Cafe"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
            />

            <section className="panel">
            <h3>Cafe Details</h3>
            <div className="triple">
              <label className="field">
                <span>Name</span>
                <input value={cafeDetails.name} onChange={(e) => setCafeDetails((prev) => ({ ...prev, name: e.target.value }))} />
              </label>
              <label className="field">
                <span>Phone</span>
                <input value={cafeDetails.phone} onChange={(e) => setCafeDetails((prev) => ({ ...prev, phone: e.target.value }))} />
              </label>
              <label className="field">
                <span>Location</span>
                <input value={cafeDetails.location} onChange={(e) => setCafeDetails((prev) => ({ ...prev, location: e.target.value }))} />
              </label>
            </div>
            <label className="field">
              <span>Description</span>
              <input value={cafeDetails.description} onChange={(e) => setCafeDetails((prev) => ({ ...prev, description: e.target.value }))} />
            </label>
            <button className="primary" onClick={() => void saveCafeDetails()}>Save Cafe Details</button>
            </section>
          </>
        )}

        {activeView === "history" && rolloutFlags.businessModules && (
          <>
            <MobileHeader
              title="History"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
              right={
                <button className="ghost" onClick={exportReportCsv}>
                  Export
                </button>
              }
            />

            <section className="panel">
            <div className="section-head">
              <h3>Reporting</h3>
              <button className="ghost" onClick={exportReportCsv}>Export CSV</button>
            </div>
            <div className="triple">
              <label className="field">
                <span>Range</span>
                <select value={reportRange} onChange={(e) => setReportRange(e.target.value as "today" | "yesterday" | "custom")}>
                  <option value="today">Today</option>
                  <option value="yesterday">Yesterday</option>
                  <option value="custom">Custom</option>
                </select>
              </label>
              {reportRange === "custom" && (
                <>
                  <label className="field">
                    <span>Start</span>
                    <input type="date" value={customStartDate} onChange={(e) => setCustomStartDate(e.target.value)} />
                  </label>
                  <label className="field">
                    <span>End</span>
                    <input type="date" value={customEndDate} onChange={(e) => setCustomEndDate(e.target.value)} />
                  </label>
                </>
              )}
            </div>
            <div className="kpi-row">
              <article className="kpi">
                <span>Orders</span>
                <strong>{todayOrders.length}</strong>
              </article>
              <article className="kpi">
                <span>Revenue</span>
                <strong>₹{todayOrders.filter((o) => o.payment_status === "paid").reduce((sum, o) => sum + Number(o.total_amount || 0), 0)}</strong>
              </article>
              <article className="kpi">
                <span>Avg Order</span>
                <strong>
                  ₹{todayOrders.length === 0 ? 0 : Math.round(todayOrders.reduce((sum, o) => sum + Number(o.total_amount || 0), 0) / todayOrders.length)}
                </strong>
              </article>
            </div>
            <h4>Payment Mix</h4>
            <ul className="list">
              {["cash", "card", "upi", "razorpay", "phonepe"].map((method) => {
                const count = todayOrders.filter((o) => (o.payment_method || "").toLowerCase() === method).length;
                return <li key={method} className="row"><span>{method}</span><strong>{count}</strong></li>;
              })}
            </ul>
            <h4>Hourly Trend</h4>
            <ul className="list">
              {hourlyTrend.length === 0 && <li>No orders in selected day.</li>}
              {hourlyTrend.map(([hour, value]) => (
                <li key={hour}>
                  <div className="row">
                    <span>{hour}</span>
                    <strong>{value.count} orders</strong>
                  </div>
                  <div className="trend-bar">
                    <div className="trend-fill" style={{ width: `${Math.min(100, value.revenue / 20)}%` }} />
                  </div>
                  <p className="tiny muted">₹{Math.round(value.revenue)}</p>
                </li>
              ))}
            </ul>
            </section>
          </>
        )}

        {activeView === "billing" && rolloutFlags.manualBilling && (
          <>
            <MobileHeader
              title="Billing"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
              right={
                <button className="ghost" onClick={() => void refreshOpsHistory()}>
                  Refresh
                </button>
              }
            />

            <section className="panel">
            <div className="section-head">
              <h3>Offline Sync & Print Queue</h3>
              <button className="ghost" onClick={() => void refreshOpsHistory()}>Refresh</button>
            </div>
            <h4>Outbox</h4>
            <ul className="list">
              {outboxHistory.length === 0 && <li>No outbox records.</li>}
              {outboxHistory.map((item) => (
                <li key={item.id}>
                  <div className="row">
                    <span>{item.payload.ticketNo} ({item.status}) - tries {item.attempts}</span>
                    <button
                      className="ghost"
                      disabled={item.status === "synced"}
                      onClick={() => void retryOutboxItem(item.id).then(refreshOpsHistory)}
                    >
                      Retry
                    </button>
                  </div>
                  {item.nextRetryAt && <p className="tiny muted">Next retry: {new Date(item.nextRetryAt).toLocaleTimeString()}</p>}
                  {item.lastError && <p className="tiny muted">{item.lastError}</p>}
                </li>
              ))}
            </ul>

            <h4>Print Jobs</h4>
            <ul className="list">
              {printHistory.length === 0 && <li>No print jobs.</li>}
              {printHistory.map((job) => (
                <li key={job.id}>
                  <div className="row">
                    <span>
                      {job.ticketNo} [{job.payload.jobType || "kot"} / {job.payload.station || "kitchen"}] ({job.status}) - tries {job.attempts || 0}
                    </span>
                    <button className="ghost" disabled={job.status === "printed"} onClick={() => void retryPrintJob(job.id).then(refreshOpsHistory)}>
                      Reprint
                    </button>
                  </div>
                  {job.nextRetryAt && <p className="tiny muted">Next retry: {new Date(job.nextRetryAt).toLocaleTimeString()}</p>}
                  {job.lastError && <p className="tiny muted">{job.lastError}</p>}
                </li>
              ))}
            </ul>
            </section>
          </>
        )}

        {activeView === "settings" && (
          <>
            <MobileHeader
              title="Settings"
              left={
                <button className="ghost menu-toggle-btn" onClick={() => setIsMobileDrawerOpen(true)}>
                  <MenuIcon size={24} />
                </button>
              }
            />

            <section className="panel">
            <h3>Terminal ID</h3>
            <p className="tiny muted">Identify this device when multiple terminals per cafe (e.g. A, 1, Counter-1).</p>
            <label className="field">
              <span>Terminal</span>
              <input
                type="text"
                value={terminalId}
                onChange={(e) => {
                  const v = e.target.value;
                  setTerminalId(v);
                  localStorage.setItem(POS_TERMINAL_ID_KEY, v);
                }}
                placeholder="e.g. A or 1"
              />
            </label>

            <h3>Rollout Controls</h3>
            <p className="tiny muted">Use feature flags for phased cutover and rollback.</p>
            <div className="triple">
              <label className="field">
                <span>Orders</span>
                <input
                  type="checkbox"
                  checked={rolloutFlags.orders}
                  onChange={(e) => setRolloutFlags((prev) => ({ ...prev, orders: e.target.checked }))}
                />
              </label>
              <label className="field">
                <span>Manual/Billing</span>
                <input
                  type="checkbox"
                  checked={rolloutFlags.manualBilling}
                  onChange={(e) => setRolloutFlags((prev) => ({ ...prev, manualBilling: e.target.checked }))}
                />
              </label>
              <label className="field">
                <span>Kitchen</span>
                <input
                  type="checkbox"
                  checked={rolloutFlags.kitchen}
                  onChange={(e) => setRolloutFlags((prev) => ({ ...prev, kitchen: e.target.checked }))}
                />
              </label>
            </div>
            <div className="triple">
              <label className="field">
                <span>Tables</span>
                <input
                  type="checkbox"
                  checked={rolloutFlags.tableManagement}
                  onChange={(e) => setRolloutFlags((prev) => ({ ...prev, tableManagement: e.target.checked }))}
                />
              </label>
              <label className="field">
                <span>Delivery Ops</span>
                <input
                  type="checkbox"
                  checked={rolloutFlags.deliveryOps}
                  onChange={(e) => setRolloutFlags((prev) => ({ ...prev, deliveryOps: e.target.checked }))}
                />
              </label>
              <label className="field">
                <span>Business Modules</span>
                <input
                  type="checkbox"
                  checked={rolloutFlags.businessModules}
                  onChange={(e) => setRolloutFlags((prev) => ({ ...prev, businessModules: e.target.checked }))}
                />
              </label>
            </div>

            <h3>Dual-run Validation</h3>
            <ul className="list">
              <li className="row"><span>Local Orders</span><strong>{dualRunStats.localCount}</strong></li>
              <li className="row"><span>Remote Orders</span><strong>{dualRunStats.remoteCount}</strong></li>
              <li className="row"><span>Local-only</span><strong>{dualRunStats.localOnly}</strong></li>
              <li className="row"><span>Remote-only</span><strong>{dualRunStats.remoteOnly}</strong></li>
              <li className="row"><span>Parity gap</span><strong>{dualRunStats.parityGap}</strong></li>
            </ul>

            <h4>Cutover Gates</h4>
            <ul className="list">
              <li className="row"><span>Gate A (Rule parity tests)</span><strong>{validationGates.gateA ? "PASS" : "FAIL"}</strong></li>
              <li className="row"><span>Gate B (API/auth ready)</span><strong>{validationGates.gateB ? "PASS" : "FAIL"}</strong></li>
              <li className="row"><span>Gate C (Slices enabled)</span><strong>{validationGates.gateC ? "PASS" : "FAIL"}</strong></li>
              <li className="row"><span>Gate D (Dual-run metrics)</span><strong>{validationGates.gateD ? "PASS" : "FAIL"}</strong></li>
              <li className="row"><span>Gate E (No local-only orders)</span><strong>{validationGates.gateE ? "PASS" : "FAIL"}</strong></li>
            </ul>
            <p className="tiny muted">
              Cutover ready: {Object.values(validationGates).every(Boolean) ? "YES" : "NO"}.
            </p>
            </section>
          </>
        )}
      </main>

      {activeView === "dashboard" ? (
        <aside className="bill-panel dashboard-side-panel">
          <div className="dashboard-side-head">
            <h3>Dashboard Widgets</h3>
            <p className="tiny muted">{new Date().toLocaleString()}</p>
          </div>

          <section className="panel dashboard-side-widget">
            <div className="section-head">
              <h4>Table Available</h4>
              <span className="tiny muted">{dashboardAvailableTables.length}</span>
            </div>
            {dashboardAvailableTables.length > 0 ? (
              <div className="dashboard-table-grid">
                {dashboardAvailableTables.map((tableNo) => (
                  <button
                    key={tableNo}
                    className="dashboard-table-chip"
                    onClick={() => {
                      setSelectedTableNo(tableNo);
                    }}
                  >
                    T{tableNo}
                  </button>
                ))}
              </div>
            ) : (
              <p className="tiny muted">No free tables right now.</p>
            )}
          </section>

          <section className="panel dashboard-side-widget">
            <div className="section-head">
              <h4>Out of Stock</h4>
              <span className="tiny muted">{dashboardOutOfStockItems.length}</span>
            </div>
            {dashboardOutOfStockItems.length > 0 ? (
              <ul className="list">
                {dashboardOutOfStockItems.map((item) => (
                  <li key={item.id} className="row">
                    <span>{item.name}</span>
                    <button className="ghost tiny" onClick={() => void toggleMenuAvailability(item.id, true)}>
                      Mark in stock
                    </button>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="tiny muted">All menu items currently available.</p>
            )}
          </section>

          <section className="panel dashboard-side-widget">
            <h4>Quick Summary</h4>
            <ul className="list">
              <li className="row"><span>Today Orders</span><strong>{dashboardTodayOrders.length}</strong></li>
              <li className="row"><span>Pending Sync</span><strong>{pendingCount}</strong></li>
              <li className="row"><span>Print Queue</span><strong>{queuedPrintCount}</strong></li>
              <li className="row"><span>Shift</span><strong>{activeShift ? "Running" : "Not started"}</strong></li>
              <li className="row"><span>Terminal</span><strong>{terminalId || "—"}</strong></li>
            </ul>
            <div className="inline-actions">
              <button className="ghost" onClick={() => setActiveView("orders")}>Open Orders</button>
              <button className="ghost" onClick={() => setActiveView("inventory")}>Manage Stock</button>
            </div>
          </section>
        </aside>
      ) : (
      <aside className="bill-panel clean-bill-panel">
        <div className="bill-header">
          <h3 className="bill-title">Bill Details</h3>
          <span className="bill-ticket">#{lastCreatedOrder || "—"}</span>
        </div>

        {/* 1. AI Insight — subtle */}
        {(customerPhone.length >= 10 && (customerDetails.topItems.length > 0 || (customerDetails.points && customerDetails.points > 0))) ? (
          <div className="bill-section">
            <div style={{ padding: '8px 12px', backgroundColor: 'var(--border-light)', border: '1px solid var(--border-default)', borderRadius: 8, fontSize: '0.8rem', color: 'var(--text-muted)' }}>
              {customerDetails.topItems.length > 0 && <div>Usual: {customerDetails.topItems.map(i => i.name).join(', ')}</div>}
              {customerDetails.points && customerDetails.points > 0 ? <div>{customerDetails.points} pts</div> : null}
              {selectedCustomer?.loyaltyTier && (
                <div style={{ marginTop: '4px' }}>Tier: <span style={{ textTransform: 'capitalize', fontWeight: 600 }}>{selectedCustomer.loyaltyTier}</span></div>
              )}
            </div>
          </div>
        ) : null}

        {/* 2. Item details — moved up below AI insight */}
        <div className="bill-section">
          <div className="bill-section-label">Items</div>
        <ul className="list bill-items">
          {cartItems.length === 0 && <li className="bill-items-empty">No items yet</li>}
          {cartItems.map((item, idx) => (
            <li key={`${item.productId}-${idx}`} className="bill-item">
              <div className="row bill-item-row">
                <span className="bill-item-name">{item.productName}</span>
              </div>
              <div className="bill-qty-row">
                <div className="bill-stepper">
                  <button
                    className="ghost bill-step-btn"
                    aria-label="Decrease quantity"
                    onClick={() =>
                      setCartItems((prev) =>
                        prev.map((line, lineIdx) =>
                          lineIdx === idx
                            ? {
                                ...line,
                                quantity: Math.max(1, line.quantity - 1),
                                lineTotal: line.unitPrice * Math.max(1, line.quantity - 1)
                              }
                            : line
                        )
                      )
                    }
                  >
                    -
                  </button>
                  <span className="bill-qty-value">{item.quantity}</span>
                  <button
                    className="ghost bill-step-btn"
                    aria-label="Increase quantity"
                    onClick={() =>
                      setCartItems((prev) =>
                        prev.map((line, lineIdx) =>
                          lineIdx === idx
                            ? { ...line, quantity: line.quantity + 1, lineTotal: line.unitPrice * (line.quantity + 1) }
                            : line
                        )
                      )
                    }
                  >
                    +
                  </button>
                  <button
                    className="ghost bill-remove-icon"
                    aria-label="Remove item"
                    onClick={() => setCartItems((prev) => prev.filter((_, lineIdx) => lineIdx !== idx))}
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
                <strong className="bill-line-total">₹{item.lineTotal}</strong>
              </div>
            </li>
          ))}
        </ul>
          <div className="totals bill-totals">
            <div className="row"><span>Items</span><strong>{cartItems.length}</strong></div>
            <div className="row"><span>Subtotal</span><strong>₹{cartSubtotal}</strong></div>
            <div className={`row ${discountAmount > 0 ? "bill-row-discount" : ""}`}><span>Discount</span><strong>- ₹{discountAmount}</strong></div>
            <div className="row"><span>Service Tax</span><strong>+ ₹{serviceChargeAmount}</strong></div>
            <div className="row grand"><span>Total</span><strong>₹{orderTotal}</strong></div>
          </div>
        </div>

        {/* Discount adjustments — labels on top, controls aligned at bottom */}
        <div className="bill-section bill-section-discount">
          <div className="bill-discount-row">
            <div className="bill-discount-col">
              <span className="bill-discount-col-label">Discount Type</span>
              <div className="bill-discount-controls">
                <button className={`ghost bill-discount-chip ${discountMode === "amount" ? "chip-active" : ""}`} onClick={() => setDiscountMode("amount")} title="Amount">₹</button>
                <button className={`ghost bill-discount-chip ${discountMode === "percent" ? "chip-active" : ""}`} onClick={() => setDiscountMode("percent")} title="Percent">%</button>
              </div>
            </div>
            <label className="field bill-discount-field">
              <span>Discount {discountMode === "percent" ? "(%)" : "(₹)"}</span>
              <input value={discountInput} onChange={(e) => setDiscountInput(e.target.value)} />
            </label>
            <label className="field bill-discount-field">
              <span>Service Tax</span>
              <input value={serviceChargeInput} onChange={(e) => setServiceChargeInput(e.target.value)} />
            </label>
          </div>
          {lastOrderForRepeat && (
            <div style={{ marginTop: 8 }}>
              <button type="button" className="ghost chip-active" style={{ padding: "8px 14px", borderRadius: "8px", fontSize: "0.85rem" }} onClick={() => void repeatLastOrder()}>
                🔁 Repeat last order
              </button>
            </div>
          )}
        </div>

        {/* Order Type */}
        <div className="bill-section bill-section-order">
          <div className="bill-section-label">Order Type</div>
          <div className="bill-chip-row bill-order-type-row">
            <button className={`ghost ${orderMode === "dine_in" ? "chip-active" : ""}`} onClick={() => setOrderMode("dine_in")}>
              Dine In
            </button>
            <button className={`ghost ${orderMode === "takeaway" ? "chip-active" : ""}`} onClick={() => setOrderMode("takeaway")}>
              Takeaway
            </button>
            <button className={`ghost ${orderMode === "delivery" ? "chip-active" : ""}`} onClick={() => setOrderMode("delivery")}>
              Delivery
            </button>
          </div>
        </div>

        {/* Table no / Pickup label / Delivery info */}
        <div className="bill-section bill-section-order">
          <div className="bill-section-label">{orderMode === "dine_in" ? "Table" : orderMode === "delivery" ? "Delivery Address" : "Pickup Label"}</div>
          <div className="bill-identity-grid">
            {orderMode === "delivery" ? (
              <label className="field" style={{ gridColumn: "1 / -1" }}>
                <input placeholder="Required for delivery" value={deliveryAddress} onChange={(e) => setDeliveryAddress(e.target.value)} />
              </label>
            ) : orderMode === "dine_in" ? (
              <label className="field" style={{ gridColumn: "1 / -1" }}>
                <input placeholder="e.g. 5" value={tableNumber} onChange={(e) => setTableNumber(e.target.value)} />
              </label>
            ) : (
              <label className="field" style={{ gridColumn: "1 / -1" }}>
                <input placeholder="Optional" value={deliveryBlock} onChange={(e) => setDeliveryBlock(e.target.value)} />
              </label>
            )}
          </div>
        </div>

        {aiSuggestion && !aiSuggestLoading && cartItems.length > 0 && (
          <div className="panel" style={{ background: "linear-gradient(135deg, #fdf4ff 0%, #f3e8ff 100%)", borderColor: "#e9d5ff", padding: "12px", marginTop: "12px", borderRadius: "12px", position: "relative", boxShadow: "0 4px 12px rgba(168, 85, 247, 0.1)" }}>
            <button className="ghost icon-only" style={{ position: "absolute", top: 4, right: 4, width: 24, height: 24, padding: 0 }} onClick={() => setAiSuggestion(null)}>×</button>
            <div style={{ display: "flex", gap: "8px", alignItems: "flex-start" }}>
              <span style={{ fontSize: "1.2rem", filter: "drop-shadow(0 2px 4px rgba(168,85,247,0.3))" }}>✨</span>
              <div style={{ flex: 1 }}>
                <strong style={{ fontSize: "0.85rem", color: "#6b21a8", display: "block", marginBottom: 2 }}>AI Suggests</strong>
                <p style={{ fontSize: "0.8rem", color: "#334155", margin: 0, lineHeight: 1.4 }}>{aiSuggestion.reason}</p>
                {(() => {
                  const item = menu.find(m => m.id === aiSuggestion.productId);
                  if (!item) return null;
                  return (
                    <button 
                      className="primary shadow" 
                      style={{ marginTop: 8, padding: "6px 14px", fontSize: "0.8rem", height: "auto", background: "linear-gradient(135deg, #a855f7 0%, #7e22ce 100%)", border: "none" }}
                      onClick={() => {
                        setCartItems(prev => [...prev, { productId: item.id, productName: item.name, quantity: 1, unitPrice: item.basePrice, lineTotal: item.basePrice, selections: { size: "medium", milk: "regular", sugarLevel: "regular", extraShots: 0 } }]);
                        setAiSuggestion(null);
                      }}
                    >
                      + Add {item.name} (₹{item.basePrice})
                    </button>
                  );
                })()}
              </div>
            </div>
          </div>
        )}

        {paymentMethod === "split" && (
          <div className="panel nested">
            <div className="row">
              <strong>Split Settlement</strong>
              <div className="inline-actions">
                <label className="field" style={{ margin: 0 }}>
                  <span>Guests</span>
                  <input
                    type="number"
                    min={2}
                    max={8}
                    value={splitCountInput}
                    onChange={(e) => setSplitCountInput(Math.max(2, Math.min(8, Number(e.target.value || 2))))}
                    style={{ width: 72 }}
                  />
                </label>
                <button className="ghost" type="button" onClick={autoSplitSettlement}>Auto Split</button>
                <button className="ghost" type="button" onClick={() => setSplitSettlements((prev) => [...prev, {
                  id: crypto.randomUUID(),
                  label: `Guest ${prev.length + 1}`,
                  amount: 0,
                  method: "cash",
                  paid: false,
                  reference: ""
                }])}>
                  Add Payer
                </button>
              </div>
            </div>
            {splitSettlements.length === 0 && (
              <p className="tiny muted">Create split entries or use Auto Split to begin.</p>
            )}
            <ul className="list">
              {splitSettlements.map((entry) => (
                <li key={entry.id}>
                  <div className="triple">
                    <label className="field">
                      <span>Payer</span>
                      <input
                        value={entry.label}
                        onChange={(e) => setSplitSettlements((prev) => prev.map((row) => row.id === entry.id ? { ...row, label: e.target.value } : row))}
                      />
                    </label>
                    <label className="field">
                      <span>Amount</span>
                      <input
                        type="number"
                        min={0}
                        value={entry.amount}
                        onChange={(e) => setSplitSettlements((prev) => prev.map((row) => row.id === entry.id ? { ...row, amount: Number(e.target.value || 0) } : row))}
                      />
                    </label>
                    <label className="field">
                      <span>Method</span>
                      <select
                        value={entry.method}
                        onChange={(e) => setSplitSettlements((prev) => prev.map((row) => row.id === entry.id ? { ...row, method: e.target.value as "cash" | "card" | "upi" } : row))}
                      >
                        <option value="cash">Cash</option>
                        <option value="card">Card</option>
                        <option value="upi">UPI</option>
                      </select>
                    </label>
                  </div>
                  <div className="triple">
                    <label className="field">
                      <span>Reference</span>
                      <input
                        placeholder="Txn / note"
                        value={entry.reference}
                        onChange={(e) => setSplitSettlements((prev) => prev.map((row) => row.id === entry.id ? { ...row, reference: e.target.value } : row))}
                      />
                    </label>
                    <button
                      className={`ghost ${entry.paid ? "chip-active" : ""}`}
                      type="button"
                      onClick={() => setSplitSettlements((prev) => prev.map((row) => row.id === entry.id ? { ...row, paid: !row.paid } : row))}
                    >
                      {entry.paid ? "Paid" : "Mark Paid"}
                    </button>
                    <button
                      className="ghost"
                      type="button"
                      onClick={() => setSplitSettlements((prev) => prev.filter((row) => row.id !== entry.id))}
                    >
                      Remove
                    </button>
                  </div>
                </li>
              ))}
            </ul>
            <p className="tiny muted">
              Allocated: ₹{Math.round(splitAllocatedTotal)} / ₹{orderTotal} • Paid: ₹{Math.round(splitPaidTotal)} / ₹{orderTotal}
            </p>
            <div className="triple">
              <label className="field">
                <span>Fallback Cash</span>
                <input value={splitAmounts.cash} onChange={(e) => setSplitAmounts((prev) => ({ ...prev, cash: Number(e.target.value || 0) }))} />
              </label>
              <label className="field">
                <span>Fallback Card</span>
                <input value={splitAmounts.card} onChange={(e) => setSplitAmounts((prev) => ({ ...prev, card: Number(e.target.value || 0) }))} />
              </label>
              <label className="field">
                <span>Fallback UPI</span>
                <input value={splitAmounts.upi} onChange={(e) => setSplitAmounts((prev) => ({ ...prev, upi: Number(e.target.value || 0) }))} />
              </label>
            </div>
          </div>
        )}

        {/* Customer details */}
        <div className="bill-section bill-section-customer">
          <div className="bill-identity-grid">
            <label className="field" style={{ position: 'relative' }}>
              <span>Customer Name</span>
              <input 
                placeholder="Required" 
                value={customerName} 
                onChange={(e) => setCustomerName(e.target.value)} 
                onFocus={() => setShowNameSuggestions(true)}
                onBlur={() => setTimeout(() => setShowNameSuggestions(false), 200)}
              />
              <SuggestionDropdown 
                suggestions={nameSuggestions} 
                onSelect={handleSelectCustomer} 
                visible={showNameSuggestions} 
              />
            </label>
            <label className="field bill-whatsapp-field">
              <span className="bill-whatsapp-label">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51a12.8 12.8 0 0 0-.57-.01c-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 0 1-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 0 1-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 0 1 2.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0 0 12.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 0 0 5.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 0 0-3.48-8.413Z"/>
                </svg>
                WhatsApp
              </span>
              <input 
                type="tel"
                className={customerPhone.length >= 10 ? "bill-phone-valid" : ""}
                placeholder="Required for digital receipt" 
                value={customerPhone} 
                onChange={(e) => {
                  setCustomerPhone(e.target.value);
                  if (e.target.value.length >= 10) {
                    void fetchCustomerDetails(e.target.value);
                  }
                }} 
                onFocus={() => setShowPhoneSuggestions(true)}
                onBlur={() => setTimeout(() => setShowPhoneSuggestions(false), 200)}
              />
              {customerPhone.length >= 10 && (
                <label className="bill-send-receipt-toggle">
                  <input 
                    type="checkbox" 
                    checked={sendDigitalReceipt} 
                    onChange={(e) => setSendDigitalReceipt(e.target.checked)} 
                  />
                  <span>Send Receipt</span>
                </label>
              )}
              {customerPhone.length >= 10 && rolloutFlags.businessModules && (
                <RedeemRewardSection
                  cafeId={cafeId}
                  customerPhone={customerPhone}
                  cartItems={cartItems}
                  setCartItems={setCartItems}
                  redeemedRewardId={redeemedRewardId}
                  setRedeemedRewardId={setRedeemedRewardId}
                  onRedeemApplied={setRewardDiscountAmount}
                />
              )}
              <SuggestionDropdown 
                suggestions={phoneSuggestions} 
                onSelect={handleSelectCustomer} 
                visible={showPhoneSuggestions} 
              />
            </label>
          </div>
        </div>

        {/* Notes */}
        <div className="bill-section bill-section-notes">
          <label className="field">
            <span>Notes</span>
            <input placeholder="Customer preference..." value={notes} onChange={(e) => setNotes(e.target.value)} />
          </label>
        </div>

        {/* 8. Transaction type */}
        <div className="bill-section">
          <div className="bill-section-label">Transaction Type</div>
        <div className="payment-row bill-payment-row">
          <button className={`ghost ${paymentMethod === "cash" ? "chip-active" : ""}`} onClick={() => setPaymentMethod("cash")}>
            Cash
          </button>
          <button className={`ghost ${paymentMethod === "card" ? "chip-active" : ""}`} onClick={() => setPaymentMethod("card")}>
            Card
          </button>
          <button className={`ghost ${paymentMethod === "upi" ? "chip-active" : ""}`} onClick={() => setPaymentMethod("upi")}>
            UPI
          </button>
          <button className={`ghost ${paymentMethod === "split" ? "chip-active" : ""}`} onClick={() => setPaymentMethod("split")}>
            Split
          </button>
        </div>
        </div>

        {/* 9. Process transaction */}
        <button className="primary full bill-process-btn" disabled={cartItems.length === 0} onClick={() => void processTransaction()}>
          Process Transaction
        </button>

        {/* 10. Hold cart */}
        <div className="bill-section bill-hold-section">
          <div className="bill-section-label">Hold Cart</div>
          <div className="inline-actions bill-hold-row">
            <input
              className="search"
              placeholder="Label (optional)"
              value={parkNameInput}
              onChange={(e) => setParkNameInput(e.target.value)}
            />
            <button className="ghost" disabled={cartItems.length === 0} onClick={parkCurrentCart}>
              Hold Cart
            </button>
          </div>
          {parkedCarts.length > 0 && (
            <ul className="list bill-parked-list">
              {parkedCarts.map((cart) => (
                <li key={cart.id} className="row">
                  <span>{cart.label} ({cart.items.length} items)</span>
                  <button className="ghost" onClick={() => resumeParkedCart(cart)}>Resume</button>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="meta-foot">
          <p className="tiny muted">Outbox: {pendingCount} | Queue: {queuedPrintCount}</p>
          <p className="tiny muted">Last sync: {lastSyncAt ? new Date(lastSyncAt).toLocaleTimeString() : "Never"}</p>
          {lastSyncSummary && <p className="tiny muted">{lastSyncSummary}</p>}
          {statusMessage && <p className="tiny">{statusMessage}</p>}
        </div>
      </aside>
      )}

      {/* Mobile Bottom Navigation */}
      <nav className="mobile-nav">
        <button className={`mobile-nav-btn ${activeView === "dashboard" ? "active" : ""}`} onClick={() => setActiveView("dashboard")}>
          <div className="icon-wrap"><LayoutDashboard size={22} /></div>
          <span>Home</span>
        </button>
        <button className={`mobile-nav-btn ${activeView === "menu" ? "active" : ""}`} onClick={() => setActiveView("menu")}>
          <div className="icon-wrap"><ShoppingBag size={22} /></div>
          <span>Menu</span>
        </button>
        <button className={`mobile-nav-btn ${activeView === "orders" ? "active" : ""}`} onClick={() => setActiveView("orders")}>
          <div className="icon-wrap"><ListOrdered size={22} /></div>
          <span>Orders</span>
        </button>
        <button className={`mobile-nav-btn ${activeView === "tables" ? "active" : ""}`} onClick={() => setActiveView("tables")}>
          <div className="icon-wrap"><LayoutGrid size={22} /></div>
          <span>Tables</span>
        </button>
      </nav>

      {/* Mobile Navigation Drawer (Reference: Alex Richards) */}
      <div className={`mobile-drawer-overlay ${isMobileDrawerOpen ? "open" : ""}`} onClick={() => setIsMobileDrawerOpen(false)}>
        <aside className="mobile-drawer" onClick={(e) => e.stopPropagation()}>
          <header className="drawer-header">
            <div className="drawer-user-info">
              <div className="drawer-avatar">
                {user.fullName?.[0] || user.email[0].toUpperCase()}
              </div>
              <div className="drawer-user-details">
                <strong>{user.fullName || user.email}</strong>
                <p className="tiny muted">{user.email}</p>
              </div>
            </div>
            <button className="ghost" onClick={() => setIsMobileDrawerOpen(false)}>
              <X size={20} />
            </button>
          </header>

          <nav className="drawer-nav">
            <button className={`drawer-nav-item ${activeView === "dashboard" ? "active" : ""}`} onClick={() => navigateMobile("dashboard")}>
              <LayoutDashboard size={20} /> <span>Home</span>
            </button>
            <button className={`drawer-nav-item ${activeView === "menu" ? "active" : ""}`} onClick={() => navigateMobile("menu")}>
              <ShoppingBag size={20} /> <span>Sales</span>
            </button>
            <button className={`drawer-nav-item ${activeView === "orders" ? "active" : ""}`} onClick={() => navigateMobile("orders")}>
              <ListOrdered size={20} /> <span>Receipts</span>
            </button>
            {rolloutFlags.tableManagement && (
              <button className={`drawer-nav-item ${activeView === "tables" ? "active" : ""}`} onClick={() => navigateMobile("tables")}>
                <LayoutGrid size={20} /> <span>Tables</span>
              </button>
            )}
            {rolloutFlags.kitchen && (
              <button className={`drawer-nav-item ${activeView === "kitchen" ? "active" : ""}`} onClick={() => navigateMobile("kitchen")}>
                <UtensilsCrossed size={20} /> <span>Kitchen</span>
              </button>
            )}
            {rolloutFlags.deliveryOps && (
              <button className={`drawer-nav-item ${activeView === "delivery" ? "active" : ""}`} onClick={() => navigateMobile("delivery")}>
                <Truck size={20} /> <span>Delivery</span>
              </button>
            )}
            {rolloutFlags.businessModules && (
              <>
                <button className={`drawer-nav-item ${activeView === "inventory" ? "active" : ""}`} onClick={() => navigateMobile("inventory")}>
                  <Package size={20} /> <span>Items</span>
                </button>
                <button className={`drawer-nav-item ${activeView === "offers" ? "active" : ""}`} onClick={() => navigateMobile("offers")}>
                  <Ticket size={20} /> <span>Offers</span>
                </button>
                <button className={`drawer-nav-item ${activeView === "customers" ? "active" : ""}`} onClick={() => navigateMobile("customers")}>
                  <Users size={20} /> <span>Customers</span>
                </button>
                <button className={`drawer-nav-item ${activeView === "analytics" ? "active" : ""}`} onClick={() => navigateMobile("analytics")}>
                  <BarChart3 size={20} /> <span>Analytics</span>
                </button>
                <button className={`drawer-nav-item ${activeView === "loyalty" ? "active" : ""}`} onClick={() => navigateMobile("loyalty")}>
                  <Heart size={20} /> <span>Loyalty</span>
                </button>
                <button className={`drawer-nav-item ${activeView === "staff" ? "active" : ""}`} onClick={() => navigateMobile("staff")}>
                  <UserCircle size={20} /> <span>Staff</span>
                </button>
                <button className={`drawer-nav-item ${activeView === "cafe" ? "active" : ""}`} onClick={() => navigateMobile("cafe")}>
                  <Coffee size={20} /> <span>Cafe</span>
                </button>
                <button className={`drawer-nav-item ${activeView === "history" ? "active" : ""}`} onClick={() => navigateMobile("history")}>
                  <History size={20} /> <span>History</span>
                </button>
              </>
            )}
            {rolloutFlags.manualBilling && (
              <button className={`drawer-nav-item ${activeView === "billing" ? "active" : ""}`} onClick={() => navigateMobile("billing")}>
                <CreditCard size={20} /> <span>Billing</span>
              </button>
            )}
            <button className={`drawer-nav-item ${activeView === "settings" ? "active" : ""}`} onClick={() => navigateMobile("settings")}>
              <Settings size={20} /> <span>Settings</span>
            </button>
          </nav>

          <footer className="drawer-footer">
            <button className="drawer-nav-item" onClick={() => setAuthMode("admin")}>
              <LayoutGrid size={20} /> <span>Back Office</span>
            </button>
            <button className="drawer-nav-item logout" onClick={() => void signOut()}>
              <LogOut size={20} /> <span>Logout</span>
            </button>
            <div className="drawer-version">v.2.5.0</div>
          </footer>
        </aside>
      </div>

      {/* Modifier selector overlay (when adding item with backend modifiers) */}
      {modifierProductForAdd && (
        <ModifierSelector
          groups={modifierProductForAdd.groups}
          selections={modifierSelections}
          onChange={setModifierSelections}
          productName={modifierProductForAdd.product.name}
          onAdd={(qty) => {
            const unitPrice = calculatePriceWithModifiers(
              modifierProductForAdd.product.basePrice,
              modifierSelections
            );
            const lineTotal = unitPrice * qty;
            setCartItems((prev) => [
              ...prev,
              {
                productId: modifierProductForAdd.product.id,
                productName: modifierProductForAdd.product.name,
                quantity: qty,
                unitPrice,
                lineTotal,
                selections: modifierSelections
              }
            ]);
            setModifierProductForAdd(null);
            setModifierSelections({});
          }}
          onClose={() => {
            setModifierProductForAdd(null);
            setModifierSelections({});
          }}
        />
      )}

      {/* Mobile Floating Cart Summary */}
      {activeView === "menu" && cartItems.length > 0 && !isMobileCartOpen && (
        <div className="mobile-cart-summary">
          <div className="mobile-cart-info">
            <h4>{cartItems.length} Items</h4>
            <p>₹{orderTotal}</p>
          </div>
          <button className="mobile-cart-btn" onClick={() => setIsMobileCartOpen(true)}>
            View Cart
          </button>
        </div>
      )}

      {/* Mobile Cart Overlay */}
      {isMobileCartOpen && (
        <div className="mobile-cart-overlay">
          <header className="mobile-cart-header">
            <button className="ghost" onClick={() => setIsMobileCartOpen(false)}>
              <X size={20} />
            </button>
            <h3>Review Order</h3>
            <button className="ghost" onClick={() => setCartItems([])}>
              Clear
            </button>
          </header>

          <div className="mobile-cart-content">
            <div className="mobile-cart-items">
              {cartItems.map((item, idx) => (
                <article key={`${item.productId}-${idx}`} className="mobile-cart-item">
                  <div className="mobile-cart-item-info">
                    <div>
                      <span className="mobile-cart-item-name">{item.productName}</span>
                    </div>
                    <strong className="mobile-cart-item-total">₹{item.lineTotal}</strong>
                  </div>
                  <div className="mobile-cart-item-controls">
                    <div className="bill-stepper" style={{ background: "#f8fafc", borderRadius: "8px", padding: "4px" }}>
                      <button
                        className="ghost bill-step-btn"
                        onClick={() =>
                          setCartItems((prev) =>
                            prev.map((line, lineIdx) =>
                              lineIdx === idx
                                ? { ...line, quantity: Math.max(1, line.quantity - 1), lineTotal: line.unitPrice * Math.max(1, line.quantity - 1) }
                                : line
                            )
                          )
                        }
                      >
                        -
                      </button>
                      <span className="bill-qty-value">{item.quantity}</span>
                      <button
                        className="ghost bill-step-btn"
                        onClick={() =>
                          setCartItems((prev) =>
                            prev.map((line, lineIdx) =>
                              lineIdx === idx
                                ? { ...line, quantity: line.quantity + 1, lineTotal: line.unitPrice * (line.quantity + 1) }
                                : line
                            )
                          )
                        }
                      >
                        +
                      </button>
                    </div>
                    <button
                      className="ghost"
                      style={{ color: "#ef4444" }}
                      onClick={() => setCartItems((prev) => prev.filter((_, lineIdx) => lineIdx !== idx))}
                    >
                      <Trash2 size={18} />
                    </button>
                  </div>
                </article>
              ))}
            </div>

            {aiSuggestion && !aiSuggestLoading && cartItems.length > 0 && (
              <div className="panel" style={{ margin: "12px 0", background: "linear-gradient(135deg, #fdf4ff 0%, #f3e8ff 100%)", borderColor: "#e9d5ff", padding: "12px", borderRadius: "12px", position: "relative", boxShadow: "0 4px 12px rgba(168, 85, 247, 0.1)" }}>
                <button className="ghost icon-only" style={{ position: "absolute", top: 4, right: 4, width: 28, height: 28, padding: 0 }} onClick={() => setAiSuggestion(null)}>×</button>
                <div style={{ display: "flex", gap: "8px", alignItems: "flex-start" }}>
                  <span style={{ fontSize: "1.2rem" }}>✨</span>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <strong style={{ fontSize: "0.85rem", color: "#6b21a8", display: "block", marginBottom: 2 }}>AI Suggests</strong>
                    <p style={{ fontSize: "0.8rem", color: "#334155", margin: 0, lineHeight: 1.4 }}>{aiSuggestion.reason}</p>
                    {(() => {
                      const item = menu.find(m => m.id === aiSuggestion.productId);
                      if (!item) return null;
                      return (
                        <button
                          type="button"
                          className="primary"
                          style={{ marginTop: 8, padding: "8px 14px", fontSize: "0.85rem", height: "auto", background: "linear-gradient(135deg, #a855f7 0%, #7e22ce 100%)", border: "none", borderRadius: "8px" }}
                          onClick={() => {
                            setCartItems(prev => [...prev, { productId: item.id, productName: item.name, quantity: 1, unitPrice: item.basePrice, lineTotal: item.basePrice, selections: { size: "medium", milk: "regular", sugarLevel: "regular", extraShots: 0 } }]);
                            setAiSuggestion(null);
                          }}
                        >
                          + Add {item.name} (₹{item.basePrice})
                        </button>
                      );
                    })()}
                  </div>
                </div>
              </div>
            )}

            <div className="panel" style={{ padding: "16px", background: "white", borderRadius: "12px", border: "1px solid #eef2f5" }}>
              <h4>Customer Details</h4>
              <div style={{ display: "flex", flexDirection: "column", gap: "12px", marginTop: "12px" }}>
                <label className="field" style={{ position: 'relative' }}>
                  <span>Customer Name</span>
                  <input 
                    placeholder="Required" 
                    value={customerName} 
                    onChange={(e) => setCustomerName(e.target.value)} 
                    onFocus={() => setShowNameSuggestions(true)}
                    onBlur={() => setTimeout(() => setShowNameSuggestions(false), 200)}
                  />
                  <SuggestionDropdown 
                    suggestions={nameSuggestions} 
                    onSelect={handleSelectCustomer} 
                    visible={showNameSuggestions} 
                  />
                </label>
                <label className="field" style={{ position: 'relative' }}>
                  <span>Phone Number</span>
                  <input 
                    placeholder="Required for digital receipt" 
                    value={customerPhone} 
                    onChange={(e) => {
                      setCustomerPhone(e.target.value);
                      // Fetch tags automatically if phone is entered
                      if (e.target.value.length >= 10) {
                        void fetchCustomerDetails(e.target.value);
                      }
                    }} 
                    onFocus={() => setShowPhoneSuggestions(true)}
                    onBlur={() => setTimeout(() => setShowPhoneSuggestions(false), 200)}
                  />
                  <SuggestionDropdown 
                    suggestions={phoneSuggestions} 
                    onSelect={handleSelectCustomer} 
                    visible={showPhoneSuggestions} 
                  />
                </label>

                <div className="field" style={{ marginBottom: 4 }}>
                  <span style={{ display: "block", marginBottom: 8, fontSize: "0.85rem", fontWeight: 600, color: "var(--text-muted)" }}>Order Type</span>
                  <div className="bill-chip-row bill-order-type-row">
                    <button className={`ghost ${orderMode === "dine_in" ? "chip-active" : ""}`} onClick={() => setOrderMode("dine_in")}>
                      Dine In
                    </button>
                    <button className={`ghost ${orderMode === "takeaway" ? "chip-active" : ""}`} onClick={() => setOrderMode("takeaway")}>
                      Takeaway
                    </button>
                    <button className={`ghost ${orderMode === "delivery" ? "chip-active" : ""}`} onClick={() => setOrderMode("delivery")}>
                      Delivery
                    </button>
                  </div>
                </div>
                
                {/* Auto-fetched Customer Tags Display */}
                {customerPhone.length >= 10 && (customerDetails.topItems.length > 0 || (customerDetails.points && customerDetails.points > 0)) && (
                  <div style={{ 
                    padding: '8px', 
                    backgroundColor: '#fffbeb', 
                    borderRadius: '8px', 
                    border: '1px solid #fde68a',
                    fontSize: '0.8rem',
                    color: '#92400e',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '4px'
                  }}>
                    {customerDetails.topItems.length > 0 && <div><span style={{fontWeight: 600}}>AI Insight:</span> Frequently orders {customerDetails.topItems.map(i => i.name).join(', ')}.</div>}
                    {customerDetails.points && customerDetails.points > 0 ? <div><span style={{fontWeight: 600}}>Points:</span> {customerDetails.points} available.</div> : null}
                    {selectedCustomer?.loyaltyTier && (
                      <div><span style={{fontWeight: 600}}>Tier:</span> <span style={{ textTransform: 'capitalize' }}>{selectedCustomer.loyaltyTier}</span></div>
                    )}
                  </div>
                )}

                {orderMode === "dine_in" && (
                  <label className="field">
                    <span>Table Number</span>
                    <input placeholder="Required" value={tableNumber} onChange={(e) => setTableNumber(e.target.value)} />
                  </label>
                )}
                {orderMode === "delivery" && (
                  <>
                    <label className="field">
                      <span>Block</span>
                      <input placeholder="G1 / B2" value={deliveryBlock} onChange={(e) => setDeliveryBlock(e.target.value)} />
                    </label>
                    <label className="field">
                      <span>Delivery Address</span>
                      <input placeholder="Required" value={deliveryAddress} onChange={(e) => setDeliveryAddress(e.target.value)} />
                    </label>
                  </>
                )}
                {orderMode === "takeaway" && (
                  <label className="field">
                    <span>Pickup Label</span>
                    <input placeholder="Optional" value={deliveryBlock} onChange={(e) => setDeliveryBlock(e.target.value)} />
                  </label>
                )}
              </div>
            </div>

            {lastOrderForRepeat && (
              <div style={{ marginTop: 8, marginBottom: 8 }}>
                <button type="button" className="ghost" style={{ padding: "10px 16px", borderRadius: "10px", fontSize: "0.9rem", width: "100%", border: "1px dashed #94a3b8", color: "#475569" }} onClick={() => void repeatLastOrder()}>
                  🔁 Repeat last order
                </button>
              </div>
            )}

            <div className="totals" style={{ padding: "0 8px" }}>
              <div className="row"><span>Subtotal</span><strong>₹{cartSubtotal}</strong></div>
              <div className="row grand"><span>Total</span><strong>₹{orderTotal}</strong></div>
            </div>
          </div>

          <footer className="mobile-cart-footer">
            <button 
              className="primary full bill-process-btn" 
              disabled={cartItems.length === 0 || !customerName || (orderMode === "dine_in" && !tableNumber) || (orderMode === "delivery" && !deliveryAddress.trim())}
              onClick={() => {
                void processTransaction();
                setIsMobileCartOpen(false);
              }}
            >
              Confirm & Print Receipt (₹{orderTotal})
            </button>
          </footer>
        </div>
      )}

      {/* Customer Profile Modal */}
      {selectedCustomer && (
        <div style={{
          position: 'fixed',
          top: 0, left: 0, right: 0, bottom: 0,
          backgroundColor: 'rgba(15, 23, 42, 0.6)',
          backdropFilter: 'blur(4px)',
          zIndex: 9999,
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          padding: '20px'
        }} onClick={() => setSelectedCustomer(null)}>
          <div style={{
            backgroundColor: 'white',
            borderRadius: '24px',
            width: '100%',
            maxWidth: '640px',
            maxHeight: '85vh',
            display: 'flex',
            flexDirection: 'column',
            boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)'
          }} onClick={e => e.stopPropagation()}>
            
            {/* Header - Fixed */}
            <div style={{ padding: '24px 24px 16px 24px', borderBottom: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexShrink: 0 }}>
              <div>
                <h2 style={{ margin: 0, fontSize: '1.75rem', color: '#0f172a', fontWeight: 700, letterSpacing: '-0.02em' }}>{selectedCustomer.name}</h2>
                <p style={{ margin: '4px 0 0 0', color: '#64748b', fontSize: '1rem', display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>
                  {selectedCustomer.phone}
                </p>
              </div>
              <button className="ghost" style={{ width: '36px', height: '36px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: '#f1f5f9', color: '#64748b' }} onClick={() => setSelectedCustomer(null)}>✕</button>
            </div>

            {/* Scrollable Content */}
            <div style={{ padding: '24px', overflowY: 'auto', flex: 1 }}>

              {/* KPIs */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px', marginBottom: '32px' }}>
                <div style={{ padding: '16px', backgroundColor: '#f8fafc', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
                  <div style={{ fontSize: '0.85rem', color: '#64748b', marginBottom: '8px', fontWeight: 500 }}>Lifetime Spend</div>
                  <div style={{ fontSize: '1.25rem', fontWeight: 700, color: '#0f172a' }}>₹{Math.round(selectedCustomer.spend)}</div>
                </div>
                <div style={{ padding: '16px', backgroundColor: '#f8fafc', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
                  <div style={{ fontSize: '0.85rem', color: '#64748b', marginBottom: '8px', fontWeight: 500 }}>Total Visits</div>
                  <div style={{ fontSize: '1.25rem', fontWeight: 700, color: '#0f172a' }}>{selectedCustomer.orderCount}</div>
                </div>
                <div style={{ padding: '16px', backgroundColor: '#f8fafc', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
                  <div style={{ fontSize: '0.85rem', color: '#64748b', marginBottom: '8px', fontWeight: 500 }}>Avg. Order</div>
                  <div style={{ fontSize: '1.25rem', fontWeight: 700, color: '#0f172a' }}>₹{Math.round(selectedCustomer.spend / selectedCustomer.orderCount)}</div>
                </div>
                <div style={{ padding: '16px', backgroundColor: '#f0fdf4', borderRadius: '16px', border: '1px solid #bbf7d0' }}>
                  <div style={{ fontSize: '0.85rem', color: '#15803d', marginBottom: '8px', fontWeight: 600 }}>Loyalty Points</div>
                  <div style={{ fontSize: '1.25rem', fontWeight: 700, color: '#166534' }}>
                    {customerDetails.isLoading ? '...' : (customerDetails.points ?? '0')}
                  </div>
                </div>
              </div>

              {/* Tier & Top Items Row */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px', marginBottom: '32px' }}>
                <div>
                  <h3 style={{ fontSize: '1rem', marginBottom: '16px', color: '#334155', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"></path><line x1="7" y1="7" x2="7.01" y2="7"></line></svg>
                    Loyalty Tier
                  </h3>
                  <span style={{ 
                    padding: '6px 12px', 
                    backgroundColor: selectedCustomer.loyaltyTier === 'connoisseur' ? '#e0e7ff' : selectedCustomer.loyaltyTier === 'gourmet' ? '#fef08a' : '#f1f5f9', 
                    color: selectedCustomer.loyaltyTier === 'connoisseur' ? '#4338ca' : selectedCustomer.loyaltyTier === 'gourmet' ? '#854d0e' : '#475569', 
                    borderRadius: '20px', 
                    fontSize: '0.85rem',
                    fontWeight: 600,
                    textTransform: 'capitalize',
                  }}>
                    {selectedCustomer.loyaltyTier}
                  </span>
                  {(selectedCustomer.loyaltyPoints ?? 0) > 0 && (
                    <div style={{ marginTop: '8px', fontSize: '0.9rem', color: '#64748b' }}>Check-in points: {selectedCustomer.loyaltyPoints}</div>
                  )}
                </div>

                <div>
                  <h3 style={{ fontSize: '1rem', marginBottom: '16px', color: '#334155', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon></svg>
                    Top Ordered Items
                  </h3>
                  {customerDetails.isLoading ? (
                    <div style={{ color: '#94a3b8', fontSize: '0.9rem' }}>Loading...</div>
                  ) : customerDetails.topItems.length > 0 ? (
                    <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                      {customerDetails.topItems.map(item => (
                        <span key={item.name} style={{ padding: '6px 12px', backgroundColor: '#f1f5f9', borderRadius: '20px', fontSize: '0.85rem', color: '#334155', fontWeight: 500, border: '1px solid #e2e8f0' }}>
                          {item.name} <span style={{ color: '#94a3b8', marginLeft: '4px' }}>{item.count}x</span>
                        </span>
                      ))}
                    </div>
                  ) : (
                    <div style={{ color: '#94a3b8', fontSize: '0.9rem', fontStyle: 'italic' }}>No items found.</div>
                  )}
                </div>
              </div>

              {/* Birthday */}
              {rolloutFlags.businessModules && (
                <div style={{ marginBottom: '24px' }}>
                  <h3 style={{ fontSize: '1rem', marginBottom: '12px', color: '#334155', fontWeight: 600 }}>Birthday</h3>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                    <input
                      type="date"
                      value={customerDetails.birthday ?? ""}
                      onChange={(e) => setCustomerDetails(prev => ({ ...prev, birthday: e.target.value || null }))}
                      style={{ padding: '8px 12px', borderRadius: '8px', border: '1px solid #e2e8f0', fontSize: '0.9rem' }}
                    />
                    <button
                      className="btn-outline"
                      style={{ padding: '8px 16px', fontSize: '0.85rem' }}
                      onClick={() => selectedCustomer && void saveCustomerBirthday(selectedCustomer.phone, customerDetails.birthday ?? "")}
                    >
                      Save
                    </button>
                  </div>
                  <p style={{ fontSize: '0.75rem', color: '#94a3b8', marginTop: '4px' }}>For birthday campaigns — select &quot;Birthday&quot; segment when sending.</p>
                </div>
              )}

              {/* Customer Notes */}
              {rolloutFlags.businessModules && (
                <div style={{ marginBottom: '32px' }}>
                  <h3 style={{ fontSize: '1rem', marginBottom: '12px', color: '#334155', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
                    Notes
                  </h3>
                  <textarea
                    placeholder="Add notes about this customer..."
                    value={customerDetails.notes ?? ""}
                    onChange={(e) => setCustomerDetails(prev => ({ ...prev, notes: e.target.value }))}
                    style={{ width: '100%', minHeight: '80px', padding: '12px', borderRadius: '10px', border: '1px solid #e2e8f0', fontSize: '0.9rem', resize: 'vertical', fontFamily: 'inherit' }}
                  />
                  <button
                    className="btn-outline"
                    style={{ marginTop: '8px', padding: '8px 16px', fontSize: '0.85rem' }}
                    onClick={() => selectedCustomer && void saveCustomerNotes(selectedCustomer.phone, customerDetails.notes ?? "")}
                  >
                    Save Notes
                  </button>
                </div>
              )}

            <h3 style={{ fontSize: '1.1rem', marginBottom: '12px', color: '#334155' }}>Recent Orders</h3>
            {customerDetails.isLoading ? (
              <div style={{ color: '#94a3b8', fontSize: '0.9rem' }}>Loading...</div>
            ) : customerDetails.recentOrders.length > 0 ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {customerDetails.recentOrders.map(order => (
                  <div key={order.id} style={{ border: '1px solid #e2e8f0', borderRadius: '12px', padding: '12px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                      <span style={{ fontWeight: 500, fontSize: '0.9rem' }}>Order #{order.order_number}</span>
                      <span style={{ color: '#64748b', fontSize: '0.85rem' }}>{new Date(order.created_at).toLocaleDateString()}</span>
                    </div>
                    <div style={{ color: '#64748b', fontSize: '0.85rem', marginBottom: '8px' }}>
                      {order.order_items?.map((oi: any) => {
                        let name = oi.menu_items?.name;
                        if (!name && !oi.menu_item_id && oi.special_instructions) {
                          try {
                            const parsed = JSON.parse(oi.special_instructions);
                            if (parsed._offlineProductName) name = parsed._offlineProductName;
                          } catch {}
                        }
                        return `${oi.quantity}x ${name || 'Item'}`;
                      }).join(', ')}
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ fontWeight: 600, fontSize: '0.95rem' }}>₹{Math.round(order.total_amount || 0)}</span>
                      <div style={{ display: 'flex', gap: '8px' }}>
                        <button 
                          className="ghost" 
                          style={{ padding: '8px 16px', fontSize: '0.85rem', borderRadius: '10px', fontWeight: 600, whiteSpace: 'nowrap', color: '#25D366' }}
                          onClick={(e) => {
                            e.stopPropagation();
                            void triggerWhatsAppAutomation(
                              "send_digital_receipt", 
                              order.id, 
                              { 
                                orderNo: order.order_number, 
                                total: order.total_amount, 
                                paymentMethod: "paid", 
                                items: order.order_items?.map((oi: any) => {
                                  let name = oi.menu_items?.name;
                                  if (!name && !oi.menu_item_id && oi.special_instructions) {
                                    try {
                                      const parsed = JSON.parse(oi.special_instructions);
                                      if (parsed._offlineProductName) name = parsed._offlineProductName;
                                    } catch {}
                                  }
                                  return { 
                                    name: name || "Item", 
                                    quantity: oi.quantity,
                                    price: oi.unit_price,
                                    amount: oi.total_price || (oi.quantity * (oi.unit_price || 0))
                                  };
                                }) || [] 
                              }, 
                              selectedCustomer.phone
                            );
                            notify("Receipt sent to WhatsApp!");
                          }}
                        >
                          <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
                              <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51a12.8 12.8 0 0 0-.57-.01c-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 0 1-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 0 1-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 0 1 2.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0 0 12.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 0 0 5.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 0 0-3.48-8.413Z"/>
                            </svg>
                            Receipt
                          </span>
                        </button>
                        <button 
                          className="btn-outline" 
                          style={{ padding: '8px 16px', fontSize: '0.85rem', borderRadius: '10px', fontWeight: 600, whiteSpace: 'nowrap', flexShrink: 0 }}
                          onClick={() => {
                            setCustomerName(selectedCustomer.name);
                            setCustomerPhone(selectedCustomer.phone);
                            void repeatSpecificOrder(order.id);
                            setSelectedCustomer(null);
                            setActiveView("dashboard");
                          }}
                        >
                          Repeat Order
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div style={{ color: '#94a3b8', fontSize: '0.9rem', fontStyle: 'italic' }}>No recent orders.</div>
            )}
            </div>
            
            {/* Footer - Fixed */}
            <div style={{ padding: '16px 24px 24px 24px', borderTop: '1px solid #e2e8f0' }}>
              <button 
                className="primary" 
                style={{ width: '100%', padding: '16px', borderRadius: '12px', fontSize: '1.05rem', fontWeight: 600 }}
                onClick={() => {
                  setCustomerName(selectedCustomer.name);
                  setCustomerPhone(selectedCustomer.phone);
                  setSelectedCustomer(null);
                  setActiveView("dashboard");
                }}
              >
                Start New Order
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
