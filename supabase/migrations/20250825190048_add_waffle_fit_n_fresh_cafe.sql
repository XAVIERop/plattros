-- Add 'Waffle Fit N Fresh' restaurant with comprehensive waffle and beverage menu
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
    'Waffle Fit N Fresh',
    'Waffle & Beverages',
    'A delightful waffle and beverage destination offering fresh waffles, mini pancakes, premium milkshakes, and refreshing drinks. From classic Belgian waffles to innovative bubble style waffles, we bring you the perfect blend of taste and freshness!',
    'G1 First Floor',
    '+91-7597538430',
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
    SELECT id INTO cafe_id FROM public.cafes WHERE name = 'Waffle Fit N Fresh';
    
    -- ========================================
    -- WAFFLE MENU
    -- ========================================
    
    -- ========================================
    -- ICE DELIGHT WAFFLE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Vanilla Treat Waffle', 'Vanilla flavored ice cream waffle', 120, 'Ice Delight Waffle', true),
    (cafe_id, 'Chocolate Delight Waffle', 'Chocolate flavored ice cream waffle', 120, 'Ice Delight Waffle', true),
    (cafe_id, 'Butterscotch Ice Waffle', 'Butterscotch flavored ice cream waffle', 120, 'Ice Delight Waffle', true);

    -- ========================================
    -- DARK WAFFLE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Choco Loaded Waffle', 'Chocolate loaded dark waffle', 115, 'Dark Waffle', true),
    (cafe_id, 'Belgian Choco Passion Waffle', 'Belgian chocolate passion waffle', 115, 'Dark Waffle', true),
    (cafe_id, 'Dark and White Choco Blend Waffle', 'Dark and white chocolate blend waffle', 115, 'Dark Waffle', true),
    (cafe_id, 'Triple Sinful Waffle', 'Triple chocolate sinful waffle', 115, 'Dark Waffle', true);

    -- ========================================
    -- MINI PAN CAKE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Chocolate Indulgence Mini Pancake', 'Chocolate indulgence mini pancake', 130, 'Mini Pan Cake', true),
    (cafe_id, 'Nutella Forever Mini Pancake', 'Nutella forever mini pancake', 149, 'Mini Pan Cake', true);

    -- ========================================
    -- CLASSIC CHOCO BELGIAN WAFFLE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Exotic Nutella Belgian Waffle', 'Exotic Nutella Belgian waffle', 120, 'Classic Choco Belgian Waffle', true),
    (cafe_id, 'Tasty Butterscotch Belgian Waffle', 'Tasty butterscotch Belgian waffle', 115, 'Classic Choco Belgian Waffle', true),
    (cafe_id, 'Coffee Choco Treat Belgian Waffle', 'Coffee chocolate treat Belgian waffle', 115, 'Classic Choco Belgian Waffle', true),
    (cafe_id, 'Oreo Belgian Waffle', 'Oreo Belgian waffle', 115, 'Classic Choco Belgian Waffle', true),
    (cafe_id, 'Kitkat Belgian Waffle', 'KitKat Belgian waffle', 115, 'Classic Choco Belgian Waffle', true),
    (cafe_id, 'Snickers Cream Belgian Waffle', 'Snickers cream Belgian waffle', 115, 'Classic Choco Belgian Waffle', true);

    -- ========================================
    -- BUBBLE STYLE WAFFLE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Melted Oreo Obsession Bubble Waffle', 'Melted Oreo obsession bubble style waffle', 169, 'Bubble Style Waffle', true),
    (cafe_id, 'Dark Choco Fantasy Bubble Waffle', 'Dark chocolate fantasy bubble style waffle', 159, 'Bubble Style Waffle', true),
    (cafe_id, 'Nutella Monster Bubble Waffle', 'Nutella monster bubble style waffle', 189, 'Bubble Style Waffle', true);

    -- ========================================
    -- DRINK MENU
    -- ========================================
    
    -- ========================================
    -- LEMON ICE TEA
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Nestle Lemon Ice Tea', 'Nestle lemon ice tea', 45, 'Lemon Ice Tea', true),
    (cafe_id, 'Strawberry Ice Tea', 'Strawberry ice tea', 50, 'Lemon Ice Tea', true),
    (cafe_id, 'Peach Ice Tea', 'Peach ice tea', 50, 'Lemon Ice Tea', true),
    (cafe_id, 'Mint Ice Tea', 'Mint ice tea', 50, 'Lemon Ice Tea', true);

    -- ========================================
    -- SODA
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Lemon Soda', 'Fresh lemon soda', 35, 'Soda', true),
    (cafe_id, 'Masala Lemon Soda', 'Spicy masala lemon soda', 45, 'Soda', true),
    (cafe_id, 'Peach Lemon Soda', 'Peach flavored lemon soda', 55, 'Soda', true);

    -- ========================================
    -- MASALA COLD DRINKS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Masala Cola', 'Spicy masala cola', 49, 'Masala Cold Drinks', true),
    (cafe_id, 'Masala Sprite', 'Spicy masala sprite', 49, 'Masala Cold Drinks', true),
    (cafe_id, 'Mountain Dew Masala', 'Spicy masala mountain dew', 45, 'Masala Cold Drinks', true);

    -- ========================================
    -- MILK SHAKES
    -- ========================================
    
    -- ========================================
    -- FRUIT SHAKES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Banana Shake (Medium)', 'Banana milkshake - medium size', 59, 'Fruit Shakes', true),
    (cafe_id, 'Banana Shake (Large)', 'Banana milkshake - large size', 80, 'Fruit Shakes', true),
    (cafe_id, 'Litchi Shake (Medium)', 'Litchi milkshake - medium size', 69, 'Fruit Shakes', true),
    (cafe_id, 'Litchi Shake (Large)', 'Litchi milkshake - large size', 89, 'Fruit Shakes', true),
    (cafe_id, 'Pineapple Shake (Medium)', 'Pineapple milkshake - medium size', 69, 'Fruit Shakes', true),
    (cafe_id, 'Pineapple Shake (Large)', 'Pineapple milkshake - large size', 89, 'Fruit Shakes', true),
    (cafe_id, 'Strawberry Shake (Medium)', 'Strawberry milkshake - medium size', 69, 'Fruit Shakes', true),
    (cafe_id, 'Strawberry Shake (Large)', 'Strawberry milkshake - large size', 89, 'Fruit Shakes', true),
    (cafe_id, 'Exotic Blueberry Shake (Medium)', 'Exotic blueberry milkshake - medium size', 69, 'Fruit Shakes', true),
    (cafe_id, 'Exotic Blueberry Shake (Large)', 'Exotic blueberry milkshake - large size', 89, 'Fruit Shakes', true),
    (cafe_id, 'Mango Shake (Medium)', 'Mango milkshake - medium size', 69, 'Fruit Shakes', true),
    (cafe_id, 'Mango Shake (Large)', 'Mango milkshake - large size', 89, 'Fruit Shakes', true),
    (cafe_id, 'Butterscotch Shake (Medium)', 'Butterscotch milkshake - medium size', 89, 'Fruit Shakes', true),
    (cafe_id, 'Butterscotch Shake (Large)', 'Butterscotch milkshake - large size', 110, 'Fruit Shakes', true),
    (cafe_id, 'Blackcurrant Shake (Medium)', 'Blackcurrant milkshake - medium size', 99, 'Fruit Shakes', true),
    (cafe_id, 'Blackcurrant Shake (Large)', 'Blackcurrant milkshake - large size', 120, 'Fruit Shakes', true);

    -- ========================================
    -- CHOCOLATY SHAKES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Oreo Shake (Medium)', 'Oreo milkshake - medium size', 69, 'Chocolaty Shakes', true),
    (cafe_id, 'Oreo Shake (Large)', 'Oreo milkshake - large size', 89, 'Chocolaty Shakes', true),
    (cafe_id, 'Nutty Sinkers Shake (Medium)', 'Nutty sinkers milkshake - medium size', 85, 'Chocolaty Shakes', true),
    (cafe_id, 'Nutty Sinkers Shake (Large)', 'Nutty sinkers milkshake - large size', 99, 'Chocolaty Shakes', true),
    (cafe_id, 'KitKat Shake (Medium)', 'KitKat milkshake - medium size', 85, 'Chocolaty Shakes', true),
    (cafe_id, 'KitKat Shake (Large)', 'KitKat milkshake - large size', 99, 'Chocolaty Shakes', true),
    (cafe_id, 'Lovely Nutella Shake (Medium)', 'Lovely Nutella milkshake - medium size', 90, 'Chocolaty Shakes', true),
    (cafe_id, 'Lovely Nutella Shake (Large)', 'Lovely Nutella milkshake - large size', 109, 'Chocolaty Shakes', true),
    (cafe_id, 'Chocolate Shake (Medium)', 'Chocolate milkshake - medium size', 69, 'Chocolaty Shakes', true),
    (cafe_id, 'Chocolate Shake (Large)', 'Chocolate milkshake - large size', 89, 'Chocolaty Shakes', true),
    (cafe_id, 'Chocolaty Brownie Shake (Medium)', 'Chocolate brownie milkshake - medium size', 69, 'Chocolaty Shakes', true),
    (cafe_id, 'Chocolaty Brownie Shake (Large)', 'Chocolate brownie milkshake - large size', 89, 'Chocolaty Shakes', true);

    -- ========================================
    -- COLD COFFEE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Cold Coffee (Medium)', 'Cold coffee - medium size', 60, 'Cold Coffee', true),
    (cafe_id, 'Cold Coffee (Large)', 'Cold coffee - large size', 80, 'Cold Coffee', true),
    (cafe_id, 'Cold Coffee with Ice', 'Cold coffee with ice', 79, 'Cold Coffee', true);

    -- ========================================
    -- FAST FOOD
    -- ========================================
    
    -- ========================================
    -- BURGER
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Aalu Tikki Burger', 'Potato tikki burger', 50, 'Burger', true),
    (cafe_id, 'Cheese Burger', 'Classic cheese burger', 65, 'Burger', true),
    (cafe_id, 'Spicy Masala Burger', 'Spicy masala burger', 60, 'Burger', true),
    (cafe_id, 'Paneer Chatpata Burger', 'Spicy paneer chatpata burger', 89, 'Burger', true),
    (cafe_id, 'Spanish Corn Burger', 'Spanish corn burger', 69, 'Burger', true),
    (cafe_id, 'Double Tikki Masala Burger', 'Double potato tikki masala burger', 89, 'Burger', true),
    (cafe_id, 'Extra Cheese Slice', 'Extra cheese slice for burger', 20, 'Burger', true);

    -- ========================================
    -- VADA PAV
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Mumbaitya Vada Pav', 'Traditional Mumbai style vada pav', 40, 'Vada Pav', true),
    (cafe_id, 'Cheese Vada Pav', 'Cheese vada pav', 45, 'Vada Pav', true),
    (cafe_id, 'Cheese Spicy Vada Pav', 'Spicy cheese vada pav', 55, 'Vada Pav', true),
    (cafe_id, 'Spicy Vada Pav', 'Spicy vada pav', 50, 'Vada Pav', true);

    -- ========================================
    -- SANDWICH
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Grill Sandwich', 'Grilled vegetable sandwich', 50, 'Sandwich', true),
    (cafe_id, 'Veg Cheese Sandwich', 'Vegetable cheese sandwich', 65, 'Sandwich', true),
    (cafe_id, 'Aloo Masala Sandwich', 'Potato masala sandwich', 69, 'Sandwich', true),
    (cafe_id, 'Spicy Paneer Sandwich', 'Spicy paneer sandwich', 89, 'Sandwich', true),
    (cafe_id, 'Spanish Cheese Corn Sandwich', 'Spanish cheese corn sandwich', 69, 'Sandwich', true);

    -- ========================================
    -- WRAPS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Aloo Tikki Wrap', 'Potato tikki wrap', 59, 'Wraps', true),
    (cafe_id, 'Chatpata Masala Wrap', 'Spicy chatpata masala wrap', 65, 'Wraps', true),
    (cafe_id, 'Crunchy Veggie Wrap', 'Crunchy vegetable wrap', 69, 'Wraps', true),
    (cafe_id, 'Paneer Makhani Wrap', 'Paneer makhani wrap', 89, 'Wraps', true),
    (cafe_id, 'Kathi Roll', 'Traditional kathi roll', 79, 'Wraps', true);

    -- ========================================
    -- MOMOS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Steam Momos', 'Vegetable steamed momos', 69, 'Momos', true),
    (cafe_id, 'Veg Fried Momos', 'Vegetable fried momos', 75, 'Momos', true),
    (cafe_id, 'Peri Peri Fried Momos', 'Spicy peri peri fried momos', 79, 'Momos', true),
    (cafe_id, 'Paneer Masala Momos', 'Paneer masala momos', 89, 'Momos', true),
    (cafe_id, 'Paneer Masala Fried Momos', 'Paneer masala fried momos', 99, 'Momos', true);

    -- ========================================
    -- SNACKS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Classic Fries', 'Classic french fries', 60, 'Snacks', true),
    (cafe_id, 'Garlic Fries', 'Garlic flavored fries', 69, 'Snacks', true),
    (cafe_id, 'Cheese Fries', 'Cheese topped fries', 69, 'Snacks', true),
    (cafe_id, 'Mayonnaise Fries', 'Mayonnaise topped fries', 69, 'Snacks', true),
    (cafe_id, 'Tandoori Fries', 'Tandoori flavored fries', 69, 'Snacks', true),
    (cafe_id, 'Peri Peri Fries', 'Spicy peri peri fries', 69, 'Snacks', true);

    -- ========================================
    -- GARLIC BREAD
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Garlic Bread', 'Classic garlic bread', 79, 'Garlic Bread', true);

    -- ========================================
    -- SWEET CORN
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Salted Corn Spicy', 'Spicy salted corn', 59, 'Sweet Corn', true),
    (cafe_id, 'Crunchy Salted Corn', 'Crunchy salted corn', 65, 'Sweet Corn', true);

    -- ========================================
    -- MAGGI
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Plain Maggi', 'Plain maggi noodles', 35, 'Maggi', true),
    (cafe_id, 'Masala Maggi', 'Spicy masala maggi', 40, 'Maggi', true),
    (cafe_id, 'Butter Maggi', 'Butter maggi noodles', 50, 'Maggi', true),
    (cafe_id, 'Butter Masala Maggi', 'Butter masala maggi', 55, 'Maggi', true),
    (cafe_id, 'Chilli Garlic Maggi', 'Chilli garlic maggi', 45, 'Maggi', true),
    (cafe_id, 'Tandoori Maggi', 'Tandoori flavored maggi', 50, 'Maggi', true),
    (cafe_id, 'Mix Veg Maggi', 'Mixed vegetable maggi', 55, 'Maggi', true),
    (cafe_id, 'Cheese Maggi', 'Cheese maggi noodles', 55, 'Maggi', true),
    (cafe_id, 'Cheese Masala Maggi', 'Cheese masala maggi', 60, 'Maggi', true),
    (cafe_id, 'Cheese Slice Cheese Masala Maggi', 'Extra cheese slice with cheese masala maggi', 70, 'Maggi', true);

    -- ========================================
    -- PASTA
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Red Sauce Pasta', 'Tomato red sauce pasta', 89, 'Pasta', true),
    (cafe_id, 'White Sauce Pasta', 'Creamy white sauce pasta', 99, 'Pasta', true),
    (cafe_id, 'Peri Peri Sauce Pasta', 'Spicy peri peri sauce pasta', 109, 'Pasta', true);

    RAISE NOTICE 'Waffle Fit N Fresh restaurant with comprehensive waffle and beverage menu added successfully';
END $$;
