-- ============================================
-- CORRIGIR RLS DA TABELA ORDERS
-- ============================================

-- ERRO: new row violates row-level security policy for table "orders"
-- CAUSA: Clientes não autenticados não podem criar pedidos

-- ============================================
-- PASSO 1: VERIFICAR SITUAÇÃO ATUAL
-- ============================================

-- Ver políticas existentes
SELECT 
  policyname,
  cmd as operacao,
  roles,
  qual as using_expression
FROM pg_policies
WHERE tablename = 'orders'
ORDER BY policyname;

-- Ver se RLS está habilitado
SELECT 
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'orders';

-- ============================================
-- PASSO 2: HABILITAR RLS
-- ============================================

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PASSO 3: REMOVER POLÍTICAS ANTIGAS
-- ============================================

DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create own orders" ON public.orders;
DROP POLICY IF EXISTS "Store owners can view their orders" ON public.orders;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.orders;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.orders;

-- ============================================
-- PASSO 4: CRIAR POLÍTICAS CORRETAS
-- ============================================

-- Política 1: QUALQUER PESSOA pode criar pedidos (clientes não autenticados)
-- ✅ Permite que clientes façam pedidos sem login
CREATE POLICY "allow_public_insert_orders"
ON public.orders
FOR INSERT
TO public
WITH CHECK (true);

-- Política 2: Admin (dono da loja) pode ver pedidos da sua loja
CREATE POLICY "store_owners_can_view_orders"
ON public.orders
FOR SELECT
TO authenticated
USING (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
);

-- Política 3: Admin pode atualizar pedidos da sua loja
CREATE POLICY "store_owners_can_update_orders"
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

-- Política 4: Admin pode deletar pedidos da sua loja
CREATE POLICY "store_owners_can_delete_orders"
ON public.orders
FOR DELETE
TO authenticated
USING (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
);

-- ============================================
-- PASSO 5: VERIFICAR POLÍTICAS CRIADAS
-- ============================================

SELECT 
  policyname,
  cmd as operacao,
  roles,
  CASE 
    WHEN roles = '{public}' THEN '🌐 Público (clientes)'
    WHEN roles = '{authenticated}' THEN '🔐 Autenticado (admin)'
    ELSE roles::text
  END as tipo_acesso
FROM pg_policies
WHERE tablename = 'orders'
ORDER BY roles, cmd;

-- Resultado esperado: 4 políticas
-- 1. allow_public_insert_orders (INSERT, public)
-- 2. store_owners_can_view_orders (SELECT, authenticated)
-- 3. store_owners_can_update_orders (UPDATE, authenticated)
-- 4. store_owners_can_delete_orders (DELETE, authenticated)

-- ============================================
-- PASSO 6: TESTAR CRIAÇÃO DE PEDIDO
-- ============================================

-- Simular criação de pedido (como cliente não autenticado)
-- Este INSERT deve funcionar
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
  'Cliente Teste',
  '11999999999',
  'Rua Teste, 123',
  'pix',
  50.00,
  'pending'
) RETURNING id, customer_name, total, status;

-- Se funcionar, deletar o pedido de teste
-- DELETE FROM orders WHERE customer_name = 'Cliente Teste';

-- ============================================
-- PASSO 7: VERIFICAR ESTRUTURA DA TABELA
-- ============================================

-- Ver colunas da tabela orders
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'orders'
ORDER BY ordinal_position;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- ✅ RLS habilitado
-- ✅ Política pública para INSERT
-- ✅ Políticas admin para SELECT/UPDATE/DELETE
-- ✅ Clientes podem criar pedidos
-- ✅ Admin pode gerenciar pedidos da sua loja

-- ============================================
-- APÓS EXECUTAR
-- ============================================
-- 1. Recarregue a página pública /s/[slug]
-- 2. Adicione produtos ao carrinho
-- 3. Faça checkout
-- 4. Pedido deve ser criado com sucesso! ✅
