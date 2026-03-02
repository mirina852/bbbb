-- ============================================
-- HABILITAR RLS E CRIAR POLÍTICAS PÚBLICAS
-- ============================================

-- PROBLEMA IDENTIFICADO:
-- Tabela 'products' está marcada como "Unrestricted"
-- Isso significa que RLS NÃO está configurado corretamente

-- ============================================
-- PASSO 1: HABILITAR RLS NA TABELA products
-- ============================================

-- Habilitar Row Level Security
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Verificar se foi habilitado
SELECT 
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'products';

-- Resultado esperado: rls_habilitado = true

-- ============================================
-- PASSO 2: REMOVER TODAS AS POLÍTICAS ANTIGAS
-- ============================================

-- Remover políticas uma por uma (mais seguro)
DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
DROP POLICY IF EXISTS "Only authenticated users can manage products" ON public.products;
DROP POLICY IF EXISTS "Users can view own store products" ON public.products;
DROP POLICY IF EXISTS "Users can manage own store products" ON public.products;
DROP POLICY IF EXISTS "Public can view available products" ON public.products;
DROP POLICY IF EXISTS "public_read_available_products" ON public.products;
DROP POLICY IF EXISTS "authenticated_read_own_store_products" ON public.products;
DROP POLICY IF EXISTS "authenticated_insert_own_store_products" ON public.products;
DROP POLICY IF EXISTS "authenticated_update_own_store_products" ON public.products;
DROP POLICY IF EXISTS "authenticated_delete_own_store_products" ON public.products;

-- Verificar que não há mais políticas
SELECT COUNT(*) as total_policies
FROM pg_policies
WHERE tablename = 'products';

-- Resultado esperado: 0

-- ============================================
-- PASSO 3: CRIAR POLÍTICA PARA ACESSO PÚBLICO
-- ============================================

-- CRÍTICO: Esta política permite que QUALQUER PESSOA veja produtos
-- Sem ela, a página pública fica vazia!

CREATE POLICY "enable_read_access_for_all_users"
ON public.products
FOR SELECT
USING (true);  -- ✅ Permite acesso TOTAL para leitura

-- Alternativa mais restritiva (apenas produtos disponíveis):
-- USING (available = true);

-- ============================================
-- PASSO 4: CRIAR POLÍTICAS PARA ADMIN
-- ============================================

-- Admin pode INSERIR produtos
CREATE POLICY "enable_insert_for_authenticated_users"
ON public.products
FOR INSERT
TO authenticated
WITH CHECK (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
);

-- Admin pode ATUALIZAR produtos
CREATE POLICY "enable_update_for_users_based_on_user_id"
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

-- Admin pode DELETAR produtos
CREATE POLICY "enable_delete_for_users_based_on_user_id"
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
  qual as condicao
FROM pg_policies
WHERE tablename = 'products'
ORDER BY policyname;

-- Resultado esperado: 4 políticas
-- 1. enable_read_access_for_all_users (SELECT, {})
-- 2. enable_insert_for_authenticated_users (INSERT, {authenticated})
-- 3. enable_update_for_users_based_on_user_id (UPDATE, {authenticated})
-- 4. enable_delete_for_users_based_on_user_id (DELETE, {authenticated})

-- ============================================
-- PASSO 6: TESTAR ACESSO PÚBLICO
-- ============================================

-- Este SELECT deve funcionar SEM estar autenticado
SELECT 
  id,
  name,
  description,
  price,
  image,
  category,
  available,
  store_id
FROM public.products
WHERE store_id = (SELECT id FROM public.stores WHERE slug = 'fcebook' LIMIT 1)
ORDER BY created_at DESC;

-- Resultado esperado: 2 produtos (coca, x-file)

-- ============================================
-- PASSO 7: VERIFICAR STATUS FINAL
-- ============================================

-- Ver status de RLS
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_ativo,
  CASE 
    WHEN rowsecurity = true THEN '✅ RLS Habilitado'
    ELSE '❌ RLS Desabilitado'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'products';

-- Ver resumo de políticas
SELECT 
  COUNT(*) as total_policies,
  COUNT(CASE WHEN cmd = 'SELECT' THEN 1 END) as select_policies,
  COUNT(CASE WHEN cmd = 'INSERT' THEN 1 END) as insert_policies,
  COUNT(CASE WHEN cmd = 'UPDATE' THEN 1 END) as update_policies,
  COUNT(CASE WHEN cmd = 'DELETE' THEN 1 END) as delete_policies
FROM pg_policies
WHERE tablename = 'products';

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- ✅ RLS habilitado: true
-- ✅ Total de políticas: 4
-- ✅ SELECT policy: 1 (acesso público)
-- ✅ INSERT policy: 1 (admin)
-- ✅ UPDATE policy: 1 (admin)
-- ✅ DELETE policy: 1 (admin)

-- ============================================
-- APÓS EXECUTAR ESTE SCRIPT
-- ============================================
-- 1. Recarregue a página /s/fcebook
-- 2. Produtos DEVEM aparecer!
-- 3. No Supabase Table Editor, 'products' deve mostrar "RLS enabled"
