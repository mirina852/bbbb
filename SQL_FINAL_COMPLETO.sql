-- ============================================
-- SQL COMPLETO FINAL - TUDO QUE O SITE PRECISA
-- ============================================
-- Execute TODO este SQL de uma vez no Supabase SQL Editor
-- Versão: Multi-Tenant + Assinaturas + RLS

-- ============================================
-- 1. CRIAR TABELA STORES (LOJAS)
-- ============================================
CREATE TABLE IF NOT EXISTS public.stores (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  phone TEXT,
  email TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  logo_url TEXT,
  background_urls TEXT[],
  primary_color TEXT DEFAULT '#FF7A30',
  delivery_fee DECIMAL(10,2) DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  is_open BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS stores_owner_id_idx ON public.stores(owner_id);
CREATE INDEX IF NOT EXISTS stores_slug_idx ON public.stores(slug);

ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Active stores viewable" ON public.stores;
CREATE POLICY "Active stores viewable" ON public.stores FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Owners manage stores" ON public.stores;
CREATE POLICY "Owners manage stores" ON public.stores FOR ALL USING (auth.uid() = owner_id);

-- ============================================
-- 2. CRIAR TABELAS DE ASSINATURAS
-- ============================================

-- Planos de assinatura
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  price DECIMAL(10,2) NOT NULL,
  duration_days INTEGER NOT NULL,
  is_trial BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  features TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS subscription_plans_slug_idx ON public.subscription_plans(slug);

ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Plans viewable by all" ON public.subscription_plans;
CREATE POLICY "Plans viewable by all" ON public.subscription_plans FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Admins manage plans" ON public.subscription_plans;
CREATE POLICY "Admins manage plans" ON public.subscription_plans FOR ALL USING (auth.uid() IS NOT NULL);

-- Assinaturas de usuários
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  subscription_plan_id UUID REFERENCES public.subscription_plans(id) NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS user_subscriptions_user_id_idx ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS user_subscriptions_status_idx ON public.user_subscriptions(status);

ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users view own subscriptions" ON public.user_subscriptions FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users create own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users create own subscriptions" ON public.user_subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users update own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users update own subscriptions" ON public.user_subscriptions FOR UPDATE USING (auth.uid() = user_id);

-- Pagamentos de assinatura
CREATE TABLE IF NOT EXISTS public.subscription_payments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  subscription_id UUID REFERENCES public.user_subscriptions(id) ON DELETE CASCADE NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
  payment_method TEXT DEFAULT 'pix',
  external_payment_id TEXT,
  qr_code TEXT,
  qr_code_base64 TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS subscription_payments_subscription_id_idx ON public.subscription_payments(subscription_id);
CREATE INDEX IF NOT EXISTS subscription_payments_external_id_idx ON public.subscription_payments(external_payment_id);

ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own payments" ON public.subscription_payments;
CREATE POLICY "Users view own payments" ON public.subscription_payments FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.user_subscriptions WHERE user_subscriptions.id = subscription_payments.subscription_id AND user_subscriptions.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users create own payments" ON public.subscription_payments;
CREATE POLICY "Users create own payments" ON public.subscription_payments FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.user_subscriptions WHERE user_subscriptions.id = subscription_payments.subscription_id AND user_subscriptions.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Users update own payments" ON public.subscription_payments;
CREATE POLICY "Users update own payments" ON public.subscription_payments FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.user_subscriptions WHERE user_subscriptions.id = subscription_payments.subscription_id AND user_subscriptions.user_id = auth.uid())
);

-- ============================================
-- 3. ADICIONAR store_id NAS TABELAS EXISTENTES
-- ============================================

ALTER TABLE public.produtos ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;
ALTER TABLE public.categorias ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;
ALTER TABLE public.credenciais_de_pagamento_comercial ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS produtos_store_id_idx ON public.produtos(store_id);
CREATE INDEX IF NOT EXISTS orders_store_id_idx ON public.orders(store_id);
CREATE INDEX IF NOT EXISTS categorias_store_id_idx ON public.categorias(store_id);
CREATE INDEX IF NOT EXISTS credenciais_store_id_idx ON public.credenciais_de_pagamento_comercial(store_id);

-- ============================================
-- 4. CRIAR FUNÇÕES AUXILIARES
-- ============================================

-- Deletar funções antigas se existirem
DROP FUNCTION IF EXISTS public.generate_unique_slug(TEXT);
DROP FUNCTION IF EXISTS public.get_user_store_id();
DROP FUNCTION IF EXISTS public.get_active_subscription(UUID);
DROP FUNCTION IF EXISTS public.has_active_subscription(UUID);

-- Função para gerar slug único
CREATE FUNCTION public.generate_unique_slug(store_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
BEGIN
  base_slug := lower(translate(store_name, 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ', 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'));
  base_slug := regexp_replace(base_slug, '[^a-z0-9]+', '-', 'g');
  base_slug := trim(both '-' from base_slug);
  final_slug := base_slug;
  
  WHILE EXISTS (SELECT 1 FROM public.stores WHERE slug = final_slug) LOOP
    counter := counter + 1;
    final_slug := base_slug || '-' || counter;
  END LOOP;
  
  RETURN final_slug;
END;
$$;

-- Função para obter store_id do usuário
CREATE FUNCTION public.get_user_store_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (
    SELECT id FROM public.stores 
    WHERE owner_id = auth.uid() 
    AND is_active = true
    ORDER BY created_at DESC
    LIMIT 1
  );
END;
$$;

-- Função para buscar assinatura ativa
CREATE FUNCTION public.get_active_subscription(_user_id UUID)
RETURNS TABLE (
  id UUID,
  plan_name TEXT,
  plan_slug TEXT,
  status TEXT,
  expires_at TIMESTAMP WITH TIME ZONE,
  days_remaining INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    us.id,
    sp.name AS plan_name,
    sp.slug AS plan_slug,
    us.status,
    us.expires_at,
    CASE 
      WHEN us.expires_at > NOW() THEN EXTRACT(DAY FROM us.expires_at - NOW())::INTEGER
      ELSE 0
    END AS days_remaining
  FROM public.user_subscriptions us
  JOIN public.subscription_plans sp ON sp.id = us.subscription_plan_id
  WHERE us.user_id = _user_id
    AND us.status = 'active'
    AND us.expires_at > NOW()
  ORDER BY us.expires_at DESC
  LIMIT 1;
END;
$$;

-- Função para verificar se tem assinatura ativa
CREATE FUNCTION public.has_active_subscription(_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_subscriptions
    WHERE user_id = _user_id
      AND status = 'active'
      AND expires_at > NOW()
  );
END;
$$;

-- ============================================
-- 5. INSERIR PLANOS PADRÃO
-- ============================================

-- Plano Gratuito (7 dias)
INSERT INTO public.subscription_plans (id, name, slug, price, duration_days, is_trial, features)
VALUES (
  '1a375586-9c50-49e7-9f47-6656c401988f',
  'Teste Gratuito',
  'free-trial',
  0.00,
  7,
  true,
  ARRAY['Acesso completo por 7 dias', 'Gestão de produtos e pedidos', 'Dashboard com estatísticas', 'Sem compromisso']
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  price = EXCLUDED.price,
  duration_days = EXCLUDED.duration_days,
  is_trial = EXCLUDED.is_trial,
  features = EXCLUDED.features;

-- Plano Mensal
INSERT INTO public.subscription_plans (id, name, slug, price, duration_days, is_trial, features)
VALUES (
  '7ef25147-395e-4cea-88f8-42d032b74f35',
  'Plano Mensal',
  'monthly',
  29.90,
  30,
  false,
  ARRAY['Acesso completo', 'Gestão de produtos e pedidos', 'Dashboard com estatísticas', 'Suporte prioritário']
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  price = EXCLUDED.price,
  duration_days = EXCLUDED.duration_days,
  features = EXCLUDED.features;

-- Plano Anual
INSERT INTO public.subscription_plans (id, name, slug, price, duration_days, is_trial, features)
VALUES (
  gen_random_uuid(),
  'Plano Anual',
  'yearly',
  299.90,
  365,
  false,
  ARRAY['Acesso completo', 'Gestão de produtos e pedidos', 'Dashboard com estatísticas', 'Suporte VIP exclusivo', 'Desconto de 16%']
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  price = EXCLUDED.price,
  duration_days = EXCLUDED.duration_days,
  features = EXCLUDED.features;

-- ============================================
-- 6. VERIFICAÇÃO FINAL
-- ============================================

DO $$
DECLARE
  table_count INTEGER;
  function_count INTEGER;
  plan_count INTEGER;
BEGIN
  -- Verificar tabelas
  SELECT COUNT(*) INTO table_count
  FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_name IN ('stores', 'subscription_plans', 'user_subscriptions', 'subscription_payments');
  
  IF table_count = 4 THEN
    RAISE NOTICE '✅ Todas as 4 tabelas principais criadas';
  ELSE
    RAISE WARNING '⚠️  Apenas % de 4 tabelas criadas', table_count;
  END IF;
  
  -- Verificar funções
  SELECT COUNT(*) INTO function_count
  FROM pg_proc
  WHERE proname IN ('generate_unique_slug', 'get_user_store_id', 'get_active_subscription', 'has_active_subscription')
    AND pronamespace = 'public'::regnamespace;
  
  IF function_count = 4 THEN
    RAISE NOTICE '✅ Todas as 4 funções criadas';
  ELSE
    RAISE WARNING '⚠️  Apenas % de 4 funções criadas', function_count;
  END IF;
  
  -- Verificar planos
  SELECT COUNT(*) INTO plan_count FROM public.subscription_plans;
  
  IF plan_count >= 3 THEN
    RAISE NOTICE '✅ % planos de assinatura inseridos', plan_count;
  ELSE
    RAISE WARNING '⚠️  Apenas % planos inseridos', plan_count;
  END IF;
  
  RAISE NOTICE '🎉 Setup completo! Recarregue a página do site.';
END $$;

-- ============================================
-- 7. LISTAR TUDO CRIADO
-- ============================================

-- Tabelas criadas
SELECT 'TABELAS' AS tipo, table_name AS nome
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('stores', 'subscription_plans', 'user_subscriptions', 'subscription_payments')

UNION ALL

-- Funções criadas
SELECT 'FUNÇÕES' AS tipo, proname AS nome
FROM pg_proc
WHERE proname IN ('generate_unique_slug', 'get_user_store_id', 'get_active_subscription', 'has_active_subscription')
  AND pronamespace = 'public'::regnamespace

UNION ALL

-- Planos inseridos
SELECT 'PLANOS' AS tipo, name AS nome
FROM public.subscription_plans

ORDER BY tipo, nome;

-- ============================================
-- FIM - PRONTO PARA USAR! ✅
-- ============================================
