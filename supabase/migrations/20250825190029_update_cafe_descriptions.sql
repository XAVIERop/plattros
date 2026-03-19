-- Update cafe descriptions to make them consistent in length
-- This will make all three cafe descriptions similar in length (4 lines each)

UPDATE public.cafes 
SET description = 'Delicious momos, Chinese cuisine, and comfort food for every craving. From steamed to fried momos, spicy combos to refreshing soups, crispy appetizers to aromatic rice dishes - everything you need for a perfect meal!'
WHERE name = 'Mini Meals';

UPDATE public.cafes 
SET description = 'Delicious snacks, sweets, and fresh juices to satisfy your cravings. From crispy pani puri to sweet gulab jamun, refreshing juices to tasty chaat - perfect for any time of day!'
WHERE name = 'Munch Box';

UPDATE public.cafes 
SET description = 'Authentic North Indian cuisine with rich flavors and traditional recipes. From creamy dal makhani to aromatic biryani, soft naans to spicy curries - experience the true taste of Punjab!'
WHERE name = 'Punjabi Tadka';

-- Verify the updates
SELECT name, description, LENGTH(description) as desc_length 
FROM public.cafes 
WHERE name IN ('Mini Meals', 'Munch Box', 'Punjabi Tadka')
ORDER BY name;
