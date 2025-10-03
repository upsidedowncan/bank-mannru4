-- ===============================================
-- CREATE YOUR ADMIN USER
-- Run this AFTER the schema above
-- ===============================================

-- Your user ID from the debug page: 87c476c8-cfa7-49f6-bad6-0c032e039f27
-- Email: utoplennik69pc@gmail.com

INSERT INTO admin_users (user_id, role, permissions, created_by) 
VALUES (
  '87c476c8-cfa7-49f6-bad6-0c032e039f27', 
  'super_admin', 
  '{"users": true, "cards": true, "settings": true}',
  '87c476c8-cfa7-49f6-bad6-0c032e039f27'
);

-- Verify the admin was created
SELECT 
  au.role,
  au.permissions,
  u.email 
FROM admin_users au 
JOIN auth.users u ON au.user_id = u.id
WHERE au.user_id = '87c476c8-cfa7-49f6-bad6-0c032e039f27';
