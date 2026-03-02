-- ============================================
-- VERIFICAR CONFIGURAÇÃO DE NOTIFICAÇÕES
-- ============================================
-- Execute este script no Supabase SQL Editor para verificar
-- se as notificações estão configuradas corretamente

-- 1. Verificar se a tabela orders tem REPLICA IDENTITY configurada
SELECT 
  schemaname,
  tablename,
  CASE 
    WHEN relreplident = 'd' THEN 'DEFAULT'
    WHEN relreplident = 'n' THEN 'NOTHING'
    WHEN relreplident = 'f' THEN 'FULL'
    WHEN relreplident = 'i' THEN 'INDEX'
  END as replica_identity
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_tables t ON t.tablename = c.relname AND t.schemaname = n.nspname
WHERE t.schemaname = 'public' 
  AND t.tablename = 'orders';

-- 2. Verificar se a tabela orders está na publicação supabase_realtime
SELECT 
  schemaname,
  tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
  AND schemaname = 'public'
  AND tablename = 'orders';

-- 3. Verificar as políticas RLS da tabela orders
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'orders'
ORDER BY policyname;

-- 4. Verificar se RLS está habilitado
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'orders';

-- ============================================
-- CORRIGIR PROBLEMAS (se necessário)
-- ============================================

-- Se REPLICA IDENTITY não estiver como FULL, execute:
-- ALTER TABLE public.orders REPLICA IDENTITY FULL;

-- Se a tabela não estiver na publicação, execute:
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;

-- Se precisar recriar a publicação:
-- ALTER PUBLICATION supabase_realtime DROP TABLE public.orders;
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
