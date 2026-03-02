-- ============================================
-- CORRIGIR POLÍTICAS RLS PARA ACESSO PÚBLICO
-- ============================================

-- 1. Ver políticas atuais de products
SELECT 
  policyname,
  cmd as operacao,
  roles,
  qual as condicao_using,
  with_check as condicao_with_check
FROM pg_policies
WHERE tablename = 'products'
ORDER BY policyname;

-- 2. Remover políticas antigas que podem estar bloqueando
DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
DROP POLICY IF EXISTS "Only authenticated users can manage products" ON public.products;
DROP POLICY IF EXISTS "Users can view own store products" ON public.products;
DROP POLICY IF EXISTS "Users can manage own store products" ON public.products;
DROP POLICY IF EXISTS "Users can insert own store products" ON public.products;
DROP POLICY IF EXISTS "Users can update own store products" ON public.products;
DROP POLICY IF EXISTS "Users can delete own store products" ON public.products;

-- 3. Criar política para ACESSO PÚBLICO (SELECT)
-- ✅ Permite que QUALQUER PESSOA veja produtos disponíveis
CREATE POLICY "Public can view available products"
ON public.products FOR SELECT
TO public
USING (available = true);

-- 4. Criar políticas para ADMIN (autenticado)
-- ✅ Admin pode ver todos os produtos da sua loja
CREATE POLICY "Authenticated users can view own store products"
ON public.products FOR SELECT
TO authenticated
USING (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
);

-- ✅ Admin pode inserir produtos na sua loja
CREATE POLICY "Authenticated users can insert own store products"
ON public.products FOR INSERT
TO authenticated
WITH CHECK (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
);

-- ✅ Admin pode atualizar produtos da sua loja
CREATE POLICY "Authenticated users can update own store products"
ON public.products FOR UPDATE
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

-- ✅ Admin pode deletar produtos da sua loja
CREATE POLICY "Authenticated users can delete own store products"
ON public.products FOR DELETE
TO authenticated
USING (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
);

-- ============================================
-- VERIFICAR RESULTADO
-- ============================================

-- Ver políticas criadas
SELECT 
  policyname,
  cmd as operacao,
  roles
FROM pg_policies
WHERE tablename = 'products'
ORDER BY roles, cmd;

-- Testar acesso público (sem autenticação)
-- Este SELECT deve funcionar sem estar logado
SELECT 
  name,
  price,
  category,
  available
FROM products
WHERE available = true
LIMIT 5;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- Políticas criadas:
-- 1. Public can view available products (SELECT, public)
-- 2. Authenticated users can view own store products (SELECT, authenticated)
-- 3. Authenticated users can insert own store products (INSERT, authenticated)
-- 4. Authenticated users can update own store products (UPDATE, authenticated)
-- 5. Authenticated users can delete own store products (DELETE, authenticated)

-- ✅ Clientes (não autenticados) podem ver produtos disponíveis
-- ✅ Admin (autenticado) pode gerenciar produtos da sua loja
