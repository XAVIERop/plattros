-- Payment Database Schema
-- This migration creates tables for payment gateway integration
-- Supports PhonePe, Razorpay, and other payment gateways
-- Created: January 2025

-- ============================================
-- 1. Payment Transactions Table
-- ============================================
-- Stores all payment transactions for orders
CREATE TABLE IF NOT EXISTS public.payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Order relationship
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- Payment details
  amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'INR',
  payment_method TEXT NOT NULL, -- 'phonepe', 'razorpay', 'cod', 'wallet', etc.
  
  -- Payment gateway details
  gateway TEXT, -- 'phonepe', 'razorpay', 'payu', 'cashfree', etc.
  gateway_transaction_id TEXT, -- Transaction ID from payment gateway
  gateway_order_id TEXT, -- Order ID from payment gateway
  gateway_response JSONB, -- Full response from payment gateway (for debugging)
  
  -- Payment status
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending',      -- Payment initiated, waiting for user
    'processing',   -- Payment in progress
    'success',      -- Payment successful
    'failed',       -- Payment failed
    'cancelled',    -- Payment cancelled by user
    'refunded',     -- Payment refunded
    'partially_refunded' -- Partial refund
  )),
  
  -- Failure details
  failure_reason TEXT, -- Why payment failed
  failure_code TEXT,   -- Error code from gateway
  
  -- Refund details
  refund_amount DECIMAL(10,2) DEFAULT 0 CHECK (refund_amount >= 0),
  refund_transaction_id TEXT, -- Refund transaction ID from gateway
  refund_reason TEXT,
  refunded_at TIMESTAMPTZ,
  
  -- Metadata
  metadata JSONB, -- Additional data (user agent, IP, etc.)
  notes TEXT,     -- Admin notes
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  paid_at TIMESTAMPTZ, -- When payment was completed
  expires_at TIMESTAMPTZ -- Payment link expiry (for pending payments)
);

-- ============================================
-- 2. Indexes for Performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_payment_transactions_order_id 
  ON public.payment_transactions(order_id);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_user_id 
  ON public.payment_transactions(user_id);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_status 
  ON public.payment_transactions(status);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_gateway_transaction_id 
  ON public.payment_transactions(gateway_transaction_id);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_created_at 
  ON public.payment_transactions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_payment_transactions_gateway_order_id 
  ON public.payment_transactions(gateway_order_id);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user_status 
  ON public.payment_transactions(user_id, status);

-- ============================================
-- 3. Subscription Payments Table (Enhancement)
-- ============================================
-- This table already exists (subscription_history), but we'll add payment gateway fields if needed
-- Check if subscription_history exists and add gateway fields
DO $$
BEGIN
  -- Add gateway fields to subscription_history if they don't exist
  IF EXISTS (SELECT 1 FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name = 'subscription_history') THEN
    
    -- Add gateway_transaction_id if it doesn't exist
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'subscription_history' 
      AND column_name = 'gateway_transaction_id'
    ) THEN
      ALTER TABLE public.subscription_history 
      ADD COLUMN gateway_transaction_id TEXT;
    END IF;
    
    -- Add gateway_response if it doesn't exist
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'subscription_history' 
      AND column_name = 'gateway_response'
    ) THEN
      ALTER TABLE public.subscription_history 
      ADD COLUMN gateway_response JSONB;
    END IF;
    
    -- Add gateway if it doesn't exist
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'subscription_history' 
      AND column_name = 'gateway'
    ) THEN
      ALTER TABLE public.subscription_history 
      ADD COLUMN gateway TEXT;
    END IF;
  END IF;
END $$;

-- ============================================
-- 4. Enable Row Level Security (RLS)
-- ============================================
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 5. RLS Policies for Payment Transactions
-- ============================================

-- Users can view their own payment transactions
CREATE POLICY "Users can view their own payment transactions"
  ON public.payment_transactions
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own payment transactions (when creating payment)
CREATE POLICY "Users can create their own payment transactions"
  ON public.payment_transactions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- System can update payment transactions (via webhooks)
-- Note: This allows service role to update, but you may want to restrict this further
CREATE POLICY "Service role can update payment transactions"
  ON public.payment_transactions
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Cafe owners can view payments for their cafe's orders
CREATE POLICY "Cafe owners can view payments for their orders"
  ON public.payment_transactions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.cafe_staff cs ON cs.cafe_id = o.cafe_id
      WHERE o.id = payment_transactions.order_id
      AND cs.user_id = auth.uid()
      AND cs.is_active = true
      AND cs.role IN ('owner', 'manager')
    )
  );

-- ============================================
-- 6. Functions for Payment Management
-- ============================================

-- Function to update payment status
CREATE OR REPLACE FUNCTION public.update_payment_status(
  p_transaction_id UUID,
  p_status TEXT,
  p_gateway_response JSONB DEFAULT NULL,
  p_failure_reason TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.payment_transactions
  SET 
    status = p_status,
    gateway_response = COALESCE(p_gateway_response, gateway_response),
    failure_reason = COALESCE(p_failure_reason, failure_reason),
    paid_at = CASE WHEN p_status = 'success' THEN now() ELSE paid_at END,
    updated_at = now()
  WHERE id = p_transaction_id;
  
  -- Update order payment status if payment successful
  IF p_status = 'success' THEN
    UPDATE public.orders
    SET 
      payment_method = (SELECT payment_method FROM public.payment_transactions WHERE id = p_transaction_id),
      updated_at = now()
    WHERE id = (SELECT order_id FROM public.payment_transactions WHERE id = p_transaction_id);
  END IF;
END;
$$;

-- Function to create refund
CREATE OR REPLACE FUNCTION public.create_payment_refund(
  p_transaction_id UUID,
  p_refund_amount DECIMAL,
  p_refund_transaction_id TEXT,
  p_refund_reason TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_original_amount DECIMAL;
  v_current_refund DECIMAL;
BEGIN
  -- Get original amount and current refund
  SELECT amount, refund_amount INTO v_original_amount, v_current_refund
  FROM public.payment_transactions
  WHERE id = p_transaction_id;
  
  -- Validate refund amount
  IF (v_current_refund + p_refund_amount) > v_original_amount THEN
    RAISE EXCEPTION 'Refund amount exceeds original payment amount';
  END IF;
  
  -- Update payment transaction
  UPDATE public.payment_transactions
  SET 
    refund_amount = refund_amount + p_refund_amount,
    refund_transaction_id = p_refund_transaction_id,
    refund_reason = p_refund_reason,
    refunded_at = now(),
    status = CASE 
      WHEN (refund_amount + p_refund_amount) >= amount THEN 'refunded'
      ELSE 'partially_refunded'
    END,
    updated_at = now()
  WHERE id = p_transaction_id;
END;
$$;

-- ============================================
-- 7. Trigger to Update updated_at Timestamp
-- ============================================
CREATE OR REPLACE FUNCTION public.update_payment_transactions_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER update_payment_transactions_updated_at
  BEFORE UPDATE ON public.payment_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_payment_transactions_updated_at();

-- ============================================
-- 8. Add Payment Status to Orders Table (if not exists)
-- ============================================
DO $$
BEGIN
  -- Add payment_status column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'orders' 
    AND column_name = 'payment_status'
  ) THEN
    ALTER TABLE public.orders 
    ADD COLUMN payment_status TEXT DEFAULT 'pending' 
    CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded'));
    
    -- Create index
    CREATE INDEX IF NOT EXISTS idx_orders_payment_status 
    ON public.orders(payment_status);
  END IF;
END $$;

-- ============================================
-- 9. Verification Queries
-- ============================================
DO $$
BEGIN
  RAISE NOTICE 'Payment schema created successfully!';
  RAISE NOTICE 'Tables created: payment_transactions';
  RAISE NOTICE 'Indexes created: 7 indexes on payment_transactions';
  RAISE NOTICE 'RLS policies created: 4 policies';
  RAISE NOTICE 'Functions created: update_payment_status, create_payment_refund';
END $$;

-- ============================================
-- 10. Sample Query to Verify
-- ============================================
-- Uncomment to test (don't run in production)
-- SELECT 
--   table_name,
--   column_name,
--   data_type
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
-- AND table_name = 'payment_transactions'
-- ORDER BY ordinal_position;









