-- ============================================
-- CORRIGIR FILTRO DE CATEGORIAS
-- ============================================

-- PROBLEMA: Ao selecionar categoria, produtos não aparecem
-- CAUSA: Slugs das categorias têm acentos, código gera sem acentos

-- ============================================
-- PASSO 1: VERIFICAR PROBLEMA
-- ============================================

-- Ver categorias atuais e slugs
SELECT 
  id,
  name,
  slug as slug_atual,
  LOWER(REGEXP_REPLACE(
    TRANSLATE(
      name, 
      'áéíóúàèìòùâêîôûãõçÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇ', 
      'aeiouaeiouaeiouaocAEIOUAEIOUAEIOUAOC'
    ),
    '[^a-z0-9]+', '-', 'g'
  )) as slug_deveria_ser,
  display_order
FROM categories
ORDER BY display_order;

-- Ver produtos por categoria
SELECT 
  c.name as categoria,
  c.slug as categoria_slug,
  COUNT(p.id) as total_produtos,
  STRING_AGG(p.name, ', ') as produtos
FROM categories c
LEFT JOIN products p ON p.category_id = c.id
GROUP BY c.id, c.name, c.slug, c.display_order
ORDER BY c.display_order;

-- ============================================
-- PASSO 2: NORMALIZAR SLUGS
-- ============================================

-- Atualizar slugs para remover acentos e caracteres especiais
UPDATE categories
SET slug = LOWER(REGEXP_REPLACE(
  TRANSLATE(
    name, 
    'áéíóúàèìòùâêîôûãõçÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇ', 
    'aeiouaeiouaeiouaocAEIOUAEIOUAEIOUAOC'
  ),
  '[^a-z0-9]+', '-', 'g'
));

-- Remover hífens do início e fim
UPDATE categories
SET slug = TRIM(BOTH '-' FROM slug);

-- Remover hífens duplicados
UPDATE categories
SET slug = REGEXP_REPLACE(slug, '-+', '-', 'g');

-- ============================================
-- PASSO 3: VERIFICAR RESULTADO
-- ============================================

-- Ver slugs corrigidos
SELECT 
  name,
  slug,
  CASE 
    WHEN slug ~ '[áéíóúàèìòùâêîôûãõçÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇ]' THEN '❌ Ainda tem acentos'
    WHEN slug ~ '[^a-z0-9-]' THEN '❌ Tem caracteres especiais'
    WHEN slug ~ '^-|-$' THEN '❌ Tem hífen no início/fim'
    ELSE '✅ OK'
  END as status
FROM categories
ORDER BY display_order;

-- Ver produtos agrupados por categoria
SELECT 
  c.name as categoria,
  c.slug,
  COUNT(p.id) as total_produtos,
  STRING_AGG(p.name, ', ' ORDER BY p.name) as produtos
FROM categories c
LEFT JOIN products p ON p.category_id = c.id
GROUP BY c.id, c.name, c.slug, c.display_order
ORDER BY c.display_order;

-- ============================================
-- PASSO 4: GARANTIR QUE PRODUTOS TÊM CATEGORIA
-- ============================================

-- Ver produtos sem categoria
SELECT 
  id,
  name,
  category_id,
  store_id
FROM products
WHERE category_id IS NULL;

-- Atribuir produtos sem categoria à primeira categoria da loja
UPDATE products
SET category_id = (
  SELECT c.id 
  FROM categories c 
  WHERE c.store_id = products.store_id 
  ORDER BY c.display_order 
  LIMIT 1
)
WHERE category_id IS NULL
  AND EXISTS (SELECT 1 FROM categories WHERE store_id = products.store_id);

-- ============================================
-- PASSO 5: TESTE FINAL
-- ============================================

-- Ver estrutura completa: lojas -> categorias -> produtos
SELECT 
  s.slug as loja,
  c.name as categoria,
  c.slug as categoria_slug,
  p.name as produto,
  p.category_id
FROM stores s
LEFT JOIN categories c ON c.store_id = s.id
LEFT JOIN products p ON p.category_id = c.id
WHERE s.slug IN ('mercadinhowp', 'fcebook')
ORDER BY s.slug, c.display_order, p.name;

-- Contar produtos por categoria por loja
SELECT 
  s.slug as loja,
  c.name as categoria,
  c.slug as categoria_slug,
  COUNT(p.id) as total_produtos
FROM stores s
LEFT JOIN categories c ON c.store_id = s.id
LEFT JOIN products p ON p.category_id = c.id
WHERE s.slug IN ('mercadinhowp', 'fcebook')
GROUP BY s.id, s.slug, c.id, c.name, c.slug, c.display_order
ORDER BY s.slug, c.display_order;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- Slugs normalizados:
-- "Hambúrguer" → "hamburguer"
-- "Bebidas" → "bebidas"
-- "Hambúrguer & Bebidas" → "hamburguer-bebidas"
-- "Açaí" → "acai"

-- Produtos agrupados:
-- hamburguer: 4 produtos
-- bebidas: 2 produtos

-- ============================================
-- APÓS EXECUTAR
-- ============================================
-- 1. Recarregue a página /s/mercadinhowp
-- 2. Clique em cada categoria (aba)
-- 3. Produtos devem aparecer filtrados por categoria
-- 4. Badge deve mostrar quantidade correta
