# Supabase Database Setup for Bank Маннру

This document explains how to set up the Supabase database schema for the Bank Маннру application.

## Prerequisites

1. A Supabase project created at [supabase.com](https://supabase.com)
2. Access to the Supabase SQL Editor in your project dashboard

## Database Schema Setup

### Step 1: Run the SQL Schema

1. Go to your Supabase project dashboard
2. Navigate to the **SQL Editor** in the left sidebar
3. Create a new query
4. Copy and paste the entire content of `supabase_schema.sql` into the editor
5. Click **Run** to execute the schema

This will create all the necessary tables and relationships:

### Tables Created

#### 1. `bank_cards`
Stores user bank cards with the following information:
- Card number, name, type (debit/credit/savings)
- Balance, credit limit, expiry date
- Currency support (RUB, USD, EUR)
- Active/blocked status

#### 2. `transactions`
Records all financial transactions:
- Links to source and destination cards
- Amount, type (debit/credit/transfer)
- Description, status, fees
- Merchant information

#### 3. `accounts`
Banking accounts (checking, savings, deposits):
- Account numbers and balances
- Interest rates for savings accounts
- Minimum balance requirements

#### 4. `user_profiles`
Extended user information:
- Personal details (name, phone, address)
- Employment and income information
- KYC data (passport, occupation)

#### 5. `loan_applications`
Loan application tracking:
- Loan type, amount, term
- Application status and decisions
- Interest rates and approval amounts

#### 6. `contact_requests`
Contact form submissions from the website

#### 7. `newsletter_subscribers`
Email newsletter subscriptions

### Step 2: Verify Row Level Security (RLS)

The schema automatically sets up Row Level Security policies to ensure:
- Users can only access their own data
- Proper authentication is enforced
- Data privacy is maintained

### Step 3: Test the Setup

After running the schema, you can test it by:

1. **Registering a new user** through the registration page
2. **Logging in** and accessing the dashboard
3. **Creating a card** to test the card creation functionality
4. **Making a transfer** to test transaction creation

## Environment Variables

Make sure your `.env` file contains the correct Supabase credentials:

```env
PUBLIC_SUPABASE_URL=your-supabase-project-url
PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
```

## Dashboard Features

Once the database is set up, the dashboard provides:

### 📊 Overview Dashboard
- Total balance across all cards
- Monthly income and expense tracking
- Quick access to common actions

### 💳 Card Management
- View all user cards with balances
- Create new cards (debit, credit, savings)
- Different card types with appropriate limits
- Multi-currency support

### 💸 Transaction Management
- View transaction history
- Make transfers between accounts
- Real-time balance updates
- Transaction categorization

### 🔐 Security Features
- Row Level Security (RLS) for data isolation
- User authentication required for all operations
- Secure session management

## API Integration

The `src/lib/supabase.ts` file provides a comprehensive API layer with functions for:

### Card Operations
```typescript
bankService.getUserCards(userId)
bankService.createCard(cardData)
bankService.updateCardBalance(cardId, newBalance)
```

### Transaction Operations
```typescript
bankService.getUserTransactions(userId, limit)
bankService.createTransaction(transactionData)
```

### User Profile
```typescript
bankService.getUserProfile(userId)
bankService.createUserProfile(profileData)
bankService.updateUserProfile(userId, profileData)
```

## Sample Data

The schema includes some sample data for testing:
- Sample contact requests
- Sample newsletter subscribers

**Note:** Remove the sample data section from the SQL file in production.

## Troubleshooting

### Common Issues

1. **RLS Policies**: If you get permission errors, ensure RLS policies are properly set up
2. **Foreign Key Constraints**: Make sure auth.users table exists (it's automatically created by Supabase Auth)
3. **UUID Generation**: The `gen_random_uuid()` function is built into PostgreSQL 13+

### Verification Queries

Test that tables were created successfully:

```sql
-- Check if tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

## Security Notes

1. **Never expose your service_role key** in frontend code
2. **Always use the anon key** for client-side operations
3. **RLS policies** automatically handle user data isolation
4. **Enable 2FA** on your Supabase account for additional security

## Next Steps

After setting up the database:

1. **Customize the card types** based on your bank's products
2. **Add more transaction categories** for better expense tracking
3. **Implement loan processing workflows**
4. **Add more detailed user profile fields**
5. **Set up email notifications** for transactions

## Support

If you encounter any issues with the database setup:

1. Check the Supabase logs in your project dashboard
2. Verify your RLS policies in the Authentication section
3. Test queries in the SQL Editor
4. Review the API documentation in your project settings

The database is now ready to support a full-featured banking application with secure user data management and comprehensive financial tracking capabilities.
