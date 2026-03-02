-- ============================================
-- VERIFICAR QUAL TABELA DE PRODUTOS EXISTE
-- ============================================

-- 1. Listar TODAS as tabelas do schema public
SELECT 
  table_name,
  table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2. Procurar especificamente por tabelas relacionadas a produtos
SELECT 
  table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (
    table_name LIKE '%product%' OR 
    table_name LIKE '%produto%'
  );

-- 3. Ver estrutura da tabela de produtos (se existir)
-- Tente primeiro com 'products'
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'products'
ORDER BY ordinal_position;

-- 4. Se não funcionar, tente com 'produtos'
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'produtos'
ORDER BY ordinal_position;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- Você verá o nome correto da tabela
-- E sua estrutura (colunas)
