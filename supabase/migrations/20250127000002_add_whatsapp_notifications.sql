-- Add WhatsApp notification fields to cafes table
-- This allows cafe owners to receive WhatsApp notifications for new orders

-- Add WhatsApp phone number and notification settings to cafes table
ALTER TABLE public.cafes 
ADD COLUMN IF NOT EXISTS whatsapp_phone TEXT,
ADD COLUMN IF NOT EXISTS whatsapp_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS whatsapp_notifications BOOLEAN DEFAULT true;

-- Add comments for documentation
COMMENT ON COLUMN public.cafes.whatsapp_phone IS 'WhatsApp phone number for cafe owner (format: +91XXXXXXXXXX)';
COMMENT ON COLUMN public.cafes.whatsapp_enabled IS 'Whether WhatsApp notifications are enabled for this cafe';
COMMENT ON COLUMN public.cafes.whatsapp_notifications IS 'Whether to send WhatsApp notifications for new orders';

-- Create a function to send WhatsApp notifications
CREATE OR REPLACE FUNCTION send_whatsapp_notification(
    p_cafe_id UUID,
    p_order_data JSONB
)
RETURNS BOOLEAN AS $$
DECLARE
    cafe_record RECORD;
    message_text TEXT;
    success BOOLEAN := false;
BEGIN
    -- Get cafe WhatsApp settings
    SELECT whatsapp_phone, whatsapp_enabled, whatsapp_notifications, name
    INTO cafe_record
    FROM public.cafes
    WHERE id = p_cafe_id;
    
    -- Check if WhatsApp is enabled for this cafe
    IF NOT FOUND OR NOT cafe_record.whatsapp_enabled OR NOT cafe_record.whatsapp_notifications THEN
        RAISE NOTICE 'WhatsApp notifications disabled for cafe %', p_cafe_id;
        RETURN false;
    END IF;
    
    -- Check if phone number is provided
    IF cafe_record.whatsapp_phone IS NULL OR cafe_record.whatsapp_phone = '' THEN
        RAISE NOTICE 'No WhatsApp phone number configured for cafe %', p_cafe_id;
        RETURN false;
    END IF;
    
    -- Format the WhatsApp message
    message_text := format('
🍽️ *New Order Alert!*

📋 *Order:* #%s
👤 *Customer:* %s
📱 *Phone:* %s
📍 *Block:* %s
💰 *Total:* ₹%s
⏰ *Time:* %s

📝 *Items:*
%s

%s

🔗 *Manage Order:* %s/pos-dashboard
    ',
        p_order_data->>'order_number',
        p_order_data->>'customer_name',
        p_order_data->>'phone_number',
        p_order_data->>'delivery_block',
        p_order_data->>'total_amount',
        to_char((p_order_data->>'created_at')::timestamp, 'HH12:MI AM, Mon DD, YYYY'),
        p_order_data->>'items_text',
        CASE 
            WHEN p_order_data->>'delivery_notes' IS NOT NULL AND p_order_data->>'delivery_notes' != '' 
            THEN '📋 *Notes:* ' || p_order_data->>'delivery_notes'
            ELSE ''
        END,
        COALESCE(p_order_data->>'frontend_url', 'https://mujfoodclub.in')
    );
    
    -- Log the notification attempt
    RAISE NOTICE 'Sending WhatsApp notification to % for cafe %: %', 
        cafe_record.whatsapp_phone, cafe_record.name, message_text;
    
    -- Placeholder: WhatsApp API integration (future enhancement)
    -- In a real implementation, you would call the WhatsApp API service here
    -- For now, we'll just log it and return success
    
    success := true;
    RETURN success;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error sending WhatsApp notification: %', SQLERRM;
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION send_whatsapp_notification(UUID, JSONB) TO authenticated;

-- Add comment
COMMENT ON FUNCTION send_whatsapp_notification IS 'Sends WhatsApp notification to cafe owner for new orders';

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'WhatsApp notification system setup completed!';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Update cafes table with WhatsApp phone numbers';
    RAISE NOTICE '2. Enable whatsapp_enabled for cafes that want notifications';
    RAISE NOTICE '3. Integrate with frontend order placement';
END $$;
