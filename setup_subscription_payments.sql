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

-- Política: Admins podem ver todos os pagamentos
drop policy if exists "Admins can view all payments" on public.subscription_payments;
create policy "Admins can view all payments"
  on public.subscription_payments for select
  to authenticated
  using (
    exists (
      select 1 from public.user_roles
      where user_id = auth.uid() and role = 'admin'
    )
  );
