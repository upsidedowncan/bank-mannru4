-- ===============================================
-- FIX RLS POLICIES FOR ADMIN SYSTEM
-- Run this to fix the access issues
-- ===============================================

-- First, let's make admin_settings readable by everyone (since they're not sensitive)
DROP POLICY IF EXISTS "Admin settings are viewable by everyone" ON admin_settings;
CREATE POLICY "Admin settings are viewable by everyone" ON admin_settings
  FOR SELECT USING (true);

-- Allow admins to update settings
DROP POLICY IF EXISTS "Only admins can modify admin settings" ON admin_settings;
CREATE POLICY "Only admins can modify admin settings" ON admin_settings
  FOR UPDATE USING (
    auth.uid() IN (SELECT user_id FROM admin_users)
  );

-- Fix admin_users policies - allow users to check if they're admin
DROP POLICY IF EXISTS "Admin users are viewable by admins" ON admin_users;
CREATE POLICY "Users can check their own admin status" ON admin_users
  FOR SELECT USING (
    auth.uid() = user_id OR auth.uid() IN (SELECT user_id FROM admin_users)
  );

-- Allow super admins to manage other admins
CREATE POLICY "Super admins can manage admin users" ON admin_users
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM admin_users WHERE role = 'super_admin')
  );

-- Fix user_approvals policies
DROP POLICY IF EXISTS "Users can view their own approval status" ON user_approvals;
DROP POLICY IF EXISTS "Only admins can manage user approvals" ON user_approvals;
DROP POLICY IF EXISTS "Users can insert their own approval request" ON user_approvals;

CREATE POLICY "Users can view their own approval status" ON user_approvals
  FOR SELECT USING (
    auth.uid() = user_id OR auth.uid() IN (SELECT user_id FROM admin_users)
  );

CREATE POLICY "Users can insert their own approval request" ON user_approvals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage user approvals" ON user_approvals
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM admin_users)
  );

-- Test the policies by checking if your user can access admin data
SELECT 
  'Testing admin access for user: ' || auth.uid() as test_message,
  (SELECT COUNT(*) FROM admin_settings) as settings_count,
  (SELECT COUNT(*) FROM admin_users WHERE user_id = auth.uid()) as is_admin,
  (SELECT role FROM admin_users WHERE user_id = auth.uid()) as admin_role;
