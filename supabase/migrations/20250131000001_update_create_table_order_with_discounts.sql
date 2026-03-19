-- =====================================================
-- 📝 UPDATE create_table_order TO SUPPORT DISCOUNTS
-- =====================================================
-- This migration updates the create_table_order RPC function
-- to accept and save discount_amount, original_total_amount,
-- and applied_offers information
-- =====================================================

-- Drop all possible variations of the function
DO $$
BEGIN
  -- Drop function with any possible signature
  DROP FUNCTION IF EXISTS public.create_table_order CASCADE;
EXCEPTION
  WHEN OTHERS THEN
    -- Function might not exist, continue
    NULL;
END $$;

-- Create updated function with discount support
-- Note: Required parameters must come before optional ones (with defaults)
CREATE OR REPLACE FUNCTION public.create_table_order(
  p_cafe_id UUID,
  p_table_number TEXT,
  p_customer_name TEXT,
  p_phone_number TEXT,
  p_total_amount DECIMAL(10,2),
  p_order_items JSONB,
  p_delivery_notes TEXT DEFAULT NULL,
  p_original_total_amount DECIMAL(10,2) DEFAULT NULL,
  p_discount_amount DECIMAL(10,2) DEFAULT 0,
  p_applied_offers JSONB DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_order_id UUID;
  v_order_number TEXT;
  v_cafe_slug TEXT;
  v_order_count INTEGER;
  v_applied_offer JSONB;
BEGIN
  -- Get cafe slug for order number generation
  SELECT slug INTO v_cafe_slug
  FROM public.cafes
  WHERE id = p_cafe_id;
  
  IF v_cafe_slug IS NULL THEN
    RAISE EXCEPTION 'Cafe not found';
  END IF;
  
  -- Generate order number (e.g., BAN000001)
  SELECT COALESCE(MAX(CAST(SUBSTRING(order_number FROM '[0-9]+$') AS INTEGER)), 0) + 1
  INTO v_order_count
  FROM public.orders
  WHERE cafe_id = p_cafe_id
    AND order_number ~ ('^' || UPPER(SUBSTRING(v_cafe_slug FROM 1 FOR 3)) || '[0-9]+$');
  
  v_order_number := UPPER(SUBSTRING(v_cafe_slug FROM 1 FOR 3)) || 
                    LPAD(v_order_count::TEXT, 6, '0');
  
  -- Create the order with discount information
  INSERT INTO public.orders (
    user_id,
    cafe_id,
    order_number,
    status,
    total_amount,
    original_total_amount,
    discount_amount,
    delivery_block,
    delivery_notes,
    payment_method,
    points_earned,
    estimated_delivery,
    customer_name,
    phone_number,
    table_number,
    order_type,
    created_at,
    updated_at
  ) VALUES (
    NULL, -- Table orders don't have a user_id
    p_cafe_id,
    v_order_number,
    'received'::order_status,
    p_total_amount,
    COALESCE(p_original_total_amount, p_total_amount), -- Use original_total_amount if provided, otherwise use total_amount
    COALESCE(p_discount_amount, 0),
    'DINE_IN'::block_type,
    p_delivery_notes,
    'cash',
    0,
    NOW() + INTERVAL '30 minutes',
    p_customer_name,
    p_phone_number,
    p_table_number,
    'table_order',
    NOW(),
    NOW()
  ) RETURNING id INTO v_order_id;
  
  -- Insert order items
  FOR v_applied_offer IN SELECT * FROM jsonb_array_elements(p_order_items)
  LOOP
    INSERT INTO public.order_items (
      order_id,
      menu_item_id,
      quantity,
      unit_price,
      total_price,
      special_instructions
    ) VALUES (
      v_order_id,
      (v_applied_offer->>'menu_item_id')::UUID,
      (v_applied_offer->>'quantity')::INTEGER,
      (v_applied_offer->>'unit_price')::DECIMAL(10,2),
      (v_applied_offer->>'total_price')::DECIMAL(10,2),
      v_applied_offer->>'special_instructions'
    );
  END LOOP;
  
  -- Insert applied offers if provided
  IF p_applied_offers IS NOT NULL AND jsonb_array_length(p_applied_offers) > 0 THEN
    FOR v_applied_offer IN SELECT * FROM jsonb_array_elements(p_applied_offers)
    LOOP
      INSERT INTO public.order_applied_offers (
        order_id,
        offer_id,
        discount_amount,
        offer_name
      ) VALUES (
        v_order_id,
        (v_applied_offer->>'offer_id')::UUID,
        (v_applied_offer->>'discount_amount')::DECIMAL(10,2),
        v_applied_offer->>'offer_name'
      )
      ON CONFLICT (order_id, offer_id) DO NOTHING;
    END LOOP;
  END IF;
  
  -- Return order details
  RETURN jsonb_build_object(
    'id', v_order_id,
    'order_number', v_order_number,
    'total_amount', p_total_amount,
    'original_total_amount', COALESCE(p_original_total_amount, p_total_amount),
    'discount_amount', COALESCE(p_discount_amount, 0)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.create_table_order(
  UUID, TEXT, TEXT, TEXT, DECIMAL, JSONB, TEXT, DECIMAL, DECIMAL, JSONB
) TO authenticated, anon;

-- Add comment
COMMENT ON FUNCTION public.create_table_order IS 'Creates a table order with support for discounts and applied offers';

