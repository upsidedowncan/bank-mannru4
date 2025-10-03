-- ===============================================
-- MARKETPLACE DATABASE SCHEMA
-- Run this in Supabase SQL Editor
-- ===============================================

-- Categories Table
CREATE TABLE IF NOT EXISTS marketplace_categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  icon VARCHAR(100),
  parent_id UUID REFERENCES marketplace_categories(id),
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Items Table
CREATE TABLE IF NOT EXISTS marketplace_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES marketplace_categories(id),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(12,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'МР',
  condition VARCHAR(20) CHECK (condition IN ('new', 'like_new', 'good', 'fair', 'poor')) DEFAULT 'new',
  status VARCHAR(20) CHECK (status IN ('draft', 'active', 'sold', 'removed', 'pending')) DEFAULT 'draft',
  quantity INTEGER DEFAULT 1,
  images JSONB DEFAULT '[]',
  tags TEXT[],
  location VARCHAR(255),
  shipping_available BOOLEAN DEFAULT TRUE,
  shipping_cost DECIMAL(10,2) DEFAULT 0,
  pickup_available BOOLEAN DEFAULT TRUE,
  featured BOOLEAN DEFAULT FALSE,
  views_count INTEGER DEFAULT 0,
  favorites_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Item Images Table
CREATE TABLE IF NOT EXISTS marketplace_item_images (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  item_id UUID REFERENCES marketplace_items(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  alt_text VARCHAR(255),
  is_primary BOOLEAN DEFAULT FALSE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Favorites/Wishlist Table
CREATE TABLE IF NOT EXISTS marketplace_favorites (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id UUID REFERENCES marketplace_items(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, item_id)
);

-- Shopping Cart Table
CREATE TABLE IF NOT EXISTS marketplace_cart (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id UUID REFERENCES marketplace_items(id) ON DELETE CASCADE,
  quantity INTEGER DEFAULT 1,
  added_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, item_id)
);

-- Orders Table
CREATE TABLE IF NOT EXISTS marketplace_orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_number VARCHAR(50) UNIQUE NOT NULL,
  buyer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  total_amount DECIMAL(12,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'МР',
  status VARCHAR(20) CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled', 'refunded')) DEFAULT 'pending',
  payment_method VARCHAR(50),
  payment_card_id UUID REFERENCES bank_cards(id),
  shipping_address JSONB,
  billing_address JSONB,
  shipping_cost DECIMAL(10,2) DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Order Items Table
CREATE TABLE IF NOT EXISTS marketplace_order_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID REFERENCES marketplace_orders(id) ON DELETE CASCADE,
  item_id UUID REFERENCES marketplace_items(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  total_price DECIMAL(12,2) NOT NULL,
  item_snapshot JSONB, -- Store item details at time of purchase
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Reviews Table
CREATE TABLE IF NOT EXISTS marketplace_reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID REFERENCES marketplace_orders(id) ON DELETE CASCADE,
  reviewer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  reviewee_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id UUID REFERENCES marketplace_items(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  title VARCHAR(255),
  comment TEXT,
  is_seller_review BOOLEAN DEFAULT FALSE, -- TRUE if reviewing seller, FALSE if reviewing buyer
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Messages/Chat Table
CREATE TABLE IF NOT EXISTS marketplace_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  item_id UUID REFERENCES marketplace_items(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  recipient_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Insert default categories
INSERT INTO marketplace_categories (name, description, icon, sort_order) VALUES
('Электроника', 'Смартфоны, компьютеры, планшеты и другая техника', 'mdi:laptop', 1),
('Одежда и обувь', 'Мужская и женская одежда, обувь, аксессуары', 'mdi:tshirt-crew', 2),
('Дом и сад', 'Мебель, декор, садовые инструменты', 'mdi:home', 3),
('Транспорт', 'Автомобили, мотоциклы, велосипеды', 'mdi:car', 4),
('Хобби и отдых', 'Спорт, музыка, книги, игры', 'mdi:gamepad-variant', 5),
('Красота и здоровье', 'Косметика, парфюмерия, медицинские товары', 'mdi:heart', 6),
('Детские товары', 'Игрушки, одежда, коляски', 'mdi:baby-carriage', 7),
('Недвижимость', 'Квартиры, дома, коммерческая недвижимость', 'mdi:home-city', 8),
('Услуги', 'Ремонт, доставка, обучение', 'mdi:wrench', 9),
('Разное', 'Прочие товары и услуги', 'mdi:dots-horizontal', 10)
ON CONFLICT DO NOTHING;

-- Enable RLS
ALTER TABLE marketplace_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_item_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_cart ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Categories - viewable by everyone
CREATE POLICY "Categories are viewable by everyone" ON marketplace_categories
  FOR SELECT USING (is_active = true);

CREATE POLICY "Only admins can manage categories" ON marketplace_categories
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM admin_users)
  );

-- Items - viewable by everyone, manageable by owners and admins
CREATE POLICY "Active items are viewable by everyone" ON marketplace_items
  FOR SELECT USING (status = 'active' OR seller_id = auth.uid());

CREATE POLICY "Users can create their own items" ON marketplace_items
  FOR INSERT WITH CHECK (seller_id = auth.uid());

CREATE POLICY "Users can update their own items" ON marketplace_items
  FOR UPDATE USING (seller_id = auth.uid());

CREATE POLICY "Admins can manage all items" ON marketplace_items
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM admin_users)
  );

-- Item Images
CREATE POLICY "Item images are viewable by everyone" ON marketplace_item_images
  FOR SELECT USING (
    item_id IN (SELECT id FROM marketplace_items WHERE status = 'active')
  );

CREATE POLICY "Users can manage images for their items" ON marketplace_item_images
  FOR ALL USING (
    item_id IN (SELECT id FROM marketplace_items WHERE seller_id = auth.uid())
  );

-- Favorites
CREATE POLICY "Users can manage their own favorites" ON marketplace_favorites
  FOR ALL USING (user_id = auth.uid());

-- Cart
CREATE POLICY "Users can manage their own cart" ON marketplace_cart
  FOR ALL USING (user_id = auth.uid());

-- Orders
CREATE POLICY "Users can view their own orders" ON marketplace_orders
  FOR SELECT USING (buyer_id = auth.uid() OR seller_id = auth.uid());

CREATE POLICY "Users can create orders as buyers" ON marketplace_orders
  FOR INSERT WITH CHECK (buyer_id = auth.uid());

CREATE POLICY "Users can update their orders" ON marketplace_orders
  FOR UPDATE USING (buyer_id = auth.uid() OR seller_id = auth.uid());

-- Order Items
CREATE POLICY "Users can view order items for their orders" ON marketplace_order_items
  FOR SELECT USING (
    order_id IN (SELECT id FROM marketplace_orders WHERE buyer_id = auth.uid() OR seller_id = auth.uid())
  );

CREATE POLICY "Users can create order items for their orders" ON marketplace_order_items
  FOR INSERT WITH CHECK (
    order_id IN (SELECT id FROM marketplace_orders WHERE buyer_id = auth.uid())
  );

-- Reviews
CREATE POLICY "Reviews are viewable by everyone" ON marketplace_reviews
  FOR SELECT USING (true);

CREATE POLICY "Users can create reviews for their orders" ON marketplace_reviews
  FOR INSERT WITH CHECK (
    reviewer_id = auth.uid() AND
    order_id IN (SELECT id FROM marketplace_orders WHERE buyer_id = auth.uid() OR seller_id = auth.uid())
  );

-- Messages
CREATE POLICY "Users can view their own messages" ON marketplace_messages
  FOR SELECT USING (sender_id = auth.uid() OR recipient_id = auth.uid());

CREATE POLICY "Users can send messages" ON marketplace_messages
  FOR INSERT WITH CHECK (sender_id = auth.uid());

-- Create triggers for updated_at
CREATE TRIGGER update_marketplace_categories_updated_at 
  BEFORE UPDATE ON marketplace_categories 
  FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_marketplace_items_updated_at 
  BEFORE UPDATE ON marketplace_items 
  FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_marketplace_orders_updated_at 
  BEFORE UPDATE ON marketplace_orders 
  FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_marketplace_reviews_updated_at 
  BEFORE UPDATE ON marketplace_reviews 
  FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Function to generate order numbers
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
BEGIN
  RETURN 'MR-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD((EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT::TEXT, 10, '0');
END;
$$ LANGUAGE plpgsql;

-- Function to update item view count
CREATE OR REPLACE FUNCTION increment_item_views(item_uuid UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE marketplace_items 
  SET views_count = views_count + 1 
  WHERE id = item_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify tables were created
SELECT 
  table_name,
  table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE 'marketplace_%'
ORDER BY table_name;
