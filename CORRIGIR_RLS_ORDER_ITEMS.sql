-- ============================================
-- CORRIGIR RLS DA TABELA ORDER_ITEMS
-- ============================================

-- Os itens do pedido também precisam de políticas RLS

-- ============================================
-- PASSO 1: VERIFICAR SITUAÇÃO ATUAL
-- ============================================

-- Ver políticas existentes
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'order_items'
ORDER BY policyname;

-- Ver se RLS está habilitado
SELECT 
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'order_items';

-- ============================================
-- PASSO 2: HABILITAR RLS
-- ============================================

ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PASSO 3: REMOVER POLÍTICAS ANTIGAS
-- ============================================

DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can create own order items" ON public.order_items;
DROP POLICY IF EXISTS "Store owners can view order items" ON public.order_items;

-- ============================================
-- PASSO 4: CRIAR POLÍTICAS
-- ============================================

-- Política 1: QUALQUER PESSOA pode criar itens de pedido
CREATE POLICY "allow_public_insert_order_items"
ON public.order_items
FOR INSERT
TO public
WITH CHECK (true);

-- Política 2: Admin pode ver itens dos pedidos da sua loja
CREATE POLICY "store_owners_can_view_order_items"
ON public.order_items
FOR SELECT
TO authenticated
USING (
  order_id IN (
    SELECT o.id FROM orders o
    JOIN stores s ON s.id = o.store_id
    WHERE s.owner_id = auth.uid()
  )
);

-- Política 3: Admin pode atualizar itens dos pedidos da sua loja
CREATE POLICY "store_owners_can_update_order_items"
ON public.order_items
FOR UPDATE
TO authenticated
USING (
  order_id IN (
    SELECT o.id FROM orders o
    JOIN stores s ON s.id = o.store_id
    WHERE s.owner_id = auth.uid()
  )
);

-- Política 4: Admin pode deletar itens dos pedidos da sua loja
CREATE POLICY "store_owners_can_delete_order_items"
ON public.order_items
FOR DELETE
TO authenticated
USING (
  order_id IN (
    SELECT o.id FROM orders o
    JOIN stores s ON s.id = o.store_id
    WHERE s.owner_id = auth.uid()
  )
);

-- ============================================
-- PASSO 5: VERIFICAR POLÍTICAS
-- ============================================

SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'order_items'
ORDER BY roles, cmd;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- ✅ 4 políticas criadas
-- ✅ Clientes podem criar itens
-- ✅ Admin pode gerenciar itens
