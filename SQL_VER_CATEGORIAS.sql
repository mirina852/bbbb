-- Ver todas as categorias
SELECT 
  id,
  store_id,
  name,
  slug,
  icon,
  position,
  created_at
FROM public.categories
ORDER BY store_id, position;

-- Ver estrutura da tabela categories
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'categories'
ORDER BY ordinal_position;
