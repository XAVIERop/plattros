-- Add latitude and longitude columns to orders table for precise location tracking
-- This allows cafes to get exact coordinates for delivery

-- Add latitude column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'orders' 
        AND column_name = 'delivery_latitude'
    ) THEN
        ALTER TABLE public.orders 
        ADD COLUMN delivery_latitude DECIMAL(10, 8);
        
        RAISE NOTICE 'Added delivery_latitude column to orders table';
    ELSE
        RAISE NOTICE 'delivery_latitude column already exists';
    END IF;
END $$;

-- Add longitude column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'orders' 
        AND column_name = 'delivery_longitude'
    ) THEN
        ALTER TABLE public.orders 
        ADD COLUMN delivery_longitude DECIMAL(11, 8);
        
        RAISE NOTICE 'Added delivery_longitude column to orders table';
    ELSE
        RAISE NOTICE 'delivery_longitude column already exists';
    END IF;
END $$;

-- Add comments for documentation
COMMENT ON COLUMN public.orders.delivery_latitude IS 'Latitude coordinate for delivery location (decimal degrees)';
COMMENT ON COLUMN public.orders.delivery_longitude IS 'Longitude coordinate for delivery location (decimal degrees)';

-- Verify the columns were added
SELECT 
    column_name,
    data_type,
    numeric_precision,
    numeric_scale,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'orders'
AND column_name IN ('delivery_latitude', 'delivery_longitude')
ORDER BY column_name;


