-- ============================================
-- SQL COMPLETO PARA EXECUTAR NO SUPABASE
-- ============================================
-- Cole este SQL inteiro no SQL Editor do Supabase e execute

-- ============================================
-- 1. CRIAR FUNÇÃO DE UPDATE TIMESTAMP
-- ============================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 2. CRIAR TABELA merchant_payment_credentials
-- ============================================
CREATE TABLE IF NOT EXISTS public.merchant_payment_credentials (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  public_key TEXT NOT NULL,
  access_token TEXT NOT NULL,
  environment TEXT NOT NULL DEFAULT 'production' CHECK (environment IN ('sandbox', 'production')),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Criar índices
CREATE INDEX IF NOT EXISTS merchant_payment_credentials_user_id_idx 
  ON public.merchant_payment_credentials(user_id);

CREATE INDEX IF NOT EXISTS merchant_payment_credentials_active_idx 
  ON public.merchant_payment_credentials(is_active);

-- Habilitar RLS
ALTER TABLE public.merchant_payment_credentials ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Users can view own credentials"
  ON public.merchant_payment_credentials
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own credentials"
  ON public.merchant_payment_credentials
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own credentials"
  ON public.merchant_payment_credentials
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own credentials"
  ON public.merchant_payment_credentials
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Criar trigger
CREATE TRIGGER update_merchant_payment_credentials_updated_at
  BEFORE UPDATE ON public.merchant_payment_credentials
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Comentários
COMMENT ON TABLE public.merchant_payment_credentials IS 'Stores Mercado Pago API credentials for merchants';
COMMENT ON COLUMN public.merchant_payment_credentials.public_key IS 'Mercado Pago Public Key (APP_USR-...)';
COMMENT ON COLUMN public.merchant_payment_credentials.access_token IS 'Mercado Pago Access Token (APP_USR-...)';
COMMENT ON COLUMN public.merchant_payment_credentials.environment IS 'Environment: sandbox or production';

-- ============================================
-- 3. ADICIONAR COLUNAS FALTANTES EM subscription_payments
-- ============================================
-- Adicionar payment_method se não existir
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_payments' 
    AND column_name = 'payment_method'
  ) THEN
    ALTER TABLE public.subscription_payments 
    ADD COLUMN payment_method TEXT DEFAULT 'pix';
  END IF;
END $$;

-- Adicionar external_payment_id se não existir
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_payments' 
    AND column_name = 'external_payment_id'
  ) THEN
    ALTER TABLE public.subscription_payments 
    ADD COLUMN external_payment_id TEXT;
  END IF;
END $$;

-- Criar índice para external_payment_id
CREATE INDEX IF NOT EXISTS subscription_payments_external_payment_id_idx 
  ON public.subscription_payments(external_payment_id);

-- ============================================
-- 4. ADICIONAR COLUNAS EM site_settings
-- ============================================
-- Adicionar coluna background_urls para múltiplas imagens
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS background_urls TEXT[] DEFAULT '{}';

-- Adicionar coluna site_title
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS site_title TEXT;

-- Adicionar coluna delivery_fee
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS delivery_fee DECIMAL(10,2) DEFAULT 5.00;

-- Migrar background_url existente para background_urls
UPDATE public.site_settings 
SET background_urls = ARRAY[background_url]::TEXT[]
WHERE background_url IS NOT NULL 
AND (background_urls IS NULL OR background_urls = '{}');

-- ============================================
-- 5. VERIFICAR SE TUDO FOI CRIADO
-- ============================================
-- Execute este SELECT para confirmar
SELECT 
  'merchant_payment_credentials' as tabela,
  COUNT(*) as existe
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'merchant_payment_credentials'

UNION ALL

SELECT 
  'update_updated_at_column' as tabela,
  COUNT(*) as existe
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name = 'update_updated_at_column'

UNION ALL

SELECT 
  'payment_method column' as tabela,
  COUNT(*) as existe
FROM information_schema.columns
WHERE table_name = 'subscription_payments'
AND column_name = 'payment_method'

UNION ALL

SELECT 
  'external_payment_id column' as tabela,
  COUNT(*) as existe
FROM information_schema.columns
WHERE table_name = 'subscription_payments'
AND column_name = 'external_payment_id'

UNION ALL

SELECT 
  'background_urls column' as tabela,
  COUNT(*) as existe
FROM information_schema.columns
WHERE table_name = 'site_settings'
AND column_name = 'background_urls'

UNION ALL

SELECT 
  'site_title column' as tabela,
  COUNT(*) as existe
FROM information_schema.columns
WHERE table_name = 'site_settings'
AND column_name = 'site_title';

-- ============================================
-- RESULTADO ESPERADO:
-- ============================================
-- Todas as linhas devem mostrar "existe = 1"
-- 
-- Se alguma mostrar "existe = 0", algo não foi criado corretamente
-- ============================================
