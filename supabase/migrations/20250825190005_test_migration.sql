-- Simple test migration to verify database connection
-- This will add basic order management features

-- Add order notifications table (if not exists)
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

-- Add status tracking columns to orders table (if not exist)
DO $$ 
BEGIN
    -- Add status_updated_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'status_updated_at') THEN
        ALTER TABLE public.orders ADD COLUMN status_updated_at TIMESTAMPTZ DEFAULT now();
    END IF;
    
    -- Add points_credited column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'points_credited') THEN
        ALTER TABLE public.orders ADD COLUMN points_credited BOOLEAN DEFAULT false;
    END IF;
    
    -- Add accepted_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'accepted_at') THEN
        ALTER TABLE public.orders ADD COLUMN accepted_at TIMESTAMPTZ;
    END IF;
    
    -- Add preparing_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'preparing_at') THEN
        ALTER TABLE public.orders ADD COLUMN preparing_at TIMESTAMPTZ;
    END IF;
    
    -- Add out_for_delivery_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'out_for_delivery_at') THEN
        ALTER TABLE public.orders ADD COLUMN out_for_delivery_at TIMESTAMPTZ;
    END IF;
    
    -- Add completed_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'completed_at') THEN
        ALTER TABLE public.orders ADD COLUMN completed_at TIMESTAMPTZ;
    END IF;
END $$;

-- Enable RLS for order_notifications
ALTER TABLE public.order_notifications ENABLE ROW LEVEL SECURITY;

-- Create basic RLS policies
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.order_notifications;
CREATE POLICY "Users can view their own notifications" ON public.order_notifications
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert notifications" ON public.order_notifications;
CREATE POLICY "System can insert notifications" ON public.order_notifications
  FOR INSERT WITH CHECK (true);

-- Create simple function to handle new order notifications
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

-- Create trigger for new order notifications (drop if exists first)
DROP TRIGGER IF EXISTS new_order_notification_trigger ON public.orders;
CREATE TRIGGER new_order_notification_trigger
  AFTER INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_order_notification();

-- Update existing orders to have proper status tracking
UPDATE public.orders 
SET 
  status_updated_at = created_at,
  points_credited = CASE WHEN status = 'completed' THEN true ELSE false END
WHERE status_updated_at IS NULL;

-- Test message
SELECT 'Database migration completed successfully!' as status;
