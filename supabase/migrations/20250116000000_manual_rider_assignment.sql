-- =====================================================
-- MANUAL RIDER ASSIGNMENT FUNCTION
-- =====================================================
-- Allows cafes to manually assign a specific rider to an order
-- =====================================================

CREATE OR REPLACE FUNCTION public.manual_assign_delivery_rider(
  p_order_id UUID,
  p_rider_id UUID,
  p_delivery_maps_link TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order RECORD;
  v_cafe RECORD;
  v_rider RECORD;
  v_assignment_id UUID;
  v_pickup_lat NUMERIC;
  v_pickup_lng NUMERIC;
  v_delivery_coords JSON;
  v_delivery_lat NUMERIC;
  v_delivery_lng NUMERIC;
  v_distance NUMERIC;
  v_earnings JSON;
BEGIN
  -- Get order details
  SELECT * INTO v_order FROM orders WHERE id = p_order_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Order not found'
    );
  END IF;
  
  -- Check if order already has a rider assigned
  IF v_order.delivery_rider_id IS NOT NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Order already has a rider assigned'
    );
  END IF;
  
  -- Get cafe details (pickup location)
  SELECT * INTO v_cafe FROM cafes WHERE id = v_order.cafe_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Cafe not found'
    );
  END IF;
  
  -- Check if cafe has coordinates
  IF v_cafe.latitude IS NULL OR v_cafe.longitude IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Cafe coordinates not set. Please add cafe coordinates first.'
    );
  END IF;
  
  v_pickup_lat := v_cafe.latitude;
  v_pickup_lng := v_cafe.longitude;
  
  -- Get rider details
  SELECT * INTO v_rider FROM delivery_riders WHERE id = p_rider_id AND is_active = true;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Rider not found or inactive'
    );
  END IF;
  
  -- Get delivery location coordinates
  v_delivery_coords := get_delivery_location_coords(p_order_id);
  v_delivery_lat := (v_delivery_coords->>'latitude')::NUMERIC;
  v_delivery_lng := (v_delivery_coords->>'longitude')::NUMERIC;
  
  -- Calculate distance from cafe to delivery location
  v_distance := calculate_distance_km(v_pickup_lat, v_pickup_lng, v_delivery_lat, v_delivery_lng);
  
  -- Calculate earnings
  v_earnings := calculate_delivery_earnings(
    p_order_id,
    v_distance,
    v_order.total_amount,
    v_order.created_at
  );
  
  -- Create assignment
  INSERT INTO delivery_assignments (
    order_id,
    rider_id,
    status,
    estimated_delivery_time,
    distance_km,
    base_earnings,
    distance_surge,
    delivery_fee,
    peak_bonus,
    total_earnings,
    is_peak_hour
  ) VALUES (
    p_order_id,
    p_rider_id,
    'assigned',
    v_order.estimated_delivery,
    v_distance,
    (v_earnings->>'base_earnings')::NUMERIC,
    (v_earnings->>'distance_surge')::NUMERIC,
    (v_earnings->>'delivery_fee')::NUMERIC,
    (v_earnings->>'peak_bonus')::NUMERIC,
    (v_earnings->>'total_earnings')::NUMERIC,
    (v_earnings->>'is_peak_hour')::BOOLEAN
  )
  RETURNING id INTO v_assignment_id;
  
  -- Update order with rider assignment and Google Maps link if provided
  UPDATE orders
  SET 
    delivery_rider_id = p_rider_id,
    delivery_assigned_at = now(),
    delivery_maps_link = COALESCE(p_delivery_maps_link, delivery_maps_link)
  WHERE id = p_order_id;
  
  -- Update rider status to busy (DISABLED - riders can manage their own status)
  -- UPDATE delivery_riders
  -- SET status = 'busy'
  -- WHERE id = p_rider_id;
  
  -- Return success
  RETURN json_build_object(
    'success', true,
    'assignment_id', v_assignment_id,
    'rider_id', p_rider_id,
    'rider_name', v_rider.full_name,
    'distance_km', v_distance,
    'earnings', v_earnings
  );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.manual_assign_delivery_rider(UUID, UUID, TEXT) TO authenticated, anon;

COMMENT ON FUNCTION public.manual_assign_delivery_rider(UUID, UUID, TEXT) IS 
  'Manually assign a specific rider to a delivery order. Creates delivery assignment and updates order and rider status. Optionally accepts a Google Maps link for the delivery location.';

