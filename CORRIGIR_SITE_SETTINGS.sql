-- ============================================
-- CORRIGIR TABELA site_settings
-- ============================================
-- Este script garante que a tabela site_settings tenha a estrutura correta

-- 1. Verificar estrutura atual da tabela
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'site_settings'
ORDER BY ordinal_position;

-- ============================================
-- OPÇÃO 1: Se a tabela NÃO tem user_id
-- ============================================
-- Adicionar coluna user_id (se não existir)
-- Descomente as linhas abaixo se necessário:

-- ALTER TABLE public.site_settings 
-- ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Preencher user_id existente com o primeiro usuário admin
-- UPDATE public.site_settings 
-- SET user_id = (SELECT id FROM auth.users LIMIT 1)
-- WHERE user_id IS NULL;

-- Tornar user_id obrigatório
-- ALTER TABLE public.site_settings 
-- ALTER COLUMN user_id SET NOT NULL;

-- ============================================
-- OPÇÃO 2: Se a tabela tem user_id mas está NULL
-- ============================================
-- Preencher registros existentes com user_id
-- UPDATE public.site_settings 
-- SET user_id = (SELECT id FROM auth.users LIMIT 1)
-- WHERE user_id IS NULL;

-- ============================================
-- OPÇÃO 3: Recriar a tabela do zero (CUIDADO!)
-- ============================================
-- Só use se quiser apagar todos os dados existentes

-- DROP TABLE IF EXISTS public.site_settings CASCADE;

-- CREATE TABLE public.site_settings (
--   id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
--   user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
--   logo_url TEXT,
--   background_urls TEXT[],
--   primary_color TEXT,
--   created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
--   updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
-- );

-- -- Enable RLS
-- ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

-- -- Policies
-- CREATE POLICY "Anyone can view site settings" 
-- ON public.site_settings 
-- FOR SELECT 
-- USING (true);

-- CREATE POLICY "Authenticated users can manage site settings" 
-- ON public.site_settings 
-- FOR ALL
-- USING (auth.uid() = user_id)
-- WITH CHECK (auth.uid() = user_id);

-- -- Trigger para atualizar updated_at
-- CREATE TRIGGER update_site_settings_updated_at
-- BEFORE UPDATE ON public.site_settings
-- FOR EACH ROW
-- EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- VERIFICAR RESULTADO
-- ============================================
SELECT * FROM public.site_settings;
