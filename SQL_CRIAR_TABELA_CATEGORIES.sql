-- ============================================
-- CRIAR TABELA CATEGORIES (CATEGORIAS)
-- ============================================

-- 1. Criar tabela categories
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  slug TEXT,
  icon TEXT,
  position INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2. Criar índices
CREATE INDEX IF NOT EXISTS categories_store_id_idx ON public.categories(store_id);
CREATE INDEX IF NOT EXISTS categories_position_idx ON public.categories(position);

-- 3. Habilitar RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- 4. Criar políticas RLS

-- SELECT: Qualquer um pode ver categorias de lojas ativas
CREATE POLICY "categories_select_policy" 
  ON public.categories 
  FOR SELECT 
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE is_active = true
    )
  );

-- INSERT: Apenas donos podem criar categorias em suas lojas
CREATE POLICY "categories_insert_policy" 
  ON public.categories 
  FOR INSERT 
  TO authenticated
  WITH CHECK (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- UPDATE: Apenas donos podem atualizar categorias de suas lojas
CREATE POLICY "categories_update_policy" 
  ON public.categories 
  FOR UPDATE 
  TO authenticated
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  )
  WITH CHECK (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- DELETE: Apenas donos podem deletar categorias de suas lojas
CREATE POLICY "categories_delete_policy" 
  ON public.categories 
  FOR DELETE 
  TO authenticated
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- 5. Criar trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION public.update_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_categories_updated_at ON public.categories;

CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON public.categories
  FOR EACH ROW
  EXECUTE FUNCTION public.update_categories_updated_at();

-- 6. Criar categorias padrão para cada loja existente
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

-- 7. Verificar estrutura
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'categories'
ORDER BY ordinal_position;

-- 8. Verificar políticas
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'categories'
ORDER BY cmd;

-- 9. Ver categorias criadas
SELECT 
  c.id,
  c.name,
  c.icon,
  c.position,
  s.name AS store_name
FROM public.categories c
JOIN public.stores s ON s.id = c.store_id
ORDER BY c.store_id, c.position;

-- 10. Resumo
DO $$
DECLARE
  categories_count INTEGER;
  rls_enabled BOOLEAN;
  policies_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO categories_count FROM public.categories;
  RAISE NOTICE '📁 Total de categorias: %', categories_count;
  
  SELECT rowsecurity INTO rls_enabled FROM pg_tables WHERE tablename = 'categories';
  IF rls_enabled THEN
    RAISE NOTICE '✅ RLS está HABILITADO';
  ELSE
    RAISE WARNING '⚠️  RLS está DESABILITADO';
  END IF;
  
  SELECT COUNT(*) INTO policies_count FROM pg_policies WHERE tablename = 'categories';
  RAISE NOTICE '🛡️  Políticas RLS: %', policies_count;
  
  IF policies_count >= 4 THEN
    RAISE NOTICE '✅ Todas as políticas criadas (SELECT, INSERT, UPDATE, DELETE)';
  ELSE
    RAISE WARNING '⚠️  Faltam políticas RLS';
  END IF;
END $$;

-- ============================================
-- PRONTO! ✅
-- ============================================
-- Tabela categories criada com:
-- ✅ RLS habilitado
-- ✅ 4 políticas de segurança
-- ✅ Categorias padrão para cada loja
-- ✅ Índices para performance
