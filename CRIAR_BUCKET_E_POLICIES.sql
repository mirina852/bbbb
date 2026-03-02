-- ============================================
-- CRIAR BUCKET site-assets E SUAS POLICIES
-- ============================================
-- Execute este script completo no SQL Editor do Supabase

-- PASSO 1: Criar o bucket site-assets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'site-assets',
  'site-assets',
  true,  -- Bucket público
  52428800,  -- 50MB em bytes
  NULL  -- Aceita todos os tipos de arquivo
)
ON CONFLICT (id) DO NOTHING;

-- PASSO 2: Criar as policies de acesso

-- 2.1. Policy para permitir upload (INSERT) - Usuários autenticados
CREATE POLICY "Authenticated users can upload to site-assets"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'site-assets');

-- 2.2. Policy para permitir leitura pública (SELECT)
CREATE POLICY "Public read access to site-assets"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'site-assets');

-- 2.3. Policy para permitir update - Usuários autenticados
CREATE POLICY "Authenticated users can update site-assets"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'site-assets')
WITH CHECK (bucket_id = 'site-assets');

-- 2.4. Policy para permitir delete - Usuários autenticados
CREATE POLICY "Authenticated users can delete from site-assets"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'site-assets');

-- ============================================
-- VERIFICAR SE TUDO FOI CRIADO CORRETAMENTE
-- ============================================

-- Verificar se o bucket foi criado
SELECT 
  id,
  name,
  public,
  file_size_limit,
  created_at
FROM storage.buckets 
WHERE name = 'site-assets';

-- Verificar se as 4 policies foram criadas
SELECT 
  policyname,
  cmd as operacao,
  roles
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND (qual LIKE '%site-assets%' OR with_check LIKE '%site-assets%')
ORDER BY cmd;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- Bucket: 1 linha mostrando site-assets com public = true
-- Policies: 4 linhas (DELETE, INSERT, SELECT, UPDATE)
