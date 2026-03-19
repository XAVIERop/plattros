-- Add Ezeep columns to cafe_printer_configs table
-- This migration adds Ezeep-specific columns for cloud printing

-- 1. Add Ezeep columns if they don't exist
DO $$
BEGIN
    -- Add ezeep_api_key column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'cafe_printer_configs' AND column_name = 'ezeep_api_key') THEN
        ALTER TABLE public.cafe_printer_configs ADD COLUMN ezeep_api_key TEXT;
    END IF;
    
    -- Add ezeep_printer_id column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'cafe_printer_configs' AND column_name = 'ezeep_printer_id') THEN
        ALTER TABLE public.cafe_printer_configs ADD COLUMN ezeep_printer_id TEXT;
    END IF;
    
    RAISE NOTICE 'Ezeep columns added successfully!';
END $$;

-- 2. Add comments for the new columns
COMMENT ON COLUMN public.cafe_printer_configs.ezeep_api_key IS 'Ezeep API key for cloud printing';
COMMENT ON COLUMN public.cafe_printer_configs.ezeep_printer_id IS 'Ezeep printer ID for cloud printing';

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_cafe_printer_configs_ezeep_api_key ON public.cafe_printer_configs(ezeep_api_key);
CREATE INDEX IF NOT EXISTS idx_cafe_printer_configs_ezeep_printer_id ON public.cafe_printer_configs(ezeep_printer_id);

-- 4. Verify the table structure
SELECT 'Updated cafe_printer_configs table structure:' as status;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'cafe_printer_configs' 
ORDER BY ordinal_position;

-- 5. Success message
DO $$
BEGIN
    RAISE NOTICE 'Ezeep columns added to cafe_printer_configs table!';
    RAISE NOTICE 'New columns:';
    RAISE NOTICE '  - ezeep_api_key: TEXT (nullable)';
    RAISE NOTICE '  - ezeep_printer_id: TEXT (nullable)';
    RAISE NOTICE 'Ready to configure Ezeep for Cook House!';
END $$;

















