-- First, find your user ID from the auth.users table
-- Replace 'your-email@example.com' with your actual email
SELECT id, email FROM auth.users WHERE email = 'your-email@example.com';

-- Then create the admin user (replace YOUR_USER_ID with the actual ID from above)
INSERT INTO admin_users (user_id, role, permissions, created_by) 
VALUES (
  'YOUR_USER_ID_HERE', 
  'super_admin', 
  '{"users": true, "cards": true, "settings": true}',
  'YOUR_USER_ID_HERE'
);

-- Verify the admin was created
SELECT 
  au.*, 
  u.email 
FROM admin_users au 
JOIN auth.users u ON au.user_id = u.id;
