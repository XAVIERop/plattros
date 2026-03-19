-- Add PrintNode printer ID support for shared account approach
-- This allows multiple cafes to use the same PrintNode account with different printer IDs

-- Add printnode_printer_id column to cafe_printer_configs
ALTER TABLE public.cafe_printer_configs 
ADD COLUMN printnode_printer_id INTEGER;

-- Add comment for the new column
COMMENT ON COLUMN public.cafe_printer_configs.printnode_printer_id IS 'PrintNode printer ID for shared account approach';

-- Create index for better performance
CREATE INDEX idx_cafe_printer_configs_printnode_id ON public.cafe_printer_configs(printnode_printer_id);

-- Update Food Court with placeholder printer ID (replace with actual ID from PrintNode)
UPDATE public.cafe_printer_configs 
SET printnode_printer_id = 12345  -- Replace with Food Court's actual PrintNode printer ID
WHERE cafe_id = (SELECT id FROM public.cafes WHERE name ILIKE '%food court%' LIMIT 1)
  AND printer_type = 'epson_tm_t82';

-- Update Chatkara with placeholder printer ID (replace with actual ID from PrintNode)
UPDATE public.cafe_printer_configs 
SET printnode_printer_id = 12346  -- Replace with Chatkara's actual PrintNode printer ID
WHERE cafe_id = (SELECT id FROM public.cafes WHERE name ILIKE '%chatkara%' LIMIT 1)
  AND printer_type = 'pixel_thermal';

-- Verify the setup
SELECT 'PrintNode Printer ID Support Added' as status;

-- Show current printer configurations with PrintNode IDs
SELECT 
  c.name as cafe_name,
  pc.printer_name,
  pc.printer_type,
  pc.connection_type,
  pc.printnode_printer_id,
  pc.is_active,
  pc.is_default
FROM public.cafe_printer_configs pc
JOIN public.cafes c ON pc.cafe_id = c.id
WHERE c.name ILIKE '%food court%' OR c.name ILIKE '%chatkara%'
ORDER BY c.name;
