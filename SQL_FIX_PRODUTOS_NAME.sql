-- ============================================
-- CORRIGIR CAMPO NAME DA TABELA PRODUTOS
-- ============================================

-- 1. Ver estrutura atual do campo name
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'produtos' AND column_name = 'name';

-- 2. Remover constraint NOT NULL temporariamente
ALTER TABLE public.produtos 
ALTER COLUMN name DROP NOT NULL;

-- 3. Remover DEFAULT
ALTER TABLE public.produtos 
ALTER COLUMN name DROP DEFAULT;

-- 4. Adicionar NOT NULL de volta (sem DEFAULT)
ALTER TABLE public.produtos 
ALTER COLUMN name SET NOT NULL;

-- 5. Verificar novamente
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'produtos' AND column_name = 'name';

-- 6. Testar insert
DO $$
DECLARE
  test_user_id UUID;
  test_store_id UUID;
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
    RAISE EXCEPTION '❌ Nenhuma loja encontrada';
  END IF;
  
  RAISE NOTICE '👤 User ID: %', test_user_id;
  RAISE NOTICE '🏪 Store ID: %', test_store_id;
  
  -- Tentar criar produto
  BEGIN
    INSERT INTO public.produtos (
      store_id,
      name,
      description,
      price,
      available
    ) VALUES (
      test_store_id,
      'Produto Teste',
      'Descrição teste',
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
-- PRONTO! ✅
-- ============================================
