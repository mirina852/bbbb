-- ============================================
-- LIMPAR E RECRIAR RLS DA TABELA ORDERS
-- ============================================

-- PROBLEMA: Políticas duplicadas e erro persiste
-- SOLUÇÃO: Remover TODAS as políticas e criar apenas as corretas

-- ============================================
-- PASSO 1: REMOVER TODAS AS POLÍTICAS
-- ============================================

-- Remover políticas antigas
DROP POLICY IF EXISTS "orders_delete_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_insert_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_select_policy" ON public.orders;
DROP POLICY IF EXISTS "orders_update_policy" ON public.orders;

-- Remover políticas novas
DROP POLICY IF EXISTS "store_owners_can_delete_orders" ON public.orders;
DROP POLICY IF EXISTS "store_owners_can_view_orders" ON public.orders;
DROP POLICY IF EXISTS "store_owners_can_update_orders" ON public.orders;
DROP POLICY IF EXISTS "allow_public_insert_orders" ON public.orders;

-- Remover qualquer outra política
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create own orders" ON public.orders;
DROP POLICY IF EXISTS "Store owners can view their orders" ON public.orders;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.orders;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.orders;

-- Verificar que não há mais políticas
SELECT COUNT(*) as total_policies FROM pg_policies WHERE tablename = 'orders';
-- Deve retornar: 0

-- ============================================
-- PASSO 2: GARANTIR QUE RLS ESTÁ HABILITADO
-- ============================================

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PASSO 3: CRIAR APENAS AS POLÍTICAS CORRETAS
-- ============================================

-- Política 1: PÚBLICO pode INSERIR pedidos (clientes sem login)
CREATE POLICY "public_insert_orders"
ON public.orders
FOR INSERT
TO public
WITH CHECK (true);

-- Política 2: AUTENTICADO pode VER pedidos da sua loja
CREATE POLICY "authenticated_select_orders"
ON public.orders
FOR SELECT
TO authenticated
USING (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
);

-- Política 3: AUTENTICADO pode ATUALIZAR pedidos da sua loja
CREATE POLICY "authenticated_update_orders"
ON public.orders
FOR UPDATE
TO authenticated
USING (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
)
WITH CHECK (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
);

-- Política 4: AUTENTICADO pode DELETAR pedidos da sua loja
CREATE POLICY "authenticated_delete_orders"
ON public.orders
FOR DELETE
TO authenticated
USING (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
);

-- ============================================
-- PASSO 4: VERIFICAR POLÍTICAS CRIADAS
-- ============================================

SELECT 
  policyname,
  cmd as operacao,
  roles,
  CASE 
    WHEN roles = '{public}' THEN '🌐 Público'
    WHEN roles = '{authenticated}' THEN '🔐 Admin'
    ELSE roles::text
  END as tipo
FROM pg_policies
WHERE tablename = 'orders'
ORDER BY roles, cmd;

-- Resultado esperado: 4 políticas
-- public_insert_orders          INSERT  {public}         🌐 Público
-- authenticated_delete_orders   DELETE  {authenticated}  🔐 Admin
-- authenticated_select_orders   SELECT  {authenticated}  🔐 Admin
-- authenticated_update_orders   UPDATE  {authenticated}  🔐 Admin

-- ============================================
-- PASSO 5: TESTAR INSERÇÃO PÚBLICA
-- ============================================

-- Este INSERT deve funcionar (simula cliente não autenticado)
INSERT INTO orders (
  store_id,
  customer_name,
  customer_phone,
  delivery_address,
  payment_method,
  total,
  status
) VALUES (
  (SELECT id FROM stores WHERE slug = 'fcebook' LIMIT 1),
  'Teste Final',
  '11999999999',
  'Rua Teste Final, 999',
  'pix',
  99.99,
  'pending'
) RETURNING id, customer_name, total, status;

-- Se funcionou, limpar
DELETE FROM orders WHERE customer_name = 'Teste Final';

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- ✅ Todas as políticas antigas removidas
-- ✅ Apenas 4 políticas novas
-- ✅ Teste de inserção funciona
-- ✅ Checkout deve funcionar
