-- Add 'ZERO DEGREE CAFE' restaurant with comprehensive café menu
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
    'ZERO DEGREE CAFE',
    'Café & Multi-Cuisine',
    'ZERO DEGREE CAFE ESTD 2018 - SIP & EAT! A vibrant café offering hot beverages, cold drinks, Chinese cuisine, wings, kebabs, sandwiches, shakes, pizza, pasta, and more. From refreshing beverages to delicious comfort food, we bring you the perfect blend of taste and ambiance!',
    'Ground Floor, GHS',
    '+91-82336 73311',
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
    SELECT id INTO cafe_id FROM public.cafes WHERE name = 'ZERO DEGREE CAFE';
    
    -- ========================================
    -- HOT BEVERAGES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Madras Filter Coffee', 'Traditional Madras filter coffee', 20, 'Hot Beverages', true),
    (cafe_id, 'Lemon Tea', 'Refreshing lemon tea', 20, 'Hot Beverages', true),
    (cafe_id, 'Hot Chocolate', 'Rich hot chocolate', 60, 'Hot Beverages', true);

    -- ========================================
    -- ICE TEA COLD BEVERAGES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Ice Tea', 'Classic iced tea', 40, 'Ice Tea Cold Beverages', true),
    (cafe_id, 'Ice Tea (Large)', 'Large iced tea', 50, 'Ice Tea Cold Beverages', true),
    (cafe_id, 'Add-on Any Flavors (Peach)', 'Peach flavor add-on for ice tea', 15, 'Ice Tea Cold Beverages', true),
    (cafe_id, 'Add-on Any Flavors (Watermelon)', 'Watermelon flavor add-on for ice tea', 15, 'Ice Tea Cold Beverages', true),
    (cafe_id, 'Add-on Any Flavors (Caramel)', 'Caramel flavor add-on for ice tea', 20, 'Ice Tea Cold Beverages', true),
    (cafe_id, 'Nimbu Pani', 'Traditional lemon water', 30, 'Ice Tea Cold Beverages', true);

    -- ========================================
    -- COLD COFFEE FRAPPES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Cold Coffee', 'Classic cold coffee', 60, 'Cold Coffee Frappes', true),
    (cafe_id, 'Caramel - Hazelnut Frappe (Small)', 'Caramel hazelnut frappe - small size', 50, 'Cold Coffee Frappes', true),
    (cafe_id, 'Caramel - Hazelnut Frappe (Large)', 'Caramel hazelnut frappe - large size', 100, 'Cold Coffee Frappes', true);

    -- ========================================
    -- FRENCH FRIES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Salted Fries', 'Classic salted french fries', 80, 'French Fries', true),
    (cafe_id, 'Masala Fries', 'Spicy masala fries', 90, 'French Fries', true),
    (cafe_id, 'Peri Peri Fries', 'Spicy peri peri fries', 90, 'French Fries', true),
    (cafe_id, 'Melted Cheese Fries', 'Cheese topped fries', 120, 'French Fries', true),
    (cafe_id, 'Chicken Fries', 'Chicken flavored fries', 150, 'French Fries', true);

    -- ========================================
    -- MUNCHIES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Potato Wedges', 'Crispy potato wedges', 80, 'Munchies', true),
    (cafe_id, 'Veggie Nuggets', 'Vegetable nuggets', 90, 'Munchies', true),
    (cafe_id, 'Chicken Nuggets', 'Chicken nuggets', 100, 'Munchies', true),
    (cafe_id, 'Chicken Fingers', 'Chicken fingers', 110, 'Munchies', true),
    (cafe_id, 'Corn Cheese Poppers', 'Corn cheese poppers', 120, 'Munchies', true);

    -- ========================================
    -- CHINESE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Dimsums', 'Vegetable dimsums', 70, 'Chinese', true),
    (cafe_id, 'Veg Kabab Dimsums', 'Vegetable kebab dimsums', 90, 'Chinese', true),
    (cafe_id, 'Paneer Dimsums', 'Paneer dimsums', 100, 'Chinese', true),
    (cafe_id, 'Veg Spring Roll', 'Vegetable spring roll', 100, 'Chinese', true),
    (cafe_id, 'Chicken Dimsums', 'Chicken dimsums', 100, 'Chinese', true),
    (cafe_id, 'Chicken Spring Roll', 'Chicken spring roll', 120, 'Chinese', true),
    (cafe_id, 'Chicken Lollypop', 'Chicken lollypop', 120, 'Chinese', true);

    -- ========================================
    -- WINGS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Mustard Chicken Chilli Wings', 'Mustard chicken chilli wings', 150, 'Wings', true),
    (cafe_id, 'Chicken Wings', 'Classic chicken wings', 150, 'Wings', true),
    (cafe_id, 'BBQ Chicken Wings', 'BBQ chicken wings', 150, 'Wings', true);

    -- ========================================
    -- KEBAB AND TIKKA
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Chicken Seekh Kebab', 'Chicken seekh kebab', 120, 'Kebab and Tikka', true),
    (cafe_id, 'Chicken Seekh Peri Peri Kebab', 'Spicy peri peri chicken seekh kebab', 120, 'Kebab and Tikka', true),
    (cafe_id, 'Chicken Seekh Kebab Malai', 'Creamy malai chicken seekh kebab', 120, 'Kebab and Tikka', true),
    (cafe_id, 'Chicken Seekh Kebab Hot & Spicy', 'Hot and spicy chicken seekh kebab', 120, 'Kebab and Tikka', true),
    (cafe_id, 'Chicken Lollypop', 'Chicken lollypop', 120, 'Kebab and Tikka', true);

    -- ========================================
    -- SANDWICHES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veggie Delight SW', 'Vegetable delight sandwich', 60, 'Sandwiches', true),
    (cafe_id, 'Tandoori Paneer Tikka SW', 'Tandoori paneer tikka sandwich', 100, 'Sandwiches', true),
    (cafe_id, 'Mexican SW', 'Mexican sandwich', 90, 'Sandwiches', true),
    (cafe_id, 'Corn & Cheese SW', 'Corn and cheese sandwich', 90, 'Sandwiches', true),
    (cafe_id, 'Tandoori Chicken Tikka SW', 'Tandoori chicken tikka sandwich', 120, 'Sandwiches', true),
    (cafe_id, 'Smoky BBQ Chicken SW', 'Smoky BBQ chicken sandwich', 120, 'Sandwiches', true),
    (cafe_id, 'Chicken Sausage SW', 'Chicken sausage sandwich', 110, 'Sandwiches', true),
    (cafe_id, 'Chicken Seekh Kebab Peri Peri', 'Spicy peri peri chicken seekh kebab sandwich', 100, 'Sandwiches', true);

    -- ========================================
    -- SHAKES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Strawberry Shake', 'Strawberry milkshake', 70, 'Shakes', true),
    (cafe_id, 'Chocolate Shake', 'Chocolate milkshake', 80, 'Shakes', true),
    (cafe_id, 'Butterscotch Shake', 'Butterscotch milkshake', 80, 'Shakes', true),
    (cafe_id, 'Oreo Shake', 'Oreo milkshake', 80, 'Shakes', true),
    (cafe_id, 'Kitkat Shake', 'KitKat milkshake', 80, 'Shakes', true),
    (cafe_id, 'Brownie Shake', 'Brownie milkshake', 90, 'Shakes', true),
    (cafe_id, 'Kitkat Gems Shake', 'KitKat gems milkshake', 90, 'Shakes', true),
    (cafe_id, 'Nutella Shake', 'Nutella milkshake', 120, 'Shakes', true);

    -- ========================================
    -- COLD PRESS FRESH JUICE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Orange Juice', 'Fresh cold pressed orange juice', 70, 'Cold Press Fresh Juice', true),
    (cafe_id, 'Watermelon Juice', 'Fresh cold pressed watermelon juice', 70, 'Cold Press Fresh Juice', true),
    (cafe_id, 'Pineapple Shake', 'Fresh pineapple shake', 70, 'Cold Press Fresh Juice', false),
    (cafe_id, 'Apple Juice', 'Fresh cold pressed apple juice', 70, 'Cold Press Fresh Juice', true);

    -- ========================================
    -- MOCKTAILS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Classic Lemonade', 'Classic lemonade', 50, 'Mocktails', true),
    (cafe_id, 'Virgin Mint Mojito', 'Virgin mint mojito', 80, 'Mocktails', true),
    (cafe_id, 'Green Apple Mojito', 'Green apple mojito', 80, 'Mocktails', true),
    (cafe_id, 'Black Currant Mojito', 'Black currant mojito', 80, 'Mocktails', true),
    (cafe_id, 'Blueberry Mojito', 'Blueberry mojito', 80, 'Mocktails', true),
    (cafe_id, 'Orange Mojito', 'Orange mojito', 80, 'Mocktails', true),
    (cafe_id, 'Watermelon Mojito', 'Watermelon mojito', 80, 'Mocktails', true),
    (cafe_id, 'Cranberry Mojito', 'Cranberry mojito', 80, 'Mocktails', true),
    (cafe_id, 'Blue Lagoon Mojito', 'Blue lagoon mojito', 80, 'Mocktails', true);

    -- ========================================
    -- DESSERT
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Hot Chocolate Brownie', 'Hot chocolate brownie', 80, 'Dessert', true),
    (cafe_id, 'Brownie with Ice Cream', 'Brownie served with ice cream', 90, 'Dessert', true),
    (cafe_id, 'Cake', 'Assorted cake selection - price varies', 0, 'Dessert', true);

    -- ========================================
    -- BURGER
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Aloo Tikki Burger', 'Potato tikki burger', 50, 'Burger', true),
    (cafe_id, 'Achari Aloo Burger', 'Pickle flavored potato burger', 50, 'Burger', true),
    (cafe_id, 'Crispy Veggie Burger', 'Crispy vegetable burger', 70, 'Burger', true),
    (cafe_id, 'Mexican Burger', 'Mexican style burger', 80, 'Burger', true),
    (cafe_id, 'Spicy Paneer Burger', 'Spicy paneer burger', 90, 'Burger', true),
    (cafe_id, 'Grilled Chicken Burger', 'Grilled chicken burger', 100, 'Burger', true),
    (cafe_id, 'Chicken Burger', 'Classic chicken burger', 110, 'Burger', true),
    (cafe_id, 'Egg Burger', 'Egg burger', 70, 'Burger', true);

    -- ========================================
    -- BIRYANI (Launching Soon)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Biryani', 'Vegetable biryani - launching soon', 0, 'Biryani', false),
    (cafe_id, 'Chicken Biryani', 'Chicken biryani - launching soon', 0, 'Biryani', false),
    (cafe_id, 'Paneer Biryani', 'Paneer biryani - launching soon', 0, 'Biryani', false);

    -- ========================================
    -- PIZZA (7"/11"/16")
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Classic Margarita Pizza (7")', 'Classic margarita pizza - 7 inch', 120, 'Pizza', true),
    (cafe_id, 'Classic Margarita Pizza (11")', 'Classic margarita pizza - 11 inch', 230, 'Pizza', true),
    (cafe_id, 'Classic Margarita Pizza (16")', 'Classic margarita pizza - 16 inch', 400, 'Pizza', true),
    (cafe_id, 'Simply Veg Pizza (7")', 'Simply vegetable pizza - 7 inch', 120, 'Pizza', true),
    (cafe_id, 'Simply Veg Pizza (11")', 'Simply vegetable pizza - 11 inch', 230, 'Pizza', true),
    (cafe_id, 'Simply Veg Pizza (16")', 'Simply vegetable pizza - 16 inch', 400, 'Pizza', true),
    (cafe_id, 'Farmhouse Pizza (7")', 'Farmhouse pizza - 7 inch', 160, 'Pizza', true),
    (cafe_id, 'Farmhouse Pizza (11")', 'Farmhouse pizza - 11 inch', 280, 'Pizza', true),
    (cafe_id, 'Farmhouse Pizza (16")', 'Farmhouse pizza - 16 inch', 420, 'Pizza', true),
    (cafe_id, 'Kadai Paneer Pizza (7")', 'Kadai paneer pizza - 7 inch', 180, 'Pizza', true),
    (cafe_id, 'Kadai Paneer Pizza (11")', 'Kadai paneer pizza - 11 inch', 310, 'Pizza', true),
    (cafe_id, 'Kadai Paneer Pizza (16")', 'Kadai paneer pizza - 16 inch', 480, 'Pizza', true),
    (cafe_id, 'Makhani Paneer Tikka Pizza (7")', 'Makhani paneer tikka pizza - 7 inch', 180, 'Pizza', true),
    (cafe_id, 'Makhani Paneer Tikka Pizza (11")', 'Makhani paneer tikka pizza - 11 inch', 310, 'Pizza', true),
    (cafe_id, 'Makhani Paneer Tikka Pizza (16")', 'Makhani paneer tikka pizza - 16 inch', 480, 'Pizza', true),
    (cafe_id, 'Exotica Pizza (7")', 'Exotica pizza - 7 inch', 180, 'Pizza', true),
    (cafe_id, 'Exotica Pizza (11")', 'Exotica pizza - 11 inch', 330, 'Pizza', true),
    (cafe_id, 'Exotica Pizza (16")', 'Exotica pizza - 16 inch', 500, 'Pizza', true),
    (cafe_id, 'Chicken BBQ Tikka Pizza (7")', 'Chicken BBQ tikka pizza - 7 inch', 190, 'Pizza', true),
    (cafe_id, 'Chicken BBQ Tikka Pizza (11")', 'Chicken BBQ tikka pizza - 11 inch', 330, 'Pizza', true),
    (cafe_id, 'Chicken BBQ Tikka Pizza (16")', 'Chicken BBQ tikka pizza - 16 inch', 500, 'Pizza', true),
    (cafe_id, 'Spicy Chicken Delight Pizza (7")', 'Spicy chicken delight pizza - 7 inch', 190, 'Pizza', true),
    (cafe_id, 'Spicy Chicken Delight Pizza (11")', 'Spicy chicken delight pizza - 11 inch', 330, 'Pizza', true),
    (cafe_id, 'Spicy Chicken Delight Pizza (16")', 'Spicy chicken delight pizza - 16 inch', 500, 'Pizza', true),
    (cafe_id, 'Classic Chicken Keema Pizza (7")', 'Classic chicken keema pizza - 7 inch', 190, 'Pizza', true),
    (cafe_id, 'Classic Chicken Keema Pizza (11")', 'Classic chicken keema pizza - 11 inch', 330, 'Pizza', true),
    (cafe_id, 'Classic Chicken Keema Pizza (16")', 'Classic chicken keema pizza - 16 inch', 500, 'Pizza', true),
    (cafe_id, 'Chicken Keema Fiesta Pizza (7")', 'Chicken keema fiesta pizza - 7 inch', 190, 'Pizza', true),
    (cafe_id, 'Chicken Keema Fiesta Pizza (11")', 'Chicken keema fiesta pizza - 11 inch', 330, 'Pizza', true),
    (cafe_id, 'Chicken Keema Fiesta Pizza (16")', 'Chicken keema fiesta pizza - 16 inch', 500, 'Pizza', true),
    (cafe_id, 'Chicken Pepperoni Pizza (7")', 'Chicken pepperoni pizza - 7 inch', 200, 'Pizza', true),
    (cafe_id, 'Chicken Pepperoni Pizza (11")', 'Chicken pepperoni pizza - 11 inch', 350, 'Pizza', true),
    (cafe_id, 'Chicken Pepperoni Pizza (16")', 'Chicken pepperoni pizza - 16 inch', 600, 'Pizza', true),
    (cafe_id, 'Chicken Supreme Pizza (7")', 'Chicken supreme pizza - 7 inch', 200, 'Pizza', true),
    (cafe_id, 'Chicken Supreme Pizza (11")', 'Chicken supreme pizza - 11 inch', 350, 'Pizza', true),
    (cafe_id, 'Chicken Supreme Pizza (16")', 'Chicken supreme pizza - 16 inch', 600, 'Pizza', true),
    (cafe_id, 'Chicken Sausage Pizza (7")', 'Chicken sausage pizza - 7 inch', 200, 'Pizza', true),
    (cafe_id, 'Chicken Sausage Pizza (11")', 'Chicken sausage pizza - 11 inch', 350, 'Pizza', true),
    (cafe_id, 'Chicken Sausage Pizza (16")', 'Chicken sausage pizza - 16 inch', 600, 'Pizza', true);

    -- ========================================
    -- PIZZA ADD-ONS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Add Sausage to Pizza', 'Add sausage topping to any pizza', 50, 'Pizza Add-ons', true),
    (cafe_id, 'Extra Toppings', 'Extra toppings for pizza', 30, 'Pizza Add-ons', true),
    (cafe_id, 'Extra Cheese', 'Extra cheese for pizza', 40, 'Pizza Add-ons', true),
    (cafe_id, 'Extra Chicken', 'Extra chicken for pizza', 60, 'Pizza Add-ons', true);

    -- ========================================
    -- WRAPS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Simply Veg Wrap', 'Simple vegetable wrap', 70, 'Wraps', true),
    (cafe_id, 'Aloo Tikki Wrap', 'Potato tikki wrap', 70, 'Wraps', true),
    (cafe_id, 'Spicy Paneer Wrap', 'Spicy paneer wrap', 80, 'Wraps', true),
    (cafe_id, 'Egg Wrap', 'Egg wrap', 50, 'Wraps', true),
    (cafe_id, 'Crispy Fried Chicken Wrap', 'Crispy fried chicken wrap', 100, 'Wraps', true),
    (cafe_id, 'Tandoori Chicken Tikka Wrap', 'Tandoori chicken tikka wrap', 110, 'Wraps', true),
    (cafe_id, 'Peri Peri Chicken Seekh Wrap', 'Spicy peri peri chicken seekh wrap', 120, 'Wraps', true);

    -- ========================================
    -- PASTA
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Red Sauce Pasta with Exotic Veg', 'Red sauce pasta with exotic vegetables', 150, 'Pasta', true),
    (cafe_id, 'White Sauce Pasta', 'Creamy white sauce pasta', 150, 'Pasta', true),
    (cafe_id, 'Mix Sauce Pasta', 'Mixed sauce pasta', 150, 'Pasta', true);

    -- ========================================
    -- PASTA ADD-ONS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Extra Cheese for Pasta', 'Extra cheese for pasta', 30, 'Pasta Add-ons', true),
    (cafe_id, 'Add Chicken to Pasta', 'Add chicken to pasta', 50, 'Pasta Add-ons', true),
    (cafe_id, 'Add Meatball to Pasta', 'Add meatball to pasta', 40, 'Pasta Add-ons', true),
    (cafe_id, 'Add Chicken Tikka to Pasta', 'Add chicken tikka to pasta', 60, 'Pasta Add-ons', true),
    (cafe_id, 'Add Sausage to Pasta', 'Add sausage to pasta', 50, 'Pasta Add-ons', true),
    (cafe_id, 'Add Seekh Kebab to Pasta', 'Add seekh kebab to pasta', 70, 'Pasta Add-ons', true);

    -- ========================================
    -- BREAKFAST MENU
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Poha', 'Traditional poha', 30, 'Breakfast Menu', true),
    (cafe_id, 'Vada Pav', 'Classic vada pav', 35, 'Breakfast Menu', true),
    (cafe_id, 'Boiled Egg (2 Pcs)', 'Boiled eggs - 2 pieces', 50, 'Breakfast Menu', true),
    (cafe_id, 'Fresh Garden Salad', 'Fresh garden salad', 50, 'Breakfast Menu', true),
    (cafe_id, 'Chicken Caesar Salad', 'Chicken caesar salad', 180, 'Breakfast Menu', true);

    -- ========================================
    -- SOUP
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Tomato Basil Soup', 'Tomato basil soup', 60, 'Soup', true),
    (cafe_id, 'Cream of Mushroom Soup', 'Cream of mushroom soup', 80, 'Soup', true);

    -- ========================================
    -- SOUP ADD-ONS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Add Chicken to Soup', 'Add chicken to soup', 30, 'Soup Add-ons', true),
    (cafe_id, 'Add Mushroom to Soup', 'Add mushroom to soup', 30, 'Soup Add-ons', true),
    (cafe_id, 'Add Veg to Soup', 'Add vegetables to soup', 30, 'Soup Add-ons', true);

    -- ========================================
    -- SIDE APPETIZERS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Garlic Bread', 'Classic garlic bread', 80, 'Side Appetizers', true),
    (cafe_id, 'Chicken Fried KFC Style', 'KFC style fried chicken', 200, 'Side Appetizers', true);

    RAISE NOTICE 'ZERO DEGREE CAFE restaurant with comprehensive café menu added successfully';
END $$;
