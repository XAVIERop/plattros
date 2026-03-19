-- New Reward System Migration
-- Implements tier-based automatic discounts and 1:1 point system

-- Update profiles table to track monthly spending for tier maintenance
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS monthly_spending DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_maintenance_reset TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Create function to calculate new tier based on total spending
CREATE OR REPLACE FUNCTION get_tier_by_spend(total_spent DECIMAL)
RETURNS TEXT AS $$
BEGIN
  IF total_spent >= 5000 THEN
    RETURN 'connoisseur';
  ELSIF total_spent >= 2000 THEN
    RETURN 'gourmet';
  ELSE
    RETURN 'foodie';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Create function to calculate simple points based on tier only
CREATE OR REPLACE FUNCTION calculate_new_points(
  order_amount DECIMAL,
  user_tier TEXT,
  is_new_user BOOLEAN DEFAULT FALSE,
  new_user_orders_count INTEGER DEFAULT 0
)
RETURNS INTEGER AS $$
DECLARE
  points_rate INTEGER;
  base_points INTEGER;
BEGIN
  -- Set points rate based on tier only
  CASE user_tier
    WHEN 'connoisseur' THEN points_rate := 10; -- 10% points
    WHEN 'gourmet' THEN points_rate := 5;     -- 5% points
    ELSE points_rate := 5;                    -- 5% points for foodie
  END CASE;
  
  -- Very simple: just base points (no multipliers, no bonuses)
  base_points := FLOOR((order_amount * points_rate) / 100);
  
  RETURN base_points;
END;
$$ LANGUAGE plpgsql;

-- Create function to calculate loyalty discount
CREATE OR REPLACE FUNCTION calculate_loyalty_discount(
  order_amount DECIMAL,
  user_tier TEXT
)
RETURNS DECIMAL AS $$
DECLARE
  discount_rate INTEGER;
BEGIN
  -- Set discount rate based on tier
  CASE user_tier
    WHEN 'connoisseur' THEN discount_rate := 20; -- 20% discount
    WHEN 'gourmet' THEN discount_rate := 10;     -- 10% discount
    ELSE discount_rate := 5;                     -- 5% discount for foodie
  END CASE;
  
  RETURN FLOOR((order_amount * discount_rate) / 100);
END;
$$ LANGUAGE plpgsql;

-- Create function to calculate maximum redeemable points (10% of order value)
CREATE OR REPLACE FUNCTION calculate_max_redeemable_points(order_amount DECIMAL)
RETURNS INTEGER AS $$
BEGIN
  RETURN FLOOR(order_amount * 0.1); -- 10% of order value
END;
$$ LANGUAGE plpgsql;

-- Create function to update user tier based on total spending
CREATE OR REPLACE FUNCTION update_user_tier(user_id UUID)
RETURNS TEXT AS $$
DECLARE
  total_spent DECIMAL;
  new_tier TEXT;
  current_tier TEXT;
BEGIN
  -- Get current total spending
  SELECT COALESCE(SUM(total_amount), 0) INTO total_spent
  FROM public.orders 
  WHERE user_id = user_id 
    AND status = 'completed';
  
  -- Calculate new tier
  new_tier := get_tier_by_spend(total_spent);
  
  -- Get current tier
  SELECT loyalty_tier INTO current_tier
  FROM public.profiles
  WHERE id = user_id;
  
  -- Update tier if changed
  IF new_tier != current_tier THEN
    UPDATE public.profiles
    SET loyalty_tier = new_tier
    WHERE id = user_id;
    
    -- Log tier change
    INSERT INTO public.loyalty_transactions (
      user_id,
      points_change,
      transaction_type,
      description
    ) VALUES (
      user_id,
      0,
      'tier_change',
      'Tier updated from ' || current_tier || ' to ' || new_tier
    );
  END IF;
  
  RETURN new_tier;
END;
$$ LANGUAGE plpgsql;

-- Create function to check and enforce tier maintenance
CREATE OR REPLACE FUNCTION check_tier_maintenance(user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  user_tier TEXT;
  maintenance_required DECIMAL;
  monthly_spent DECIMAL;
  last_reset TIMESTAMP WITH TIME ZONE;
  current_month_start TIMESTAMP WITH TIME ZONE;
  total_spent DECIMAL;
  new_tier TEXT;
BEGIN
  -- Get user tier and maintenance requirements
  SELECT loyalty_tier, monthly_spending, last_maintenance_reset
  INTO user_tier, monthly_spent, last_reset
  FROM public.profiles
  WHERE id = user_id;
  
  -- Check if we need to reset monthly spending (new month)
  current_month_start := DATE_TRUNC('month', NOW());
  IF last_reset < current_month_start THEN
    -- Reset monthly spending for new month
    UPDATE public.profiles
    SET monthly_spending = 0, last_maintenance_reset = NOW()
    WHERE id = user_id;
    
    monthly_spent := 0;
  END IF;
  
  -- Set maintenance requirements based on tier
  CASE user_tier
    WHEN 'connoisseur' THEN maintenance_required := 5000;
    WHEN 'gourmet' THEN maintenance_required := 2000;
    ELSE RETURN TRUE; -- Foodie tier has no maintenance requirement
  END CASE;
  
  -- Check if maintenance requirement is met
  IF monthly_spent < maintenance_required THEN
    -- Downgrade user tier
    CASE user_tier
      WHEN 'connoisseur' THEN
        UPDATE public.profiles
        SET loyalty_tier = 'gourmet'
        WHERE id = user_id;
      WHEN 'gourmet' THEN
        UPDATE public.profiles
        SET loyalty_tier = 'foodie'
        WHERE id = user_id;
    END CASE;
    
    -- Log tier downgrade
    INSERT INTO public.loyalty_transactions (
      user_id,
      points_change,
      transaction_type,
      description
    ) VALUES (
      user_id,
      0,
      'tier_downgrade',
      'Tier downgraded due to maintenance requirement not met'
    );
    
    RETURN FALSE;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Create function to track monthly spending
CREATE OR REPLACE FUNCTION track_monthly_spending(
  user_id UUID,
  order_amount DECIMAL
)
RETURNS VOID AS $$
DECLARE
  current_month_start TIMESTAMP WITH TIME ZONE;
  last_reset TIMESTAMP WITH TIME ZONE;
BEGIN
  current_month_start := DATE_TRUNC('month', NOW());
  
  -- Get last reset time
  SELECT last_maintenance_reset INTO last_reset
  FROM public.profiles
  WHERE id = user_id;
  
  -- Reset monthly spending if new month
  IF last_reset < current_month_start THEN
    UPDATE public.profiles
    SET monthly_spending = order_amount, last_maintenance_reset = NOW()
    WHERE id = user_id;
  ELSE
    -- Add to existing monthly spending
    UPDATE public.profiles
    SET monthly_spending = monthly_spending + order_amount
    WHERE id = user_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Create function to check tier maintenance only (separate from points redemption)
CREATE OR REPLACE FUNCTION check_tier_maintenance_only(user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  user_tier TEXT;
  maintenance_required DECIMAL;
  monthly_spent DECIMAL;
  last_reset TIMESTAMP WITH TIME ZONE;
  current_month_start TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Get user tier and maintenance requirements
  SELECT loyalty_tier, monthly_spending, last_maintenance_reset
  INTO user_tier, monthly_spent, last_reset
  FROM public.profiles
  WHERE id = user_id;
  
  -- Check if we need to reset monthly spending (new month)
  current_month_start := DATE_TRUNC('month', NOW());
  IF last_reset < current_month_start THEN
    -- Reset monthly spending for new month
    UPDATE public.profiles
    SET monthly_spending = 0, last_maintenance_reset = NOW()
    WHERE id = user_id;
    
    monthly_spent := 0;
  END IF;
  
  -- Set maintenance requirements based on tier
  CASE user_tier
    WHEN 'connoisseur' THEN maintenance_required := 5000;
    WHEN 'gourmet' THEN maintenance_required := 2000;
    ELSE RETURN TRUE; -- Foodie tier has no maintenance requirement
  END CASE;
  
  -- Check if maintenance requirement is met
  IF monthly_spent < maintenance_required THEN
    -- Downgrade user tier
    CASE user_tier
      WHEN 'connoisseur' THEN
        UPDATE public.profiles
        SET loyalty_tier = 'gourmet'
        WHERE id = user_id;
      WHEN 'gourmet' THEN
        UPDATE public.profiles
        SET loyalty_tier = 'foodie'
        WHERE id = user_id;
    END CASE;
    
    -- Log tier downgrade
    INSERT INTO public.loyalty_transactions (
      user_id,
      points_change,
      transaction_type,
      description
    ) VALUES (
      user_id,
      0,
      'tier_downgrade',
      'Tier downgraded due to maintenance requirement not met'
    );
    
    RETURN FALSE;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_tier_by_spend(DECIMAL) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION calculate_new_points(DECIMAL, TEXT, BOOLEAN, INTEGER) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION calculate_loyalty_discount(DECIMAL, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION calculate_max_redeemable_points(DECIMAL) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION update_user_tier(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION check_tier_maintenance(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION check_tier_maintenance_only(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION track_monthly_spending(UUID, DECIMAL) TO authenticated, anon;

-- Update existing users to have correct tiers based on their spending
DO $$
DECLARE
  user_record RECORD;
  total_spent DECIMAL;
  new_tier TEXT;
BEGIN
  FOR user_record IN SELECT id FROM public.profiles LOOP
    -- Calculate total spending for user
    SELECT COALESCE(SUM(total_amount), 0) INTO total_spent
    FROM public.orders 
    WHERE user_id = user_record.id 
      AND status = 'completed';
    
    -- Get new tier
    new_tier := get_tier_by_spend(total_spent);
    
    -- Update user tier
    UPDATE public.profiles
    SET loyalty_tier = new_tier
    WHERE id = user_record.id;
  END LOOP;
END $$;
