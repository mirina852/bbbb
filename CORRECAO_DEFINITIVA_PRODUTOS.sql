-- ============================================
-- CORREÇÃO DEFINITIVA - PRODUTOS NÃO APARECEM
-- ============================================

-- PROBLEMA IDENTIFICADO:
-- 1. Produtos existem no banco ✅
-- 2. Produtos têm store_id correto ✅
-- 3. Produtos estão disponíveis ✅
-- 4. MAS: Políticas RLS podem estar bloqueando acesso público ❌

-- ============================================
-- PASSO 1: VERIFICAR SITUAÇÃO ATUAL
-- ============================================

-- Ver produtos da loja 'fcebook'
SELECT 
  name,
  category,
  available,
  store_id
FROM products
WHERE store_id = (SELECT id FROM stores WHERE slug = 'fcebook' LIMIT 1);

-- Resultado esperado: 2 produtos (coca, x-file)

-- ============================================
-- PASSO 2: REMOVER TODAS AS POLÍTICAS ANTIGAS
-- ============================================

-- Remover TODAS as políticas existentes de products
DO $$ 
DECLARE 
  pol RECORD;
BEGIN
  FOR pol IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE tablename = 'products'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.products', pol.policyname);
  END LOOP;
END $$;

-- Verificar que não há mais políticas
SELECT policyname FROM pg_policies WHERE tablename = 'products';
-- Deve retornar 0 linhas

-- ============================================
-- PASSO 3: CRIAR POLÍTICA PARA ACESSO PÚBLICO
-- ============================================

-- Política 1: QUALQUER PESSOA pode ver produtos disponíveis
-- ✅ Permite acesso SEM autenticação
-- ✅ Mostra apenas produtos com available = true
CREATE POLICY "public_read_available_products"
ON public.products
FOR SELECT
TO public
USING (available = true);

-- ============================================
-- PASSO 4: CRIAR POLÍTICAS PARA ADMIN
-- ============================================

-- Política 2: Admin pode ver TODOS os produtos da sua loja
CREATE POLICY "authenticated_read_own_store_products"
ON public.products
FOR SELECT
TO authenticated
USING (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
);

-- Política 3: Admin pode INSERIR produtos na sua loja
CREATE POLICY "authenticated_insert_own_store_products"
ON public.products
FOR INSERT
TO authenticated
WITH CHECK (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
);

-- Política 4: Admin pode ATUALIZAR produtos da sua loja
CREATE POLICY "authenticated_update_own_store_products"
ON public.products
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

-- Política 5: Admin pode DELETAR produtos da sua loja
CREATE POLICY "authenticated_delete_own_store_products"
ON public.products
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
    WHEN roles = '{public}' THEN '🌐 Público (sem login)'
    WHEN roles = '{authenticated}' THEN '🔐 Autenticado (admin)'
    ELSE roles::text
  END as tipo_acesso
FROM pg_policies
WHERE tablename = 'products'
ORDER BY roles, cmd;

-- Resultado esperado: 5 políticas
-- 1. public_read_available_products (SELECT, public)
-- 2. authenticated_read_own_store_products (SELECT, authenticated)
-- 3. authenticated_insert_own_store_products (INSERT, authenticated)
-- 4. authenticated_update_own_store_products (UPDATE, authenticated)
-- 5. authenticated_delete_own_store_products (DELETE, authenticated)

-- ============================================
-- PASSO 6: TESTAR ACESSO PÚBLICO
-- ============================================

-- Simular acesso de um cliente NÃO autenticado
-- Este SELECT deve retornar produtos
SELECT 
  p.name as produto,
  p.category as categoria,
  p.price as preco,
  s.name as loja,
  s.slug as loja_slug
FROM products p
JOIN stores s ON s.id = p.store_id
WHERE p.available = true
  AND s.slug = 'fcebook'
ORDER BY p.name;

-- Resultado esperado:
-- produto | categoria | preco | loja    | loja_slug
-- --------|-----------|-------|---------|----------
-- coca    | outros    | 7.00  | fcebook | fcebook
-- x-file  | outros    | 25.00 | fcebook | fcebook

-- ============================================
-- PASSO 7: GARANTIR QUE RLS ESTÁ HABILITADO
-- ============================================

-- Verificar se RLS está ativo
SELECT 
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'products';

-- Se rls_habilitado = false, executar:
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PASSO 8: TESTE FINAL
-- ============================================

-- Este SELECT simula o que o código faz
SELECT 
  id,
  name,
  description,
  price,
  image,
  category,
  available,
  store_id
FROM products
WHERE store_id = (SELECT id FROM stores WHERE slug = 'fcebook' LIMIT 1)
  AND available = true
ORDER BY created_at DESC;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- ✅ Políticas criadas: 5
-- ✅ Acesso público permitido: Sim
-- ✅ Produtos retornados: 2 (coca, x-file)
-- ✅ RLS habilitado: Sim

-- ============================================
-- APÓS EXECUTAR ESTE SCRIPT
-- ============================================
-- 1. Recarregue a página /s/fcebook
-- 2. Produtos devem aparecer!
-- 3. Se não aparecer, abra o Console (F12) e veja os logs
