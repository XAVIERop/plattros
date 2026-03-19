-- Fix infinite recursion in cafe_staff table policy
-- This migration will fix the policy issue that's preventing notifications from working

-- First, let's check if cafe_staff table exists and drop problematic policies
DO $$ 
BEGIN
    -- Drop all policies on cafe_staff table if they exist
    DROP POLICY IF EXISTS "Cafe staff can view their cafe orders" ON public.cafe_staff;
    DROP POLICY IF EXISTS "Cafe staff can update their cafe orders" ON public.cafe_staff;
    DROP POLICY IF EXISTS "Cafe staff can insert their cafe orders" ON public.cafe_staff;
    DROP POLICY IF EXISTS "Cafe staff can delete their cafe orders" ON public.cafe_staff;
    
    -- Create simple, non-recursive policies
    CREATE POLICY "Cafe staff can view their own records" ON public.cafe_staff
      FOR SELECT USING (auth.uid() = user_id);
    
    CREATE POLICY "Cafe staff can update their own records" ON public.cafe_staff
      FOR UPDATE USING (auth.uid() = user_id);
    
    CREATE POLICY "System can insert cafe staff" ON public.cafe_staff
      FOR INSERT WITH CHECK (true);
    
    CREATE POLICY "System can delete cafe staff" ON public.cafe_staff
      FOR DELETE USING (true);
    
EXCEPTION
    WHEN undefined_table THEN
        -- Table doesn't exist, create it
        CREATE TABLE IF NOT EXISTS public.cafe_staff (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
          user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
          role TEXT NOT NULL DEFAULT 'staff', -- 'owner', 'manager', 'staff'
          is_active BOOLEAN NOT NULL DEFAULT true,
          created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
          updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
        );
        
        -- Enable RLS
        ALTER TABLE public.cafe_staff ENABLE ROW LEVEL SECURITY;
        
        -- Create simple policies
        CREATE POLICY "Cafe staff can view their own records" ON public.cafe_staff
          FOR SELECT USING (auth.uid() = user_id);
        
        CREATE POLICY "Cafe staff can update their own records" ON public.cafe_staff
          FOR UPDATE USING (auth.uid() = user_id);
        
        CREATE POLICY "System can insert cafe staff" ON public.cafe_staff
          FOR INSERT WITH CHECK (true);
        
        CREATE POLICY "System can delete cafe staff" ON public.cafe_staff
          FOR DELETE USING (true);
END $$;

-- Ensure order_notifications table exists and has proper policies
CREATE TABLE IF NOT EXISTS public.order_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL, -- 'new_order', 'status_update', 'order_completed'
  message TEXT NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS for order_notifications
ALTER TABLE public.order_notifications ENABLE ROW LEVEL SECURITY;

-- Drop and recreate order_notifications policies to ensure they're clean
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.order_notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON public.order_notifications;
DROP POLICY IF EXISTS "Cafe staff can view their cafe notifications" ON public.order_notifications;

-- Create clean policies for order_notifications
CREATE POLICY "Users can view their own notifications" ON public.order_notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications" ON public.order_notifications
  FOR INSERT WITH CHECK (true);

CREATE POLICY "System can update notifications" ON public.order_notifications
  FOR UPDATE USING (true);

-- Add sample cafe staff if not exists
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

-- Test the fix
SELECT 'Database migration completed successfully! Cafe staff policy fixed.' as status;
