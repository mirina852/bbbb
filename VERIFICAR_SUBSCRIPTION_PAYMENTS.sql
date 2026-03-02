-- ============================================
-- VERIFICAR ESTRUTURA DA TABELA subscription_payments
-- ============================================

-- 1. Ver todas as colunas e suas propriedades
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default,
  CASE 
    WHEN is_nullable = 'NO' THEN '✅ NOT NULL'
    ELSE '⚠️ NULLABLE'
  END as obrigatorio
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'subscription_payments'
ORDER BY ordinal_position;

-- ============================================
-- 2. Verificar se existe subscription_id (NÃO DEVERIA EXISTIR!)
-- ============================================
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'subscription_payments'
      AND column_name = 'subscription_id'
    ) THEN '❌ ERRO: Coluna subscription_id existe (deveria ser subscription_plan_id!)'
    ELSE '✅ OK: Coluna subscription_id NÃO existe (correto!)'
  END as verificacao_subscription_id;

-- ============================================
-- 3. Verificar se existe subscription_plan_id (DEVE EXISTIR!)
-- ============================================
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'subscription_payments'
      AND column_name = 'subscription_plan_id'
    ) THEN '✅ OK: Coluna subscription_plan_id existe'
    ELSE '❌ ERRO: Coluna subscription_plan_id NÃO existe!'
  END as verificacao_subscription_plan_id;

-- ============================================
-- 4. Verificar campos obrigatórios
-- ============================================
SELECT 
  'user_id' as campo,
  CASE 
    WHEN is_nullable = 'NO' THEN '✅ NOT NULL (correto)'
    ELSE '❌ NULLABLE (incorreto!)'
  END as status
FROM information_schema.columns
WHERE table_name = 'subscription_payments' AND column_name = 'user_id'

UNION ALL

SELECT 
  'subscription_plan_id' as campo,
  CASE 
    WHEN is_nullable = 'NO' THEN '✅ NOT NULL (correto)'
    ELSE '❌ NULLABLE (incorreto!)'
  END as status
FROM information_schema.columns
WHERE table_name = 'subscription_payments' AND column_name = 'subscription_plan_id'

UNION ALL

SELECT 
  'amount' as campo,
  CASE 
    WHEN is_nullable = 'NO' THEN '✅ NOT NULL (correto)'
    ELSE '❌ NULLABLE (incorreto!)'
  END as status
FROM information_schema.columns
WHERE table_name = 'subscription_payments' AND column_name = 'amount'

UNION ALL

SELECT 
  'status' as campo,
  CASE 
    WHEN is_nullable = 'NO' THEN '✅ NOT NULL (correto)'
    ELSE '❌ NULLABLE (incorreto!)'
  END as status
FROM information_schema.columns
WHERE table_name = 'subscription_payments' AND column_name = 'status';

-- ============================================
-- 5. Ver pagamentos existentes
-- ============================================
SELECT 
  id,
  user_id,
  subscription_plan_id,
  amount,
  status,
  payment_method,
  payment_id,
  created_at
FROM public.subscription_payments
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 6. Verificar se há registros com campos NULL
-- ============================================
SELECT 
  COUNT(*) as total_registros,
  COUNT(user_id) as com_user_id,
  COUNT(subscription_plan_id) as com_subscription_plan_id,
  COUNT(amount) as com_amount,
  COUNT(status) as com_status,
  COUNT(CASE WHEN user_id IS NULL THEN 1 END) as sem_user_id,
  COUNT(CASE WHEN subscription_plan_id IS NULL THEN 1 END) as sem_subscription_plan_id,
  COUNT(CASE WHEN amount IS NULL THEN 1 END) as sem_amount,
  COUNT(CASE WHEN status IS NULL THEN 1 END) as sem_status
FROM public.subscription_payments;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- ✅ subscription_id NÃO deve existir
-- ✅ subscription_plan_id DEVE existir e ser NOT NULL
-- ✅ user_id DEVE ser NOT NULL
-- ✅ amount DEVE ser NOT NULL
-- ✅ status DEVE ser NOT NULL
-- ✅ Nenhum registro com campos obrigatórios NULL
