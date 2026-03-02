-- ============================================
-- CORRIGIR CATEGORIA DOS PRODUTOS
-- ============================================

-- PROBLEMA: Produtos aparecem com badge "Outros"
-- CAUSA: Produtos não têm category_id ou estão na categoria errada

-- ============================================
-- PASSO 1: VERIFICAR PRODUTOS E CATEGORIAS
-- ============================================

-- Ver produtos e suas categorias atuais
SELECT 
  p.id,
  p.name as produto,
  p.category_id,
  c.name as categoria_atual,
  c.slug as categoria_slug,
  s.slug as loja
FROM products p
JOIN stores s ON s.id = p.store_id
LEFT JOIN categories c ON c.id = p.category_id
WHERE s.slug IN ('mercadinhowp', 'fcebook')
ORDER BY s.slug, p.name;

-- Ver categorias disponíveis
SELECT 
  c.id,
  c.name as categoria,
  c.slug,
  s.slug as loja,
  c.display_order
FROM categories c
JOIN stores s ON s.id = c.store_id
WHERE s.slug IN ('mercadinhowp', 'fcebook')
ORDER BY s.slug, c.display_order;

-- ============================================
-- PASSO 2: IDENTIFICAR PRODUTOS SEM CATEGORIA
-- ============================================

-- Produtos sem category_id (aparecem como "Outros")
SELECT 
  p.name as produto,
  p.category_id,
  p.category as category_texto,
  s.slug as loja
FROM products p
JOIN stores s ON s.id = p.store_id
WHERE p.category_id IS NULL
  AND s.slug IN ('mercadinhowp', 'fcebook')
ORDER BY s.slug, p.name;

-- ============================================
-- PASSO 3: ATRIBUIR CATEGORIA CORRETA
-- ============================================

-- Opção 1: Atribuir baseado no campo 'category' (texto)
-- Se produto tem category = 'burger', atribuir à categoria 'Hambúrguer'

UPDATE products p
SET category_id = c.id
FROM categories c
WHERE p.store_id = c.store_id
  AND p.category_id IS NULL
  AND (
    -- Mapear texto para categoria
    (LOWER(p.category) IN ('burger', 'hamburguer', 'hamburger', 'sanduiche') AND LOWER(c.name) LIKE '%hambur%') OR
    (LOWER(p.category) IN ('bebida', 'bebidas', 'drink', 'drinks') AND LOWER(c.name) LIKE '%bebida%') OR
    (LOWER(p.category) IN ('pizza', 'pizzas') AND LOWER(c.name) LIKE '%pizza%') OR
    (LOWER(p.category) IN ('sobremesa', 'sobremesas', 'doce', 'doces') AND LOWER(c.name) LIKE '%sobremesa%') OR
    (LOWER(p.category) IN ('outros', 'other') AND LOWER(c.name) LIKE '%outro%')
  );

-- Opção 2: Atribuir todos à primeira categoria da loja
-- (Use se não quiser mapear por nome)

UPDATE products p
SET category_id = (
  SELECT c.id 
  FROM categories c 
  WHERE c.store_id = p.store_id 
  ORDER BY c.display_order 
  LIMIT 1
)
WHERE p.category_id IS NULL
  AND EXISTS (SELECT 1 FROM categories WHERE store_id = p.store_id);

-- Opção 3: Atribuir produto específico a categoria específica
-- Exemplo: Atribuir "X-FRANGO" à categoria "Hambúrguer"

-- Primeiro, ver IDs disponíveis
SELECT 
  p.id as produto_id,
  p.name as produto,
  c.id as categoria_id,
  c.name as categoria,
  s.slug as loja
FROM products p
CROSS JOIN categories c
JOIN stores s ON s.id = p.store_id AND s.id = c.store_id
WHERE p.name = 'X-FRANGO'
  AND s.slug = 'fcebook'
ORDER BY c.display_order;

-- Depois, atualizar (substitua os IDs pelos corretos)
-- UPDATE products 
-- SET category_id = '[ID-DA-CATEGORIA-HAMBURGUER]'
-- WHERE name = 'X-FRANGO' 
--   AND store_id = (SELECT id FROM stores WHERE slug = 'fcebook');

-- ============================================
-- PASSO 4: VERIFICAR RESULTADO
-- ============================================

-- Ver produtos com suas categorias atualizadas
SELECT 
  p.name as produto,
  c.name as categoria,
  c.slug as categoria_slug,
  s.slug as loja,
  p.category_id
FROM products p
JOIN stores s ON s.id = p.store_id
LEFT JOIN categories c ON c.id = p.category_id
WHERE s.slug IN ('mercadinhowp', 'fcebook')
ORDER BY s.slug, c.name, p.name;

-- Contar produtos por categoria
SELECT 
  s.slug as loja,
  c.name as categoria,
  c.slug as categoria_slug,
  COUNT(p.id) as total_produtos,
  STRING_AGG(p.name, ', ' ORDER BY p.name) as produtos
FROM stores s
LEFT JOIN categories c ON c.store_id = s.id
LEFT JOIN products p ON p.category_id = c.id
WHERE s.slug IN ('mercadinhowp', 'fcebook')
GROUP BY s.id, s.slug, c.id, c.name, c.slug, c.display_order
ORDER BY s.slug, c.display_order;

-- Ver produtos ainda sem categoria
SELECT 
  COUNT(*) as produtos_sem_categoria,
  STRING_AGG(p.name, ', ') as produtos
FROM products p
JOIN stores s ON s.id = p.store_id
WHERE p.category_id IS NULL
  AND s.slug IN ('mercadinhowp', 'fcebook');

-- ============================================
-- PASSO 5: SCRIPT RÁPIDO PARA LOJA ESPECÍFICA
-- ============================================

-- Para loja 'fcebook': atribuir todos à categoria "Hambúrguer"
DO $$
DECLARE
  v_store_id UUID;
  v_category_id UUID;
BEGIN
  -- Pegar ID da loja
  SELECT id INTO v_store_id FROM stores WHERE slug = 'fcebook';
  
  -- Pegar ID da primeira categoria (ou específica)
  SELECT id INTO v_category_id 
  FROM categories 
  WHERE store_id = v_store_id 
  ORDER BY display_order 
  LIMIT 1;
  
  -- Atribuir produtos sem categoria
  UPDATE products
  SET category_id = v_category_id
  WHERE store_id = v_store_id
    AND category_id IS NULL;
    
  RAISE NOTICE 'Produtos atualizados para categoria: %', v_category_id;
END $$;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- Todos os produtos devem ter category_id
-- Badge deve mostrar nome correto da categoria
-- Produtos devem aparecer na aba correta

-- Exemplo:
-- produto    | categoria   | categoria_slug | loja
-- -----------|-------------|----------------|--------
-- X-FRANGO   | Hambúrguer  | hamburguer     | fcebook ✅
-- coca       | Bebidas     | bebidas        | fcebook ✅
-- x-file     | Hambúrguer  | hamburguer     | fcebook ✅
