-- Dedicated policies for authenticated orders and QR table orders
-- This keeps the existing authenticated flow secure while enabling anon table orders.

BEGIN;

-- 1. Standard authenticated users must insert with their own user_id
DROP POLICY IF EXISTS "users_create_own_orders" ON public.orders;
CREATE POLICY "users_create_own_orders" ON public.orders
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() IS NOT NULL AND user_id = auth.uid()
);

-- 2. Allow table-order QR flow (user_id = NULL, requires table metadata)
DROP POLICY IF EXISTS "table_orders_insert" ON public.orders;
CREATE POLICY "table_orders_insert" ON public.orders
FOR INSERT
TO anon, authenticated
WITH CHECK (
  order_type = 'table_order'
  AND user_id IS NULL
  AND table_number IS NOT NULL
  AND cafe_id IS NOT NULL
  AND phone_number IS NOT NULL
);

COMMIT;

-- Verification helper (optional)
-- SELECT policyname, cmd, roles, with_check
-- FROM pg_policies
-- WHERE schemaname = 'public' AND tablename = 'orders'
-- ORDER BY cmd, policyname;
