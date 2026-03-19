-- Order Management System with Notifications and Status Tracking

-- Add order notifications table
CREATE TABLE public.order_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  notification_type TEXT NOT NULL, -- 'new_order', 'status_update', 'order_completed'
  message TEXT NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Add cafe staff table for notifications
CREATE TABLE public.cafe_staff (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'staff', -- 'owner', 'manager', 'staff'
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(cafe_id, user_id)
);

-- Update orders table to track status changes
ALTER TABLE public.orders 
ADD COLUMN status_updated_at TIMESTAMPTZ DEFAULT now(),
ADD COLUMN accepted_at TIMESTAMPTZ,
ADD COLUMN preparing_at TIMESTAMPTZ,
ADD COLUMN out_for_delivery_at TIMESTAMPTZ,
ADD COLUMN completed_at TIMESTAMPTZ,
ADD COLUMN points_credited BOOLEAN DEFAULT false;

-- Create function to handle new order notifications
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

-- Create trigger for new order notifications
CREATE TRIGGER new_order_notification_trigger
  AFTER INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_order_notification();

-- Create function to handle status updates
CREATE OR REPLACE FUNCTION public.handle_order_status_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Update status timestamps
  IF NEW.status = 'confirmed' AND OLD.status = 'received' THEN
    NEW.accepted_at = now();
    NEW.status_updated_at = now();
  ELSIF NEW.status = 'preparing' AND OLD.status = 'confirmed' THEN
    NEW.preparing_at = now();
    NEW.status_updated_at = now();
  ELSIF NEW.status = 'on_the_way' AND OLD.status = 'preparing' THEN
    NEW.out_for_delivery_at = now();
    NEW.status_updated_at = now();
  ELSIF NEW.status = 'completed' AND OLD.status = 'on_the_way' THEN
    NEW.completed_at = now();
    NEW.status_updated_at = now();
    
    -- Credit points only when order is completed
    IF NOT NEW.points_credited AND NEW.points_earned > 0 THEN
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
  
  -- Create status update notification
  IF NEW.status != OLD.status THEN
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

-- Create trigger for status updates
CREATE TRIGGER order_status_update_trigger
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_order_status_update();

-- Enable RLS for new tables
ALTER TABLE public.order_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafe_staff ENABLE ROW LEVEL SECURITY;

-- RLS policies for order_notifications
CREATE POLICY "Users can view their own notifications" ON public.order_notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Cafe staff can view cafe notifications" ON public.order_notifications
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff 
      WHERE cafe_staff.cafe_id = order_notifications.cafe_id 
      AND cafe_staff.user_id = auth.uid()
      AND cafe_staff.is_active = true
    )
  );

CREATE POLICY "System can insert notifications" ON public.order_notifications
  FOR INSERT WITH CHECK (true);

-- RLS policies for cafe_staff
CREATE POLICY "Cafe staff can view their assignments" ON public.cafe_staff
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Cafe owners can manage staff" ON public.cafe_staff
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff 
      WHERE cafe_staff.cafe_id = cafe_staff.cafe_id 
      AND cafe_staff.user_id = auth.uid()
      AND cafe_staff.role IN ('owner', 'manager')
      AND cafe_staff.is_active = true
    )
  );

-- Add trigger for updated_at on cafe_staff
CREATE TRIGGER update_cafe_staff_updated_at BEFORE UPDATE ON public.cafe_staff
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Insert sample cafe staff (you can modify these)
INSERT INTO public.cafe_staff (cafe_id, user_id, role) VALUES
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 
 (SELECT id FROM public.profiles WHERE email = 'pulkit.229302047@muj.manipal.edu'), 'owner');

-- Update existing orders to have proper status tracking
UPDATE public.orders 
SET 
  status_updated_at = created_at,
  points_credited = CASE WHEN status = 'completed' THEN true ELSE false END
WHERE status_updated_at IS NULL;
