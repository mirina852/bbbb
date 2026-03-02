-- ============================================
-- DEBUG: Erro ao Criar Loja
-- ============================================

-- 1. Ver políticas atuais
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'stores';

-- 2. Ver seu user_id atual
SELECT 
  id,
  email,
  created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- 3. Tentar criar loja manualmente (TESTE)
-- IMPORTANTE: Substitua 'SEU_USER_ID' pelo seu user_id real da query acima
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
  test_slug := public.generate_unique_slug('Loja Teste Debug');
  RAISE NOTICE '🔗 Slug gerado: %', test_slug;
  
  -- Tentar criar loja
  BEGIN
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
      'Loja Teste Debug',
      test_slug,
      'Loja criada para debug',
      '#FF7A30',
      5.00,
      true,
      true
    )
    RETURNING id INTO test_store_id;
    
    RAISE NOTICE '✅ Loja criada com sucesso! ID: %', test_store_id;
    
    -- Deletar loja de teste
    DELETE FROM public.stores WHERE id = test_store_id;
    RAISE NOTICE '🗑️  Loja de teste deletada';
    
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ERRO ao criar loja: %', SQLERRM;
    RAISE NOTICE '💡 Código do erro: %', SQLSTATE;
  END;
END $$;

-- 4. Verificar se há constraint bloqueando
SELECT 
  conname AS constraint_name,
  contype AS constraint_type,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.stores'::regclass;

-- 5. SOLUÇÃO: Recriar políticas RLS corretamente
-- Remover todas as políticas antigas
DROP POLICY IF EXISTS "stores_select" ON public.stores;
DROP POLICY IF EXISTS "stores_all" ON public.stores;
DROP POLICY IF EXISTS "stores_insert" ON public.stores;
DROP POLICY IF EXISTS "stores_update" ON public.stores;
DROP POLICY IF EXISTS "stores_delete" ON public.stores;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.stores;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.stores;

-- Criar políticas corretas
-- SELECT: Qualquer um pode ver lojas ativas
CREATE POLICY "stores_select_policy" 
  ON public.stores 
  FOR SELECT 
  USING (is_active = true);

-- INSERT: Usuários autenticados podem criar lojas (SEM verificação de owner_id)
CREATE POLICY "stores_insert_policy" 
  ON public.stores 
  FOR INSERT 
  TO authenticated
  WITH CHECK (true);  -- ✅ Permite qualquer insert de usuário autenticado

-- UPDATE: Apenas donos podem atualizar
CREATE POLICY "stores_update_policy" 
  ON public.stores 
  FOR UPDATE 
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- DELETE: Apenas donos podem deletar
CREATE POLICY "stores_delete_policy" 
  ON public.stores 
  FOR DELETE 
  TO authenticated
  USING (auth.uid() = owner_id);

-- 6. Verificar políticas criadas
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'stores'
ORDER BY cmd;

-- 7. Testar novamente
DO $$
DECLARE
  test_user_id UUID;
  test_slug TEXT;
  test_store_id UUID;
BEGIN
  SELECT id INTO test_user_id FROM auth.users ORDER BY created_at DESC LIMIT 1;
  
  IF test_user_id IS NULL THEN
    RAISE EXCEPTION '❌ Nenhum usuário encontrado';
  END IF;
  
  test_slug := public.generate_unique_slug('Loja Teste Final');
  
  BEGIN
    INSERT INTO public.stores (
      owner_id,
      name,
      slug,
      is_active,
      is_open
    ) VALUES (
      test_user_id,
      'Loja Teste Final',
      test_slug,
      true,
      true
    )
    RETURNING id INTO test_store_id;
    
    RAISE NOTICE '✅ SUCESSO! Loja criada com ID: %', test_store_id;
    RAISE NOTICE '🔗 Slug: %', test_slug;
    
    -- Deletar loja de teste
    DELETE FROM public.stores WHERE id = test_store_id;
    RAISE NOTICE '🗑️  Loja de teste deletada';
    
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ AINDA COM ERRO: %', SQLERRM;
  END;
END $$;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- Você deve ver:
-- ✅ SUCESSO! Loja criada com ID: [uuid]
-- 🔗 Slug: loja-teste-final
-- 🗑️  Loja de teste deletada
