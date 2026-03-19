-- Customer notes per cafe+phone (for CRM)
CREATE TABLE IF NOT EXISTS public.customer_notes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  phone TEXT NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(cafe_id, phone)
);

CREATE INDEX IF NOT EXISTS idx_customer_notes_cafe_phone ON public.customer_notes(cafe_id, phone);

ALTER TABLE public.customer_notes ENABLE ROW LEVEL SECURITY;

-- Cafe staff can manage notes for their cafe
CREATE POLICY "cafe_staff_manage_customer_notes" ON public.customer_notes
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.cafe_staff
      WHERE cafe_staff.cafe_id = customer_notes.cafe_id
        AND cafe_staff.user_id = auth.uid()
        AND cafe_staff.is_active = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.cafe_staff
      WHERE cafe_staff.cafe_id = customer_notes.cafe_id
        AND cafe_staff.user_id = auth.uid()
        AND cafe_staff.is_active = true
    )
  );

-- Cafe owners can manage notes for their cafe
CREATE POLICY "cafe_owners_manage_customer_notes" ON public.customer_notes
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.user_type = 'cafe_owner'
        AND profiles.cafe_id = customer_notes.cafe_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
        AND profiles.user_type = 'cafe_owner'
        AND profiles.cafe_id = customer_notes.cafe_id
    )
  );

COMMENT ON TABLE public.customer_notes IS 'Per-customer notes for CRM (cafe_id + phone)';
