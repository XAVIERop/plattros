-- Add 'The Kitchen & Curry' restaurant with comprehensive Indian menu
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
    'The Kitchen & Curry',
    'North Indian',
    'Authentic North Indian cuisine featuring delicious parathas, rich curries, aromatic biryanis, and tandoori specialties. From traditional favorites to modern twists, we bring the authentic taste of Indian kitchens to your plate. Night delivery available!',
    'Indya Mess First Floor, GHS',
    '+91-7073991323',
    '11:00 AM - 11:00 PM (Night Delivery Available)',
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
    SELECT id INTO cafe_id FROM public.cafes WHERE name = 'The Kitchen & Curry';
    
    -- ========================================
    -- PARATHA SECTION
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Aloo Paratha', 'Traditional potato stuffed paratha', 70, 'Paratha', true),
    (cafe_id, 'Aloo Pyaz Paratha', 'Potato and onion stuffed paratha', 80, 'Paratha', true),
    (cafe_id, 'Paneer Masala Paratha', 'Spiced paneer stuffed paratha', 100, 'Paratha', true),
    (cafe_id, 'Chicken Keema Paratha', 'Minced chicken stuffed paratha', 130, 'Paratha', true),
    (cafe_id, 'Chicken Tikka Paratha', 'Chicken tikka stuffed paratha', 140, 'Paratha', true),
    (cafe_id, 'Add Cheese', 'Extra cheese topping for parathas', 30, 'Paratha', true);

    -- ========================================
    -- VEG CURRIES (500ml)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Jeera Aloo', 'Cumin flavored potato curry - 500ml', 150, 'Veg Curries', true),
    (cafe_id, 'Mushroom Do Pyaaza', 'Mushroom with double onions - 500ml', 190, 'Veg Curries', true),
    (cafe_id, 'Matar Mushroom', 'Peas and mushroom curry - 500ml', 190, 'Veg Curries', true),
    (cafe_id, 'Sev Tamatar', 'Crispy sev with tomato curry - 500ml', 170, 'Veg Curries', true),
    (cafe_id, 'Choley Masala', 'Spiced chickpea curry - 500ml', 190, 'Veg Curries', true),
    (cafe_id, 'Rajama Masala', 'Spiced kidney beans curry - 500ml', 190, 'Veg Curries', true),
    (cafe_id, 'Butter Palak Paneer', 'Creamy spinach with paneer - 500ml', 220, 'Veg Curries', true),
    (cafe_id, 'Paneer Butter Masala', 'Creamy tomato paneer curry - 500ml', 220, 'Veg Curries', true),
    (cafe_id, 'Paneer Tikka Lababdar', 'Paneer tikka in rich gravy - 500ml', 220, 'Veg Curries', true),
    (cafe_id, 'Special Paneer Laziz', 'Special delicious paneer curry - 500ml', 220, 'Veg Curries', true),
    (cafe_id, 'Kadai Paneer', 'Paneer in kadai style - 500ml', 220, 'Veg Curries', true),
    (cafe_id, 'Paneer Kolhapuri', 'Spicy Kolhapuri style paneer - 500ml', 220, 'Veg Curries', true),
    (cafe_id, 'Mattar Paneer', 'Peas and paneer curry - 500ml', 220, 'Veg Curries', true),
    (cafe_id, 'Paneer Bhurji', 'Scrambled paneer curry - 500ml', 220, 'Veg Curries', true),
    (cafe_id, 'Paneer Aangara', 'Smoky grilled paneer curry - 500ml', 220, 'Veg Curries', true),
    (cafe_id, 'Paneer Do Pyaza', 'Paneer with double onions - 500ml', 220, 'Veg Curries', true),
    (cafe_id, 'Paneer Chatpata', 'Tangy and spicy paneer curry - 500ml', 250, 'Veg Curries', true),
    (cafe_id, 'Paneer Tikka Masala', 'Paneer tikka in masala gravy - 500ml', 250, 'Veg Curries', true);

    -- ========================================
    -- NON VEG CURRIES (500ml)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Egg Bhurji', 'Scrambled egg curry - 500ml', 90, 'Non-Veg Curries', true),
    (cafe_id, 'Egg Curry (Fried 2 Egg)', 'Fried egg curry with 2 eggs - 500ml', 150, 'Non-Veg Curries', true),
    (cafe_id, 'Chicken Masala', 'Spiced chicken curry - 500ml', 250, 'Non-Veg Curries', true),
    (cafe_id, 'Kadhai Chicken', 'Chicken in kadai style - 500ml', 250, 'Non-Veg Curries', true),
    (cafe_id, 'Chicken Tikka Masala', 'Chicken tikka in masala gravy - 500ml', 260, 'Non-Veg Curries', true),
    (cafe_id, 'Chicken Kolhapuri', 'Spicy Kolhapuri style chicken - 500ml', 270, 'Non-Veg Curries', true),
    (cafe_id, 'Chicken Kaali Mirch', 'Black pepper chicken curry - 500ml', 280, 'Non-Veg Curries', true),
    (cafe_id, 'Butter Chicken Roasted', 'Roasted butter chicken - 500ml', 290, 'Non-Veg Curries', true),
    (cafe_id, 'Chicken Rara', 'Rara style chicken curry - 500ml', 290, 'Non-Veg Curries', true),
    (cafe_id, 'Chicken Bhuna Masala', 'Bhuna style chicken masala - 500ml', 300, 'Non-Veg Curries', true),
    (cafe_id, 'Mutton Curry', 'Traditional mutton curry - 500ml', 310, 'Non-Veg Curries', true),
    (cafe_id, 'Mutton Rogan Josh', 'Mutton in Rogan Josh style - 500ml', 320, 'Non-Veg Curries', true),
    (cafe_id, 'Mutton Masala', 'Spiced mutton masala - 500ml', 340, 'Non-Veg Curries', true);

    -- ========================================
    -- TANDOORI STARTERS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Mushroom Tikka', 'Tandoori grilled mushroom tikka', 250, 'Tandoori Starters', true),
    (cafe_id, 'Paneer Tikka (8 Pcs)', 'Tandoori paneer tikka - 8 pieces', 250, 'Tandoori Starters', true),
    (cafe_id, 'Paneer Malai Tikka (8 Pcs)', 'Creamy malai paneer tikka - 8 pieces', 250, 'Tandoori Starters', true),
    (cafe_id, 'Paneer Achari Tikka (8 Pcs)', 'Pickle flavored paneer tikka - 8 pieces', 260, 'Tandoori Starters', true),
    (cafe_id, 'Paneer Pahadi Tikka (8 Pcs)', 'Pahadi style paneer tikka - 8 pieces', 260, 'Tandoori Starters', true),
    (cafe_id, 'Chicken Tikka (8 Pcs)', 'Tandoori chicken tikka - 8 pieces', 280, 'Tandoori Starters', true),
    (cafe_id, 'Chicken Malai Tikka (8 Pcs)', 'Creamy malai chicken tikka - 8 pieces', 280, 'Tandoori Starters', true),
    (cafe_id, 'Chicken Kali Miri (8 Pcs)', 'Black pepper chicken tikka - 8 pieces', 280, 'Tandoori Starters', true),
    (cafe_id, 'Chicken Pahadi Tikka (8 Pcs)', 'Pahadi style chicken tikka - 8 pieces', 280, 'Tandoori Starters', true),
    (cafe_id, 'Chicken Seek Kebab (8 Pcs)', 'Chicken seekh kebab - 8 pieces', 300, 'Tandoori Starters', true),
    (cafe_id, 'Tandoori Chicken Half (4 Pcs)', 'Half tandoori chicken - 4 pieces', 200, 'Tandoori Starters', true),
    (cafe_id, 'Tandoori Chicken Full (8 Pcs)', 'Full tandoori chicken - 8 pieces', 400, 'Tandoori Starters', true);

    -- ========================================
    -- BIRYANI (750ml)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Paneer Tikka Biryani', 'Paneer tikka biryani - 750ml', 180, 'Biryani', true),
    (cafe_id, 'Egg Biryani', 'Egg biryani - 750ml', 170, 'Biryani', true),
    (cafe_id, 'Chicken Tikka Biryani (4 Pcs)', 'Chicken tikka biryani with 4 pieces - 750ml', 210, 'Biryani', true),
    (cafe_id, 'Achari Tikka Biryani', 'Pickle flavored tikka biryani - 750ml', 220, 'Biryani', true),
    (cafe_id, 'Hyderabadi Chicken Biryani (4 Pcs)', 'Hyderabadi style chicken biryani with 4 pieces - 750ml', 230, 'Biryani', true),
    (cafe_id, 'Chicken Leg Biryani (3 Pcs)', 'Chicken leg biryani with 3 pieces - 750ml', 250, 'Biryani', true),
    (cafe_id, 'Mutton Biryani (4 Pcs)', 'Mutton biryani with 4 pieces - 750ml', 300, 'Biryani', true);

    -- ========================================
    -- RICE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Fried Rice', 'Vegetable fried rice', 130, 'Rice', true),
    (cafe_id, 'Paneer Fried Rice', 'Paneer fried rice', 160, 'Rice', true),
    (cafe_id, 'Egg Fried Rice', 'Egg fried rice', 160, 'Rice', true),
    (cafe_id, 'Chicken Fried Rice', 'Chicken fried rice', 170, 'Rice', true),
    (cafe_id, 'Add - Schezwan', 'Schezwan sauce add-on for rice', 20, 'Rice', true);

    -- ========================================
    -- SANDWICH
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Aloo Sandwich', 'Potato sandwich', 70, 'Sandwich', true),
    (cafe_id, 'Aloo Cheese Sandwich', 'Potato and cheese sandwich', 90, 'Sandwich', true),
    (cafe_id, 'Crispy Paneer Sandwich', 'Crispy paneer sandwich', 100, 'Sandwich', true),
    (cafe_id, 'Paneer Tikka Sandwich', 'Paneer tikka sandwich', 110, 'Sandwich', true),
    (cafe_id, 'Spicy Chicken Sandwich', 'Spicy chicken sandwich', 130, 'Sandwich', true),
    (cafe_id, 'Chicken Tikka Sandwich', 'Chicken tikka sandwich', 140, 'Sandwich', true),
    (cafe_id, 'Chicken Salami Sandwich', 'Chicken salami sandwich', 150, 'Sandwich', true);

    -- ========================================
    -- PIZZA
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Margherita Pizza (8")', 'Classic margherita pizza - 8 inch', 120, 'Pizza', true),
    (cafe_id, 'Margherita Pizza (11")', 'Classic margherita pizza - 11 inch', 220, 'Pizza', true),
    (cafe_id, 'Veggie Feast (OTC) Pizza (8")', 'Veggie feast pizza - 8 inch', 160, 'Pizza', true),
    (cafe_id, 'Veggie Feast (OTC) Pizza (11")', 'Veggie feast pizza - 11 inch', 260, 'Pizza', true),
    (cafe_id, 'Double Cheese Pizza (8")', 'Double cheese pizza - 8 inch', 170, 'Pizza', true),
    (cafe_id, 'Double Cheese Pizza (11")', 'Double cheese pizza - 11 inch', 270, 'Pizza', true),
    (cafe_id, 'Paneer Tikka Pizza (8")', 'Paneer tikka pizza - 8 inch', 190, 'Pizza', true),
    (cafe_id, 'Paneer Tikka Pizza (11")', 'Paneer tikka pizza - 11 inch', 290, 'Pizza', true),
    (cafe_id, 'Chicken Tikka Pizza (8")', 'Chicken tikka pizza - 8 inch', 210, 'Pizza', true),
    (cafe_id, 'Chicken Tikka Pizza (11")', 'Chicken tikka pizza - 11 inch', 330, 'Pizza', true),
    (cafe_id, 'Chicken Salami Pizza (8")', 'Chicken salami pizza - 8 inch', 230, 'Pizza', true),
    (cafe_id, 'Chicken Salami Pizza (11")', 'Chicken salami pizza - 11 inch', 350, 'Pizza', true);

    -- ========================================
    -- TANDOORI ROLL
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Tandoori Aloo Garlic Roll', 'Tandoori potato with garlic roll', 100, 'Tandoori Roll', true),
    (cafe_id, 'Tandoori Garlic Paneer Tikka Roll', 'Tandoori paneer tikka with garlic roll', 150, 'Tandoori Roll', true),
    (cafe_id, 'Tandoori Chicken Garlic Tikka Roll', 'Tandoori chicken tikka with garlic roll', 180, 'Tandoori Roll', true);

    -- ========================================
    -- OMELETTE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Masala Omelette With Butter Toast', 'Spiced omelette with butter toast', 50, 'Omelette', true),
    (cafe_id, 'Mushroom Omelette', 'Mushroom omelette', 70, 'Omelette', true),
    (cafe_id, 'Chicken Omelette', 'Chicken omelette', 100, 'Omelette', true),
    (cafe_id, 'Jumbo French Toast', 'Large French toast', 120, 'Omelette', true);

    -- ========================================
    -- SMOOTHIES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Banana On Date Smoothie', 'Banana, apple, dates, muesli, honey with milk', 90, 'Smoothies', true),
    (cafe_id, 'Apple Strawberry Crunch Smoothie', 'Apple, strawberry, muesli, honey with milk', 90, 'Smoothies', true),
    (cafe_id, 'Strawberry Banana Smoothie', 'Strawberry, banana, muesli, honey with milk', 90, 'Smoothies', true),
    (cafe_id, 'Shiry Chas Smoothie', 'Oats, banana, strawberry, honey with milk', 90, 'Smoothies', true),
    (cafe_id, 'Peanut Banana Smoothie', 'Banana with peanut butter', 90, 'Smoothies', true);

    -- ========================================
    -- BREADS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Roti (Plain)', 'Plain roti', 12, 'Breads', true),
    (cafe_id, 'Roti (Butter)', 'Butter roti', 15, 'Breads', true),
    (cafe_id, 'Missi Roti', 'Traditional missi roti', 20, 'Breads', true),
    (cafe_id, 'Naan (Plain)', 'Plain naan', 30, 'Breads', true),
    (cafe_id, 'Naan (Butter)', 'Butter naan', 35, 'Breads', true),
    (cafe_id, 'Lachha Paratha', 'Layered lachha paratha', 40, 'Breads', true),
    (cafe_id, 'Garlic Naan', 'Garlic flavored naan', 50, 'Breads', true),
    (cafe_id, 'Stuff Naan', 'Stuffed naan', 70, 'Breads', true),
    (cafe_id, 'Cheese Naan', 'Cheese naan', 70, 'Breads', true);

    -- ========================================
    -- OTHER
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Dahi Papdi Chaat', 'Yogurt papdi chaat', 100, 'Other', true),
    (cafe_id, 'Honey Chilli Potato', 'Honey chili potatoes', 120, 'Other', true),
    (cafe_id, 'Grilled Chicken 100g', 'Grilled chicken - 100g', 90, 'Other', true),
    (cafe_id, 'Raw Paneer 100g', 'Raw paneer - 100g', 50, 'Other', true),
    (cafe_id, 'Sauted Paneer 150g', 'Sautéed paneer - 150g', 100, 'Other', true);

    -- ========================================
    -- EXTRA
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Butter Milk', 'Traditional buttermilk', 40, 'Extra', true),
    (cafe_id, 'Boondi Raita', 'Boondi yogurt raita', 60, 'Extra', true),
    (cafe_id, 'Mix Veg Raita', 'Mixed vegetable raita', 70, 'Extra', true),
    (cafe_id, 'Green Salad', 'Fresh green salad', 70, 'Extra', true);

    -- ========================================
    -- VEG COMBO (350ml)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Chole Kulcha (4 Pcs)', 'Chickpea curry with kulcha - 4 pieces', 99, 'Veg Combo', true),
    (cafe_id, 'Rajma Chawal', 'Kidney beans with rice', 160, 'Veg Combo', true),
    (cafe_id, 'Choley Chawal', 'Chickpea curry with rice', 160, 'Veg Combo', true),
    (cafe_id, 'Choley + 2 Tandoori Butter Roti', 'Chickpea curry with 2 butter rotis', 160, 'Veg Combo', true),
    (cafe_id, 'Rajma + 2 Tandoori Butter Roti', 'Kidney beans with 2 butter rotis', 160, 'Veg Combo', true),
    (cafe_id, 'Paneer Bhurji + 2 Tandoori Butter Roti', 'Scrambled paneer with 2 butter rotis', 180, 'Veg Combo', true),
    (cafe_id, 'Paneer Butter Masala + 2 Tandoori Butter Roti', 'Paneer butter masala with 2 butter rotis', 190, 'Veg Combo', true),
    (cafe_id, 'Paneer Tikka Lababdar + 2 Tandoori Butter Roti', 'Paneer tikka lababdar with 2 butter rotis', 190, 'Veg Combo', true),
    (cafe_id, 'Special Paneer Laziz + 2 Tandoori Butter Roti', 'Special paneer laziz with 2 butter rotis', 190, 'Veg Combo', true),
    (cafe_id, 'Kadai Paneer + 2 Tandoori Butter Roti', 'Kadai paneer with 2 butter rotis', 190, 'Veg Combo', true),
    (cafe_id, 'Paneer Kolhapuri + 2 Tandoori Butter Roti', 'Paneer kolhapuri with 2 butter rotis', 190, 'Veg Combo', true),
    (cafe_id, 'Mattar Paneer + 2 Tandoori Butter Roti', 'Mattar paneer with 2 butter rotis', 190, 'Veg Combo', true);

    -- ========================================
    -- NON VEG COMBO (350ml)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Egg Bhurji + 2 Tandoori Butter Roti', 'Scrambled egg with 2 butter rotis', 120, 'Non-Veg Combo', true),
    (cafe_id, 'Egg Dry (3 Egg) + 2 Tandoori Butter Roti', 'Dry egg curry with 3 eggs and 2 butter rotis', 150, 'Non-Veg Combo', true),
    (cafe_id, 'Chicken Curry + 2 Tandoori Butter Roti', 'Chicken curry with 2 butter rotis', 240, 'Non-Veg Combo', true),
    (cafe_id, 'Butter Chicken + 2 Tandoori Butter Roti', 'Butter chicken with 2 butter rotis', 260, 'Non-Veg Combo', true),
    (cafe_id, 'Chicken Dry + 2 Tandoori Butter Roti', 'Dry chicken with 2 butter rotis', 300, 'Non-Veg Combo', true),
    (cafe_id, 'Chicken Masala + 2 Tandoori Butter Roti', 'Chicken masala with 2 butter rotis', 260, 'Non-Veg Combo', true),
    (cafe_id, 'Butter Chicken Roasted + 2 Tandoori Butter Roti', 'Roasted butter chicken with 2 butter rotis', 260, 'Non-Veg Combo', true),
    (cafe_id, 'Chicken Tikka Masala + 2 Tandoori Butter Roti', 'Chicken tikka masala with 2 butter rotis', 260, 'Non-Veg Combo', true),
    (cafe_id, 'Chicken Curry (4 Pcs) + Rice', 'Chicken curry with 4 pieces and rice', 290, 'Non-Veg Combo', true),
    (cafe_id, 'Mutton Curry (3 Pcs) + 2 Tandoori Butter Roti', 'Mutton curry with 3 pieces and 2 butter rotis', 300, 'Non-Veg Combo', true);

    RAISE NOTICE 'The Kitchen & Curry restaurant with comprehensive Indian menu added successfully';
END $$;
