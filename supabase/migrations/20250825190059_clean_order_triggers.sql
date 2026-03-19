-- Clean up all conflicting triggers and create a single, proper trigger
-- This fixes the status reversion issue by ensuring only one trigger handles order updates

-- 1. DROP ALL EXISTING TRIGGERS
DROP TRIGGER IF EXISTS order_status_update_trigger ON public.orders;
DROP TRIGGER IF EXISTS order_analytics_trigger ON public.orders;
DROP TRIGGER IF EXISTS queue_management_trigger ON public.orders;
DROP TRIGGER IF EXISTS new_order_notification_trigger ON public.orders;

-- 2. DROP ALL EXISTING FUNCTIONS
DROP FUNCTION IF EXISTS public.handle_order_status_update();
DROP FUNCTION IF EXISTS public.update_order_analytics();
DROP FUNCTION IF EXISTS public.manage_order_queue();
DROP FUNCTION IF EXISTS public.handle_new_order_notification();

-- 3. CREATE A SINGLE, CLEAN FUNCTION FOR NEW ORDERS
CREATE OR REPLACE FUNCTION public.handle_new_order()
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

-- 4. CREATE A SINGLE, CLEAN FUNCTION FOR STATUS UPDATES
CREATE OR REPLACE FUNCTION public.handle_order_status_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process if status actually changed
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    
    -- Update status_updated_at only when status changes
    NEW.status_updated_at = now();
    
    -- Add specific status timestamps only when advancing
    CASE NEW.status
      WHEN 'confirmed' THEN
        IF OLD.status = 'received' THEN
          NEW.accepted_at = now();
        END IF;
      WHEN 'preparing' THEN
        IF OLD.status IN ('received', 'confirmed') THEN
          NEW.preparing_at = now();
        END IF;
      WHEN 'on_the_way' THEN
        IF OLD.status IN ('received', 'confirmed', 'preparing') THEN
          NEW.out_for_delivery_at = now();
        END IF;
      WHEN 'completed' THEN
        IF OLD.status IN ('received', 'confirmed', 'preparing', 'on_the_way') THEN
          NEW.completed_at = now();
          NEW.points_credited = true;
          
          -- Credit points to user only when order is completed
          UPDATE public.profiles 
          SET 
            loyalty_points = loyalty_points + NEW.points_earned,
            total_orders = total_orders + 1,
            total_spent = total_spent + NEW.total_amount
          WHERE id = NEW.user_id;
          
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
    END CASE;
    
    -- Create status update notification only when status actually changes
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
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. CREATE CLEAN TRIGGERS
CREATE TRIGGER new_order_trigger
  AFTER INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_order();

CREATE TRIGGER order_status_update_trigger
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION public.handle_order_status_update();
