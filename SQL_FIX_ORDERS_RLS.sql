-- ============================================
-- CORRIGIR RLS DA TABELA ORDERS
-- ============================================

-- OPÇÃO 1: Desabilitar RLS temporariamente (MAIS SIMPLES)
-- Use isso se quiser permitir qualquer pessoa criar pedidos
ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;

-- OPÇÃO 2: Manter RLS mas permitir INSERT público (MAIS SEGURO)
-- Comente a linha acima e descomente as linhas abaixo:

-- 1. Remover política INSERT antiga
-- DROP POLICY IF EXISTS "orders_insert_policy" ON public.orders;

-- 2. Criar nova política INSERT que permite inserção pública
-- CREATE POLICY "orders_insert_public" 
--   ON public.orders 
--   FOR INSERT 
--   TO public
--   WITH CHECK (true);

-- 3. Permitir SELECT apenas para donos
-- DROP POLICY IF EXISTS "orders_select_policy" ON public.orders;
-- CREATE POLICY "orders_select_policy" 
--   ON public.orders 
--   FOR SELECT 
--   TO authenticated
--   USING (
--     store_id IN (
--       SELECT id FROM public.stores WHERE owner_id = auth.uid()
--     )
--   );

-- 4. Verificar políticas
SELECT 
  policyname,
  cmd,
  roles,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'orders'
ORDER BY cmd;

-- 5. Verificar se RLS está habilitado
SELECT 
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'orders';

-- ============================================
-- PRONTO! ✅
-- ============================================
-- OPÇÃO 1 (SIMPLES): RLS desabilitado - qualquer um pode criar/ler pedidos
-- OPÇÃO 2 (SEGURO): RLS habilitado - qualquer um pode criar, apenas donos podem ler
