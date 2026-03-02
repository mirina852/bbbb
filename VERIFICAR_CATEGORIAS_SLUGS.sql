-- ============================================
-- VERIFICAR CATEGORIAS E SLUGS
-- ============================================

-- 1. Ver todas as categorias com seus slugs
SELECT 
  id,
  name,
  slug,
  store_id,
  display_order
FROM categories
WHERE store_id IN (
  SELECT id FROM stores WHERE slug IN ('mercadinhowp', 'fcebook')
)
ORDER BY store_id, display_order;

-- 2. Ver produtos por categoria
SELECT 
  c.name as categoria,
  c.slug as categoria_slug,
  COUNT(p.id) as total_produtos,
  STRING_AGG(p.name, ', ') as produtos
FROM categories c
LEFT JOIN products p ON p.category_id = c.id
WHERE c.store_id IN (
  SELECT id FROM stores WHERE slug IN ('mercadinhowp', 'fcebook')
)
GROUP BY c.id, c.name, c.slug, c.display_order
ORDER BY c.display_order;

-- 3. Normalizar slugs das categorias
-- Remove acentos e caracteres especiais
UPDATE categories
SET slug = LOWER(
  REGEXP_REPLACE(
    TRANSLATE(
      name,
      'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ',
      'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'
    ),
    '[^a-z0-9]+', '-', 'g'
  )
)
WHERE slug IS NULL OR slug = '' OR slug != LOWER(
  REGEXP_REPLACE(
    TRANSLATE(
      name,
      'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ',
      'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'
    ),
    '[^a-z0-9]+', '-', 'g'
  )
);

-- 4. Verificar resultado
SELECT 
  name,
  slug,
  CASE 
    WHEN slug = LOWER(
      REGEXP_REPLACE(
        TRANSLATE(
          name,
          'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ',
          'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'
        ),
        '[^a-z0-9]+', '-', 'g'
      )
    ) THEN '✅ OK'
    ELSE '❌ Precisa corrigir'
  END as status
FROM categories
WHERE store_id IN (
  SELECT id FROM stores WHERE slug IN ('mercadinhowp', 'fcebook')
)
ORDER BY display_order;

-- ============================================
-- EXEMPLOS DE NORMALIZAÇÃO
-- ============================================
-- "Hambúrguer" → "hamburguer"
-- "Bebidas" → "bebidas"
-- "Hambúrguer & Bebidas" → "hamburguer-bebidas"
-- "Açaí" → "acai"
