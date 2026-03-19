-- Add CHATKARA cafe and all menu items
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
    'CHATKARA',
    'Multi-Cuisine',
    'Specializing in Chaap, Chinese, Momos and more. From authentic soya chaap to delicious momos, tandoori items to Indian curries - we bring you the perfect blend of flavors. Pure vegetarian menu with the taste of non-veg in veg!',
    'B1 Ground Floor, GHS',
    '+91-890 596 2406',
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
    SELECT id INTO cafe_id FROM public.cafes WHERE name = 'CHATKARA';
    
    -- STARTER'S (Chaap Items)
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Masala Chaap (Half)', 'Spiced soya chaap - half portion', 170, 'Starters', true),
    (cafe_id, 'Masala Chaap (Full)', 'Spiced soya chaap - full portion', 230, 'Starters', true),
    (cafe_id, 'Punjabi Chaap (Half)', 'Punjabi style soya chaap - half portion', 170, 'Starters', true),
    (cafe_id, 'Punjabi Chaap (Full)', 'Punjabi style soya chaap - full portion', 230, 'Starters', true),
    (cafe_id, 'Achari Chaap (Half)', 'Pickle-flavored soya chaap - half portion', 170, 'Starters', true),
    (cafe_id, 'Achari Chaap (Full)', 'Pickle-flavored soya chaap - full portion', 230, 'Starters', true),
    (cafe_id, 'Tandoori Chaap (Half)', 'Tandoori style soya chaap - half portion', 170, 'Starters', true),
    (cafe_id, 'Tandoori Chaap (Full)', 'Tandoori style soya chaap - full portion', 230, 'Starters', true),
    (cafe_id, 'Malai Chaap (Half)', 'Creamy malai soya chaap - half portion', 180, 'Starters', true),
    (cafe_id, 'Malai Chaap (Full)', 'Creamy malai soya chaap - full portion', 240, 'Starters', true),
    (cafe_id, 'Afghani Chaap (Half)', 'Afghani style soya chaap - half portion', 180, 'Starters', true),
    (cafe_id, 'Afghani Chaap (Full)', 'Afghani style soya chaap - full portion', 240, 'Starters', true),
    (cafe_id, 'Peshawari Chaap (Half)', 'Peshawari style soya chaap - half portion', 180, 'Starters', true),
    (cafe_id, 'Peshawari Chaap (Full)', 'Peshawari style soya chaap - full portion', 240, 'Starters', true),
    (cafe_id, 'Lemon Chaap (Half)', 'Lemon-flavored soya chaap - half portion', 180, 'Starters', true),
    (cafe_id, 'Lemon Chaap (Full)', 'Lemon-flavored soya chaap - full portion', 240, 'Starters', true),
    (cafe_id, 'Haryali Chaap (Half)', 'Green herb soya chaap - half portion', 180, 'Starters', true),
    (cafe_id, 'Haryali Chaap (Full)', 'Green herb soya chaap - full portion', 240, 'Starters', true),
    (cafe_id, 'Pudina Chaap (Half)', 'Mint-flavored soya chaap - half portion', 180, 'Starters', true),
    (cafe_id, 'Pudina Chaap (Full)', 'Mint-flavored soya chaap - full portion', 240, 'Starters', true),
    (cafe_id, 'Spl. Chatkara Chaap (Half)', 'Special Chatkara soya chaap - half portion', 180, 'Starters', true),
    (cafe_id, 'Spl. Chatkara Chaap (Full)', 'Special Chatkara soya chaap - full portion', 240, 'Starters', true),
    (cafe_id, 'GYM Spl. Chaap (Half)', 'Gym special soya chaap - half portion', 180, 'Starters', true),
    (cafe_id, 'GYM Spl. Chaap (Full)', 'Gym special soya chaap - full portion', 240, 'Starters', true),
    (cafe_id, 'Super Spicy Chaap (Half)', 'Extra spicy soya chaap - half portion', 190, 'Starters', true),
    (cafe_id, 'Super Spicy Chaap (Full)', 'Extra spicy soya chaap - full portion', 250, 'Starters', true),
    (cafe_id, 'Garlic Chaap (Half)', 'Garlic-flavored soya chaap - half portion', 190, 'Starters', true),
    (cafe_id, 'Garlic Chaap (Full)', 'Garlic-flavored soya chaap - full portion', 250, 'Starters', true),
    (cafe_id, 'Kali Mirchi Chaap (Half)', 'Black pepper soya chaap - half portion', 190, 'Starters', true),
    (cafe_id, 'Kali Mirchi Chaap (Full)', 'Black pepper soya chaap - full portion', 250, 'Starters', true),
    (cafe_id, 'Stuff Chaap (Half)', 'Stuffed soya chaap - half portion', 190, 'Starters', true),
    (cafe_id, 'Stuff Chaap (Full)', 'Stuffed soya chaap - full portion', 250, 'Starters', true),
    (cafe_id, 'Stuff Masala Chaap (Half)', 'Stuffed masala soya chaap - half portion', 200, 'Starters', true),
    (cafe_id, 'Stuff Masala Chaap (Full)', 'Stuffed masala soya chaap - full portion', 260, 'Starters', true),
    (cafe_id, 'Veg Chi. Tikka (Half)', 'Vegetable chicken-style tikka - half portion', 190, 'Starters', true),
    (cafe_id, 'Veg Chi. Tikka (Full)', 'Vegetable chicken-style tikka - full portion', 250, 'Starters', true);

    -- TIKKA ITEMS
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Paneer Tikka (Half)', 'Marinated paneer tikka - half portion', 200, 'Tikka Items', true),
    (cafe_id, 'Paneer Tikka (Full)', 'Marinated paneer tikka - full portion', 280, 'Tikka Items', true),
    (cafe_id, 'Achari Paneer Tikka (Half)', 'Pickle-flavored paneer tikka - half portion', 210, 'Tikka Items', true),
    (cafe_id, 'Achari Paneer Tikka (Full)', 'Pickle-flavored paneer tikka - full portion', 280, 'Tikka Items', true),
    (cafe_id, 'Punjabi Paneer Tikka (Half)', 'Punjabi style paneer tikka - half portion', 220, 'Tikka Items', true),
    (cafe_id, 'Punjabi Paneer Tikka (Full)', 'Punjabi style paneer tikka - full portion', 290, 'Tikka Items', true),
    (cafe_id, 'Afghani Paneer Tikka (Half)', 'Afghani style paneer tikka - half portion', 230, 'Tikka Items', true),
    (cafe_id, 'Afghani Paneer Tikka (Full)', 'Afghani style paneer tikka - full portion', 290, 'Tikka Items', true);

    -- TANDOORI MOMO'S
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Masala Momos', 'Spiced tandoori momos', 230, 'Tandoori Momos', true),
    (cafe_id, 'Malai Momos', 'Creamy malai tandoori momos', 230, 'Tandoori Momos', true),
    (cafe_id, 'Afghani Momos', 'Afghani style tandoori momos', 240, 'Tandoori Momos', true),
    (cafe_id, 'Peri Peri Momos', 'Peri peri spiced tandoori momos', 230, 'Tandoori Momos', true),
    (cafe_id, 'Achari Momos', 'Pickle-flavored tandoori momos', 230, 'Tandoori Momos', true),
    (cafe_id, 'Spicy Tandoori Momos', 'Extra spicy tandoori momos', 240, 'Tandoori Momos', true),
    (cafe_id, 'Chatkara Tan. Momos', 'Special Chatkara tandoori momos', 240, 'Tandoori Momos', true),
    (cafe_id, 'Masala Cheese Momos', 'Cheese-stuffed masala tandoori momos', 270, 'Tandoori Momos', true);

    -- GRAVY ITEMS - Chaap Gravy
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg. Butter Chicken (Half)', 'Vegetarian butter chicken gravy - half portion', 240, 'Gravy Items', true),
    (cafe_id, 'Veg. Butter Chicken (Full)', 'Vegetarian butter chicken gravy - full portion', 360, 'Gravy Items', true),
    (cafe_id, 'Veg. Punjabi Kukad (Half)', 'Vegetarian Punjabi chicken-style gravy - half portion', 240, 'Gravy Items', true),
    (cafe_id, 'Veg. Punjabi Kukad (Full)', 'Vegetarian Punjabi chicken-style gravy - full portion', 360, 'Gravy Items', true),
    (cafe_id, 'Veg. Handi Chicken (Half)', 'Vegetarian handi chicken-style gravy - half portion', 240, 'Gravy Items', true),
    (cafe_id, 'Veg. Handi Chicken (Full)', 'Vegetarian handi chicken-style gravy - full portion', 360, 'Gravy Items', true),
    (cafe_id, 'Veg. Tawa Chaap (Half)', 'Vegetarian tawa chaap gravy - half portion', 240, 'Gravy Items', true),
    (cafe_id, 'Veg. Tawa Chaap (Full)', 'Vegetarian tawa chaap gravy - full portion', 360, 'Gravy Items', true),
    (cafe_id, 'Veg. Kadhai Chaap (Half)', 'Vegetarian kadhai chaap gravy - half portion', 240, 'Gravy Items', true),
    (cafe_id, 'Veg. Kadhai Chaap (Full)', 'Vegetarian kadhai chaap gravy - full portion', 360, 'Gravy Items', true),
    (cafe_id, 'Veg. Traffic Police (Half)', 'Vegetarian traffic police-style gravy - half portion', 240, 'Gravy Items', true),
    (cafe_id, 'Veg. Traffic Police (Full)', 'Vegetarian traffic police-style gravy - full portion', 360, 'Gravy Items', true),
    (cafe_id, 'Veg. Bahubali Chaap (Half)', 'Vegetarian bahubali chaap gravy - half portion', 240, 'Gravy Items', true),
    (cafe_id, 'Veg. Bahubali Chaap (Full)', 'Vegetarian bahubali chaap gravy - full portion', 360, 'Gravy Items', true),
    (cafe_id, 'Veg. Chatkara (Half)', 'Vegetarian Chatkara special gravy - half portion', 240, 'Gravy Items', true),
    (cafe_id, 'Veg. Chatkara (Full)', 'Vegetarian Chatkara special gravy - full portion', 360, 'Gravy Items', true),
    (cafe_id, 'Veg. Korma Chaap (Half)', 'Vegetarian korma chaap gravy - half portion', 240, 'Gravy Items', true),
    (cafe_id, 'Veg. Korma Chaap (Full)', 'Vegetarian korma chaap gravy - full portion', 360, 'Gravy Items', true);

    -- GRAVY ITEMS - Veg Meat Gravy
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg. Lal Maas (Half)', 'Vegetarian red meat-style gravy - half portion', 240, 'Gravy Items', true),
    (cafe_id, 'Veg. Lal Maas (Full)', 'Vegetarian red meat-style gravy - full portion', 360, 'Gravy Items', true),
    (cafe_id, 'Veg. Rogan Gosh (Half)', 'Vegetarian rogan gosh-style gravy - half portion', 240, 'Gravy Items', true),
    (cafe_id, 'Veg. Rogan Gosh (Full)', 'Vegetarian rogan gosh-style gravy - full portion', 360, 'Gravy Items', true),
    (cafe_id, 'Veg. Rara Meat (Keema) (Half)', 'Vegetarian rara meat-style gravy - half portion', 240, 'Gravy Items', true),
    (cafe_id, 'Veg. Rara Meat (Keema) (Full)', 'Vegetarian rara meat-style gravy - full portion', 360, 'Gravy Items', true),
    (cafe_id, 'Veg. Mutton Gravy (Half)', 'Vegetarian mutton-style gravy - half portion', 240, 'Gravy Items', true),
    (cafe_id, 'Veg. Mutton Gravy (Full)', 'Vegetarian mutton-style gravy - full portion', 360, 'Gravy Items', true),
    (cafe_id, 'Veg. Black Mutton (Half)', 'Vegetarian black mutton-style gravy - half portion', 240, 'Gravy Items', true),
    (cafe_id, 'Veg. Black Mutton (Full)', 'Vegetarian black mutton-style gravy - full portion', 360, 'Gravy Items', true);

    -- INDIAN GRAVY
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Pindi Chole (Half)', 'Traditional pindi chole - half portion', 160, 'Indian Gravy', true),
    (cafe_id, 'Pindi Chole (Full)', 'Traditional pindi chole - full portion', 250, 'Indian Gravy', true),
    (cafe_id, 'Rajma (Masala) (Half)', 'Spiced rajma curry - half portion', 160, 'Indian Gravy', true),
    (cafe_id, 'Rajma (Masala) (Full)', 'Spiced rajma curry - full portion', 250, 'Indian Gravy', true),
    (cafe_id, 'Daal Makhani (Half)', 'Creamy black lentils - half portion', 220, 'Indian Gravy', true),
    (cafe_id, 'Daal Makhani (Full)', 'Creamy black lentils - full portion', 320, 'Indian Gravy', true);

    -- PANEER
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Shahi Paneer (Half)', 'Royal shahi paneer - half portion', 240, 'Paneer', true),
    (cafe_id, 'Shahi Paneer (Full)', 'Royal shahi paneer - full portion', 360, 'Paneer', true),
    (cafe_id, 'Kadhai Paneer (Half)', 'Kadhai-style paneer - half portion', 240, 'Paneer', true),
    (cafe_id, 'Kadhai Paneer (Full)', 'Kadhai-style paneer - full portion', 360, 'Paneer', true),
    (cafe_id, 'Paneer Do-Pyaza (Half)', 'Paneer with onions - half portion', 240, 'Paneer', true),
    (cafe_id, 'Paneer Do-Pyaza (Full)', 'Paneer with onions - full portion', 360, 'Paneer', true),
    (cafe_id, 'Panner Chatkara (Half)', 'Chatkara special paneer - half portion', 240, 'Paneer', true),
    (cafe_id, 'Panner Chatkara (Full)', 'Chatkara special paneer - full portion', 360, 'Paneer', true),
    (cafe_id, 'Paneer Lababdar (Half)', 'Rich paneer lababdar - half portion', 240, 'Paneer', true),
    (cafe_id, 'Paneer Lababdar (Full)', 'Rich paneer lababdar - full portion', 360, 'Paneer', true),
    (cafe_id, 'Paneer Butter Masala (Half)', 'Creamy paneer butter masala - half portion', 240, 'Paneer', true),
    (cafe_id, 'Paneer Butter Masala (Full)', 'Creamy paneer butter masala - full portion', 360, 'Paneer', true),
    (cafe_id, 'Paneer Tikka Masala (Half)', 'Paneer tikka in masala gravy - half portion', 260, 'Paneer', true),
    (cafe_id, 'Paneer Tikka Masala (Full)', 'Paneer tikka in masala gravy - full portion', 360, 'Paneer', true);

    -- BREAD
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Tandoori Roti', 'Traditional tandoori roti', 20, 'Bread', true),
    (cafe_id, 'Butter Tandoori Roti', 'Buttered tandoori roti', 25, 'Bread', true),
    (cafe_id, 'Rumali Roti', 'Thin handkerchief bread', 20, 'Bread', true),
    (cafe_id, 'Butter Rumali Roti', 'Buttered rumali roti', 25, 'Bread', true),
    (cafe_id, 'Lachha Paratha', 'Layered paratha', 45, 'Bread', true),
    (cafe_id, 'Plain Naan', 'Plain leavened bread', 35, 'Bread', true),
    (cafe_id, 'Butter Naan', 'Buttered naan', 40, 'Bread', true),
    (cafe_id, 'Garlic Naan', 'Garlic-flavored naan', 80, 'Bread', true),
    (cafe_id, 'Cheese Garlic Naan', 'Cheese and garlic naan', 95, 'Bread', true);

    -- RICE
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Plain Rice (450ml)', 'Steamed basmati rice - 450ml', 70, 'Rice', true),
    (cafe_id, 'Plain Rice (650ml)', 'Steamed basmati rice - 650ml', 100, 'Rice', true),
    (cafe_id, 'Jeera Rice (450ml)', 'Cumin-flavored rice - 450ml', 100, 'Rice', true),
    (cafe_id, 'Jeera Rice (650ml)', 'Cumin-flavored rice - 650ml', 130, 'Rice', true);

    -- BIRYANI
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Chicken Biryani', 'Vegetarian chicken-style biryani', 250, 'Biryani', true),
    (cafe_id, 'Veg Mutton Biryani', 'Vegetarian mutton-style biryani', 250, 'Biryani', true);

    -- FRIED CHAAP
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'KFC Chaap', 'KFC-style fried chaap', 230, 'Fried Chaap', true),
    (cafe_id, 'Crunchy Stick Chaap', 'Crunchy stick-style chaap', 230, 'Fried Chaap', true);

    -- ROLLS
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Masala Chaap Roll (Half)', 'Masala chaap roll - 2 pieces', 190, 'Rolls', true),
    (cafe_id, 'Masala Chaap Roll (Full)', 'Masala chaap roll - 3 pieces', 260, 'Rolls', true),
    (cafe_id, 'Punjabi Chaap Roll (Half)', 'Punjabi chaap roll - 2 pieces', 190, 'Rolls', true),
    (cafe_id, 'Punjabi Chaap Roll (Full)', 'Punjabi chaap roll - 3 pieces', 260, 'Rolls', true),
    (cafe_id, 'Achari Chaap Roll (Half)', 'Achari chaap roll - 2 pieces', 190, 'Rolls', true),
    (cafe_id, 'Achari Chaap Roll (Full)', 'Achari chaap roll - 3 pieces', 260, 'Rolls', true),
    (cafe_id, 'Tandoori Chaap Roll (Half)', 'Tandoori chaap roll - 2 pieces', 190, 'Rolls', true),
    (cafe_id, 'Tandoori Chaap Roll (Full)', 'Tandoori chaap roll - 3 pieces', 260, 'Rolls', true),
    (cafe_id, 'Malai Chaap Roll (Half)', 'Malai chaap roll - 2 pieces', 200, 'Rolls', true),
    (cafe_id, 'Malai Chaap Roll (Full)', 'Malai chaap roll - 3 pieces', 270, 'Rolls', true),
    (cafe_id, 'Afghani Chaap Roll (Half)', 'Afghani chaap roll - 2 pieces', 200, 'Rolls', true),
    (cafe_id, 'Afghani Chaap Roll (Full)', 'Afghani chaap roll - 3 pieces', 270, 'Rolls', true),
    (cafe_id, 'Peshawari Chaap Roll (Half)', 'Peshawari chaap roll - 2 pieces', 200, 'Rolls', true),
    (cafe_id, 'Peshawari Chaap Roll (Full)', 'Peshawari chaap roll - 3 pieces', 270, 'Rolls', true),
    (cafe_id, 'Lemon Chaap Roll (Half)', 'Lemon chaap roll - 2 pieces', 200, 'Rolls', true),
    (cafe_id, 'Lemon Chaap Roll (Full)', 'Lemon chaap roll - 3 pieces', 270, 'Rolls', true),
    (cafe_id, 'Haryali Chaap Roll (Half)', 'Haryali chaap roll - 2 pieces', 200, 'Rolls', true),
    (cafe_id, 'Haryali Chaap Roll (Full)', 'Haryali chaap roll - 3 pieces', 270, 'Rolls', true),
    (cafe_id, 'Pudina Chaap Roll (Half)', 'Pudina chaap roll - 2 pieces', 200, 'Rolls', true),
    (cafe_id, 'Pudina Chaap Roll (Full)', 'Pudina chaap roll - 3 pieces', 270, 'Rolls', true),
    (cafe_id, 'Spl. Chatkara Chaap Roll (Half)', 'Special Chatkara chaap roll - 2 pieces', 200, 'Rolls', true),
    (cafe_id, 'Spl. Chatkara Chaap Roll (Full)', 'Special Chatkara chaap roll - 3 pieces', 270, 'Rolls', true),
    (cafe_id, 'Super Spicy Chaap Roll (Half)', 'Super spicy chaap roll - 2 pieces', 200, 'Rolls', true),
    (cafe_id, 'Super Spicy Chaap Roll (Full)', 'Super spicy chaap roll - 3 pieces', 270, 'Rolls', true),
    (cafe_id, 'Garlic Chaap Roll (Half)', 'Garlic chaap roll - 2 pieces', 210, 'Rolls', true),
    (cafe_id, 'Garlic Chaap Roll (Full)', 'Garlic chaap roll - 3 pieces', 280, 'Rolls', true),
    (cafe_id, 'Stuff Chaap Roll (Half)', 'Stuffed chaap roll - 2 pieces', 220, 'Rolls', true),
    (cafe_id, 'Stuff Chaap Roll (Full)', 'Stuffed chaap roll - 3 pieces', 290, 'Rolls', true),
    (cafe_id, 'Chi. Tikka Chaap Roll (Half)', 'Chicken-style tikka chaap roll - 2 pieces', 220, 'Rolls', true),
    (cafe_id, 'Chi. Tikka Chaap Roll (Full)', 'Chicken-style tikka chaap roll - 3 pieces', 280, 'Rolls', true),
    (cafe_id, 'Paneer Tikka Roll (Half)', 'Paneer tikka roll - 2 pieces', 230, 'Rolls', true),
    (cafe_id, 'Paneer Tikka Roll (Full)', 'Paneer tikka roll - 3 pieces', 310, 'Rolls', true),
    (cafe_id, 'Achari Paneer Tikka Roll (Half)', 'Achari paneer tikka roll - 2 pieces', 230, 'Rolls', true),
    (cafe_id, 'Achari Paneer Tikka Roll (Full)', 'Achari paneer tikka roll - 3 pieces', 310, 'Rolls', true),
    (cafe_id, 'Punjabi Paneer Tikka Roll (Half)', 'Punjabi paneer tikka roll - 2 pieces', 230, 'Rolls', true),
    (cafe_id, 'Punjabi Paneer Tikka Roll (Full)', 'Punjabi paneer tikka roll - 3 pieces', 310, 'Rolls', true),
    (cafe_id, 'Afghani Paneer Tikka Roll (Half)', 'Afghani paneer tikka roll - 2 pieces', 240, 'Rolls', true),
    (cafe_id, 'Afghani Paneer Tikka Roll (Full)', 'Afghani paneer tikka roll - 3 pieces', 320, 'Rolls', true);

    -- CHINESE MENU - HOT SOUP
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Soup', 'Vegetable soup', 100, 'Chinese - Hot Soup', true),
    (cafe_id, 'Veg Thupka', 'Vegetable thukpa', 120, 'Chinese - Hot Soup', true),
    (cafe_id, 'Chicken Soup', 'Chicken-style soup', 130, 'Chinese - Hot Soup', true),
    (cafe_id, 'Chicken Thukpa', 'Chicken-style thukpa', 140, 'Chinese - Hot Soup', true);

    -- CHINESE MENU - MOMO'S (8 Pc)
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Steam Momos', 'Steamed vegetable momos - 8 pieces', 100, 'Chinese - Momos', true),
    (cafe_id, 'Paneer Steam Momos', 'Steamed paneer momos - 8 pieces', 120, 'Chinese - Momos', true),
    (cafe_id, 'Chicken Steam Momos', 'Steamed chicken-style momos - 8 pieces', 130, 'Chinese - Momos', true),
    (cafe_id, 'Veg Fried Momos', 'Fried vegetable momos - 8 pieces', 120, 'Chinese - Momos', true),
    (cafe_id, 'Paneer Fried Momos', 'Fried paneer momos - 8 pieces', 130, 'Chinese - Momos', true),
    (cafe_id, 'Chicken Fried Momos', 'Fried chicken-style momos - 8 pieces', 140, 'Chinese - Momos', true),
    (cafe_id, 'Veg Schezwan Momos', 'Schezwan vegetable momos - 8 pieces', 130, 'Chinese - Momos', true),
    (cafe_id, 'Paneer Schezwan Momos', 'Schezwan paneer momos - 8 pieces', 140, 'Chinese - Momos', true),
    (cafe_id, 'Chicken Schezwan Momos', 'Schezwan chicken-style momos - 8 pieces', 150, 'Chinese - Momos', true),
    (cafe_id, 'Veg Kurkure Momos', 'Kurkure-style vegetable momos - 8 pieces', 160, 'Chinese - Momos', true),
    (cafe_id, 'Paneer Kurkure Momos', 'Kurkure-style paneer momos - 8 pieces', 170, 'Chinese - Momos', true),
    (cafe_id, 'Chicken Kurkure Momos', 'Kurkure-style chicken momos - 8 pieces', 180, 'Chinese - Momos', true),
    (cafe_id, 'Nepoli Veg Momos', 'Nepoli-style vegetable momos - 8 pieces', 160, 'Chinese - Momos', true),
    (cafe_id, 'Nepoli Paneer Momos', 'Nepoli-style paneer momos - 8 pieces', 170, 'Chinese - Momos', true),
    (cafe_id, 'Nepoli Chicken Momos', 'Nepoli-style chicken momos - 8 pieces', 180, 'Chinese - Momos', true);

    -- CHINESE MENU - SPRING ROLL'S
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Spring Roll', 'Vegetable spring roll', 120, 'Chinese - Spring Rolls', true),
    (cafe_id, 'Veg Dragon Spring Roll', 'Dragon-style vegetable spring roll', 160, 'Chinese - Spring Rolls', true),
    (cafe_id, 'Veg Tandoori Spring Roll', 'Tandoori-style vegetable spring roll', 170, 'Chinese - Spring Rolls', true);

    -- CHINESE MENU - TANDOORI CHOWMEIN
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Tandoori Chowmein', 'Tandoori-style vegetable chowmein', 160, 'Chinese - Tandoori Chowmein', true),
    (cafe_id, 'Chicken Tandoori Chowmein', 'Tandoori-style chicken chowmein', 180, 'Chinese - Tandoori Chowmein', true);

    -- CHINESE MENU - CHICKEN TANDOORI MOMO'S
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Chicken Tandoori Momos', 'Tandoori-style chicken momos', 260, 'Chinese - Chicken Tandoori Momos', true),
    (cafe_id, 'Chicken Peri Peri Momos', 'Peri peri chicken momos', 260, 'Chinese - Chicken Tandoori Momos', true),
    (cafe_id, 'Chicken Afghani Momos', 'Afghani-style chicken momos', 260, 'Chinese - Chicken Tandoori Momos', true);

    -- CHINESE MENU - WOK RICE
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Fried Rice', 'Vegetable fried rice', 120, 'Chinese - Wok Rice', true),
    (cafe_id, 'Veg Schezwan Fried Rice', 'Schezwan vegetable fried rice', 140, 'Chinese - Wok Rice', true),
    (cafe_id, 'Paneer Fried Rice', 'Paneer fried rice', 160, 'Chinese - Wok Rice', true),
    (cafe_id, 'Paneer Schezwan Fried Rice', 'Schezwan paneer fried rice', 170, 'Chinese - Wok Rice', true),
    (cafe_id, 'Double Egg Fried Rice', 'Double egg fried rice', 160, 'Chinese - Wok Rice', true),
    (cafe_id, 'Chicken Fried Rice', 'Chicken fried rice', 170, 'Chinese - Wok Rice', true),
    (cafe_id, 'Chicken Schezwan Fried Rice', 'Schezwan chicken fried rice', 180, 'Chinese - Wok Rice', true);

    -- CHINESE MENU - NOODLE'S
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Noodles', 'Vegetable noodles', 120, 'Chinese - Noodles', true),
    (cafe_id, 'Veg Hakka Noodles', 'Hakka vegetable noodles', 130, 'Chinese - Noodles', true),
    (cafe_id, 'Veg Schezawan Noodles', 'Schezwan vegetable noodles', 140, 'Chinese - Noodles', true),
    (cafe_id, 'Veg Chilli Garlic Noodles', 'Chilli garlic vegetable noodles', 150, 'Chinese - Noodles', true),
    (cafe_id, 'Veg Butter Garlic Noodles', 'Butter garlic vegetable noodles', 160, 'Chinese - Noodles', true),
    (cafe_id, 'Double Egg Hakka Noodles', 'Double egg hakka noodles', 160, 'Chinese - Noodles', true),
    (cafe_id, 'Chicken Noodles', 'Chicken noodles', 160, 'Chinese - Noodles', true),
    (cafe_id, 'Chicken Hakka Noodles', 'Chicken hakka noodles', 170, 'Chinese - Noodles', true),
    (cafe_id, 'Chicken Schezawan Noodles', 'Chicken schezwan noodles', 180, 'Chinese - Noodles', true),
    (cafe_id, 'Chicken Chilli Garlic Noodles', 'Chicken chilli garlic noodles', 190, 'Chinese - Noodles', true);

    -- CHINESE MENU - CHILLI CHINA
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Manchuriyan (Dry)', 'Dry vegetable manchurian', 150, 'Chinese - Chilli China', true),
    (cafe_id, 'Veg Manchuriyan (Gravy)', 'Gravy vegetable manchurian', 160, 'Chinese - Chilli China', true),
    (cafe_id, 'Chilli Paneer (Dry)', 'Dry chilli paneer', 180, 'Chinese - Chilli China', true),
    (cafe_id, 'Chilli Paneer (Gravy)', 'Gravy chilli paneer', 190, 'Chinese - Chilli China', true),
    (cafe_id, 'Chilli Chicken', 'Chilli chicken-style dish', 260, 'Chinese - Chilli China', true),
    (cafe_id, 'Chicken 65', 'Chicken 65-style dish', 260, 'Chinese - Chilli China', true);

    -- INDIAN MENU - INDIAN
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Chole Bhature', 'Chickpeas with bhatura', 130, 'Indian', true),
    (cafe_id, 'Paneer Chole Bharure', 'Paneer with chole and bhatura', 150, 'Indian', true),
    (cafe_id, 'Extra Bhatura', 'Additional bhatura', 45, 'Indian', true),
    (cafe_id, 'Chole Kulche', 'Chickpeas with kulcha', 120, 'Indian', true),
    (cafe_id, 'Paneer Chole Kulche', 'Paneer with chole and kulcha', 140, 'Indian', true),
    (cafe_id, 'Extra Kulcha', 'Additional kulcha', 40, 'Indian', true),
    (cafe_id, 'Nutri Kulcha', 'Nutritious kulcha', 130, 'Indian', true),
    (cafe_id, 'Paneer Nutri Kulcha', 'Paneer with nutritious kulcha', 150, 'Indian', true),
    (cafe_id, 'Extra Chole', 'Additional chole', 40, 'Indian', true);

    -- INDIAN MENU - PARATHA
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Aloo Paratha', 'Potato-stuffed paratha', 90, 'Indian - Paratha', true),
    (cafe_id, 'Aloo Onion Paratha', 'Potato and onion paratha', 90, 'Indian - Paratha', true),
    (cafe_id, 'Paneer Paratha', 'Paneer-stuffed paratha', 110, 'Indian - Paratha', true),
    (cafe_id, 'Veg Keema Paratha', 'Vegetable keema paratha', 130, 'Indian - Paratha', true),
    (cafe_id, 'Aloo Cheese Paratha', 'Potato and cheese paratha', 120, 'Indian - Paratha', true),
    (cafe_id, 'Cheese Paneer Paratha', 'Cheese and paneer paratha', 140, 'Indian - Paratha', true);

    -- INDIAN MENU - VEG. COMBOS
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Chhole Chur Chur Naan-1', 'Chhole with chur chur naan combo', 170, 'Indian - Combos', true),
    (cafe_id, 'Rajma Chawal', 'Rajma with rice combo', 160, 'Indian - Combos', true),
    (cafe_id, 'Chhole Chawal', 'Chhole with rice combo', 160, 'Indian - Combos', true),
    (cafe_id, 'Daal Makhani', 'Creamy dal makhani combo', 190, 'Indian - Combos', true),
    (cafe_id, 'Shahi Paneer', 'Royal shahi paneer combo', 190, 'Indian - Combos', true),
    (cafe_id, 'Kadhai Paneer', 'Kadhai-style paneer combo', 190, 'Indian - Combos', true),
    (cafe_id, 'Paneer Lababdar', 'Rich paneer lababdar combo', 190, 'Indian - Combos', true),
    (cafe_id, 'Paneer Butter Masala', 'Creamy paneer butter masala combo', 190, 'Indian - Combos', true);

    RAISE NOTICE 'CHATKARA cafe and all menu items added successfully';
END $$;
