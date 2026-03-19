-- =====================================================
-- ADD 'ready' STATUS TO ORDER_STATUS ENUM
-- =====================================================
-- Adds 'ready' status for when order is ready for pickup
-- =====================================================

-- Add 'ready' to the order_status enum
DO $$ 
BEGIN
  -- Check if 'ready' already exists in the enum
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'ready' 
    AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'order_status')
  ) THEN
    ALTER TYPE order_status ADD VALUE 'ready';
    RAISE NOTICE 'Added "ready" status to order_status enum';
  ELSE
    RAISE NOTICE '"ready" status already exists in order_status enum';
  END IF;
END $$;

-- Verify the enum values
SELECT 
  enumlabel as status_value,
  enumsortorder as sort_order
FROM pg_enum
WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'order_status')
ORDER BY enumsortorder;

COMMENT ON TYPE order_status IS 
  'Order status values: received, confirmed, preparing, ready, on_the_way, completed, cancelled';


