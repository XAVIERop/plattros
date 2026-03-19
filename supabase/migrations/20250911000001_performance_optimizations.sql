-- Performance Optimizations for High-Concurrency Order Handling
-- This migration adds indexes and optimizations for handling 500+ concurrent orders

-- 1. ADD CRITICAL INDEXES FOR HIGH-VOLUME QUERIES

-- Orders table indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orders_user_id_status ON public.orders(user_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_cafe_id_status ON public.orders(cafe_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at_status ON public.orders(created_at DESC, status);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_block ON public.orders(delivery_block);
CREATE INDEX IF NOT EXISTS idx_orders_table_number ON public.orders(table_number) WHERE table_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_phone_number ON public.orders(phone_number);
CREATE INDEX IF NOT EXISTS idx_orders_estimated_delivery ON public.orders(estimated_delivery);

-- Order items indexes
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item_id ON public.order_items(menu_item_id);

-- Menu items indexes
CREATE INDEX IF NOT EXISTS idx_menu_items_cafe_id_available ON public.menu_items(cafe_id, is_available);
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON public.menu_items(category);
CREATE INDEX IF NOT EXISTS idx_menu_items_price ON public.menu_items(price);

-- Cafes indexes
CREATE INDEX IF NOT EXISTS idx_cafes_active_orders ON public.cafes(is_active, accepting_orders);
CREATE INDEX IF NOT EXISTS idx_cafes_priority ON public.cafes(priority DESC NULLS LAST);

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_user_type ON public.profiles(user_type);
CREATE INDEX IF NOT EXISTS idx_profiles_cafe_id ON public.profiles(cafe_id) WHERE cafe_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_loyalty_tier ON public.profiles(loyalty_tier);

-- 2. ADD COMPOSITE INDEXES FOR COMPLEX QUERIES

-- For cafe dashboard queries
CREATE INDEX IF NOT EXISTS idx_orders_cafe_status_created ON public.orders(cafe_id, status, created_at DESC);

-- For user order history
CREATE INDEX IF NOT EXISTS idx_orders_user_created_status ON public.orders(user_id, created_at DESC, status);

-- For real-time order updates
CREATE INDEX IF NOT EXISTS idx_orders_status_updated ON public.orders(status, updated_at DESC);

-- 3. ADD PARTIAL INDEXES FOR BETTER PERFORMANCE

-- Only index active orders
CREATE INDEX IF NOT EXISTS idx_orders_active ON public.orders(cafe_id, created_at DESC) 
WHERE status IN ('received', 'confirmed', 'preparing', 'on_the_way');

-- Only index available menu items
CREATE INDEX IF NOT EXISTS idx_menu_items_available ON public.menu_items(cafe_id, category, name) 
WHERE is_available = true;

-- 4. OPTIMIZE EXISTING TABLES

-- Add statistics for better query planning
ANALYZE public.orders;
ANALYZE public.order_items;
ANALYZE public.menu_items;
ANALYZE public.cafes;
ANALYZE public.profiles;

-- 5. ADD PERFORMANCE MONITORING FUNCTIONS

-- Function to get order queue status
CREATE OR REPLACE FUNCTION get_order_queue_status(cafe_id_param UUID)
RETURNS TABLE (
  total_orders BIGINT,
  pending_orders BIGINT,
  processing_orders BIGINT,
  avg_processing_time NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_orders,
    COUNT(*) FILTER (WHERE status IN ('received', 'confirmed')) as pending_orders,
    COUNT(*) FILTER (WHERE status = 'preparing') as processing_orders,
    AVG(processing_time_minutes) as avg_processing_time
  FROM public.orders 
  WHERE cafe_id = cafe_id_param 
    AND created_at >= NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql;

-- Function to get system performance metrics
CREATE OR REPLACE FUNCTION get_system_performance_metrics()
RETURNS TABLE (
  total_orders_today BIGINT,
  active_cafes BIGINT,
  avg_order_value NUMERIC,
  peak_hour INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE) as total_orders_today,
    COUNT(DISTINCT cafe_id) FILTER (WHERE created_at >= CURRENT_DATE) as active_cafes,
    AVG(total_amount) FILTER (WHERE created_at >= CURRENT_DATE) as avg_order_value,
    EXTRACT(HOUR FROM created_at) as peak_hour
  FROM public.orders
  WHERE created_at >= CURRENT_DATE
  GROUP BY EXTRACT(HOUR FROM created_at)
  ORDER BY COUNT(*) DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- 6. ADD CONCURRENT ORDER LIMITS

-- Add a function to check if cafe can accept more orders
CREATE OR REPLACE FUNCTION can_accept_order(cafe_id_param UUID, max_concurrent INTEGER DEFAULT 50)
RETURNS BOOLEAN AS $$
DECLARE
  current_orders INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO current_orders
  FROM public.orders
  WHERE cafe_id = cafe_id_param 
    AND status IN ('received', 'confirmed', 'preparing')
    AND created_at >= NOW() - INTERVAL '2 hours';
  
  RETURN current_orders < max_concurrent;
END;
$$ LANGUAGE plpgsql;

-- 7. ADD ORDER PROCESSING OPTIMIZATION

-- Add a function to update order status with queue position
CREATE OR REPLACE FUNCTION update_order_status_with_queue(
  order_id_param UUID,
  new_status TEXT,
  cafe_id_param UUID
)
RETURNS VOID AS $$
DECLARE
  queue_position INTEGER;
BEGIN
  -- Update order status
  UPDATE public.orders 
  SET status = new_status, updated_at = NOW()
  WHERE id = order_id_param;
  
  -- Update queue position if order is being processed
  IF new_status = 'preparing' THEN
    SELECT COALESCE(MAX(queue_position), 0) + 1
    INTO queue_position
    FROM public.orders
    WHERE cafe_id = cafe_id_param 
      AND status = 'preparing'
      AND id != order_id_param;
    
    UPDATE public.orders 
    SET queue_position = queue_position
    WHERE id = order_id_param;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 8. GRANT PERMISSIONS

-- Grant execute permissions on new functions
GRANT EXECUTE ON FUNCTION get_order_queue_status(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_system_performance_metrics() TO authenticated;
GRANT EXECUTE ON FUNCTION can_accept_order(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION update_order_status_with_queue(UUID, TEXT, UUID) TO authenticated;

-- 9. SUCCESS MESSAGE
DO $$
BEGIN
  RAISE NOTICE 'Performance optimizations applied successfully!';
  RAISE NOTICE 'Added % indexes for better query performance', (
    SELECT COUNT(*) FROM pg_indexes 
    WHERE schemaname = 'public' 
    AND tablename IN ('orders', 'order_items', 'menu_items', 'cafes', 'profiles')
  );
END $$;
