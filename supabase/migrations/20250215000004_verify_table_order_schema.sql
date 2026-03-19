-- Verify that all required columns exist for table orders
-- This ensures the schema supports the new table_order flow

-- Check current orders table schema
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'orders'
  AND column_name IN (
    'user_id',
    'cafe_id', 
    'order_type',
    'table_number',
    'phone_number',
    'customer_name',
    'delivery_notes',
    'total_amount',
    'status'
  )
ORDER BY column_name;

-- Expected output should show all these columns exist
-- user_id should be nullable
-- table_number should exist (text, nullable)
-- phone_number should exist (text, nullable)
-- order_type should exist (text, default 'delivery')

