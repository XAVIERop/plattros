-- Fix order notification triggers to handle table orders (user_id = NULL)
-- Table orders don't have a user_id, so notifications should only go to cafe staff

BEGIN;

-- Update the notification trigger function to skip user notifications for table orders
CREATE OR REPLACE FUNCTION public.handle_new_order_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- For table orders (user_id IS NULL), only create cafe notification
  -- For regular orders, create user notification as before
  
  -- Only insert notification if user_id is NOT NULL
  -- (Table orders don't need user notifications since there's no user account)
  IF NEW.user_id IS NOT NULL THEN
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
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Also update the status update trigger to handle NULL user_id
CREATE OR REPLACE FUNCTION public.handle_order_status_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process if status actually changed
  IF NEW.status != OLD.status THEN
    -- Update status timestamp
    NEW.status_updated_at = now();
    
    -- Track specific status timestamps
    CASE NEW.status
      WHEN 'accepted' THEN NEW.accepted_at = now();
      WHEN 'preparing' THEN NEW.preparing_at = now();
      WHEN 'out_for_delivery' THEN NEW.out_for_delivery_at = now();
      WHEN 'completed' THEN NEW.completed_at = now();
      ELSE NULL;
    END CASE;
    
    -- Only create notification if user_id is NOT NULL
    -- (Table orders don't need user notifications)
    IF NEW.user_id IS NOT NULL THEN
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
        'Order #' || NEW.order_number || ' status updated to: ' || NEW.status
      );
      
      -- Handle points crediting for completed orders
      IF NEW.status = 'completed' AND NOT NEW.points_credited AND NEW.points_earned > 0 THEN
        -- Add loyalty transaction for points earned
        INSERT INTO public.loyalty_transactions (
          user_id,
          order_id,
          points_change,
          transaction_type,
          description
        ) VALUES (
          NEW.user_id,
          NEW.id,
          NEW.points_earned,
          'earned',
          'Earned ' || NEW.points_earned || ' points for completed order ' || NEW.order_number
        );
        
        -- Update user profile with points
        UPDATE public.profiles 
        SET 
          loyalty_points = loyalty_points + NEW.points_earned,
          total_orders = total_orders + 1,
          total_spent = total_spent + NEW.total_amount
        WHERE id = NEW.user_id;
        
        -- Mark points as credited
        NEW.points_credited = true;
        
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
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMIT;

-- Verification: Check that triggers exist
SELECT 
  trigger_name,
  event_object_table,
  action_timing,
  event_manipulation
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table = 'orders'
  AND trigger_name IN ('new_order_notification_trigger', 'order_status_update_trigger');

