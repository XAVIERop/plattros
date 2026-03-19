-- Add 'ZAIKA' restaurant with comprehensive multi-cuisine menu
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
    'ZAIKA',
    'Multi-Cuisine',
    'ZAIKA - Where every dish tells a story of authentic flavors! A vibrant restaurant offering an extensive menu featuring starters, rice dishes, noodles, and more. From sizzling starters to aromatic rice preparations, we bring you the perfect blend of taste and tradition with both vegetarian and non-vegetarian delights!',
    'B1 First Floor',
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
    SELECT id INTO cafe_id FROM public.cafes WHERE name = 'ZAIKA';
    
    -- ========================================
    -- STARTERS (VEG)
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'HONEY CHILLI PATATO', 'Crispy potato tossed in honey chilli sauce', 150, 'Starters (Veg)', true),
    (cafe_id, 'DRAGON PATATO', 'Spicy dragon style potato preparation', 140, 'Starters (Veg)', true),
    (cafe_id, 'VEG MUNCHURIAN DRY & GRAVY', 'Vegetable manchurian in dry and gravy style', 165, 'Starters (Veg)', true),
    (cafe_id, 'CHILLY PANEER DRY & GRAVY', 'Paneer in spicy chilli sauce - dry and gravy style', 190, 'Starters (Veg)', true),
    (cafe_id, 'PANEER 65', 'Classic paneer 65 preparation', 190, 'Starters (Veg)', true),
    (cafe_id, 'CRISPY HONEY CHILLI PATATO', 'Extra crispy honey chilli potato', 170, 'Starters (Veg)', true),
    (cafe_id, 'CRISPY CORN', 'Crispy corn preparation', 170, 'Starters (Veg)', true),
    (cafe_id, 'HONEY CHILLY PANEER', 'Paneer tossed in honey chilli sauce', 190, 'Starters (Veg)', true),
    (cafe_id, 'CHILLY MUSHROOM', 'Spicy chilli mushroom', 180, 'Starters (Veg)', true);

    -- ========================================
    -- VEG RICE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'THAI VEG FRIED RICE', 'Thai style vegetable fried rice', 160, 'Veg Rice', true),
    (cafe_id, 'SCHEZWAN VEG FRIED RICE', 'Spicy schezwan vegetable fried rice', 160, 'Veg Rice', true),
    (cafe_id, 'INDO VEG FRIED RICE', 'Indian style vegetable fried rice', 160, 'Veg Rice', true),
    (cafe_id, 'ASIAN VEG FRIED RICE', 'Asian style vegetable fried rice', 160, 'Veg Rice', true),
    (cafe_id, 'BURNT GARLIC VEG FRIED RICE', 'Burnt garlic flavored vegetable fried rice', 160, 'Veg Rice', true),
    (cafe_id, 'VEG CHILLI GARLIC FRIED RICE', 'Spicy chilli garlic vegetable fried rice', 170, 'Veg Rice', true),
    (cafe_id, 'VEG MANCHURIAN FRIED RICE', 'Vegetable manchurian fried rice', 180, 'Veg Rice', true),
    (cafe_id, 'VEG SINGAPURI FRIED RICE', 'Singapore style vegetable fried rice', 180, 'Veg Rice', true);

    -- ========================================
    -- NON VEG
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'CHICKEN 65', 'Classic chicken 65 preparation', 210, 'Non Veg', true),
    (cafe_id, 'CHILLY CHICKEN DRY & GRAVY', 'Spicy chilli chicken in dry and gravy style', 210, 'Non Veg', true),
    (cafe_id, 'HONEY CHILLY CHICKEN', 'Chicken tossed in honey chilli sauce', 200, 'Non Veg', true),
    (cafe_id, 'SCHEZWAN CHICKEN', 'Spicy schezwan chicken', 200, 'Non Veg', true),
    (cafe_id, 'CHICKEN LOLYPOP', 'Chicken lollipop', 200, 'Non Veg', true),
    (cafe_id, 'CRISPY CHICKEN', 'Crispy fried chicken', 200, 'Non Veg', true),
    (cafe_id, 'HUNAN CHICKEN', 'Hunan style chicken preparation', 190, 'Non Veg', true);

    -- ========================================
    -- NON VEG RICE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'THAI CHICKEN FRIED RICE', 'Thai style chicken fried rice', 180, 'Non Veg Rice', true),
    (cafe_id, 'INDO CHICKEN FRIED RICE', 'Indian style chicken fried rice', 180, 'Non Veg Rice', true),
    (cafe_id, 'ASIAN CHICKEN FRIED RICE', 'Asian style chicken fried rice', 180, 'Non Veg Rice', true),
    (cafe_id, 'BURNT GARLIC CHICKEN FRIED RICE', 'Burnt garlic flavored chicken fried rice', 180, 'Non Veg Rice', true),
    (cafe_id, 'SCHEZWAN CHICKEN FRIED RICE', 'Spicy schezwan chicken fried rice', 180, 'Non Veg Rice', true),
    (cafe_id, 'CHICKEN TIKKA FRIED RICE', 'Chicken tikka fried rice', 200, 'Non Veg Rice', true),
    (cafe_id, 'CHILLI GARLIC CHICKEN FRIED RICE', 'Spicy chilli garlic chicken fried rice', 200, 'Non Veg Rice', true),
    (cafe_id, 'CHILLI CHICKEN FRIED RICE', 'Spicy chilli chicken fried rice', 200, 'Non Veg Rice', true);

    -- ========================================
    -- VEG NOODLES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'THAI VEG NOODLE', 'Thai style vegetable noodles', 160, 'Veg Noodles', true),
    (cafe_id, 'VEG HAKKA NOODLE', 'Hakka style vegetable noodles', 160, 'Veg Noodles', true),
    (cafe_id, 'SCHEZWAN VEG NOODLE', 'Spicy schezwan vegetable noodles', 160, 'Veg Noodles', true),
    (cafe_id, 'INDO VEG NOODLE', 'Indian style vegetable noodles', 160, 'Veg Noodles', true),
    (cafe_id, 'BURNT GARLIC VEG NOODLE', 'Burnt garlic flavored vegetable noodles', 160, 'Veg Noodles', true);

    -- ========================================
    -- NON VEG NOODLES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'THAI CHICKEN NOODLE', 'Thai style chicken noodles', 170, 'Non Veg Noodles', true),
    (cafe_id, 'SCHEZWAN CHICKEN NOODLE', 'Spicy schezwan chicken noodles', 170, 'Non Veg Noodles', true),
    (cafe_id, 'INDO CHICKEN NOODLE', 'Indian style chicken noodles', 170, 'Non Veg Noodles', true),
    (cafe_id, 'ASIAN CHICKEN NOODLE', 'Asian style chicken noodles', 170, 'Non Veg Noodles', true),
    (cafe_id, 'BURNT GARLIC CHICKEN NOODLE', 'Burnt garlic flavored chicken noodles', 170, 'Non Veg Noodles', true);

    RAISE NOTICE 'ZAIKA restaurant with comprehensive multi-cuisine menu added successfully';
END $$;
