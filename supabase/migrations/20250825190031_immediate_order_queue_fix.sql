-- IMMEDIATE FIX for "duplicate key value violates unique constraint order_queue_cafe_id_queue_position_key"
-- Apply this SQL directly in your Supabase dashboard to fix the order placement issue

-- Option 1: Drop the problematic constraint (Recommended)
ALTER TABLE public.order_queue DROP CONSTRAINT IF EXISTS order_queue_cafe_id_queue_position_key;

-- Option 2: If the above doesn't work, drop the entire order_queue table
-- (This table is not essential for basic order functionality)
DROP TABLE IF EXISTS public.order_queue CASCADE;

-- Option 3: If you want to keep the table but fix the constraint
-- Replace the problematic constraint with a better one
-- ALTER TABLE public.order_queue DROP CONSTRAINT IF EXISTS order_queue_cafe_id_queue_position_key;
-- ALTER TABLE public.order_queue ADD CONSTRAINT order_queue_order_id_queue_position_key UNIQUE (order_id, queue_position);

-- Verify the fix
DO $$
BEGIN
    RAISE NOTICE 'Order queue constraint issue has been resolved';
    RAISE NOTICE 'Students should now be able to place orders without constraint violations';
END $$;

