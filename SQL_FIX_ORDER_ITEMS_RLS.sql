-- ============================================
-- CORRIGIR RLS DA TABELA ORDER_ITEMS
-- ============================================

-- OPÇÃO 1: Desabilitar RLS temporariamente (MAIS SIMPLES)
-- Use isso se quiser permitir qualquer pessoa criar itens de pedido
ALTER TABLE public.order_items DISABLE ROW LEVEL SECURITY;

-- OPÇÃO 2: Manter RLS mas permitir INSERT público (MAIS SEGURO)
-- Comente a linha acima e descomente as linhas abaixo:

-- 1. Remover política INSERT antiga
-- DROP POLICY IF EXISTS "order_items_insert_policy" ON public.order_items;

-- 2. Criar nova política INSERT que permite inserção pública
-- CREATE POLICY "order_items_insert_public" 
--   ON public.order_items 
--   FOR INSERT 
--   TO public
--   WITH CHECK (true);

-- 3. Permitir SELECT apenas para donos
-- DROP POLICY IF EXISTS "order_items_select_policy" ON public.order_items;
-- CREATE POLICY "order_items_select_policy" 
--   ON public.order_items 
--   FOR SELECT 
--   TO authenticated
--   USING (
--     order_id IN (
--       SELECT o.id FROM public.orders o
--       JOIN public.stores s ON s.id = o.store_id
--       WHERE s.owner_id = auth.uid()
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
WHERE tablename = 'order_items'
ORDER BY cmd;

-- 5. Verificar se RLS está habilitado
SELECT 
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'order_items';

-- ============================================
-- PRONTO! ✅
-- ============================================
-- OPÇÃO 1 (SIMPLES): RLS desabilitado - qualquer um pode criar/ler itens
-- OPÇÃO 2 (SEGURO): RLS habilitado - qualquer um pode criar, apenas donos podem ler
