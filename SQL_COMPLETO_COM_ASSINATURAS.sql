-- ============================================
-- SQL COMPLETO - MULTI-TENANT + ASSINATURAS
-- ============================================
-- Execute TODO este SQL de uma vez

-- ============================================
-- 1. CRIAR TABELA STORES
-- ============================================
CREATE TABLE IF NOT EXISTS public.stores (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  phone TEXT,
  email TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  logo_url TEXT,
  background_urls TEXT[],
  primary_color TEXT DEFAULT '#FF7A30',
  delivery_fee DECIMAL(10,2) DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  is_open BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS stores_owner_id_idx ON public.stores(owner_id);
CREATE INDEX IF NOT EXISTS stores_slug_idx ON public.stores(slug);

ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Active stores viewable" ON public.stores;
CREATE POLICY "Active stores viewable" ON public.stores FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Owners manage stores" ON public.stores;
CREATE POLICY "Owners manage stores" ON public.stores FOR ALL USING (auth.uid() = owner_id);

-- ============================================
-- 2. CRIAR/ATUALIZAR TABELAS DE ASSINATURAS
-- ============================================

-- Tabela de planos
CREATE TABLE IF NOT EXISTS public.planos_de_assinatura (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  duration_days INTEGER NOT NULL,
  features TEXT[],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.planos_de_assinatura ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Plans viewable by all" ON public.planos_de_assinatura;
CREATE POLICY "Plans viewable by all" ON public.planos_de_assinatura FOR SELECT USING (is_active = true);

-- Tabela de assinaturas de usuário
CREATE TABLE IF NOT EXISTS public.assinaturas_de_usuario (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  plan_id UUID REFERENCES public.planos_de_assinatura(id) NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
  start_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS assinaturas_user_id_idx ON public.assinaturas_de_usuario(user_id);
CREATE INDEX IF NOT EXISTS assinaturas_status_idx ON public.assinaturas_de_usuario(status);

ALTER TABLE public.assinaturas_de_usuario ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own subscriptions" ON public.assinaturas_de_usuario;
CREATE POLICY "Users view own subscriptions" 
  ON public.assinaturas_de_usuario FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own subscriptions" ON public.assinaturas_de_usuario;
CREATE POLICY "Users manage own subscriptions" 
  ON public.assinaturas_de_usuario FOR ALL 
  USING (auth.uid() = user_id);

-- Tabela de pagamentos de assinatura
CREATE TABLE IF NOT EXISTS public.pagamentos_de_assinatura (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  subscription_id UUID REFERENCES public.assinaturas_de_usuario(id) ON DELETE CASCADE NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
  payment_method TEXT DEFAULT 'pix',
  external_payment_id TEXT,
  qr_code TEXT,
  qr_code_base64 TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS pagamentos_subscription_id_idx ON public.pagamentos_de_assinatura(subscription_id);
CREATE INDEX IF NOT EXISTS pagamentos_external_id_idx ON public.pagamentos_de_assinatura(external_payment_id);

ALTER TABLE public.pagamentos_de_assinatura ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own payments" ON public.pagamentos_de_assinatura;
CREATE POLICY "Users view own payments" 
  ON public.pagamentos_de_assinatura FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.assinaturas_de_usuario 
      WHERE assinaturas_de_usuario.id = pagamentos_de_assinatura.subscription_id 
      AND assinaturas_de_usuario.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users manage own payments" ON public.pagamentos_de_assinatura;
CREATE POLICY "Users manage own payments" 
  ON public.pagamentos_de_assinatura FOR ALL 
  USING (
    EXISTS (
      SELECT 1 FROM public.assinaturas_de_usuario 
      WHERE assinaturas_de_usuario.id = pagamentos_de_assinatura.subscription_id 
      AND assinaturas_de_usuario.user_id = auth.uid()
    )
  );

-- ============================================
-- 3. FUNÇÕES AUXILIARES
-- ============================================

-- Função para gerar slug único
CREATE OR REPLACE FUNCTION public.generate_unique_slug(store_name TEXT)
RETURNS TEXT AS $$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
BEGIN
  base_slug := lower(translate(store_name, 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ', 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'));
  base_slug := regexp_replace(base_slug, '[^a-z0-9]+', '-', 'g');
  base_slug := trim(both '-' from base_slug);
  final_slug := base_slug;
  
  WHILE EXISTS (SELECT 1 FROM public.stores WHERE slug = final_slug) LOOP
    counter := counter + 1;
    final_slug := base_slug || '-' || counter;
  END LOOP;
  
  RETURN final_slug;
END;
$$ LANGUAGE plpgsql;

-- Função para obter store_id do usuário
CREATE OR REPLACE FUNCTION public.get_user_store_id()
RETURNS UUID AS $$
BEGIN
  RETURN (
    SELECT id FROM public.stores 
    WHERE owner_id = auth.uid() 
    AND is_active = true
    ORDER BY created_at DESC
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para obter assinatura ativa do usuário
CREATE OR REPLACE FUNCTION public.get_active_subscription(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  plan_id UUID,
  status TEXT,
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.id,
    a.user_id,
    a.plan_id,
    a.status,
    a.start_date,
    a.end_date
  FROM public.assinaturas_de_usuario a
  WHERE a.user_id = p_user_id
    AND a.status = 'active'
    AND a.end_date > NOW()
  ORDER BY a.end_date DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para verificar se usuário tem assinatura ativa
CREATE OR REPLACE FUNCTION public.has_active_subscription(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.assinaturas_de_usuario
    WHERE user_id = p_user_id
      AND status = 'active'
      AND end_date > NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 4. INSERIR PLANO GRATUITO (se não existir)
-- ============================================
INSERT INTO public.planos_de_assinatura (id, name, price, duration_days, features, is_active)
VALUES (
  '1a375586-9c50-49e7-9f47-6656c401988f',
  'Plano Gratuito',
  0.00,
  7,
  ARRAY['Teste por 7 dias', 'Acesso completo', 'Sem compromisso'],
  true
)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 5. ADICIONAR store_id NAS TABELAS (se necessário)
-- ============================================
ALTER TABLE public.produtos ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id);
ALTER TABLE public.categorias ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id);
ALTER TABLE public.credenciais_de_pagamento_comercial ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id);

-- ============================================
-- 6. VERIFICAÇÃO FINAL
-- ============================================
DO $$
BEGIN
  -- Verificar stores
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'stores') THEN
    RAISE NOTICE '✅ Tabela stores OK';
  END IF;
  
  -- Verificar funções
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_user_store_id') THEN
    RAISE NOTICE '✅ Função get_user_store_id OK';
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_active_subscription') THEN
    RAISE NOTICE '✅ Função get_active_subscription OK';
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'has_active_subscription') THEN
    RAISE NOTICE '✅ Função has_active_subscription OK';
  END IF;
  
  -- Verificar plano gratuito
  IF EXISTS (SELECT 1 FROM public.planos_de_assinatura WHERE id = '1a375586-9c50-49e7-9f47-6656c401988f') THEN
    RAISE NOTICE '✅ Plano gratuito OK';
  END IF;
  
  RAISE NOTICE '🎉 Setup completo! Agora você pode usar o sistema.';
END $$;

-- ============================================
-- PRONTO! ✅
-- ============================================
