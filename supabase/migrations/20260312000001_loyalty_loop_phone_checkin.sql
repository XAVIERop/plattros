-- =====================================================
-- LOYALTY LOOP: Phone-based check-in system
-- =====================================================
-- For Loyalty Loop: customers check in via QR with phone (no auth).
-- Coexists with cafe_loyalty_points (user_id-based) used by POS/Food Club.

-- 1. loyalty_customers: phone-based customer per cafe
CREATE TABLE IF NOT EXISTS public.loyalty_customers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
    phone TEXT NOT NULL,
    name TEXT,
    points INTEGER NOT NULL DEFAULT 0,
    total_check_ins INTEGER NOT NULL DEFAULT 0,
    last_check_in_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(cafe_id, phone)
);

-- 2. loyalty_check_ins: each check-in event
CREATE TABLE IF NOT EXISTS public.loyalty_check_ins (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
    phone TEXT NOT NULL,
    points_awarded INTEGER NOT NULL DEFAULT 50,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. loyalty_feedback: feedback after check-in
CREATE TABLE IF NOT EXISTS public.loyalty_feedback (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
    phone TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_loyalty_customers_cafe ON public.loyalty_customers(cafe_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_customers_phone ON public.loyalty_customers(cafe_id, phone);
CREATE INDEX IF NOT EXISTS idx_loyalty_check_ins_cafe ON public.loyalty_check_ins(cafe_id);
CREATE INDEX IF NOT EXISTS idx_loyalty_check_ins_created ON public.loyalty_check_ins(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_loyalty_feedback_cafe ON public.loyalty_feedback(cafe_id);

-- RLS
ALTER TABLE public.loyalty_customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_check_ins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_feedback ENABLE ROW LEVEL SECURITY;

-- Anyone can insert check-ins and feedback (anon for QR check-in flow)
CREATE POLICY "anon_insert_check_ins" ON public.loyalty_check_ins
    FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon_insert_feedback" ON public.loyalty_feedback
    FOR INSERT TO anon WITH CHECK (true);

-- Service role / RPC will handle loyalty_customers upsert; allow anon to call RPC
-- For direct inserts we use a trigger or RPC. Simpler: allow anon to insert into loyalty_customers
-- only when it's part of check-in flow. Actually, we'll use an RPC to do the atomic upsert.
-- Let's allow anon to insert into loyalty_check_ins and loyalty_feedback.
-- loyalty_customers: we need to upsert. Use RPC.

-- Cafe staff/owners can view their cafe's data
CREATE POLICY "cafe_staff_view_loyalty_customers" ON public.loyalty_customers
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.cafe_staff cs
            WHERE cs.cafe_id = loyalty_customers.cafe_id
            AND cs.user_id = auth.uid()
            AND cs.is_active = true
        )
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
            AND p.cafe_id = loyalty_customers.cafe_id
        )
    );

CREATE POLICY "cafe_staff_view_loyalty_check_ins" ON public.loyalty_check_ins
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.cafe_staff cs
            WHERE cs.cafe_id = loyalty_check_ins.cafe_id
            AND cs.user_id = auth.uid()
            AND cs.is_active = true
        )
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
            AND p.cafe_id = loyalty_check_ins.cafe_id
        )
    );

CREATE POLICY "cafe_staff_view_loyalty_feedback" ON public.loyalty_feedback
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.cafe_staff cs
            WHERE cs.cafe_id = loyalty_feedback.cafe_id
            AND cs.user_id = auth.uid()
            AND cs.is_active = true
        )
        OR EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
            AND p.cafe_id = loyalty_feedback.cafe_id
        )
    );

-- RPC: process check-in (upsert customer, insert check-in, award points)
CREATE OR REPLACE FUNCTION public.loyalty_check_in(
    p_cafe_id UUID,
    p_phone TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_points INTEGER := 50;
BEGIN
    -- Normalize phone: strip spaces
    p_phone := regexp_replace(trim(p_phone), '\s', '', 'g');
    IF length(p_phone) < 10 THEN
        RAISE EXCEPTION 'Invalid phone number';
    END IF;

    -- Upsert loyalty_customers
    INSERT INTO public.loyalty_customers (cafe_id, phone, points, total_check_ins, last_check_in_at, updated_at)
    VALUES (p_cafe_id, p_phone, v_points, 1, NOW(), NOW())
    ON CONFLICT (cafe_id, phone) DO UPDATE SET
        points = loyalty_customers.points + v_points,
        total_check_ins = loyalty_customers.total_check_ins + 1,
        last_check_in_at = NOW(),
        updated_at = NOW();

    -- Insert check-in record
    INSERT INTO public.loyalty_check_ins (cafe_id, phone, points_awarded)
    VALUES (p_cafe_id, p_phone, v_points);

    RETURN jsonb_build_object(
        'success', true,
        'points_awarded', v_points,
        'phone', p_phone
    );
END;
$$;

-- Grant execute to anon (for check-in flow) and authenticated
GRANT EXECUTE ON FUNCTION public.loyalty_check_in(UUID, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.loyalty_check_in(UUID, TEXT) TO authenticated;

-- RPC: submit feedback
CREATE OR REPLACE FUNCTION public.loyalty_submit_feedback(
    p_cafe_id UUID,
    p_phone TEXT,
    p_rating INTEGER,
    p_comment TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    p_phone := regexp_replace(trim(p_phone), '\s', '', 'g');
    IF p_rating < 1 OR p_rating > 5 THEN
        RAISE EXCEPTION 'Rating must be 1-5';
    END IF;

    INSERT INTO public.loyalty_feedback (cafe_id, phone, rating, comment)
    VALUES (p_cafe_id, p_phone, p_rating, NULLIF(trim(p_comment), ''));

    RETURN jsonb_build_object('success', true);
END;
$$;

GRANT EXECUTE ON FUNCTION public.loyalty_submit_feedback(UUID, TEXT, INTEGER, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.loyalty_submit_feedback(UUID, TEXT, INTEGER, TEXT) TO authenticated;
