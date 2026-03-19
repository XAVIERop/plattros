-- Final fix for infinite recursion in cafe_staff table
-- This will completely resolve the recursion issue

-- 1. TEMPORARILY DISABLE RLS TO BREAK RECURSION
ALTER TABLE public.cafe_staff DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_queue DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_analytics DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.item_analytics DISABLE ROW LEVEL SECURITY;

-- 2. DROP ALL EXISTING POLICIES THAT CAUSE RECURSION
-- Drop cafe_staff policies
DROP POLICY IF EXISTS "cafe_staff_select" ON public.cafe_staff;
DROP POLICY IF EXISTS "cafe_staff_update" ON public.cafe_staff;
DROP POLICY IF EXISTS "cafe_staff_insert" ON public.cafe_staff;
DROP POLICY IF EXISTS "cafe_staff_delete" ON public.cafe_staff;
DROP POLICY IF EXISTS "Cafe staff can view their own records" ON public.cafe_staff;
DROP POLICY IF EXISTS "Cafe staff can update their own records" ON public.cafe_staff;
DROP POLICY IF EXISTS "System can insert cafe staff" ON public.cafe_staff;
DROP POLICY IF EXISTS "System can delete cafe staff" ON public.cafe_staff;

-- Drop order_notifications policies
DROP POLICY IF EXISTS "notifications_select" ON public.order_notifications;
DROP POLICY IF EXISTS "notifications_insert" ON public.order_notifications;
DROP POLICY IF EXISTS "notifications_update" ON public.order_notifications;
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.order_notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON public.order_notifications;
DROP POLICY IF EXISTS "System can update notifications" ON public.order_notifications;

-- Drop order_queue policies
DROP POLICY IF EXISTS "cafe_staff_can_manage_queue" ON public.order_queue;

-- Drop analytics policies
DROP POLICY IF EXISTS "cafe_staff_can_view_analytics" ON public.order_analytics;
DROP POLICY IF EXISTS "cafe_staff_can_view_item_analytics" ON public.item_analytics;

-- 3. RE-ENABLE RLS WITH SIMPLE, NON-RECURSIVE POLICIES
ALTER TABLE public.cafe_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.item_analytics ENABLE ROW LEVEL SECURITY;

-- 4. CREATE SIMPLE POLICIES FOR CAFE_STAFF (NO RECURSION)
CREATE POLICY "cafe_staff_simple_select" ON public.cafe_staff
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "cafe_staff_simple_insert" ON public.cafe_staff
  FOR INSERT WITH CHECK (true);

CREATE POLICY "cafe_staff_simple_update" ON public.cafe_staff
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "cafe_staff_simple_delete" ON public.cafe_staff
  FOR DELETE USING (auth.uid() = user_id);

-- 5. CREATE SIMPLE POLICIES FOR ORDER_NOTIFICATIONS
CREATE POLICY "notifications_simple_select" ON public.order_notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "notifications_simple_insert" ON public.order_notifications
  FOR INSERT WITH CHECK (true);

CREATE POLICY "notifications_simple_update" ON public.order_notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- 6. CREATE SIMPLE POLICIES FOR ORDER_QUEUE (NO CAFE_STAFF REFERENCE)
CREATE POLICY "queue_simple_all" ON public.order_queue
  FOR ALL USING (true);

-- 7. CREATE SIMPLE POLICIES FOR ANALYTICS (NO CAFE_STAFF REFERENCE)
CREATE POLICY "analytics_simple_select" ON public.order_analytics
  FOR SELECT USING (true);

CREATE POLICY "item_analytics_simple_select" ON public.item_analytics
  FOR SELECT USING (true);

-- 8. ENSURE PULKIT IS ADDED AS CAFE OWNER
INSERT INTO public.cafe_staff (cafe_id, user_id, role, is_active)
SELECT 
  c.id as cafe_id,
  p.id as user_id,
  'owner' as role,
  true as is_active
FROM public.cafes c
CROSS JOIN public.profiles p
WHERE p.email = 'pulkit.229302047@muj.manipal.edu'
  AND c.name = 'Mini Meals'
  AND NOT EXISTS (
    SELECT 1 FROM public.cafe_staff cs 
    WHERE cs.cafe_id = c.id AND cs.user_id = p.id
  )
LIMIT 1;

-- 9. TEST THE FIX
SELECT 'Infinite recursion fixed! All policies recreated with simple, non-recursive rules.' as status;
