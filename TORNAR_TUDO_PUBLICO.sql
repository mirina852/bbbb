-- ============================================
-- TORNAR TODAS AS TABELAS PÚBLICAS (LEITURA)
-- ============================================

-- OBJETIVO: Clientes não autenticados podem ver:
-- ✅ Lojas (stores)
-- ✅ Categorias (categories)
-- ✅ Produtos (products)
-- ✅ Ingredientes (ingredients)

-- ============================================
-- TABELA: STORES
-- ============================================

-- Remover políticas antigas
DROP POLICY IF EXISTS "Stores are viewable by everyone" ON public.stores;
DROP POLICY IF EXISTS "Users can view own store" ON public.stores;
DROP POLICY IF EXISTS "public_read_stores" ON public.stores;

-- Habilitar RLS
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- Política: PÚBLICO pode VER lojas
CREATE POLICY "public_select_stores"
ON public.stores
FOR SELECT
TO public
USING (true);

-- Política: AUTENTICADO pode ATUALIZAR sua loja
CREATE POLICY "authenticated_update_stores"
ON public.stores
FOR UPDATE
TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

-- Dar permissão
GRANT SELECT ON public.stores TO anon;

-- ============================================
-- TABELA: CATEGORIES
-- ============================================

-- Remover políticas antigas
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON public.categories;
DROP POLICY IF EXISTS "Users can manage own categories" ON public.categories;
DROP POLICY IF EXISTS "public_read_categories" ON public.categories;

-- Habilitar RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Política: PÚBLICO pode VER categorias
CREATE POLICY "public_select_categories"
ON public.categories
FOR SELECT
TO public
USING (true);

-- Política: AUTENTICADO pode INSERIR categorias na sua loja
CREATE POLICY "authenticated_insert_categories"
ON public.categories
FOR INSERT
TO authenticated
WITH CHECK (
  store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid())
);

-- Política: AUTENTICADO pode ATUALIZAR categorias da sua loja
CREATE POLICY "authenticated_update_categories"
ON public.categories
FOR UPDATE
TO authenticated
USING (
  store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid())
)
WITH CHECK (
  store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid())
);

-- Política: AUTENTICADO pode DELETAR categorias da sua loja
CREATE POLICY "authenticated_delete_categories"
ON public.categories
FOR DELETE
TO authenticated
USING (
  store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid())
);

-- Dar permissão
GRANT SELECT ON public.categories TO anon;

-- ============================================
-- TABELA: PRODUCTS
-- ============================================

-- Remover políticas antigas
DROP POLICY IF EXISTS "enable_read_access_for_all_users" ON public.products;
DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
DROP POLICY IF EXISTS "public_select_products" ON public.products;
DROP POLICY IF EXISTS "authenticated_insert_products" ON public.products;
DROP POLICY IF EXISTS "authenticated_update_products" ON public.products;
DROP POLICY IF EXISTS "authenticated_delete_products" ON public.products;

-- Habilitar RLS
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Política: PÚBLICO pode VER produtos
CREATE POLICY "public_select_products"
ON public.products
FOR SELECT
TO public
USING (true);

-- Política: AUTENTICADO pode INSERIR produtos na sua loja
CREATE POLICY "authenticated_insert_products"
ON public.products
FOR INSERT
TO authenticated
WITH CHECK (
  store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid())
);

-- Política: AUTENTICADO pode ATUALIZAR produtos da sua loja
CREATE POLICY "authenticated_update_products"
ON public.products
FOR UPDATE
TO authenticated
USING (
  store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid())
)
WITH CHECK (
  store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid())
);

-- Política: AUTENTICADO pode DELETAR produtos da sua loja
CREATE POLICY "authenticated_delete_products"
ON public.products
FOR DELETE
TO authenticated
USING (
  store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid())
);

-- Dar permissão
GRANT SELECT ON public.products TO anon;

-- ============================================
-- TABELA: INGREDIENTS
-- ============================================

-- Remover políticas antigas
DROP POLICY IF EXISTS "Ingredients are viewable by everyone" ON public.ingredients;
DROP POLICY IF EXISTS "public_read_ingredients" ON public.ingredients;

-- Habilitar RLS
ALTER TABLE public.ingredients ENABLE ROW LEVEL SECURITY;

-- Política: PÚBLICO pode VER ingredientes
CREATE POLICY "public_select_ingredients"
ON public.ingredients
FOR SELECT
TO public
USING (true);

-- Política: AUTENTICADO pode INSERIR ingredientes
CREATE POLICY "authenticated_insert_ingredients"
ON public.ingredients
FOR INSERT
TO authenticated
WITH CHECK (
  product_id IN (
    SELECT p.id FROM products p
    JOIN stores s ON s.id = p.store_id
    WHERE s.owner_id = auth.uid()
  )
);

-- Política: AUTENTICADO pode ATUALIZAR ingredientes
CREATE POLICY "authenticated_update_ingredients"
ON public.ingredients
FOR UPDATE
TO authenticated
USING (
  product_id IN (
    SELECT p.id FROM products p
    JOIN stores s ON s.id = p.store_id
    WHERE s.owner_id = auth.uid()
  )
);

-- Política: AUTENTICADO pode DELETAR ingredientes
CREATE POLICY "authenticated_delete_ingredients"
ON public.ingredients
FOR DELETE
TO authenticated
USING (
  product_id IN (
    SELECT p.id FROM products p
    JOIN stores s ON s.id = p.store_id
    WHERE s.owner_id = auth.uid()
  )
);

-- Dar permissão
GRANT SELECT ON public.ingredients TO anon;

-- ============================================
-- TABELA: ORDERS (já configurada)
-- ============================================

-- Garantir permissões
GRANT INSERT ON public.orders TO anon;
GRANT INSERT ON public.order_items TO anon;

-- ============================================
-- VERIFICAR TODAS AS POLÍTICAS
-- ============================================

-- Ver políticas de todas as tabelas
SELECT 
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename IN ('stores', 'categories', 'products', 'ingredients', 'orders', 'order_items')
ORDER BY tablename, roles, cmd;

-- ============================================
-- TESTAR LEITURA PÚBLICA
-- ============================================

-- Simular usuário não autenticado
SET ROLE anon;

-- Testar leitura de lojas
SELECT slug, name FROM stores LIMIT 3;

-- Testar leitura de categorias
SELECT name, slug FROM categories LIMIT 5;

-- Testar leitura de produtos
SELECT name, price FROM products LIMIT 5;

-- Testar leitura de ingredientes
SELECT name FROM ingredients LIMIT 5;

-- Voltar para role normal
RESET ROLE;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- ✅ Todos os SELECTs acima devem funcionar
-- ✅ Clientes podem ver lojas, categorias, produtos, ingredientes
-- ✅ Clientes podem criar pedidos
-- ✅ Admin pode gerenciar tudo da sua loja
