-- ===============================================
-- CREATE FUNCTION TO GET ALL USERS WITH PROFILES
-- Run this in Supabase SQL Editor
-- ===============================================

-- Create a function to get all users with their profiles and approval status
CREATE OR REPLACE FUNCTION get_all_users_with_profiles()
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  user_approvals JSONB
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(up.user_id, au.id) as user_id,
    COALESCE(up.email, au.email) as email,
    up.first_name,
    up.last_name,
    up.phone,
    COALESCE(up.created_at, au.created_at) as created_at,
    up.updated_at,
    CASE 
      WHEN ua.id IS NOT NULL THEN
        json_build_object(
          'status', ua.status,
          'approved_at', ua.approved_at,
          'rejection_reason', ua.rejection_reason
        )::jsonb
      ELSE NULL
    END as user_approvals
  FROM auth.users au
  LEFT JOIN user_profiles up ON au.id = up.user_id
  LEFT JOIN user_approvals ua ON au.id = ua.user_id
  ORDER BY COALESCE(up.created_at, au.created_at) DESC;
END;
$$;

-- Create a trigger to automatically create user profiles when users register
CREATE OR REPLACE FUNCTION create_user_profile_on_signup()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO user_profiles (
    user_id,
    email,
    first_name,
    last_name,
    phone
  ) VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', '')
  );
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- If profile creation fails, don't block user creation
    RETURN NEW;
END;
$$;

-- Drop the trigger if it exists and create it
DROP TRIGGER IF EXISTS create_user_profile_trigger ON auth.users;
CREATE TRIGGER create_user_profile_trigger
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_user_profile_on_signup();

-- Create user profile for existing user (your current user)
INSERT INTO user_profiles (
  user_id,
  email,
  first_name,
  last_name,
  phone
) 
SELECT 
  id,
  email,
  COALESCE(raw_user_meta_data->>'first_name', ''),
  COALESCE(raw_user_meta_data->>'last_name', ''),
  COALESCE(raw_user_meta_data->>'phone', '')
FROM auth.users
WHERE id = '87c476c8-cfa7-49f6-bad6-0c032e039f27'
ON CONFLICT (user_id) DO UPDATE SET
  email = EXCLUDED.email,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  phone = EXCLUDED.phone;

-- Verify the profile was created
SELECT 
  up.*,
  au.email as auth_email
FROM user_profiles up
JOIN auth.users au ON up.user_id = au.id
WHERE up.user_id = '87c476c8-cfa7-49f6-bad6-0c032e039f27';
