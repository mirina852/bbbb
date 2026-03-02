-- ============================================
-- CORRIGIR ERRO: products_category_check
-- ============================================
-- Erro: "new row for relation products violates check constraint products_category_check"

-- ============================================
-- 1. VERIFICAR CONSTRAINT ATUAL
-- ============================================

-- Ver constraints da tabela produtos
SELECT 
  conname AS constraint_name,
  contype AS constraint_type,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.produtos'::regclass;

-- ============================================
-- 2. REMOVER CONSTRAINT PROBLEMÁTICA
-- ============================================

-- Se a constraint existe, remover
ALTER TABLE public.produtos 
DROP CONSTRAINT IF EXISTS products_category_check;

-- Também verificar se existe na tabela "products" (nome em inglês)
ALTER TABLE IF EXISTS public.products 
DROP CONSTRAINT IF EXISTS products_category_check;

-- ============================================
-- 3. VERIFICAR ESTRUTURA DA TABELA
-- ============================================

-- Ver estrutura da tabela produtos
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'produtos'
ORDER BY ordinal_position;

-- ============================================
-- 4. VERIFICAR SE CATEGORIA É OBRIGATÓRIA
-- ============================================

-- Se category_id for NOT NULL, tornar opcional
ALTER TABLE public.produtos 
ALTER COLUMN category_id DROP NOT NULL;

-- ============================================
-- 5. ADICIONAR CONSTRAINT CORRETA (OPCIONAL)
-- ============================================

-- Se quiser validar que category_id existe na tabela categorias
-- (mas permitir NULL)
ALTER TABLE public.produtos
ADD CONSTRAINT produtos_category_fkey 
FOREIGN KEY (category_id) 
REFERENCES public.categorias(id) 
ON DELETE SET NULL;

-- ============================================
-- 6. VERIFICAR TABELA CATEGORIAS
-- ============================================

-- Ver se existem categorias
SELECT 
  id,
  store_id,
  name,
  position
FROM public.categorias
ORDER BY store_id, position;

-- ============================================
-- 7. CRIAR CATEGORIA PADRÃO (SE NÃO EXISTIR)
-- ============================================

-- Para cada loja, criar uma categoria padrão
INSERT INTO public.categorias (store_id, name, position)
SELECT 
  id AS store_id,
  'Geral' AS name,
  0 AS position
FROM public.stores
WHERE NOT EXISTS (
  SELECT 1 FROM public.categorias 
  WHERE categorias.store_id = stores.id
)
ON CONFLICT DO NOTHING;

-- ============================================
-- 8. VERIFICAÇÃO FINAL
-- ============================================

DO $$
DECLARE
  constraint_exists BOOLEAN;
  produtos_count INTEGER;
  categorias_count INTEGER;
BEGIN
  -- Verificar se constraint foi removida
  SELECT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'products_category_check'
  ) INTO constraint_exists;
  
  IF constraint_exists THEN
    RAISE WARNING '⚠️  Constraint products_category_check ainda existe';
  ELSE
    RAISE NOTICE '✅ Constraint products_category_check removida';
  END IF;
  
  -- Contar produtos
  SELECT COUNT(*) INTO produtos_count FROM public.produtos;
  RAISE NOTICE '📦 Total de produtos: %', produtos_count;
  
  -- Contar categorias
  SELECT COUNT(*) INTO categorias_count FROM public.categorias;
  RAISE NOTICE '📁 Total de categorias: %', categorias_count;
  
  IF categorias_count = 0 THEN
    RAISE WARNING '⚠️  Nenhuma categoria encontrada. Crie categorias antes de adicionar produtos.';
  END IF;
END $$;

-- ============================================
-- 9. TESTE: INSERIR PRODUTO SEM CATEGORIA
-- ============================================

-- Teste para verificar se agora funciona
-- DESCOMENTE para testar (substitua os valores)
/*
INSERT INTO public.produtos (
  store_id,
  name,
  description,
  price,
  category_id,
  available
) VALUES (
  'SEU_STORE_ID_AQUI',
  'Produto Teste',
  'Descrição do produto teste',
  10.00,
  NULL,  -- Sem categoria
  true
)
RETURNING *;
*/

-- ============================================
-- PRONTO! ✅
-- ============================================
-- Agora você pode salvar produtos sem categoria
-- ou com categoria válida
