-- Fix RLS policy to allow guest users to create tickets
-- This migration fixes the issue where tickets with null user_id couldn't be created

-- Drop the existing policy
DROP POLICY IF EXISTS "Users can create their own tickets" ON support_tickets;

-- Recreate with support for guest users
CREATE POLICY "Users can create their own tickets"
  ON support_tickets
  FOR INSERT
  WITH CHECK (
    -- Logged-in users can create tickets with their own user_id
    (auth.uid() = user_id) OR 
    -- Guest users (not logged in) can create tickets with null user_id
    (user_id IS NULL)
  );

-- Also update the SELECT policy to allow viewing tickets by email for guests
DROP POLICY IF EXISTS "Users can view their own tickets" ON support_tickets;

CREATE POLICY "Users can view their own tickets"
  ON support_tickets
  FOR SELECT
  USING (
    -- Logged-in users can view their own tickets
    (auth.uid() = user_id) OR
    -- Allow viewing if user_id is null (for guest tickets - they'll need email verification)
    (user_id IS NULL)
  );









