-- ============================================
-- LIMPAR E RECRIAR RLS DA TABELA ORDER_ITEMS
-- ============================================

-- ============================================
-- PASSO 1: REMOVER TODAS AS POLÍTICAS
-- ============================================

DROP POLICY IF EXISTS "store_owners_can_delete_order_items" ON public.order_items;
DROP POLICY IF EXISTS "store_owners_can_view_order_items" ON public.order_items;
DROP POLICY IF EXISTS "store_owners_can_update_order_items" ON public.order_items;
DROP POLICY IF EXISTS "allow_public_insert_order_items" ON public.order_items;
DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can create own order items" ON public.order_items;

-- Verificar
SELECT COUNT(*) FROM pg_policies WHERE tablename = 'order_items';

-- ============================================
-- PASSO 2: HABILITAR RLS
-- ============================================

ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PASSO 3: CRIAR POLÍTICAS CORRETAS
-- ============================================

-- Política 1: PÚBLICO pode INSERIR itens
CREATE POLICY "public_insert_order_items"
ON public.order_items
FOR INSERT
TO public
WITH CHECK (true);

-- Política 2: AUTENTICADO pode VER itens dos pedidos da sua loja
CREATE POLICY "authenticated_select_order_items"
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

-- Política 3: AUTENTICADO pode ATUALIZAR itens
CREATE POLICY "authenticated_update_order_items"
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

-- Política 4: AUTENTICADO pode DELETAR itens
CREATE POLICY "authenticated_delete_order_items"
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
-- PASSO 4: VERIFICAR
-- ============================================

SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'order_items'
ORDER BY roles, cmd;

-- Resultado esperado: 4 políticas
