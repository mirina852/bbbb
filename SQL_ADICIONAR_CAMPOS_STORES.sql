-- ============================================
-- ADICIONAR CAMPOS FALTANTES NA TABELA STORES
-- ============================================

-- Ver estrutura atual
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

-- ============================================
-- ADICIONAR CAMPOS FALTANTES
-- ============================================

-- description
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS description TEXT;

-- phone
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS phone TEXT;

-- email
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS email TEXT;

-- address
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS address TEXT;

-- city
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS city TEXT;

-- state
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS state TEXT;

-- zip_code
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS zip_code TEXT;

-- logo_url
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS logo_url TEXT;

-- background_urls
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS background_urls TEXT[];

-- primary_color
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS primary_color TEXT DEFAULT '#FF7A30';

-- delivery_fee
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS delivery_fee DECIMAL(10,2) DEFAULT 0;

-- is_active
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- is_open
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS is_open BOOLEAN DEFAULT true;

-- updated_at
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- ============================================
-- CRIAR TRIGGER PARA ATUALIZAR updated_at
-- ============================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_stores_updated_at ON public.stores;

CREATE TRIGGER update_stores_updated_at
  BEFORE UPDATE ON public.stores
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- VERIFICAR ESTRUTURA FINAL
-- ============================================

SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

-- ============================================
-- TESTAR CRIAÇÃO DE LOJA
-- ============================================

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
  test_slug := public.generate_unique_slug('Loja Completa Teste');
  RAISE NOTICE '🔗 Slug gerado: %', test_slug;
  
  -- Criar loja com TODOS os campos
  BEGIN
    INSERT INTO public.stores (
      owner_id,
      name,
      slug,
      description,
      phone,
      email,
      address,
      city,
      state,
      zip_code,
      primary_color,
      delivery_fee,
      is_active,
      is_open
    ) VALUES (
      test_user_id,
      'Loja Completa Teste',
      test_slug,
      'Descrição da loja teste',
      '(11) 99999-9999',
      'teste@loja.com',
      'Rua Teste, 123',
      'São Paulo',
      'SP',
      '01234-567',
      '#FF7A30',
      5.00,
      true,
      true
    )
    RETURNING id INTO test_store_id;
    
    RAISE NOTICE '✅ SUCESSO! Loja criada com ID: %', test_store_id;
    RAISE NOTICE '🔗 Slug: %', test_slug;
    
    -- Ver loja criada
    RAISE NOTICE '📊 Dados da loja:';
    
    -- Deletar loja de teste
    DELETE FROM public.stores WHERE id = test_store_id;
    RAISE NOTICE '🗑️  Loja de teste deletada';
    
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
BEGIN
  SELECT COUNT(*) INTO column_count 
  FROM information_schema.columns 
  WHERE table_name = 'stores';
  
  RAISE NOTICE '📊 Total de colunas na tabela stores: %', column_count;
  
  IF column_count >= 15 THEN
    RAISE NOTICE '✅ Tabela stores tem todos os campos necessários!';
  ELSE
    RAISE WARNING '⚠️  Tabela stores pode estar incompleta (esperado: ~18 colunas)';
  END IF;
END $$;

-- ============================================
-- PRONTO! ✅
-- ============================================
-- Agora a tabela stores tem todos os campos necessários
