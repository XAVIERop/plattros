-- Add delivery_address field to orders table for outside cafe delivery orders
-- This allows customers to provide their full delivery address or Google Maps link

-- Add the delivery_address column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'orders' 
        AND column_name = 'delivery_address'
    ) THEN
        ALTER TABLE public.orders 
        ADD COLUMN delivery_address TEXT;
        
        RAISE NOTICE 'Added delivery_address column to orders table';
    ELSE
        RAISE NOTICE 'delivery_address column already exists';
    END IF;
END $$;

-- Add comment for documentation
COMMENT ON COLUMN public.orders.delivery_address IS 'Full delivery address or Google Maps link for outside cafe delivery orders';

-- Verify the column was added
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'orders'
AND column_name = 'delivery_address';


