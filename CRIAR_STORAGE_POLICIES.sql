-- ============================================
-- CRIAR POLICIES PARA O BUCKET site-assets
-- ============================================
-- Execute este script no SQL Editor do Supabase
-- IMPORTANTE: Crie o bucket 'site-assets' primeiro via Dashboard

-- 1. Policy para permitir upload (INSERT) - Usuários autenticados
CREATE POLICY "Authenticated users can upload to site-assets"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'site-assets');

-- 2. Policy para permitir leitura pública (SELECT)
CREATE POLICY "Public read access to site-assets"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'site-assets');

-- 3. Policy para permitir update - Usuários autenticados
CREATE POLICY "Authenticated users can update site-assets"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'site-assets')
WITH CHECK (bucket_id = 'site-assets');

-- 4. Policy para permitir delete - Usuários autenticados
CREATE POLICY "Authenticated users can delete from site-assets"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'site-assets');

-- ============================================
-- VERIFICAR SE AS POLICIES FORAM CRIADAS
-- ============================================

SELECT 
  policyname,
  cmd,
  roles,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND (qual LIKE '%site-assets%' OR with_check LIKE '%site-assets%')
ORDER BY policyname;

-- ============================================
-- VERIFICAR SE O BUCKET EXISTE
-- ============================================

SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE name = 'site-assets';
