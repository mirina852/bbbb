-- ============================================
-- SQL PARA FAZER TODAS AS PÁGINAS FUNCIONAREM
-- ============================================
-- Este SQL faz funcionar:
-- ✅ Dashboard
-- ✅ Produtos
-- ✅ Pedidos
-- ✅ Assinatura
-- ✅ Configurações

-- ============================================
-- COPIE E COLE TODO ESTE SQL NO SUPABASE
-- ============================================

-- 1️⃣ TABELA STORES (para Configurações)
CREATE TABLE IF NOT EXISTS public.stores (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
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
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS stores_owner_id_idx ON public.stores(owner_id);
CREATE INDEX IF NOT EXISTS stores_slug_idx ON public.stores(slug);
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "stores_select" ON public.stores;
CREATE POLICY "stores_select" ON public.stores FOR SELECT USING (is_active = true);
DROP POLICY IF EXISTS "stores_all" ON public.stores;
CREATE POLICY "stores_all" ON public.stores FOR ALL USING (auth.uid() = owner_id);

-- 2️⃣ TABELAS DE ASSINATURAS (para página Assinatura)
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  price DECIMAL(10,2) NOT NULL,
  duration_days INTEGER NOT NULL,
  is_trial BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  features TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  subscription_plan_id UUID REFERENCES public.subscription_plans(id) NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.subscription_payments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  subscription_id UUID REFERENCES public.user_subscriptions(id) ON DELETE CASCADE NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
  payment_method TEXT DEFAULT 'pix',
  external_payment_id TEXT,
  qr_code TEXT,
  qr_code_base64 TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "plans_select" ON public.subscription_plans;
CREATE POLICY "plans_select" ON public.subscription_plans FOR SELECT USING (is_active = true);
DROP POLICY IF EXISTS "plans_all" ON public.subscription_plans;
CREATE POLICY "plans_all" ON public.subscription_plans FOR ALL USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "subs_select" ON public.user_subscriptions;
CREATE POLICY "subs_select" ON public.user_subscriptions FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "subs_insert" ON public.user_subscriptions;
CREATE POLICY "subs_insert" ON public.user_subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "subs_update" ON public.user_subscriptions;
CREATE POLICY "subs_update" ON public.user_subscriptions FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "payments_select" ON public.subscription_payments;
CREATE POLICY "payments_select" ON public.subscription_payments FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.user_subscriptions WHERE user_subscriptions.id = subscription_payments.subscription_id AND user_subscriptions.user_id = auth.uid())
);
DROP POLICY IF EXISTS "payments_insert" ON public.subscription_payments;
CREATE POLICY "payments_insert" ON public.subscription_payments FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.user_subscriptions WHERE user_subscriptions.id = subscription_payments.subscription_id AND user_subscriptions.user_id = auth.uid())
);
DROP POLICY IF EXISTS "payments_update" ON public.subscription_payments;
CREATE POLICY "payments_update" ON public.subscription_payments FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.user_subscriptions WHERE user_subscriptions.id = subscription_payments.subscription_id AND user_subscriptions.user_id = auth.uid())
);

-- 3️⃣ ADICIONAR store_id (para Produtos e Pedidos)
ALTER TABLE public.produtos ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id);
ALTER TABLE public.categorias ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id);
ALTER TABLE public.credenciais_de_pagamento_comercial ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id);

CREATE INDEX IF NOT EXISTS produtos_store_id_idx ON public.produtos(store_id);
CREATE INDEX IF NOT EXISTS orders_store_id_idx ON public.orders(store_id);

-- 4️⃣ FUNÇÕES ESSENCIAIS
DROP FUNCTION IF EXISTS public.generate_unique_slug(TEXT);
CREATE FUNCTION public.generate_unique_slug(store_name TEXT) RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE base_slug TEXT; final_slug TEXT; counter INTEGER := 0;
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
END; $$;

DROP FUNCTION IF EXISTS public.get_user_store_id();
CREATE FUNCTION public.get_user_store_id() RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN (SELECT id FROM public.stores WHERE owner_id = auth.uid() AND is_active = true ORDER BY created_at DESC LIMIT 1);
END; $$;

DROP FUNCTION IF EXISTS public.get_active_subscription(UUID);
CREATE FUNCTION public.get_active_subscription(_user_id UUID)
RETURNS TABLE (id UUID, plan_name TEXT, plan_slug TEXT, status TEXT, expires_at TIMESTAMP WITH TIME ZONE, days_remaining INTEGER)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT us.id, sp.name, sp.slug, us.status, us.expires_at,
    CASE WHEN us.expires_at > NOW() THEN EXTRACT(DAY FROM us.expires_at - NOW())::INTEGER ELSE 0 END
  FROM public.user_subscriptions us
  JOIN public.subscription_plans sp ON sp.id = us.subscription_plan_id
  WHERE us.user_id = _user_id AND us.status = 'active' AND us.expires_at > NOW()
  ORDER BY us.expires_at DESC LIMIT 1;
END; $$;

DROP FUNCTION IF EXISTS public.has_active_subscription(UUID);
CREATE FUNCTION public.has_active_subscription(_user_id UUID) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM public.user_subscriptions WHERE user_id = _user_id AND status = 'active' AND expires_at > NOW());
END; $$;

-- 5️⃣ INSERIR PLANOS
INSERT INTO public.subscription_plans (id, name, slug, price, duration_days, is_trial, features) VALUES
('1a375586-9c50-49e7-9f47-6656c401988f', 'Teste Gratuito', 'free-trial', 0.00, 7, true, ARRAY['Acesso completo por 7 dias', 'Gestão de produtos e pedidos', 'Dashboard com estatísticas', 'Sem compromisso']),
('7ef25147-395e-4cea-88f8-42d032b74f35', 'Plano Mensal', 'monthly', 29.90, 30, false, ARRAY['Acesso completo', 'Gestão de produtos e pedidos', 'Dashboard com estatísticas', 'Suporte prioritário'])
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, price = EXCLUDED.price, features = EXCLUDED.features;

INSERT INTO public.subscription_plans (name, slug, price, duration_days, is_trial, features) VALUES
('Plano Anual', 'yearly', 299.90, 365, false, ARRAY['Acesso completo', 'Gestão de produtos e pedidos', 'Dashboard com estatísticas', 'Suporte VIP exclusivo', 'Desconto de 16%'])
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, price = EXCLUDED.price, features = EXCLUDED.features;

-- 6️⃣ VERIFICAÇÃO
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'stores') THEN RAISE NOTICE '✅ Stores OK'; END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscription_plans') THEN RAISE NOTICE '✅ Subscription Plans OK'; END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_user_store_id') THEN RAISE NOTICE '✅ get_user_store_id OK'; END IF;
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_active_subscription') THEN RAISE NOTICE '✅ get_active_subscription OK'; END IF;
  RAISE NOTICE '🎉 TUDO PRONTO! Recarregue o site (Ctrl+F5)';
END $$;

-- ============================================
-- PRONTO! AGORA TODAS AS PÁGINAS VÃO FUNCIONAR:
-- ✅ Dashboard - mostra estatísticas da loja
-- ✅ Produtos - gerencia produtos da loja
-- ✅ Pedidos - gerencia pedidos da loja
-- ✅ Assinatura - mostra plano ativo
-- ✅ Configurações - edita dados da loja
-- ============================================
