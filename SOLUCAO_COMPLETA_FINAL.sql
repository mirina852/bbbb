-- ============================================
-- SOLUÇÃO COMPLETA E DEFINITIVA
-- ============================================

-- PROBLEMA: Produtos não aparecem na página pública
-- CAUSA: Produtos não têm categoria_id

-- ============================================
-- PASSO 1: VERIFICAR E CRIAR COLUNA categoria_id
-- ============================================

-- Adicionar coluna categoria_id se não existir
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS categoria_id UUID REFERENCES public.categories(id) ON DELETE SET NULL;

-- Criar índice
CREATE INDEX IF NOT EXISTS products_categoria_id_idx ON public.products(categoria_id);

-- ============================================
-- PASSO 2: HABILITAR RLS
-- ============================================

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PASSO 3: REMOVER POLÍTICAS ANTIGAS
-- ============================================

DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
DROP POLICY IF EXISTS "Public can view available products" ON public.products;
DROP POLICY IF EXISTS "public_read_available_products" ON public.products;
DROP POLICY IF EXISTS "enable_read_access_for_all_users" ON public.products;
DROP POLICY IF EXISTS "Users can view own store products" ON public.products;
DROP POLICY IF EXISTS "authenticated_read_own_store_products" ON public.products;
DROP POLICY IF EXISTS "authenticated_insert_own_store_products" ON public.products;
DROP POLICY IF EXISTS "authenticated_update_own_store_products" ON public.products;
DROP POLICY IF EXISTS "authenticated_delete_own_store_products" ON public.products;
DROP POLICY IF EXISTS "enable_insert_for_authenticated_users" ON public.products;
DROP POLICY IF EXISTS "enable_update_for_users_based_on_user_id" ON public.products;
DROP POLICY IF EXISTS "enable_delete_for_users_based_on_user_id" ON public.products;

-- ============================================
-- PASSO 4: CRIAR POLÍTICA PÚBLICA (CRÍTICO!)
-- ============================================

CREATE POLICY "enable_read_access_for_all_users"
ON public.products
FOR SELECT
USING (true);

-- ============================================
-- PASSO 5: CRIAR POLÍTICAS PARA ADMIN
-- ============================================

CREATE POLICY "enable_insert_for_authenticated_users"
ON public.products FOR INSERT TO authenticated
WITH CHECK (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

CREATE POLICY "enable_update_for_users_based_on_user_id"
ON public.products FOR UPDATE TO authenticated
USING (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()))
WITH CHECK (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

CREATE POLICY "enable_delete_for_users_based_on_user_id"
ON public.products FOR DELETE TO authenticated
USING (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

-- ============================================
-- PASSO 6: ATRIBUIR CATEGORIAS AOS PRODUTOS
-- ============================================

-- Para cada loja, atribuir produtos à primeira categoria
UPDATE products p
SET categoria_id = (
  SELECT c.id 
  FROM categories c 
  WHERE c.store_id = p.store_id 
  ORDER BY c.display_order 
  LIMIT 1
)
WHERE p.categoria_id IS NULL
  AND EXISTS (SELECT 1 FROM categories WHERE store_id = p.store_id);

-- ============================================
-- PASSO 7: VERIFICAR RESULTADO
-- ============================================

-- Ver produtos com categorias
SELECT 
  s.slug as loja,
  p.name as produto,
  c.name as categoria,
  p.categoria_id,
  p.available
FROM products p
JOIN stores s ON s.id = p.store_id
LEFT JOIN categories c ON c.id = p.categoria_id
ORDER BY s.slug, c.name, p.name;

-- Ver contagem por loja
SELECT 
  s.slug as loja,
  COUNT(p.id) as total_produtos,
  COUNT(p.categoria_id) as com_categoria,
  COUNT(p.id) - COUNT(p.categoria_id) as sem_categoria
FROM stores s
LEFT JOIN products p ON p.store_id = s.id
GROUP BY s.id, s.slug
ORDER BY s.slug;

-- Ver políticas RLS
SELECT policyname, cmd, roles
FROM pg_policies
WHERE tablename = 'products'
ORDER BY policyname;

-- Testar acesso público (deve retornar produtos)
SELECT 
  p.name,
  p.price,
  c.name as categoria,
  s.slug as loja
FROM products p
JOIN stores s ON s.id = p.store_id
LEFT JOIN categories c ON c.id = p.categoria_id
WHERE s.slug = 'mercadinhowp'
  AND p.available = true
ORDER BY c.name, p.name;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- ✅ Coluna categoria_id existe
-- ✅ RLS habilitado
-- ✅ Política pública criada (USING true)
-- ✅ Todos os produtos têm categoria_id
-- ✅ Produtos aparecem na página pública

-- ============================================
-- APÓS EXECUTAR
-- ============================================
-- 1. Recarregue a página /s/mercadinhowp
-- 2. Produtos DEVEM aparecer agrupados por categoria!
