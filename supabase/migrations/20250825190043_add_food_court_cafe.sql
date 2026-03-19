-- Add FOOD COURT cafe with 4 brands (KRISPP, GOBBLERS, Momo Street, WAFFLES & MORE)
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
    'FOOD COURT',
    'Multi-Brand',
    'A culinary destination featuring 4 amazing brands under one roof: KRISPP for crispy delights, GOBBLERS for wholesome bowls and wraps, Momo Street for authentic momos, and WAFFLES & MORE for sweet treats. From savory to sweet, we have everything you crave!',
    'G1 Ground Floor',
    '+91-98765 43210',
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
    SELECT id INTO cafe_id FROM public.cafes WHERE name = 'FOOD COURT';
    
    -- ========================================
    -- KRISPP BRAND MENU
    -- ========================================
    
    -- KRISPPY NON-VEG (6 pcs)
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Chicken Hot Wings (6 pcs)', 'Spicy hot chicken wings - 6 pieces', 239, 'KRISPP - Non-Veg', true),
    (cafe_id, 'Chicken Strips (6 pcs)', 'Crispy chicken strips - 6 pieces', 229, 'KRISPP - Non-Veg', true),
    (cafe_id, 'Garlic Chicken Fingers (6 pcs)', 'Garlic-flavored chicken fingers - 6 pieces', 159, 'KRISPP - Non-Veg', true),
    (cafe_id, 'Fish Fingers (6 pcs)', 'Crispy fish fingers - 6 pieces', 249, 'KRISPP - Non-Veg', true),
    (cafe_id, 'Golden Prawns (6 pcs)', 'Golden fried prawns - 6 pieces', 249, 'KRISPP - Non-Veg', true);

    -- KRISPPY VEG (6 pcs)
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Pizza Pockets (6 pcs)', 'Crispy pizza pockets - 6 pieces', 149, 'KRISPP - Veg', true),
    (cafe_id, 'Veg Strips (6 pcs)', 'Vegetable strips - 6 pieces', 119, 'KRISPP - Veg', true),
    (cafe_id, 'Cheesy Strips (6 pcs)', 'Cheese-filled strips - 6 pieces', 129, 'KRISPP - Veg', true),
    (cafe_id, 'Onion Rings (6 pcs)', 'Crispy onion rings - 6 pieces', 129, 'KRISPP - Veg', true),
    (cafe_id, 'Jalapeno Poppers (6 pcs)', 'Spicy jalapeno poppers - 6 pieces', 119, 'KRISPP - Veg', true);

    -- KRISPP SNACKS
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Chilli Garlic Potato', 'Spicy chilli garlic potatoes', 109, 'KRISPP - Snacks', true),
    (cafe_id, 'Chicken Popcorn', 'Crispy chicken popcorn', 119, 'KRISPP - Snacks', true),
    (cafe_id, 'Corn Cheese Nuggets', 'Corn and cheese nuggets', 119, 'KRISPP - Snacks', true),
    (cafe_id, 'Chicken Nuggets', 'Crispy chicken nuggets', 129, 'KRISPP - Snacks', true),
    (cafe_id, 'Masala French Fries', 'Spiced masala french fries', 99, 'KRISPP - Snacks', true),
    (cafe_id, 'Chicken French Fries', 'Chicken-topped french fries', 109, 'KRISPP - Snacks', true);

    -- KRISPP BURGER
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Classic Veg Burger', 'Classic vegetable burger', 89, 'KRISPP - Burger', true),
    (cafe_id, 'Classic Chicken Burger', 'Classic chicken burger', 99, 'KRISPP - Burger', true),
    (cafe_id, 'Krisppy Paneer Burger', 'Crispy paneer burger', 129, 'KRISPP - Burger', true),
    (cafe_id, 'Krisppy Chicken Burger', 'Crispy chicken burger', 139, 'KRISPP - Burger', true),
    (cafe_id, 'Krisppy Fish Burger', 'Crispy fish burger', 149, 'KRISPP - Burger', true);

    -- KRISPP BEVERAGES
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Masala Lemonade', 'Spiced masala lemonade', 79, 'KRISPP - Beverages', true),
    (cafe_id, 'Cola Lemonade', 'Cola-flavored lemonade', 79, 'KRISPP - Beverages', true),
    (cafe_id, 'Virgin Mojito', 'Refreshing virgin mojito', 89, 'KRISPP - Beverages', true),
    (cafe_id, 'Cucumber Mojito', 'Cool cucumber mojito', 89, 'KRISPP - Beverages', true),
    (cafe_id, 'Watermelon Mojito', 'Fresh watermelon mojito', 89, 'KRISPP - Beverages', true),
    (cafe_id, 'Green Apple Mojito', 'Tangy green apple mojito', 89, 'KRISPP - Beverages', true),
    (cafe_id, 'Blue Magic Mojito', 'Magical blue mojito', 89, 'KRISPP - Beverages', true);

    -- KRISPP MEAL UPGRADES
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Meal Upgrade', 'Chilli Garlic Potato + Any Beverage', 149, 'KRISPP - Meal Upgrades', true),
    (cafe_id, 'Non-Veg Meal Upgrade', 'Chicken Popcorn + Any Beverage', 159, 'KRISPP - Meal Upgrades', true);

    -- ========================================
    -- GOBBLERS BRAND MENU
    -- ========================================
    
    -- GOBBLERS BOWLS
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Khichdi Bowl', 'Traditional khichdi bowl', 149, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Rajma - Rice Bowl', 'Rajma with rice bowl', 179, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Dilli Chola - Rice Bowl', 'Delhi-style chole with rice bowl', 179, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Dal Makhni - Rice Bowl', 'Creamy dal makhni with rice bowl', 179, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Makhni - Rice Bowl (Paneer)', 'Makhni paneer with rice bowl', 199, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Makhni - Rice Bowl (Chicken)', 'Makhni chicken with rice bowl', 199, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Makhni - Rice Bowl (Prawns)', 'Makhni prawns with rice bowl', 199, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Lahori - Rice Bowl (Paneer)', 'Lahori paneer with rice bowl', 199, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Lahori - Rice Bowl (Chicken)', 'Lahori chicken with rice bowl', 199, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Lahori - Rice Bowl (Prawns)', 'Lahori prawns with rice bowl', 199, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Chinese - Rice Bowl (Paneer)', 'Chinese paneer with rice bowl', 199, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Chinese - Rice Bowl (Chicken)', 'Chinese chicken with rice bowl', 199, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Chinese - Rice Bowl (Prawns)', 'Chinese prawns with rice bowl', 199, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Biryani Bowl (Paneer)', 'Paneer biryani bowl', 209, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Biryani Bowl (Chicken)', 'Chicken biryani bowl', 209, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Biryani Bowl (Prawns)', 'Prawns biryani bowl', 209, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Red Sauce Pasta Bowl', 'Red sauce pasta bowl', 169, 'GOBBLERS - Bowls', true),
    (cafe_id, 'White Sauce Pasta Bowl', 'White sauce pasta bowl', 169, 'GOBBLERS - Bowls', true),
    (cafe_id, 'Mix Sauce Pasta Bowl', 'Mixed sauce pasta bowl', 169, 'GOBBLERS - Bowls', true),
    (cafe_id, 'ADD ON - Chicken', 'Additional chicken for bowls', 69, 'GOBBLERS - Bowls', true),
    (cafe_id, 'ADD ON - Prawns', 'Additional prawns for bowls', 69, 'GOBBLERS - Bowls', true);

    -- GOBBLERS WRAPS
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Wrap', 'Vegetable wrap', 89, 'GOBBLERS - Wraps', true),
    (cafe_id, 'Paneer Wrap', 'Paneer wrap', 99, 'GOBBLERS - Wraps', true),
    (cafe_id, 'Chicken Wrap', 'Chicken wrap', 99, 'GOBBLERS - Wraps', true),
    (cafe_id, 'Makhni Wrap (Paneer)', 'Makhni paneer wrap', 119, 'GOBBLERS - Wraps', true),
    (cafe_id, 'Makhni Wrap (Chicken)', 'Makhni chicken wrap', 119, 'GOBBLERS - Wraps', true),
    (cafe_id, 'Makhni Wrap (Prawns)', 'Makhni prawns wrap', 119, 'GOBBLERS - Wraps', true),
    (cafe_id, 'Lahori Wrap (Paneer)', 'Lahori paneer wrap', 119, 'GOBBLERS - Wraps', true),
    (cafe_id, 'Lahori Wrap (Chicken)', 'Lahori chicken wrap', 119, 'GOBBLERS - Wraps', true),
    (cafe_id, 'Lahori Wrap (Prawns)', 'Lahori prawns wrap', 119, 'GOBBLERS - Wraps', true),
    (cafe_id, 'Schezwan Wrap (Paneer)', 'Schezwan paneer wrap', 119, 'GOBBLERS - Wraps', true),
    (cafe_id, 'Schezwan Wrap (Chicken)', 'Schezwan chicken wrap', 119, 'GOBBLERS - Wraps', true),
    (cafe_id, 'Schezwan Wrap (Prawns)', 'Schezwan prawns wrap', 119, 'GOBBLERS - Wraps', true);

    -- GOBBLERS BEVERAGES
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Masala Lemonade', 'Spiced masala lemonade', 79, 'GOBBLERS - Beverages', true),
    (cafe_id, 'Cola Lemonade', 'Cola-flavored lemonade', 79, 'GOBBLERS - Beverages', true),
    (cafe_id, 'Virgin Mojito', 'Refreshing virgin mojito', 89, 'GOBBLERS - Beverages', true),
    (cafe_id, 'Cucumber Mojito', 'Cool cucumber mojito', 89, 'GOBBLERS - Beverages', true),
    (cafe_id, 'Watermelon Mojito', 'Fresh watermelon mojito', 89, 'GOBBLERS - Beverages', true),
    (cafe_id, 'Green Apple Mojito', 'Tangy green apple mojito', 89, 'GOBBLERS - Beverages', true),
    (cafe_id, 'Blue Magic Mojito', 'Magical blue mojito', 89, 'GOBBLERS - Beverages', true);

    -- GOBBLERS STARTERS (6 PCS)
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Hara - Bhara Kebab (6 pcs)', 'Green herb kebabs - 6 pieces', 139, 'GOBBLERS - Starters', true),
    (cafe_id, 'Dahi Ke Kebab (6 pcs)', 'Yogurt-based kebabs - 6 pieces', 139, 'GOBBLERS - Starters', true),
    (cafe_id, 'Corn Cheese Kebab (6 pcs)', 'Corn and cheese kebabs - 6 pieces', 149, 'GOBBLERS - Starters', true),
    (cafe_id, 'Chicken Cheese Kebab (6 pcs)', 'Chicken and cheese kebabs - 6 pieces', 149, 'GOBBLERS - Starters', true);

    -- ========================================
    -- MOMO STREET BRAND MENU
    -- ========================================
    
    -- MOMO STREET STEAMED MOMOS (6 PCS)
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veggie Momos (6 pcs)', 'Steamed vegetable momos - 6 pieces', 89, 'MOMO STREET - Steamed', true),
    (cafe_id, 'Paneer Momos (6 pcs)', 'Steamed paneer momos - 6 pieces', 99, 'MOMO STREET - Steamed', true),
    (cafe_id, 'Corn & Cheese Momos (6 pcs)', 'Steamed corn and cheese momos - 6 pieces', 99, 'MOMO STREET - Steamed', true),
    (cafe_id, 'Chicken Momos (6 pcs)', 'Steamed chicken momos - 6 pieces', 99, 'MOMO STREET - Steamed', true),
    (cafe_id, 'Chicken & Cheese Momos (6 pcs)', 'Steamed chicken and cheese momos - 6 pieces', 109, 'MOMO STREET - Steamed', true),
    (cafe_id, 'Spicy Chicken Momos (6 pcs)', 'Steamed spicy chicken momos - 6 pieces', 109, 'MOMO STREET - Steamed', true);

    -- MOMO STREET FRIED MOMOS (6 PCS)
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veggie Fried Momos (6 pcs)', 'Fried vegetable momos - 6 pieces', 99, 'MOMO STREET - Fried', true),
    (cafe_id, 'Paneer Fried Momos (6 pcs)', 'Fried paneer momos - 6 pieces', 109, 'MOMO STREET - Fried', true),
    (cafe_id, 'Corn & Cheese Fried Momos (6 pcs)', 'Fried corn and cheese momos - 6 pieces', 109, 'MOMO STREET - Fried', true),
    (cafe_id, 'Chicken Fried Momos (6 pcs)', 'Fried chicken momos - 6 pieces', 109, 'MOMO STREET - Fried', true),
    (cafe_id, 'Chicken & Cheese Fried Momos (6 pcs)', 'Fried chicken and cheese momos - 6 pieces', 119, 'MOMO STREET - Fried', true),
    (cafe_id, 'Spicy Chicken Fried Momos (6 pcs)', 'Fried spicy chicken momos - 6 pieces', 119, 'MOMO STREET - Fried', true);

    -- MOMO STREET KURKURE MOMOS (6 PCS)
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veggie Kurkure Momos (6 pcs)', 'Kurkure-style vegetable momos - 6 pieces', 109, 'MOMO STREET - Kurkure', true),
    (cafe_id, 'Paneer Kurkure Momos (6 pcs)', 'Kurkure-style paneer momos - 6 pieces', 119, 'MOMO STREET - Kurkure', true),
    (cafe_id, 'Corn & Cheese Kurkure Momos (6 pcs)', 'Kurkure-style corn and cheese momos - 6 pieces', 119, 'MOMO STREET - Kurkure', true),
    (cafe_id, 'Chicken Kurkure Momos (6 pcs)', 'Kurkure-style chicken momos - 6 pieces', 119, 'MOMO STREET - Kurkure', true),
    (cafe_id, 'Chicken & Cheese Kurkure Momos (6 pcs)', 'Kurkure-style chicken and cheese momos - 6 pieces', 129, 'MOMO STREET - Kurkure', true),
    (cafe_id, 'Spicy Chicken Kurkure Momos (6 pcs)', 'Kurkure-style spicy chicken momos - 6 pieces', 129, 'MOMO STREET - Kurkure', true);

    -- MOMO STREET GRAVY MOMOS (6 PCS)
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veggie Momos - Makhni Gravy (6 pcs)', 'Veggie momos in makhni gravy - 6 pieces', 129, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Veggie Momos - Lahori Gravy (6 pcs)', 'Veggie momos in lahori gravy - 6 pieces', 129, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Veggie Momos - Schezwan Gravy (6 pcs)', 'Veggie momos in schezwan gravy - 6 pieces', 129, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Paneer Momos - Makhni Gravy (6 pcs)', 'Paneer momos in makhni gravy - 6 pieces', 139, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Paneer Momos - Lahori Gravy (6 pcs)', 'Paneer momos in lahori gravy - 6 pieces', 139, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Paneer Momos - Schezwan Gravy (6 pcs)', 'Paneer momos in schezwan gravy - 6 pieces', 139, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Corn & Cheese Momos - Makhni Gravy (6 pcs)', 'Corn & cheese momos in makhni gravy - 6 pieces', 139, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Corn & Cheese Momos - Lahori Gravy (6 pcs)', 'Corn & cheese momos in lahori gravy - 6 pieces', 139, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Corn & Cheese Momos - Schezwan Gravy (6 pcs)', 'Corn & cheese momos in schezwan gravy - 6 pieces', 139, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Chicken Momos - Makhni Gravy (6 pcs)', 'Chicken momos in makhni gravy - 6 pieces', 139, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Chicken Momos - Lahori Gravy (6 pcs)', 'Chicken momos in lahori gravy - 6 pieces', 139, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Chicken Momos - Schezwan Gravy (6 pcs)', 'Chicken momos in schezwan gravy - 6 pieces', 139, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Chicken & Cheese Momos - Makhni Gravy (6 pcs)', 'Chicken & cheese momos in makhni gravy - 6 pieces', 149, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Chicken & Cheese Momos - Lahori Gravy (6 pcs)', 'Chicken & cheese momos in lahori gravy - 6 pieces', 149, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Chicken & Cheese Momos - Schezwan Gravy (6 pcs)', 'Chicken & cheese momos in schezwan gravy - 6 pieces', 149, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Spicy Chicken Momos - Makhni Gravy (6 pcs)', 'Spicy chicken momos in makhni gravy - 6 pieces', 149, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Spicy Chicken Momos - Lahori Gravy (6 pcs)', 'Spicy chicken momos in lahori gravy - 6 pieces', 149, 'MOMO STREET - Gravy', true),
    (cafe_id, 'Spicy Chicken Momos - Schezwan Gravy (6 pcs)', 'Spicy chicken momos in schezwan gravy - 6 pieces', 149, 'MOMO STREET - Gravy', true);

    -- MOMO STREET STARTERS (6 PCS)
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Dosa Spring Roll (6 pcs)', 'Dosa-style spring rolls - 6 pieces', 129, 'MOMO STREET - Starters', true),
    (cafe_id, 'Veggie Spring Roll (6 pcs)', 'Vegetable spring rolls - 6 pieces', 129, 'MOMO STREET - Starters', true),
    (cafe_id, 'Chicken Spring Roll (6 pcs)', 'Chicken spring rolls - 6 pieces', 149, 'MOMO STREET - Starters', true),
    (cafe_id, 'Corn & Cheese Nuggets (6 pcs)', 'Corn and cheese nuggets - 6 pieces', 119, 'MOMO STREET - Starters', true),
    (cafe_id, 'Chicken Nuggets (6 pcs)', 'Chicken nuggets - 6 pieces', 129, 'MOMO STREET - Starters', true);

    -- MOMO STREET BEVERAGES
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Masala Lemonade', 'Spiced masala lemonade', 79, 'MOMO STREET - Beverages', true),
    (cafe_id, 'Cola Lemonade', 'Cola-flavored lemonade', 79, 'MOMO STREET - Beverages', true),
    (cafe_id, 'Virgin Mojito', 'Refreshing virgin mojito', 89, 'MOMO STREET - Beverages', true),
    (cafe_id, 'Cucumber Mojito', 'Cool cucumber mojito', 89, 'MOMO STREET - Beverages', true),
    (cafe_id, 'Watermelon Mojito', 'Fresh watermelon mojito', 89, 'MOMO STREET - Beverages', true),
    (cafe_id, 'Green Apple Mojito', 'Tangy green apple mojito', 89, 'MOMO STREET - Beverages', true),
    (cafe_id, 'Blue Magic Mojito', 'Magical blue mojito', 89, 'MOMO STREET - Beverages', true);

    -- ========================================
    -- WAFFLES & MORE BRAND MENU
    -- ========================================
    
    -- WAFFLES & MORE CLASSIC WAFFLES
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Honey Butter Waffle', 'Classic honey butter waffle served with ice-cream', 90, 'WAFFLES & MORE - Classic', true),
    (cafe_id, 'Maple Butter Waffle', 'Classic maple butter waffle served with ice-cream', 90, 'WAFFLES & MORE - Classic', true),
    (cafe_id, 'Roasted Almond Cocoa Waffle', 'Roasted almond cocoa waffle served with ice-cream', 130, 'WAFFLES & MORE - Classic', true),
    (cafe_id, 'Butterscotch Crunch Waffle', 'Butterscotch crunch waffle served with ice-cream', 130, 'WAFFLES & MORE - Classic', true),
    (cafe_id, 'Coffee Mocha Waffle', 'Coffee mocha waffle served with ice-cream', 130, 'WAFFLES & MORE - Classic', true),
    (cafe_id, 'Orange Zest Waffle', 'Orange zest waffle served with ice-cream', 130, 'WAFFLES & MORE - Classic', true),
    (cafe_id, 'Golden Caramel Waffle', 'Golden caramel waffle served with ice-cream', 130, 'WAFFLES & MORE - Classic', true),
    (cafe_id, 'Coconut Cream Waffle', 'Coconut cream waffle served with ice-cream', 130, 'WAFFLES & MORE - Classic', true);

    -- WAFFLES & MORE PREMIUM WAFFLES
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Belgian Chocolate Waffle (Milk)', 'Belgian milk chocolate waffle served with ice-cream', 140, 'WAFFLES & MORE - Premium', true),
    (cafe_id, 'Belgian Chocolate Waffle (Dark)', 'Belgian dark chocolate waffle served with ice-cream', 140, 'WAFFLES & MORE - Premium', true),
    (cafe_id, 'Nutella Waffle', 'Nutella waffle served with ice-cream', 160, 'WAFFLES & MORE - Premium', true),
    (cafe_id, 'Hazelnut Bliss Waffle', 'Hazelnut bliss waffle served with ice-cream', 160, 'WAFFLES & MORE - Premium', true),
    (cafe_id, 'Kit-Kat Waffle', 'Kit-Kat waffle served with ice-cream', 140, 'WAFFLES & MORE - Premium', true),
    (cafe_id, 'Oreo Dream Waffle', 'Oreo dream waffle served with ice-cream', 140, 'WAFFLES & MORE - Premium', true),
    (cafe_id, 'Tiramisu Waffle', 'Tiramisu waffle served with ice-cream', 160, 'WAFFLES & MORE - Premium', true),
    (cafe_id, 'Strawberry White Chocolate Waffle', 'Strawberry white chocolate waffle served with ice-cream', 150, 'WAFFLES & MORE - Premium', true),
    (cafe_id, 'Blueberry White Chocolate Waffle', 'Blueberry white chocolate waffle served with ice-cream', 150, 'WAFFLES & MORE - Premium', true);

    -- WAFFLES & MORE EXOTIC WAFFLES
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Biscoff Milkyway Waffle', 'Biscoff milkyway waffle served with ice-cream', 160, 'WAFFLES & MORE - Exotic', true),
    (cafe_id, 'Chocolate Overload Waffle (Milk)', 'Milk chocolate overload waffle served with ice-cream', 150, 'WAFFLES & MORE - Exotic', true),
    (cafe_id, 'Chocolate Overload Waffle (Dark)', 'Dark chocolate overload waffle served with ice-cream', 150, 'WAFFLES & MORE - Exotic', true),
    (cafe_id, 'Almond Brownie Waffle', 'Almond brownie waffle served with ice-cream', 160, 'WAFFLES & MORE - Exotic', true),
    (cafe_id, 'Dark & White Fantasy Waffle', 'Dark and white fantasy waffle served with ice-cream', 140, 'WAFFLES & MORE - Exotic', true),
    (cafe_id, 'Triple Chocolate Waffle', 'Triple chocolate waffle served with ice-cream', 160, 'WAFFLES & MORE - Exotic', true);

    -- WAFFLES & MORE EXTRA GOODNESS (ADD-ONS)
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Extra Fillings', 'Additional fillings for waffles', 30, 'WAFFLES & MORE - Add-ons', true),
    (cafe_id, 'Oreo Chunks', 'Oreo chunks topping', 20, 'WAFFLES & MORE - Add-ons', true),
    (cafe_id, 'Kit-Kat Bits', 'Kit-Kat bits topping', 20, 'WAFFLES & MORE - Add-ons', true),
    (cafe_id, 'Biscoff Bits', 'Biscoff bits topping', 30, 'WAFFLES & MORE - Add-ons', true),
    (cafe_id, 'Roasted Almonds', 'Roasted almonds topping', 30, 'WAFFLES & MORE - Add-ons', true),
    (cafe_id, 'Brownie Chunks', 'Brownie chunks topping', 30, 'WAFFLES & MORE - Add-ons', true),
    (cafe_id, 'Chocolate Sprinkles', 'Chocolate sprinkles topping', 15, 'WAFFLES & MORE - Add-ons', true),
    (cafe_id, 'Ice-Cream (Vanilla)', 'Vanilla ice-cream scoop', 30, 'WAFFLES & MORE - Add-ons', true),
    (cafe_id, 'Ice-Cream (Chocolate)', 'Chocolate ice-cream scoop', 30, 'WAFFLES & MORE - Add-ons', true);

    -- WAFFLES & MORE TREATS
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Chocolate Lava Cake', 'Warm chocolate lava cake', 80, 'WAFFLES & MORE - Treats', true),
    (cafe_id, 'Lava Cake With Ice-Cream', 'Chocolate lava cake with ice-cream', 100, 'WAFFLES & MORE - Treats', true),
    (cafe_id, 'Chocolate Brownie', 'Rich chocolate brownie', 80, 'WAFFLES & MORE - Treats', true),
    (cafe_id, 'Brownie With Ice-Cream', 'Chocolate brownie with ice-cream', 100, 'WAFFLES & MORE - Treats', true);

    -- WAFFLES & MORE SHAKES
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Kit-Kat Shake', 'Kit-Kat milkshake', 90, 'WAFFLES & MORE - Shakes', true),
    (cafe_id, 'Oreo Shake', 'Oreo milkshake', 90, 'WAFFLES & MORE - Shakes', true),
    (cafe_id, 'Nutella Shake', 'Nutella milkshake', 110, 'WAFFLES & MORE - Shakes', true),
    (cafe_id, 'Belgian Chocolate Shake', 'Belgian chocolate milkshake', 90, 'WAFFLES & MORE - Shakes', true),
    (cafe_id, 'Blueberry White Chocolate Shake', 'Blueberry white chocolate milkshake', 100, 'WAFFLES & MORE - Shakes', true),
    (cafe_id, 'Strawberry White Chocolate Shake', 'Strawberry white chocolate milkshake', 100, 'WAFFLES & MORE - Shakes', true),
    (cafe_id, 'Butterscotch Shake', 'Butterscotch milkshake', 90, 'WAFFLES & MORE - Shakes', true),
    (cafe_id, 'Tiramisu Shake', 'Tiramisu milkshake', 100, 'WAFFLES & MORE - Shakes', true),
    (cafe_id, 'Cold Coffee Shake', 'Classic cold coffee shake', 90, 'WAFFLES & MORE - Shakes', true);

    RAISE NOTICE 'FOOD COURT cafe with all 4 brands (KRISPP, GOBBLERS, Momo Street, WAFFLES & MORE) and menu items added successfully';
END $$;
