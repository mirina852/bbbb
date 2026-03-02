-- ============================================
-- SQL para Testar Sistema Multi-Tenant de Pagamentos
-- ============================================

-- 📋 PASSO 1: Verificar estrutura da tabela
-- ============================================
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'merchant_payment_credentials'
ORDER BY ordinal_position;

-- Resultado esperado: Deve mostrar a coluna 'store_id'


-- 📋 PASSO 2: Verificar lojas existentes
-- ============================================
SELECT 
  id,
  name,
  slug,
  owner_id,
  is_active,
  created_at
FROM stores
WHERE is_active = true
ORDER BY created_at DESC;


-- 📋 PASSO 3: Verificar credenciais configuradas
-- ============================================
SELECT 
  mpc.id,
  s.name AS loja,
  s.slug,
  mpc.public_key,
  LEFT(mpc.access_token, 20) || '...' AS access_token_preview,
  mpc.environment,
  mpc.is_active,
  mpc.created_at
FROM merchant_payment_credentials mpc
JOIN stores s ON s.id = mpc.store_id
ORDER BY mpc.created_at DESC;


-- 📋 PASSO 4: Inserir credenciais de teste (EXEMPLO)
-- ============================================
-- ⚠️ ATENÇÃO: Substitua os valores pelos seus dados reais

-- Primeiro, pegue o ID da sua loja
-- SELECT id, name FROM stores WHERE owner_id = auth.uid();

-- Depois, insira as credenciais
INSERT INTO merchant_payment_credentials (
  user_id,
  store_id,
  public_key,
  access_token,
  environment,
  is_active
) VALUES (
  auth.uid(),                                    -- ID do usuário atual
  'SEU-STORE-ID-AQUI',                          -- Substitua pelo ID da loja
  'TEST-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',  -- Public Key de teste
  'TEST-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',       -- Access Token de teste
  'sandbox',                                     -- 'sandbox' para teste, 'production' para produção
  true
);


-- 📋 PASSO 5: Testar busca de credenciais por store_id
-- ============================================
-- Substitua 'SEU-STORE-ID' pelo ID real da sua loja
SELECT 
  public_key,
  access_token,
  environment,
  is_active
FROM merchant_payment_credentials
WHERE store_id = 'SEU-STORE-ID'
  AND is_active = true
ORDER BY created_at DESC
LIMIT 1;


-- 📋 PASSO 6: Testar busca de credenciais por slug
-- ============================================
-- Substitua 'minha-loja' pelo slug real da sua loja
SELECT 
  mpc.public_key,
  mpc.access_token,
  mpc.environment,
  s.name AS loja,
  s.slug
FROM merchant_payment_credentials mpc
JOIN stores s ON s.id = mpc.store_id
WHERE s.slug = 'minha-loja'
  AND s.is_active = true
  AND mpc.is_active = true
ORDER BY mpc.created_at DESC
LIMIT 1;


-- 📋 PASSO 7: Criar lojas de teste para isolamento
-- ============================================
-- Cria 2 lojas de teste para verificar isolamento

-- Loja A
INSERT INTO stores (owner_id, name, slug, is_active)
VALUES (
  auth.uid(),
  'Loja Teste A',
  'loja-teste-a',
  true
)
RETURNING id, name, slug;

-- Loja B
INSERT INTO stores (owner_id, name, slug, is_active)
VALUES (
  auth.uid(),
  'Loja Teste B',
  'loja-teste-b',
  true
)
RETURNING id, name, slug;


-- 📋 PASSO 8: Configurar credenciais diferentes para cada loja
-- ============================================
-- ⚠️ Substitua os IDs das lojas pelos retornados no PASSO 7

-- Credenciais para Loja A
INSERT INTO merchant_payment_credentials (
  user_id,
  store_id,
  public_key,
  access_token,
  environment,
  is_active
) VALUES (
  auth.uid(),
  'ID-DA-LOJA-A',  -- Substitua
  'PUBLIC_KEY_LOJA_A',
  'ACCESS_TOKEN_LOJA_A',
  'sandbox',
  true
);

-- Credenciais para Loja B
INSERT INTO merchant_payment_credentials (
  user_id,
  store_id,
  public_key,
  access_token,
  environment,
  is_active
) VALUES (
  auth.uid(),
  'ID-DA-LOJA-B',  -- Substitua
  'PUBLIC_KEY_LOJA_B',
  'ACCESS_TOKEN_LOJA_B',
  'sandbox',
  true
);


-- 📋 PASSO 9: Verificar isolamento entre lojas
-- ============================================
-- Deve mostrar credenciais diferentes para cada loja

SELECT 
  s.name AS loja,
  s.slug,
  mpc.public_key,
  LEFT(mpc.access_token, 20) || '...' AS access_token_preview
FROM merchant_payment_credentials mpc
JOIN stores s ON s.id = mpc.store_id
WHERE mpc.is_active = true
ORDER BY s.name;


-- 📋 PASSO 10: Atualizar credenciais de uma loja
-- ============================================
-- Desativa credenciais antigas e insere novas

-- 1. Desativar credenciais antigas
UPDATE merchant_payment_credentials
SET is_active = false
WHERE store_id = 'SEU-STORE-ID';

-- 2. Inserir novas credenciais
INSERT INTO merchant_payment_credentials (
  user_id,
  store_id,
  public_key,
  access_token,
  environment,
  is_active
) VALUES (
  auth.uid(),
  'SEU-STORE-ID',
  'NOVA-PUBLIC-KEY',
  'NOVO-ACCESS-TOKEN',
  'production',
  true
);


-- 📋 PASSO 11: Verificar RLS Policies
-- ============================================
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'merchant_payment_credentials';


-- 📋 PASSO 12: Testar acesso público (anônimo)
-- ============================================
-- Esta query simula o que um usuário não autenticado veria
-- Deve retornar apenas public_key, não access_token

SET ROLE anon;  -- Simula usuário anônimo

SELECT 
  s.name AS loja,
  s.slug,
  mpc.public_key
  -- Note: access_token não deve ser acessível
FROM merchant_payment_credentials mpc
JOIN stores s ON s.id = mpc.store_id
WHERE mpc.is_active = true;

RESET ROLE;  -- Volta ao usuário normal


-- 📋 PASSO 13: Limpar dados de teste
-- ============================================
-- ⚠️ CUIDADO: Isso remove TODAS as credenciais de teste

-- Remover credenciais de teste
DELETE FROM merchant_payment_credentials
WHERE environment = 'sandbox'
  AND (public_key LIKE 'TEST-%' OR public_key LIKE '%TESTE%');

-- Remover lojas de teste
DELETE FROM stores
WHERE slug LIKE 'loja-teste-%';


-- 📋 PASSO 14: Estatísticas do sistema
-- ============================================

-- Total de lojas com credenciais configuradas
SELECT 
  COUNT(DISTINCT mpc.store_id) AS lojas_configuradas,
  COUNT(*) AS total_credenciais,
  COUNT(CASE WHEN mpc.is_active THEN 1 END) AS credenciais_ativas
FROM merchant_payment_credentials mpc;

-- Lojas por ambiente
SELECT 
  mpc.environment,
  COUNT(DISTINCT mpc.store_id) AS total_lojas
FROM merchant_payment_credentials mpc
WHERE mpc.is_active = true
GROUP BY mpc.environment;

-- Lojas sem credenciais configuradas
SELECT 
  s.id,
  s.name,
  s.slug,
  s.created_at
FROM stores s
LEFT JOIN merchant_payment_credentials mpc 
  ON s.id = mpc.store_id AND mpc.is_active = true
WHERE s.is_active = true
  AND mpc.id IS NULL
ORDER BY s.created_at DESC;


-- 📋 PASSO 15: Verificar integridade dos dados
-- ============================================

-- Verificar credenciais órfãs (sem loja)
SELECT 
  mpc.id,
  mpc.store_id,
  mpc.created_at
FROM merchant_payment_credentials mpc
LEFT JOIN stores s ON s.id = mpc.store_id
WHERE s.id IS NULL;

-- Verificar credenciais duplicadas (múltiplas ativas para mesma loja)
SELECT 
  store_id,
  COUNT(*) AS total_ativas
FROM merchant_payment_credentials
WHERE is_active = true
GROUP BY store_id
HAVING COUNT(*) > 1;


-- ============================================
-- 🎉 FIM DOS TESTES
-- ============================================

-- ✅ Checklist:
-- [ ] Coluna store_id existe
-- [ ] Lojas existem no banco
-- [ ] Credenciais foram inseridas
-- [ ] Busca por store_id funciona
-- [ ] Busca por slug funciona
-- [ ] Isolamento entre lojas funciona
-- [ ] RLS policies estão ativas
-- [ ] Acesso público limitado funciona
-- [ ] Sem credenciais órfãs
-- [ ] Sem credenciais duplicadas

-- Se todos os testes passaram, o sistema está pronto! 🚀
