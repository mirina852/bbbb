-- ============================================
-- CONFIGURAÇÃO DE PLANOS DE ASSINATURA
-- Execute no Supabase SQL Editor
-- ============================================

-- 1. CRIAR TABELA DE PLANOS
-- ============================================
DROP TABLE IF EXISTS public.subscription_plans CASCADE;

CREATE TABLE public.subscription_plans (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  price DECIMAL(10,2) NOT NULL,
  duration_days INTEGER NOT NULL,
  is_trial BOOLEAN DEFAULT false,
  features JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- 2. CRIAR TABELA DE ASSINATURAS
-- ============================================
DROP TABLE IF EXISTS public.user_subscriptions CASCADE;

CREATE TABLE public.user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  plan_id TEXT REFERENCES public.subscription_plans(id) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'expired', 'cancelled')),
  started_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- 3. CRIAR TABELA DE PAGAMENTOS
-- ============================================
DROP TABLE IF EXISTS public.subscription_payments CASCADE;

CREATE TABLE public.subscription_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  plan_id TEXT REFERENCES public.subscription_plans(id) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'cancelled', 'expired')),
  payment_method TEXT NOT NULL DEFAULT 'pix',
  external_payment_id TEXT UNIQUE,
  qr_code TEXT,
  qr_code_base64 TEXT,
  ticket_url TEXT,
  expires_at TIMESTAMP WITH TIME ZONE,
  paid_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- 4. ÍNDICES PARA PERFORMANCE
-- ============================================
CREATE INDEX user_subscriptions_user_id_idx ON public.user_subscriptions(user_id);
CREATE INDEX user_subscriptions_status_idx ON public.user_subscriptions(status);
CREATE INDEX user_subscriptions_expires_at_idx ON public.user_subscriptions(expires_at);
CREATE INDEX subscription_payments_user_id_idx ON public.subscription_payments(user_id);
CREATE INDEX subscription_payments_status_idx ON public.subscription_payments(status);

-- 5. RLS POLICIES
-- ============================================
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;

-- Qualquer um pode ver os planos
CREATE POLICY "Planos são públicos"
  ON public.subscription_plans FOR SELECT
  TO public
  USING (true);

-- Usuários veem suas assinaturas
CREATE POLICY "Ver próprias assinaturas"
  ON public.user_subscriptions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Criar própria assinatura"
  ON public.user_subscriptions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Atualizar própria assinatura"
  ON public.user_subscriptions FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Usuários veem seus pagamentos
CREATE POLICY "Ver próprios pagamentos"
  ON public.subscription_payments FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Criar próprio pagamento"
  ON public.subscription_payments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 6. INSERIR 3 PLANOS
-- ============================================
INSERT INTO public.subscription_plans (id, name, slug, price, duration_days, is_trial, features) VALUES
  ('free', 'Teste Gratuito', 'trial', 0.00, 30, true, 
   '["✅ 30 dias grátis", "✅ Acesso completo", "✅ Sem cartão"]'::jsonb),
  
  ('monthly', 'Plano Mensal', 'monthly', 29.90, 30, false, 
   '["✅ Todos os recursos", "✅ Suporte prioritário", "✅ Sem fidelidade"]'::jsonb),
  
  ('annual', 'Plano Anual', 'annual', 299.90, 365, false, 
   '["✅ Todos os recursos", "✅ Suporte VIP", "✅ 2 meses grátis", "✅ Melhor custo-benefício"]'::jsonb);

-- 7. FUNÇÕES RPC
-- ============================================

-- Obter planos disponíveis
CREATE OR REPLACE FUNCTION public.get_available_plans(_user_id uuid DEFAULT NULL)
RETURNS TABLE (
  id text,
  name text,
  slug text,
  price decimal,
  duration_days integer,
  is_trial boolean,
  features jsonb,
  is_available boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT 
    sp.id,
    sp.name,
    sp.slug,
    sp.price,
    sp.duration_days,
    sp.is_trial,
    sp.features,
    CASE 
      WHEN sp.is_trial = true AND _user_id IS NOT NULL THEN 
        NOT EXISTS (
          SELECT 1 FROM public.user_subscriptions us
          WHERE us.user_id = _user_id AND us.plan_id = sp.id
        )
      ELSE true
    END as is_available
  FROM public.subscription_plans sp
  ORDER BY sp.price
$$;

-- Verificar se já usou trial
CREATE OR REPLACE FUNCTION public.has_used_trial(_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_subscriptions us
    JOIN public.subscription_plans sp ON sp.id = us.plan_id
    WHERE us.user_id = _user_id AND sp.is_trial = true
  )
$$;

-- Obter assinatura ativa
CREATE OR REPLACE FUNCTION public.get_active_subscription(_user_id uuid)
RETURNS TABLE (
  id uuid,
  plan_name text,
  plan_slug text,
  status text,
  expires_at timestamptz,
  days_remaining integer
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT 
    us.id,
    sp.name as plan_name,
    sp.slug as plan_slug,
    us.status,
    us.expires_at,
    EXTRACT(day FROM (us.expires_at - now()))::integer as days_remaining
  FROM public.user_subscriptions us
  JOIN public.subscription_plans sp ON sp.id = us.plan_id
  WHERE us.user_id = _user_id
    AND us.status = 'active'
    AND us.expires_at > now()
  ORDER BY us.expires_at DESC
  LIMIT 1
$$;

-- Verificar assinatura ativa
CREATE OR REPLACE FUNCTION public.has_active_subscription(_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_subscriptions
    WHERE user_id = _user_id
      AND status = 'active'
      AND expires_at > now()
  )
$$;

-- 8. TRIGGER UPDATED_AT
-- ============================================
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.subscription_payments
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at();

-- ============================================
-- ✅ VERIFICAÇÃO
-- ============================================
SELECT 
  'Planos cadastrados:' as info,
  COUNT(*) as total
FROM public.subscription_plans;

SELECT * FROM public.subscription_plans ORDER BY price;

-- ============================================
-- 🎉 PRONTO!
-- ============================================
-- Execute no Supabase SQL Editor
-- Os 3 planos estarão disponíveis imediatamente
-- ============================================
