-- Supabase Database Schema for Bank Dashboard
-- Run this SQL in your Supabase SQL Editor

-- Enable RLS (Row Level Security)
-- This should already be enabled by default in Supabase

-- Create bank_cards table
CREATE TABLE IF NOT EXISTS public.bank_cards (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    card_number VARCHAR(19) NOT NULL UNIQUE,
    card_name VARCHAR(100) NOT NULL,
    card_type VARCHAR(20) NOT NULL CHECK (card_type IN ('debit', 'credit', 'savings')),
    currency VARCHAR(3) NOT NULL DEFAULT 'МР',
    balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    credit_limit DECIMAL(15,2) NULL,
    expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
    cvv VARCHAR(4) NOT NULL DEFAULT '123',
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_blocked BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create transactions table
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    from_card_id UUID REFERENCES public.bank_cards(id) ON DELETE SET NULL,
    to_card_id UUID REFERENCES public.bank_cards(id) ON DELETE SET NULL,
    amount DECIMAL(15,2) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('debit', 'credit', 'transfer')),
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
    recipient_account VARCHAR(50),
    merchant_name VARCHAR(100),
    merchant_category VARCHAR(50),
    transaction_fee DECIMAL(15,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create accounts table (for savings accounts, deposits, etc.)
CREATE TABLE IF NOT EXISTS public.accounts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    account_number VARCHAR(20) NOT NULL UNIQUE,
    account_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(20) NOT NULL CHECK (account_type IN ('checking', 'savings', 'deposit')),
    currency VARCHAR(3) NOT NULL DEFAULT 'МР',
    balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    interest_rate DECIMAL(5,4) DEFAULT 0.0000,
    minimum_balance DECIMAL(15,2) DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create contact_requests table (from your original design)
CREATE TABLE IF NOT EXISTS public.contact_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    message TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'in_progress', 'resolved', 'closed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create newsletter_subscribers table (from your original design)
CREATE TABLE IF NOT EXISTS public.newsletter_subscribers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    subscribed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT true
);

-- Create user_profiles table for extended user information
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    middle_name VARCHAR(50),
    phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    passport_number VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    postal_code VARCHAR(10),
    country VARCHAR(50) DEFAULT 'Russia',
    occupation VARCHAR(100),
    monthly_income DECIMAL(15,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create loan_applications table
CREATE TABLE IF NOT EXISTS public.loan_applications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    loan_type VARCHAR(20) NOT NULL CHECK (loan_type IN ('personal', 'mortgage', 'auto', 'business')),
    requested_amount DECIMAL(15,2) NOT NULL,
    loan_term_months INTEGER NOT NULL,
    purpose TEXT,
    employment_status VARCHAR(50),
    annual_income DECIMAL(15,2),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'disbursed')),
    application_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    decision_date TIMESTAMP WITH TIME ZONE,
    approved_amount DECIMAL(15,2),
    interest_rate DECIMAL(5,4),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bank_cards_user_id ON public.bank_cards(user_id);
CREATE INDEX IF NOT EXISTS idx_bank_cards_card_number ON public.bank_cards(card_number);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_from_card_id ON public.transactions(from_card_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON public.transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON public.accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_loan_applications_user_id ON public.loan_applications(user_id);

-- Add updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Enable Row Level Security (RLS) policies
ALTER TABLE public.bank_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_applications ENABLE ROW LEVEL SECURITY;

-- Contact requests and newsletter don't need RLS as they're not user-specific in the same way
-- But you can add policies if needed for admin access

-- Insert some sample data (optional - for testing)
-- You can remove this section if you don't want sample data

-- This is just for demonstration - remove in production
INSERT INTO public.contact_requests (name, email, message) VALUES
('Иван Петров', 'ivan@example.com', 'Интересует кредит на жилье'),
('Мария Сидорова', 'maria@example.com', 'Вопрос по депозитам')
ON CONFLICT DO NOTHING;

INSERT INTO public.newsletter_subscribers (email) VALUES
('subscriber1@example.com'),
('subscriber2@example.com')
ON CONFLICT DO NOTHING;
