-- ============================================
-- VERIFICAR LOJAS NO BANCO
-- ============================================

-- 1. Ver todas as lojas
SELECT 
  id,
  owner_id,
  name,
  slug,
  is_active,
  created_at
FROM public.stores
ORDER BY created_at DESC;

-- 2. Ver lojas do usuário atual (substitua pelo seu user_id)
-- Para pegar seu user_id, vá em Authentication > Users no Supabase
SELECT 
  id,
  owner_id,
  name,
  slug,
  is_active,
  created_at
FROM public.stores
WHERE owner_id = 'SEU_USER_ID_AQUI'
ORDER BY created_at DESC;

-- 3. Verificar se a tabela stores existe
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'stores'
) AS stores_table_exists;

-- 4. Verificar RLS da tabela stores
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'stores';

-- 5. Ver políticas RLS
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

-- 6. Criar uma loja de teste (se não tiver nenhuma)
-- IMPORTANTE: Substitua 'SEU_USER_ID_AQUI' pelo seu user_id real
/*
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
  'SEU_USER_ID_AQUI',
  'Minha Loja Teste',
  'minha-loja-teste',
  'Loja de teste',
  '#FF7A30',
  5.00,
  true,
  true
)
RETURNING *;
*/

-- 7. Verificar função generate_unique_slug
SELECT EXISTS (
  SELECT FROM pg_proc 
  WHERE proname = 'generate_unique_slug'
) AS function_exists;

-- 8. Testar função generate_unique_slug
SELECT public.generate_unique_slug('Minha Loja Teste') AS slug_gerado;

-- ============================================
-- DIAGNÓSTICO COMPLETO
-- ============================================

DO $$
DECLARE
  store_count INTEGER;
  user_count INTEGER;
  rls_enabled BOOLEAN;
BEGIN
  -- Contar lojas
  SELECT COUNT(*) INTO store_count FROM public.stores;
  RAISE NOTICE '📊 Total de lojas: %', store_count;
  
  -- Contar usuários
  SELECT COUNT(*) INTO user_count FROM auth.users;
  RAISE NOTICE '👥 Total de usuários: %', user_count;
  
  -- Verificar RLS
  SELECT rowsecurity INTO rls_enabled FROM pg_tables WHERE tablename = 'stores';
  IF rls_enabled THEN
    RAISE NOTICE '🔒 RLS está HABILITADO';
  ELSE
    RAISE WARNING '⚠️  RLS está DESABILITADO';
  END IF;
  
  -- Verificar função
  IF EXISTS (SELECT FROM pg_proc WHERE proname = 'generate_unique_slug') THEN
    RAISE NOTICE '✅ Função generate_unique_slug existe';
  ELSE
    RAISE WARNING '❌ Função generate_unique_slug NÃO existe';
  END IF;
END $$;
