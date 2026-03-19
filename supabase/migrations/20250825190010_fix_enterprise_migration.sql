-- Simplified Enterprise Order Management System
-- Handles existing policies and focuses on core enterprise features

-- 1. ENHANCE ORDERS TABLE FOR HIGH VOLUME
-- Add indexes for better performance on high-volume queries
CREATE INDEX IF NOT EXISTS idx_orders_cafe_id_created_at ON public.orders(cafe_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_status_created_at ON public.orders(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_user_id_created_at ON public.orders(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON public.orders(order_number);

-- Add performance tracking columns
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS processing_time_minutes INTEGER;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS queue_position INTEGER;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS priority_level TEXT DEFAULT 'normal'; -- 'high', 'normal', 'low'
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS estimated_completion_time TIMESTAMPTZ;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS actual_completion_time TIMESTAMPTZ;

-- 2. CREATE ORDER QUEUE MANAGEMENT (with proper policy handling)
CREATE TABLE IF NOT EXISTS public.order_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  queue_position INTEGER NOT NULL,
  priority_level TEXT NOT NULL DEFAULT 'normal',
  status TEXT NOT NULL DEFAULT 'waiting', -- 'waiting', 'processing', 'completed', 'cancelled'
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  UNIQUE(cafe_id, queue_position)
);

-- Enable RLS for order_queue
ALTER TABLE public.order_queue ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "cafe_staff_can_manage_queue" ON public.order_queue;

-- Create policies for order_queue
CREATE POLICY "cafe_staff_can_manage_queue" ON public.order_queue
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff 
      WHERE cafe_staff.cafe_id = order_queue.cafe_id 
      AND cafe_staff.user_id = auth.uid()
      AND cafe_staff.is_active = true
    )
  );

-- 3. CREATE ORDER ANALYTICS TABLE
CREATE TABLE IF NOT EXISTS public.order_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  total_orders INTEGER NOT NULL DEFAULT 0,
  total_revenue DECIMAL(10,2) NOT NULL DEFAULT 0,
  completed_orders INTEGER NOT NULL DEFAULT 0,
  cancelled_orders INTEGER NOT NULL DEFAULT 0,
  average_order_value DECIMAL(10,2) NOT NULL DEFAULT 0,
  average_processing_time DECIMAL(5,2), -- in minutes
  peak_hour INTEGER, -- 0-23
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(cafe_id, date)
);

-- Enable RLS for order_analytics
ALTER TABLE public.order_analytics ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "cafe_staff_can_view_analytics" ON public.order_analytics;

-- Create policies for order_analytics
CREATE POLICY "cafe_staff_can_view_analytics" ON public.order_analytics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff 
      WHERE cafe_staff.cafe_id = order_analytics.cafe_id 
      AND cafe_staff.user_id = auth.uid()
      AND cafe_staff.is_active = true
    )
  );

-- 4. CREATE ITEM ANALYTICS TABLE
CREATE TABLE IF NOT EXISTS public.item_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  menu_item_id UUID NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  quantity_sold INTEGER NOT NULL DEFAULT 0,
  revenue_generated DECIMAL(10,2) NOT NULL DEFAULT 0,
  times_ordered INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(cafe_id, menu_item_id, date)
);

-- Enable RLS for item_analytics
ALTER TABLE public.item_analytics ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "cafe_staff_can_view_item_analytics" ON public.item_analytics;

-- Create policies for item_analytics
CREATE POLICY "cafe_staff_can_view_item_analytics" ON public.item_analytics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff 
      WHERE cafe_staff.cafe_id = item_analytics.cafe_id 
      AND cafe_staff.user_id = auth.uid()
      AND cafe_staff.is_active = true
    )
  );

-- 5. ENHANCE NOTIFICATION SYSTEM FOR HIGH VOLUME
-- Add notification categories and priorities
ALTER TABLE public.order_notifications ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal'; -- 'high', 'normal', 'low'
ALTER TABLE public.order_notifications ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'order'; -- 'order', 'system', 'alert'
ALTER TABLE public.order_notifications ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;

-- Create index for notification performance
CREATE INDEX IF NOT EXISTS idx_notifications_cafe_id_created_at ON public.order_notifications(cafe_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_is_read ON public.order_notifications(user_id, is_read);

-- 6. CREATE SIMPLIFIED BULK OPERATION FUNCTION
-- Function to handle multiple simultaneous orders
CREATE OR REPLACE FUNCTION public.handle_multiple_orders()
RETURNS TRIGGER AS $$
DECLARE
  current_queue_position INTEGER;
  estimated_time TIMESTAMPTZ;
BEGIN
  -- Get next queue position for this cafe
  SELECT COALESCE(MAX(queue_position), 0) + 1 
  INTO current_queue_position
  FROM public.order_queue 
  WHERE cafe_id = NEW.cafe_id AND date(created_at) = date(NEW.created_at);
  
  -- Insert into queue
  INSERT INTO public.order_queue (order_id, cafe_id, queue_position, priority_level)
  VALUES (NEW.id, NEW.cafe_id, current_queue_position, NEW.priority_level);
  
  -- Calculate estimated completion time (30 minutes per order in queue)
  estimated_time := NEW.created_at + (INTERVAL '30 minutes' * current_queue_position);
  
  -- Update order with queue info
  UPDATE public.orders 
  SET 
    queue_position = current_queue_position,
    estimated_completion_time = estimated_time
  WHERE id = NEW.id;
  
  -- Create high-priority notification for cafe
  INSERT INTO public.order_notifications (
    order_id,
    cafe_id,
    user_id,
    notification_type,
    message,
    priority,
    category
  ) VALUES (
    NEW.id,
    NEW.cafe_id,
    NEW.user_id,
    'new_order',
    'New order #' || NEW.order_number || ' received (Queue: #' || current_queue_position || ')',
    'high',
    'order'
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for multiple orders (drop if exists first)
DROP TRIGGER IF EXISTS multiple_orders_trigger ON public.orders;
CREATE TRIGGER multiple_orders_trigger
  AFTER INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_multiple_orders();

-- 7. CREATE SIMPLIFIED ANALYTICS UPDATE FUNCTION
CREATE OR REPLACE FUNCTION public.update_order_analytics()
RETURNS TRIGGER AS $$
DECLARE
  order_date DATE;
BEGIN
  order_date := date(NEW.created_at);
  
  -- Insert or update daily analytics
  INSERT INTO public.order_analytics (
    cafe_id, date, total_orders, total_revenue, completed_orders, 
    cancelled_orders, average_order_value
  )
  SELECT 
    NEW.cafe_id,
    order_date,
    COUNT(*),
    SUM(total_amount),
    COUNT(*) FILTER (WHERE status = 'completed'),
    COUNT(*) FILTER (WHERE status = 'cancelled'),
    AVG(total_amount)
  FROM public.orders 
  WHERE cafe_id = NEW.cafe_id AND date(created_at) = order_date
  ON CONFLICT (cafe_id, date) DO UPDATE SET
    total_orders = EXCLUDED.total_orders,
    total_revenue = EXCLUDED.total_revenue,
    completed_orders = EXCLUDED.completed_orders,
    cancelled_orders = EXCLUDED.cancelled_orders,
    average_order_value = EXCLUDED.average_order_value,
    updated_at = now();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for analytics updates (drop if exists first)
DROP TRIGGER IF EXISTS order_analytics_trigger ON public.orders;
CREATE TRIGGER order_analytics_trigger
  AFTER INSERT OR UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.update_order_analytics();

-- 8. CREATE SIMPLIFIED QUEUE MANAGEMENT FUNCTION
CREATE OR REPLACE FUNCTION public.manage_order_queue()
RETURNS TRIGGER AS $$
BEGIN
  -- When order status changes, update queue
  IF NEW.status = 'confirmed' THEN
    UPDATE public.order_queue 
    SET status = 'processing', started_at = now()
    WHERE order_id = NEW.id;
  ELSIF NEW.status IN ('completed', 'cancelled') THEN
    UPDATE public.order_queue 
    SET status = 'completed', completed_at = now()
    WHERE order_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for queue management (drop if exists first)
DROP TRIGGER IF EXISTS queue_management_trigger ON public.orders;
CREATE TRIGGER queue_management_trigger
  AFTER UPDATE ON public.orders
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION public.manage_order_queue();

-- 9. CREATE SIMPLIFIED PERFORMANCE MONITORING FUNCTION
CREATE OR REPLACE FUNCTION public.calculate_processing_time()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate processing time when order is completed
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    UPDATE public.orders 
    SET 
      processing_time_minutes = EXTRACT(EPOCH FROM (now() - created_at)) / 60,
      actual_completion_time = now()
    WHERE id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for processing time calculation (drop if exists first)
DROP TRIGGER IF EXISTS processing_time_trigger ON public.orders;
CREATE TRIGGER processing_time_trigger
  AFTER UPDATE ON public.orders
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION public.calculate_processing_time();

-- 10. CREATE SIMPLIFIED VIEWS FOR EASY DATA ACCESS
-- View for cafe dashboard analytics
CREATE OR REPLACE VIEW public.cafe_dashboard_view AS
SELECT 
  c.id as cafe_id,
  c.name as cafe_name,
  COUNT(o.id) as total_orders,
  SUM(o.total_amount) as total_revenue,
  AVG(o.total_amount) as average_order_value,
  COUNT(o.id) FILTER (WHERE o.status = 'completed') as completed_orders,
  COUNT(o.id) FILTER (WHERE o.status IN ('received', 'confirmed', 'preparing', 'on_the_way')) as pending_orders,
  COUNT(o.id) FILTER (WHERE date(o.created_at) = date(now())) as today_orders,
  SUM(o.total_amount) FILTER (WHERE date(o.created_at) = date(now())) as today_revenue,
  AVG(o.processing_time_minutes) as avg_processing_time
FROM public.cafes c
LEFT JOIN public.orders o ON c.id = o.cafe_id
GROUP BY c.id, c.name;

-- View for order queue status
CREATE OR REPLACE VIEW public.order_queue_view AS
SELECT 
  oq.id,
  oq.order_id,
  oq.cafe_id,
  oq.queue_position,
  oq.priority_level,
  oq.status as queue_status,
  o.order_number,
  o.status as order_status,
  o.total_amount,
  o.created_at,
  o.estimated_completion_time,
  p.full_name as customer_name,
  p.block as delivery_block
FROM public.order_queue oq
JOIN public.orders o ON oq.order_id = o.id
JOIN public.profiles p ON o.user_id = p.id
ORDER BY oq.cafe_id, oq.queue_position;

-- 11. SET UP SAMPLE DATA FOR TESTING
-- Insert sample analytics data for the last 7 days
INSERT INTO public.order_analytics (cafe_id, date, total_orders, total_revenue, completed_orders, cancelled_orders, average_order_value)
SELECT 
  c.id,
  date(now() - (i || ' days')::INTERVAL),
  FLOOR(RANDOM() * 50) + 10,
  FLOOR(RANDOM() * 5000) + 1000,
  FLOOR(RANDOM() * 40) + 8,
  FLOOR(RANDOM() * 5) + 1,
  FLOOR(RANDOM() * 200) + 100
FROM public.cafes c
CROSS JOIN generate_series(0, 6) i
WHERE c.name = 'Mini Meals'
ON CONFLICT (cafe_id, date) DO NOTHING;

-- Test the simplified enterprise system
SELECT 'Simplified Enterprise Order Management System setup completed! High-volume order handling ready.' as status;
