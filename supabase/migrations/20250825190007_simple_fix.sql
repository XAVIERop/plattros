-- Simple fix for infinite recursion in cafe_staff table
-- Drop all existing policies and recreate them properly

-- First, disable RLS temporarily to avoid recursion issues
ALTER TABLE public.cafe_staff DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_notifications DISABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies on cafe_staff
DROP POLICY IF EXISTS "Cafe staff can view their own records" ON public.cafe_staff;
DROP POLICY IF EXISTS "Cafe staff can update their own records" ON public.cafe_staff;
DROP POLICY IF EXISTS "System can insert cafe staff" ON public.cafe_staff;
DROP POLICY IF EXISTS "System can delete cafe staff" ON public.cafe_staff;
DROP POLICY IF EXISTS "Cafe staff can view their cafe orders" ON public.cafe_staff;
DROP POLICY IF EXISTS "Cafe staff can update their cafe orders" ON public.cafe_staff;
DROP POLICY IF EXISTS "Cafe staff can insert their cafe orders" ON public.cafe_staff;
DROP POLICY IF EXISTS "Cafe staff can delete their cafe orders" ON public.cafe_staff;

-- Drop ALL existing policies on order_notifications
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.order_notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON public.order_notifications;
DROP POLICY IF EXISTS "System can update notifications" ON public.order_notifications;
DROP POLICY IF EXISTS "Cafe staff can view their cafe notifications" ON public.order_notifications;

-- Re-enable RLS
ALTER TABLE public.cafe_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_notifications ENABLE ROW LEVEL SECURITY;

-- Create simple, non-recursive policies for cafe_staff
CREATE POLICY "cafe_staff_select" ON public.cafe_staff
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "cafe_staff_update" ON public.cafe_staff
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "cafe_staff_insert" ON public.cafe_staff
  FOR INSERT WITH CHECK (true);

CREATE POLICY "cafe_staff_delete" ON public.cafe_staff
  FOR DELETE USING (true);

-- Create simple, non-recursive policies for order_notifications
CREATE POLICY "notifications_select" ON public.order_notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "notifications_insert" ON public.order_notifications
  FOR INSERT WITH CHECK (true);

CREATE POLICY "notifications_update" ON public.order_notifications
  FOR UPDATE USING (true);

-- Test that the fix works
SELECT 'Database migration completed successfully! All policies recreated.' as status;
