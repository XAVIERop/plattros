-- Create Events and Event Registrations System
-- For Lohri event and future events

-- Create events table
CREATE TABLE IF NOT EXISTS public.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  event_date DATE NOT NULL,
  event_time TIME,
  location TEXT,
  capacity INTEGER, -- NULL means unlimited
  registration_deadline TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_registration_open BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create event_registrations table
CREATE TABLE IF NOT EXISTS public.event_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- NULL for guest registrations
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  accommodation_type TEXT NOT NULL CHECK (accommodation_type IN ('hosteller', 'day_scholar')),
  registration_status TEXT NOT NULL DEFAULT 'registered' CHECK (registration_status IN ('registered', 'confirmed', 'cancelled', 'attended')),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- Ensure unique email per event (one person can't register twice for same event)
  CONSTRAINT unique_email_per_event UNIQUE (event_id, email)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_event_registrations_event_id ON public.event_registrations(event_id);
CREATE INDEX IF NOT EXISTS idx_event_registrations_user_id ON public.event_registrations(user_id);
CREATE INDEX IF NOT EXISTS idx_event_registrations_email ON public.event_registrations(email);
CREATE INDEX IF NOT EXISTS idx_events_is_active ON public.events(is_active);
CREATE INDEX IF NOT EXISTS idx_events_is_registration_open ON public.events(is_registration_open);

-- Enable RLS
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_registrations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for events
-- Anyone can read active events
CREATE POLICY "Anyone can view active events"
  ON public.events
  FOR SELECT
  USING (is_active = true);

-- Only admins can insert/update/delete events
CREATE POLICY "Admins can manage events"
  ON public.events
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type IN ('super_admin', 'admin')
    )
  );

-- RLS Policies for event_registrations
-- Anyone can insert their own registration (including anonymous users)
-- Explicitly allow both authenticated and anonymous users
CREATE POLICY "Anyone can register for events"
  ON public.event_registrations
  FOR INSERT
  TO authenticated, anon
  WITH CHECK (true);

-- Users can view their own registrations
CREATE POLICY "Users can view their own registrations"
  ON public.event_registrations
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type IN ('super_admin', 'admin')
    )
  );

-- Only admins can update/delete registrations
CREATE POLICY "Admins can manage registrations"
  ON public.event_registrations
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type IN ('super_admin', 'admin')
    )
  );

CREATE POLICY "Admins can delete registrations"
  ON public.event_registrations
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type IN ('super_admin', 'admin')
    )
  );

-- Insert Lohri event
INSERT INTO public.events (
  name,
  description,
  event_date,
  event_time,
  location,
  capacity,
  registration_deadline,
  is_active,
  is_registration_open
)
VALUES (
  'Lohri Celebration 2026',
  'Join us for a festive Lohri celebration with free registrations!',
  '2026-01-13',
  '18:00:00', -- 6 PM
  'Bannas Chowki',
  NULL, -- Unlimited capacity
  '2026-01-12 23:59:59', -- Registration deadline: Jan 12, 11:59 PM
  true,
  true
)
ON CONFLICT DO NOTHING;

-- Function to get active event
CREATE OR REPLACE FUNCTION get_active_event()
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  event_date DATE,
  event_time TIME,
  location TEXT,
  capacity INTEGER,
  registration_deadline TIMESTAMPTZ,
  is_active BOOLEAN,
  is_registration_open BOOLEAN,
  registration_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.name,
    e.description,
    e.event_date,
    e.event_time,
    e.location,
    e.capacity,
    e.registration_deadline,
    e.is_active,
    e.is_registration_open,
    COUNT(er.id) as registration_count
  FROM public.events e
  LEFT JOIN public.event_registrations er ON er.event_id = e.id AND er.registration_status = 'registered'
  WHERE e.is_active = true
    AND e.is_registration_open = true
    AND (e.registration_deadline IS NULL OR e.registration_deadline > NOW())
  GROUP BY e.id
  ORDER BY e.event_date ASC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_active_event() TO authenticated, anon;

-- Function to get registration count for an event
CREATE OR REPLACE FUNCTION get_event_registration_count(p_event_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM public.event_registrations
  WHERE event_id = p_event_id
    AND registration_status = 'registered';
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_event_registration_count(UUID) TO authenticated, anon;

-- Verify
SELECT 'Events system created successfully!' as status;
SELECT * FROM public.events WHERE is_active = true;

