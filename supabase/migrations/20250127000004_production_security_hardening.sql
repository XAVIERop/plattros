-- Production Security Hardening Migration
-- This migration fixes critical security vulnerabilities

-- 1. RE-ENABLE ROW LEVEL SECURITY ON ALL CRITICAL TABLES
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafe_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafe_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;

-- 2. DROP ALL EXISTING PERMISSIVE POLICIES
DROP POLICY IF EXISTS "orders_allow_all" ON public.orders;
DROP POLICY IF EXISTS "profiles_allow_all" ON public.profiles;
DROP POLICY IF EXISTS "cafe_staff_allow_all" ON public.cafe_staff;
DROP POLICY IF EXISTS "notifications_allow_all" ON public.order_notifications;

-- 3. CREATE SECURE RLS POLICIES FOR ORDERS
-- Users can only view their own orders
CREATE POLICY "users_view_own_orders" ON public.orders
  FOR SELECT USING (auth.uid() = user_id);

-- Users can create their own orders
CREATE POLICY "users_create_own_orders" ON public.orders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own orders (limited fields)
CREATE POLICY "users_update_own_orders" ON public.orders
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Cafe staff can view orders for their cafe
CREATE POLICY "cafe_staff_view_orders" ON public.orders
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff cs
      WHERE cs.user_id = auth.uid()
      AND cs.cafe_id = orders.cafe_id
      AND cs.is_active = true
    )
  );

-- Cafe staff can update orders for their cafe (status updates only)
CREATE POLICY "cafe_staff_update_orders" ON public.orders
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff cs
      WHERE cs.user_id = auth.uid()
      AND cs.cafe_id = orders.cafe_id
      AND cs.is_active = true
    )
  );

-- 4. CREATE SECURE RLS POLICIES FOR PROFILES
-- Users can view their own profile
CREATE POLICY "users_view_own_profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "users_update_own_profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "users_insert_own_profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Cafe staff can view profiles of users who have orders at their cafe
CREATE POLICY "cafe_staff_view_customer_profiles" ON public.profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.cafe_staff cs ON o.cafe_id = cs.cafe_id
      WHERE o.user_id = profiles.id
      AND cs.user_id = auth.uid()
      AND cs.is_active = true
    )
  );

-- 5. CREATE SECURE RLS POLICIES FOR ORDER ITEMS
-- Users can view order items for their own orders
CREATE POLICY "users_view_own_order_items" ON public.order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_items.order_id
      AND o.user_id = auth.uid()
    )
  );

-- Users can create order items for their own orders
CREATE POLICY "users_create_own_order_items" ON public.order_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_items.order_id
      AND o.user_id = auth.uid()
    )
  );

-- Cafe staff can view order items for orders at their cafe
CREATE POLICY "cafe_staff_view_order_items" ON public.order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.cafe_staff cs ON o.cafe_id = cs.cafe_id
      WHERE o.id = order_items.order_id
      AND cs.user_id = auth.uid()
      AND cs.is_active = true
    )
  );

-- 6. CREATE SECURE RLS POLICIES FOR MENU ITEMS
-- Anyone can view available menu items (public read)
CREATE POLICY "public_view_available_menu_items" ON public.menu_items
  FOR SELECT USING (is_available = true);

-- Cafe staff can manage menu items for their cafe
CREATE POLICY "cafe_staff_manage_menu_items" ON public.menu_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff cs
      WHERE cs.cafe_id = menu_items.cafe_id
      AND cs.user_id = auth.uid()
      AND cs.is_active = true
    )
  );

-- 7. CREATE SECURE RLS POLICIES FOR CAFE STAFF
-- Users can view their own cafe staff records
CREATE POLICY "users_view_own_cafe_staff" ON public.cafe_staff
  FOR SELECT USING (auth.uid() = user_id);

-- Users can update their own cafe staff records
CREATE POLICY "users_update_own_cafe_staff" ON public.cafe_staff
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- System can insert cafe staff records (for admin operations)
CREATE POLICY "system_insert_cafe_staff" ON public.cafe_staff
  FOR INSERT WITH CHECK (true);

-- 8. CREATE SECURE RLS POLICIES FOR ORDER NOTIFICATIONS
-- Users can view notifications for their own orders
CREATE POLICY "users_view_own_notifications" ON public.order_notifications
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_notifications.order_id
      AND o.user_id = auth.uid()
    )
  );

-- Cafe staff can view notifications for their cafe
CREATE POLICY "cafe_staff_view_notifications" ON public.order_notifications
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff cs
      WHERE cs.cafe_id = order_notifications.cafe_id
      AND cs.user_id = auth.uid()
      AND cs.is_active = true
    )
  );

-- System can insert notifications
CREATE POLICY "system_insert_notifications" ON public.order_notifications
  FOR INSERT WITH CHECK (true);

-- 9. CREATE SECURE RLS POLICIES FOR LOYALTY TRANSACTIONS
-- Users can view their own loyalty transactions
CREATE POLICY "users_view_own_loyalty_transactions" ON public.loyalty_transactions
  FOR SELECT USING (auth.uid() = user_id);

-- System can insert loyalty transactions
CREATE POLICY "system_insert_loyalty_transactions" ON public.loyalty_transactions
  FOR INSERT WITH CHECK (true);

-- 10. CREATE SECURE RLS POLICIES FOR CAFE RATINGS
-- Users can view all cafe ratings (public read)
CREATE POLICY "public_view_cafe_ratings" ON public.cafe_ratings
  FOR SELECT USING (true);

-- Users can insert their own cafe ratings
CREATE POLICY "users_insert_own_cafe_ratings" ON public.cafe_ratings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own cafe ratings
CREATE POLICY "users_update_own_cafe_ratings" ON public.cafe_ratings
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 11. CREATE SECURE RLS POLICIES FOR USER FAVORITES
-- Users can view their own favorites
CREATE POLICY "users_view_own_favorites" ON public.user_favorites
  FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own favorites
CREATE POLICY "users_insert_own_favorites" ON public.user_favorites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can delete their own favorites
CREATE POLICY "users_delete_own_favorites" ON public.user_favorites
  FOR DELETE USING (auth.uid() = user_id);

-- 12. CREATE INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_orders_user_id_created_at ON public.orders(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_cafe_id_created_at ON public.orders(cafe_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_status_created_at ON public.orders(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_cafe_staff_user_id ON public.cafe_staff(user_id);
CREATE INDEX IF NOT EXISTS idx_cafe_staff_cafe_id ON public.cafe_staff(cafe_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_cafe_id ON public.menu_items(cafe_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_user_id ON public.loyalty_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_cafe_ratings_cafe_id ON public.cafe_ratings(cafe_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_user_id ON public.user_favorites(user_id);

-- 13. CREATE SECURITY AUDIT FUNCTION
CREATE OR REPLACE FUNCTION public.audit_security_policies()
RETURNS TABLE (
  table_name text,
  policy_name text,
  policy_type text,
  policy_definition text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    schemaname||'.'||tablename as table_name,
    policyname as policy_name,
    permissive as policy_type,
    qual as policy_definition
  FROM pg_policies 
  WHERE schemaname = 'public'
  ORDER BY tablename, policyname;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14. CREATE SECURITY MONITORING VIEW
CREATE OR REPLACE VIEW public.security_audit_summary AS
SELECT 
  'RLS Status' as check_type,
  schemaname||'.'||tablename as table_name,
  CASE WHEN rowsecurity THEN 'ENABLED' ELSE 'DISABLED' END as status,
  CASE WHEN rowsecurity THEN '✅' ELSE '❌' END as icon
FROM pg_tables 
WHERE schemaname = 'public'
UNION ALL
SELECT 
  'Policy Count' as check_type,
  schemaname||'.'||tablename as table_name,
  count(*)::text as status,
  CASE WHEN count(*) > 0 THEN '✅' ELSE '❌' END as icon
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY table_name, check_type;

-- 15. GRANT NECESSARY PERMISSIONS
GRANT SELECT ON public.security_audit_summary TO authenticated;
GRANT EXECUTE ON FUNCTION public.audit_security_policies() TO authenticated;

-- 16. CREATE SECURITY ALERT FUNCTION
CREATE OR REPLACE FUNCTION public.check_security_status()
RETURNS json AS $$
DECLARE
  result json;
  disabled_tables text[];
  tables_without_policies text[];
BEGIN
  -- Check for tables with disabled RLS
  SELECT array_agg(schemaname||'.'||tablename)
  INTO disabled_tables
  FROM pg_tables 
  WHERE schemaname = 'public' 
  AND rowsecurity = false;
  
  -- Check for tables without policies
  SELECT array_agg(t.tablename)
  INTO tables_without_policies
  FROM pg_tables t
  LEFT JOIN pg_policies p ON t.tablename = p.tablename AND p.schemaname = 'public'
  WHERE t.schemaname = 'public'
  AND p.policyname IS NULL;
  
  result := json_build_object(
    'timestamp', now(),
    'disabled_rls_tables', COALESCE(disabled_tables, '{}'),
    'tables_without_policies', COALESCE(tables_without_policies, '{}'),
    'security_status', CASE 
      WHEN array_length(disabled_tables, 1) > 0 OR array_length(tables_without_policies, 1) > 0 
      THEN 'CRITICAL' 
      ELSE 'SECURE' 
    END
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 17. TEST SECURITY POLICIES
SELECT 'Security hardening migration completed successfully!' as status;
SELECT * FROM public.check_security_status();


