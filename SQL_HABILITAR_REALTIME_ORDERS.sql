-- ============================================
-- HABILITAR REALTIME PARA NOTIFICAÇÕES
-- Execute este SQL no Supabase SQL Editor
-- ============================================

-- 1. Habilitar Realtime para a tabela orders
ALTER PUBLICATION supabase_realtime ADD TABLE orders;

-- 2. Verificar se foi habilitado com sucesso
SELECT 
  schemaname, 
  tablename,
  '✅ Realtime habilitado!' as status
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename = 'orders';

-- 3. Verificar estrutura da tabela orders
SELECT 
  '📋 Estrutura da tabela orders:' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'orders'
ORDER BY ordinal_position;

-- 4. Verificar últimos pedidos e se têm store_id
SELECT 
  '📦 Últimos pedidos:' as info,
  id,
  customer_name,
  store_id,
  CASE 
    WHEN store_id IS NULL THEN '❌ NULL'
    ELSE '✅ OK'
  END as store_id_status,
  total,
  status,
  created_at
FROM orders
ORDER BY created_at DESC
LIMIT 5;

-- 5. Contar pedidos por loja
SELECT 
  '📊 Pedidos por loja:' as info,
  s.name as loja_nome,
  s.id as loja_id,
  COUNT(o.id) as total_pedidos,
  MAX(o.created_at) as ultimo_pedido
FROM stores s
LEFT JOIN orders o ON o.store_id = s.id
GROUP BY s.id, s.name
ORDER BY total_pedidos DESC;

-- ============================================
-- PRONTO! ✅
-- ============================================
-- Agora o Realtime está habilitado para orders
-- As notificações devem funcionar quando:
-- 1. Você estiver logado no painel admin
-- 2. As notificações estiverem ativadas nas configurações
-- 3. Um novo pedido for criado
