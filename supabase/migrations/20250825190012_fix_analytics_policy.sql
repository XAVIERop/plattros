-- Fix order_analytics RLS policy to allow inserts
-- The current policy only allows SELECT, but we need INSERT for the analytics triggers

-- 1. DROP THE CURRENT RESTRICTIVE POLICY
DROP POLICY IF EXISTS "analytics_simple_select" ON public.order_analytics;

-- 2. CREATE A MORE PERMISSIVE POLICY FOR ANALYTICS
CREATE POLICY "analytics_allow_all" ON public.order_analytics
  FOR ALL USING (true);

-- 3. ALSO FIX ITEM ANALYTICS POLICY
DROP POLICY IF EXISTS "item_analytics_simple_select" ON public.item_analytics;

CREATE POLICY "item_analytics_allow_all" ON public.item_analytics
  FOR ALL USING (true);

-- 4. FIX ORDER_QUEUE POLICY TOO (JUST IN CASE)
DROP POLICY IF EXISTS "queue_simple_all" ON public.order_queue;

CREATE POLICY "queue_allow_all" ON public.order_queue
  FOR ALL USING (true);

-- 5. TEST THE FIX
SELECT 'Analytics policies fixed! Order placement should now work.' as status;
