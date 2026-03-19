-- Add 'STARDOM Café & Lounge' restaurant with comprehensive café menu
-- Insert the cafe
INSERT INTO public.cafes (
    id,
    name,
    type,
    description,
    location,
    phone,
    hours,
    accepting_orders,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    'STARDOM Café & Lounge',
    'Café & Lounge',
    'A premium café and lounge experience offering specialty coffee, gourmet sandwiches, international cuisine, and refreshing beverages. From artisanal coffee to delicious comfort food, we bring you the perfect blend of taste and ambiance!',
    'G2 Ground Floor',
    '+91-9928884373',
    '11:00 AM - 2:00 AM',
    true,
    NOW(),
    NOW()
);

-- Get the cafe ID for menu items
DO $$
DECLARE
    cafe_id UUID;
BEGIN
    -- Get the cafe ID
    SELECT id INTO cafe_id FROM public.cafes WHERE name = 'STARDOM Café & Lounge';
    
    -- ========================================
    -- COFFEE SHOTS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Espresso', 'Single shot espresso', 30, 'Coffee Shots', true),
    (cafe_id, 'Double Shots Espresso', 'Double shot espresso', 45, 'Coffee Shots', true),
    (cafe_id, 'Café Macchiato', 'Espresso with a dash of milk', 50, 'Coffee Shots', true);

    -- ========================================
    -- HOT COFFEE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Café Americana', 'Classic American coffee', 50, 'Hot Coffee', true),
    (cafe_id, 'Cappuccino', 'Espresso with steamed milk and foam', 70, 'Hot Coffee', true),
    (cafe_id, 'Café Latte', 'Espresso with steamed milk', 80, 'Hot Coffee', true),
    (cafe_id, 'Café Mocha', 'Espresso with chocolate and steamed milk', 90, 'Hot Coffee', true),
    (cafe_id, 'Hazelnut Latte', 'Espresso with hazelnut syrup and steamed milk', 100, 'Hot Coffee', true),
    (cafe_id, 'Caramel Latte', 'Espresso with caramel syrup and steamed milk', 100, 'Hot Coffee', true),
    (cafe_id, 'Irish Latte', 'Espresso with Irish cream and steamed milk', 100, 'Hot Coffee', true);

    -- ========================================
    -- TEA
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Tea', 'Classic black tea', 30, 'Tea', true),
    (cafe_id, 'Regular Tea', 'Regular Indian tea', 30, 'Tea', true),
    (cafe_id, 'Ginger Tea', 'Spiced ginger tea', 30, 'Tea', true);

    -- ========================================
    -- COLD COFFEE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Milk Cold Coffee (Small)', 'Cold coffee with milk - small size', 50, 'Cold Coffee', true),
    (cafe_id, 'Milk Cold Coffee (Medium)', 'Cold coffee with milk - medium size', 60, 'Cold Coffee', true),
    (cafe_id, 'Milk Cold Coffee (Large)', 'Cold coffee with milk - large size', 80, 'Cold Coffee', true),
    (cafe_id, 'Caramel Cold Coffee (Small)', 'Caramel flavored cold coffee - small size', 70, 'Cold Coffee', true),
    (cafe_id, 'Caramel Cold Coffee (Medium)', 'Caramel flavored cold coffee - medium size', 90, 'Cold Coffee', true),
    (cafe_id, 'Caramel Cold Coffee (Large)', 'Caramel flavored cold coffee - large size', 110, 'Cold Coffee', true),
    (cafe_id, 'Café Frappe (Small)', 'Blended coffee frappe - small size', 90, 'Cold Coffee', true),
    (cafe_id, 'Café Frappe (Large)', 'Blended coffee frappe - large size', 110, 'Cold Coffee', true),
    (cafe_id, 'Crunchy Oreo Cold Coffee (Small)', 'Oreo cold coffee - small size', 100, 'Cold Coffee', true),
    (cafe_id, 'Crunchy Oreo Cold Coffee (Large)', 'Oreo cold coffee - large size', 120, 'Cold Coffee', true),
    (cafe_id, 'Brownie Cold Coffee (Small)', 'Brownie cold coffee - small size', 110, 'Cold Coffee', true),
    (cafe_id, 'Brownie Cold Coffee (Large)', 'Brownie cold coffee - large size', 130, 'Cold Coffee', true),
    (cafe_id, 'Caramel Frappe (Small)', 'Caramel frappe - small size', 110, 'Cold Coffee', true),
    (cafe_id, 'Caramel Frappe (Large)', 'Caramel frappe - large size', 130, 'Cold Coffee', true),
    (cafe_id, 'Hazelnut Frappe (Small)', 'Hazelnut frappe - small size', 110, 'Cold Coffee', true),
    (cafe_id, 'Hazelnut Frappe (Large)', 'Hazelnut frappe - large size', 130, 'Cold Coffee', true),
    (cafe_id, 'Irish Frappe (Small)', 'Irish cream frappe - small size', 110, 'Cold Coffee', true),
    (cafe_id, 'Irish Frappe (Large)', 'Irish cream frappe - large size', 130, 'Cold Coffee', true);

    -- ========================================
    -- ICED TEA
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Lemon Ice Tea (Small)', 'Lemon iced tea - small size', 50, 'Iced Tea', true),
    (cafe_id, 'Lemon Ice Tea (Large)', 'Lemon iced tea - large size', 80, 'Iced Tea', true),
    (cafe_id, 'Strawberry Ice Tea (Small)', 'Strawberry iced tea - small size', 60, 'Iced Tea', true),
    (cafe_id, 'Strawberry Ice Tea (Large)', 'Strawberry iced tea - large size', 90, 'Iced Tea', true),
    (cafe_id, 'Peach Ice Tea (Small)', 'Peach iced tea - small size', 60, 'Iced Tea', true),
    (cafe_id, 'Peach Ice Tea (Large)', 'Peach iced tea - large size', 90, 'Iced Tea', true),
    (cafe_id, 'Green Apple Ice Tea (Small)', 'Green apple iced tea - small size', 70, 'Iced Tea', true),
    (cafe_id, 'Green Apple Ice Tea (Large)', 'Green apple iced tea - large size', 100, 'Iced Tea', true),
    (cafe_id, 'Watermelon Ice Tea (Small)', 'Watermelon iced tea - small size', 70, 'Iced Tea', true),
    (cafe_id, 'Watermelon Ice Tea (Large)', 'Watermelon iced tea - large size', 100, 'Iced Tea', true),
    (cafe_id, 'Orange Ice Tea (Small)', 'Orange iced tea - small size', 70, 'Iced Tea', true),
    (cafe_id, 'Orange Ice Tea (Large)', 'Orange iced tea - large size', 100, 'Iced Tea', true);

    -- ========================================
    -- SODA
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Fresh Lime Soda', 'Fresh lime soda', 50, 'Soda', true),
    (cafe_id, 'Mint Mojito', 'Refreshing mint mojito', 70, 'Soda', true),
    (cafe_id, 'Blue Lagoon Mojito', 'Blue lagoon mojito', 70, 'Soda', true),
    (cafe_id, 'Peach Soda', 'Peach flavored soda', 70, 'Soda', true),
    (cafe_id, 'Strawberry Soda', 'Strawberry flavored soda', 70, 'Soda', true),
    (cafe_id, 'Green Apple Soda', 'Green apple flavored soda', 90, 'Soda', true),
    (cafe_id, 'Orange Soda', 'Orange flavored soda', 80, 'Soda', true);

    -- ========================================
    -- QUESADILLA
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veggie Quesadilla', 'Vegetable quesadilla', 150, 'Quesadilla', true),
    (cafe_id, 'Paneer Quesadilla', 'Paneer quesadilla', 160, 'Quesadilla', true),
    (cafe_id, 'Loaded Cheese Quesadilla', 'Extra cheese quesadilla', 170, 'Quesadilla', true);

    -- ========================================
    -- SHAKES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Banana Shake (Small)', 'Banana milkshake - small size', 60, 'Shakes', true),
    (cafe_id, 'Banana Shake (Medium)', 'Banana milkshake - medium size', 80, 'Shakes', true),
    (cafe_id, 'Banana Shake (Large)', 'Banana milkshake - large size', 100, 'Shakes', true),
    (cafe_id, 'Mango Shake (Small)', 'Mango milkshake - small size', 60, 'Shakes', true),
    (cafe_id, 'Mango Shake (Medium)', 'Mango milkshake - medium size', 80, 'Shakes', true),
    (cafe_id, 'Mango Shake (Large)', 'Mango milkshake - large size', 100, 'Shakes', true),
    (cafe_id, 'Caramel Shake (Small)', 'Caramel milkshake - small size', 70, 'Shakes', true),
    (cafe_id, 'Caramel Shake (Medium)', 'Caramel milkshake - medium size', 90, 'Shakes', true),
    (cafe_id, 'Caramel Shake (Large)', 'Caramel milkshake - large size', 120, 'Shakes', true),
    (cafe_id, 'Chocolate Shake (Small)', 'Chocolate milkshake - small size', 70, 'Shakes', true),
    (cafe_id, 'Chocolate Shake (Medium)', 'Chocolate milkshake - medium size', 100, 'Shakes', true),
    (cafe_id, 'Chocolate Shake (Large)', 'Chocolate milkshake - large size', 120, 'Shakes', true),
    (cafe_id, 'Oreo Shake (Small)', 'Oreo milkshake - small size', 70, 'Shakes', true),
    (cafe_id, 'Oreo Shake (Medium)', 'Oreo milkshake - medium size', 100, 'Shakes', true),
    (cafe_id, 'Oreo Shake (Large)', 'Oreo milkshake - large size', 120, 'Shakes', true),
    (cafe_id, 'Butterscotch Shake (Small)', 'Butterscotch milkshake - small size', 70, 'Shakes', true),
    (cafe_id, 'Butterscotch Shake (Medium)', 'Butterscotch milkshake - medium size', 100, 'Shakes', true),
    (cafe_id, 'Butterscotch Shake (Large)', 'Butterscotch milkshake - large size', 120, 'Shakes', true),
    (cafe_id, 'Strawberry Shake (Small)', 'Strawberry milkshake - small size', 70, 'Shakes', true),
    (cafe_id, 'Strawberry Shake (Medium)', 'Strawberry milkshake - medium size', 100, 'Shakes', true),
    (cafe_id, 'Strawberry Shake (Large)', 'Strawberry milkshake - large size', 120, 'Shakes', true),
    (cafe_id, 'Black Current Shake (Small)', 'Black currant milkshake - small size', 70, 'Shakes', true),
    (cafe_id, 'Black Current Shake (Medium)', 'Black currant milkshake - medium size', 100, 'Shakes', true),
    (cafe_id, 'Black Current Shake (Large)', 'Black currant milkshake - large size', 120, 'Shakes', true),
    (cafe_id, 'Blue Berry Shake (Small)', 'Blueberry milkshake - small size', 70, 'Shakes', true),
    (cafe_id, 'Blue Berry Shake (Medium)', 'Blueberry milkshake - medium size', 100, 'Shakes', true),
    (cafe_id, 'Blue Berry Shake (Large)', 'Blueberry milkshake - large size', 120, 'Shakes', true),
    (cafe_id, 'Badam Thandai (Small)', 'Almond thandai - small size', 70, 'Shakes', true),
    (cafe_id, 'Badam Thandai (Medium)', 'Almond thandai - medium size', 100, 'Shakes', true),
    (cafe_id, 'Badam Thandai (Large)', 'Almond thandai - large size', 120, 'Shakes', true),
    (cafe_id, 'Cold Chocolate (Small)', 'Cold chocolate - small size', 70, 'Shakes', true),
    (cafe_id, 'Cold Chocolate (Medium)', 'Cold chocolate - medium size', 100, 'Shakes', true),
    (cafe_id, 'Cold Chocolate (Large)', 'Cold chocolate - large size', 120, 'Shakes', true),
    (cafe_id, 'Brownie Shake (Small)', 'Brownie milkshake - small size', 90, 'Shakes', true),
    (cafe_id, 'Brownie Shake (Medium)', 'Brownie milkshake - medium size', 110, 'Shakes', true),
    (cafe_id, 'Brownie Shake (Large)', 'Brownie milkshake - large size', 130, 'Shakes', true),
    (cafe_id, 'Kit Kat Shake (Small)', 'Kit Kat milkshake - small size', 80, 'Shakes', true),
    (cafe_id, 'Kit Kat Shake (Medium)', 'Kit Kat milkshake - medium size', 110, 'Shakes', true),
    (cafe_id, 'Kit Kat Shake (Large)', 'Kit Kat milkshake - large size', 130, 'Shakes', true),
    (cafe_id, 'Oreo Kit Kat Shake (Small)', 'Oreo Kit Kat milkshake - small size', 90, 'Shakes', true),
    (cafe_id, 'Oreo Kit Kat Shake (Medium)', 'Oreo Kit Kat milkshake - medium size', 120, 'Shakes', true),
    (cafe_id, 'Oreo Kit Kat Shake (Large)', 'Oreo Kit Kat milkshake - large size', 140, 'Shakes', true),
    (cafe_id, 'Oreo Brownie Shake (Small)', 'Oreo brownie milkshake - small size', 90, 'Shakes', true),
    (cafe_id, 'Oreo Brownie Shake (Medium)', 'Oreo brownie milkshake - medium size', 120, 'Shakes', true),
    (cafe_id, 'Oreo Brownie Shake (Large)', 'Oreo brownie milkshake - large size', 140, 'Shakes', true),
    (cafe_id, 'Hazelnut Shake (Small)', 'Hazelnut milkshake - small size', 90, 'Shakes', true),
    (cafe_id, 'Hazelnut Shake (Medium)', 'Hazelnut milkshake - medium size', 120, 'Shakes', true),
    (cafe_id, 'Hazelnut Shake (Large)', 'Hazelnut milkshake - large size', 140, 'Shakes', true),
    (cafe_id, 'Nutella Shake (Small)', 'Nutella milkshake - small size', 90, 'Shakes', true),
    (cafe_id, 'Nutella Shake (Medium)', 'Nutella milkshake - medium size', 120, 'Shakes', true),
    (cafe_id, 'Nutella Shake (Large)', 'Nutella milkshake - large size', 140, 'Shakes', true);

    -- ========================================
    -- CHEESE SHAKES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Oreo Cheese Shake (Small)', 'Oreo cheese milkshake - small size', 90, 'Cheese Shakes', true),
    (cafe_id, 'Oreo Cheese Shake (Medium)', 'Oreo cheese milkshake - medium size', 120, 'Cheese Shakes', true),
    (cafe_id, 'Oreo Cheese Shake (Large)', 'Oreo cheese milkshake - large size', 140, 'Cheese Shakes', true),
    (cafe_id, 'Blue Berry Cheese Shake (Small)', 'Blueberry cheese milkshake - small size', 90, 'Cheese Shakes', true),
    (cafe_id, 'Blue Berry Cheese Shake (Medium)', 'Blueberry cheese milkshake - medium size', 120, 'Cheese Shakes', true),
    (cafe_id, 'Blue Berry Cheese Shake (Large)', 'Blueberry cheese milkshake - large size', 140, 'Cheese Shakes', true),
    (cafe_id, 'Nutella Cheese Shake (Small)', 'Nutella cheese milkshake - small size', 100, 'Cheese Shakes', true),
    (cafe_id, 'Nutella Cheese Shake (Medium)', 'Nutella cheese milkshake - medium size', 130, 'Cheese Shakes', true),
    (cafe_id, 'Nutella Cheese Shake (Large)', 'Nutella cheese milkshake - large size', 150, 'Cheese Shakes', true),
    (cafe_id, 'Biscoff Cheese Shake (Small)', 'Biscoff cheese milkshake - small size', 100, 'Cheese Shakes', true),
    (cafe_id, 'Biscoff Cheese Shake (Medium)', 'Biscoff cheese milkshake - medium size', 130, 'Cheese Shakes', true),
    (cafe_id, 'Biscoff Cheese Shake (Large)', 'Biscoff cheese milkshake - large size', 150, 'Cheese Shakes', true),
    (cafe_id, 'Hazelnut Chocolate Cheese Shake (Small)', 'Hazelnut chocolate cheese milkshake - small size', 100, 'Cheese Shakes', true),
    (cafe_id, 'Hazelnut Chocolate Cheese Shake (Medium)', 'Hazelnut chocolate cheese milkshake - medium size', 120, 'Cheese Shakes', true),
    (cafe_id, 'Hazelnut Chocolate Cheese Shake (Large)', 'Hazelnut chocolate cheese milkshake - large size', 140, 'Cheese Shakes', true);

    -- ========================================
    -- SLUSH
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Blue Slush', 'Blue flavored slush', 70, 'Slush', true),
    (cafe_id, 'Green Apple Slush', 'Green apple flavored slush', 80, 'Slush', true),
    (cafe_id, 'Strawberry Slush', 'Strawberry flavored slush', 80, 'Slush', true),
    (cafe_id, 'Orange Slush', 'Orange flavored slush', 80, 'Slush', true);

    -- ========================================
    -- CRISPY FRY SNACKS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'French Fry', 'Classic french fries', 85, 'Crispy Fry Snacks', true),
    (cafe_id, 'Peri Peri French Fry', 'Spicy peri peri french fries', 95, 'Crispy Fry Snacks', true),
    (cafe_id, 'Cheese Nachos', 'Cheese topped nachos', 115, 'Crispy Fry Snacks', true),
    (cafe_id, 'Onion Rings', 'Crispy onion rings', 115, 'Crispy Fry Snacks', true),
    (cafe_id, 'Paneer Popcorn', 'Crispy paneer popcorn', 115, 'Crispy Fry Snacks', true),
    (cafe_id, 'Hara Bhara Kabab', 'Green herb kebabs', 120, 'Crispy Fry Snacks', true),
    (cafe_id, 'Cheese Corn Nuggets', 'Cheese corn nuggets', 125, 'Crispy Fry Snacks', true),
    (cafe_id, 'Cheese French Fry', 'Cheese topped french fries', 135, 'Crispy Fry Snacks', true);

    -- ========================================
    -- SUNDAE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Walnut Brownie With Ice Cream', 'Walnut brownie served with ice cream', 100, 'Sundae', true),
    (cafe_id, 'Chocolate Passion Sundae', 'Chocolate passion sundae', 120, 'Sundae', true),
    (cafe_id, 'Brownie Fudge Sundae', 'Brownie fudge sundae', 130, 'Sundae', true);

    -- ========================================
    -- SANDWICH
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Sandwich', 'Vegetable sandwich', 60, 'Sandwich', true),
    (cafe_id, 'Aloo Sandwich', 'Potato sandwich', 60, 'Sandwich', true),
    (cafe_id, 'Club Sandwich', 'Classic club sandwich', 80, 'Sandwich', true),
    (cafe_id, 'Club Cheese Sandwich', 'Club sandwich with extra cheese', 100, 'Sandwich', true),
    (cafe_id, 'Hung Curd Sandwich', 'Hung curd sandwich', 80, 'Sandwich', true),
    (cafe_id, 'Tandoori Paneer Sandwich', 'Tandoori paneer sandwich', 90, 'Sandwich', true),
    (cafe_id, 'Paneer Tikka Sandwich', 'Paneer tikka sandwich', 100, 'Sandwich', true),
    (cafe_id, 'Peri Peri Paneer Sandwich', 'Spicy peri peri paneer sandwich', 105, 'Sandwich', true),
    (cafe_id, 'Paneer Pie Sandwich', 'Paneer pie sandwich', 100, 'Sandwich', true),
    (cafe_id, 'Cheese Chilli Corn Sandwich', 'Cheese chili corn sandwich', 100, 'Sandwich', true),
    (cafe_id, 'Cheese Blast Sandwich', 'Cheese blast sandwich', 100, 'Sandwich', true),
    (cafe_id, 'Triple Layer Cheese Sandwich', 'Triple layer cheese sandwich', 120, 'Sandwich', true),
    (cafe_id, 'Focaccia Cottage Cheese Sandwich', 'Focaccia with cottage cheese', 130, 'Sandwich', true),
    (cafe_id, 'Rim - Zim Sandwich', 'Special rim-zim sandwich', 140, 'Sandwich', true),
    (cafe_id, 'Garlic Cheese Sandwich', 'Garlic cheese sandwich', 100, 'Sandwich', true),
    (cafe_id, 'Mexican Cheese Sandwich', 'Mexican cheese sandwich', 100, 'Sandwich', true),
    (cafe_id, 'Veg Cheese Sandwich', 'Vegetable cheese sandwich', 90, 'Sandwich', true),
    (cafe_id, 'Aloo Cheese Sandwich', 'Potato cheese sandwich', 90, 'Sandwich', true);

    -- ========================================
    -- KHATI ROLL EXPRESS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Roll', 'Vegetable roll', 85, 'Khati Roll Express', true),
    (cafe_id, 'Veg Noodles Roll', 'Vegetable noodles roll', 100, 'Khati Roll Express', true),
    (cafe_id, 'Masala Aloo Roll', 'Spiced potato roll', 90, 'Khati Roll Express', true),
    (cafe_id, 'Aloo Tikki Roll', 'Potato tikki roll', 90, 'Khati Roll Express', true),
    (cafe_id, 'Mexican Tikki Roll', 'Mexican tikki roll', 100, 'Khati Roll Express', true),
    (cafe_id, 'Achari Aloo Tikki Roll', 'Pickle flavored potato tikki roll', 100, 'Khati Roll Express', true),
    (cafe_id, 'Spicy Chole Roll', 'Spicy chickpea roll', 95, 'Khati Roll Express', true),
    (cafe_id, 'Falafel Roll', 'Falafel roll', 100, 'Khati Roll Express', true),
    (cafe_id, 'Manchurian Dry Roll', 'Dry manchurian roll', 100, 'Khati Roll Express', true),
    (cafe_id, 'Paneer Popcorn Roll', 'Paneer popcorn roll', 125, 'Khati Roll Express', true),
    (cafe_id, 'Paneer Roll', 'Paneer roll', 130, 'Khati Roll Express', true),
    (cafe_id, 'Tandoori Paneer Roll', 'Tandoori paneer roll', 130, 'Khati Roll Express', true),
    (cafe_id, 'Peri Peri Paneer Roll', 'Peri peri paneer roll', 130, 'Khati Roll Express', true),
    (cafe_id, 'Paneer Tikka Roll', 'Paneer tikka roll', 140, 'Khati Roll Express', true),
    (cafe_id, 'Paneer Malai Roll', 'Creamy paneer roll', 140, 'Khati Roll Express', true),
    (cafe_id, 'Cheese Roll', 'Cheese roll', 130, 'Khati Roll Express', true),
    (cafe_id, 'BBQ Paneer Roll', 'BBQ paneer roll', 130, 'Khati Roll Express', true),
    (cafe_id, 'Schezwan Paneer Roll', 'Schezwan paneer roll', 140, 'Khati Roll Express', true),
    (cafe_id, 'Chilli Paneer Roll', 'Chili paneer roll', 140, 'Khati Roll Express', true),
    (cafe_id, 'Cheese Corn Roll', 'Cheese corn roll', 140, 'Khati Roll Express', true),
    (cafe_id, 'Paneer Corn Roll', 'Paneer corn roll', 140, 'Khati Roll Express', true),
    (cafe_id, 'Paneer Bhurji Roll', 'Scrambled paneer roll', 140, 'Khati Roll Express', true),
    (cafe_id, 'Paneer Pizza Roll', 'Paneer pizza roll', 140, 'Khati Roll Express', true),
    (cafe_id, 'Paneer Makhni Roll', 'Paneer makhni roll', 140, 'Khati Roll Express', true),
    (cafe_id, 'Achari Chaap Roll', 'Pickle flavored chaap roll', 135, 'Khati Roll Express', true),
    (cafe_id, 'Stuff Chaap Roll', 'Stuffed chaap roll', 140, 'Khati Roll Express', true),
    (cafe_id, 'Afgani Chaap Roll', 'Afghani chaap roll', 140, 'Khati Roll Express', true),
    (cafe_id, 'Garlic Chaap Roll', 'Garlic chaap roll', 140, 'Khati Roll Express', true),
    (cafe_id, 'Malai Chaap Roll', 'Creamy chaap roll', 140, 'Khati Roll Express', true),
    (cafe_id, 'Plain Egg Roll', 'Plain egg roll', 75, 'Khati Roll Express', true),
    (cafe_id, 'Egg Bhurji Roll', 'Scrambled egg roll', 85, 'Khati Roll Express', true),
    (cafe_id, 'Egg Roll', 'Egg roll', 95, 'Khati Roll Express', true),
    (cafe_id, 'Double Egg Roll', 'Double egg roll', 105, 'Khati Roll Express', true),
    (cafe_id, 'Double Egg Paneer Roll', 'Double egg paneer roll', 155, 'Khati Roll Express', true),
    (cafe_id, 'Egg Paneer Roll', 'Egg paneer roll', 145, 'Khati Roll Express', true),
    (cafe_id, 'Egg Cheese Roll', 'Egg cheese roll', 145, 'Khati Roll Express', true),
    (cafe_id, 'Egg Noodle Roll', 'Egg noodle roll', 110, 'Khati Roll Express', true),
    (cafe_id, 'Double Egg Noodle Roll', 'Double egg noodle roll', 120, 'Khati Roll Express', true),
    (cafe_id, 'Korean Paneer Roll', 'Korean paneer roll', 135, 'Khati Roll Express', true),
    (cafe_id, 'Hara Bhara Kabab Roll', 'Green herb kebab roll', 125, 'Khati Roll Express', true);

    -- ========================================
    -- PANINI SANDWICH
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Paneer Tikka Panini', 'Paneer tikka panini', 120, 'Panini Sandwich', true),
    (cafe_id, 'Tandoori Paneer Panini', 'Tandoori paneer panini', 110, 'Panini Sandwich', true),
    (cafe_id, 'Peri - Peri Panini', 'Peri peri panini', 110, 'Panini Sandwich', true),
    (cafe_id, 'Cheese Paneer Panini', 'Cheese paneer panini', 120, 'Panini Sandwich', true),
    (cafe_id, 'Corn Cheese Paneer Panini', 'Corn cheese paneer panini', 120, 'Panini Sandwich', true);

    -- ========================================
    -- PASTA
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'White Sauce Pasta', 'Creamy white sauce pasta', 160, 'Pasta', true),
    (cafe_id, 'Red Sauce Pasta', 'Tomato red sauce pasta', 150, 'Pasta', true),
    (cafe_id, 'Mix Sauce Pasta', 'Mixed sauce pasta', 160, 'Pasta', true),
    (cafe_id, 'Makhani Sauce Pasta', 'Buttery makhani sauce pasta', 160, 'Pasta', true),
    (cafe_id, 'Cheesy Jalapeno Pasta', 'Cheesy jalapeno pasta', 160, 'Pasta', true),
    (cafe_id, 'Corn N Cheese Pasta', 'Corn and cheese pasta', 160, 'Pasta', true),
    (cafe_id, 'Peri Peri Pasta', 'Spicy peri peri pasta', 160, 'Pasta', true);

    -- ========================================
    -- BURGER
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Korean Burger', 'Korean style burger', 80, 'Burger', true),
    (cafe_id, 'Aloo Tikki Burger', 'Potato tikki burger', 60, 'Burger', true),
    (cafe_id, 'Achari Veggie Burger', 'Pickle flavored veggie burger', 70, 'Burger', true),
    (cafe_id, 'Mexican Tikki Burger', 'Mexican tikki burger', 70, 'Burger', true),
    (cafe_id, 'Cheese Burger', 'Classic cheese burger', 80, 'Burger', true),
    (cafe_id, 'Double Aloo Tikki Burger', 'Double potato tikki burger', 80, 'Burger', true),
    (cafe_id, 'Crispy Paneer Burger', 'Crispy paneer burger', 80, 'Burger', true),
    (cafe_id, 'Falafel Tikki Burger', 'Falafel tikki burger', 80, 'Burger', true),
    (cafe_id, 'Crispy Paneer Cheese Burger', 'Crispy paneer cheese burger', 90, 'Burger', true);

    -- ========================================
    -- PIZZA
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Margarita Pizza (8")', 'Classic margarita pizza - 8 inch', 135, 'Pizza', true),
    (cafe_id, 'Margarita Pizza (12")', 'Classic margarita pizza - 12 inch', 255, 'Pizza', true),
    (cafe_id, 'OTC Pizza (8")', 'Onion tomato capsicum pizza - 8 inch', 145, 'Pizza', true),
    (cafe_id, 'OTC Pizza (12")', 'Onion tomato capsicum pizza - 12 inch', 265, 'Pizza', true),
    (cafe_id, 'Veg Pizza (8")', 'Vegetable pizza - 8 inch', 155, 'Pizza', true),
    (cafe_id, 'Veg Pizza (12")', 'Vegetable pizza - 12 inch', 275, 'Pizza', true),
    (cafe_id, 'Tandoori Paneer Pizza (8")', 'Tandoori paneer pizza - 8 inch', 170, 'Pizza', true),
    (cafe_id, 'Tandoori Paneer Pizza (12")', 'Tandoori paneer pizza - 12 inch', 310, 'Pizza', true),
    (cafe_id, 'Paneer Tikka Pizza (8")', 'Paneer tikka pizza - 8 inch', 180, 'Pizza', true),
    (cafe_id, 'Paneer Tikka Pizza (12")', 'Paneer tikka pizza - 12 inch', 320, 'Pizza', true),
    (cafe_id, 'Korean Paneer Pizza (8")', 'Korean paneer pizza - 8 inch', 180, 'Pizza', true),
    (cafe_id, 'Korean Paneer Pizza (12")', 'Korean paneer pizza - 12 inch', 320, 'Pizza', true),
    (cafe_id, 'Farm House Pizza (8")', 'Farm house pizza - 8 inch', 160, 'Pizza', true),
    (cafe_id, 'Farm House Pizza (12")', 'Farm house pizza - 12 inch', 280, 'Pizza', true),
    (cafe_id, 'Makhani Paneer Pizza (8")', 'Makhani paneer pizza - 8 inch', 180, 'Pizza', true),
    (cafe_id, 'Makhani Paneer Pizza (12")', 'Makhani paneer pizza - 12 inch', 320, 'Pizza', true);

    -- ========================================
    -- SUBS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Achari Aloo Patty Sub', 'Pickle flavored potato patty sub', 110, 'Subs', true),
    (cafe_id, 'Mexican Patty Sub', 'Mexican patty sub', 120, 'Subs', true),
    (cafe_id, 'Crispy Paneer Tikki Sub', 'Crispy paneer tikki sub', 120, 'Subs', true),
    (cafe_id, 'Hara Bhara Kabab Sub', 'Green herb kebab sub', 120, 'Subs', true),
    (cafe_id, 'Chatpata Chana Sub', 'Spicy chickpea sub', 110, 'Subs', true);

    RAISE NOTICE 'STARDOM Café & Lounge restaurant with comprehensive café menu added successfully';
END $$;
