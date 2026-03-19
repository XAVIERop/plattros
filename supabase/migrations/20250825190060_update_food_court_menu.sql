-- Update FOOD COURT menu with new prices and items for MOMO STREET, KRISPP, and GOBBLERS
-- This migration updates existing items and adds new ones based on the latest menu

DO $$
DECLARE
    cafe_id UUID;
BEGIN
    -- Get the cafe ID
    SELECT id INTO cafe_id FROM public.cafes WHERE name = 'FOOD COURT';
    
    -- ========================================
    -- UPDATE KRISPP MENU
    -- ========================================
    
    -- Update KRISPPY NON-VEG prices
    UPDATE public.menu_items SET price = 299 WHERE cafe_id = cafe_id AND name = 'Chicken Hot Wings (6 pcs)';
    UPDATE public.menu_items SET price = 279 WHERE cafe_id = cafe_id AND name = 'Chicken Strips (6 pcs)';
    UPDATE public.menu_items SET price = 199 WHERE cafe_id = cafe_id AND name = 'Garlic Chicken Fingers (6 pcs)';
    UPDATE public.menu_items SET price = 299 WHERE cafe_id = cafe_id AND name = 'Fish Fingers (6 pcs)';
    
    -- Remove Golden Prawns (not in new menu)
    DELETE FROM public.menu_items WHERE cafe_id = cafe_id AND name = 'Golden Prawns (6 pcs)';
    
    -- Update KRISPPY VEG prices
    UPDATE public.menu_items SET price = 199 WHERE cafe_id = cafe_id AND name = 'Pizza Pockets (6 pcs)';
    UPDATE public.menu_items SET price = 149 WHERE cafe_id = cafe_id AND name = 'Veg Strips (6 pcs)';
    UPDATE public.menu_items SET price = 179 WHERE cafe_id = cafe_id AND name = 'Cheesy Strips (6 pcs)';
    UPDATE public.menu_items SET price = 159 WHERE cafe_id = cafe_id AND name = 'Onion Rings (6 pcs)';
    UPDATE public.menu_items SET price = 169 WHERE cafe_id = cafe_id AND name = 'Jalapeno Poppers (6 pcs)';
    
    -- Update KRISPP SNACKS prices
    UPDATE public.menu_items SET price = 119 WHERE cafe_id = cafe_id AND name = 'Chilli Garlic Potato';
    UPDATE public.menu_items SET price = 129 WHERE cafe_id = cafe_id AND name = 'Chicken Popcorn';
    UPDATE public.menu_items SET price = 139 WHERE cafe_id = cafe_id AND name = 'Corn Cheese Nuggets';
    UPDATE public.menu_items SET price = 149 WHERE cafe_id = cafe_id AND name = 'Chicken Nuggets';
    UPDATE public.menu_items SET price = 109 WHERE cafe_id = cafe_id AND name = 'Masala French Fries';
    
    -- Remove Chicken French Fries (not in new menu)
    DELETE FROM public.menu_items WHERE cafe_id = cafe_id AND name = 'Chicken French Fries';
    
    -- Update KRISPP BURGER prices
    UPDATE public.menu_items SET price = 99 WHERE cafe_id = cafe_id AND name = 'Classic Veg Burger';
    UPDATE public.menu_items SET price = 109 WHERE cafe_id = cafe_id AND name = 'Classic Chicken Burger';
    UPDATE public.menu_items SET price = 149 WHERE cafe_id = cafe_id AND name = 'Krisppy Paneer Burger';
    UPDATE public.menu_items SET price = 159 WHERE cafe_id = cafe_id AND name = 'Krisppy Chicken Burger';
    UPDATE public.menu_items SET price = 169 WHERE cafe_id = cafe_id AND name = 'Krisppy Fish Burger';
    
    -- Update KRISPP BEVERAGES prices
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Masala Lemonade' AND category = 'KRISPP - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Cola Lemonade' AND category = 'KRISPP - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Virgin Mojito' AND category = 'KRISPP - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Cucumber Mojito' AND category = 'KRISPP - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Watermelon Mojito' AND category = 'KRISPP - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Green Apple Mojito' AND category = 'KRISPP - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Blue Magic Mojito' AND category = 'KRISPP - Beverages';
    
    -- Add KRISPP Make It A Meal options
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'Veg Upgrade - Chilli Garlic Potato + Any Beverage', 'Veg upgrade combo with chilli garlic potato and any beverage', 159, 'KRISPP - Combos', true),
    (cafe_id, 'Non-Veg Upgrade - Chicken Popcorn + Any Beverage', 'Non-veg upgrade combo with chicken popcorn and any beverage', 169, 'KRISPP - Combos', true);
    
    -- ========================================
    -- UPDATE MOMO STREET MENU
    -- ========================================
    
    -- Update STEAMED MOMOS prices
    UPDATE public.menu_items SET price = 99 WHERE cafe_id = cafe_id AND name = 'Veggie Momos (6 pcs)';
    UPDATE public.menu_items SET price = 109 WHERE cafe_id = cafe_id AND name = 'Paneer Momos (6 pcs)';
    UPDATE public.menu_items SET price = 109 WHERE cafe_id = cafe_id AND name = 'Corn & Cheese Momos (6 pcs)';
    UPDATE public.menu_items SET price = 109 WHERE cafe_id = cafe_id AND name = 'Chicken Momos (6 pcs)';
    UPDATE public.menu_items SET price = 119 WHERE cafe_id = cafe_id AND name = 'Chicken & Cheese Momos (6 pcs)';
    UPDATE public.menu_items SET price = 119 WHERE cafe_id = cafe_id AND name = 'Spicy Chicken Momos (6 pcs)';
    
    -- Update FRIED MOMOS prices
    UPDATE public.menu_items SET price = 119 WHERE cafe_id = cafe_id AND name = 'Veggie Fried Momos (6 pcs)';
    UPDATE public.menu_items SET price = 129 WHERE cafe_id = cafe_id AND name = 'Paneer Fried Momos (6 pcs)';
    UPDATE public.menu_items SET price = 129 WHERE cafe_id = cafe_id AND name = 'Corn & Cheese Fried Momos (6 pcs)';
    UPDATE public.menu_items SET price = 129 WHERE cafe_id = cafe_id AND name = 'Chicken Fried Momos (6 pcs)';
    UPDATE public.menu_items SET price = 139 WHERE cafe_id = cafe_id AND name = 'Chicken & Cheese Fried Momos (6 pcs)';
    UPDATE public.menu_items SET price = 139 WHERE cafe_id = cafe_id AND name = 'Spicy Chicken Fried Momos (6 pcs)';
    
    -- Update KURKURE MOMOS prices
    UPDATE public.menu_items SET price = 129 WHERE cafe_id = cafe_id AND name = 'Veggie Kurkure Momos (6 pcs)';
    UPDATE public.menu_items SET price = 139 WHERE cafe_id = cafe_id AND name = 'Paneer Kurkure Momos (6 pcs)';
    UPDATE public.menu_items SET price = 139 WHERE cafe_id = cafe_id AND name = 'Corn & Cheese Kurkure Momos (6 pcs)';
    UPDATE public.menu_items SET price = 139 WHERE cafe_id = cafe_id AND name = 'Chicken Kurkure Momos (6 pcs)';
    UPDATE public.menu_items SET price = 149 WHERE cafe_id = cafe_id AND name = 'Chicken & Cheese Kurkure Momos (6 pcs)';
    UPDATE public.menu_items SET price = 149 WHERE cafe_id = cafe_id AND name = 'Spicy Chicken Kurkure Momos (6 pcs)';
    
    -- Update GRAVY MOMOS prices
    UPDATE public.menu_items SET price = 139 WHERE cafe_id = cafe_id AND name = 'Veggie Gravy Momos (6 pcs)';
    UPDATE public.menu_items SET price = 149 WHERE cafe_id = cafe_id AND name = 'Paneer Gravy Momos (6 pcs)';
    UPDATE public.menu_items SET price = 149 WHERE cafe_id = cafe_id AND name = 'Corn & Cheese Gravy Momos (6 pcs)';
    UPDATE public.menu_items SET price = 149 WHERE cafe_id = cafe_id AND name = 'Chicken Gravy Momos (6 pcs)';
    UPDATE public.menu_items SET price = 159 WHERE cafe_id = cafe_id AND name = 'Chicken & Cheese Gravy Momos (6 pcs)';
    UPDATE public.menu_items SET price = 159 WHERE cafe_id = cafe_id AND name = 'Spicy Chicken Gravy Momos (6 pcs)';
    
    -- Update MOMO STREET STARTERS prices
    UPDATE public.menu_items SET price = 149 WHERE cafe_id = cafe_id AND name = 'Dosa Spring Roll (6 pcs)';
    UPDATE public.menu_items SET price = 149 WHERE cafe_id = cafe_id AND name = 'Veggie Spring Roll (6 pcs)';
    UPDATE public.menu_items SET price = 189 WHERE cafe_id = cafe_id AND name = 'Chicken Spring Roll (6 pcs)';
    UPDATE public.menu_items SET price = 139 WHERE cafe_id = cafe_id AND name = 'Corn & Cheese Nuggets (6 pcs)';
    UPDATE public.menu_items SET price = 149 WHERE cafe_id = cafe_id AND name = 'Chicken Nuggets (6 pcs)';
    
    -- Update MOMO STREET BEVERAGES prices
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Masala Lemonade' AND category = 'Momo Street - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Cola Lemonade' AND category = 'Momo Street - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Virgin Mojito' AND category = 'Momo Street - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Cucumber Mojito' AND category = 'Momo Street - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Watermelon Mojito' AND category = 'Momo Street - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Green Apple Mojito' AND category = 'Momo Street - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Blue Magic Mojito' AND category = 'Momo Street - Beverages';
    
    -- ========================================
    -- UPDATE GOBBLERS MENU
    -- ========================================
    
    -- Update GOBBLERS BOWLS prices
    UPDATE public.menu_items SET price = 169 WHERE cafe_id = cafe_id AND name = 'Khichdi Bowl';
    UPDATE public.menu_items SET price = 199 WHERE cafe_id = cafe_id AND name = 'Rajma - Rice Bowl';
    UPDATE public.menu_items SET price = 199 WHERE cafe_id = cafe_id AND name = 'Dilli Chola - Rice Bowl';
    UPDATE public.menu_items SET price = 199 WHERE cafe_id = cafe_id AND name = 'Dal Makhni - Rice Bowl';
    UPDATE public.menu_items SET price = 219 WHERE cafe_id = cafe_id AND name = 'Makhni Rice Bowl (Paneer)';
    UPDATE public.menu_items SET price = 229 WHERE cafe_id = cafe_id AND name = 'Makhni Rice Bowl (Chicken)';
    UPDATE public.menu_items SET price = 219 WHERE cafe_id = cafe_id AND name = 'Lahori Rice Bowl (Paneer)';
    UPDATE public.menu_items SET price = 229 WHERE cafe_id = cafe_id AND name = 'Lahori Rice Bowl (Chicken)';
    UPDATE public.menu_items SET price = 219 WHERE cafe_id = cafe_id AND name = 'Chinese Rice Bowl (Paneer)';
    UPDATE public.menu_items SET price = 229 WHERE cafe_id = cafe_id AND name = 'Chinese Rice Bowl (Chicken)';
    UPDATE public.menu_items SET price = 239 WHERE cafe_id = cafe_id AND name = 'Biryani Bowl (Paneer)';
    UPDATE public.menu_items SET price = 249 WHERE cafe_id = cafe_id AND name = 'Biryani Bowl (Chicken)';
    UPDATE public.menu_items SET price = 179 WHERE cafe_id = cafe_id AND name = 'Red Sauce Pasta Bowl';
    UPDATE public.menu_items SET price = 179 WHERE cafe_id = cafe_id AND name = 'White Sauce Pasta Bowl';
    UPDATE public.menu_items SET price = 189 WHERE cafe_id = cafe_id AND name = 'Mix Sauce Pasta Bowl';
    UPDATE public.menu_items SET price = 69 WHERE cafe_id = cafe_id AND name = 'Add On - Chicken';
    
    -- Update GOBBLERS STARTERS prices
    UPDATE public.menu_items SET price = 149 WHERE cafe_id = cafe_id AND name = 'Hara - Bhara Kebab (6 pcs)';
    UPDATE public.menu_items SET price = 159 WHERE cafe_id = cafe_id AND name = 'Dahi Ke Kebab (6 pcs)';
    UPDATE public.menu_items SET price = 189 WHERE cafe_id = cafe_id AND name = 'Corn Cheese Kebab (6 pcs)';
    UPDATE public.menu_items SET price = 179 WHERE cafe_id = cafe_id AND name = 'Chicken Cheese Kebab (6 pcs)';
    
    -- Update GOBBLERS WRAPS prices
    UPDATE public.menu_items SET price = 99 WHERE cafe_id = cafe_id AND name = 'Veg Wrap';
    UPDATE public.menu_items SET price = 119 WHERE cafe_id = cafe_id AND name = 'Paneer Wrap';
    UPDATE public.menu_items SET price = 119 WHERE cafe_id = cafe_id AND name = 'Chicken Wrap';
    UPDATE public.menu_items SET price = 139 WHERE cafe_id = cafe_id AND name = 'Makhni Wrap (Paneer)';
    UPDATE public.menu_items SET price = 139 WHERE cafe_id = cafe_id AND name = 'Makhni Wrap (Chicken)';
    UPDATE public.menu_items SET price = 139 WHERE cafe_id = cafe_id AND name = 'Lahori Wrap (Paneer)';
    UPDATE public.menu_items SET price = 139 WHERE cafe_id = cafe_id AND name = 'Lahori Wrap (Chicken)';
    UPDATE public.menu_items SET price = 139 WHERE cafe_id = cafe_id AND name = 'Schezwan Wrap (Paneer)';
    UPDATE public.menu_items SET price = 139 WHERE cafe_id = cafe_id AND name = 'Schezwan Wrap (Chicken)';
    
    -- Update GOBBLERS BEVERAGES prices
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Masala Lemonade' AND category = 'GOBBLERS - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Cola Lemonade' AND category = 'GOBBLERS - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Virgin Mojito' AND category = 'GOBBLERS - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Cucumber Mojito' AND category = 'GOBBLERS - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Watermelon Mojito' AND category = 'GOBBLERS - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Green Apple Mojito' AND category = 'GOBBLERS - Beverages';
    UPDATE public.menu_items SET price = 89 WHERE cafe_id = cafe_id AND name = 'Blue Magic Mojito' AND category = 'GOBBLERS - Beverages';
    
    RAISE NOTICE 'FOOD COURT menu updated successfully with new prices for MOMO STREET, KRISPP, and GOBBLERS';
END $$;
