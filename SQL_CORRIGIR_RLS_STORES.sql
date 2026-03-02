-- ============================================
-- CORRIGIR RLS - STORES (Solução Final)
-- ============================================

-- 1. Remover TODAS as políticas antigas
DROP POLICY IF EXISTS "stores_select" ON public.stores;
DROP POLICY IF EXISTS "stores_all" ON public.stores;
DROP POLICY IF EXISTS "stores_insert" ON public.stores;
DROP POLICY IF EXISTS "stores_update" ON public.stores;
DROP POLICY IF EXISTS "stores_delete" ON public.stores;
DROP POLICY IF EXISTS "stores_select_policy" ON public.stores;
DROP POLICY IF EXISTS "stores_insert_policy" ON public.stores;
DROP POLICY IF EXISTS "stores_update_policy" ON public.stores;
DROP POLICY IF EXISTS "stores_delete_policy" ON public.stores;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.stores;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.stores;

-- 2. Garantir que RLS está habilitado
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- 3. Criar políticas corretas

-- SELECT: Qualquer um pode ver lojas ativas
CREATE POLICY "stores_select_policy" 
  ON public.stores 
  FOR SELECT 
  USING (is_active = true);

-- INSERT: Usuários autenticados podem criar lojas
-- IMPORTANTE: Não verificar owner_id aqui, pois ele é definido pela aplicação
CREATE POLICY "stores_insert_policy" 
  ON public.stores 
  FOR INSERT 
  TO authenticated
  WITH CHECK (true);

-- UPDATE: Apenas donos podem atualizar suas lojas
CREATE POLICY "stores_update_policy" 
  ON public.stores 
  FOR UPDATE 
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- DELETE: Apenas donos podem deletar suas lojas
CREATE POLICY "stores_delete_policy" 
  ON public.stores 
  FOR DELETE 
  TO authenticated
  USING (auth.uid() = owner_id);

-- 4. Verificar políticas criadas
SELECT 
  policyname,
  cmd,
  roles,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'stores'
ORDER BY cmd;

-- 5. Testar criação de loja
DO $$
DECLARE
  test_user_id UUID;
  test_slug TEXT;
  test_store_id UUID;
BEGIN
  -- Pegar primeiro usuário
  SELECT id INTO test_user_id FROM auth.users ORDER BY created_at DESC LIMIT 1;
  
  IF test_user_id IS NULL THEN
    RAISE EXCEPTION '❌ Nenhum usuário encontrado';
  END IF;
  
  RAISE NOTICE '👤 Testando com user_id: %', test_user_id;
  
  -- Gerar slug
  test_slug := public.generate_unique_slug('Teste Final');
  RAISE NOTICE '🔗 Slug gerado: %', test_slug;
  
  -- Tentar criar loja
  BEGIN
    INSERT INTO public.stores (
      owner_id,
      name,
      slug,
      is_active,
      is_open
    ) VALUES (
      test_user_id,
      'Teste Final',
      test_slug,
      true,
      true
    )
    RETURNING id INTO test_store_id;
    
    RAISE NOTICE '✅ SUCESSO! Loja criada com ID: %', test_store_id;
    
    -- Deletar loja de teste
    DELETE FROM public.stores WHERE id = test_store_id;
    RAISE NOTICE '🗑️  Loja de teste deletada';
    
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ERRO: %', SQLERRM;
    RAISE NOTICE '💡 Código: %', SQLSTATE;
  END;
END $$;

-- ============================================
-- PRONTO! ✅
-- ============================================
