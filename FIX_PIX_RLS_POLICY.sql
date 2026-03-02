-- ============================================
-- CORREÇÃO: Permitir leitura pública das credenciais do merchant
-- ============================================
-- Execute este SQL no SQL Editor do Supabase para corrigir o problema do PIX

-- Remove a política antiga de SELECT
DROP POLICY IF EXISTS "Users can view own credentials" ON public.merchant_payment_credentials;

-- Cria nova política que permite acesso público para verificar credenciais ativas
CREATE POLICY "Allow public read of active credentials"
  ON public.merchant_payment_credentials
  FOR SELECT
  USING (
    -- Usuários autenticados podem ver suas próprias credenciais
    (auth.uid() = user_id) 
    OR 
    -- Acesso público pode ver credenciais ativas (necessário para a loja)
    (is_active = true)
  );

-- Comentário explicativo
COMMENT ON POLICY "Allow public read of active credentials" ON public.merchant_payment_credentials IS 
'Permite que usuários autenticados vejam suas próprias credenciais e que a loja pública verifique se há credenciais ativas configuradas';

-- Verificar se a política foi criada corretamente
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual
FROM pg_policies 
WHERE tablename = 'merchant_payment_credentials';
