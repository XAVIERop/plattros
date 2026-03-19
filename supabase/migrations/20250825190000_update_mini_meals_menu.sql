-- Update Mini Meals menu with new comprehensive menu
-- First, delete existing Mini Meals menu items
DELETE FROM public.menu_items WHERE cafe_id = (SELECT id FROM public.cafes WHERE name = 'Mini Meals');

-- Update cafe phone number and description to match the menu
UPDATE public.cafes 
SET phone = '+91 8112257659',
    description = 'Delicious momos, Chinese cuisine, and comfort food. From steamed to fried momos, spicy combos to refreshing soups - everything you crave!'
WHERE name = 'Mini Meals';

-- Insert new Mini Meals menu items based on the provided menu images

-- Momos Corner (8 pieces)
INSERT INTO public.menu_items (cafe_id, name, description, price, category, preparation_time) VALUES
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Veg Steam Momos', 'Fresh steamed vegetable momos with dipping sauce', 100.00, 'Momos Corner', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Veg Fried Momos', 'Crispy fried vegetable momos with spicy sauce', 140.00, 'Momos Corner', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Paneer Steam Momos', 'Steamed momos filled with fresh paneer', 120.00, 'Momos Corner', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Paneer Fried Momos', 'Crispy fried paneer momos with chutney', 130.00, 'Momos Corner', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Cheese Paneer Steam Momos', 'Steamed momos with cheese and paneer filling', 120.00, 'Momos Corner', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Cheese Paneer Fried Momos', 'Fried momos with cheese and paneer', 140.00, 'Momos Corner', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Steam Momos', 'Steamed chicken momos with herbs', 120.00, 'Momos Corner', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Fried Momos', 'Crispy fried chicken momos', 140.00, 'Momos Corner', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Perry Perry Veg Momos', 'Spicy peri peri vegetable momos', 110.00, 'Momos Corner', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Perry Perry Paneer Momos', 'Spicy peri peri paneer momos', 130.00, 'Momos Corner', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Perry Perry Chicken Momos', 'Spicy peri peri chicken momos', 150.00, 'Momos Corner', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Makhani Chicken Momos', 'Chicken momos in rich makhani gravy', 150.00, 'Momos Corner', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Afghani Veg Momos', 'Creamy afghani style vegetable momos', 130.00, 'Momos Corner', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Afghani Paneer Momos', 'Creamy afghani style paneer momos', 140.00, 'Momos Corner', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Afghani Chicken Momos', 'Creamy afghani style chicken momos', 160.00, 'Momos Corner', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Veg Chill Momos', 'Spicy chilli vegetable momos', 120.00, 'Momos Corner', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Paneer Chill Momos', 'Spicy chilli paneer momos', 140.00, 'Momos Corner', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Chill Momos', 'Spicy chilli chicken momos', 160.00, 'Momos Corner', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Veg Makhani', 'Vegetable momos in makhani gravy', 110.00, 'Momos Corner', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Paneer Makhani', 'Paneer momos in makhani gravy', 130.00, 'Momos Corner', 15);

-- Veg Combos (CHINESE)
INSERT INTO public.menu_items (cafe_id, name, description, price, category, preparation_time) VALUES
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Veg Manchurian + Hakka Noodles', 'Crispy vegetable manchurian with hakka noodles', 170.00, 'Veg Combos', 20),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Veg Manchurian + Garlic Noodles', 'Crispy vegetable manchurian with garlic noodles', 170.00, 'Veg Combos', 20),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Veg Manchurian + Schezwan Noodles', 'Crispy vegetable manchurian with schezwan noodles', 180.00, 'Veg Combos', 20),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chilli Paneer + Hakka Noodles', 'Spicy chilli paneer with hakka noodles', 170.00, 'Veg Combos', 20),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chilli Paneer + Garlic Noodles', 'Spicy chilli paneer with garlic noodles', 170.00, 'Veg Combos', 20),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chilli Paneer + Schezwan Noodles', 'Spicy chilli paneer with schezwan noodles', 180.00, 'Veg Combos', 20);

-- Mini Meals Special
INSERT INTO public.menu_items (cafe_id, name, description, price, category, preparation_time) VALUES
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Mini Meals Special', 'French Fry + Chill Paneer + Noodles/Rice + Cold Drink', 300.00, 'Mini Meals Special', 25);

-- Veg Soups
INSERT INTO public.menu_items (cafe_id, name, description, price, category, preparation_time) VALUES
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Sweet Corn Soup', 'Hot and creamy sweet corn soup', 100.00, 'Veg Soups', 10),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Manchow Soup', 'Spicy and tangy manchow soup', 110.00, 'Veg Soups', 10),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Hot & Sour Soup', 'Traditional hot and sour soup', 100.00, 'Veg Soups', 10),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Lemon Coriander Soup', 'Refreshing lemon coriander soup', 100.00, 'Veg Soups', 10),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Veg Clear Soup', 'Light and healthy clear soup', 100.00, 'Veg Soups', 8);

-- Mini Meals Special Momos
INSERT INTO public.menu_items (cafe_id, name, description, price, category, preparation_time) VALUES
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Veg Delight Momos', 'Special vegetable delight momos', 130.00, 'Mini Meals Special Momos', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Paneer Delight Momos', 'Special paneer delight momos', 140.00, 'Mini Meals Special Momos', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Delight Momos', 'Special chicken delight momos', 160.00, 'Mini Meals Special Momos', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Veg Afghani Momos', 'Creamy afghani vegetable momos', 140.00, 'Mini Meals Special Momos', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Paneer Afghani Momos', 'Creamy afghani paneer momos', 140.00, 'Mini Meals Special Momos', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Veg KFC Momos', 'Korean fried chicken style veg momos', 160.00, 'Mini Meals Special Momos', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Paneer KFC Momos', 'Korean fried chicken style paneer momos', 180.00, 'Mini Meals Special Momos', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken KFC Momos', 'Korean fried chicken style chicken momos', 180.00, 'Mini Meals Special Momos', 15);

-- Non-Veg Soups
INSERT INTO public.menu_items (cafe_id, name, description, price, category, preparation_time) VALUES
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Sweet Corn Soup', 'Creamy chicken sweet corn soup', 150.00, 'Non-Veg Soups', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Hot & Sour Soup', 'Spicy chicken hot and sour soup', 150.00, 'Non-Veg Soups', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Clear Soup', 'Light chicken clear soup', 150.00, 'Non-Veg Soups', 10),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Minced Chicken Coriander Soup', 'Fresh coriander chicken soup', 150.00, 'Non-Veg Soups', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Man Chow Soup', 'Spicy chicken manchow soup', 160.00, 'Non-Veg Soups', 12);

-- Non-Veg Combos
INSERT INTO public.menu_items (cafe_id, name, description, price, category, preparation_time) VALUES
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Manchurian + Fry Rice', 'Crispy chicken manchurian with fried rice', 235.00, 'Non-Veg Combos', 20),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Manchurian + Egg Rice', 'Crispy chicken manchurian with egg rice', 250.00, 'Non-Veg Combos', 20),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chilli Chicken + Noodles/Rice', 'Spicy chilli chicken with noodles or rice', 210.00, 'Non-Veg Combos', 20),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Mini Meals Special Combo', '(4 PCS) Chicken Momos + French Fry + Chill Chicken + Rice Noodles + Cold Drink', 380.00, 'Non-Veg Combos', 25);

-- Noodles/Rice
INSERT INTO public.menu_items (cafe_id, name, description, price, category, preparation_time) VALUES
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Plain Rice', 'Steamed basmati rice', 100.00, 'Noodles/Rice', 8),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Fried Rice', 'Chinese style fried rice', 120.00, 'Noodles/Rice', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Egg Fried Rice', 'Fried rice with scrambled eggs', 140.00, 'Noodles/Rice', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Fried Rice', 'Fried rice with chicken pieces', 150.00, 'Noodles/Rice', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Veg Hakka Noodles', 'Stir-fried hakka noodles with vegetables', 130.00, 'Noodles/Rice', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chowmein', 'Classic chowmein noodles', 120.00, 'Noodles/Rice', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chilli Garlic Noodles', 'Spicy chilli garlic noodles', 130.00, 'Noodles/Rice', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Chilli Garlic Noodles', 'Spicy chilli garlic noodles with chicken', 160.00, 'Noodles/Rice', 15);

-- Veg Appetizers
INSERT INTO public.menu_items (cafe_id, name, description, price, category, preparation_time) VALUES
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Spring Roll', 'Crispy vegetable spring rolls', 110.00, 'Veg Appetizers', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Paneer Spring Roll', 'Crispy paneer spring rolls', 130.00, 'Veg Appetizers', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chilli Potato', 'Spicy chilli potatoes', 150.00, 'Veg Appetizers', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Honey Chilli Potato', 'Sweet and spicy honey chilli potatoes', 160.00, 'Veg Appetizers', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chilli Paneer Dry', 'Spicy dry chilli paneer', 160.00, 'Veg Appetizers', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Gobhi Manchurian Dry', 'Crispy cauliflower manchurian', 170.00, 'Veg Appetizers', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chilli Baby Corn Dry', 'Spicy baby corn appetizer', 170.00, 'Veg Appetizers', 15);

-- Non-Veg Appetizers
INSERT INTO public.menu_items (cafe_id, name, description, price, category, preparation_time) VALUES
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Spring Roll', 'Crispy chicken spring rolls', 150.00, 'Non-Veg Appetizers', 12),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Lollypop', 'Spicy chicken lollypops', 250.00, 'Non-Veg Appetizers', 18),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chilli Chicken Dry', 'Spicy dry chilli chicken', 220.00, 'Non-Veg Appetizers', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Crispy Chicken Wings', 'Crispy fried chicken wings', 240.00, 'Non-Veg Appetizers', 18),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Manchurian Dry', 'Crispy chicken manchurian', 220.00, 'Non-Veg Appetizers', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Honey Chicken', 'Sweet honey glazed chicken', 220.00, 'Non-Veg Appetizers', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Dragon Chicken', 'Spicy dragon style chicken', 220.00, 'Non-Veg Appetizers', 15),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Chicken Hongkong', 'Hongkong style chicken', 250.00, 'Non-Veg Appetizers', 18);
