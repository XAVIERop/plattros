-- Create support tickets table
CREATE TABLE IF NOT EXISTS support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  subject TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('order', 'payment', 'account', 'technical', 'general', 'refund')),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
  description TEXT NOT NULL,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  attachments JSONB DEFAULT '[]'::jsonb,
  admin_notes TEXT,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create support ticket responses table
CREATE TABLE IF NOT EXISTS support_ticket_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID REFERENCES support_tickets(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  is_admin BOOLEAN NOT NULL DEFAULT false,
  message TEXT NOT NULL,
  attachments JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_category ON support_tickets(category);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_at ON support_tickets(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_support_tickets_order_id ON support_tickets(order_id);
CREATE INDEX IF NOT EXISTS idx_support_ticket_responses_ticket_id ON support_ticket_responses(ticket_id);
CREATE INDEX IF NOT EXISTS idx_support_ticket_responses_created_at ON support_ticket_responses(created_at DESC);

-- Enable RLS
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_ticket_responses ENABLE ROW LEVEL SECURITY;

-- RLS Policies for support_tickets
-- Users can view their own tickets
CREATE POLICY "Users can view their own tickets"
  ON support_tickets
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can create their own tickets (or guests can create tickets with null user_id)
CREATE POLICY "Users can create their own tickets"
  ON support_tickets
  FOR INSERT
  WITH CHECK (
    (auth.uid() = user_id) OR 
    (user_id IS NULL AND auth.uid() IS NULL)
  );

-- Users can update their own open tickets
CREATE POLICY "Users can update their own open tickets"
  ON support_tickets
  FOR UPDATE
  USING (auth.uid() = user_id AND status = 'open');

-- Admins can view all tickets
CREATE POLICY "Admins can view all tickets"
  ON support_tickets
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'super_admin'
    )
  );

-- Admins can update all tickets
CREATE POLICY "Admins can update all tickets"
  ON support_tickets
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'super_admin'
    )
  );

-- RLS Policies for support_ticket_responses
-- Users can view responses to their tickets
CREATE POLICY "Users can view responses to their tickets"
  ON support_ticket_responses
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM support_tickets
      WHERE support_tickets.id = support_ticket_responses.ticket_id
      AND support_tickets.user_id = auth.uid()
    )
  );

-- Users can create responses to their own tickets
CREATE POLICY "Users can create responses to their tickets"
  ON support_ticket_responses
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM support_tickets
      WHERE support_tickets.id = support_ticket_responses.ticket_id
      AND support_tickets.user_id = auth.uid()
    )
    AND auth.uid() = user_id
  );

-- Admins can view all responses
CREATE POLICY "Admins can view all responses"
  ON support_ticket_responses
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'super_admin'
    )
  );

-- Admins can create responses to any ticket
CREATE POLICY "Admins can create responses to any ticket"
  ON support_ticket_responses
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.user_type = 'super_admin'
    )
    AND is_admin = true
  );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_support_ticket_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at
CREATE TRIGGER update_support_tickets_updated_at
  BEFORE UPDATE ON support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION update_support_ticket_updated_at();

-- Function to update ticket status when response is added
CREATE OR REPLACE FUNCTION update_ticket_status_on_response()
RETURNS TRIGGER AS $$
BEGIN
  -- If admin responds, set status to in_progress
  IF NEW.is_admin = true THEN
    UPDATE support_tickets
    SET status = 'in_progress'
    WHERE id = NEW.ticket_id AND status = 'open';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update ticket status
CREATE TRIGGER update_ticket_status_on_response
  AFTER INSERT ON support_ticket_responses
  FOR EACH ROW
  EXECUTE FUNCTION update_ticket_status_on_response();

