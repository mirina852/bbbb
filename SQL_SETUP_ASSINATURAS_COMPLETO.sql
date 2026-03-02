-- ============================================
-- SETUP COMPLETO DE ASSINATURAS
-- Execute no Supabase SQL Editor
-- ============================================

-- 1. CRIAR TABELA DE PLANOS
-- ============================================
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  price DECIMAL(10,2) NOT NULL,
  duration_days INTEGER NOT NULL,
  is_trial BOOLEAN DEFAULT false,
  features JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- 2. CRIAR TABELA DE ASSINATURAS DOS USUÁRIOS
-- ============================================
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  plan_id TEXT REFERENCES public.subscription_plans(id) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'expired', 'cancelled')),
  started_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- 3. CRIAR TABELA DE PAGAMENTOS DE ASSINATURA
-- ============================================
CREATE TABLE IF NOT EXISTS public.subscription_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  plan_id TEXT REFERENCES public.subscription_plans(id) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'cancelled', 'expired')),
  payment_method TEXT NOT NULL DEFAULT 'pix',
  
  -- Dados do PIX
  external_payment_id TEXT UNIQUE,
  qr_code TEXT,
  qr_code_base64 TEXT,
  ticket_url TEXT,
  
  -- Metadados
  expires_at TIMESTAMP WITH TIME ZONE,
  paid_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- 4. CRIAR ÍNDICES
-- ============================================
CREATE INDEX IF NOT EXISTS user_subscriptions_user_id_idx ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS user_subscriptions_status_idx ON public.user_subscriptions(status);
CREATE INDEX IF NOT EXISTS user_subscriptions_expires_at_idx ON public.user_subscriptions(expires_at);
CREATE INDEX IF NOT EXISTS subscription_payments_user_id_idx ON public.subscription_payments(user_id);
CREATE INDEX IF NOT EXISTS subscription_payments_status_idx ON public.subscription_payments(status);
CREATE INDEX IF NOT EXISTS subscription_payments_external_id_idx ON public.subscription_payments(external_payment_id);

-- 5. HABILITAR RLS
-- ============================================
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;

-- 6. CRIAR POLÍTICAS RLS
-- ============================================

-- Planos: Qualquer um pode ver
DROP POLICY IF EXISTS "Anyone can view plans" ON public.subscription_plans;
CREATE POLICY "Anyone can view plans"
  ON public.subscription_plans FOR SELECT
  TO authenticated, anon
  USING (true);

-- Assinaturas: Usuários veem suas próprias
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can view own subscriptions"
  ON public.user_subscriptions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can insert own subscriptions"
  ON public.user_subscriptions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can update own subscriptions"
  ON public.user_subscriptions FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Pagamentos: Usuários veem seus próprios
DROP POLICY IF EXISTS "Users can view own payments" ON public.subscription_payments;
CREATE POLICY "Users can view own payments"
  ON public.subscription_payments FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own payments" ON public.subscription_payments;
CREATE POLICY "Users can create own payments"
  ON public.subscription_payments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 7. INSERIR PLANOS PADRÃO
-- ============================================
INSERT INTO public.subscription_plans (id, name, slug, price, duration_days, is_trial, features) VALUES
  ('free', 'Teste Gratuito', 'trial', 0.00, 30, true, '["Acesso completo por 30 dias", "Todos os recursos", "Sem cartão de crédito"]'::jsonb),
  ('monthly', 'Plano Mensal', 'monthly', 29.90, 30, false, '["Acesso completo", "Suporte prioritário", "Atualizações gratuitas"]'::jsonb),
  ('annual', 'Plano Anual', 'annual', 299.90, 365, false, '["Acesso completo", "Suporte VIP", "2 meses grátis", "Atualizações gratuitas"]'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  slug = EXCLUDED.slug,
  price = EXCLUDED.price,
  duration_days = EXCLUDED.duration_days,
  is_trial = EXCLUDED.is_trial,
  features = EXCLUDED.features;

-- 8. CRIAR FUNÇÕES RPC
-- ============================================

-- Função: Obter assinatura ativa
DROP FUNCTION IF EXISTS public.get_active_subscription(uuid);
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

-- Função: Verificar se tem assinatura ativa
DROP FUNCTION IF EXISTS public.has_active_subscription(uuid);
CREATE OR REPLACE FUNCTION public.has_active_subscription(_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_subscriptions
    WHERE user_id = _user_id
      AND status = 'active'
      AND expires_at > now()
  )
$$;

-- Função: Verificar se já usou trial
DROP FUNCTION IF EXISTS public.has_used_trial(uuid);
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
    WHERE us.user_id = _user_id
      AND sp.is_trial = true
  )
$$;

-- Função: Obter planos disponíveis
DROP FUNCTION IF EXISTS public.get_available_plans(uuid);
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
          SELECT 1 
          FROM public.user_subscriptions us
          WHERE us.user_id = _user_id 
            AND us.plan_id = sp.id
        )
      ELSE true
    END as is_available
  FROM public.subscription_plans sp
  ORDER BY sp.price
$$;

-- 9. TRIGGER PARA ATUALIZAR updated_at
-- ============================================
CREATE OR REPLACE FUNCTION public.update_subscription_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_user_subscriptions_updated_at ON public.user_subscriptions;
CREATE TRIGGER update_user_subscriptions_updated_at
  BEFORE UPDATE ON public.user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_subscription_updated_at();

DROP TRIGGER IF EXISTS update_subscription_payments_updated_at ON public.subscription_payments;
CREATE TRIGGER update_subscription_payments_updated_at
  BEFORE UPDATE ON public.subscription_payments
  FOR EACH ROW
  EXECUTE FUNCTION public.update_subscription_updated_at();

-- ============================================
-- VERIFICAÇÃO FINAL
-- ============================================

DO $$
DECLARE
  table_count INTEGER;
  function_count INTEGER;
  plan_count INTEGER;
BEGIN
  -- Contar tabelas
  SELECT COUNT(*) INTO table_count
  FROM information_schema.tables
  WHERE table_schema = 'public'
  AND table_name IN ('subscription_plans', 'user_subscriptions', 'subscription_payments');
  
  -- Contar funções
  SELECT COUNT(*) INTO function_count
  FROM pg_proc
  WHERE proname IN ('get_active_subscription', 'has_active_subscription', 'has_used_trial', 'get_available_plans')
  AND pronamespace = 'public'::regnamespace;
  
  -- Contar planos
  SELECT COUNT(*) INTO plan_count FROM public.subscription_plans;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'VERIFICAÇÃO FINAL - SISTEMA DE ASSINATURAS';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Tabelas criadas: % de 3', table_count;
  RAISE NOTICE '✅ Funções RPC criadas: % de 4', function_count;
  RAISE NOTICE '✅ Planos inseridos: % de 3', plan_count;
  RAISE NOTICE '';
  
  IF table_count = 3 AND function_count = 4 AND plan_count = 3 THEN
    RAISE NOTICE '🎉 SUCESSO! Sistema de assinaturas configurado completamente!';
  ELSE
    RAISE WARNING '⚠️  Alguns itens podem estar faltando. Verifique os logs acima.';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
END $$;
