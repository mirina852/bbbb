-- ============================================
-- ATIVAR RLS NA TABELA ORDERS
-- ============================================
-- Este comando ativa a segurança de linhas (RLS) na tabela orders
-- As policies já existem e começarão a funcionar após ativar o RLS

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- ============================================
-- VERIFICAR SE FOI ATIVADO
-- ============================================
-- Execute este comando para confirmar que RLS está ativado (deve retornar true)

SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'orders';

-- ============================================
-- POLICIES EXISTENTES (já configuradas)
-- ============================================
-- Estas policies já existem e agora estarão ativas:
--
-- 1. orders_delete_policy - DELETE para authenticated users
-- 2. orders_insert_policy - INSERT para public (permite criar pedidos sem login)
-- 3. orders_select_policy - SELECT para authenticated users (filtra por store_id)
-- 4. orders_update_policy - UPDATE para authenticated users (filtra por store_id)
