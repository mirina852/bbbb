-- ============================================
-- CORRIGIR TABELA PRODUTOS
-- ============================================

-- 1. Ver estrutura atual
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'produtos'
ORDER BY ordinal_position;

-- 2. Adicionar campo 'available' (disponivel)
ALTER TABLE public.produtos 
ADD COLUMN IF NOT EXISTS available BOOLEAN DEFAULT true;

-- 3. Adicionar campo 'store_id' se não existir
ALTER TABLE public.produtos 
ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;

-- 4. Adicionar campo 'category_id' se não existir
ALTER TABLE public.produtos 
ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL;

-- 5. Adicionar outros campos necessários
ALTER TABLE public.produtos 
ADD COLUMN IF NOT EXISTS name TEXT NOT NULL DEFAULT '';

ALTER TABLE public.produtos 
ADD COLUMN IF NOT EXISTS description TEXT;

ALTER TABLE public.produtos 
ADD COLUMN IF NOT EXISTS price DECIMAL(10,2) NOT NULL DEFAULT 0;

ALTER TABLE public.produtos 
ADD COLUMN IF NOT EXISTS image_url TEXT;

ALTER TABLE public.produtos 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now();

ALTER TABLE public.produtos 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- 6. Habilitar RLS
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;

-- 7. Remover políticas antigas
DROP POLICY IF EXISTS "produtos_select" ON public.produtos;
DROP POLICY IF EXISTS "produtos_all" ON public.produtos;
DROP POLICY IF EXISTS "produtos_insert" ON public.produtos;
DROP POLICY IF EXISTS "produtos_update" ON public.produtos;
DROP POLICY IF EXISTS "produtos_delete" ON public.produtos;

-- 8. Criar políticas RLS corretas

-- SELECT: Qualquer um pode ver produtos disponíveis de lojas ativas
CREATE POLICY "produtos_select_policy" 
  ON public.produtos 
  FOR SELECT 
  USING (
    available = true 
    AND store_id IN (
      SELECT id FROM public.stores WHERE is_active = true
    )
  );

-- INSERT: Apenas donos podem criar produtos em suas lojas
CREATE POLICY "produtos_insert_policy" 
  ON public.produtos 
  FOR INSERT 
  TO authenticated
  WITH CHECK (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- UPDATE: Apenas donos podem atualizar produtos de suas lojas
CREATE POLICY "produtos_update_policy" 
  ON public.produtos 
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

-- DELETE: Apenas donos podem deletar produtos de suas lojas
CREATE POLICY "produtos_delete_policy" 
  ON public.produtos 
  FOR DELETE 
  TO authenticated
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- 9. Criar índices
CREATE INDEX IF NOT EXISTS produtos_store_id_idx ON public.produtos(store_id);
CREATE INDEX IF NOT EXISTS produtos_category_id_idx ON public.produtos(category_id);
CREATE INDEX IF NOT EXISTS produtos_available_idx ON public.produtos(available);

-- 10. Criar trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION public.update_produtos_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_produtos_updated_at ON public.produtos;

CREATE TRIGGER update_produtos_updated_at
  BEFORE UPDATE ON public.produtos
  FOR EACH ROW
  EXECUTE FUNCTION public.update_produtos_updated_at();

-- 11. Verificar estrutura final
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'produtos'
ORDER BY ordinal_position;

-- 12. Verificar políticas
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'produtos'
ORDER BY cmd;

-- 13. Testar criação de produto
DO $$
DECLARE
  test_user_id UUID;
  test_store_id UUID;
  test_category_id UUID;
  test_product_id UUID;
BEGIN
  -- Pegar primeiro usuário
  SELECT id INTO test_user_id FROM auth.users ORDER BY created_at DESC LIMIT 1;
  
  IF test_user_id IS NULL THEN
    RAISE EXCEPTION '❌ Nenhum usuário encontrado';
  END IF;
  
  -- Pegar primeira loja do usuário
  SELECT id INTO test_store_id FROM public.stores WHERE owner_id = test_user_id LIMIT 1;
  
  IF test_store_id IS NULL THEN
    RAISE EXCEPTION '❌ Nenhuma loja encontrada para o usuário';
  END IF;
  
  -- Pegar primeira categoria da loja
  SELECT id INTO test_category_id FROM public.categories WHERE store_id = test_store_id LIMIT 1;
  
  RAISE NOTICE '👤 User ID: %', test_user_id;
  RAISE NOTICE '🏪 Store ID: %', test_store_id;
  RAISE NOTICE '📁 Category ID: %', test_category_id;
  
  -- Tentar criar produto
  BEGIN
    INSERT INTO public.produtos (
      store_id,
      category_id,
      name,
      description,
      price,
      available
    ) VALUES (
      test_store_id,
      test_category_id,
      'Produto Teste',
      'Descrição do produto teste',
      10.00,
      true
    )
    RETURNING id INTO test_product_id;
    
    RAISE NOTICE '✅ SUCESSO! Produto criado com ID: %', test_product_id;
    
    -- Deletar produto de teste
    DELETE FROM public.produtos WHERE id = test_product_id;
    RAISE NOTICE '🗑️  Produto de teste deletado';
    
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ERRO: %', SQLERRM;
    RAISE NOTICE '💡 Código: %', SQLSTATE;
  END;
END $$;

-- ============================================
-- RESUMO
-- ============================================

DO $$
DECLARE
  column_count INTEGER;
  rls_enabled BOOLEAN;
  policies_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO column_count FROM information_schema.columns WHERE table_name = 'produtos';
  RAISE NOTICE '📊 Total de colunas: %', column_count;
  
  SELECT rowsecurity INTO rls_enabled FROM pg_tables WHERE tablename = 'produtos';
  IF rls_enabled THEN
    RAISE NOTICE '✅ RLS está HABILITADO';
  ELSE
    RAISE WARNING '⚠️  RLS está DESABILITADO';
  END IF;
  
  SELECT COUNT(*) INTO policies_count FROM pg_policies WHERE tablename = 'produtos';
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
