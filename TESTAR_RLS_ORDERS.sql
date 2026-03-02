-- ============================================
-- TESTAR RLS DA TABELA ORDERS
-- ============================================

-- Este script testa se as políticas RLS estão funcionando corretamente

-- ============================================
-- TESTE 1: Verificar Políticas
-- ============================================

SELECT 
  policyname,
  cmd,
  roles,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE tablename = 'orders'
ORDER BY roles, cmd;

-- Deve mostrar:
-- public_insert_orders          INSERT  {public}         NULL  true
-- authenticated_select_orders   SELECT  {authenticated}  ...   NULL
-- authenticated_update_orders   UPDATE  {authenticated}  ...   ...
-- authenticated_delete_orders   DELETE  {authenticated}  ...   NULL

-- ============================================
-- TESTE 2: Simular Inserção Pública (Cliente)
-- ============================================

-- Resetar para role anônimo (simula cliente não autenticado)
SET ROLE anon;

-- Tentar inserir pedido (deve funcionar)
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
  'Cliente Anônimo Teste',
  '11999999999',
  'Rua Teste, 123',
  'pix',
  50.00,
  'pending'
) RETURNING id, customer_name, total, status;

-- Se funcionou, você verá o pedido criado ✅
-- Se deu erro, a política não está funcionando ❌

-- Voltar para role normal
RESET ROLE;

-- ============================================
-- TESTE 3: Verificar se Pedido Foi Criado
-- ============================================

SELECT 
  id,
  customer_name,
  total,
  status,
  created_at
FROM orders
WHERE customer_name = 'Cliente Anônimo Teste'
ORDER BY created_at DESC;

-- ============================================
-- TESTE 4: Limpar Pedido de Teste
-- ============================================

DELETE FROM orders WHERE customer_name = 'Cliente Anônimo Teste';

-- ============================================
-- TESTE 5: Verificar Configuração do RLS
-- ============================================

-- Ver se RLS está habilitado
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'orders';

-- Deve retornar: rls_enabled = true

-- ============================================
-- TESTE 6: Verificar Permissões da Role 'anon'
-- ============================================

-- Ver permissões da role anon na tabela orders
SELECT 
  grantee,
  privilege_type
FROM information_schema.table_privileges
WHERE table_name = 'orders'
  AND grantee IN ('anon', 'authenticated', 'public');

-- Deve incluir INSERT para anon ou public

-- ============================================
-- TESTE 7: Verificar se a Política Permite INSERT
-- ============================================

-- Ver detalhes da política de INSERT
SELECT 
  policyname,
  cmd,
  roles,
  permissive,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'orders'
  AND cmd = 'INSERT';

-- Deve mostrar:
-- public_insert_orders  INSERT  {public}  PERMISSIVE  NULL  true

-- ============================================
-- DIAGNÓSTICO COMPLETO
-- ============================================

-- Se o TESTE 2 falhou, execute:

-- 1. Verificar se a role 'anon' existe
SELECT rolname FROM pg_roles WHERE rolname = 'anon';

-- 2. Dar permissão de INSERT para anon
GRANT INSERT ON orders TO anon;
GRANT INSERT ON order_items TO anon;

-- 3. Tentar novamente o TESTE 2

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- ✅ TESTE 2 deve funcionar (inserir pedido)
-- ✅ TESTE 3 deve mostrar o pedido criado
-- ✅ TESTE 5 deve mostrar rls_enabled = true
-- ✅ TESTE 7 deve mostrar política com with_check = true
