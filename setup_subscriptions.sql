-- ========================================
-- INSTRUÇÕES: Execute este SQL no Lovable Cloud
-- ========================================
-- 1. Clique em "Manage Cloud" no topo
-- 2. Vá em "Database" > "SQL Editor"
-- 3. Cole e execute este código
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
