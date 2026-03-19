-- Add 'The Crazy Chef' restaurant with comprehensive multi-cuisine menu
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
    'The Crazy Chef',
    'Multi-Cuisine',
    'A culinary adventure with THE CRAZY CHEF! Offering an extensive menu of pizzas, pasta, sandwiches, burgers, and international meals. From classic favorites to innovative creations, we bring you the perfect blend of taste and excitement!',
    'B1 First Floor',
    '+91-9521099336',
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
    SELECT id INTO cafe_id FROM public.cafes WHERE name = 'The Crazy Chef';
    
    -- ========================================
    -- VEG PIZZA (8" & 12")
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Margarita Pizza (8")', 'Classic margarita pizza - 8 inch', 140, 'Veg Pizza', true),
    (cafe_id, 'Margarita Pizza (12")', 'Classic margarita pizza - 12 inch', 260, 'Veg Pizza', true),
    (cafe_id, 'Veg Pizza (8")', 'Vegetable pizza - 8 inch', 160, 'Veg Pizza', true),
    (cafe_id, 'Veg Pizza (12")', 'Vegetable pizza - 12 inch', 280, 'Veg Pizza', true),
    (cafe_id, 'Paneer Tikka Pizza (8")', 'Paneer tikka pizza - 8 inch', 180, 'Veg Pizza', true),
    (cafe_id, 'Paneer Tikka Pizza (12")', 'Paneer tikka pizza - 12 inch', 320, 'Veg Pizza', true),
    (cafe_id, 'Prima Vera Pizza (8")', 'Prima vera pizza - 8 inch', 180, 'Veg Pizza', true),
    (cafe_id, 'Prima Vera Pizza (12")', 'Prima vera pizza - 12 inch', 340, 'Veg Pizza', true),
    (cafe_id, 'Mughlai Paneer Pizza (8")', 'Mughlai paneer pizza - 8 inch', 180, 'Veg Pizza', true),
    (cafe_id, 'Mughlai Paneer Pizza (12")', 'Mughlai paneer pizza - 12 inch', 360, 'Veg Pizza', true),
    (cafe_id, 'Spicy Hawaiian Pizza (8")', 'Spicy Hawaiian pizza - 8 inch', 180, 'Veg Pizza', true),
    (cafe_id, 'Spicy Hawaiian Pizza (12")', 'Spicy Hawaiian pizza - 12 inch', 360, 'Veg Pizza', true);

    -- ========================================
    -- NONVEG PIZZA (8" & 12")
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Spicy BBQ Chicken Pizza (8")', 'Spicy BBQ chicken pizza - 8 inch', 190, 'Non-Veg Pizza', true),
    (cafe_id, 'Spicy BBQ Chicken Pizza (12")', 'Spicy BBQ chicken pizza - 12 inch', 360, 'Non-Veg Pizza', true),
    (cafe_id, 'Chicken Keema Pizza (8")', 'Chicken keema pizza - 8 inch', 190, 'Non-Veg Pizza', true),
    (cafe_id, 'Chicken Keema Pizza (12")', 'Chicken keema pizza - 12 inch', 360, 'Non-Veg Pizza', true),
    (cafe_id, 'Chicken Tikka Pizza (8")', 'Chicken tikka pizza - 8 inch', 190, 'Non-Veg Pizza', true),
    (cafe_id, 'Chicken Tikka Pizza (12")', 'Chicken tikka pizza - 12 inch', 360, 'Non-Veg Pizza', true),
    (cafe_id, 'Chicken Makhani Pizza (8")', 'Chicken makhani pizza - 8 inch', 190, 'Non-Veg Pizza', true),
    (cafe_id, 'Chicken Makhani Pizza (12")', 'Chicken makhani pizza - 12 inch', 360, 'Non-Veg Pizza', true),
    (cafe_id, 'Triple Chicken Loaded Pizza (8")', 'Triple chicken loaded pizza - 8 inch', 220, 'Non-Veg Pizza', true),
    (cafe_id, 'Triple Chicken Loaded Pizza (12")', 'Triple chicken loaded pizza - 12 inch', 400, 'Non-Veg Pizza', true),
    (cafe_id, 'Hot & Sweet Chicken Pizza (8")', 'Hot & sweet chicken pizza - 8 inch', 210, 'Non-Veg Pizza', true),
    (cafe_id, 'Hot & Sweet Chicken Pizza (12")', 'Hot & sweet chicken pizza - 12 inch', 400, 'Non-Veg Pizza', true),
    (cafe_id, 'Hot Pepperoni Pizza (8")', 'Hot pepperoni pizza - 8 inch', 220, 'Non-Veg Pizza', true),
    (cafe_id, 'Hot Pepperoni Pizza (12")', 'Hot pepperoni pizza - 12 inch', 400, 'Non-Veg Pizza', true);

    -- ========================================
    -- PASTA
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Exotic Veg Pasta', 'Exotic vegetable pasta', 180, 'Pasta', true),
    (cafe_id, 'Chicken Pasta', 'Chicken pasta', 200, 'Pasta', true);

    -- ========================================
    -- VEG SANDWICHES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Bombay Aloo Sandwich', 'Bombay style potato sandwich', 70, 'Veg Sandwiches', true),
    (cafe_id, 'Grilled Veg Sandwich', 'Grilled vegetable sandwich', 80, 'Veg Sandwiches', true),
    (cafe_id, 'Veg Cheese Sandwich', 'Vegetable cheese sandwich', 100, 'Veg Sandwiches', true),
    (cafe_id, 'Cheesy Lava Sandwich', 'Cheesy lava sandwich', 120, 'Veg Sandwiches', true),
    (cafe_id, 'Tandoori Paneer Sandwich', 'Tandoori paneer sandwich', 100, 'Veg Sandwiches', true);

    -- ========================================
    -- NONVEG SANDWICHES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Chicken Corn Cheese Sandwich', 'Chicken corn cheese sandwich', 110, 'Non-Veg Sandwiches', true),
    (cafe_id, 'Spicy Chicken Sandwich', 'Spicy chicken sandwich', 100, 'Non-Veg Sandwiches', true),
    (cafe_id, 'Tandoori Chicken Sandwich', 'Tandoori chicken sandwich', 100, 'Non-Veg Sandwiches', true),
    (cafe_id, 'Kadhai Chicken Sandwich', 'Kadhai chicken sandwich', 100, 'Non-Veg Sandwiches', true),
    (cafe_id, 'Chicken Jalapeno Sandwich', 'Chicken jalapeno sandwich', 100, 'Non-Veg Sandwiches', true);

    -- ========================================
    -- VEG BURGERS (Burger / Meal)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Achari Aloo Burger', 'Pickle flavored potato burger', 50, 'Veg Burgers', true),
    (cafe_id, 'Achari Aloo Burger Meal', 'Pickle flavored potato burger with fries and drink', 130, 'Veg Burgers', true),
    (cafe_id, 'Masala Veg Burger', 'Spicy masala vegetable burger', 70, 'Veg Burgers', true),
    (cafe_id, 'Masala Veg Burger Meal', 'Spicy masala vegetable burger with fries and drink', 150, 'Veg Burgers', true),
    (cafe_id, 'Falafel Burger', 'Falafel burger', 80, 'Veg Burgers', true),
    (cafe_id, 'Falafel Burger Meal', 'Falafel burger with fries and drink', 160, 'Veg Burgers', true),
    (cafe_id, 'Mexican Bean Burger', 'Mexican bean burger', 90, 'Veg Burgers', true),
    (cafe_id, 'Mexican Bean Burger Meal', 'Mexican bean burger with fries and drink', 160, 'Veg Burgers', true),
    (cafe_id, 'Crispy Paneer Burger', 'Crispy paneer burger', 100, 'Veg Burgers', true),
    (cafe_id, 'Crispy Paneer Burger Meal', 'Crispy paneer burger with fries and drink', 180, 'Veg Burgers', true);

    -- ========================================
    -- NONVEG BURGERS (Burger / Meal)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Chicken Chipotle Burger', 'Chicken chipotle burger', 80, 'Non-Veg Burgers', true),
    (cafe_id, 'Chicken Chipotle Burger Meal', 'Chicken chipotle burger with fries and drink', 160, 'Non-Veg Burgers', true),
    (cafe_id, 'Simply Chicken Burger', 'Simply chicken burger', 85, 'Non-Veg Burgers', true),
    (cafe_id, 'Simply Chicken Burger Meal', 'Simply chicken burger with fries and drink', 170, 'Non-Veg Burgers', true),
    (cafe_id, 'Tandoori Chicken Burger', 'Tandoori chicken burger', 120, 'Non-Veg Burgers', true),
    (cafe_id, 'Tandoori Chicken Burger Meal', 'Tandoori chicken burger with fries and drink', 190, 'Non-Veg Burgers', true),
    (cafe_id, 'Spicy Chicken Burger', 'Spicy chicken burger', 120, 'Non-Veg Burgers', true),
    (cafe_id, 'Spicy Chicken Burger Meal', 'Spicy chicken burger with fries and drink', 190, 'Non-Veg Burgers', true),
    (cafe_id, 'Crazy Chicken Burger', 'Crazy chicken burger', 120, 'Non-Veg Burgers', true),
    (cafe_id, 'Crazy Chicken Burger Meal', 'Crazy chicken burger with fries and drink', 190, 'Non-Veg Burgers', true),
    (cafe_id, 'Italian Parma Burger', 'Italian parma chicken burger', 120, 'Non-Veg Burgers', true),
    (cafe_id, 'Italian Parma Burger Meal', 'Italian parma chicken burger with fries and drink', 190, 'Non-Veg Burgers', true),
    (cafe_id, 'Double Devil Chicken Burger', 'Double devil chicken burger', 150, 'Non-Veg Burgers', true),
    (cafe_id, 'Double Devil Chicken Burger Meal', 'Double devil chicken burger with fries and drink', 220, 'Non-Veg Burgers', true),
    (cafe_id, 'Fish Fillet Burger', 'Fish fillet burger', 150, 'Non-Veg Burgers', true),
    (cafe_id, 'Fish Fillet Burger Meal', 'Fish fillet burger with fries and drink', 220, 'Non-Veg Burgers', true),
    (cafe_id, 'Mutton Burger', 'Mutton burger', 150, 'Non-Veg Burgers', true),
    (cafe_id, 'Mutton Burger Meal', 'Mutton burger with fries and drink', 220, 'Non-Veg Burgers', true);

    -- ========================================
    -- VEG MEALS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Oriental Veg with Fries', 'Oriental vegetable with fries', 250, 'Veg Meals', true),
    (cafe_id, 'BBQ Paneer & Fries', 'BBQ paneer with fries', 250, 'Veg Meals', true),
    (cafe_id, 'Korean Crispy Veg with Fries', 'Korean crispy vegetable with fries', 250, 'Veg Meals', true),
    (cafe_id, 'Rice Bowl (Pesto)', 'Pesto rice bowl', 250, 'Veg Meals', true),
    (cafe_id, 'Rice Bowl (Roasted Garlic Tomato)', 'Roasted garlic tomato rice bowl', 250, 'Veg Meals', true),
    (cafe_id, 'Rice Bowl (Peri Peri)', 'Peri peri rice bowl', 250, 'Veg Meals', true),
    (cafe_id, 'Rice Bowl (Thai)', 'Thai rice bowl', 250, 'Veg Meals', true),
    (cafe_id, 'Paneer Parma', 'Paneer parma', 250, 'Veg Meals', true);

    -- ========================================
    -- NONVEG MEALS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Chicken Schnitzel', 'Chicken schnitzel', 230, 'Non-Veg Meals', true),
    (cafe_id, 'Chicken Parma', 'Chicken parma', 250, 'Non-Veg Meals', true),
    (cafe_id, 'Grilled Chicken & Chips', 'Grilled chicken with chips', 250, 'Non-Veg Meals', true),
    (cafe_id, 'BBQ Chicken & Chips', 'BBQ chicken with chips', 250, 'Non-Veg Meals', true),
    (cafe_id, 'South West Chicken', 'South west chicken', 250, 'Non-Veg Meals', true),
    (cafe_id, 'Korean Chicken & Chips', 'Korean chicken with chips', 250, 'Non-Veg Meals', true),
    (cafe_id, 'Chicken Rice Bowl (Pesto)', 'Chicken pesto rice bowl', 250, 'Non-Veg Meals', true),
    (cafe_id, 'Chicken Rice Bowl (Roasted Garlic Tomato)', 'Chicken roasted garlic tomato rice bowl', 250, 'Non-Veg Meals', true),
    (cafe_id, 'Chicken Rice Bowl (Peri Peri)', 'Chicken peri peri rice bowl', 250, 'Non-Veg Meals', true),
    (cafe_id, 'Chicken Rice Bowl (Thai)', 'Chicken Thai rice bowl', 250, 'Non-Veg Meals', true),
    (cafe_id, 'Fish & Chips', 'Fish and chips', 270, 'Non-Veg Meals', true),
    (cafe_id, 'Korean Fish & Chips', 'Korean fish and chips', 270, 'Non-Veg Meals', true),
    (cafe_id, 'Thai Red Fish With Rice', 'Thai red fish with rice', 270, 'Non-Veg Meals', true);

    -- ========================================
    -- VEG SNAKKERS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Spicy Paneer Slider', 'Spicy paneer slider', 70, 'Veg Snackers', true),
    (cafe_id, 'Paneer Popcorn', 'Paneer popcorn', 100, 'Veg Snackers', true),
    (cafe_id, 'Peri Peri French Fries', 'Spicy peri peri french fries', 90, 'Veg Snackers', true),
    (cafe_id, 'Crispy Garlic Bread', 'Crispy garlic bread', 90, 'Veg Snackers', true),
    (cafe_id, 'Cheesy Garlic Bread', 'Cheesy garlic bread', 140, 'Veg Snackers', true),
    (cafe_id, 'Mac N Cheese', 'Mac and cheese', 150, 'Veg Snackers', true),
    (cafe_id, 'Vada Pav', 'Traditional vada pav', 40, 'Veg Snackers', true);

    -- ========================================
    -- NONVEG SNAKKERS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Cheesy Chicken Slider', 'Cheesy chicken slider', 80, 'Non-Veg Snackers', true),
    (cafe_id, 'Crispy Chiplets', 'Crispy chiplets', 150, 'Non-Veg Snackers', true),
    (cafe_id, 'Chicken Pop Corn', 'Chicken popcorn', 120, 'Non-Veg Snackers', true),
    (cafe_id, 'Fried Chicken Wings', 'Fried chicken wings', 170, 'Non-Veg Snackers', true),
    (cafe_id, 'Grilled Korean Wings', 'Grilled Korean chicken wings', 170, 'Non-Veg Snackers', true),
    (cafe_id, 'Baked Mac Chicken', 'Baked mac and cheese with chicken', 170, 'Non-Veg Snackers', true);

    -- ========================================
    -- VEG PANINI
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Cheese Panini', 'Vegetable cheese panini', 150, 'Veg Panini', true),
    (cafe_id, 'Jalapeno Paneer Panini', 'Jalapeno paneer panini', 160, 'Veg Panini', true),
    (cafe_id, 'Paneer Tikka Panini', 'Paneer tikka panini', 160, 'Veg Panini', true);

    -- ========================================
    -- NONVEG PANINI
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'BBQ Chicken Panini', 'BBQ chicken panini', 160, 'Non-Veg Panini', true),
    (cafe_id, 'Spicy Chicken Panini', 'Spicy chicken panini', 160, 'Non-Veg Panini', true),
    (cafe_id, 'Grilled Chicken Panini', 'Grilled chicken panini', 160, 'Non-Veg Panini', true);

    -- ========================================
    -- LOADED FRIES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Spicy Chicken Fries', 'Spicy chicken loaded fries', 160, 'Loaded Fries', true),
    (cafe_id, 'Cheesy Italian Fries', 'Cheesy Italian loaded fries', 140, 'Loaded Fries', true),
    (cafe_id, 'BBQ Chicken Fries', 'BBQ chicken loaded fries', 160, 'Loaded Fries', true),
    (cafe_id, 'Chilly Cheese Fries', 'Chilly cheese loaded fries', 140, 'Loaded Fries', true),
    (cafe_id, 'Italian Chicken Fries', 'Italian chicken loaded fries', 170, 'Loaded Fries', true),
    (cafe_id, 'Paneer Makhani Fries', 'Paneer makhani loaded fries', 140, 'Loaded Fries', true),
    (cafe_id, 'Desi Keema Fries', 'Desi keema loaded fries', 160, 'Loaded Fries', true);

    RAISE NOTICE 'The Crazy Chef restaurant with comprehensive multi-cuisine menu added successfully';
END $$;
