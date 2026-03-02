-- ============================================
-- CORRIGIR FUNÇÃO generate_unique_slug
-- ============================================
-- Esta função gera slugs únicos para lojas
-- Parâmetro correto: _name (não store_name)
-- ============================================

-- 1. REMOVER função antiga (se existir com parâmetro errado)
DROP FUNCTION IF EXISTS public.generate_unique_slug(store_name TEXT);
DROP FUNCTION IF EXISTS public.generate_unique_slug(_name TEXT);

-- 2. CRIAR função com parâmetro _name
CREATE OR REPLACE FUNCTION public.generate_unique_slug(_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
BEGIN
  -- Remover acentos e caracteres especiais
  base_slug := lower(
    translate(
      _name, 
      'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ', 
      'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'
    )
  );
  
  -- Substituir espaços e caracteres especiais por hífen
  base_slug := regexp_replace(base_slug, '[^a-z0-9]+', '-', 'g');
  
  -- Remover hífens do início e fim
  base_slug := trim(both '-' from base_slug);
  
  -- Se ficar vazio, usar 'loja'
  IF base_slug = '' OR base_slug IS NULL THEN
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
-- 3. TESTAR A FUNÇÃO
-- ============================================
SELECT public.generate_unique_slug('Minha Loja') AS slug_teste_1;
SELECT public.generate_unique_slug('Hamburgueria do Zé') AS slug_teste_2;
SELECT public.generate_unique_slug('Açaí & Cia') AS slug_teste_3;

-- ============================================
-- 4. VERIFICAÇÃO FINAL
-- ============================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'generate_unique_slug') THEN
    RAISE NOTICE '✅ Função generate_unique_slug criada com sucesso';
  ELSE
    RAISE WARNING '❌ Função generate_unique_slug NÃO foi criada';
  END IF;
END $$;

-- ============================================
-- PRONTO! ✅
-- ============================================
-- Execute este SQL no Supabase SQL Editor
-- Depois tente criar a loja novamente
