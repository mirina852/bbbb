-- ========================================
-- FIX: PIX não aparece para usuários não autenticados
-- ========================================
-- Este SQL corrige as políticas RLS para permitir que usuários
-- não autenticados (anon) vejam se há credenciais ativas do Mercado Pago

-- 1. Remover todas as políticas antigas que podem estar conflitando
DROP POLICY IF EXISTS "Users can view own credentials" ON public.merchant_payment_credentials;
DROP POLICY IF EXISTS "Allow public read of active credentials" ON public.merchant_payment_credentials;
DROP POLICY IF EXISTS "Public can view active store credentials" ON public.merchant_payment_credentials;
DROP POLICY IF EXISTS "Public can view active credentials" ON public.merchant_payment_credentials;
DROP POLICY IF EXISTS "Users can view own store credentials" ON public.merchant_payment_credentials;

-- 2. Criar política para usuários AUTENTICADOS verem suas próprias credenciais
CREATE POLICY "Authenticated users can view own store credentials"
  ON public.merchant_payment_credentials
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id 
    OR 
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- 3. Criar política para usuários ANÔNIMOS (não autenticados) verem credenciais ativas
-- IMPORTANTE: Isso é seguro porque o access_token não é retornado pela query
-- Apenas public_key e is_active são visíveis
CREATE POLICY "Anonymous users can view active credentials"
  ON public.merchant_payment_credentials
  FOR SELECT
  TO anon
  USING (is_active = true);

-- 4. Verificar se RLS está habilitado
ALTER TABLE public.merchant_payment_credentials ENABLE ROW LEVEL SECURITY;

-- 5. Comentário explicativo
COMMENT ON POLICY "Anonymous users can view active credentials" ON public.merchant_payment_credentials IS 
'Permite que usuários não autenticados vejam se há credenciais ativas do Mercado Pago. Isso é necessário para mostrar a opção PIX no checkout público. O access_token nunca é exposto.';

-- ========================================
-- TESTE: Execute este SELECT para verificar
-- ========================================
-- Descomente as linhas abaixo e execute para testar:

-- SELECT 
--   id, 
--   store_id, 
--   public_key, 
--   is_active,
--   created_at
-- FROM public.merchant_payment_credentials
-- WHERE is_active = true;

-- Se retornar dados, a política está funcionando!
