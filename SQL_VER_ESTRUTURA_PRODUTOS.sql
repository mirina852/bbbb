-- Ver TODAS as colunas da tabela produtos
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'produtos'
ORDER BY ordinal_position;
