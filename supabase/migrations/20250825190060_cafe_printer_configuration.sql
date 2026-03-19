-- Cafe Printer Configuration System
-- This migration adds printer configuration support for each cafe

-- Create printer types enum
CREATE TYPE printer_type AS ENUM (
  'epson_tm_t82',      -- Epson TM-T82 (Network)
  'pixel_thermal',     -- Pixel Thermal Printer (USB)
  'star_tsp143',       -- Star TSP143 (USB/Network)
  'citizen_cts310',    -- Citizen CTS310 (USB)
  'browser_print',     -- Browser printing (fallback)
  'custom'             -- Custom printer configuration
);

-- Create connection types enum
CREATE TYPE connection_type AS ENUM (
  'usb',               -- USB/Serial connection
  'network',           -- Network/IP connection
  'bluetooth',         -- Bluetooth connection
  'browser'            -- Browser printing
);

-- Create cafe_printer_configs table
CREATE TABLE public.cafe_printer_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  printer_name TEXT NOT NULL DEFAULT 'Main Printer',
  printer_type printer_type NOT NULL DEFAULT 'browser_print',
  connection_type connection_type NOT NULL DEFAULT 'browser',
  
  -- Network configuration (for network printers)
  printer_ip TEXT,
  printer_port INTEGER DEFAULT 8008,
  
  -- USB configuration (for USB printers)
  com_port TEXT,
  baud_rate INTEGER DEFAULT 9600,
  
  -- Bluetooth configuration (for Bluetooth printers)
  bluetooth_address TEXT,
  
  -- Printer settings
  paper_width INTEGER DEFAULT 80, -- in mm
  print_density INTEGER DEFAULT 8, -- 1-15
  auto_cut BOOLEAN DEFAULT true,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  is_default BOOLEAN DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Constraints
  CONSTRAINT unique_default_per_cafe UNIQUE (cafe_id, is_default) DEFERRABLE INITIALLY DEFERRED,
  CONSTRAINT valid_network_config CHECK (
    (connection_type = 'network' AND printer_ip IS NOT NULL) OR
    (connection_type != 'network')
  ),
  CONSTRAINT valid_usb_config CHECK (
    (connection_type = 'usb' AND com_port IS NOT NULL) OR
    (connection_type != 'usb')
  )
);

-- Create indexes for better performance
CREATE INDEX idx_cafe_printer_configs_cafe_id ON public.cafe_printer_configs(cafe_id);
CREATE INDEX idx_cafe_printer_configs_active ON public.cafe_printer_configs(is_active);
CREATE INDEX idx_cafe_printer_configs_default ON public.cafe_printer_configs(is_default);

-- Add comments
COMMENT ON TABLE public.cafe_printer_configs IS 'Printer configuration for each cafe';
COMMENT ON COLUMN public.cafe_printer_configs.printer_type IS 'Type of thermal printer';
COMMENT ON COLUMN public.cafe_printer_configs.connection_type IS 'How the printer is connected';
COMMENT ON COLUMN public.cafe_printer_configs.paper_width IS 'Paper width in millimeters';
COMMENT ON COLUMN public.cafe_printer_configs.print_density IS 'Print density (1-15)';

-- Create function to set default printer
CREATE OR REPLACE FUNCTION set_default_printer_config()
RETURNS TRIGGER AS $$
BEGIN
  -- If this is being set as default, unset all other defaults for this cafe
  IF NEW.is_default = true THEN
    UPDATE public.cafe_printer_configs 
    SET is_default = false 
    WHERE cafe_id = NEW.cafe_id AND id != NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for default printer
CREATE TRIGGER trigger_set_default_printer_config
  BEFORE INSERT OR UPDATE ON public.cafe_printer_configs
  FOR EACH ROW
  EXECUTE FUNCTION set_default_printer_config();

-- Insert default printer configurations for existing cafes
INSERT INTO public.cafe_printer_configs (cafe_id, printer_name, printer_type, connection_type, is_default)
SELECT 
  c.id as cafe_id,
  CASE 
    WHEN c.name ILIKE '%food court%' THEN 'EPSON TM-T82 Receipt'
    WHEN c.name ILIKE '%chatkara%' THEN 'Pixel Thermal Printer'
    ELSE 'Default Thermal Printer'
  END as printer_name,
  CASE 
    WHEN c.name ILIKE '%food court%' THEN 'epson_tm_t82'::printer_type
    WHEN c.name ILIKE '%chatkara%' THEN 'pixel_thermal'::printer_type
    ELSE 'browser_print'::printer_type
  END as printer_type,
  CASE 
    WHEN c.name ILIKE '%food court%' THEN 'network'::connection_type
    WHEN c.name ILIKE '%chatkara%' THEN 'usb'::connection_type
    ELSE 'browser'::connection_type
  END as connection_type,
  true as is_default
FROM public.cafes c
WHERE c.is_active = true;

-- Update Food Court printer with network configuration
UPDATE public.cafe_printer_configs 
SET 
  printer_ip = '192.168.1.100',
  printer_port = 8008,
  paper_width = 80,
  print_density = 8
WHERE cafe_id = (SELECT id FROM public.cafes WHERE name ILIKE '%food court%' LIMIT 1)
  AND printer_type = 'epson_tm_t82';

-- Update Chatkara printer with USB configuration
UPDATE public.cafe_printer_configs 
SET 
  com_port = 'COM3',
  baud_rate = 9600,
  paper_width = 80,
  print_density = 8
WHERE cafe_id = (SELECT id FROM public.cafes WHERE name ILIKE '%chatkara%' LIMIT 1)
  AND printer_type = 'pixel_thermal';

-- Create RLS policies
ALTER TABLE public.cafe_printer_configs ENABLE ROW LEVEL SECURITY;

-- Cafe owners can view and edit their own printer configs
CREATE POLICY "Cafe owners can view their printer configs" ON public.cafe_printer_configs
  FOR SELECT USING (
    cafe_id IN (
      SELECT c.id FROM public.cafes c
      JOIN public.profiles p ON p.cafe_id = c.id
      WHERE p.id = auth.uid() AND p.user_type = 'cafe_owner'
    )
  );

CREATE POLICY "Cafe owners can insert their printer configs" ON public.cafe_printer_configs
  FOR INSERT WITH CHECK (
    cafe_id IN (
      SELECT c.id FROM public.cafes c
      JOIN public.profiles p ON p.cafe_id = c.id
      WHERE p.id = auth.uid() AND p.user_type = 'cafe_owner'
    )
  );

CREATE POLICY "Cafe owners can update their printer configs" ON public.cafe_printer_configs
  FOR UPDATE USING (
    cafe_id IN (
      SELECT c.id FROM public.cafes c
      JOIN public.profiles p ON p.cafe_id = c.id
      WHERE p.id = auth.uid() AND p.user_type = 'cafe_owner'
    )
  );

CREATE POLICY "Cafe owners can delete their printer configs" ON public.cafe_printer_configs
  FOR DELETE USING (
    cafe_id IN (
      SELECT c.id FROM public.cafes c
      JOIN public.profiles p ON p.cafe_id = c.id
      WHERE p.id = auth.uid() AND p.user_type = 'cafe_owner'
    )
  );

-- Verify the setup
SELECT 'Cafe Printer Configuration Setup Complete' as status;

-- Show current printer configurations
SELECT 
  c.name as cafe_name,
  pc.printer_name,
  pc.printer_type,
  pc.connection_type,
  pc.printer_ip,
  pc.printer_port,
  pc.com_port,
  pc.baud_rate,
  pc.paper_width,
  pc.is_active,
  pc.is_default
FROM public.cafe_printer_configs pc
JOIN public.cafes c ON pc.cafe_id = c.id
ORDER BY c.name, pc.is_default DESC;
