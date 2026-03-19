-- Add is_exclusive column to cafes table
-- This migration adds the is_exclusive column to the cafes table

-- Add is_exclusive column to cafes table
ALTER TABLE public.cafes 
ADD COLUMN IF NOT EXISTS is_exclusive BOOLEAN DEFAULT false;

-- Create index for is_exclusive column
CREATE INDEX IF NOT EXISTS idx_cafes_is_exclusive ON public.cafes(is_exclusive);

-- Set existing exclusive cafes (you can modify this based on your current exclusive cafes)
-- For now, let's assume Chatkara and Food Court are exclusive
UPDATE public.cafes 
SET is_exclusive = true 
WHERE name ILIKE '%chatkara%' OR name ILIKE '%food court%';

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'is_exclusive column added to cafes table successfully!';
    RAISE NOTICE 'Chatkara and Food Court set as exclusive by default';
END $$;
