-- PaintOps Database Schema
-- Run this SQL to set up the complete database structure

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles table (users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('ceo', 'supervisor', 'painter')),
  phone TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  profile_image_url TEXT,
  hire_date DATE,
  hourly_rate DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Clients table
CREATE TABLE IF NOT EXISTS clients (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Projects table
CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'planning' CHECK (status IN ('planning', 'inprogress', 'completed', 'onhold')),
  budget_amount DECIMAL(12,2) DEFAULT 0,
  actual_costs DECIMAL(12,2) DEFAULT 0,
  start_date DATE,
  end_date DATE,
  image_url TEXT,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Timesheets table
CREATE TABLE IF NOT EXISTS timesheets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  worker_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  description TEXT,
  is_approved BOOLEAN DEFAULT FALSE,
  approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Expenses table
CREATE TABLE IF NOT EXISTS expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  submitted_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  supplier TEXT NOT NULL,
  amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
  category TEXT NOT NULL CHECK (category IN ('materials', 'equipment', 'transportation', 'subcontractor', 'permits', 'other')),
  description TEXT,
  date DATE NOT NULL,
  is_approved BOOLEAN DEFAULT FALSE,
  approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,
  receipt_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Leads table
CREATE TABLE IF NOT EXISTS leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT NOT NULL,
  address TEXT NOT NULL,
  project_type TEXT NOT NULL,
  timeline TEXT NOT NULL,
  message TEXT,
  status TEXT DEFAULT 'newlead' CHECK (status IN ('newlead', 'contacted', 'quoted', 'won', 'lost')),
  contacted_at TIMESTAMPTZ,
  assigned_to UUID REFERENCES profiles(id) ON DELETE SET NULL,
  estimated_value DECIMAL(12,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Landing page content table
CREATE TABLE IF NOT EXISTS landing_page_content (
  id TEXT PRIMARY KEY DEFAULT 'main',
  hero_title TEXT NOT NULL,
  hero_subtitle TEXT NOT NULL,
  hero_primary_cta TEXT NOT NULL,
  hero_secondary_cta TEXT NOT NULL,
  hero_image_url TEXT,
  services JSONB NOT NULL DEFAULT '[]'::jsonb,
  portfolio JSONB NOT NULL DEFAULT '[]'::jsonb,
  business_info JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create storage bucket for images (if using Supabase Storage)
INSERT INTO storage.buckets (id, name, public) VALUES ('landing-page-images', 'landing-page-images', TRUE);
INSERT INTO storage.buckets (id, name, public) VALUES ('receipts', 'receipts', FALSE);
INSERT INTO storage.buckets (id, name, public) VALUES ('project-images', 'project-images', TRUE);
INSERT INTO storage.buckets (id, name, public) VALUES ('profile-images', 'profile-images', FALSE);

-- Row Level Security Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE timesheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE landing_page_content ENABLE ROW LEVEL SECURITY;

-- Basic RLS policies (adjust based on your security requirements)
CREATE POLICY "Enable read access for authenticated users" ON profiles FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON clients FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON projects FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON timesheets FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON expenses FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for authenticated users" ON leads FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Enable read access for landing page content" ON landing_page_content FOR SELECT USING (TRUE);

-- Insert default admin user
INSERT INTO profiles (id, full_name, email, role, is_active) VALUES 
  ('00000000-0000-0000-0000-000000000001', 'System Administrator', 'admin@paintops.com', 'ceo', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Insert default landing page content
INSERT INTO landing_page_content (id, hero_title, hero_subtitle, hero_primary_cta, hero_secondary_cta, business_info) VALUES 
  ('main', 'Transform Your Space with HWR Painting Services', 'Professional painters delivering exceptional results for homes and businesses across Perth', 'Get a Free Quote', 'Schedule an Estimate', '{"name": "HWR Painting Services", "address": "123 Swan Street, Perth WA 6000", "phone": "(08) 9123-4567", "email": "info@hwrpainting.com.au", "hours": "Mon-Fri: 7AM-6PM, Sat: 8AM-4PM"}')
ON CONFLICT (id) DO UPDATE SET 
  hero_title = EXCLUDED.hero_title,
  hero_subtitle = EXCLUDED.hero_subtitle,
  hero_primary_cta = EXCLUDED.hero_primary_cta,
  hero_secondary_cta = EXCLUDED.hero_secondary_cta,
  business_info = EXCLUDED.business_info;
