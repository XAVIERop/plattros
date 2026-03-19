-- Add discount_value to loyalty_rewards for discount-type rewards
ALTER TABLE public.loyalty_rewards ADD COLUMN IF NOT EXISTS discount_value INTEGER;
COMMENT ON COLUMN public.loyalty_rewards.discount_value IS 'For discount type: amount in rupees or percentage (e.g. 20 for 20% or ₹20)';

-- RPC: Redeem a reward (deduct points, increment redemptions)
CREATE OR REPLACE FUNCTION public.loyalty_redeem_reward(
  p_cafe_id UUID,
  p_phone TEXT,
  p_reward_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reward RECORD;
  v_customer RECORD;
  v_points_after INT;
BEGIN
  SELECT * INTO v_reward FROM loyalty_rewards
  WHERE id = p_reward_id AND cafe_id = p_cafe_id AND active = true;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Reward not found or inactive');
  END IF;

  SELECT * INTO v_customer FROM loyalty_customers
  WHERE cafe_id = p_cafe_id AND regexp_replace(regexp_replace(COALESCE(phone, ''), '[^0-9]', '', 'g'), '^91', '', 'g') = regexp_replace(regexp_replace(COALESCE(p_phone, ''), '[^0-9]', '', 'g'), '^91', '', 'g');
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Customer not in loyalty program');
  END IF;

  IF COALESCE(v_customer.points, 0) < v_reward.points_cost THEN
    RETURN jsonb_build_object('success', false, 'error', 'Insufficient points');
  END IF;

  v_points_after := v_customer.points - v_reward.points_cost;
  UPDATE loyalty_customers SET points = v_points_after, updated_at = NOW()
  WHERE cafe_id = p_cafe_id AND id = v_customer.id;
  UPDATE loyalty_rewards SET redemptions = redemptions + 1 WHERE id = p_reward_id;

  RETURN jsonb_build_object(
    'success', true,
    'reward_name', v_reward.name,
    'reward_type', v_reward.type,
    'discount_value', v_reward.discount_value,
    'points_remaining', v_points_after
  );
END;
$$;
