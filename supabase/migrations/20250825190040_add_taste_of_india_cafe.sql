-- Add Taste of India cafe and all menu items
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
    'Taste of India',
    'North Indian',
    'Authentic Indian cuisine featuring curries, biryanis, and more. Specializing in traditional Indian dishes with a modern twist. From spicy curries to aromatic biryanis, we bring the authentic taste of India to your plate.',
    'B1 First Floor',
    '+91-72970 17744',
    '11:00 AM - 10:00 PM',
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
    SELECT id INTO cafe_id FROM public.cafes WHERE name = 'Taste of India';
    
    -- INDIAN STARTERS
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Harabhara Kabab / Falafel Kabab', 'Fresh green kababs made with spinach and herbs', 150, 'Indian Starters', true),
    (cafe_id, 'Cheese Balls', 'Crispy cheese balls with a golden crust', 160, 'Indian Starters', true),
    (cafe_id, 'Paneer Tikka', 'Marinated cottage cheese grilled to perfection', 230, 'Indian Starters', true),
    (cafe_id, 'Paneer Sashlik / Chicken Sheekh Kabab', 'Skewered paneer or chicken with aromatic spices', 250, 'Indian Starters', true),
    (cafe_id, 'Malai Chicken / Peri Peri Sheekh Kabab', 'Creamy or spicy chicken kababs', 280, 'Indian Starters', true),
    (cafe_id, 'Chicken Tikka', 'Tender chicken marinated in spices and grilled', 280, 'Indian Starters', true),
    (cafe_id, 'Banjara Kabab', 'Rustic style kababs with bold flavors', 290, 'Indian Starters', true),
    (cafe_id, 'Malai Chicken / Peri Peri Chicken Tikka', 'Creamy or spicy chicken tikka', 300, 'Indian Starters', true),
    (cafe_id, 'Chicken Pudina Tikka', 'Mint-flavored chicken tikka', 300, 'Indian Starters', true);

    -- RICE
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Steamed Rice', 'Perfectly cooked white rice', 120, 'Rice', true),
    (cafe_id, 'Jeera Rice', 'Fragrant rice with cumin seeds', 140, 'Rice', true);

    -- ORIENTAL STARTERS
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Spring Roll', 'Crispy vegetable spring rolls', 130, 'Oriental Starters', true),
    (cafe_id, 'Honey Chili Potato', 'Sweet and spicy potato dish', 130, 'Oriental Starters', true),
    (cafe_id, 'Chili Garlic Potato', 'Spicy garlic-flavored potatoes', 140, 'Oriental Starters', true),
    (cafe_id, 'Veg Manchurian Dry', 'Dry vegetable manchurian', 160, 'Oriental Starters', true),
    (cafe_id, 'Veg Szechewan Dry', 'Spicy Szechwan vegetables', 180, 'Oriental Starters', true),
    (cafe_id, 'Chili Paneer/Paneer Salt N Pepper', 'Spicy or seasoned paneer', 200, 'Oriental Starters', true),
    (cafe_id, 'Paneer Manchurian', 'Paneer in manchurian sauce', 200, 'Oriental Starters', true),
    (cafe_id, 'Chili Garlic Paneer', 'Paneer with chili and garlic', 200, 'Oriental Starters', true),
    (cafe_id, 'Chicken Lollypop', 'Crispy chicken lollipops', 220, 'Oriental Starters', true),
    (cafe_id, 'Crispy Fried Chicken', 'Golden fried chicken pieces', 230, 'Oriental Starters', true),
    (cafe_id, 'Dragon Chicken', 'Spicy dragon-style chicken', 230, 'Oriental Starters', true),
    (cafe_id, 'Chili Chicken Dry', 'Dry spicy chicken', 230, 'Oriental Starters', true),
    (cafe_id, 'Hunan Chicken', 'Hunan-style spicy chicken', 230, 'Oriental Starters', true),
    (cafe_id, 'Chicken Taichi', 'Special Taichi chicken preparation', 240, 'Oriental Starters', true),
    (cafe_id, 'Chicken Manchurian', 'Chicken in manchurian sauce', 240, 'Oriental Starters', true),
    (cafe_id, 'Szechwan/Chili Garlic Chicken', 'Spicy Szechwan or chili garlic chicken', 240, 'Oriental Starters', true),
    (cafe_id, 'Chicken Salt N Pepper', 'Seasoned salt and pepper chicken', 240, 'Oriental Starters', true),
    (cafe_id, 'Thai Honey Chilli Chicken', 'Thai-style honey chili chicken', 240, 'Oriental Starters', true),
    (cafe_id, 'Paneer/Chicken 65', 'Spicy 65-style paneer or chicken', 210, 'Oriental Starters', true);

    -- CHAAP STARTERS
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Masala Chaap', 'Spiced soya chaap', 150, 'Chaap Starters', true),
    (cafe_id, 'Malai Chaap / Masala Malai Chaap', 'Creamy or spiced malai chaap', 170, 'Chaap Starters', true),
    (cafe_id, 'Malai Cheese / Masala Cheese Chaap', 'Creamy cheese or spiced cheese chaap', 190, 'Chaap Starters', true),
    (cafe_id, 'Achari Chaap / Haryali Chaap', 'Pickle-flavored or green chaap', 160, 'Chaap Starters', true),
    (cafe_id, 'Peri Peri Chaap', 'Peri peri spiced chaap', 170, 'Chaap Starters', true);

    -- APPETIZERS
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Green Salad', 'Fresh green salad', 90, 'Appetizers', true),
    (cafe_id, 'Kachumbar Salad', 'Traditional Indian salad', 100, 'Appetizers', true),
    (cafe_id, 'Mutter Milk', 'Sweet green pea milk', 50, 'Appetizers', true),
    (cafe_id, 'Lassi', 'Traditional yogurt drink', 70, 'Appetizers', true),
    (cafe_id, 'Roasted Papad', 'Roasted papadum', 30, 'Appetizers', true),
    (cafe_id, 'Fried Papad', 'Fried papadum', 40, 'Appetizers', true),
    (cafe_id, 'Masala Papad', 'Spiced papadum', 60, 'Appetizers', true);

    -- COMBO MEALS
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Dal Combo (Rice / Bread)', 'Dal with rice or bread', 150, 'Combo Meals', true),
    (cafe_id, 'Paneer Combo', 'Paneer dish with accompaniments', 170, 'Combo Meals', true),
    (cafe_id, 'Chicken Combo (Bone / Boneless)', 'Chicken dish with accompaniments', 190, 'Combo Meals', true),
    (cafe_id, 'Sev Tamatar Combo', 'Sev tamatar with accompaniments', 160, 'Combo Meals', true),
    (cafe_id, 'Choley Kulcha', 'Chickpeas with kulcha bread', 130, 'Combo Meals', true),
    (cafe_id, 'Veg Combo', 'Vegetarian combo meal', 160, 'Combo Meals', true),
    (cafe_id, 'Egg Combo', 'Egg dish with accompaniments', 170, 'Combo Meals', true),
    (cafe_id, 'Tandoori Sampler - Veg', 'Assorted vegetarian tandoori items', 250, 'Combo Meals', true),
    (cafe_id, 'Tandoori Sampler - Chicken', 'Assorted chicken tandoori items', 300, 'Combo Meals', true),
    (cafe_id, 'Special Paneer Combo', 'Special paneer combination', 200, 'Combo Meals', true),
    (cafe_id, 'Special Chicken Combo', 'Special chicken combination', 230, 'Combo Meals', true);

    -- BIRYANI
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Biryani', 'Traditional vegetable biryani', 200, 'Biryani', true),
    (cafe_id, 'Paneer Tikka Biryani', 'Biryani with paneer tikka', 240, 'Biryani', true),
    (cafe_id, 'Paneer 65 Biryani', 'Biryani with paneer 65', 250, 'Biryani', true),
    (cafe_id, 'Veg Hyderabadi Biryani', 'Hyderabadi-style vegetable biryani', 220, 'Biryani', true),
    (cafe_id, 'Paneer Achari Biryani', 'Biryani with pickled paneer', 250, 'Biryani', true),
    (cafe_id, 'Egg Biryani', 'Biryani with boiled eggs', 220, 'Biryani', true),
    (cafe_id, 'Chicken Dum Biryani', 'Traditional chicken dum biryani', 240, 'Biryani', true),
    (cafe_id, 'Chicken Tikka Biryani', 'Biryani with chicken tikka', 280, 'Biryani', true),
    (cafe_id, 'Achari Chicken Tikka Biryani', 'Biryani with pickled chicken tikka', 280, 'Biryani', true),
    (cafe_id, 'Chicken 65 Biryani', 'Biryani with chicken 65', 290, 'Biryani', true),
    (cafe_id, 'Chicken Keema Biryani', 'Biryani with minced chicken', 300, 'Biryani', true),
    (cafe_id, 'Lucknowi Chicken Biryani', 'Lucknow-style chicken biryani', 310, 'Biryani', true),
    (cafe_id, 'Awadhi Chicken Biryani', 'Awadhi-style chicken biryani', 310, 'Biryani', true),
    (cafe_id, 'Chicken Achari Biryani', 'Biryani with pickled chicken', 310, 'Biryani', true),
    (cafe_id, 'Hyderabadi Chicken Biryani', 'Hyderabadi-style chicken biryani', 310, 'Biryani', true);

    -- CHAAP GRAVIES
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Masala Chaap', 'Spiced soya chaap gravy', 190, 'Chaap Gravies', true),
    (cafe_id, 'Tawa Chaap Masala', 'Griddle-cooked chaap masala', 200, 'Chaap Gravies', true),
    (cafe_id, 'Chaap Butter Masala', 'Creamy butter masala chaap', 210, 'Chaap Gravies', true),
    (cafe_id, 'Chaap Lababdar', 'Rich and creamy chaap lababdar', 210, 'Chaap Gravies', true),
    (cafe_id, 'Chaap Lazeez', 'Delicious chaap preparation', 210, 'Chaap Gravies', true),
    (cafe_id, 'Kadhai Chaap', 'Kadhai-style chaap', 210, 'Chaap Gravies', true),
    (cafe_id, 'Chaap Bhuna Masala', 'Dry roasted chaap masala', 210, 'Chaap Gravies', true),
    (cafe_id, 'Handi Chaap', 'Handi-style chaap preparation', 210, 'Chaap Gravies', true);

    -- EXTRA
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'S2 Sauce', 'Special S2 sauce', 15, 'Extra', true),
    (cafe_id, 'Extra Onion', 'Additional onions', 10, 'Extra', true),
    (cafe_id, 'Green Chutney', 'Fresh green chutney', 10, 'Extra', true);

    -- INDIAN CURRIES
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Kadhai Mushroom / Mutter Mushroom', 'Kadhai-style mushroom or green pea mushroom', 230, 'Indian Curries', true),
    (cafe_id, 'Jeera Aloo / Aloo Mutter', 'Cumin potatoes or potato with peas', 150, 'Indian Curries', true),
    (cafe_id, 'Mix Veg Jhalfrezi', 'Mixed vegetables in jhalfrezi style', 210, 'Indian Curries', true),
    (cafe_id, 'Sev Tamatar', 'Tomato curry with sev', 180, 'Indian Curries', true),
    (cafe_id, 'Kadhai Paneer', 'Kadhai-style paneer', 280, 'Indian Curries', true),
    (cafe_id, 'Paneer Roganjosh', 'Rich paneer roganjosh', 280, 'Indian Curries', true),
    (cafe_id, 'Paneer Kolhapuri', 'Spicy Kolhapuri paneer', 280, 'Indian Curries', true),
    (cafe_id, 'Paneer Handi / Paneer Butter Masala', 'Handi-style or butter masala paneer', 280, 'Indian Curries', true),
    (cafe_id, 'Paneer Tikka Masala', 'Paneer tikka in masala gravy', 280, 'Indian Curries', true),
    (cafe_id, 'Tawa Paneer Masala', 'Griddle-cooked paneer masala', 280, 'Indian Curries', true),
    (cafe_id, 'Paneer Lazeez', 'Delicious paneer preparation', 290, 'Indian Curries', true),
    (cafe_id, 'Paneer Lababdar', 'Rich and creamy paneer lababdar', 290, 'Indian Curries', true),
    (cafe_id, 'Paneer Peshawari', 'Peshawari-style paneer', 290, 'Indian Curries', true),
    (cafe_id, 'Dal Fry', 'Simple fried lentils', 170, 'Indian Curries', true),
    (cafe_id, 'Dal Tadka', 'Tempered lentils', 190, 'Indian Curries', true),
    (cafe_id, 'Dal Makhani', 'Creamy black lentils', 220, 'Indian Curries', true),
    (cafe_id, 'Chana Masala', 'Spiced chickpeas', 200, 'Indian Curries', true),
    (cafe_id, 'Egg Curry', 'Spicy egg curry', 180, 'Indian Curries', true),
    (cafe_id, 'Chicken Curry', 'Traditional chicken curry', 230, 'Indian Curries', true),
    (cafe_id, 'Chicken Masala', 'Spiced chicken masala', 240, 'Indian Curries', true),
    (cafe_id, 'Kadhai Chicken', 'Kadhai-style chicken', 260, 'Indian Curries', true),
    (cafe_id, 'Butter Chicken', 'Creamy butter chicken', 280, 'Indian Curries', true),
    (cafe_id, 'Chicken Sheekh Kabab Masala', 'Chicken sheekh kabab in masala', 280, 'Indian Curries', true),
    (cafe_id, 'Chicken Kolhapuri', 'Spicy Kolhapuri chicken', 300, 'Indian Curries', true),
    (cafe_id, 'Chicken Tawa Masala', 'Griddle-cooked chicken masala', 300, 'Indian Curries', true),
    (cafe_id, 'Chicken Lababdar', 'Rich and creamy chicken lababdar', 300, 'Indian Curries', true),
    (cafe_id, 'Chicken Handi', 'Handi-style chicken', 270, 'Indian Curries', true),
    (cafe_id, 'Chicken Lazeez', 'Delicious chicken preparation', 300, 'Indian Curries', true),
    (cafe_id, 'Chicken Tikka Masala', 'Chicken tikka in masala gravy', 300, 'Indian Curries', true),
    (cafe_id, 'Murgh Peshawari', 'Peshawari-style chicken', 300, 'Indian Curries', true),
    (cafe_id, 'Chicken Korma', 'Mild and creamy chicken korma', 300, 'Indian Curries', true),
    (cafe_id, 'Chicken Roganjosh', 'Rich chicken roganjosh', 300, 'Indian Curries', true),
    (cafe_id, 'Chicken Keema Masala', 'Minced chicken masala', 300, 'Indian Curries', true),
    (cafe_id, 'Chicken Rara', 'Rara-style chicken preparation', 300, 'Indian Curries', true);

    -- RICE / NOODLES
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Fried Rice', 'Vegetable fried rice', 130, 'Rice/Noodles', true),
    (cafe_id, 'Veg Hakka Noodles', 'Vegetable hakka noodles', 130, 'Rice/Noodles', true),
    (cafe_id, 'Szechwan / Chili Garlic Veg Fried Rice', 'Spicy Szechwan or chili garlic vegetable fried rice', 150, 'Rice/Noodles', true),
    (cafe_id, 'Szechwan / Chili Garlic Veg Noodles', 'Spicy Szechwan or chili garlic vegetable noodles', 150, 'Rice/Noodles', true),
    (cafe_id, 'Egg Fried Rice', 'Egg fried rice', 140, 'Rice/Noodles', true),
    (cafe_id, 'Egg Hakka Noodles', 'Egg hakka noodles', 150, 'Rice/Noodles', true),
    (cafe_id, 'Chicken Fried Rice', 'Chicken fried rice', 180, 'Rice/Noodles', true),
    (cafe_id, 'Szechwan / Chili Garlic Chicken Fried Rice', 'Spicy Szechwan or chili garlic chicken fried rice', 200, 'Rice/Noodles', true),
    (cafe_id, 'Szechwan / Chili Garlic Chicken Noodles', 'Spicy Szechwan or chili garlic chicken noodles', 200, 'Rice/Noodles', true),
    (cafe_id, 'Indo Fried Veg Rice / Noodles', 'Indo-style fried vegetable rice or noodles', 170, 'Rice/Noodles', true),
    (cafe_id, 'Indo Fried Chicken Rice / Noodles', 'Indo-style fried chicken rice or noodles', 210, 'Rice/Noodles', true),
    (cafe_id, 'Burnt Garlic Veg / Chicken Fried Rice', 'Burnt garlic vegetable or chicken fried rice', 170, 'Rice/Noodles', true),
    (cafe_id, 'Burnt Garlic Veg / Chicken Noodles', 'Burnt garlic vegetable or chicken noodles', 170, 'Rice/Noodles', true),
    (cafe_id, 'Paneer Tikka/Chicken Tikka Fried Rice', 'Paneer tikka or chicken tikka fried rice', 180, 'Rice/Noodles', true),
    (cafe_id, 'Hunan Veg / Chicken Fried Rice', 'Hunan-style vegetable or chicken fried rice', 170, 'Rice/Noodles', true),
    (cafe_id, 'Hunan Veg / Chicken Noodles', 'Hunan-style vegetable or chicken noodles', 170, 'Rice/Noodles', true),
    (cafe_id, 'Thai Fried Rice Veg / Chicken', 'Thai-style vegetable or chicken fried rice', 170, 'Rice/Noodles', true),
    (cafe_id, 'Thai Noodles Veg / Chicken', 'Thai-style vegetable or chicken noodles', 170, 'Rice/Noodles', true);

    -- SOUP
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Tomato Soup', 'Fresh tomato soup', 100, 'Soup', true),
    (cafe_id, 'Sweet Corn Veg / Chicken', 'Sweet corn vegetable or chicken soup', 100, 'Soup', true),
    (cafe_id, 'Hot n Sour Veg / Chicken', 'Hot and sour vegetable or chicken soup', 100, 'Soup', true),
    (cafe_id, 'Manchow Veg / Chicken', 'Manchow vegetable or chicken soup', 100, 'Soup', true);

    -- BREAD
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Roti', 'Whole wheat flatbread', 15, 'Bread', true),
    (cafe_id, 'Butter Roti', 'Buttered whole wheat flatbread', 18, 'Bread', true),
    (cafe_id, 'Missi Roti', 'Spiced gram flour flatbread', 20, 'Bread', true),
    (cafe_id, 'Laccha Paratha (Plain / Butter)', 'Layered flatbread plain or with butter', 45, 'Bread', true),
    (cafe_id, 'Naan (Plain / Butter)', 'Leavened flatbread plain or with butter', 50, 'Bread', true),
    (cafe_id, 'Kulcha Roti (Plain / Butter)', 'Leavened bread plain or with butter', 35, 'Bread', true),
    (cafe_id, 'Laccha Naan (Plain / Butter)', 'Layered naan plain or with butter', 60, 'Bread', true),
    (cafe_id, 'Garlic Naan', 'Garlic-flavored naan', 70, 'Bread', true),
    (cafe_id, 'Cheese Naan', 'Cheese-stuffed naan', 90, 'Bread', true),
    (cafe_id, 'Stuffed Paratha (Aloo, Aloo Pyaaz, Mix Veg)', 'Stuffed flatbread with various fillings', 85, 'Bread', true),
    (cafe_id, 'Stuffed Kulcha', 'Stuffed leavened bread', 90, 'Bread', true),
    (cafe_id, 'Paneer Paratha', 'Paneer-stuffed flatbread', 100, 'Bread', true);

    -- RICE / BIRYANI (under Chaap Gravies)
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Soya Chaap Biryani', 'Biryani with soya chaap', 200, 'Rice/Biryani', true),
    (cafe_id, 'Soya Tikka Biryani', 'Biryani with soya tikka', 210, 'Rice/Biryani', true),
    (cafe_id, 'Achari Soya Biryani', 'Biryani with pickled soya', 210, 'Rice/Biryani', true),
    (cafe_id, 'Hyderabadi Soya Biryani', 'Hyderabadi-style soya biryani', 220, 'Rice/Biryani', true);

    -- BEVERAGES
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Lemonade', 'Fresh lemonade', 40, 'Beverages', true),
    (cafe_id, 'Iced Tea', 'Refreshing iced tea', 50, 'Beverages', true),
    (cafe_id, 'Fresh Lime Soda', 'Fresh lime soda', 50, 'Beverages', true),
    (cafe_id, 'Masala Nimbu Soda', 'Spiced lemon soda', 50, 'Beverages', true),
    (cafe_id, 'Cold Coffee', 'Iced coffee', 60, 'Beverages', true),
    (cafe_id, 'Mojito', 'Refreshing mojito', 70, 'Beverages', true),
    (cafe_id, 'Mango / Strawberry', 'Mango or strawberry drink', 80, 'Beverages', true),
    (cafe_id, 'Hazelnut Cold Coffee', 'Hazelnut-flavored iced coffee', 80, 'Beverages', true),
    (cafe_id, 'Blueberry Shake', 'Blueberry milkshake', 80, 'Beverages', true),
    (cafe_id, 'Verry Berry Shake', 'Mixed berry milkshake', 80, 'Beverages', true),
    (cafe_id, 'Black Currant Shake', 'Black currant milkshake', 80, 'Beverages', true),
    (cafe_id, 'Oreo Shake / Chocolate Shake', 'Oreo or chocolate milkshake', 80, 'Beverages', true),
    (cafe_id, 'Brownie Shake', 'Brownie milkshake', 80, 'Beverages', true),
    (cafe_id, 'Chocolate Hazelnut', 'Chocolate hazelnut drink', 90, 'Beverages', true),
    (cafe_id, 'Fruit Punch', 'Mixed fruit punch', 90, 'Beverages', true),
    (cafe_id, 'Frappe - Coffee / Chocolate', 'Coffee or chocolate frappe', 100, 'Beverages', true);

    -- COMBO MEALS (under Rice/Noodles)
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Combo', 'Vegetarian combo meal', 180, 'Combo Meals', true),
    (cafe_id, 'Paneer Combo', 'Paneer combo meal', 200, 'Combo Meals', true),
    (cafe_id, 'Chicken Combo', 'Chicken combo meal', 220, 'Combo Meals', true),
    (cafe_id, 'Chinese Sampler Veg', 'Assorted vegetarian Chinese dishes', 280, 'Combo Meals', true),
    (cafe_id, 'Chinese Sampler Non-Veg', 'Assorted non-vegetarian Chinese dishes', 320, 'Combo Meals', true);

    -- BREAD (under Rice/Biryani)
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Roomali Roti', 'Thin handkerchief bread', 15, 'Bread', true),
    (cafe_id, 'Butter Roomali Roti', 'Buttered thin handkerchief bread', 20, 'Bread', true);

    RAISE NOTICE 'Taste of India cafe and all menu items added successfully';
END $$;
