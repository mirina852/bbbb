-- ============================================
-- 🔧 ADICIONAR COLUNAS FALTANTES NA TABELA STORES
-- ============================================
-- Adiciona colunas que o código precisa mas não existem
-- ============================================

-- Adicionar coluna email (se não existir)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'stores' 
    AND column_name = 'email'
  ) THEN
    ALTER TABLE public.stores ADD COLUMN email TEXT;
    RAISE NOTICE '✅ Coluna email adicionada';
  ELSE
    RAISE NOTICE '⚠️ Coluna email já existe';
  END IF;
END $$;

-- Adicionar coluna city (se não existir)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'stores' 
    AND column_name = 'city'
  ) THEN
    ALTER TABLE public.stores ADD COLUMN city TEXT;
    RAISE NOTICE '✅ Coluna city adicionada';
  ELSE
    RAISE NOTICE '⚠️ Coluna city já existe';
  END IF;
END $$;

-- Adicionar coluna state (se não existir)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'stores' 
    AND column_name = 'state'
  ) THEN
    ALTER TABLE public.stores ADD COLUMN state TEXT;
    RAISE NOTICE '✅ Coluna state adicionada';
  ELSE
    RAISE NOTICE '⚠️ Coluna state já existe';
  END IF;
END $$;

-- Adicionar coluna zip_code (se não existir)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'stores' 
    AND column_name = 'zip_code'
  ) THEN
    ALTER TABLE public.stores ADD COLUMN zip_code TEXT;
    RAISE NOTICE '✅ Coluna zip_code adicionada';
  ELSE
    RAISE NOTICE '⚠️ Coluna zip_code já existe';
  END IF;
END $$;

-- Adicionar coluna background_urls (se não existir)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'stores' 
    AND column_name = 'background_urls'
  ) THEN
    ALTER TABLE public.stores ADD COLUMN background_urls TEXT[];
    RAISE NOTICE '✅ Coluna background_urls adicionada';
  ELSE
    RAISE NOTICE '⚠️ Coluna background_urls já existe';
  END IF;
END $$;

-- ============================================
-- 🔍 VERIFICAR ESTRUTURA FINAL
-- ============================================

SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'stores'
ORDER BY ordinal_position;

-- ============================================
-- ✅ PRONTO!
-- ============================================
-- Execute este SQL no Supabase SQL Editor
-- Depois tente criar a loja novamente
