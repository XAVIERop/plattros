-- Simple fix: Make user_id nullable in order_notifications table
-- This allows notifications for table orders where user_id is NULL

BEGIN;

-- Check if user_id is NOT NULL and change it to nullable
DO $$
BEGIN
  -- Alter the column to allow NULL values
  ALTER TABLE public.order_notifications 
  ALTER COLUMN user_id DROP NOT NULL;
  
  RAISE NOTICE 'Made user_id nullable in order_notifications table';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Could not alter user_id column: %', SQLERRM;
END $$;

-- Update the trigger to handle NULL user_id gracefully
CREATE OR REPLACE FUNCTION public.handle_new_order_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- Create notification for all orders
  -- For table orders (user_id IS NULL), this creates a cafe-only notification
  -- For regular orders, this creates a user notification
  INSERT INTO public.order_notifications (
    order_id,
    cafe_id,
    user_id,
    notification_type,
    message
  ) VALUES (
    NEW.id,
    NEW.cafe_id,
    NEW.user_id, -- Can be NULL for table orders
    'new_order',
    'New order #' || NEW.order_number || ' received for ₹' || NEW.total_amount
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMIT;

-- Verify the change
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'order_notifications'
  AND column_name = 'user_id';

