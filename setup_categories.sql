-- ========================================
-- INSTRUÇÕES: Execute este SQL no Lovable Cloud
-- ========================================
-- 1. Clique em "Manage Cloud" no topo
-- 2. Vá em "Database" > "SQL Editor"
-- 3. Cole e execute este código
-- ========================================

-- Create categories table
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  display_order int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Enable RLS
alter table public.categories enable row level security;

-- Create policies (public read, admin write)
create policy "Anyone can view categories"
  on public.categories for select
  to public
  using (true);

create policy "Authenticated users can insert categories"
  on public.categories for insert
  to authenticated
  with check (true);

create policy "Authenticated users can update categories"
  on public.categories for update
  to authenticated
  using (true);

create policy "Authenticated users can delete categories"
  on public.categories for delete
  to authenticated
  using (true);

-- Insert default categories
insert into public.categories (name, slug, display_order) values
  ('Burger', 'burger', 1),
  ('Pizza', 'pizza', 2),
  ('Churrasco', 'churrasco', 3),
  ('Steak', 'steak', 4),
  ('Drink', 'drink', 5),
  ('Dessert', 'dessert', 6),
  ('Snack', 'snack', 7),
  ('Combo', 'combo', 8)
on conflict (slug) do nothing;

-- Update products table to use text for category instead of enum
-- (This allows dynamic categories)
alter table public.products 
  alter column category type text;
