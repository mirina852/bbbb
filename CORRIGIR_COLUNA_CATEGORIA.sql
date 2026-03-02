-- ============================================
-- CORRIGIR COLUNA DE CATEGORIA
-- ============================================

-- ERRO: Could not find the 'category_id' column
-- CAUSA: Código está tentando usar 'category_id' mas coluna se chama 'categoria_id'

-- ============================================
-- OPÇÃO 1: VERIFICAR QUAL COLUNA EXISTE
-- ============================================

SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'products'
  AND column_name IN ('category_id', 'categoria_id')
ORDER BY column_name;

-- ============================================
-- OPÇÃO 2: REMOVER categoria_id E CRIAR category_id
-- ============================================

-- Se a coluna categoria_id existe, vamos renomear para category_id
-- (para seguir padrão inglês da tabela)

-- 1. Remover índice antigo (se existir)
DROP INDEX IF EXISTS products_categoria_id_idx;

-- 2. Renomear coluna de categoria_id para category_id
ALTER TABLE public.products 
RENAME COLUMN categoria_id TO category_id;

-- 3. Criar índice com novo nome
CREATE INDEX IF NOT EXISTS products_category_id_idx 
ON public.products(category_id);

-- 4. Verificar resultado
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'products'
  AND column_name IN ('category_id', 'categoria_id')
ORDER BY column_name;

-- Resultado esperado: Apenas 'category_id' deve existir

-- ============================================
-- OPÇÃO 3: CRIAR category_id SE NÃO EXISTIR
-- ============================================

-- Se nenhuma coluna existe, criar category_id
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS category_id UUID 
REFERENCES public.categories(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS products_category_id_idx 
ON public.products(category_id);

-- ============================================
-- ATUALIZAR PRODUTOS COM CATEGORIA
-- ============================================

-- Atribuir produtos à primeira categoria de cada loja
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

-- ============================================
-- VERIFICAR RESULTADO FINAL
-- ============================================

-- Ver estrutura
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'products'
ORDER BY ordinal_position;

-- Ver produtos com categorias
SELECT 
  p.name as produto,
  c.name as categoria,
  p.category_id,
  s.slug as loja
FROM products p
JOIN stores s ON s.id = p.store_id
LEFT JOIN categories c ON c.id = p.category_id
ORDER BY s.slug, c.name, p.name;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- ✅ Coluna 'category_id' existe (não 'categoria_id')
-- ✅ Todos os produtos têm category_id
-- ✅ Produtos aparecem com categoria
