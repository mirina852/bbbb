-- ============================================
-- CORREÇÃO COMPLETA DE TODAS AS TABELAS
-- ============================================
-- Execute DEPOIS de verificar o diagnóstico
-- Este script corrige todos os problemas identificados

-- 1. CORRIGIR TABELA STORES - Adicionar colunas faltantes
DO $$ 
BEGIN
  -- Adicionar city
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stores' AND column_name = 'city'
  ) THEN
    ALTER TABLE public.stores ADD COLUMN city TEXT;
    RAISE NOTICE '✅ Coluna city adicionada à tabela stores';
  END IF;

  -- Adicionar state
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stores' AND column_name = 'state'
  ) THEN
    ALTER TABLE public.stores ADD COLUMN state TEXT;
    RAISE NOTICE '✅ Coluna state adicionada à tabela stores';
  END IF;

  -- Adicionar zip_code
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stores' AND column_name = 'zip_code'
  ) THEN
    ALTER TABLE public.stores ADD COLUMN zip_code TEXT;
    RAISE NOTICE '✅ Coluna zip_code adicionada à tabela stores';
  END IF;

  -- Adicionar email
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stores' AND column_name = 'email'
  ) THEN
    ALTER TABLE public.stores ADD COLUMN email TEXT;
    RAISE NOTICE '✅ Coluna email adicionada à tabela stores';
  END IF;

  -- Adicionar background_urls
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stores' AND column_name = 'background_urls'
  ) THEN
    ALTER TABLE public.stores ADD COLUMN background_urls TEXT[];
    RAISE NOTICE '✅ Coluna background_urls adicionada à tabela stores';
  END IF;
END $$;

-- 2. CORRIGIR TABELA USER_SUBSCRIPTIONS - Garantir nome correto das colunas
DO $$ 
BEGIN
  -- Renomear plan_id para subscription_plan_id se existir
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_subscriptions' AND column_name = 'plan_id'
  ) THEN
    ALTER TABLE public.user_subscriptions 
    RENAME COLUMN plan_id TO subscription_plan_id;
    RAISE NOTICE '✅ Coluna plan_id renomeada para subscription_plan_id';
  END IF;

  -- Criar subscription_plan_id se não existir
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_subscriptions' AND column_name = 'subscription_plan_id'
  ) THEN
    ALTER TABLE public.user_subscriptions 
    ADD COLUMN subscription_plan_id UUID REFERENCES public.subscription_plans(id) NOT NULL;
    RAISE NOTICE '✅ Coluna subscription_plan_id criada';
  END IF;

  -- Adicionar current_period_start se não existir
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_subscriptions' AND column_name = 'current_period_start'
  ) THEN
    ALTER TABLE public.user_subscriptions 
    ADD COLUMN current_period_start TIMESTAMP WITH TIME ZONE DEFAULT now();
    RAISE NOTICE '✅ Coluna current_period_start adicionada';
  END IF;

  -- Adicionar current_period_end se não existir
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_subscriptions' AND column_name = 'current_period_end'
  ) THEN
    ALTER TABLE public.user_subscriptions 
    ADD COLUMN current_period_end TIMESTAMP WITH TIME ZONE;
    RAISE NOTICE '✅ Coluna current_period_end adicionada';
  END IF;

  -- Remover expires_at se ainda existir (substituído por current_period_end)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_subscriptions' AND column_name = 'expires_at'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_subscriptions' AND column_name = 'current_period_end'
  ) THEN
    -- Migrar dados de expires_at para current_period_end
    UPDATE public.user_subscriptions 
    SET current_period_end = expires_at 
    WHERE current_period_end IS NULL;
    
    ALTER TABLE public.user_subscriptions DROP COLUMN expires_at;
    RAISE NOTICE '✅ Coluna expires_at migrada para current_period_end e removida';
  END IF;
END $$;

-- 3. GARANTIR QUE A COLUNA is_trial EXISTE EM subscription_plans
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_plans' AND column_name = 'is_trial'
  ) THEN
    ALTER TABLE public.subscription_plans 
    ADD COLUMN is_trial BOOLEAN NOT NULL DEFAULT false;
    RAISE NOTICE '✅ Coluna is_trial adicionada à tabela subscription_plans';
  END IF;
END $$;

-- 4. GARANTIR PLANO GRATUITO EXISTE
INSERT INTO public.subscription_plans (name, slug, price, duration_days, is_trial, features, is_active)
VALUES (
  'Plano Gratuito',
  'free',
  0.00,
  30,
  true,
  '["Acesso básico", "1 loja", "Produtos ilimitados"]'::jsonb,
  true
)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  price = EXCLUDED.price,
  duration_days = EXCLUDED.duration_days,
  is_trial = EXCLUDED.is_trial,
  features = EXCLUDED.features,
  is_active = EXCLUDED.is_active;

-- 5. CRIAR FUNÇÃO PARA CALCULAR DIAS RESTANTES
CREATE OR REPLACE FUNCTION public.get_days_remaining(subscription_id uuid)
RETURNS integer
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  end_date timestamp with time zone;
  days_left integer;
BEGIN
  SELECT current_period_end INTO end_date
  FROM public.user_subscriptions
  WHERE id = subscription_id;
  
  IF end_date IS NULL THEN
    RETURN 0;
  END IF;
  
  days_left := GREATEST(0, EXTRACT(DAY FROM (end_date - now()))::integer);
  RETURN days_left;
END;
$$;

-- 6. CRIAR FUNÇÃO PARA OBTER ASSINATURA ATIVA
CREATE OR REPLACE FUNCTION public.get_active_subscription(p_user_id uuid)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  subscription_plan_id uuid,
  plan_name text,
  plan_slug text,
  status text,
  current_period_start timestamp with time zone,
  current_period_end timestamp with time zone,
  days_remaining integer,
  created_at timestamp with time zone,
  updated_at timestamp with time zone
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    us.id,
    us.user_id,
    us.subscription_plan_id,
    sp.name as plan_name,
    sp.slug as plan_slug,
    us.status,
    us.current_period_start,
    us.current_period_end,
    GREATEST(0, EXTRACT(DAY FROM (us.current_period_end - now()))::integer) as days_remaining,
    us.created_at,
    us.updated_at
  FROM public.user_subscriptions us
  JOIN public.subscription_plans sp ON sp.id = us.subscription_plan_id
  WHERE us.user_id = p_user_id
    AND us.status = 'active'
    AND us.current_period_end > now()
  ORDER BY us.current_period_end DESC
  LIMIT 1;
END;
$$;

-- 7. VERIFICAÇÃO FINAL
SELECT '✅ CORREÇÕES APLICADAS COM SUCESSO!' as resultado;

-- Verificar estrutura da tabela stores
SELECT 'Estrutura da tabela STORES:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'stores' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verificar estrutura da tabela user_subscriptions
SELECT 'Estrutura da tabela USER_SUBSCRIPTIONS:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'user_subscriptions' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verificar planos cadastrados
SELECT 'Planos cadastrados:' as info;
SELECT id, name, slug, price, duration_days, is_trial, is_active
FROM public.subscription_plans
ORDER BY price;
