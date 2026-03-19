-- Add 'Havmor' restaurant with comprehensive ice cream and dessert menu
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
    'Havmor',
    'Ice Cream & Desserts',
    'Premium ice cream and dessert destination featuring a wide variety of candies, scoops, sundaes, ice cream cakes, and traditional Indian treats. From classic flavors to innovative combinations, we bring joy through every scoop!',
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
    SELECT id INTO cafe_id FROM public.cafes WHERE name = 'Havmor';
    
    -- ========================================
    -- CANDIES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'ZULUBAR HAZELTELLA', 'Hazelnut chocolate candy bar', 50, 'Candies', true),
    (cafe_id, 'ZULUBAR', 'Classic chocolate candy bar', 45, 'Candies', true),
    (cafe_id, 'ALMOND CHOCOBAR', 'Almond chocolate bar', 60, 'Candies', true),
    (cafe_id, 'CRUNCHY CHOCOBAR', 'Crunchy chocolate bar', 55, 'Candies', true),
    (cafe_id, 'CHOCOBAR (SUGARFREE)', 'Sugar-free chocolate bar', 65, 'Candies', true),
    (cafe_id, 'JUMBO MANGO DOLLY', 'Large mango ice candy', 40, 'Candies', true),
    (cafe_id, 'JUMBO RASPBERRY DOLLY', 'Large raspberry ice candy', 40, 'Candies', true),
    (cafe_id, 'JUMBO CLASSIC CHOCOBAR', 'Large classic chocolate bar', 50, 'Candies', true),
    (cafe_id, 'ROCKY ROAD', 'Rocky road ice cream bar', 55, 'Candies', true),
    (cafe_id, 'MANGO DOLLY', 'Mango ice candy', 30, 'Candies', true),
    (cafe_id, 'CLASSIC CHOCOBAR', 'Classic chocolate bar', 35, 'Candies', true),
    (cafe_id, 'MINI CHOCOBAR', 'Mini chocolate bar', 25, 'Candies', true),
    (cafe_id, 'CHOCO BITE', 'Chocolate bite-sized candy', 20, 'Candies', true),
    (cafe_id, 'LOLLY POP', 'Traditional lollipop', 15, 'Candies', true);

    -- ========================================
    -- ICE CANDIES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'JAL JEERA', 'Spiced jal jeera ice candy', 25, 'Ice Candies', true),
    (cafe_id, 'KACHHA AAM', 'Raw mango ice candy', 30, 'Ice Candies', true),
    (cafe_id, 'ORANGE BAR', 'Orange flavored ice candy', 25, 'Ice Candies', true),
    (cafe_id, 'MASALA WATERMELON', 'Spiced watermelon ice candy', 30, 'Ice Candies', true);

    -- ========================================
    -- SUNDAE CUPS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'CHOCO BROWNIE SUNDAE', 'Chocolate brownie sundae', 120, 'Sundae Cups', true),
    (cafe_id, 'CHOCO SUNDAE', 'Classic chocolate sundae', 100, 'Sundae Cups', true),
    (cafe_id, 'STRAWBERRY SUNDAE', 'Fresh strawberry sundae', 110, 'Sundae Cups', true),
    (cafe_id, 'MANGO SUNDAE', 'Mango flavored sundae', 110, 'Sundae Cups', true);

    -- ========================================
    -- BLOCK BUSTER
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'TRIPLE CHOCOLATE', 'Triple chocolate ice cream', 150, 'Block Buster', true),
    (cafe_id, 'CHOCO TRUFFLE', 'Chocolate truffle ice cream', 160, 'Block Buster', true),
    (cafe_id, 'ALMOND MOCHA', 'Almond mocha ice cream', 140, 'Block Buster', true),
    (cafe_id, 'COOKIE CREAM', 'Cookie and cream ice cream', 130, 'Block Buster', true),
    (cafe_id, 'MANGO MAGIC', 'Mango magic ice cream', 120, 'Block Buster', true);

    -- ========================================
    -- DOUBLE SUNDAE
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'CHOCO BROWNIE DOUBLE SUNDAE', 'Chocolate brownie double sundae', 180, 'Double Sundae', true);

    -- ========================================
    -- SIMPLY TUBS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'HAVMOR KULFI', 'Traditional Havmor kulfi', 200, 'Simply Tubs', true),
    (cafe_id, 'DRYFRUIT MALAI', 'Dry fruit malai ice cream', 220, 'Simply Tubs', true),
    (cafe_id, 'MOCHA BROWNIE FUDGE', 'Mocha brownie fudge ice cream', 180, 'Simply Tubs', true),
    (cafe_id, 'CHOCO BROWNIE', 'Chocolate brownie ice cream', 170, 'Simply Tubs', true);

    -- ========================================
    -- NOVELTIES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'SLICE CASSATA', 'Cassata ice cream slice', 160, 'Novelties', true),
    (cafe_id, 'COOKIE ICE CREAM SANDWICH', 'Cookie ice cream sandwich', 140, 'Novelties', true),
    (cafe_id, 'BLACK FOREST PASTRY', 'Black forest ice cream pastry', 180, 'Novelties', true),
    (cafe_id, 'RAJA RANI ROLL CUT', 'Raja rani ice cream roll', 150, 'Novelties', true),
    (cafe_id, 'SANDWICH ICE CREAM', 'Ice cream sandwich', 130, 'Novelties', true);

    -- ========================================
    -- ICE CREAM CAKES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'HEART BEAT ICE CREAM CAKE', 'Heart beat themed ice cream cake', 800, 'Ice Cream Cakes', true),
    (cafe_id, 'CHOCOLATE FANTASY ICE CREAM CAKE', 'Chocolate fantasy ice cream cake', 750, 'Ice Cream Cakes', true),
    (cafe_id, 'NUTTY CARAMEL ICE CREAM CAKE', 'Nutty caramel ice cream cake', 850, 'Ice Cream Cakes', true),
    (cafe_id, 'COOKIES & CREAM ICE CREAM CAKE', 'Cookies and cream ice cream cake', 700, 'Ice Cream Cakes', true),
    (cafe_id, 'BLACK FOREST ICE CREAM CAKE', 'Black forest ice cream cake', 900, 'Ice Cream Cakes', true),
    (cafe_id, 'GOLDEN FANTASY ICE CREAM CAKE', 'Golden fantasy ice cream cake', 800, 'Ice Cream Cakes', true),
    (cafe_id, 'CHOCOLATE CAKE ICE CREAM', 'Chocolate cake with ice cream', 650, 'Ice Cream Cakes', true),
    (cafe_id, 'ITALIAN CASSATA ICE CREAM CAKE', 'Italian cassata ice cream cake', 950, 'Ice Cream Cakes', true),
    (cafe_id, 'BUTTERSCOTCH COOKIE ICE CREAM CAKE', 'Butterscotch cookie ice cream cake', 750, 'Ice Cream Cakes', true);

    -- ========================================
    -- SUGAR FREE TUBS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'KESAR PISTA SUGAR FREE', 'Kesar pista sugar-free ice cream', 250, 'Sugar Free Tubs', true),
    (cafe_id, 'ANJIR SUGAR FREE', 'Anjeer sugar-free ice cream', 240, 'Sugar Free Tubs', true),
    (cafe_id, 'CRANBERRY SUGAR FREE', 'Cranberry sugar-free ice cream', 230, 'Sugar Free Tubs', true),
    (cafe_id, 'VANILLA SUGAR FREE', 'Vanilla sugar-free ice cream', 200, 'Sugar Free Tubs', true);

    -- ========================================
    -- SCOOPS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'RED VELVET SCOOP', 'Red velvet ice cream scoop', 80, 'Scoops', true),
    (cafe_id, 'TAJ MAHAL SCOOP', 'Taj mahal flavored scoop', 70, 'Scoops', true),
    (cafe_id, 'RAJ BHOG SCOOP', 'Raj bhog flavored scoop', 75, 'Scoops', true),
    (cafe_id, 'KESAR MALTI SCOOP', 'Kesar malti flavored scoop', 80, 'Scoops', true),
    (cafe_id, 'MOCHA BROWNIE FUDGE SCOOP', 'Mocha brownie fudge scoop', 90, 'Scoops', true),
    (cafe_id, 'NUTTY BELGIAN DARK CHOCOLATE SCOOP', 'Nutty Belgian dark chocolate scoop', 100, 'Scoops', true),
    (cafe_id, 'AMERICAN MUD PIE SCOOP', 'American mud pie scoop', 95, 'Scoops', true),
    (cafe_id, 'BLACK CURRENT SCOOP', 'Black currant flavored scoop', 75, 'Scoops', true),
    (cafe_id, 'COOKIE CREAM SCOOP', 'Cookie and cream scoop', 70, 'Scoops', true),
    (cafe_id, 'KESAR PISTA SCOOP', 'Kesar pista flavored scoop', 85, 'Scoops', true),
    (cafe_id, 'AMERICAN NUTS SCOOP', 'American nuts flavored scoop', 90, 'Scoops', true),
    (cafe_id, 'ALMOND CARNIVAL SCOOP', 'Almond carnival flavored scoop', 85, 'Scoops', true),
    (cafe_id, 'GULKAND SCOOP', 'Gulkand flavored scoop', 80, 'Scoops', true),
    (cafe_id, 'TOFFEE COFFEE SCOOP', 'Toffee coffee flavored scoop', 85, 'Scoops', true),
    (cafe_id, 'CREAM N CARAMEL SCOOP', 'Cream and caramel scoop', 80, 'Scoops', true),
    (cafe_id, 'KAJU ANJIR SCOOP', 'Kaju anjeer flavored scoop', 90, 'Scoops', true),
    (cafe_id, 'CHOCOLATE CHIPS SCOOP', 'Chocolate chips scoop', 70, 'Scoops', true),
    (cafe_id, 'KAJU DRAKSH SCOOP', 'Kaju draksh flavored scoop', 85, 'Scoops', true),
    (cafe_id, 'BUTTER SCOTCH SCOOP', 'Butterscotch flavored scoop', 75, 'Scoops', true),
    (cafe_id, 'COFFEE SCOOP', 'Coffee flavored scoop', 70, 'Scoops', true),
    (cafe_id, 'SWISS CAKE SCOOP', 'Swiss cake flavored scoop', 80, 'Scoops', true),
    (cafe_id, 'PINEAPPLE SCOOP', 'Pineapple flavored scoop', 65, 'Scoops', true),
    (cafe_id, 'MAHABLESHWAR STRAWBERRY SCOOP', 'Mahabaleshwar strawberry scoop', 75, 'Scoops', true),
    (cafe_id, 'VANILLA SCOOP', 'Classic vanilla scoop', 60, 'Scoops', true),
    (cafe_id, 'NEW FLAVOR SCOOP', 'New flavor scoop', 70, 'Scoops', true);

    -- ========================================
    -- TOPO CONES
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'DOUBLE BELGIAN CHOCOLATE CONE', 'Double Belgian chocolate cone', 120, 'Topo Cones', true),
    (cafe_id, 'SWISS CHOCO BROWNIE CONE', 'Swiss chocolate brownie cone', 110, 'Topo Cones', true),
    (cafe_id, 'NUTTY FRENCH VANILLA CONE', 'Nutty French vanilla cone', 100, 'Topo Cones', true),
    (cafe_id, 'CHOCO BLOCK CONE', 'Chocolate block cone', 95, 'Topo Cones', true),
    (cafe_id, 'TURBO CHOCOLATE DISC CONE', 'Turbo chocolate disc cone', 105, 'Topo Cones', true),
    (cafe_id, 'DARK CHOCOLATE CONE', 'Dark chocolate cone', 90, 'Topo Cones', true),
    (cafe_id, 'CHOCO BROWNIE CONE', 'Chocolate brownie cone', 100, 'Topo Cones', true),
    (cafe_id, 'KESAR PISTA CONE', 'Kesar pista cone', 110, 'Topo Cones', true),
    (cafe_id, 'BUTTER SCOTCH CONE', 'Butterscotch cone', 85, 'Topo Cones', true),
    (cafe_id, 'CHOCOLATE CONE', 'Classic chocolate cone', 80, 'Topo Cones', true),
    (cafe_id, 'YUMMY STRAWBERRY CONE', 'Yummy strawberry cone', 90, 'Topo Cones', true),
    (cafe_id, 'CHOCO POPS CONE', 'Chocolate pops cone', 95, 'Topo Cones', true),
    (cafe_id, 'HAVMOR BUTTER SCOTCH CONE', 'Havmor butterscotch cone', 100, 'Topo Cones', true),
    (cafe_id, 'CHIC CHOC CONE', 'Chic chocolate cone', 85, 'Topo Cones', true),
    (cafe_id, 'RINGO BINGO CONE', 'Ringo bingo cone', 90, 'Topo Cones', true),
    (cafe_id, 'MAGIC CONE', 'Magic flavored cone', 95, 'Topo Cones', true);

    -- ========================================
    -- KULFIS
    -- ========================================
    INSERT INTO public.menu_items (cafe_id, name, description, price, category, is_available) VALUES
    (cafe_id, 'HAVMOR KULFI SIMPLY TUBS', 'Havmor kulfi in tubs', 180, 'Kulfis', true),
    (cafe_id, 'MATKA KULFI', 'Traditional matka kulfi', 120, 'Kulfis', true),
    (cafe_id, 'DRYFRUIT RABDI KULFI', 'Dry fruit rabdi kulfi', 150, 'Kulfis', true),
    (cafe_id, 'CHOWPATY KULFI', 'Chowpatty style kulfi', 100, 'Kulfis', true),
    (cafe_id, 'MALAI KULFI SUGARFREE', 'Sugar-free malai kulfi', 140, 'Kulfis', true),
    (cafe_id, 'RAJ BHOG KULFI', 'Raj bhog flavored kulfi', 130, 'Kulfis', true),
    (cafe_id, 'MAVA TILLEWALI KULFI', 'Mava til wali kulfi', 110, 'Kulfis', true),
    (cafe_id, 'SHAHI KULFI', 'Shahi kulfi', 160, 'Kulfis', true),
    (cafe_id, 'BOMBAY KULFI', 'Bombay style kulfi', 120, 'Kulfis', true);

    RAISE NOTICE 'Havmor restaurant with comprehensive ice cream and dessert menu added successfully';
END $$;
