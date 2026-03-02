-- ============================================
-- SCRIPT DE VERIFICAÇÃO: Configuração Mercado Pago Multi-Tenant
-- ============================================
-- Execute este script no SQL Editor do Supabase para verificar
-- se tudo está configurado corretamente
-- ============================================

-- 1️⃣ VERIFICAR SE A TABELA EXISTE
-- ============================================
SELECT 
  'Tabela merchant_payment_credentials existe' AS status,
  COUNT(*) AS total_registros
FROM merchant_payment_credentials;

-- 2️⃣ VERIFICAR SE A COLUNA store_id EXISTE
-- ============================================
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'merchant_payment_credentials'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3️⃣ VERIFICAR ÍNDICES
-- ============================================
SELECT 
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'merchant_payment_credentials'
  AND schemaname = 'public';

-- 4️⃣ VERIFICAR POLÍTICAS RLS
-- ============================================
SELECT 
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'merchant_payment_credentials'
  AND schemaname = 'public';

-- 5️⃣ VERIFICAR SE RLS ESTÁ HABILITADO
-- ============================================
SELECT 
  tablename,
  rowsecurity AS rls_enabled
FROM pg_tables
WHERE tablename = 'merchant_payment_credentials'
  AND schemaname = 'public';

-- 6️⃣ VERIFICAR CREDENCIAIS ATIVAS POR LOJA
-- ============================================
SELECT 
  s.id AS store_id,
  s.name AS loja,
  s.slug,
  u.email AS dono,
  mpc.public_key,
  mpc.environment,
  mpc.is_active,
  mpc.created_at
FROM stores s
LEFT JOIN merchant_payment_credentials mpc ON mpc.store_id = s.id AND mpc.is_active = true
LEFT JOIN auth.users u ON u.id = s.owner_id
WHERE s.is_active = true
ORDER BY s.created_at DESC;

-- 7️⃣ VERIFICAR LOJAS SEM CREDENCIAIS
-- ============================================
SELECT 
  s.id,
  s.name AS loja,
  s.slug,
  u.email AS dono,
  'SEM CREDENCIAIS CONFIGURADAS' AS status
FROM stores s
JOIN auth.users u ON u.id = s.owner_id
LEFT JOIN merchant_payment_credentials mpc ON mpc.store_id = s.id AND mpc.is_active = true
WHERE mpc.id IS NULL
  AND s.is_active = true;

-- 8️⃣ VERIFICAR CREDENCIAIS DUPLICADAS (PROBLEMA)
-- ============================================
SELECT 
  store_id,
  COUNT(*) AS total_credenciais_ativas
FROM merchant_payment_credentials
WHERE is_active = true
GROUP BY store_id
HAVING COUNT(*) > 1;

-- 9️⃣ VERIFICAR FOREIGN KEYS
-- ============================================
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'merchant_payment_credentials';

-- 🔟 ESTATÍSTICAS GERAIS
-- ============================================
SELECT 
  'Total de lojas' AS metrica,
  COUNT(*) AS valor
FROM stores
WHERE is_active = true

UNION ALL

SELECT 
  'Lojas com credenciais configuradas' AS metrica,
  COUNT(DISTINCT mpc.store_id) AS valor
FROM merchant_payment_credentials mpc
WHERE mpc.is_active = true

UNION ALL

SELECT 
  'Lojas sem credenciais' AS metrica,
  COUNT(*) AS valor
FROM stores s
LEFT JOIN merchant_payment_credentials mpc ON mpc.store_id = s.id AND mpc.is_active = true
WHERE s.is_active = true
  AND mpc.id IS NULL

UNION ALL

SELECT 
  'Total de credenciais ativas' AS metrica,
  COUNT(*) AS valor
FROM merchant_payment_credentials
WHERE is_active = true

UNION ALL

SELECT 
  'Total de credenciais inativas' AS metrica,
  COUNT(*) AS valor
FROM merchant_payment_credentials
WHERE is_active = false;

-- ============================================
-- RESULTADOS ESPERADOS:
-- ============================================
-- 1. Tabela deve existir
-- 2. Coluna store_id deve existir (tipo UUID, nullable)
-- 3. Deve ter índices: 
--    - merchant_payment_credentials_store_id_idx
--    - merchant_payment_credentials_store_active_idx
-- 4. Deve ter políticas RLS:
--    - Users can view own store credentials
--    - Users can insert own store credentials
--    - Users can update own store credentials
--    - Users can delete own store credentials
--    - Public can view active credentials
-- 5. RLS deve estar habilitado (true)
-- 6. Cada loja deve ter no máximo 1 credencial ativa
-- 7. Não deve haver credenciais duplicadas
-- 8. Foreign key para stores(id) deve existir
-- ============================================
