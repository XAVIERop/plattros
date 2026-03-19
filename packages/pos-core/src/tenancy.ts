export type PlatformRole = "super_admin" | "tenant_admin" | "store_manager" | "cashier" | "kitchen" | "customer";

export interface TenantContext {
  tenantId: string;
  storeId?: string | null;
  userId: string;
  role: PlatformRole;
}

export const RBAC_PERMISSIONS = {
  manageTenant: "tenant.manage",
  manageStore: "store.manage",
  manageUsers: "users.manage",
  manageMenu: "menu.manage",
  manageOffers: "offers.manage",
  viewAnalytics: "analytics.view",
  operatePos: "pos.operate",
  operateKitchen: "kitchen.operate",
  placeOrder: "orders.place",
  manageOrders: "orders.manage"
} as const;

export type Permission = (typeof RBAC_PERMISSIONS)[keyof typeof RBAC_PERMISSIONS];

const ROLE_PERMISSION_MATRIX: Record<PlatformRole, Permission[]> = {
  super_admin: [
    RBAC_PERMISSIONS.manageTenant,
    RBAC_PERMISSIONS.manageStore,
    RBAC_PERMISSIONS.manageUsers,
    RBAC_PERMISSIONS.manageMenu,
    RBAC_PERMISSIONS.manageOffers,
    RBAC_PERMISSIONS.viewAnalytics,
    RBAC_PERMISSIONS.operatePos,
    RBAC_PERMISSIONS.operateKitchen,
    RBAC_PERMISSIONS.placeOrder,
    RBAC_PERMISSIONS.manageOrders
  ],
  tenant_admin: [
    RBAC_PERMISSIONS.manageStore,
    RBAC_PERMISSIONS.manageUsers,
    RBAC_PERMISSIONS.manageMenu,
    RBAC_PERMISSIONS.manageOffers,
    RBAC_PERMISSIONS.viewAnalytics,
    RBAC_PERMISSIONS.operatePos,
    RBAC_PERMISSIONS.operateKitchen,
    RBAC_PERMISSIONS.placeOrder,
    RBAC_PERMISSIONS.manageOrders
  ],
  store_manager: [
    RBAC_PERMISSIONS.manageUsers,
    RBAC_PERMISSIONS.manageMenu,
    RBAC_PERMISSIONS.manageOffers,
    RBAC_PERMISSIONS.viewAnalytics,
    RBAC_PERMISSIONS.operatePos,
    RBAC_PERMISSIONS.operateKitchen,
    RBAC_PERMISSIONS.placeOrder,
    RBAC_PERMISSIONS.manageOrders
  ],
  cashier: [RBAC_PERMISSIONS.operatePos, RBAC_PERMISSIONS.placeOrder, RBAC_PERMISSIONS.manageOrders],
  kitchen: [RBAC_PERMISSIONS.operateKitchen, RBAC_PERMISSIONS.manageOrders],
  customer: [RBAC_PERMISSIONS.placeOrder]
};

export function getRolePermissions(role: PlatformRole): Permission[] {
  return ROLE_PERMISSION_MATRIX[role];
}

export function hasPermission(role: PlatformRole, permission: Permission): boolean {
  return ROLE_PERMISSION_MATRIX[role].includes(permission);
}
