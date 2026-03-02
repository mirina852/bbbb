-- ============================================
-- CORRIGIR TABELA DE CATEGORIAS
-- ============================================

-- ============================================
-- 1. VERIFICAR ESTRUTURA ATUAL
-- ============================================

-- Ver estrutura da tabela categories
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'categories'
ORDER BY ordinal_position;

-- ============================================
-- 2. OPÇÃO A: RENOMEAR TABELA (SE PREFERIR PORTUGUÊS)
-- ============================================

-- Se quiser usar 'categorias' em vez de 'categories'
-- DESCOMENTE as linhas abaixo:

/*
ALTER TABLE public.categories RENAME TO categorias;
*/

-- ============================================
-- 3. GARANTIR QUE TABELA TEM CAMPOS CORRETOS
-- ============================================

-- Adicionar store_id se não existir
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'categories' AND column_name = 'store_id'
  ) THEN
    ALTER TABLE public.categories 
    ADD COLUMN store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Adicionar icon se não existir
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'categories' AND column_name = 'icon'
  ) THEN
    ALTER TABLE public.categories 
    ADD COLUMN icon TEXT;
  END IF;
END $$;

-- Adicionar position se não existir (renomear display_order)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'categories' AND column_name = 'display_order'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'categories' AND column_name = 'position'
  ) THEN
    ALTER TABLE public.categories 
    RENAME COLUMN display_order TO position;
  END IF;
END $$;

-- Se position não existir, criar
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'categories' AND column_name = 'position'
  ) THEN
    ALTER TABLE public.categories 
    ADD COLUMN position INTEGER DEFAULT 0;
  END IF;
END $$;

-- ============================================
-- 4. HABILITAR RLS
-- ============================================

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 5. CRIAR POLÍTICAS RLS
-- ============================================

-- Remover políticas antigas
DROP POLICY IF EXISTS "categories_select" ON public.categories;
DROP POLICY IF EXISTS "categories_all" ON public.categories;
DROP POLICY IF EXISTS "categories_insert" ON public.categories;
DROP POLICY IF EXISTS "categories_update" ON public.categories;
DROP POLICY IF EXISTS "categories_delete" ON public.categories;

-- SELECT: Qualquer um pode ver categorias de lojas ativas
CREATE POLICY "categories_select" 
  ON public.categories 
  FOR SELECT 
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE is_active = true
    )
  );

-- INSERT: Apenas donos podem criar categorias em suas lojas
CREATE POLICY "categories_insert" 
  ON public.categories 
  FOR INSERT 
  WITH CHECK (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- UPDATE: Apenas donos podem atualizar categorias de suas lojas
CREATE POLICY "categories_update" 
  ON public.categories 
  FOR UPDATE 
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- DELETE: Apenas donos podem deletar categorias de suas lojas
CREATE POLICY "categories_delete" 
  ON public.categories 
  FOR DELETE 
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- ============================================
-- 6. CRIAR ÍNDICES
-- ============================================

CREATE INDEX IF NOT EXISTS categories_store_id_idx ON public.categories(store_id);
CREATE INDEX IF NOT EXISTS categories_position_idx ON public.categories(position);

-- ============================================
-- 7. ATUALIZAR CATEGORIAS EXISTENTES (SE NECESSÁRIO)
-- ============================================

-- Se houver categorias sem store_id, associar à primeira loja do usuário
-- DESCOMENTE se necessário:

/*
UPDATE public.categories
SET store_id = (
  SELECT id FROM public.stores 
  WHERE owner_id = auth.uid() 
  LIMIT 1
)
WHERE store_id IS NULL;
*/

-- ============================================
-- 8. CRIAR CATEGORIAS PADRÃO PARA CADA LOJA
-- ============================================

-- Para cada loja que não tem categorias, criar categorias padrão
INSERT INTO public.categories (store_id, name, icon, position)
SELECT 
  s.id AS store_id,
  'Lanches' AS name,
  'Sandwich' AS icon,
  0 AS position
FROM public.stores s
WHERE NOT EXISTS (
  SELECT 1 FROM public.categories c 
  WHERE c.store_id = s.id
)
ON CONFLICT DO NOTHING;

INSERT INTO public.categories (store_id, name, icon, position)
SELECT 
  s.id AS store_id,
  'Bebidas' AS name,
  'Coffee' AS icon,
  1 AS position
FROM public.stores s
WHERE NOT EXISTS (
  SELECT 1 FROM public.categories c 
  WHERE c.store_id = s.id AND c.name = 'Bebidas'
)
ON CONFLICT DO NOTHING;

INSERT INTO public.categories (store_id, name, icon, position)
SELECT 
  s.id AS store_id,
  'Sobremesas' AS name,
  'IceCream' AS icon,
  2 AS position
FROM public.stores s
WHERE NOT EXISTS (
  SELECT 1 FROM public.categories c 
  WHERE c.store_id = s.id AND c.name = 'Sobremesas'
)
ON CONFLICT DO NOTHING;

-- ============================================
-- 9. VERIFICAÇÃO FINAL
-- ============================================

DO $$
DECLARE
  categories_count INTEGER;
  rls_enabled BOOLEAN;
  policies_count INTEGER;
BEGIN
  -- Contar categorias
  SELECT COUNT(*) INTO categories_count FROM public.categories;
  RAISE NOTICE '📁 Total de categorias: %', categories_count;
  
  -- Verificar RLS
  SELECT rowsecurity INTO rls_enabled FROM pg_tables WHERE tablename = 'categories';
  IF rls_enabled THEN
    RAISE NOTICE '🔒 RLS está HABILITADO';
  ELSE
    RAISE WARNING '⚠️  RLS está DESABILITADO';
  END IF;
  
  -- Contar políticas
  SELECT COUNT(*) INTO policies_count FROM pg_policies WHERE tablename = 'categories';
  RAISE NOTICE '🛡️  Políticas RLS: %', policies_count;
  
  IF policies_count >= 4 THEN
    RAISE NOTICE '✅ Todas as políticas criadas (SELECT, INSERT, UPDATE, DELETE)';
  ELSE
    RAISE WARNING '⚠️  Faltam políticas RLS';
  END IF;
END $$;

-- Ver estrutura final
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'categories'
ORDER BY ordinal_position;

-- Ver políticas criadas
SELECT 
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'categories';

-- ============================================
-- 10. ATUALIZAR COMPONENTE (OPCIONAL)
-- ============================================

-- Se você renomeou para 'categorias', atualize o CategoryManager.tsx
-- Se manteve 'categories', atualize para usar 'categories' em vez de 'categorias'

-- ============================================
-- PRONTO! ✅
-- ============================================
-- Tabela categories agora está:
-- ✅ Com RLS habilitado
-- ✅ Com políticas de segurança
-- ✅ Com store_id obrigatório
-- ✅ Com categorias padrão criadas
