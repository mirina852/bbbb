-- ============================================
-- DEBUG COMPLETO - PRODUTOS
-- ============================================

-- 1. Ver estrutura da tabela produtos
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'produtos'
ORDER BY ordinal_position;

-- 2. Ver políticas RLS
SELECT 
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'produtos';

-- 3. Verificar se RLS está habilitado
SELECT 
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'produtos';

-- 4. Tentar INSERT direto (SEM RLS)
-- Desabilitar RLS temporariamente para teste
ALTER TABLE public.produtos DISABLE ROW LEVEL SECURITY;

-- Tentar inserir produto de teste
DO $$
DECLARE
  test_store_id UUID;
  test_product_id UUID;
BEGIN
  -- Pegar primeira loja
  SELECT id INTO test_store_id FROM public.stores LIMIT 1;
  
  IF test_store_id IS NULL THEN
    RAISE EXCEPTION '❌ Nenhuma loja encontrada';
  END IF;
  
  RAISE NOTICE '🏪 Store ID: %', test_store_id;
  
  -- Tentar inserir produto
  BEGIN
    INSERT INTO public.produtos (
      store_id,
      name,
      description,
      price,
      available
    ) VALUES (
      test_store_id,
      'Produto Teste Direto',
      'Teste sem RLS',
      10.00,
      true
    )
    RETURNING id INTO test_product_id;
    
    RAISE NOTICE '✅ SUCESSO! Produto criado com ID: %', test_product_id;
    
    -- Ver produto criado
    RAISE NOTICE '📊 Verificando produto...';
    
    -- Deletar produto de teste
    DELETE FROM public.produtos WHERE id = test_product_id;
    RAISE NOTICE '🗑️  Produto de teste deletado';
    
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ ERRO: %', SQLERRM;
    RAISE NOTICE '💡 Código: %', SQLSTATE;
  END;
END $$;

-- 5. Reabilitar RLS
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;

-- 6. Verificar se há trigger que pode estar causando problema
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_table = 'produtos';

-- 7. Ver constraints
SELECT 
  conname AS constraint_name,
  contype AS constraint_type,
  pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.produtos'::regclass;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- Se o INSERT direto funcionar, o problema é RLS
-- Se não funcionar, o problema é na estrutura da tabela
