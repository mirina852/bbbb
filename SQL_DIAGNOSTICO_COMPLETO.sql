-- ============================================
-- DIAGNÓSTICO COMPLETO DAS TABELAS
-- ============================================
-- Execute este script no Supabase SQL Editor para verificar
-- a estrutura completa de todas as tabelas importantes

-- 1. VERIFICAR TABELA STORES
SELECT 
  '=== TABELA STORES ===' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'stores'
ORDER BY ordinal_position;

-- 2. VERIFICAR TABELA USER_SUBSCRIPTIONS
SELECT 
  '=== TABELA USER_SUBSCRIPTIONS ===' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'user_subscriptions'
ORDER BY ordinal_position;

-- 3. VERIFICAR TABELA SUBSCRIPTION_PLANS
SELECT 
  '=== TABELA SUBSCRIPTION_PLANS ===' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'subscription_plans'
ORDER BY ordinal_position;

-- 4. VERIFICAR TABELA PRODUCTS
SELECT 
  '=== TABELA PRODUCTS ===' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'products'
ORDER BY ordinal_position;

-- 5. VERIFICAR TABELA ORDERS
SELECT 
  '=== TABELA ORDERS ===' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'orders'
ORDER BY ordinal_position;

-- 6. VERIFICAR TABELA CATEGORIES
SELECT 
  '=== TABELA CATEGORIES ===' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'categories'
ORDER BY ordinal_position;

-- 7. VERIFICAR TABELA INGREDIENTS
SELECT 
  '=== TABELA INGREDIENTS ===' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'ingredients'
ORDER BY ordinal_position;

-- 8. VERIFICAR TABELA MERCHANT_PAYMENT_CREDENTIALS
SELECT 
  '=== TABELA MERCHANT_PAYMENT_CREDENTIALS ===' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'merchant_payment_credentials'
ORDER BY ordinal_position;

-- 9. VERIFICAR PLANOS CADASTRADOS
SELECT 
  '=== PLANOS CADASTRADOS ===' as info,
  id,
  name,
  slug,
  price,
  duration_days,
  is_trial,
  is_active
FROM public.subscription_plans
ORDER BY price;

-- 10. VERIFICAR POLÍTICAS RLS
SELECT 
  '=== POLÍTICAS RLS ===' as info,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('stores', 'user_subscriptions', 'products', 'orders', 'categories')
ORDER BY tablename, policyname;

-- 11. VERIFICAR FOREIGN KEYS
SELECT
  '=== FOREIGN KEYS ===' as info,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_schema = 'public'
  AND tc.table_name IN ('stores', 'user_subscriptions', 'products', 'orders', 'categories', 'ingredients')
ORDER BY tc.table_name, kcu.column_name;
