-- =====================================================
-- LOYALTY FEEDBACK: Low-rating alerts, WhatsApp follow-up, public reviews
-- =====================================================

-- 1. Track which low ratings have been processed (cron runs as postgres, bypasses RLS)
ALTER TABLE public.loyalty_feedback ADD COLUMN IF NOT EXISTS low_rating_processed_at TIMESTAMPTZ;

-- 2. Process unprocessed low ratings: queue WhatsApp to staff + customer (runs via cron as postgres)
CREATE OR REPLACE FUNCTION public.process_low_rating_feedback()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r RECORD;
  v_cafe_whatsapp TEXT;
  v_cafe_name TEXT;
  v_phone_norm TEXT;
  v_count INTEGER := 0;
BEGIN
  FOR r IN (
    SELECT f.id, f.cafe_id, f.phone, f.rating, f.comment
    FROM public.loyalty_feedback f
    WHERE f.rating <= 2 AND f.low_rating_processed_at IS NULL
    ORDER BY f.created_at ASC
    LIMIT 50
  )
  LOOP
    v_phone_norm := regexp_replace(regexp_replace(trim(r.phone), '[^0-9]', '', 'g'), '^91', '', 'g');
    IF length(v_phone_norm) < 10 THEN
      UPDATE public.loyalty_feedback SET low_rating_processed_at = NOW() WHERE id = r.id;
      v_count := v_count + 1;
      CONTINUE;
    END IF;

    SELECT c.whatsapp_phone, c.name INTO v_cafe_whatsapp, v_cafe_name
    FROM public.cafes c WHERE c.id = r.cafe_id;

    -- Staff alert
    IF v_cafe_whatsapp IS NOT NULL AND trim(v_cafe_whatsapp) <> '' THEN
      INSERT INTO public.whatsapp_outbox (cafe_id, phone, event_type, message_body, payload_json)
      VALUES (
        r.cafe_id,
        v_cafe_whatsapp,
        'low_rating_alert',
        '⚠️ Low rating received: ' || r.rating || '/5 from Guest. ' ||
        COALESCE('Comment: ' || NULLIF(trim(r.comment), '') || '. ', '') ||
        'Phone: ' || substring(v_phone_norm from 1 for 4) || '****' || substring(v_phone_norm from 7 for 4),
        jsonb_build_object('feedback_id', r.id, 'rating', r.rating, 'comment', r.comment)
      );
    END IF;

    -- Customer follow-up
    INSERT INTO public.whatsapp_outbox (cafe_id, phone, event_type, message_body, payload_json)
    VALUES (
      r.cafe_id,
      v_phone_norm,
      'low_rating_followup',
      'We''re sorry to hear about your experience at ' || COALESCE(v_cafe_name, 'our cafe') || '. We''d love to make it right. Please visit us again or reply to this message.',
      jsonb_build_object('feedback_id', r.id, 'rating', r.rating)
    );

    UPDATE public.loyalty_feedback SET low_rating_processed_at = NOW() WHERE id = r.id;
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.process_low_rating_feedback() TO authenticated;

-- Optional: Run every 2 minutes via pg_cron (enable pg_cron in Supabase Dashboard first)
-- SELECT cron.schedule('process-low-rating-feedback', '*/2 * * * *', 'SELECT process_low_rating_feedback();');

-- 2. RPC: Get public reviews by cafe slug (for social proof page)
CREATE OR REPLACE FUNCTION public.get_public_reviews(p_slug TEXT)
RETURNS TABLE (
  id UUID,
  rating INTEGER,
  comment TEXT,
  created_at TIMESTAMPTZ,
  cafe_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT f.id, f.rating, f.comment, f.created_at, c.name
  FROM public.loyalty_feedback f
  JOIN public.cafes c ON c.id = f.cafe_id AND c.slug = p_slug
  ORDER BY f.created_at DESC
  LIMIT 100;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_public_reviews(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_public_reviews(TEXT) TO authenticated;
