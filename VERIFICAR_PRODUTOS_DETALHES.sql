-- ============================================
-- VERIFICAR DETALHES DOS PRODUTOS
-- ============================================

-- 1. Ver TODOS os campos dos produtos
SELECT 
  id,
  store_id,
  name,
  description,
  price,
  image,
  category,
  available,
  created_at
FROM products
ORDER BY created_at DESC;

-- 2. Ver produtos SEM store_id (problema comum)
SELECT 
  name,
  store_id,
  category,
  available
FROM products
WHERE store_id IS NULL;

-- 3. Ver produtos SEM categoria
SELECT 
  name,
  store_id,
  category,
  available
FROM products
WHERE category IS NULL OR category = '';

-- 4. Ver produtos por loja
SELECT 
  s.name as loja,
  s.slug,
  p.name as produto,
  p.category as categoria,
  p.available as disponivel,
  p.store_id
FROM stores s
LEFT JOIN products p ON p.store_id = s.id
ORDER BY s.name, p.name;

-- 5. Contar produtos por loja
SELECT 
  s.name as loja,
  s.slug,
  COUNT(p.id) as total_produtos,
  COUNT(CASE WHEN p.available = true THEN 1 END) as disponiveis
FROM stores s
LEFT JOIN products p ON p.store_id = s.id
GROUP BY s.id, s.name, s.slug
ORDER BY s.name;

-- ============================================
-- CORRIGIR PROBLEMAS COMUNS
-- ============================================

-- Se produtos não têm store_id, atribuir à loja 'fcebook'
-- Descomente as linhas abaixo se necessário:

-- UPDATE products 
-- SET store_id = (SELECT id FROM stores WHERE slug = 'fcebook' LIMIT 1)
-- WHERE store_id IS NULL;

-- Se produtos não têm categoria, definir categoria padrão
-- UPDATE products 
-- SET category = 'outros'
-- WHERE category IS NULL OR category = '';

-- Garantir que produtos estão disponíveis
-- UPDATE products 
-- SET available = true
-- WHERE available IS NULL OR available = false;

-- ============================================
-- VERIFICAR RESULTADO
-- ============================================

-- Ver produtos da loja 'fcebook' especificamente
SELECT 
  name,
  category,
  price,
  available,
  store_id
FROM products
WHERE store_id = (SELECT id FROM stores WHERE slug = 'fcebook' LIMIT 1);
