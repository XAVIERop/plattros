-- Add 'COOK HOUSE' restaurant with comprehensive multi-cuisine menu
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
    'COOK HOUSE',
    'Multi-Cuisine',
    'A culinary haven offering diverse flavors from Chinese specialties to authentic Indian cuisine. From sizzling starters to hearty main courses, we bring you the best of multiple cuisines under one roof. Perfect for every craving!',
    'G1 First Floor',
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
    SELECT id INTO cafe_id FROM public.cafes WHERE name = 'COOK HOUSE';
    
    -- ========================================
    -- CHINA WALL SECTION
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Spring Roll', 'Crispy vegetable spring rolls', 180, 'China Wall', true),
    (cafe_id, 'Honey Chilli Potato', 'Sweet and spicy honey chili potatoes', 180, 'China Wall', true),
    (cafe_id, 'Crispy Chilly Paneer (Dry)', 'Crispy paneer in chili sauce - dry', 260, 'China Wall', true),
    (cafe_id, 'Crispy Chilly Paneer (Gravy)', 'Crispy paneer in chili sauce - gravy', 260, 'China Wall', true),
    (cafe_id, 'Crispy Chilli Mushroom', 'Crispy mushrooms in chili sauce', 220, 'China Wall', true),
    (cafe_id, 'Crispy Corn Salt n Pepper', 'Crispy corn with salt and pepper', 180, 'China Wall', true),
    (cafe_id, 'Veg Manchurian (Dry)', 'Vegetable manchurian - dry', 180, 'China Wall', true),
    (cafe_id, 'Veg Manchurian (Gravy)', 'Vegetable manchurian - gravy', 200, 'China Wall', true),
    (cafe_id, 'Veg Fried Rice', 'Vegetable fried rice', 200, 'China Wall', true),
    (cafe_id, 'Veg Schezwan Rice', 'Vegetable schezwan rice', 210, 'China Wall', true),
    (cafe_id, 'Steam Momos (6 pcs)', 'Steamed vegetable momos - 6 pieces', 130, 'China Wall', true),
    (cafe_id, 'Fried Momos (6 pcs)', 'Fried vegetable momos - 6 pieces', 140, 'China Wall', true),
    (cafe_id, 'Vegetable Hakka Noodles', 'Vegetable hakka noodles', 150, 'China Wall', true),
    (cafe_id, 'Chilli Garlic Noodles', 'Chili garlic noodles', 160, 'China Wall', true),
    (cafe_id, 'Chicken Fried Rice', 'Chicken fried rice', 210, 'China Wall', true),
    (cafe_id, 'Chicken Hakka Noodles', 'Chicken hakka noodles', 200, 'China Wall', true),
    (cafe_id, 'Chilli Chicken', 'Spicy chili chicken', 290, 'China Wall', true);

    -- ========================================
    -- CHEF'S SPECIAL
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Jungli Chicken', 'Chef special jungli chicken', 350, 'Chef Special', true),
    (cafe_id, 'Anda Ghotala (5 pcs)', 'Egg ghotala with 5 eggs', 250, 'Chef Special', true),
    (cafe_id, 'Subz-E-Nizami', 'Chef special vegetable dish', 260, 'Chef Special', true);

    -- ========================================
    -- BREADS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Tandoori Roti (Plain)', 'Plain tandoori roti', 18, 'Breads', true),
    (cafe_id, 'Tandoori Roti (Butter)', 'Butter tandoori roti', 22, 'Breads', true),
    (cafe_id, 'Missi Roti', 'Traditional missi roti', 55, 'Breads', true),
    (cafe_id, 'Pudina Laccha Paratha (Plain)', 'Mint laccha paratha - plain', 50, 'Breads', true),
    (cafe_id, 'Pudina Laccha Paratha (Butter)', 'Mint laccha paratha - butter', 60, 'Breads', true),
    (cafe_id, 'Hari Mirch Laccha Paratha (Plain)', 'Green chili laccha paratha - plain', 55, 'Breads', true),
    (cafe_id, 'Hari Mirch Laccha Paratha (Butter)', 'Green chili laccha paratha - butter', 60, 'Breads', true),
    (cafe_id, 'Laccha Paratha (Plain)', 'Layered laccha paratha - plain', 55, 'Breads', true),
    (cafe_id, 'Laccha Paratha (Butter)', 'Layered laccha paratha - butter', 60, 'Breads', true),
    (cafe_id, 'Amritsari Kulcha', 'Amritsari style kulcha', 90, 'Breads', true),
    (cafe_id, 'Paneer Kulcha', 'Paneer stuffed kulcha', 90, 'Breads', true),
    (cafe_id, 'Onion Kulcha', 'Onion stuffed kulcha', 70, 'Breads', true),
    (cafe_id, 'Mix Kulcha', 'Mixed vegetable kulcha', 80, 'Breads', true),
    (cafe_id, 'Naan (Plain)', 'Plain naan', 50, 'Breads', true),
    (cafe_id, 'Naan (Butter)', 'Butter naan', 55, 'Breads', true),
    (cafe_id, 'Garlic Naan (Plain)', 'Garlic naan - plain', 65, 'Breads', true),
    (cafe_id, 'Garlic Naan (Butter)', 'Garlic naan - butter', 75, 'Breads', true),
    (cafe_id, 'Cheese Naan', 'Cheese stuffed naan', 90, 'Breads', true),
    (cafe_id, 'Cheese Garlic Naan', 'Cheese garlic naan', 110, 'Breads', true),
    (cafe_id, 'Chur Chur Naan', 'Chur chur naan', 80, 'Breads', true);

    -- ========================================
    -- PARATHA (with curd & pickle)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Aloo Paratha (2pcs)', 'Potato stuffed paratha - 2 pieces with curd & pickle', 140, 'Paratha', true),
    (cafe_id, 'Aloo Pyaaz Paratha (2pcs)', 'Potato onion paratha - 2 pieces with curd & pickle', 150, 'Paratha', true),
    (cafe_id, 'Paneer Onion Paratha (2pcs)', 'Paneer onion paratha - 2 pieces with curd & pickle', 160, 'Paratha', true),
    (cafe_id, 'Gobhi Paratha (2pcs)', 'Cauliflower paratha - 2 pieces with curd & pickle', 140, 'Paratha', true),
    (cafe_id, 'Onion Cheese Paratha (2pcs)', 'Onion cheese paratha - 2 pieces with curd & pickle', 170, 'Paratha', true),
    (cafe_id, 'Cheese Corn Paratha (2pcs)', 'Cheese corn paratha - 2 pieces with curd & pickle', 160, 'Paratha', true),
    (cafe_id, 'Mix Paratha (2pcs)', 'Mixed vegetable paratha - 2 pieces with curd & pickle', 160, 'Paratha', true);

    -- ========================================
    -- RAITA
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Mix Veg Raita', 'Mixed vegetable raita', 110, 'Raita', true),
    (cafe_id, 'Nupuri Raita (Boondi)', 'Boondi raita', 100, 'Raita', true),
    (cafe_id, 'Fried Raita', 'Fried raita', 110, 'Raita', true);

    -- ========================================
    -- PAPAD
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Plain Papad (Roasted)', 'Plain papad - roasted', 40, 'Papad', true),
    (cafe_id, 'Plain Papad (Fried)', 'Plain papad - fried', 50, 'Papad', true),
    (cafe_id, 'Masala Papad (Roasted)', 'Masala papad - roasted', 60, 'Papad', true),
    (cafe_id, 'Masala Papad (Fried)', 'Masala papad - fried', 70, 'Papad', true);

    -- ========================================
    -- THALI (VEG)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'SPECIAL VEG THALI', 'Paneer Lababdar + Dal Makhani + Vegetable + Rice + 2 Tandoori Roti + 1 Laccha Paratha + Raita + Salad + Pickle + Papad', 230, 'Veg Thali', true);

    -- ========================================
    -- THALI (NON-VEG)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'SPECIAL NON-VEG THALI', 'Butter Chicken + Egg Curry + Dal Makhani + Rice + 2 Tandoori Roti + 1 Laccha Paratha + Raita + Salad + Pickle + Papad', 300, 'Non-Veg Thali', true);

    -- ========================================
    -- STARTERS (VEG/PANEER/SOYA)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Bhutte Ke Kebab (8 pcs)', 'Corn kebabs - 8 pieces', 210, 'Starters', true),
    (cafe_id, 'Paneer Tikka (6 pcs)', 'Paneer tikka - 6 pieces', 270, 'Starters', true),
    (cafe_id, 'Malai Paneer Tikka (6 pcs)', 'Creamy paneer tikka - 6 pieces', 280, 'Starters', true),
    (cafe_id, 'Soya Chaap Tikka', 'Soya chaap tikka', 250, 'Starters', true),
    (cafe_id, 'Malai Soya Chaap Tikka', 'Creamy soya chaap tikka', 260, 'Starters', true),
    (cafe_id, 'Aachari Paneer Tikka (6 pcs)', 'Pickle flavored paneer tikka - 6 pieces', 270, 'Starters', true),
    (cafe_id, 'Hara Bhara Kebab (8 pcs)', 'Green herb kebabs - 8 pieces', 220, 'Starters', true),
    (cafe_id, 'Mushroom Tikka', 'Mushroom tikka', 270, 'Starters', true),
    (cafe_id, 'Paneer Pudina Tikka (6 pcs)', 'Mint paneer tikka - 6 pieces', 280, 'Starters', true);

    -- ========================================
    -- STARTERS (CHICKEN)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Chicken Tikka (8 pcs)', 'Chicken tikka - 8 pieces', 370, 'Chicken Starters', true),
    (cafe_id, 'Aachari Chicken Tikka', 'Pickle flavored chicken tikka', 370, 'Chicken Starters', true),
    (cafe_id, 'Garlic Chicken Tikka', 'Garlic chicken tikka', 380, 'Chicken Starters', true),
    (cafe_id, 'Murgh Malai Tikka (6 pcs)', 'Creamy chicken tikka - 6 pieces', 360, 'Chicken Starters', true),
    (cafe_id, 'Chicken Seekh Kebab', 'Chicken seekh kebab', 400, 'Chicken Starters', true),
    (cafe_id, 'Tandoori Chicken (Half)', 'Half tandoori chicken', 320, 'Chicken Starters', true),
    (cafe_id, 'Tandoori Chicken (Full)', 'Full tandoori chicken', 500, 'Chicken Starters', true),
    (cafe_id, 'Pudina Chicken Tikka (6 pcs)', 'Mint chicken tikka - 6 pieces', 360, 'Chicken Starters', true);

    -- ========================================
    -- MAIN COURSE (VEG) - VEG GRAVY
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Palak Paneer (Half)', 'Spinach paneer - half portion', 200, 'Veg Main Course', true),
    (cafe_id, 'Palak Paneer (Full)', 'Spinach paneer - full portion', 280, 'Veg Main Course', true),
    (cafe_id, 'Shahi Paneer (Half)', 'Royal paneer - half portion', 200, 'Veg Main Course', true),
    (cafe_id, 'Shahi Paneer (Full)', 'Royal paneer - full portion', 280, 'Veg Main Course', true),
    (cafe_id, 'Kadhai Paneer (Half)', 'Kadhai style paneer - half portion', 190, 'Veg Main Course', true),
    (cafe_id, 'Kadhai Paneer (Full)', 'Kadhai style paneer - full portion', 280, 'Veg Main Course', true),
    (cafe_id, 'Paneer Tikka Masala (Half)', 'Paneer tikka masala - half portion', 210, 'Veg Main Course', true),
    (cafe_id, 'Paneer Tikka Masala (Full)', 'Paneer tikka masala - full portion', 290, 'Veg Main Course', true),
    (cafe_id, 'Paneer Lababdar (Half)', 'Paneer lababdar - half portion', 200, 'Veg Main Course', true),
    (cafe_id, 'Paneer Lababdar (Full)', 'Paneer lababdar - full portion', 290, 'Veg Main Course', true),
    (cafe_id, 'Paneer Makhanwala (Half)', 'Paneer makhanwala - half portion', 210, 'Veg Main Course', true),
    (cafe_id, 'Paneer Makhanwala (Full)', 'Paneer makhanwala - full portion', 300, 'Veg Main Course', true),
    (cafe_id, 'Paneer Bhurji (Half)', 'Scrambled paneer - half portion', 210, 'Veg Main Course', true),
    (cafe_id, 'Paneer Bhurji (Full)', 'Scrambled paneer - full portion', 290, 'Veg Main Course', true),
    (cafe_id, 'Paneer Sirka Pyaaz (Half)', 'Paneer with vinegar onions - half portion', 200, 'Veg Main Course', true),
    (cafe_id, 'Paneer Sirka Pyaaz (Full)', 'Paneer with vinegar onions - full portion', 300, 'Veg Main Course', true),
    (cafe_id, 'Matar Paneer (Half)', 'Peas paneer - half portion', 190, 'Veg Main Course', true),
    (cafe_id, 'Matar Paneer (Full)', 'Peas paneer - full portion', 280, 'Veg Main Course', true),
    (cafe_id, 'Paneer Rajwada (Half)', 'Paneer rajwada - half portion', 210, 'Veg Main Course', true),
    (cafe_id, 'Paneer Rajwada (Full)', 'Paneer rajwada - full portion', 300, 'Veg Main Course', true),
    (cafe_id, 'Malai Kofta (Half)', 'Creamy kofta - half portion', 190, 'Veg Main Course', true),
    (cafe_id, 'Malai Kofta (Full)', 'Creamy kofta - full portion', 300, 'Veg Main Course', true),
    (cafe_id, 'Soya Chaap Korma (Half)', 'Soya chaap korma - half portion', 200, 'Veg Main Course', true),
    (cafe_id, 'Soya Chaap Korma (Full)', 'Soya chaap korma - full portion', 280, 'Veg Main Course', true),
    (cafe_id, 'Soya Chaap Tikka Masala (Half)', 'Soya chaap tikka masala - half portion', 200, 'Veg Main Course', true),
    (cafe_id, 'Soya Chaap Tikka Masala (Full)', 'Soya chaap tikka masala - full portion', 290, 'Veg Main Course', true),
    (cafe_id, 'Matar Mushroom (Half)', 'Peas mushroom - half portion', 180, 'Veg Main Course', true),
    (cafe_id, 'Matar Mushroom (Full)', 'Peas mushroom - full portion', 270, 'Veg Main Course', true),
    (cafe_id, 'Kadhai Mushroom (Half)', 'Kadhai mushroom - half portion', 190, 'Veg Main Course', true),
    (cafe_id, 'Kadhai Mushroom (Full)', 'Kadhai mushroom - full portion', 280, 'Veg Main Course', true),
    (cafe_id, 'Amritsari Chole (Half)', 'Amritsari chickpeas - half portion', 180, 'Veg Main Course', true),
    (cafe_id, 'Amritsari Chole (Full)', 'Amritsari chickpeas - full portion', 260, 'Veg Main Course', true),
    (cafe_id, 'Jeera Aloo (Half)', 'Cumin potatoes - half portion', 150, 'Veg Main Course', true),
    (cafe_id, 'Jeera Aloo (Full)', 'Cumin potatoes - full portion', 210, 'Veg Main Course', true),
    (cafe_id, 'Mix-Veg (Half)', 'Mixed vegetables - half portion', 160, 'Veg Main Course', true),
    (cafe_id, 'Mix-Veg (Full)', 'Mixed vegetables - full portion', 240, 'Veg Main Course', true),
    (cafe_id, 'Bhindi Masala (Half)', 'Spiced okra - half portion', 150, 'Veg Main Course', true),
    (cafe_id, 'Bhindi Masala (Full)', 'Spiced okra - full portion', 220, 'Veg Main Course', true),
    (cafe_id, 'Bhindi Do Pyaza (Half)', 'Okra with double onions - half portion', 140, 'Veg Main Course', true),
    (cafe_id, 'Bhindi Do Pyaza (Full)', 'Okra with double onions - full portion', 210, 'Veg Main Course', true),
    (cafe_id, 'Sev Tamatar (Half)', 'Crispy sev with tomatoes - half portion', 150, 'Veg Main Course', true),
    (cafe_id, 'Sev Tamatar (Full)', 'Crispy sev with tomatoes - full portion', 220, 'Veg Main Course', true),
    (cafe_id, 'Sev Bhaji (Half)', 'Crispy sev curry - half portion', 180, 'Veg Main Course', true),
    (cafe_id, 'Sev Bhaji (Full)', 'Crispy sev curry - full portion', 240, 'Veg Main Course', true),
    (cafe_id, 'Veg Kolhapuri (Half)', 'Spicy vegetable kolhapuri - half portion', 180, 'Veg Main Course', true),
    (cafe_id, 'Veg Kolhapuri (Full)', 'Spicy vegetable kolhapuri - full portion', 260, 'Veg Main Course', true),
    (cafe_id, 'Veg Jaipuri (Half)', 'Vegetable jaipuri - half portion', 190, 'Veg Main Course', true),
    (cafe_id, 'Veg Jaipuri (Full)', 'Vegetable jaipuri - full portion', 270, 'Veg Main Course', true);

    -- ========================================
    -- MAIN COURSE (VEG) - OTHER
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Kashmiri Dum Aloo (Half)', 'Kashmiri style potatoes - half portion', 200, 'Veg Main Course', true),
    (cafe_id, 'Kashmiri Dum Aloo (Full)', 'Kashmiri style potatoes - full portion', 280, 'Veg Main Course', true),
    (cafe_id, 'Kaju Curry (Half)', 'Cashew curry - half portion', 220, 'Veg Main Course', true),
    (cafe_id, 'Kaju Curry (Full)', 'Cashew curry - full portion', 300, 'Veg Main Course', true),
    (cafe_id, 'Cheese Corn Masala (Half)', 'Cheese corn masala - half portion', 210, 'Veg Main Course', true),
    (cafe_id, 'Cheese Corn Masala (Full)', 'Cheese corn masala - full portion', 300, 'Veg Main Course', true);

    -- ========================================
    -- DAL DARSHAN
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Dal Maharani (Half)', 'Royal dal makhni - half portion', 190, 'Dal Darshan', true),
    (cafe_id, 'Dal Maharani (Full)', 'Royal dal makhni - full portion', 260, 'Dal Darshan', true),
    (cafe_id, 'Dal Dhaba (Half)', 'Dhaba style dal - half portion', 170, 'Dal Darshan', true),
    (cafe_id, 'Dal Dhaba (Full)', 'Dhaba style dal - full portion', 210, 'Dal Darshan', true),
    (cafe_id, 'Dal Lehsuni (Half)', 'Garlic dal - half portion', 170, 'Dal Darshan', true),
    (cafe_id, 'Dal Lehsuni (Full)', 'Garlic dal - full portion', 210, 'Dal Darshan', true),
    (cafe_id, 'Dal Tadka (Half)', 'Tempered dal - half portion', 160, 'Dal Darshan', true),
    (cafe_id, 'Dal Tadka (Full)', 'Tempered dal - full portion', 210, 'Dal Darshan', true),
    (cafe_id, 'Dal Fry (Half)', 'Fried dal - half portion', 160, 'Dal Darshan', true),
    (cafe_id, 'Dal Fry (Full)', 'Fried dal - full portion', 210, 'Dal Darshan', true);

    -- ========================================
    -- RICE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Navaratna Pulao', 'Nine-gem rice pulao', 280, 'Rice', true),
    (cafe_id, 'Jeera Rice', 'Cumin rice', 200, 'Rice', true),
    (cafe_id, 'Plain Rice', 'Plain steamed rice', 180, 'Rice', true),
    (cafe_id, 'Masala Rice', 'Spiced rice', 220, 'Rice', true),
    (cafe_id, 'Paneer Bhurji Pulao', 'Paneer bhurji rice', 240, 'Rice', true),
    (cafe_id, 'Dal Khichdi', 'Lentil rice khichdi', 200, 'Rice', true),
    (cafe_id, 'Curd Rice', 'Yogurt rice', 210, 'Rice', true);

    -- ========================================
    -- BIRYANI (VEG)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Biryani', 'Vegetable biryani', 260, 'Veg Biryani', true),
    (cafe_id, 'Kolkata Sabz Biryani', 'Kolkata style vegetable biryani', 280, 'Veg Biryani', true),
    (cafe_id, 'Paneer Tikka Biryani', 'Paneer tikka biryani', 280, 'Veg Biryani', true),
    (cafe_id, 'Hyderabadi Biryani', 'Hyderabadi style biryani', 270, 'Veg Biryani', true);

    -- ========================================
    -- MAIN COURSE (NON-VEG) - INDIAN GRAVY
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Butter Chicken (Bone) (Half)', 'Butter chicken with bone - half portion', 410, 'Non-Veg Main Course', true),
    (cafe_id, 'Butter Chicken (Bone) (Full)', 'Butter chicken with bone - full portion', 620, 'Non-Veg Main Course', true),
    (cafe_id, 'Butter Chicken (Boneless) (Half)', 'Butter chicken boneless - half portion', 430, 'Non-Veg Main Course', true),
    (cafe_id, 'Butter Chicken (Boneless) (Full)', 'Butter chicken boneless - full portion', 640, 'Non-Veg Main Course', true),
    (cafe_id, 'Chicken Tikka Masala (Half)', 'Chicken tikka masala - half portion', 410, 'Non-Veg Main Course', true),
    (cafe_id, 'Chicken Tikka Masala (Full)', 'Chicken tikka masala - full portion', 630, 'Non-Veg Main Course', true),
    (cafe_id, 'Chicken Patiala (Half)', 'Chicken patiala - half portion', 380, 'Non-Veg Main Course', true),
    (cafe_id, 'Chicken Patiala (Full)', 'Chicken patiala - full portion', 600, 'Non-Veg Main Course', true),
    (cafe_id, 'Chicken Rara (Half)', 'Chicken rara - half portion', 400, 'Non-Veg Main Course', true),
    (cafe_id, 'Chicken Rara (Full)', 'Chicken rara - full portion', 600, 'Non-Veg Main Course', true),
    (cafe_id, 'Chicken Champaran (Half)', 'Chicken champaran - half portion', 360, 'Non-Veg Main Course', true),
    (cafe_id, 'Chicken Champaran (Full)', 'Chicken champaran - full portion', 560, 'Non-Veg Main Course', true),
    (cafe_id, 'Kolkata Chicken (Half)', 'Kolkata style chicken - half portion', 410, 'Non-Veg Main Course', true),
    (cafe_id, 'Kolkata Chicken (Full)', 'Kolkata style chicken - full portion', 620, 'Non-Veg Main Course', true),
    (cafe_id, 'Chicken Kadhai (Half)', 'Chicken kadhai - half portion', 400, 'Non-Veg Main Course', true),
    (cafe_id, 'Chicken Kadhai (Full)', 'Chicken kadhai - full portion', 610, 'Non-Veg Main Course', true),
    (cafe_id, 'Methi Murgh (Half)', 'Fenugreek chicken - half portion', 400, 'Non-Veg Main Course', true),
    (cafe_id, 'Methi Murgh (Full)', 'Fenugreek chicken - full portion', 600, 'Non-Veg Main Course', true),
    (cafe_id, 'Hyderabadi Mutton Keema (Half)', 'Hyderabadi mutton keema - half portion', 650, 'Non-Veg Main Course', true),
    (cafe_id, 'Hyderabadi Mutton Keema (Full)', 'Hyderabadi mutton keema - full portion', 980, 'Non-Veg Main Course', true),
    (cafe_id, 'Lal Mass (Half)', 'Red mutton curry - half portion', 600, 'Non-Veg Main Course', true),
    (cafe_id, 'Lal Mass (Full)', 'Red mutton curry - full portion', 980, 'Non-Veg Main Course', true),
    (cafe_id, 'Mutton Curry (Half)', 'Traditional mutton curry - half portion', 600, 'Non-Veg Main Course', true),
    (cafe_id, 'Mutton Curry (Full)', 'Traditional mutton curry - full portion', 980, 'Non-Veg Main Course', true),
    (cafe_id, 'Mutton Rogan Josh (Half)', 'Mutton rogan josh - half portion', 600, 'Non-Veg Main Course', true),
    (cafe_id, 'Mutton Rogan Josh (Full)', 'Mutton rogan josh - full portion', 980, 'Non-Veg Main Course', true),
    (cafe_id, 'Egg Curry', 'Egg curry', 260, 'Non-Veg Main Course', true),
    (cafe_id, 'Egg Bhurji', 'Scrambled egg curry', 220, 'Non-Veg Main Course', true);

    -- ========================================
    -- BIRYANI (NON-VEG)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Hyderabadi Dum Murg Biryani (Half)', 'Hyderabadi chicken biryani - half portion', 250, 'Non-Veg Biryani', true),
    (cafe_id, 'Hyderabadi Dum Murg Biryani (Full)', 'Hyderabadi chicken biryani - full portion', 360, 'Non-Veg Biryani', true),
    (cafe_id, 'Chicken Tikka Biryani (Half)', 'Chicken tikka biryani - half portion', 270, 'Non-Veg Biryani', true),
    (cafe_id, 'Chicken Tikka Biryani (Full)', 'Chicken tikka biryani - full portion', 380, 'Non-Veg Biryani', true),
    (cafe_id, 'Egg Biryani (Half)', 'Egg biryani - half portion', 200, 'Non-Veg Biryani', true),
    (cafe_id, 'Egg Biryani (Full)', 'Egg biryani - full portion', 270, 'Non-Veg Biryani', true),
    (cafe_id, 'Mutton Keema Pulao (Half)', 'Mutton keema pulao - half portion', 280, 'Non-Veg Biryani', true),
    (cafe_id, 'Mutton Keema Pulao (Full)', 'Mutton keema pulao - full portion', 400, 'Non-Veg Biryani', true);

    RAISE NOTICE 'COOK HOUSE restaurant with comprehensive multi-cuisine menu added successfully';
END $$;
