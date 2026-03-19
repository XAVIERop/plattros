-- Add Dine In system with QR codes and table management

-- Step 1: Add 'DINE_IN' to the block_type enum
ALTER TYPE block_type ADD VALUE 'DINE_IN';

-- Step 2: Create cafe_tables table for QR code management
CREATE TABLE public.cafe_tables (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  table_number TEXT NOT NULL,
  qr_code TEXT UNIQUE NOT NULL DEFAULT 'QR_' || gen_random_uuid()::text,
  is_available BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Ensure unique table numbers per cafe
  UNIQUE(cafe_id, table_number)
);

-- Step 3: Add table_number to orders table for dine-in orders
ALTER TABLE public.orders ADD COLUMN table_number TEXT;

-- Step 4: Create indexes for performance
CREATE INDEX idx_cafe_tables_cafe_id ON public.cafe_tables(cafe_id);
CREATE INDEX idx_cafe_tables_qr_code ON public.cafe_tables(qr_code);
CREATE INDEX idx_orders_table_number ON public.orders(table_number);

-- Step 5: Enable RLS for cafe_tables
ALTER TABLE public.cafe_tables ENABLE ROW LEVEL SECURITY;

-- Step 6: Create RLS policies for cafe_tables
CREATE POLICY "Anyone can view cafe tables" ON public.cafe_tables
  FOR SELECT USING (true);

CREATE POLICY "Cafe owners can manage their tables" ON public.cafe_tables
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.cafe_id = cafe_tables.cafe_id
      AND profiles.user_type IN ('cafe_owner', 'cafe_staff')
    )
  );

-- Step 7: Create function to generate QR codes
CREATE OR REPLACE FUNCTION public.generate_table_qr_code()
RETURNS TRIGGER AS $$
BEGIN
  -- Generate QR code in format: cafe_id:table_id
  NEW.qr_code = 'QR_' || NEW.cafe_id::text || '_' || NEW.table_number;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 8: Create trigger to auto-generate QR codes
CREATE TRIGGER generate_qr_code_trigger
  BEFORE INSERT ON public.cafe_tables
  FOR EACH ROW
  EXECUTE FUNCTION public.generate_table_qr_code();

-- Step 9: Create function to update updated_at
CREATE OR REPLACE FUNCTION public.update_cafe_tables_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 10: Create trigger for updated_at
CREATE TRIGGER update_cafe_tables_updated_at_trigger
  BEFORE UPDATE ON public.cafe_tables
  FOR EACH ROW
  EXECUTE FUNCTION public.update_cafe_tables_updated_at();

-- Step 11: Insert sample tables for all cafes with specific counts
-- Cook House: 12 tables, Food Court: 8 tables, Others: 5 tables

-- Insert tables for Cook House (12 tables)
INSERT INTO public.cafe_tables (cafe_id, table_number) 
SELECT 
  c.id as cafe_id,
  generate_series(1, 12)::text as table_number
FROM public.cafes c
WHERE c.is_active = true AND LOWER(c.name) LIKE '%cook house%';

-- Insert tables for Food Court (8 tables)
INSERT INTO public.cafe_tables (cafe_id, table_number) 
SELECT 
  c.id as cafe_id,
  generate_series(1, 8)::text as table_number
FROM public.cafes c
WHERE c.is_active = true AND LOWER(c.name) LIKE '%food court%';

-- Insert tables for all other cafes (5 tables each)
INSERT INTO public.cafe_tables (cafe_id, table_number) 
SELECT 
  c.id as cafe_id,
  generate_series(1, 5)::text as table_number
FROM public.cafes c
WHERE c.is_active = true 
  AND LOWER(c.name) NOT LIKE '%cook house%' 
  AND LOWER(c.name) NOT LIKE '%food court%';

-- Step 12: Verify the setup
SELECT 
  'Dine In system setup complete' as status,
  COUNT(*) as total_tables_created
FROM public.cafe_tables;
