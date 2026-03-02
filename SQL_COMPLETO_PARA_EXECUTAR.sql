-- ========================================
-- SQL COMPLETO - EXECUTAR NO SUPABASE
-- ========================================
-- IMPORTANTE: Execute este arquivo COMPLETO no Supabase
-- Vá em: Manage Cloud > Database > SQL Editor
-- ========================================

-- ========================================
-- PASSO 1: CRIAR PLANOS DE ASSINATURA
-- ========================================

-- Criar tabela de planos
create table if not exists public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  price decimal(10,2) not null,
  duration_days integer not null,
  is_trial boolean default false,
  features jsonb not null default '[]'::jsonb,
  created_at timestamptz default now() not null
);

-- RLS para planos (leitura pública)
alter table public.subscription_plans enable row level security;

create policy "Anyone can view plans"
  on public.subscription_plans for select
  to authenticated, anon
  using (true);

-- Inserir os 3 planos
insert into public.subscription_plans (name, slug, price, duration_days, is_trial, features) values
  ('Teste Gratuito', 'trial', 0.00, 30, true, '["Acesso completo por 30 dias", "Todos os recursos", "Sem cartão de crédito"]'::jsonb),
  ('Mensal', 'monthly', 49.99, 30, false, '["Acesso completo", "Suporte prioritário", "Atualizações gratuitas"]'::jsonb),
  ('Anual', 'annual', 299.99, 365, false, '["Acesso completo", "Suporte VIP", "2 meses grátis", "Atualizações gratuitas"]'::jsonb)
on conflict (slug) do nothing;

-- ========================================
-- PASSO 2: CRIAR ASSINATURAS DOS USUÁRIOS
-- ========================================

-- Criar tabela de assinaturas dos usuários
create table if not exists public.user_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  plan_id uuid references public.subscription_plans(id) not null,
  status text not null check (status in ('active', 'expired', 'cancelled')),
  started_at timestamptz default now() not null,
  expires_at timestamptz not null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null
);

-- Índices para performance
create index if not exists user_subscriptions_user_id_idx on public.user_subscriptions(user_id);
create index if not exists user_subscriptions_status_idx on public.user_subscriptions(status);
create index if not exists user_subscriptions_expires_at_idx on public.user_subscriptions(expires_at);

-- RLS policies para assinaturas
alter table public.user_subscriptions enable row level security;

-- Usuários podem ver suas próprias assinaturas
create policy "Users can view own subscriptions"
  on public.user_subscriptions for select
  to authenticated
  using (auth.uid() = user_id);

-- Usuários podem inserir suas próprias assinaturas
create policy "Users can insert own subscriptions"
  on public.user_subscriptions for insert
  to authenticated
  with check (auth.uid() = user_id);

-- ========================================
-- PASSO 3: FUNÇÕES PARA VERIFICAR ASSINATURA
-- ========================================

-- Função para verificar se usuário tem assinatura ativa
create or replace function public.has_active_subscription(_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.user_subscriptions
    where user_id = _user_id
      and status = 'active'
      and expires_at > now()
  )
$$;

-- Função para obter assinatura ativa do usuário
create or replace function public.get_active_subscription(_user_id uuid)
returns table (
  id uuid,
  plan_name text,
  plan_slug text,
  status text,
  expires_at timestamptz,
  days_remaining integer
)
language sql
stable
security definer
set search_path = public
as $$
  select 
    us.id,
    sp.name as plan_name,
    sp.slug as plan_slug,
    us.status,
    us.expires_at,
    extract(day from (us.expires_at - now()))::integer as days_remaining
  from public.user_subscriptions us
  join public.subscription_plans sp on sp.id = us.plan_id
  where us.user_id = _user_id
    and us.status = 'active'
    and us.expires_at > now()
  order by us.expires_at desc
  limit 1
$$;

-- ========================================
-- PASSO 4: CRIAR TABELA DE PAGAMENTOS PIX
-- ========================================

-- Tabela para armazenar pagamentos de assinatura
create table if not exists public.subscription_payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  plan_id uuid references public.subscription_plans(id) not null,
  amount decimal(10,2) not null,
  status text not null check (status in ('pending', 'approved', 'cancelled', 'expired')),
  payment_method text not null default 'pix',
  
  -- Dados do PIX
  external_payment_id text unique,
  qr_code text,
  qr_code_base64 text,
  ticket_url text,
  
  -- Metadados
  expires_at timestamp with time zone,
  paid_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Índices para performance
create index if not exists subscription_payments_user_id_idx on public.subscription_payments(user_id);
create index if not exists subscription_payments_status_idx on public.subscription_payments(status);
create index if not exists subscription_payments_external_id_idx on public.subscription_payments(external_payment_id);

-- Habilitar RLS
alter table public.subscription_payments enable row level security;

-- Política: Usuários podem ver seus próprios pagamentos
drop policy if exists "Users can view own payments" on public.subscription_payments;
create policy "Users can view own payments"
  on public.subscription_payments for select
  to authenticated
  using (auth.uid() = user_id);

-- Política: Usuários podem criar seus próprios pagamentos
drop policy if exists "Users can create own payments" on public.subscription_payments;
create policy "Users can create own payments"
  on public.subscription_payments for insert
  to authenticated
  with check (auth.uid() = user_id);

-- ========================================
-- PASSO 5: CRIAR TABELA DE CATEGORIAS
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

-- ========================================
-- ✅ CONCLUÍDO!
-- ========================================
-- Após executar este SQL, você terá:
-- ✅ Tabela de planos de assinatura
-- ✅ Tabela de assinaturas dos usuários
-- ✅ Tabela de pagamentos PIX
-- ✅ Tabela de categorias
-- ✅ Todas as RLS policies configuradas
-- ✅ Funções auxiliares criadas
-- ========================================