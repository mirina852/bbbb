-- ============================================
-- VERIFICAR ESTRUTURA DA TABELA products
-- ============================================

-- 1. Ver TODAS as colunas da tabela products
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'products'
ORDER BY ordinal_position;

-- 2. Verificar se coluna categoria_id existe
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'products' AND column_name = 'categoria_id'
    ) THEN '✅ Coluna categoria_id EXISTE'
    ELSE '❌ Coluna categoria_id NÃO EXISTE'
  END as status_categoria_id,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'products' AND column_name = 'category_id'
    ) THEN '✅ Coluna category_id EXISTE'
    ELSE '❌ Coluna category_id NÃO EXISTE'
  END as status_category_id;

-- 3. Ver dados dos produtos
SELECT * FROM products LIMIT 5;

-- ============================================
-- SE COLUNA NÃO EXISTIR, CRIAR
-- ============================================

-- Adicionar coluna categoria_id se não existir
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS categoria_id UUID REFERENCES public.categories(id) ON DELETE SET NULL;

-- Criar índice para performance
CREATE INDEX IF NOT EXISTS products_categoria_id_idx ON public.products(categoria_id);

-- ============================================
-- VERIFICAR RESULTADO
-- ============================================

-- Ver estrutura atualizada
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'products' 
  AND column_name IN ('categoria_id', 'category_id', 'category')
ORDER BY column_name;
