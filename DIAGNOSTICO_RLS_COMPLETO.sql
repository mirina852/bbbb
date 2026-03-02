-- ============================================
-- DIAGNÓSTICO COMPLETO - RLS
-- ============================================

-- Este script identifica EXATAMENTE qual é o problema

-- ============================================
-- TESTE 1: Verificar se RLS está habilitado
-- ============================================

SELECT 
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('orders', 'order_items')
ORDER BY tablename;

-- Deve retornar: rls_habilitado = true para ambas

-- ============================================
-- TESTE 2: Verificar políticas existentes
-- ============================================

SELECT 
  tablename,
  policyname,
  cmd,
  roles,
  permissive,
  CASE 
    WHEN with_check IS NULL THEN 'NULL'
    WHEN with_check::text = 'true' THEN 'true'
    ELSE with_check::text
  END as with_check_value
FROM pg_policies
WHERE tablename IN ('orders', 'order_items')
ORDER BY tablename, roles, cmd;

-- Deve mostrar:
-- orders: public_insert_orders, INSERT, {public}, PERMISSIVE, true
-- order_items: public_insert_order_items, INSERT, {public}, PERMISSIVE, true

-- ============================================
-- TESTE 3: Verificar permissões GRANT
-- ============================================

SELECT 
  table_name,
  grantee,
  privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND table_name IN ('orders', 'order_items')
  AND grantee IN ('anon', 'authenticated', 'public')
ORDER BY table_name, grantee, privilege_type;

-- Deve incluir:
-- orders, anon, INSERT
-- order_items, anon, INSERT

-- ============================================
-- TESTE 4: Verificar se role 'anon' existe
-- ============================================

SELECT 
  rolname,
  rolsuper,
  rolinherit,
  rolcreaterole,
  rolcreatedb,
  rolcanlogin
FROM pg_roles
WHERE rolname IN ('anon', 'authenticated', 'postgres');

-- Deve mostrar as 3 roles

-- ============================================
-- TESTE 5: Testar inserção como 'anon'
-- ============================================

-- Resetar para role anônimo
SET ROLE anon;

-- Verificar role atual
SELECT current_user, session_user;
-- Deve retornar: anon, anon

-- Tentar inserir pedido
DO $$
DECLARE
  v_store_id UUID;
  v_order_id UUID;
BEGIN
  -- Pegar ID da loja
  SELECT id INTO v_store_id FROM stores WHERE slug = 'fcebook' LIMIT 1;
  
  IF v_store_id IS NULL THEN
    RAISE EXCEPTION 'Loja não encontrada!';
  END IF;
  
  -- Tentar inserir pedido
  INSERT INTO orders (
    store_id,
    customer_name,
    customer_phone,
    delivery_address,
    payment_method,
    total,
    status
  ) VALUES (
    v_store_id,
    'Teste Diagnóstico',
    '11999999999',
    'Rua Teste, 123',
    'pix',
    50.00,
    'pending'
  ) RETURNING id INTO v_order_id;
  
  RAISE NOTICE 'Pedido criado com sucesso! ID: %', v_order_id;
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'ERRO: % - %', SQLSTATE, SQLERRM;
END $$;

-- Voltar para role normal
RESET ROLE;

-- ============================================
-- TESTE 6: Verificar se há políticas conflitantes
-- ============================================

-- Ver TODAS as políticas de orders (inclusive antigas)
SELECT 
  policyname,
  cmd,
  roles,
  permissive,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'orders';

-- Se houver mais de 4 políticas, há duplicatas!

-- ============================================
-- TESTE 7: Verificar configuração do Supabase
-- ============================================

-- Ver configurações de autenticação
SELECT 
  name,
  setting
FROM pg_settings
WHERE name LIKE '%auth%'
   OR name LIKE '%jwt%'
   OR name LIKE '%role%'
ORDER BY name;

-- ============================================
-- SOLUÇÃO ALTERNATIVA: Desabilitar RLS temporariamente
-- ============================================

-- ATENÇÃO: Use apenas para teste!
-- ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.order_items DISABLE ROW LEVEL SECURITY;

-- Testar checkout
-- Se funcionar, o problema é nas políticas RLS

-- Reabilitar RLS
-- ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- ============================================
-- SOLUÇÃO DEFINITIVA: Forçar permissões
-- ============================================

-- Revogar todas as permissões
REVOKE ALL ON public.orders FROM anon;
REVOKE ALL ON public.order_items FROM anon;

-- Dar permissões explícitas
GRANT INSERT ON public.orders TO anon;
GRANT INSERT ON public.order_items TO anon;
GRANT USAGE ON SCHEMA public TO anon;

-- Verificar
SELECT 
  table_name,
  grantee,
  privilege_type
FROM information_schema.table_privileges
WHERE table_name IN ('orders', 'order_items')
  AND grantee = 'anon';

-- ============================================
-- TESTE 8: Verificar se há triggers bloqueando
-- ============================================

SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_table IN ('orders', 'order_items')
ORDER BY event_object_table, trigger_name;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- TESTE 1: rls_habilitado = true ✅
-- TESTE 2: 4 políticas em orders, 4 em order_items ✅
-- TESTE 3: anon tem INSERT em orders e order_items ✅
-- TESTE 4: role anon existe ✅
-- TESTE 5: Inserção funciona ✅
-- TESTE 6: Apenas 4 políticas (sem duplicatas) ✅
-- TESTE 7: Configurações corretas ✅
-- TESTE 8: Sem triggers bloqueando ✅

-- ============================================
-- PRÓXIMOS PASSOS
-- ============================================
-- 1. Execute este script completo
-- 2. Veja qual teste falha
-- 3. Me envie o resultado do teste que falhou
-- 4. Vou criar a solução específica
