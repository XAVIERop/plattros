-- Add DIALOG cafe menu items based on the provided menu images
-- First, check if Dialog cafe exists, if not create it
DO $$
DECLARE
    dialog_cafe_id UUID;
BEGIN
    -- Check if Dialog cafe exists
    SELECT id INTO dialog_cafe_id FROM public.cafes WHERE name = 'Dialog';
    
    -- If cafe doesn't exist, create it
    IF dialog_cafe_id IS NULL THEN
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
            'Dialog',
            'Café & Multi-Cuisine',
            'Make It A Habit To Eat! A vibrant café offering specialty coffee, hand-toasted pizzas, burgers, subs, crispy toasties, and delicious desserts. From classic beverages to innovative food creations, we bring you the perfect blend of taste and comfort!',
            'B1 Ground Floor, GHS',
            '+91-98765 43210',
            '11:00 AM - 2:00 AM',
            true,
            NOW(),
            NOW()
        );
        
        -- Get the newly created cafe ID
        SELECT id INTO dialog_cafe_id FROM public.cafes WHERE name = 'Dialog';
    END IF;
    
    -- Clear existing menu items for Dialog
    DELETE FROM public.menu_items WHERE cafe_id = dialog_cafe_id;
    
    -- ========================================
    -- COFFEES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'Café Americano (Black Coffee)', 'Black Coffee', 90, 'Coffees', true),
    (dialog_cafe_id, 'Happiness (Is Cappuccino)', 'Prepared By Freshly Grounded Coffee Beans Imported From Malta', 130, 'Coffees', true),
    (dialog_cafe_id, 'Café Latte', 'Who Doesn''t Like A More Creamier Coffee With A Vanilla Shot In It!', 140, 'Coffees', true),
    (dialog_cafe_id, 'Café Mocha', 'Chocolaty Sibling Of Café Latte. Delicious', 140, 'Coffees', true),
    (dialog_cafe_id, 'Hazelnut Latte', 'Hazelnut Fusion With Freshly Grounded Coffee Beans', 140, 'Coffees', true),
    (dialog_cafe_id, 'Caramel Latte', 'Ye Coffee Hai Ya Toffee? Yum!', 140, 'Coffees', true);

    -- ========================================
    -- COLD BREWS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'Iced Americano (Cold Brew Coffee)', 'Cold Brew Coffee', 100, 'Cold Brews', true),
    (dialog_cafe_id, 'Ginger Ale Syrup', 'Cold Brew Coffee & Ginger Syrup mixed with Schweppe', 150, 'Cold Brews', true);

    -- ========================================
    -- HOT BEVERAGES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'Hot Chocolate', 'Hershey''s Cocoa Syrup Mixed With Warm Steamed Milk, Sprinkled With Chocolate Powder', 130, 'Hot Beverages', true),
    (dialog_cafe_id, 'Nutella Hot Chocolate', 'Nutella Lover''s Delight If You''re Looking For Something Warm Without Caffeine', 150, 'Hot Beverages', true);

    -- ========================================
    -- COLD COFFEES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'Café Dialog Frappe', 'Classic Cold Coffee & Sprinkled With Choco Chips', 100, 'Cold Coffees', true),
    (dialog_cafe_id, 'Irish Iced Frappe', 'Irish Iced Frappe', 120, 'Cold Coffees', true),
    (dialog_cafe_id, 'Dialog''s Dare Devil Frappe', 'Dark Chocolat''s Deadly Combination With Dark Roasted Coffee', 130, 'Cold Coffees', true),
    (dialog_cafe_id, 'Crunchy Caramel Frappe', 'A Toffee Iced Frappe To Drool Over & Over', 130, 'Cold Coffees', true),
    (dialog_cafe_id, 'Hazelnut Frappe', 'Hazelnut Infusion Into Freshly Brewed Coffee Shots Dripped Over Ice & A Whipped Cream Topping', 130, 'Cold Coffees', true),
    (dialog_cafe_id, 'Double Choco Chip Frappe', 'Chocolaty Sibling Of Chocolate Heaven Pleasure', 140, 'Cold Coffees', true);

    -- ========================================
    -- MILK SHAKES & SMOOTHIES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'Frozen Strawberry Margarita Delight', 'A Customary Yummy Strawberry Milk Shak', 100, 'Milk Shakes & Smoothies', true),
    (dialog_cafe_id, 'Chocolate Heaven Pleasure', 'A True Chocolate Lover''s Ecstasy', 120, 'Milk Shakes & Smoothies', true),
    (dialog_cafe_id, 'Toasted Marsh Mallow', 'Dialog''s Secret Recipe Ingredient Mixed Into Blender & Hand Gun Toasted Mars Mallows', 120, 'Milk Shakes & Smoothies', true),
    (dialog_cafe_id, 'Cadbury- Gems Meets Kit-Kat', 'When Your Childhood Crush Gems Take Nuptial Vows With Wafer Kitkat In Our Blender', 120, 'Milk Shakes & Smoothies', true),
    (dialog_cafe_id, 'No Cardio Only Oreo', 'Oreo Crushed With Chilled Milk & Chocolate Ice Cream', 120, 'Milk Shakes & Smoothies', true),
    (dialog_cafe_id, 'Strawberry Toasted Marsh Mallow', 'A Smooth Blend Of Crushed Fresh Strawberries Added To Toasted Marsh Mallow', 120, 'Milk Shakes & Smoothies', true),
    (dialog_cafe_id, 'Nutella Love Story', 'Instant Gratification Guaranteed. Highly Recommended', 140, 'Milk Shakes & Smoothies', true),
    (dialog_cafe_id, 'Mango Smoothie', 'It''s Made With Fresh Mango & Handful of Ingredients', 150, 'Milk Shakes & Smoothies', true),
    (dialog_cafe_id, 'Choco Lava Shake', 'It''s Made With choco lava', 160, 'Milk Shakes & Smoothies', true),
    (dialog_cafe_id, 'Ferrero Rocher Shake', 'Ferrero Rocher Shake', 170, 'Milk Shakes & Smoothies', true);

    -- ========================================
    -- HAND TOASTED PIZZAS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'Margherita (S 8")', 'An Old Country Original: Classic Cheese - Small 8 inch', 150, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Margherita (M 11")', 'An Old Country Original: Classic Cheese - Medium 11 inch', 290, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Margherita (L 16")', 'An Old Country Original: Classic Cheese - Large 16 inch', 480, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'C4 Margherita (S 8")', 'Extra Cheese on Cheese: Double Cheese - Small 8 inch', 200, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'C4 Margherita (M 11")', 'Extra Cheese on Cheese: Double Cheese - Medium 11 inch', 340, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'C4 Margherita (L 16")', 'Extra Cheese on Cheese: Double Cheese - Large 16 inch', 540, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, '3 Dimensions (S 8")', 'OTC Onion, Tomato, Capsicum / OTS Onion, Tomato, Sweet Corn / OTM Onion, Tomato, Mushroom - Small 8 inch', 220, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, '3 Dimensions (M 11")', 'OTC Onion, Tomato, Capsicum / OTS Onion, Tomato, Sweet Corn / OTM Onion, Tomato, Mushroom - Medium 11 inch', 350, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, '3 Dimensions (L 16")', 'OTC Onion, Tomato, Capsicum / OTS Onion, Tomato, Sweet Corn / OTM Onion, Tomato, Mushroom - Large 16 inch', 560, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'High-Five (S 8")', 'Onion, Capsicum, Mushroom, Tomato, Red Paprika - Small 8 inch', 220, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'High-Five (M 11")', 'Onion, Capsicum, Mushroom, Tomato, Red Paprika - Medium 11 inch', 370, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'High-Five (L 16")', 'Onion, Capsicum, Mushroom, Tomato, Red Paprika - Large 16 inch', 580, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Paneer King (S 8")', 'Onion, Capsicum, Paneer, Tomato, Red Paprika - Small 8 inch', 230, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Paneer King (M 11")', 'Onion, Capsicum, Paneer, Tomato, Red Paprika - Medium 11 inch', 390, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Paneer King (L 16")', 'Onion, Capsicum, Paneer, Tomato, Red Paprika - Large 16 inch', 610, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Exotica (S 8")', 'Red Paprika, Baby Corn, Green Capsicum, Black & Green Olives, Jalapeno - Small 8 inch', 240, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Exotica (M 11")', 'Red Paprika, Baby Corn, Green Capsicum, Black & Green Olives, Jalapeno - Medium 11 inch', 380, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Exotica (L 16")', 'Red Paprika, Baby Corn, Green Capsicum, Black & Green Olives, Jalapeno - Large 16 inch', 600, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Spicy Paneer (S 8")', 'Tandoori Spicy Paneer, Onion, Capsicum, Tomato, Red Paprika - Small 8 inch', 250, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Spicy Paneer (M 11")', 'Tandoori Spicy Paneer, Onion, Capsicum, Tomato, Red Paprika - Medium 11 inch', 410, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Spicy Paneer (L 16")', 'Tandoori Spicy Paneer, Onion, Capsicum, Tomato, Red Paprika - Large 16 inch', 630, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Paneer Makhni (S 8")', 'Makhni Sauce, Makhni Paneer, Onion, Capsicum, Tomato, Red Paprika - Small 8 inch', 250, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Paneer Makhni (M 11")', 'Makhni Sauce, Makhni Paneer, Onion, Capsicum, Tomato, Red Paprika - Medium 11 inch', 410, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Paneer Makhni (L 16")', 'Makhni Sauce, Makhni Paneer, Onion, Capsicum, Tomato, Red Paprika - Large 16 inch', 640, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Veggie Blast (S 8")', 'Red Capsicum, Yellow Capsicum, Black & Green Olives, Paneer, Mushroom, Onion, Tomotos, Sweet Corn, Red Paprika - Small 8 inch', 250, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Veggie Blast (M 11")', 'Red Capsicum, Yellow Capsicum, Black & Green Olives, Paneer, Mushroom, Onion, Tomotos, Sweet Corn, Red Paprika - Medium 11 inch', 410, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Veggie Blast (L 16")', 'Red Capsicum, Yellow Capsicum, Black & Green Olives, Paneer, Mushroom, Onion, Tomotos, Sweet Corn, Red Paprika - Large 16 inch', 610, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Chicken Tikka (S 8")', 'Chicken Tikka, Onion, Red Paprika, Tandoori Sauce - Small 8 inch', 250, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Chicken Tikka (M 11")', 'Chicken Tikka, Onion, Red Paprika, Tandoori Sauce - Medium 11 inch', 440, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Chicken Tikka (L 16")', 'Chicken Tikka, Onion, Red Paprika, Tandoori Sauce - Large 16 inch', 650, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Pindi Chole & Paneer (S 8")', 'Tandoori Spicy Paneer, Onion, Tomato, Red Paprika, Sweet Corn, Jalapeno - Small 8 inch', 250, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Pindi Chole & Paneer (M 11")', 'Tandoori Spicy Paneer, Onion, Tomato, Red Paprika, Sweet Corn, Jalapeno - Medium 11 inch', 460, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Pindi Chole & Paneer (L 16")', 'Tandoori Spicy Paneer, Onion, Tomato, Red Paprika, Sweet Corn, Jalapeno - Large 16 inch', 680, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Pindi Chole Chicken (S 8")', 'Bar-B-Que Chicken, Onion, Red Paprika, Sweet Corn, Jalapeno, Black Olives - Small 8 inch', 260, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Pindi Chole Chicken (M 11")', 'Bar-B-Que Chicken, Onion, Red Paprika, Sweet Corn, Jalapeno, Black Olives - Medium 11 inch', 460, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Pindi Chole Chicken (L 16")', 'Bar-B-Que Chicken, Onion, Red Paprika, Sweet Corn, Jalapeno, Black Olives - Large 16 inch', 660, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Panama Chicken (S 8")', 'Chicken, Capsicum, Mushroom, Red Paprika, Green Olives - Small 8 inch', 260, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Panama Chicken (M 11")', 'Chicken, Capsicum, Mushroom, Red Paprika, Green Olives - Medium 11 inch', 460, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Panama Chicken (L 16")', 'Chicken, Capsicum, Mushroom, Red Paprika, Green Olives - Large 16 inch', 660, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Chicken Pepperoni (S 8")', 'Chicken Pepperoni & Cheese, Red Paprika, Pizza Sauce - Small 8 inch', 270, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Chicken Pepperoni (M 11")', 'Chicken Pepperoni & Cheese, Red Paprika, Pizza Sauce - Medium 11 inch', 480, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Chicken Pepperoni (L 16")', 'Chicken Pepperoni & Cheese, Red Paprika, Pizza Sauce - Large 16 inch', 690, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Chicken Burst (S 8")', 'Chicken Tikka, Meatball, Salami, Spicy Chicken, Red Paprika, Onion - Small 8 inch', 290, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Chicken Burst (M 11")', 'Chicken Tikka, Meatball, Salami, Spicy Chicken, Red Paprika, Onion - Medium 11 inch', 510, 'Hand Toasted Pizzas', true),
    (dialog_cafe_id, 'Chicken Burst (L 16")', 'Chicken Tikka, Meatball, Salami, Spicy Chicken, Red Paprika, Onion - Large 16 inch', 760, 'Hand Toasted Pizzas', true);

    -- ========================================
    -- UPGRADE ANY PIZZA TO
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'C4 Cheesilicious Pizza (S 8")', 'Dialog''s Melted Cheese & Filler Cheese - Small 8 inch', 20, 'Pizza Upgrades', true),
    (dialog_cafe_id, 'C4 Cheesilicious Pizza (M 11")', 'Dialog''s Melted Cheese & Filler Cheese - Medium 11 inch', 40, 'Pizza Upgrades', true),
    (dialog_cafe_id, 'C4 Cheesilicious Pizza (L 16")', 'Dialog''s Melted Cheese & Filler Cheese - Large 16 inch', 50, 'Pizza Upgrades', true),
    (dialog_cafe_id, 'Cheese Burst Pizza (S 8")', 'Process Cheese, Filler Cheese, Dialog''s Melted Cheese, Cheese Cubes - Small 8 inch', 70, 'Pizza Upgrades', true),
    (dialog_cafe_id, 'Cheese Burst Pizza (M 11")', 'Process Cheese, Filler Cheese, Dialog''s Melted Cheese, Cheese Cubes - Medium 11 inch', 150, 'Pizza Upgrades', true),
    (dialog_cafe_id, 'Cheese Burst Pizza (L 16")', 'Process Cheese, Filler Cheese, Dialog''s Melted Cheese, Cheese Cubes - Large 16 inch', 300, 'Pizza Upgrades', true);

    -- ========================================
    -- ADD ONS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'Extra Topping (S 8")', 'Onion / Capsicum / Sweet Corn / Jalapenos / Red Paprika / Mushroom / Baby Corn / Black Olives - Small 8 inch', 30, 'Add Ons', true),
    (dialog_cafe_id, 'Extra Topping (M 11")', 'Onion / Capsicum / Sweet Corn / Jalapenos / Red Paprika / Mushroom / Baby Corn / Black Olives - Medium 11 inch', 50, 'Add Ons', true),
    (dialog_cafe_id, 'Extra Topping (L 16")', 'Onion / Capsicum / Sweet Corn / Jalapenos / Red Paprika / Mushroom / Baby Corn / Black Olives - Large 16 inch', 80, 'Add Ons', true),
    (dialog_cafe_id, 'Extra Cheese (S 8")', 'Extra Cheese - Small 8 inch', 40, 'Add Ons', true),
    (dialog_cafe_id, 'Extra Cheese (M 11")', 'Extra Cheese - Medium 11 inch', 80, 'Add Ons', true),
    (dialog_cafe_id, 'Extra Cheese (L 16")', 'Extra Cheese - Large 16 inch', 100, 'Add Ons', true);

    -- ========================================
    -- CRISPY TOASTIES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'Cheese Garlic Bread', 'Cheese Garlic Bread', 110, 'Crispy Toasties', true),
    (dialog_cafe_id, 'Cheese Garlic Bread Sticks', 'Cheese Garlic Bread Sticks', 140, 'Crispy Toasties', true);

    -- ========================================
    -- SUBS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'Aloo ki Adaa (Potato Patty Filoling)', 'Potato Patty Filoling', 120, 'Subs', true),
    (dialog_cafe_id, 'Spicy Veggie Delight (All Veggies, Without Any Patty)', 'All Veggies, Without Any Patty', 130, 'Subs', true),
    (dialog_cafe_id, 'Hanging Green (Includes Veggie Patty)', 'Includes Veggie Patty', 140, 'Subs', true),
    (dialog_cafe_id, 'Paneer Tikka (Paneer Marinated in Spices & Grilled in a Tandoor)', 'Paneer Marinated in Spices & Grilled in a Tandoor', 170, 'Subs', true),
    (dialog_cafe_id, 'Chicken Tikka (Marinated & Tandoor Grilled Chicken)', 'Marinated & Tandoor Grilled Chicken', 170, 'Subs', true),
    (dialog_cafe_id, 'Chicken Seekh (Seekh Kebabs Filling Which Melts In the Mouth Chicken Minee mixed with onions & Spices)', 'Seekh Kebabs Filling Which Melts In the Mouth Chicken Minee mixed with onions & Spices', 170, 'Subs', true);

    -- ========================================
    -- BURGERS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'Aloo Tikki Burger', 'Aloo Tikki Burger', 60, 'Burgers', true),
    (dialog_cafe_id, 'Mc Veggie Burger', 'Mc Veggie Burger', 70, 'Burgers', true),
    (dialog_cafe_id, 'Super Freak Burger', 'Super Freak Burger', 80, 'Burgers', true),
    (dialog_cafe_id, 'Go Green Burger', 'Go Green Burger', 90, 'Burgers', true),
    (dialog_cafe_id, 'Masala Aloo Tikki Burger', 'Masala Aloo Tikki Burger', 90, 'Burgers', true),
    (dialog_cafe_id, 'Crispy Chicken Burger', 'Crispy Chicken Burger', 90, 'Burgers', true),
    (dialog_cafe_id, 'Achari Chicken Burger', 'Achari Chicken Burger', 90, 'Burgers', true),
    (dialog_cafe_id, 'Grilled Chicken Burger', 'Grilled Chicken Burger', 100, 'Burgers', true),
    (dialog_cafe_id, 'Crumby Chicken Burger', 'Crumby Chicken Burger', 100, 'Burgers', true),
    (dialog_cafe_id, 'Peri Peri Paneer Patty', 'Peri Peri Paneer Patty', 110, 'Burgers', true),
    (dialog_cafe_id, 'Cheese Burger', 'Cheese Burger', 110, 'Burgers', true),
    (dialog_cafe_id, 'Double Cheese Burger', 'Double Cheese Burger', 130, 'Burgers', true);

    -- ========================================
    -- DESSERTS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'Choco Lava Cake', 'Choco Lava Cake', 90, 'Desserts', true),
    (dialog_cafe_id, 'Choco Lava Cake With Vanilla Ice-Cream', 'Choco Lava Cake With Vanilla Ice-Cream', 120, 'Desserts', true),
    (dialog_cafe_id, 'Blue Berry Cheese Cake', 'Blue Berry Cheese Cake', 180, 'Desserts', true),
    (dialog_cafe_id, 'Biscoff Cheese Cake', 'Biscoff Cheese Cake', 200, 'Desserts', true);

    -- ========================================
    -- MOJITO - VOHITO
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'Virgin Mint Mojito', 'Virgin Mint Mojito', 100, 'Mojito - Vohito', true),
    (dialog_cafe_id, 'Green Apple Mojito', 'Green Apple Mojito', 100, 'Mojito - Vohito', true),
    (dialog_cafe_id, 'Cranberry Mojito', 'Cranberry Mojito', 100, 'Mojito - Vohito', true),
    (dialog_cafe_id, 'Black Magic', 'Black Magic', 100, 'Mojito - Vohito', true),
    (dialog_cafe_id, 'Bubblegum Mojito', 'Bubblegum Mojito', 100, 'Mojito - Vohito', true),
    (dialog_cafe_id, 'Blue Curaso Mojito', 'Blue Curaso Mojito', 100, 'Mojito - Vohito', true),
    (dialog_cafe_id, 'Kiwi Mojito', 'Kiwi Mojito', 120, 'Mojito - Vohito', true),
    (dialog_cafe_id, 'Water Melon Mojito', 'Water Melon Mojito', 120, 'Mojito - Vohito', true);

    -- ========================================
    -- ICED TEAS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'Lemon-Mint Iced Tea (Beloved Refreshing Drink Always)', 'Beloved Refreshing Drink Always', 110, 'Iced Teas', true),
    (dialog_cafe_id, 'Sparkling Peach Iced Tea (Peach Infused Tea Served On The Rocks Along With Crushed Peach Fruit)', 'Peach Infused Tea Served On The Rocks Along With Crushed Peach Fruit', 110, 'Iced Teas', true),
    (dialog_cafe_id, 'Water Melon Iced Tea', 'Water Melon Iced Tea', 130, 'Iced Teas', true);

    -- ========================================
    -- SIDES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'French Fries', 'French Fries', 120, 'Sides', true),
    (dialog_cafe_id, 'Chicken Nuggets (6 pcs)', 'Chicken Nuggets - 6 pieces', 130, 'Sides', true),
    (dialog_cafe_id, 'Peri-Peri Fries', 'Peri-Peri Fries', 140, 'Sides', true),
    (dialog_cafe_id, 'Masala Fries', 'Masala Fries', 150, 'Sides', true),
    (dialog_cafe_id, 'Dialog''s Chicken Bucket', 'Dialog''s Chicken Bucket', 520, 'Sides', true);

    -- ========================================
    -- PASTAS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'Penne Alfredo (Penne Tossed with White Sauce & Garden Vegetables)', 'Penne Tossed with White Sauce & Garden Vegetables', 170, 'Pastas', true),
    (dialog_cafe_id, 'Penne Arrabiata (Penne Tossed with Spicy Red Tomato Sauce & Garden Vegetables)', 'Penne Tossed with Spicy Red Tomato Sauce & Garden Vegetables', 170, 'Pastas', true),
    (dialog_cafe_id, 'Basil Pesto', 'Basil Pesto', 180, 'Pastas', true),
    (dialog_cafe_id, 'Pink Sauce Pasta', 'Pink Sauce Pasta', 190, 'Pastas', true),
    (dialog_cafe_id, 'Mushroom Sauce Pasta', 'Mushroom Sauce Pasta', 190, 'Pastas', true),
    (dialog_cafe_id, 'Makhni Sauce Pasta', 'Makhni Sauce Pasta', 190, 'Pastas', true),
    (dialog_cafe_id, 'Oven Baked Pasta (Alfredo / Arrabiata / Makhni / Pink)', 'Oven Baked Pasta - Alfredo / Arrabiata / Makhni / Pink', 210, 'Pastas', true);

    -- ========================================
    -- PASTA ADD-ONS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (dialog_cafe_id, 'Add Peri-Peri Masala', 'Add Peri-Peri Masala', 10, 'Pasta Add-ons', true),
    (dialog_cafe_id, 'Add Chicken', 'Add Chicken', 60, 'Pasta Add-ons', true);

    RAISE NOTICE 'Dialog cafe menu successfully added/updated with % menu items', (SELECT COUNT(*) FROM public.menu_items WHERE cafe_id = dialog_cafe_id);
END $$;
