-- ============================================
-- CORRIGIR NOME DA COLUNA NA TABELA user_subscriptions
-- ============================================
-- O código estava usando plan_id e subscription_plan_id inconsistentemente
-- Vamos padronizar para subscription_plan_id

-- 1. Verificar se a coluna existe com nome errado e renomear
DO $$ 
BEGIN
  -- Se existe plan_id, renomear para subscription_plan_id
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_subscriptions' 
    AND column_name = 'plan_id'
  ) THEN
    ALTER TABLE public.user_subscriptions 
    RENAME COLUMN plan_id TO subscription_plan_id;
    RAISE NOTICE '✅ Coluna plan_id renomeada para subscription_plan_id';
  END IF;

  -- Se não existe subscription_plan_id, criar
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'user_subscriptions' 
    AND column_name = 'subscription_plan_id'
  ) THEN
    ALTER TABLE public.user_subscriptions 
    ADD COLUMN subscription_plan_id uuid REFERENCES public.subscription_plans(id) NOT NULL;
    RAISE NOTICE '✅ Coluna subscription_plan_id criada';
  END IF;
END $$;

-- 2. Verificar estrutura final
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'user_subscriptions'
AND column_name IN ('plan_id', 'subscription_plan_id')
ORDER BY column_name;
