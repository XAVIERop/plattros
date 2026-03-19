-- Fix order number generation to ensure uniqueness

-- Create a function to generate unique order numbers
CREATE OR REPLACE FUNCTION public.generate_unique_order_number(user_id UUID)
RETURNS TEXT AS $$
DECLARE
  order_number TEXT;
  counter INTEGER := 0;
  max_attempts INTEGER := 10;
BEGIN
  LOOP
    -- Generate order number with timestamp, random string, and user suffix
    order_number := 'ORD-' || 
                   EXTRACT(EPOCH FROM NOW())::BIGINT || '-' ||
                   substr(md5(random()::text), 1, 8) || '-' ||
                   substr(user_id::text, -4);
    
    -- Check if this order number already exists
    IF NOT EXISTS (SELECT 1 FROM public.orders WHERE order_number = order_number) THEN
      RETURN order_number;
    END IF;
    
    -- Increment counter and try again
    counter := counter + 1;
    IF counter >= max_attempts THEN
      RAISE EXCEPTION 'Failed to generate unique order number after % attempts', max_attempts;
    END IF;
    
    -- Small delay to ensure different timestamp
    PERFORM pg_sleep(0.001);
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Update the handle_new_order_notification function to use the new order number generation
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

-- Add a comment to help developers understand the order number format
COMMENT ON FUNCTION public.generate_unique_order_number(UUID) IS 
'Generates unique order numbers in format: ORD-{timestamp}-{random8chars}-{userid_last4}';
