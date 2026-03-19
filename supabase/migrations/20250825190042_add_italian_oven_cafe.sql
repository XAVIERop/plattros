-- Add ITALIAN OVEN cafe and all menu items
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
    'ITALIAN OVEN',
    'Italian',
    'Authentic Italian cuisine with a modern twist. From classic pizzas to gourmet pasta, thick shakes to jumbo sandwiches - we bring you the finest Italian flavors. Specializing in wood-fired pizzas, creamy pasta, and delicious Italian-inspired dishes.',
    'G1 First Floor',
    '+91-8905464595',
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
    SELECT id INTO cafe_id FROM public.cafes WHERE name = 'ITALIAN OVEN';
    
    -- ALL-TIME FAVORITE PIZZA
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Classic Margarita (8")', 'Classic cheese red sauce with basil - 8 inch', 130, 'Pizza', true),
    (cafe_id, 'Classic Margarita (11")', 'Classic cheese red sauce with basil - 11 inch', 240, 'Pizza', true),
    (cafe_id, 'Classic Margarita (16")', 'Classic cheese red sauce with basil - 16 inch', 420, 'Pizza', true),
    (cafe_id, 'Margarita Loaded Cheese (8")', 'Loaded with extra cheese oodies and basil - 8 inch', 180, 'Pizza', true),
    (cafe_id, 'Margarita Loaded Cheese (11")', 'Loaded with extra cheese oodies and basil - 11 inch', 290, 'Pizza', true),
    (cafe_id, 'Margarita Loaded Cheese (16")', 'Loaded with extra cheese oodies and basil - 16 inch', 450, 'Pizza', true),
    (cafe_id, 'Veggie Feast (8")', 'Onion, capsicum & sweet corn - 8 inch', 200, 'Pizza', true),
    (cafe_id, 'Veggie Feast (11")', 'Onion, capsicum & sweet corn - 11 inch', 310, 'Pizza', true),
    (cafe_id, 'Veggie Feast (16")', 'Onion, capsicum & sweet corn - 16 inch', 500, 'Pizza', true),
    (cafe_id, 'Veggie Lover''s (8")', 'Onion, capsicum, tomato, sweet corn, jalapeno - 8 inch', 200, 'Pizza', true),
    (cafe_id, 'Veggie Lover''s (11")', 'Onion, capsicum, tomato, sweet corn, jalapeno - 11 inch', 350, 'Pizza', true),
    (cafe_id, 'Veggie Lover''s (16")', 'Onion, capsicum, tomato, sweet corn, jalapeno - 16 inch', 550, 'Pizza', true),
    (cafe_id, 'Toasted Paneer King Pizza (8")', 'Onion, capsicum, paneer, tomato, red paprika - 8 inch', 210, 'Pizza', true),
    (cafe_id, 'Toasted Paneer King Pizza (11")', 'Onion, capsicum, paneer, tomato, red paprika - 11 inch', 350, 'Pizza', true),
    (cafe_id, 'Toasted Paneer King Pizza (16")', 'Onion, capsicum, paneer, tomato, red paprika - 16 inch', 560, 'Pizza', true),
    (cafe_id, 'Classic Exotica (8")', 'Capsicum, red paprika, olive, baby corn, jalapeno - 8 inch', 220, 'Pizza', true),
    (cafe_id, 'Classic Exotica (11")', 'Capsicum, red paprika, olive, baby corn, jalapeno - 11 inch', 350, 'Pizza', true),
    (cafe_id, 'Classic Exotica (16")', 'Capsicum, red paprika, olive, baby corn, jalapeno - 16 inch', 550, 'Pizza', true),
    (cafe_id, 'Hawaiian Pizza (8")', 'Onion, capsicum, red paprika, pineapple/paneer, mushroom, jalapeno - 8 inch', 210, 'Pizza', true),
    (cafe_id, 'Hawaiian Pizza (11")', 'Onion, capsicum, red paprika, pineapple/paneer, mushroom, jalapeno - 11 inch', 360, 'Pizza', true),
    (cafe_id, 'Hawaiian Pizza (16")', 'Onion, capsicum, red paprika, pineapple/paneer, mushroom, jalapeno - 16 inch', 570, 'Pizza', true),
    (cafe_id, 'Tandoori Paneer (8")', 'Onion, capsicum, tomato, red paprika, paneer - 8 inch', 220, 'Pizza', true),
    (cafe_id, 'Tandoori Paneer (11")', 'Onion, capsicum, tomato, red paprika, paneer - 11 inch', 360, 'Pizza', true),
    (cafe_id, 'Tandoori Paneer (16")', 'Onion, capsicum, tomato, red paprika, paneer - 16 inch', 570, 'Pizza', true),
    (cafe_id, 'Special Makhni Pizza (8")', 'Makhni sauce, makhni paneer, onion, capsicum, tomato, red paprika - 8 inch', 210, 'Pizza', true),
    (cafe_id, 'Special Makhni Pizza (11")', 'Makhni sauce, makhni paneer, onion, capsicum, tomato, red paprika - 11 inch', 380, 'Pizza', true),
    (cafe_id, 'Special Makhni Pizza (16")', 'Makhni sauce, makhni paneer, onion, capsicum, tomato, red paprika - 16 inch', 580, 'Pizza', true),
    (cafe_id, 'White Green Pizza (8")', 'Ricotta cheese, garlic, spinach, olive - 8 inch', 220, 'Pizza', true),
    (cafe_id, 'White Green Pizza (11")', 'Ricotta cheese, garlic, spinach, olive - 11 inch', 400, 'Pizza', true),
    (cafe_id, 'White Green Pizza (16")', 'Ricotta cheese, garlic, spinach, olive - 16 inch', 580, 'Pizza', true),
    (cafe_id, 'Italian Veggie Loaded (8")', 'Onion, tomato, green, yellow & red capsicum, red paprika, sweet corn, paneer, black olives, mushroom - 8 inch', 230, 'Pizza', true),
    (cafe_id, 'Italian Veggie Loaded (11")', 'Onion, tomato, green, yellow & red capsicum, red paprika, sweet corn, paneer, black olives, mushroom - 11 inch', 400, 'Pizza', true),
    (cafe_id, 'Italian Veggie Loaded (16")', 'Onion, tomato, green, yellow & red capsicum, red paprika, sweet corn, paneer, black olives, mushroom - 16 inch', 600, 'Pizza', true),
    (cafe_id, 'Chicken & Spicy (8")', 'Onion, tomato, red paprika, chicken tikka - 8 inch', 230, 'Pizza', true),
    (cafe_id, 'Chicken & Spicy (11")', 'Onion, tomato, red paprika, chicken tikka - 11 inch', 380, 'Pizza', true),
    (cafe_id, 'Chicken & Spicy (16")', 'Onion, tomato, red paprika, chicken tikka - 16 inch', 590, 'Pizza', true),
    (cafe_id, 'Veggie & Chicken Loaded (8")', 'Chicken, capsicum, mushroom, red paprika - 8 inch', 240, 'Pizza', true),
    (cafe_id, 'Veggie & Chicken Loaded (11")', 'Chicken, capsicum, mushroom, red paprika - 11 inch', 400, 'Pizza', true),
    (cafe_id, 'Veggie & Chicken Loaded (16")', 'Chicken, capsicum, mushroom, red paprika - 16 inch', 600, 'Pizza', true),
    (cafe_id, 'Pepperoni Pizza (8")', 'Double pepperoni & cheese - 8 inch', 250, 'Pizza', true),
    (cafe_id, 'Pepperoni Pizza (11")', 'Double pepperoni & cheese - 11 inch', 400, 'Pizza', true),
    (cafe_id, 'Pepperoni Pizza (16")', 'Double pepperoni & cheese - 16 inch', 600, 'Pizza', true),
    (cafe_id, 'Chicken Over Loaded (8")', 'Fully loaded with meatball, chicken tikka, chicken salami - 8 inch', 270, 'Pizza', true),
    (cafe_id, 'Chicken Over Loaded (11")', 'Fully loaded with meatball, chicken tikka, chicken salami - 11 inch', 460, 'Pizza', true),
    (cafe_id, 'Chicken Over Loaded (16")', 'Fully loaded with meatball, chicken tikka, chicken salami - 16 inch', 690, 'Pizza', true),
    (cafe_id, 'Broccoli Chicken Pizza (8")', 'Double chicken, broccoli, tomato, provolone cheese, cheddar - 8 inch', 270, 'Pizza', true),
    (cafe_id, 'Broccoli Chicken Pizza (11")', 'Double chicken, broccoli, tomato, provolone cheese, cheddar - 11 inch', 460, 'Pizza', true),
    (cafe_id, 'Broccoli Chicken Pizza (16")', 'Double chicken, broccoli, tomato, provolone cheese, cheddar - 16 inch', 690, 'Pizza', true),
    (cafe_id, 'Italian Special Chicken Pizza (8")', 'Fully loaded with onion, meatball, chicken tikka, chicken salami, pepperoni, roasted red pepper, pea sauce, basil - 8 inch', 290, 'Pizza', true),
    (cafe_id, 'Italian Special Chicken Pizza (11")', 'Fully loaded with onion, meatball, chicken tikka, chicken salami, pepperoni, roasted red pepper, pea sauce, basil - 11 inch', 510, 'Pizza', true),
    (cafe_id, 'Italian Special Chicken Pizza (16")', 'Fully loaded with onion, meatball, chicken tikka, chicken salami, pepperoni, roasted red pepper, pea sauce, basil - 16 inch', 710, 'Pizza', true);

    -- UPGRADE TO ANY PIZZA
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Style Cheese Burst (8")', 'Process cheese, filler cheese, melted cheese, cheese cubes - 8 inch', 50, 'Pizza Upgrades', true),
    (cafe_id, 'Style Cheese Burst (11")', 'Process cheese, filler cheese, melted cheese, cheese cubes - 11 inch', 110, 'Pizza Upgrades', true),
    (cafe_id, 'Style Cheese Burst (16")', 'Process cheese, filler cheese, melted cheese, cheese cubes - 16 inch', 260, 'Pizza Upgrades', true);

    -- EXTRA ADD ONS
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Extra Cheese (8")', 'Additional cheese - 8 inch', 30, 'Pizza Add-ons', true),
    (cafe_id, 'Extra Cheese (11")', 'Additional cheese - 11 inch', 60, 'Pizza Add-ons', true),
    (cafe_id, 'Extra Cheese (16")', 'Additional cheese - 16 inch', 110, 'Pizza Add-ons', true),
    (cafe_id, 'Extra Chicken (8")', 'Additional chicken - 8 inch', 40, 'Pizza Add-ons', true),
    (cafe_id, 'Extra Chicken (11")', 'Additional chicken - 11 inch', 70, 'Pizza Add-ons', true),
    (cafe_id, 'Extra Chicken (16")', 'Additional chicken - 16 inch', 140, 'Pizza Add-ons', true);

    -- EXTRA TOPPINGS
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Extra Toppings (8")', 'Garlic/tomato/onion/capsicum/sweet corn/jalapenos/red paprika/mushroom/baby corn/black olives - 8 inch', 20, 'Pizza Toppings', true),
    (cafe_id, 'Extra Toppings (11")', 'Garlic/tomato/onion/capsicum/sweet corn/jalapenos/red paprika/mushroom/baby corn/black olives - 11 inch', 30, 'Pizza Toppings', true),
    (cafe_id, 'Extra Toppings (16")', 'Garlic/tomato/onion/capsicum/sweet corn/jalapenos/red paprika/mushroom/baby corn/black olives - 16 inch', 40, 'Pizza Toppings', true);

    -- SPECIAL-THICK SHAKES
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Vanilla Milkshake', 'Classic vanilla milkshake', 79, 'Thick Shakes', true),
    (cafe_id, 'Come Together Shake', 'Chocolate vanilla swirl ice cream', 99, 'Thick Shakes', true),
    (cafe_id, 'Cotton Candy Milk Shake', 'Vanilla ice cream with cotton candy flavor', 110, 'Thick Shakes', true),
    (cafe_id, 'Cotton Kitkat Milk Shake', 'Vanilla ice cream with cotton kitkat flavor', 110, 'Thick Shakes', true),
    (cafe_id, 'Chocolate Wasted Milk Shake', 'Chocolate ice cream with brownie bites and chocolate chips', 120, 'Thick Shakes', true),
    (cafe_id, 'Green Monster Milk Shake', 'Vanilla ice cream with oreo crumbs and mint chocolate chips', 130, 'Thick Shakes', true),
    (cafe_id, 'Nutella Heaven Milk Shake', 'Vanilla ice cream with nutella', 150, 'Thick Shakes', true),
    (cafe_id, 'Love'' Strawberry Milk Shake', 'Vanilla ice cream with strawberry sauce', 170, 'Thick Shakes', true);

    -- JUMBO SANDWICH
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Spicy Veggie Delight', 'Spicy vegetable sandwich', 99, 'Jumbo Sandwich', true),
    (cafe_id, 'Cheese Veggie Delight', 'Cheese vegetable sandwich', 120, 'Jumbo Sandwich', true),
    (cafe_id, 'Paneer Tikka Sandwich', 'Paneer tikka sandwich', 149, 'Jumbo Sandwich', true),
    (cafe_id, 'Chicken Tikka Sandwich', 'Chicken tikka sandwich', 149, 'Jumbo Sandwich', true),
    (cafe_id, 'Pepperoni Sandwich', 'Pepperoni sandwich', 160, 'Jumbo Sandwich', true),
    (cafe_id, 'Chicken Club Sandwich', 'Chicken club sandwich', 180, 'Jumbo Sandwich', true);

    -- PASTA
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Italian Red Sauce Pasta', 'Classic Italian red sauce pasta', 149, 'Pasta', true),
    (cafe_id, 'Garlic Mushroom Sauce Pasta', 'Garlic mushroom sauce pasta', 169, 'Pasta', true),
    (cafe_id, 'Creamy White Sauce Pasta', 'Creamy white sauce pasta', 169, 'Pasta', true),
    (cafe_id, 'Marinara Pink Sauce Pasta', 'Marinara pink sauce pasta', 179, 'Pasta', true),
    (cafe_id, 'Add Chicken to Pasta', 'Additional chicken for pasta', 50, 'Pasta Add-ons', true);

    -- CLASSIC BURGER
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veggie Aloo Tikki Burger', 'Vegetable aloo tikki burger', 60, 'Classic Burger', true),
    (cafe_id, 'Veggie Herb Patty Burger', 'Vegetable herb patty burger', 80, 'Classic Burger', true),
    (cafe_id, 'Masala Crunch Burger', 'Masala crunch burger', 90, 'Classic Burger', true),
    (cafe_id, 'Paneer Tikki Burger', 'Paneer tikki burger', 110, 'Classic Burger', true),
    (cafe_id, 'Grilled Chicken Burger', 'Grilled chicken burger', 110, 'Classic Burger', true),
    (cafe_id, 'Classic Cheese Burger', 'Classic cheese burger', 130, 'Classic Burger', true),
    (cafe_id, 'Double Cheese Burger', 'Double cheese burger', 140, 'Classic Burger', true);

    -- MOMOS (6 PCS)
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Mix Veg Steam Momos', 'Mixed vegetable steamed momos - 6 pieces', 100, 'Momos', true),
    (cafe_id, 'Mix Veg Fried Momos', 'Mixed vegetable fried momos - 6 pieces', 110, 'Momos', true),
    (cafe_id, 'Veg Schezwan Steam Momos', 'Vegetable schezwan steamed momos - 6 pieces', 110, 'Momos', true),
    (cafe_id, 'Veg Schezwan Fried Momos', 'Vegetable schezwan fried momos - 6 pieces', 120, 'Momos', true),
    (cafe_id, 'Simply Paneer Steam Momos', 'Paneer steamed momos - 6 pieces', 120, 'Momos', true),
    (cafe_id, 'Simply Paneer Fried Momos', 'Paneer fried momos - 6 pieces', 130, 'Momos', true),
    (cafe_id, 'Veg Momos - Peri Peri Steam', 'Vegetable peri peri steamed momos - 6 pieces', 120, 'Momos', true),
    (cafe_id, 'Veg Momos - Peri Peri Fried', 'Vegetable peri peri fried momos - 6 pieces', 130, 'Momos', true),
    (cafe_id, 'Tandoori Fried Momos', 'Tandoori fried momos - 6 pieces', 140, 'Momos', true),
    (cafe_id, 'Chicken Steam Momos', 'Chicken steamed momos - 6 pieces', 130, 'Momos', true),
    (cafe_id, 'Chicken Fried Momos', 'Chicken fried momos - 6 pieces', 140, 'Momos', true);

    -- MAGGI
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Yummy Plain Maggi', 'Plain maggi noodles', 69, 'Maggi', true),
    (cafe_id, 'Special Masala Maggi', 'Special masala maggi', 99, 'Maggi', true),
    (cafe_id, 'Veg Hot & Spicy Maggi', 'Vegetable hot and spicy maggi', 99, 'Maggi', true),
    (cafe_id, 'Veg Exotic Maggi', 'Paneer, cheese, peri peri double masala maggi', 120, 'Maggi', true),
    (cafe_id, 'Schezwan Maggi', 'Schezwan maggi', 120, 'Maggi', true),
    (cafe_id, 'Chilli Paneer Maggi', 'Chilli paneer maggi', 120, 'Maggi', true),
    (cafe_id, 'Milk Chilli Flakes Maggi', 'Milk chilli flakes maggi', 120, 'Maggi', true),
    (cafe_id, 'Cheese Corn Fried Maggi', 'Cheese corn fried maggi', 130, 'Maggi', true),
    (cafe_id, 'Cheese Oregano Maggi', 'Cheese oregano maggi', 149, 'Maggi', true),
    (cafe_id, 'Italian Chicken Spicy Maggi', 'Italian chicken spicy maggi', 199, 'Maggi', true);

    -- BIRYANI
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Biryani', 'Vegetable biryani', 120, 'Biryani', true),
    (cafe_id, 'Chicken Biryani', 'Chicken biryani', 160, 'Biryani', true);

    -- WRAP
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Aloo Tikki Wrap', 'Potato tikki wrap', 89, 'Wrap', true),
    (cafe_id, 'Herb Chilli Wrap', 'Herb chilli wrap', 99, 'Wrap', true),
    (cafe_id, 'Veggie Patty Wrap', 'Vegetable patty wrap', 99, 'Wrap', true),
    (cafe_id, 'Chilly Paneer Wrap', 'Chilli paneer wrap', 110, 'Wrap', true),
    (cafe_id, 'Paneer Tikka Wrap', 'Paneer tikka wrap', 120, 'Wrap', true),
    (cafe_id, 'Chicken Tikka Wrap', 'Chicken tikka wrap', 140, 'Wrap', true),
    (cafe_id, 'Crispy Chicken Wrap', 'Crispy chicken wrap', 150, 'Wrap', true),
    (cafe_id, 'Chicken Seekh Kabab Wrap', 'Chicken seekh kabab wrap', 160, 'Wrap', true);

    -- HOT BEVERAGES
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Hot Milk Tea', 'Hot milk tea', 25, 'Hot Beverages', true),
    (cafe_id, 'Black Tea', 'Black tea', 29, 'Hot Beverages', true),
    (cafe_id, 'Hot Chocolate Tea', 'Hot chocolate tea', 39, 'Hot Beverages', true),
    (cafe_id, 'Lemon Tea', 'Lemon tea', 39, 'Hot Beverages', true),
    (cafe_id, 'Green Tea', 'Green tea', 39, 'Hot Beverages', true),
    (cafe_id, 'Black Coffee', 'Black coffee', 39, 'Hot Beverages', true),
    (cafe_id, 'Hot Milk Coffee', 'Hot milk coffee', 49, 'Hot Beverages', true),
    (cafe_id, 'Hot Chocolate Coffee', 'Hot chocolate coffee', 69, 'Hot Beverages', true),
    (cafe_id, 'Cappuccino', 'Cappuccino', 79, 'Hot Beverages', true);

    -- COLD BEVERAGES
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Ice Tea', 'Iced tea', 49, 'Cold Beverages', true),
    (cafe_id, 'Lemon Iced Tea', 'Lemon iced tea', 79, 'Cold Beverages', true),
    (cafe_id, 'Virgin Mint Mojito', 'Virgin mint mojito', 79, 'Cold Beverages', true),
    (cafe_id, 'Blue Lagoon', 'Blue lagoon drink', 79, 'Cold Beverages', true),
    (cafe_id, 'Blue Berry Mojito', 'Blue berry mojito', 79, 'Cold Beverages', true),
    (cafe_id, 'Green Apple Mojito', 'Green apple mojito', 79, 'Cold Beverages', true),
    (cafe_id, 'Kala Khatta Mojito', 'Kala khatta mojito', 79, 'Cold Beverages', true),
    (cafe_id, 'Classic Cold Coffee', 'Classic cold coffee', 79, 'Cold Beverages', true),
    (cafe_id, 'Mint Chocolate', 'Mint chocolate drink', 110, 'Cold Beverages', true),
    (cafe_id, 'Vanilla Frappuccino', 'Mixture of cold coffee topped with ice cream choco chips', 130, 'Cold Beverages', true);

    RAISE NOTICE 'ITALIAN OVEN cafe and all menu items added successfully';
END $$;
