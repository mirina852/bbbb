-- ============================================
-- TORNAR PRODUTOS PÚBLICOS (LEITURA)
-- ============================================

-- OBJETIVO: Qualquer pessoa pode VER produtos (sem login)
-- Admin pode gerenciar produtos da sua loja

-- ============================================
-- PASSO 1: VERIFICAR POLÍTICAS ATUAIS
-- ============================================

SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'products'
ORDER BY roles, cmd;

-- ============================================
-- PASSO 2: REMOVER POLÍTICAS ANTIGAS
-- ============================================

-- Remover todas as políticas existentes
DROP POLICY IF EXISTS "enable_read_access_for_all_users" ON public.products;
DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
DROP POLICY IF EXISTS "Public can view available products" ON public.products;
DROP POLICY IF EXISTS "public_read_available_products" ON public.products;
DROP POLICY IF EXISTS "enable_insert_for_authenticated_users" ON public.products;
DROP POLICY IF EXISTS "enable_update_for_users_based_on_user_id" ON public.products;
DROP POLICY IF EXISTS "enable_delete_for_users_based_on_user_id" ON public.products;
DROP POLICY IF EXISTS "Users can view own store products" ON public.products;
DROP POLICY IF EXISTS "authenticated_read_own_store_products" ON public.products;
DROP POLICY IF EXISTS "authenticated_insert_own_store_products" ON public.products;
DROP POLICY IF EXISTS "authenticated_update_own_store_products" ON public.products;
DROP POLICY IF EXISTS "authenticated_delete_own_store_products" ON public.products;

-- Verificar que não há mais políticas
SELECT COUNT(*) as total_policies FROM pg_policies WHERE tablename = 'products';
-- Deve retornar: 0

-- ============================================
-- PASSO 3: HABILITAR RLS
-- ============================================

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PASSO 4: CRIAR POLÍTICAS CORRETAS
-- ============================================

-- Política 1: PÚBLICO pode VER todos os produtos
-- ✅ Permite que clientes vejam produtos sem login
CREATE POLICY "public_select_products"
ON public.products
FOR SELECT
TO public
USING (true);

-- Política 2: AUTENTICADO pode INSERIR produtos na sua loja
CREATE POLICY "authenticated_insert_products"
ON public.products
FOR INSERT
TO authenticated
WITH CHECK (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
);

-- Política 3: AUTENTICADO pode ATUALIZAR produtos da sua loja
CREATE POLICY "authenticated_update_products"
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

-- Política 4: AUTENTICADO pode DELETAR produtos da sua loja
CREATE POLICY "authenticated_delete_products"
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
    WHEN roles = '{public}' THEN '🌐 Público (todos)'
    WHEN roles = '{authenticated}' THEN '🔐 Admin (logado)'
    ELSE roles::text
  END as tipo_acesso
FROM pg_policies
WHERE tablename = 'products'
ORDER BY roles, cmd;

-- Resultado esperado: 4 políticas
-- public_select_products          SELECT  {public}         🌐 Público
-- authenticated_delete_products   DELETE  {authenticated}  🔐 Admin
-- authenticated_insert_products   INSERT  {authenticated}  🔐 Admin
-- authenticated_update_products   UPDATE  {authenticated}  🔐 Admin

-- ============================================
-- PASSO 6: TESTAR LEITURA PÚBLICA
-- ============================================

-- Simular usuário não autenticado
SET ROLE anon;

-- Tentar ler produtos (deve funcionar)
SELECT 
  id,
  name,
  price,
  available
FROM products
LIMIT 5;

-- Se funcionou, você verá os produtos ✅
-- Se deu erro, a política não está funcionando ❌

-- Voltar para role normal
RESET ROLE;

-- ============================================
-- PASSO 7: DAR PERMISSÕES PARA ROLE 'anon'
-- ============================================

-- Garantir que a role 'anon' pode ler produtos
GRANT SELECT ON public.products TO anon;
GRANT SELECT ON public.categories TO anon;
GRANT SELECT ON public.stores TO anon;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- ✅ RLS habilitado
-- ✅ Política pública para SELECT
-- ✅ Políticas admin para INSERT/UPDATE/DELETE
-- ✅ Qualquer pessoa pode ver produtos
-- ✅ Apenas admin pode gerenciar produtos

-- ============================================
-- APÓS EXECUTAR
-- ============================================
-- 1. Recarregue a página pública /s/[slug]
-- 2. Produtos devem aparecer (sem login)
-- 3. Admin pode adicionar/editar/deletar produtos
