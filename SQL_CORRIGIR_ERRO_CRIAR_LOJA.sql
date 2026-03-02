-- ============================================
-- CORRIGIR ERRO: Criar Loja
-- ============================================

-- ============================================
-- 1. VERIFICAR FUNÇÃO generate_unique_slug
-- ============================================

-- Ver se função existe
SELECT EXISTS (
  SELECT 1 FROM pg_proc 
  WHERE proname = 'generate_unique_slug'
) AS function_exists;

-- Se não existir, criar:
CREATE OR REPLACE FUNCTION public.generate_unique_slug(store_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
BEGIN
  -- Remover acentos e caracteres especiais
  base_slug := lower(
    translate(
      store_name, 
      'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ', 
      'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'
    )
  );
  
  -- Substituir espaços e caracteres especiais por hífen
  base_slug := regexp_replace(base_slug, '[^a-z0-9]+', '-', 'g');
  
  -- Remover hífens do início e fim
  base_slug := trim(both '-' from base_slug);
  
  -- Se ficar vazio, usar 'loja'
  IF base_slug = '' THEN
    base_slug := 'loja';
  END IF;
  
  final_slug := base_slug;
  
  -- Verificar se slug já existe e adicionar número
  WHILE EXISTS (SELECT 1 FROM public.stores WHERE slug = final_slug) LOOP
    counter := counter + 1;
    final_slug := base_slug || '-' || counter;
  END LOOP;
  
  RETURN final_slug;
END;
$$;

-- ============================================
-- 2. VERIFICAR TABELA STORES
-- ============================================

-- Ver estrutura da tabela
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'stores'
ORDER BY ordinal_position;

-- ============================================
-- 3. VERIFICAR RLS DA TABELA STORES
-- ============================================

-- Ver status RLS
SELECT 
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'stores';

-- Se RLS não estiver habilitado, habilitar:
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 4. RECRIAR POLÍTICAS RLS - STORES
-- ============================================

-- Remover políticas antigas
DROP POLICY IF EXISTS "stores_select" ON public.stores;
DROP POLICY IF EXISTS "stores_all" ON public.stores;
DROP POLICY IF EXISTS "stores_insert" ON public.stores;
DROP POLICY IF EXISTS "stores_update" ON public.stores;
DROP POLICY IF EXISTS "stores_delete" ON public.stores;

-- SELECT: Qualquer um pode ver lojas ativas
CREATE POLICY "stores_select" 
  ON public.stores 
  FOR SELECT 
  USING (is_active = true);

-- INSERT: Usuários autenticados podem criar lojas
CREATE POLICY "stores_insert" 
  ON public.stores 
  FOR INSERT 
  WITH CHECK (auth.uid() = owner_id);

-- UPDATE: Apenas donos podem atualizar suas lojas
CREATE POLICY "stores_update" 
  ON public.stores 
  FOR UPDATE 
  USING (auth.uid() = owner_id);

-- DELETE: Apenas donos podem deletar suas lojas
CREATE POLICY "stores_delete" 
  ON public.stores 
  FOR DELETE 
  USING (auth.uid() = owner_id);

-- ============================================
-- 5. GARANTIR CAMPOS OBRIGATÓRIOS
-- ============================================

-- Verificar se todos os campos existem
DO $$
BEGIN
  -- owner_id
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stores' AND column_name = 'owner_id'
  ) THEN
    ALTER TABLE public.stores 
    ADD COLUMN owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL;
  END IF;
  
  -- slug
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stores' AND column_name = 'slug'
  ) THEN
    ALTER TABLE public.stores 
    ADD COLUMN slug TEXT NOT NULL UNIQUE;
  END IF;
  
  -- is_active
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stores' AND column_name = 'is_active'
  ) THEN
    ALTER TABLE public.stores 
    ADD COLUMN is_active BOOLEAN DEFAULT true;
  END IF;
  
  -- is_open
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stores' AND column_name = 'is_open'
  ) THEN
    ALTER TABLE public.stores 
    ADD COLUMN is_open BOOLEAN DEFAULT true;
  END IF;
  
  -- primary_color
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stores' AND column_name = 'primary_color'
  ) THEN
    ALTER TABLE public.stores 
    ADD COLUMN primary_color TEXT DEFAULT '#FF7A30';
  END IF;
  
  -- delivery_fee
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stores' AND column_name = 'delivery_fee'
  ) THEN
    ALTER TABLE public.stores 
    ADD COLUMN delivery_fee DECIMAL(10,2) DEFAULT 0;
  END IF;
END $$;

-- ============================================
-- 6. CRIAR ÍNDICES
-- ============================================

CREATE INDEX IF NOT EXISTS stores_owner_id_idx ON public.stores(owner_id);
CREATE INDEX IF NOT EXISTS stores_slug_idx ON public.stores(slug);
CREATE INDEX IF NOT EXISTS stores_is_active_idx ON public.stores(is_active);

-- ============================================
-- 7. TESTAR FUNÇÃO generate_unique_slug
-- ============================================

-- Testar geração de slug
SELECT public.generate_unique_slug('Minha Loja Teste') AS slug_gerado;
SELECT public.generate_unique_slug('Hamburgueria do Zé') AS slug_gerado;
SELECT public.generate_unique_slug('Pizzaria Bella') AS slug_gerado;

-- ============================================
-- 8. TESTE: CRIAR LOJA MANUALMENTE
-- ============================================

-- DESCOMENTE para testar (substitua o user_id)
/*
DO $$
DECLARE
  test_user_id UUID;
  test_slug TEXT;
  test_store_id UUID;
BEGIN
  -- Pegar primeiro usuário (ou use seu user_id)
  SELECT id INTO test_user_id FROM auth.users LIMIT 1;
  
  IF test_user_id IS NULL THEN
    RAISE EXCEPTION 'Nenhum usuário encontrado';
  END IF;
  
  -- Gerar slug
  test_slug := public.generate_unique_slug('Loja Teste SQL');
  
  -- Criar loja
  INSERT INTO public.stores (
    owner_id,
    name,
    slug,
    description,
    primary_color,
    delivery_fee,
    is_active,
    is_open
  ) VALUES (
    test_user_id,
    'Loja Teste SQL',
    test_slug,
    'Loja criada via SQL para teste',
    '#FF7A30',
    5.00,
    true,
    true
  )
  RETURNING id INTO test_store_id;
  
  RAISE NOTICE '✅ Loja criada com sucesso! ID: %', test_store_id;
  RAISE NOTICE '🔗 Slug: %', test_slug;
END $$;
*/

-- ============================================
-- 9. VERIFICAÇÃO FINAL
-- ============================================

DO $$
DECLARE
  function_exists BOOLEAN;
  rls_enabled BOOLEAN;
  policies_count INTEGER;
  stores_count INTEGER;
BEGIN
  -- Verificar função
  SELECT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'generate_unique_slug'
  ) INTO function_exists;
  
  IF function_exists THEN
    RAISE NOTICE '✅ Função generate_unique_slug existe';
  ELSE
    RAISE WARNING '❌ Função generate_unique_slug NÃO existe';
  END IF;
  
  -- Verificar RLS
  SELECT rowsecurity INTO rls_enabled FROM pg_tables WHERE tablename = 'stores';
  IF rls_enabled THEN
    RAISE NOTICE '✅ RLS está HABILITADO na tabela stores';
  ELSE
    RAISE WARNING '⚠️  RLS está DESABILITADO na tabela stores';
  END IF;
  
  -- Contar políticas
  SELECT COUNT(*) INTO policies_count FROM pg_policies WHERE tablename = 'stores';
  RAISE NOTICE '🛡️  Políticas RLS: %', policies_count;
  
  IF policies_count >= 4 THEN
    RAISE NOTICE '✅ Todas as políticas criadas (SELECT, INSERT, UPDATE, DELETE)';
  ELSE
    RAISE WARNING '⚠️  Faltam políticas RLS (esperado: 4, encontrado: %)', policies_count;
  END IF;
  
  -- Contar lojas
  SELECT COUNT(*) INTO stores_count FROM public.stores;
  RAISE NOTICE '🏪 Total de lojas: %', stores_count;
END $$;

-- Ver lojas existentes
SELECT 
  id,
  owner_id,
  name,
  slug,
  is_active,
  created_at
FROM public.stores
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- PRONTO! ✅
-- ============================================
-- Agora você pode criar lojas sem erro
