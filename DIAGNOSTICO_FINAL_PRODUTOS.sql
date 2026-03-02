-- ============================================
-- DIAGNÓSTICO FINAL - POR QUE PRODUTOS NÃO APARECEM
-- ============================================

-- 1. Ver TODAS as lojas e seus produtos
SELECT 
  s.name as loja,
  s.slug,
  s.owner_id,
  COUNT(p.id) as total_produtos,
  COUNT(CASE WHEN p.available = true THEN 1 END) as disponiveis,
  STRING_AGG(p.name, ', ') as nomes_produtos
FROM stores s
LEFT JOIN products p ON p.store_id = s.id
GROUP BY s.id, s.name, s.slug, s.owner_id
ORDER BY s.name;

-- 2. Ver produtos da loja 'fcebook' especificamente
SELECT 
  'fcebook' as loja,
  p.id,
  p.name,
  p.category,
  p.price,
  p.available,
  p.store_id
FROM products p
WHERE p.store_id = (SELECT id FROM stores WHERE slug = 'fcebook' LIMIT 1)
ORDER BY p.created_at DESC;

-- 3. Ver produtos da loja 'mercadinhowp'
SELECT 
  'mercadinhowp' as loja,
  p.id,
  p.name,
  p.category,
  p.price,
  p.available,
  p.store_id
FROM products p
WHERE p.store_id = (SELECT id FROM stores WHERE slug = 'mercadinhowp' LIMIT 1)
ORDER BY p.created_at DESC;

-- 4. Ver produtos SEM store_id (órfãos)
SELECT 
  'SEM LOJA' as loja,
  p.id,
  p.name,
  p.category,
  p.price,
  p.available,
  p.store_id
FROM products p
WHERE p.store_id IS NULL
ORDER BY p.created_at DESC;

-- 5. Verificar políticas RLS
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual as using_expression
FROM pg_policies
WHERE tablename = 'products'
ORDER BY policyname;

-- ============================================
-- TESTE DE ACESSO PÚBLICO
-- ============================================

-- 6. Simular o que um cliente NÃO autenticado vê
-- (Este SELECT deve retornar produtos se RLS estiver correto)
SET ROLE anon; -- Simula usuário não autenticado

SELECT 
  p.name,
  p.category,
  p.price,
  p.available,
  s.slug as loja_slug
FROM products p
JOIN stores s ON s.id = p.store_id
WHERE p.available = true
  AND s.slug = 'fcebook';

RESET ROLE; -- Volta ao normal

-- ============================================
-- ANÁLISE DO PROBLEMA
-- ============================================

-- 7. Contar produtos por situação
SELECT 
  'Total de produtos' as situacao,
  COUNT(*) as quantidade
FROM products
UNION ALL
SELECT 
  'Produtos disponíveis',
  COUNT(*)
FROM products
WHERE available = true
UNION ALL
SELECT 
  'Produtos com store_id',
  COUNT(*)
FROM products
WHERE store_id IS NOT NULL
UNION ALL
SELECT 
  'Produtos SEM store_id',
  COUNT(*)
FROM products
WHERE store_id IS NULL
UNION ALL
SELECT 
  'Produtos da loja fcebook',
  COUNT(*)
FROM products
WHERE store_id = (SELECT id FROM stores WHERE slug = 'fcebook' LIMIT 1);

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- Query 1: Deve mostrar todas as lojas com contagem de produtos
-- Query 2: Deve mostrar 2 produtos (coca, x-file) da loja fcebook
-- Query 3: Deve mostrar 2 produtos (vvvv, x-file) da loja mercadinhowp
-- Query 4: Deve mostrar produtos órfãos (se houver)
-- Query 5: Deve mostrar política "Public can view available products"
-- Query 6: Deve retornar produtos se RLS permitir acesso público
-- Query 7: Resumo estatístico
