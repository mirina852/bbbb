-- ============================================
-- ATRIBUIR CATEGORIAS AOS PRODUTOS
-- ============================================

-- PROBLEMA IDENTIFICADO:
-- Produtos não têm categoria_id (está NULL)
-- Por isso não aparecem em nenhuma categoria na página pública

-- ============================================
-- PASSO 1: VERIFICAR CATEGORIAS EXISTENTES
-- ============================================

-- Ver categorias da loja 'mercadinhowp' (loja atual nos logs)
SELECT 
  id,
  name,
  slug,
  store_id
FROM categories
WHERE store_id = (SELECT id FROM stores WHERE slug = 'mercadinhowp' LIMIT 1)
ORDER BY display_order;

-- ============================================
-- PASSO 2: VERIFICAR PRODUTOS SEM CATEGORIA
-- ============================================

-- Ver produtos sem categoria_id
SELECT 
  p.id,
  p.name,
  p.category,
  p.categoria_id,
  p.category_id,
  s.slug as loja
FROM products p
JOIN stores s ON s.id = p.store_id
WHERE p.store_id = (SELECT id FROM stores WHERE slug = 'mercadinhowp' LIMIT 1)
ORDER BY p.name;

-- ============================================
-- PASSO 3: ATRIBUIR CATEGORIA PADRÃO
-- ============================================

-- Opção 1: Atribuir à primeira categoria da loja
UPDATE products
SET categoria_id = (
  SELECT id FROM categories 
  WHERE store_id = products.store_id 
  ORDER BY display_order 
  LIMIT 1
)
WHERE store_id = (SELECT id FROM stores WHERE slug = 'mercadinhowp' LIMIT 1)
  AND categoria_id IS NULL;

-- Opção 2: Atribuir baseado no campo 'category' (texto)
-- Se o produto tem category = 'burger', atribuir à categoria 'Burgers'
UPDATE products p
SET categoria_id = c.id
FROM categories c
WHERE p.store_id = c.store_id
  AND p.store_id = (SELECT id FROM stores WHERE slug = 'mercadinhowp' LIMIT 1)
  AND p.categoria_id IS NULL
  AND (
    LOWER(p.category) = LOWER(c.slug) OR
    LOWER(p.category) LIKE '%' || LOWER(c.name) || '%'
  );

-- Opção 3: Criar categoria "Outros" se não existir e atribuir
DO $$
DECLARE
  v_store_id UUID;
  v_category_id UUID;
BEGIN
  -- Pegar ID da loja
  SELECT id INTO v_store_id FROM stores WHERE slug = 'mercadinhowp' LIMIT 1;
  
  -- Verificar se categoria "Outros" existe
  SELECT id INTO v_category_id FROM categories 
  WHERE store_id = v_store_id AND LOWER(name) = 'outros';
  
  -- Se não existir, criar
  IF v_category_id IS NULL THEN
    INSERT INTO categories (store_id, name, slug, display_order)
    VALUES (v_store_id, 'Outros', 'outros', 999)
    RETURNING id INTO v_category_id;
  END IF;
  
  -- Atribuir produtos sem categoria à categoria "Outros"
  UPDATE products
  SET categoria_id = v_category_id
  WHERE store_id = v_store_id
    AND categoria_id IS NULL;
END $$;

-- ============================================
-- PASSO 4: VERIFICAR RESULTADO
-- ============================================

-- Ver produtos com suas categorias
SELECT 
  p.name as produto,
  c.name as categoria,
  p.categoria_id,
  c.slug as categoria_slug
FROM products p
LEFT JOIN categories c ON c.id = p.categoria_id
WHERE p.store_id = (SELECT id FROM stores WHERE slug = 'mercadinhowp' LIMIT 1)
ORDER BY c.name, p.name;

-- Resultado esperado:
-- produto | categoria | categoria_id              | categoria_slug
-- --------|-----------|---------------------------|----------------
-- X-file  | Burgers   | [uuid-categoria-burgers] | burgers
-- cola    | Bebidas   | [uuid-categoria-bebidas] | bebidas
-- vvvv    | Outros    | [uuid-categoria-outros]  | outros
-- X-file  | Burgers   | [uuid-categoria-burgers] | burgers

-- ============================================
-- PASSO 5: CONTAR PRODUTOS POR CATEGORIA
-- ============================================

SELECT 
  c.name as categoria,
  c.slug,
  COUNT(p.id) as total_produtos,
  STRING_AGG(p.name, ', ') as produtos
FROM categories c
LEFT JOIN products p ON p.categoria_id = c.id
WHERE c.store_id = (SELECT id FROM stores WHERE slug = 'mercadinhowp' LIMIT 1)
GROUP BY c.id, c.name, c.slug
ORDER BY c.display_order;

-- ============================================
-- SCRIPT RÁPIDO PARA TODAS AS LOJAS
-- ============================================

-- Atribuir produtos sem categoria à primeira categoria de cada loja
UPDATE products p
SET categoria_id = (
  SELECT c.id 
  FROM categories c 
  WHERE c.store_id = p.store_id 
  ORDER BY c.display_order 
  LIMIT 1
)
WHERE categoria_id IS NULL
  AND EXISTS (
    SELECT 1 FROM categories WHERE store_id = p.store_id
  );

-- Verificar produtos ainda sem categoria
SELECT 
  COUNT(*) as produtos_sem_categoria,
  STRING_AGG(DISTINCT s.slug, ', ') as lojas_afetadas
FROM products p
JOIN stores s ON s.id = p.store_id
WHERE p.categoria_id IS NULL;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- ✅ Todos os produtos têm categoria_id
-- ✅ Produtos aparecem agrupados por categoria
-- ✅ Página pública mostra produtos
