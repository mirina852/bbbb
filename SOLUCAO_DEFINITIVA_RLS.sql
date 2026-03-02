-- ============================================
-- SOLUÇÃO DEFINITIVA - RLS PARA TODAS AS TABELAS
-- ============================================

-- Este script resolve TODOS os problemas de RLS de uma vez

-- ============================================
-- PARTE 1: LIMPAR TUDO
-- ============================================

-- Remover TODAS as políticas de TODAS as tabelas
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT schemaname, tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename IN ('stores', 'categories', 'products', 'ingredients', 'orders', 'order_items')
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
            r.policyname, r.schemaname, r.tablename);
    END LOOP;
END $$;

-- Verificar que não há mais políticas
SELECT tablename, COUNT(*) as total_policies
FROM pg_policies
WHERE tablename IN ('stores', 'categories', 'products', 'ingredients', 'orders', 'order_items')
GROUP BY tablename;
-- Deve retornar: 0 para todas ou nenhuma linha

-- ============================================
-- PARTE 2: HABILITAR RLS EM TODAS AS TABELAS
-- ============================================

ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PARTE 3: DAR PERMISSÕES PARA ROLE 'anon'
-- ============================================

-- CRÍTICO: Dar permissões ANTES de criar políticas
GRANT SELECT ON public.stores TO anon;
GRANT SELECT ON public.categories TO anon;
GRANT SELECT ON public.products TO anon;
GRANT SELECT ON public.ingredients TO anon;
GRANT INSERT ON public.orders TO anon;
GRANT INSERT ON public.order_items TO anon;

-- Também para 'authenticated'
GRANT ALL ON public.stores TO authenticated;
GRANT ALL ON public.categories TO authenticated;
GRANT ALL ON public.products TO authenticated;
GRANT ALL ON public.ingredients TO authenticated;
GRANT ALL ON public.orders TO authenticated;
GRANT ALL ON public.order_items TO authenticated;

-- ============================================
-- PARTE 4: CRIAR POLÍTICAS - STORES
-- ============================================

CREATE POLICY "public_select_stores"
ON public.stores FOR SELECT TO public USING (true);

CREATE POLICY "authenticated_update_stores"
ON public.stores FOR UPDATE TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

-- ============================================
-- PARTE 5: CRIAR POLÍTICAS - CATEGORIES
-- ============================================

CREATE POLICY "public_select_categories"
ON public.categories FOR SELECT TO public USING (true);

CREATE POLICY "authenticated_insert_categories"
ON public.categories FOR INSERT TO authenticated
WITH CHECK (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

CREATE POLICY "authenticated_update_categories"
ON public.categories FOR UPDATE TO authenticated
USING (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()))
WITH CHECK (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

CREATE POLICY "authenticated_delete_categories"
ON public.categories FOR DELETE TO authenticated
USING (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

-- ============================================
-- PARTE 6: CRIAR POLÍTICAS - PRODUCTS
-- ============================================

CREATE POLICY "public_select_products"
ON public.products FOR SELECT TO public USING (true);

CREATE POLICY "authenticated_insert_products"
ON public.products FOR INSERT TO authenticated
WITH CHECK (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

CREATE POLICY "authenticated_update_products"
ON public.products FOR UPDATE TO authenticated
USING (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()))
WITH CHECK (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

CREATE POLICY "authenticated_delete_products"
ON public.products FOR DELETE TO authenticated
USING (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

-- ============================================
-- PARTE 7: CRIAR POLÍTICAS - INGREDIENTS
-- ============================================

CREATE POLICY "public_select_ingredients"
ON public.ingredients FOR SELECT TO public USING (true);

CREATE POLICY "authenticated_insert_ingredients"
ON public.ingredients FOR INSERT TO authenticated
WITH CHECK (product_id IN (
  SELECT p.id FROM products p
  JOIN stores s ON s.id = p.store_id
  WHERE s.owner_id = auth.uid()
));

CREATE POLICY "authenticated_update_ingredients"
ON public.ingredients FOR UPDATE TO authenticated
USING (product_id IN (
  SELECT p.id FROM products p
  JOIN stores s ON s.id = p.store_id
  WHERE s.owner_id = auth.uid()
));

CREATE POLICY "authenticated_delete_ingredients"
ON public.ingredients FOR DELETE TO authenticated
USING (product_id IN (
  SELECT p.id FROM products p
  JOIN stores s ON s.id = p.store_id
  WHERE s.owner_id = auth.uid()
));

-- ============================================
-- PARTE 8: CRIAR POLÍTICAS - ORDERS (CRÍTICO!)
-- ============================================

-- PÚBLICO pode INSERIR pedidos (clientes não autenticados)
CREATE POLICY "public_insert_orders"
ON public.orders FOR INSERT TO public WITH CHECK (true);

-- AUTENTICADO pode VER pedidos da sua loja
CREATE POLICY "authenticated_select_orders"
ON public.orders FOR SELECT TO authenticated
USING (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

-- AUTENTICADO pode ATUALIZAR pedidos da sua loja
CREATE POLICY "authenticated_update_orders"
ON public.orders FOR UPDATE TO authenticated
USING (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()))
WITH CHECK (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

-- AUTENTICADO pode DELETAR pedidos da sua loja
CREATE POLICY "authenticated_delete_orders"
ON public.orders FOR DELETE TO authenticated
USING (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

-- ============================================
-- PARTE 9: CRIAR POLÍTICAS - ORDER_ITEMS (CRÍTICO!)
-- ============================================

-- PÚBLICO pode INSERIR itens de pedido
CREATE POLICY "public_insert_order_items"
ON public.order_items FOR INSERT TO public WITH CHECK (true);

-- AUTENTICADO pode VER itens dos pedidos da sua loja
CREATE POLICY "authenticated_select_order_items"
ON public.order_items FOR SELECT TO authenticated
USING (order_id IN (
  SELECT o.id FROM orders o
  JOIN stores s ON s.id = o.store_id
  WHERE s.owner_id = auth.uid()
));

-- AUTENTICADO pode ATUALIZAR itens
CREATE POLICY "authenticated_update_order_items"
ON public.order_items FOR UPDATE TO authenticated
USING (order_id IN (
  SELECT o.id FROM orders o
  JOIN stores s ON s.id = o.store_id
  WHERE s.owner_id = auth.uid()
));

-- AUTENTICADO pode DELETAR itens
CREATE POLICY "authenticated_delete_order_items"
ON public.order_items FOR DELETE TO authenticated
USING (order_id IN (
  SELECT o.id FROM orders o
  JOIN stores s ON s.id = o.store_id
  WHERE s.owner_id = auth.uid()
));

-- ============================================
-- PARTE 10: VERIFICAR RESULTADO
-- ============================================

-- Ver todas as políticas criadas
SELECT 
  tablename,
  policyname,
  cmd,
  roles,
  CASE 
    WHEN roles = '{public}' THEN '🌐 Público'
    WHEN roles = '{authenticated}' THEN '🔐 Admin'
    ELSE roles::text
  END as tipo
FROM pg_policies
WHERE tablename IN ('stores', 'categories', 'products', 'ingredients', 'orders', 'order_items')
ORDER BY tablename, roles, cmd;

-- Resultado esperado:
-- stores: 2 políticas (1 public SELECT, 1 authenticated UPDATE)
-- categories: 4 políticas (1 public SELECT, 3 authenticated)
-- products: 4 políticas (1 public SELECT, 3 authenticated)
-- ingredients: 4 políticas (1 public SELECT, 3 authenticated)
-- orders: 4 políticas (1 public INSERT, 3 authenticated)
-- order_items: 4 políticas (1 public INSERT, 3 authenticated)

-- ============================================
-- PARTE 11: TESTAR INSERÇÃO DE PEDIDO
-- ============================================

-- Simular cliente não autenticado
SET ROLE anon;

-- Tentar inserir pedido (DEVE FUNCIONAR!)
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
  'Teste Definitivo',
  '11999999999',
  'Rua Final, 999',
  'pix',
  100.00,
  'pending'
) RETURNING id, customer_name, total;

-- Se funcionou, você verá o pedido criado! ✅

-- Voltar para role normal
RESET ROLE;

-- Limpar teste
DELETE FROM orders WHERE customer_name = 'Teste Definitivo';

-- ============================================
-- RESULTADO FINAL
-- ============================================
-- ✅ Todas as políticas antigas removidas
-- ✅ RLS habilitado em todas as tabelas
-- ✅ Permissões concedidas para anon e authenticated
-- ✅ Políticas públicas para leitura e inserção
-- ✅ Políticas admin para gerenciamento
-- ✅ Teste de inserção funciona
-- ✅ CHECKOUT DEVE FUNCIONAR AGORA!
