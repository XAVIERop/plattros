-- Manual Order System Support
-- Allows creating orders for walk-in customers without requiring user registration

-- 1. Create a system user for manual orders
-- This user will be used for all manual/walk-in orders
INSERT INTO auth.users (
  id,
  instance_id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '00000000-0000-0000-0000-000000000000'::uuid,
  'authenticated',
  'authenticated',
  'manual-orders@mujfoodclub.com',
  crypt('manual-orders-password', gen_salt('bf')),
  NOW(),
  NULL,
  NULL,
  '{"provider": "email", "providers": ["email"]}',
  '{}',
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
) ON CONFLICT (id) DO NOTHING;

-- 2. Create a system profile for manual orders
INSERT INTO public.profiles (
  id,
  email,
  full_name,
  student_id,
  block,
  phone,
  qr_code,
  loyalty_points,
  loyalty_tier,
  total_orders,
  total_spent,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  'manual-orders@mujfoodclub.com',
  'Manual Orders System',
  'MANUAL-001',
  'B1'::block_type,
  '0000000000',
  'MANUAL-ORDERS-QR',
  0,
  'foodie'::loyalty_tier,
  0,
  0.00,
  NOW(),
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- 3. Add columns to orders table for manual order support
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS customer_name TEXT,
ADD COLUMN IF NOT EXISTS phone_number TEXT,
ADD COLUMN IF NOT EXISTS is_manual_order BOOLEAN DEFAULT false;

-- 4. Update delivery_block to allow more flexible values for manual orders
-- Change from enum to text to allow "Counter", "Walk-in", etc.
ALTER TABLE public.orders 
ALTER COLUMN delivery_block TYPE TEXT;

-- 5. Create a function to handle manual order creation
CREATE OR REPLACE FUNCTION public.create_manual_order(
  p_cafe_id UUID,
  p_customer_name TEXT,
  p_phone_number TEXT DEFAULT NULL,
  p_delivery_block TEXT DEFAULT 'Counter',
  p_delivery_notes TEXT DEFAULT NULL,
  p_total_amount DECIMAL(10,2),
  p_payment_method TEXT DEFAULT 'cod'
)
RETURNS UUID AS $$
DECLARE
  v_order_id UUID;
  v_order_number TEXT;
  v_system_user_id UUID := '00000000-0000-0000-0000-000000000001'::uuid;
BEGIN
  -- Generate unique order number for manual orders
  v_order_number := 'MO-' || EXTRACT(EPOCH FROM NOW())::BIGINT || '-' || substr(md5(random()::text), 1, 6);
  
  -- Create the order
  INSERT INTO public.orders (
    user_id,
    cafe_id,
    order_number,
    status,
    total_amount,
    delivery_block,
    delivery_notes,
    payment_method,
    points_earned,
    estimated_delivery,
    customer_name,
    phone_number,
    is_manual_order,
    created_at,
    updated_at
  ) VALUES (
    v_system_user_id,
    p_cafe_id,
    v_order_number,
    'received'::order_status,
    p_total_amount,
    p_delivery_block,
    p_delivery_notes,
    p_payment_method,
    FLOOR(p_total_amount / 10), -- 1 point per ₹10
    NOW() + INTERVAL '30 minutes', -- 30 minutes estimated delivery
    p_customer_name,
    p_phone_number,
    true,
    NOW(),
    NOW()
  ) RETURNING id INTO v_order_id;
  
  RETURN v_order_id;
END;
$$ LANGUAGE plpgsql;

-- 6. Create a function to add items to manual orders
CREATE OR REPLACE FUNCTION public.add_manual_order_item(
  p_order_id UUID,
  p_menu_item_id UUID,
  p_quantity INTEGER,
  p_unit_price DECIMAL(8,2),
  p_total_price DECIMAL(8,2),
  p_special_instructions TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_item_id UUID;
BEGIN
  INSERT INTO public.order_items (
    order_id,
    menu_item_id,
    quantity,
    unit_price,
    total_price,
    special_instructions
  ) VALUES (
    p_order_id,
    p_menu_item_id,
    p_quantity,
    p_unit_price,
    p_total_price,
    p_special_instructions
  ) RETURNING id INTO v_item_id;
  
  RETURN v_item_id;
END;
$$ LANGUAGE plpgsql;

-- 7. Create coupons table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value DECIMAL(10,2) NOT NULL,
  min_order_amount DECIMAL(10,2) DEFAULT 0,
  max_discount DECIMAL(10,2),
  is_active BOOLEAN NOT NULL DEFAULT true,
  valid_from TIMESTAMPTZ DEFAULT NOW(),
  valid_until TIMESTAMPTZ,
  usage_limit INTEGER,
  used_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 8. Create order_coupons table to track applied coupons
CREATE TABLE IF NOT EXISTS public.order_coupons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  coupon_id UUID NOT NULL REFERENCES public.coupons(id) ON DELETE CASCADE,
  discount_amount DECIMAL(10,2) NOT NULL,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(order_id, coupon_id)
);

-- 9. Enable RLS for new tables
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_coupons ENABLE ROW LEVEL SECURITY;

-- 10. Create RLS policies for coupons
CREATE POLICY "Anyone can view active coupons" ON public.coupons
  FOR SELECT USING (is_active = true);

CREATE POLICY "Cafe staff can manage coupons" ON public.coupons
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff cs 
      WHERE cs.user_id = auth.uid() 
      AND cs.is_active = true
    )
  );

-- 11. Create RLS policies for order_coupons
CREATE POLICY "Cafe staff can view order coupons" ON public.order_coupons
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.cafe_staff cs ON cs.cafe_id = o.cafe_id
      WHERE o.id = order_coupons.order_id
      AND cs.user_id = auth.uid()
      AND cs.is_active = true
    )
  );

CREATE POLICY "Cafe staff can insert order coupons" ON public.order_coupons
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.cafe_staff cs ON cs.cafe_id = o.cafe_id
      WHERE o.id = order_coupons.order_id
      AND cs.user_id = auth.uid()
      AND cs.is_active = true
    )
  );

-- 12. Add some sample coupons
INSERT INTO public.coupons (code, name, description, discount_type, discount_value, min_order_amount, max_discount, is_active) VALUES
('WELCOME10', 'Welcome Discount', '10% off for new customers', 'percentage', 10, 100, 50, true),
('SAVE50', 'Fixed Discount', '₹50 off on orders above ₹200', 'fixed', 50, 200, 50, true),
('STUDENT15', 'Student Special', '15% off for students', 'percentage', 15, 150, 100, true)
ON CONFLICT (code) DO NOTHING;

-- 13. Add comment to explain the manual order system
COMMENT ON FUNCTION public.create_manual_order IS 'Creates a manual order for walk-in customers using the system user';
COMMENT ON FUNCTION public.add_manual_order_item IS 'Adds items to a manual order';
COMMENT ON TABLE public.coupons IS 'Coupon codes for discounts on orders';
COMMENT ON TABLE public.order_coupons IS 'Tracks which coupons were applied to which orders';
