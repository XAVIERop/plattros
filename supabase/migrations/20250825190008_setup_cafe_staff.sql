-- Setup cafe staff and real-time order management system
-- This will ensure cafe owners can manage orders properly

-- First, ensure cafe_staff table exists with proper structure
CREATE TABLE IF NOT EXISTS public.cafe_staff (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'staff', -- 'owner', 'manager', 'staff'
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(cafe_id, user_id)
);

-- Enable RLS for cafe_staff
ALTER TABLE public.cafe_staff ENABLE ROW LEVEL SECURITY;

-- Create simple policies for cafe_staff
DROP POLICY IF EXISTS "cafe_staff_select" ON public.cafe_staff;
DROP POLICY IF EXISTS "cafe_staff_update" ON public.cafe_staff;
DROP POLICY IF EXISTS "cafe_staff_insert" ON public.cafe_staff;
DROP POLICY IF EXISTS "cafe_staff_delete" ON public.cafe_staff;

CREATE POLICY "cafe_staff_select" ON public.cafe_staff
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "cafe_staff_update" ON public.cafe_staff
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "cafe_staff_insert" ON public.cafe_staff
  FOR INSERT WITH CHECK (true);

CREATE POLICY "cafe_staff_delete" ON public.cafe_staff
  FOR DELETE USING (true);

-- Ensure order_notifications table exists
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

-- Create policies for order_notifications
DROP POLICY IF EXISTS "notifications_select" ON public.order_notifications;
DROP POLICY IF EXISTS "notifications_insert" ON public.order_notifications;
DROP POLICY IF EXISTS "notifications_update" ON public.order_notifications;

CREATE POLICY "notifications_select" ON public.order_notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "notifications_insert" ON public.order_notifications
  FOR INSERT WITH CHECK (true);

CREATE POLICY "notifications_update" ON public.order_notifications
  FOR UPDATE USING (true);

-- Add status tracking columns to orders if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'status_updated_at') THEN
        ALTER TABLE public.orders ADD COLUMN status_updated_at TIMESTAMPTZ DEFAULT now();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'points_credited') THEN
        ALTER TABLE public.orders ADD COLUMN points_credited BOOLEAN DEFAULT false;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'accepted_at') THEN
        ALTER TABLE public.orders ADD COLUMN accepted_at TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'preparing_at') THEN
        ALTER TABLE public.orders ADD COLUMN preparing_at TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'out_for_delivery_at') THEN
        ALTER TABLE public.orders ADD COLUMN out_for_delivery_at TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'completed_at') THEN
        ALTER TABLE public.orders ADD COLUMN completed_at TIMESTAMPTZ;
    END IF;
END $$;

-- Create function to handle new order notifications
CREATE OR REPLACE FUNCTION public.handle_new_order_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- Create notification for cafe
  INSERT INTO public.order_notifications (
    order_id,
    cafe_id,
    user_id,
    notification_type,
    message
  ) VALUES (
    NEW.id,
    NEW.cafe_id,
    NEW.user_id,
    'new_order',
    'New order #' || NEW.order_number || ' received for ₹' || NEW.total_amount
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for new order notifications
DROP TRIGGER IF EXISTS new_order_notification_trigger ON public.orders;
CREATE TRIGGER new_order_notification_trigger
  AFTER INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_order_notification();

-- Create function to handle order status updates and points crediting
CREATE OR REPLACE FUNCTION public.handle_order_status_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Update status timestamp
  NEW.status_updated_at = now();
  
  -- Add specific status timestamps
  CASE NEW.status
    WHEN 'confirmed' THEN
      NEW.accepted_at = now();
    WHEN 'preparing' THEN
      NEW.preparing_at = now();
    WHEN 'on_the_way' THEN
      NEW.out_for_delivery_at = now();
    WHEN 'completed' THEN
      NEW.completed_at = now();
      NEW.points_credited = true;
      
      -- Credit points to user only when order is completed
      UPDATE public.profiles 
      SET 
        loyalty_points = loyalty_points + NEW.points_earned,
        total_orders = total_orders + 1,
        total_spent = total_spent + NEW.total_amount
      WHERE id = NEW.user_id;
      
      -- Create completion notification
      INSERT INTO public.order_notifications (
        order_id,
        cafe_id,
        user_id,
        notification_type,
        message
      ) VALUES (
        NEW.id,
        NEW.cafe_id,
        NEW.user_id,
        'order_completed',
        'Order #' || NEW.order_number || ' completed! You earned ' || NEW.points_earned || ' points.'
      );
  END CASE;
  
  -- Create status update notification
  INSERT INTO public.order_notifications (
    order_id,
    cafe_id,
    user_id,
    notification_type,
    message
  ) VALUES (
    NEW.id,
    NEW.cafe_id,
    NEW.user_id,
    'status_update',
    'Order #' || NEW.order_number || ' status updated to ' || NEW.status
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for order status updates
DROP TRIGGER IF EXISTS order_status_update_trigger ON public.orders;
CREATE TRIGGER order_status_update_trigger
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION public.handle_order_status_update();

-- Add Pulkit as cafe owner for Mini Meals
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

-- Update existing orders to have proper status tracking
UPDATE public.orders 
SET 
  status_updated_at = created_at,
  points_credited = CASE WHEN status = 'completed' THEN true ELSE false END
WHERE status_updated_at IS NULL;

-- Test the setup
SELECT 'Cafe staff and real-time order management system setup completed!' as status;
