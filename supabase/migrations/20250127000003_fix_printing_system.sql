-- Comprehensive Fix for Printing and KOT System
-- This migration addresses all identified issues with cafe-specific printing

-- 1. First, ensure all necessary tables and columns exist
DO $$ 
BEGIN
    -- Ensure cafe_printer_configs table exists with all required columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'cafe_printer_configs') THEN
        -- Create the table if it doesn't exist
        CREATE TABLE public.cafe_printer_configs (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
            printer_name TEXT NOT NULL DEFAULT 'Main Printer',
            printer_type TEXT NOT NULL DEFAULT 'browser_print',
            connection_type TEXT NOT NULL DEFAULT 'browser',
            printer_ip TEXT,
            printer_port INTEGER DEFAULT 8008,
            com_port TEXT,
            baud_rate INTEGER DEFAULT 9600,
            bluetooth_address TEXT,
            paper_width INTEGER DEFAULT 80,
            print_density INTEGER DEFAULT 8,
            auto_cut BOOLEAN DEFAULT true,
            is_active BOOLEAN DEFAULT true,
            is_default BOOLEAN DEFAULT true,
            printnode_printer_id INTEGER,
            created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
            updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
        );
    END IF;

    -- Add missing columns if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'cafe_printer_configs' AND column_name = 'printnode_printer_id') THEN
        ALTER TABLE public.cafe_printer_configs ADD COLUMN printnode_printer_id INTEGER;
    END IF;
END $$;

-- 2. Create proper printer configurations for each cafe
-- Clear existing configurations first
DELETE FROM public.cafe_printer_configs;

-- Insert proper configurations for each cafe
INSERT INTO public.cafe_printer_configs (
    cafe_id, 
    printer_name, 
    printer_type, 
    connection_type, 
    printnode_printer_id,
    is_active, 
    is_default
)
SELECT 
    c.id as cafe_id,
    CASE 
        WHEN LOWER(c.name) LIKE '%chatkara%' THEN 'Chatkara Thermal Printer'
        WHEN LOWER(c.name) LIKE '%food court%' THEN 'Food Court Epson Printer'
        WHEN LOWER(c.name) LIKE '%mini meals%' THEN 'Mini Meals Printer'
        ELSE 'Default Thermal Printer'
    END as printer_name,
    CASE 
        WHEN LOWER(c.name) LIKE '%chatkara%' THEN 'pixel_thermal'
        WHEN LOWER(c.name) LIKE '%food court%' THEN 'epson_tm_t82'
        WHEN LOWER(c.name) LIKE '%mini meals%' THEN 'browser_print'
        ELSE 'browser_print'
    END as printer_type,
    CASE 
        WHEN LOWER(c.name) LIKE '%chatkara%' THEN 'usb'
        WHEN LOWER(c.name) LIKE '%food court%' THEN 'network'
        WHEN LOWER(c.name) LIKE '%mini meals%' THEN 'browser'
        ELSE 'browser'
    END as connection_type,
    CASE 
        WHEN LOWER(c.name) LIKE '%chatkara%' THEN 12346  -- Chatkara's PrintNode printer ID
        WHEN LOWER(c.name) LIKE '%food court%' THEN 12345  -- Food Court's PrintNode printer ID
        ELSE NULL  -- No PrintNode for other cafes
    END as printnode_printer_id,
    true as is_active,
    true as is_default
FROM public.cafes c
WHERE c.is_active = true;

-- 3. Add network configuration for Food Court
UPDATE public.cafe_printer_configs 
SET 
    printer_ip = '192.168.1.100',
    printer_port = 8008,
    paper_width = 80,
    print_density = 8
WHERE cafe_id = (SELECT id FROM public.cafes WHERE LOWER(name) LIKE '%food court%' LIMIT 1)
  AND printer_type = 'epson_tm_t82';

-- 4. Add USB configuration for Chatkara
UPDATE public.cafe_printer_configs 
SET 
    com_port = 'COM3',
    baud_rate = 9600,
    paper_width = 80,
    print_density = 8
WHERE cafe_id = (SELECT id FROM public.cafes WHERE LOWER(name) LIKE '%chatkara%' LIMIT 1)
  AND printer_type = 'pixel_thermal';

-- 5. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_cafe_printer_configs_cafe_id ON public.cafe_printer_configs(cafe_id);
CREATE INDEX IF NOT EXISTS idx_cafe_printer_configs_active ON public.cafe_printer_configs(is_active);
CREATE INDEX IF NOT EXISTS idx_cafe_printer_configs_default ON public.cafe_printer_configs(is_default);
CREATE INDEX IF NOT EXISTS idx_cafe_printer_configs_printnode_id ON public.cafe_printer_configs(printnode_printer_id);

-- 6. Create function to get cafe printer configuration
CREATE OR REPLACE FUNCTION public.get_cafe_printer_config(cafe_uuid UUID)
RETURNS TABLE (
    id UUID,
    printer_name TEXT,
    printer_type TEXT,
    connection_type TEXT,
    printnode_printer_id INTEGER,
    printer_ip TEXT,
    printer_port INTEGER,
    com_port TEXT,
    baud_rate INTEGER,
    paper_width INTEGER,
    print_density INTEGER,
    auto_cut BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cpc.id,
        cpc.printer_name,
        cpc.printer_type,
        cpc.connection_type,
        cpc.printnode_printer_id,
        cpc.printer_ip,
        cpc.printer_port,
        cpc.com_port,
        cpc.baud_rate,
        cpc.paper_width,
        cpc.print_density,
        cpc.auto_cut
    FROM public.cafe_printer_configs cpc
    WHERE cpc.cafe_id = cafe_uuid
      AND cpc.is_active = true
      AND cpc.is_default = true
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Create function to get cafe name for formatting
CREATE OR REPLACE FUNCTION public.get_cafe_name_for_formatting(cafe_uuid UUID)
RETURNS TEXT AS $$
DECLARE
    cafe_name TEXT;
BEGIN
    SELECT c.name INTO cafe_name
    FROM public.cafes c
    WHERE c.id = cafe_uuid;
    
    RETURN COALESCE(cafe_name, 'Unknown Cafe');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Enable RLS with proper policies
ALTER TABLE public.cafe_printer_configs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Cafe owners can view their printer configs" ON public.cafe_printer_configs;
DROP POLICY IF EXISTS "Cafe owners can insert their printer configs" ON public.cafe_printer_configs;
DROP POLICY IF EXISTS "Cafe owners can update their printer configs" ON public.cafe_printer_configs;
DROP POLICY IF EXISTS "Cafe owners can delete their printer configs" ON public.cafe_printer_configs;

-- Create new, simplified policies
CREATE POLICY "Cafe owners can view their printer configs" ON public.cafe_printer_configs
    FOR SELECT USING (
        cafe_id IN (
            SELECT c.id FROM public.cafes c
            JOIN public.profiles p ON p.cafe_id = c.id
            WHERE p.id = auth.uid() AND p.user_type = 'cafe_owner'
        )
    );

CREATE POLICY "Cafe owners can manage their printer configs" ON public.cafe_printer_configs
    FOR ALL USING (
        cafe_id IN (
            SELECT c.id FROM public.cafes c
            JOIN public.profiles p ON p.cafe_id = c.id
            WHERE p.id = auth.uid() AND p.user_type = 'cafe_owner'
        )
    );

-- 9. Verify the setup
SELECT 'Printing System Fix Complete' as status;

-- Show current printer configurations
SELECT 
    c.name as cafe_name,
    cpc.printer_name,
    cpc.printer_type,
    cpc.connection_type,
    cpc.printnode_printer_id,
    cpc.printer_ip,
    cpc.is_active,
    cpc.is_default
FROM public.cafe_printer_configs cpc
JOIN public.cafes c ON cpc.cafe_id = c.id
ORDER BY c.name;



