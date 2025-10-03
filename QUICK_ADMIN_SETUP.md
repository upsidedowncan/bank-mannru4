# Quick Admin Setup Guide

## 🚨 **Issue**: Invite-only mode is ON but you can still register

This happens because:
1. You don't have an admin user set up yet
2. The system needs at least one admin to manage approvals

## ⚡ **Quick Fix Steps:**

### **Step 1: Find Your User ID**

Go to Supabase SQL Editor and run:

```sql
-- Find your user ID (replace with your actual email)
SELECT id, email, created_at 
FROM auth.users 
WHERE email = 'your-email@example.com';
```

Copy the `id` value.

### **Step 2: Create Admin User**

```sql
-- Replace 'YOUR_USER_ID_HERE' with the actual ID from Step 1
INSERT INTO admin_users (user_id, role, permissions, created_by) 
VALUES (
  'YOUR_USER_ID_HERE', 
  'super_admin', 
  '{"users": true, "cards": true, "settings": true}',
  'YOUR_USER_ID_HERE'
);
```

### **Step 3: Verify Setup**

```sql
-- Check if admin was created successfully
SELECT 
  au.role,
  au.permissions,
  u.email 
FROM admin_users au 
JOIN auth.users u ON au.user_id = u.id;
```

### **Step 4: Test**

1. **Go to debug page**: `http://localhost:5174/debug`
2. **Check "Admin Status"** - should show "YES"
3. **Click "Go to Admin Panel"** - should work now
4. **Test registration** - create new account to see approval flow

## 🔍 **Debug Your Current State:**

Visit: `http://localhost:5174/debug`

This page will show you:
- ✅ Current user info
- ✅ Admin status (YES/NO)
- ✅ Invite-only mode status
- ✅ Approval status
- ✅ All system settings

## 🎯 **Expected Behavior After Fix:**

### **With Admin User Created:**
1. **Login** → Should redirect to `/admin` (if you're admin)
2. **Admin Panel** → Should be accessible at `/admin`
3. **New Registrations** → Should require approval when invite-only is ON

### **Registration Flow (Invite-Only ON):**
1. User registers → Creates approval request
2. User redirected to `/pending-approval`
3. Admin approves in admin panel
4. User can then login normally

## 🛠️ **If Still Having Issues:**

### **Check Database Tables:**

```sql
-- Check if tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('admin_settings', 'admin_users', 'user_approvals');

-- Check admin_settings
SELECT * FROM admin_settings;

-- Check admin_users
SELECT * FROM admin_users;
```

### **Reset Invite-Only Mode:**

```sql
-- Temporarily disable invite-only mode for testing
UPDATE admin_settings 
SET setting_value = false 
WHERE setting_key = 'invite_only_mode';
```

## 🎉 **Once Working:**

1. **Admin Panel**: `http://localhost:5174/admin`
2. **Toggle Settings**: Use admin panel to control invite-only mode
3. **Manage Users**: Approve/reject registrations
4. **Control Cards**: Edit balances, limits, etc.

The system should work perfectly once you have an admin user set up!
