-- Admin Settings Table
CREATE TABLE admin_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  setting_key VARCHAR(255) UNIQUE NOT NULL,
  setting_value BOOLEAN DEFAULT FALSE,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Insert default settings
INSERT INTO admin_settings (setting_key, setting_value, description) VALUES
('invite_only_mode', FALSE, 'When enabled, new registrations require admin approval'),
('maintenance_mode', FALSE, 'When enabled, site shows maintenance message'),
('allow_card_creation', TRUE, 'When disabled, users cannot create new cards');

-- User Approvals Table
CREATE TABLE user_approvals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL,
  first_name VARCHAR(255),
  last_name VARCHAR(255),
  phone VARCHAR(20),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  approved_by UUID REFERENCES auth.users(id),
  approved_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Admin Users Table (for role management)
CREATE TABLE admin_users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  role VARCHAR(20) DEFAULT 'admin' CHECK (role IN ('admin', 'super_admin')),
  permissions JSONB DEFAULT '{"users": true, "cards": true, "settings": true}',
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- RLS Policies for admin_settings
CREATE POLICY "Admin settings are viewable by everyone" ON admin_settings
  FOR SELECT USING (true);

CREATE POLICY "Only admins can modify admin settings" ON admin_settings
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM admin_users)
  );

-- RLS Policies for user_approvals
CREATE POLICY "Users can view their own approval status" ON user_approvals
  FOR SELECT USING (
    auth.uid() = user_id OR auth.uid() IN (SELECT user_id FROM admin_users)
  );

CREATE POLICY "Only admins can manage user approvals" ON user_approvals
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM admin_users)
  );

CREATE POLICY "Users can insert their own approval request" ON user_approvals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for admin_users
CREATE POLICY "Admin users are viewable by admins" ON admin_users
  FOR SELECT USING (
    auth.uid() IN (SELECT user_id FROM admin_users)
  );

CREATE POLICY "Only super admins can manage admin users" ON admin_users
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM admin_users WHERE role = 'super_admin')
  );

-- Functions
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_admin_settings_updated_at BEFORE UPDATE ON admin_settings FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_user_approvals_updated_at BEFORE UPDATE ON user_approvals FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_admin_users_updated_at BEFORE UPDATE ON admin_users FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM admin_users WHERE user_id = user_uuid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get admin setting
CREATE OR REPLACE FUNCTION get_admin_setting(setting_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  setting_val BOOLEAN;
BEGIN
  SELECT setting_value INTO setting_val 
  FROM admin_settings 
  WHERE setting_key = setting_name;
  
  RETURN COALESCE(setting_val, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
