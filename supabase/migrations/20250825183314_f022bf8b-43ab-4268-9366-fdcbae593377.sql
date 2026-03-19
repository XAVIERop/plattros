-- Create enum types for better data integrity
CREATE TYPE block_type AS ENUM ('B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'B8', 'B9', 'B10', 'B11', 'G1', 'G2', 'G3', 'G4', 'G5', 'G6', 'G7');
CREATE TYPE order_status AS ENUM ('received', 'confirmed', 'preparing', 'on_the_way', 'completed', 'cancelled');
CREATE TYPE loyalty_tier AS ENUM ('foodie', 'gourmet', 'connoisseur');

-- Create profiles table for students
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  student_id TEXT UNIQUE,
  block block_type NOT NULL,
  phone TEXT,
  qr_code TEXT UNIQUE NOT NULL DEFAULT gen_random_uuid()::text,
  loyalty_points INTEGER NOT NULL DEFAULT 0,
  loyalty_tier loyalty_tier NOT NULL DEFAULT 'foodie',
  total_orders INTEGER NOT NULL DEFAULT 0,
  total_spent DECIMAL(10,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create cafes table
CREATE TABLE public.cafes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  description TEXT,
  location TEXT NOT NULL,
  phone TEXT NOT NULL,
  hours TEXT NOT NULL,
  image_url TEXT,
  rating DECIMAL(2,1) DEFAULT 0,
  total_reviews INTEGER DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create menu items table
CREATE TABLE public.menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(8,2) NOT NULL,
  category TEXT NOT NULL,
  image_url TEXT,
  is_available BOOLEAN NOT NULL DEFAULT true,
  preparation_time INTEGER DEFAULT 15, -- in minutes
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create orders table
CREATE TABLE public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  cafe_id UUID NOT NULL REFERENCES public.cafes(id) ON DELETE CASCADE,
  order_number TEXT NOT NULL UNIQUE,
  status order_status NOT NULL DEFAULT 'received',
  total_amount DECIMAL(10,2) NOT NULL,
  delivery_block block_type NOT NULL,
  delivery_notes TEXT,
  payment_method TEXT NOT NULL DEFAULT 'cod',
  points_earned INTEGER NOT NULL DEFAULT 0,
  estimated_delivery TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create order items table
CREATE TABLE public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  menu_item_id UUID NOT NULL REFERENCES public.menu_items(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(8,2) NOT NULL,
  total_price DECIMAL(8,2) NOT NULL,
  special_instructions TEXT
);

-- Create loyalty transactions table
CREATE TABLE public.loyalty_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  points_change INTEGER NOT NULL,
  transaction_type TEXT NOT NULL, -- 'earned', 'redeemed', 'bonus'
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cafes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_transactions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for profiles
CREATE POLICY "Users can view their own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Create RLS policies for cafes (public read)
CREATE POLICY "Anyone can view active cafes" ON public.cafes
  FOR SELECT USING (is_active = true);

-- Create RLS policies for menu items (public read)
CREATE POLICY "Anyone can view available menu items" ON public.menu_items
  FOR SELECT USING (is_available = true);

-- Create RLS policies for orders
CREATE POLICY "Users can view their own orders" ON public.orders
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create orders" ON public.orders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own orders" ON public.orders
  FOR UPDATE USING (auth.uid() = user_id);

-- Create RLS policies for order items
CREATE POLICY "Users can view their order items" ON public.order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders 
      WHERE orders.id = order_items.order_id 
      AND orders.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create order items" ON public.order_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders 
      WHERE orders.id = order_items.order_id 
      AND orders.user_id = auth.uid()
    )
  );

-- Create RLS policies for loyalty transactions
CREATE POLICY "Users can view their loyalty transactions" ON public.loyalty_transactions
  FOR SELECT USING (auth.uid() = user_id);

-- Create trigger for updated_at timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_cafes_updated_at BEFORE UPDATE ON public.cafes
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_menu_items_updated_at BEFORE UPDATE ON public.menu_items
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Create function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id, 
    email, 
    full_name,
    block,
    qr_code
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'block')::block_type, 'B1'),
    'QR_' || NEW.id::text
  );
  RETURN NEW;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Create trigger for new user registration
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Insert sample cafes data
INSERT INTO public.cafes (name, type, description, location, phone, hours, rating, total_reviews) VALUES
('Mini Meals', 'Quick Bites', 'Fresh breakfast, sandwiches and coffee to fuel your day', 'B1 Ground Floor, GHS', '+91 98765 43210', '7:00 AM - 11:00 PM', 4.8, 234),
('Punjabi Tadka', 'North Indian', 'Authentic North Indian cuisine with rich flavors', 'G1 Ground Floor, GHS', '+91 98765 43211', '11:00 AM - 10:00 PM', 4.6, 189),
('Munch Box', 'Snacks & Sweets', 'Delicious snacks, sweets and fresh juices', 'G1 Ground Floor, GHS', '+91 98765 43212', '9:00 AM - 12:00 AM', 4.7, 156);

-- Insert sample menu items
INSERT INTO public.menu_items (cafe_id, name, description, price, category) VALUES
-- Mini Meals items
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Grilled Sandwich', 'Fresh vegetables and cheese grilled to perfection', 80.00, 'Breakfast'),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Coffee', 'Hot brewed coffee', 40.00, 'Beverages'),
((SELECT id FROM public.cafes WHERE name = 'Mini Meals'), 'Masala Dosa', 'Crispy dosa with spiced potato filling', 120.00, 'Breakfast'),

-- Punjabi Tadka items
((SELECT id FROM public.cafes WHERE name = 'Punjabi Tadka'), 'Dal Makhani', 'Rich and creamy black lentils', 150.00, 'Main Course'),
((SELECT id FROM public.cafes WHERE name = 'Punjabi Tadka'), 'Butter Naan', 'Soft bread with butter', 45.00, 'Bread'),
((SELECT id FROM public.cafes WHERE name = 'Punjabi Tadka'), 'Biryani', 'Aromatic basmati rice with spices', 180.00, 'Main Course'),

-- Munch Box items
((SELECT id FROM public.cafes WHERE name = 'Munch Box'), 'Pani Puri', 'Crispy puris with tangy water', 60.00, 'Chaat'),
((SELECT id FROM public.cafes WHERE name = 'Munch Box'), 'Fresh Juice', 'Seasonal fruit juice', 50.00, 'Beverages'),
((SELECT id FROM public.cafes WHERE name = 'Munch Box'), 'Gulab Jamun', 'Sweet milk dumplings', 80.00, 'Sweets');

-- Enable realtime for orders table
ALTER TABLE public.orders REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;