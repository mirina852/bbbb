-- ============================================
-- SQL COMPLETO - TUDO QUE O SITE PRECISA
-- Execute TODO este SQL no Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. TABELAS PRINCIPAIS
-- ============================================

-- 1.1 STORES (Lojas)
CREATE TABLE IF NOT EXISTS public.stores (
  id UUID NOT NULL DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  owner_id UUID NOT NULL,
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
  delivery_fee NUMERIC DEFAULT 5.00,
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_open BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.2 CATEGORIES (Categorias)
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID NOT NULL DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  store_id UUID NOT NULL,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  icon TEXT,
  position INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.3 PRODUCTS (Produtos)
CREATE TABLE IF NOT EXISTS public.products (
  id UUID NOT NULL DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  store_id UUID NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC NOT NULL,
  image TEXT,
  category TEXT DEFAULT 'outros',
  category_id UUID,
  available BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.4 INGREDIENTS (Ingredientes)
CREATE TABLE IF NOT EXISTS public.ingredients (
  id UUID NOT NULL DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  product_id UUID NOT NULL,
  name TEXT NOT NULL,
  is_extra BOOLEAN DEFAULT false,
  price NUMERIC,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.5 ORDERS (Pedidos)
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID NOT NULL DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  store_id UUID NOT NULL,
  customer_name TEXT NOT NULL,
  customer_phone TEXT,
  delivery_address TEXT,
  payment_method TEXT,
  payment_status TEXT DEFAULT 'pending',
  external_payment_id TEXT,
  total NUMERIC NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.6 ORDER_ITEMS (Itens dos Pedidos)
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID NOT NULL DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  order_id UUID NOT NULL,
  product_id UUID,
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  price NUMERIC NOT NULL,
  removed_ingredients TEXT[] DEFAULT '{}',
  extra_ingredients JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.7 SUBSCRIPTION_PLANS (Planos de Assinatura)
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id UUID NOT NULL DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  price NUMERIC NOT NULL DEFAULT 0,
  duration_days INTEGER NOT NULL DEFAULT 30,
  is_trial BOOLEAN NOT NULL DEFAULT false,
  features JSONB DEFAULT '[]',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.8 USER_SUBSCRIPTIONS (Assinaturas dos Usuários)
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id UUID NOT NULL DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL,
  subscription_plan_id UUID,
  status TEXT NOT NULL DEFAULT 'active',
  current_period_start TIMESTAMPTZ NOT NULL DEFAULT now(),
  current_period_end TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '30 days'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.9 SUBSCRIPTION_PAYMENTS (Pagamentos de Assinatura)
CREATE TABLE IF NOT EXISTS public.subscription_payments (
  id UUID NOT NULL DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL,
  subscription_plan_id UUID,
  amount NUMERIC NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  payment_method TEXT,
  payment_id TEXT,
  external_payment_id TEXT,
  qr_code TEXT,
  qr_code_base64 TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.10 MERCHANT_PAYMENT_CREDENTIALS (Credenciais de Pagamento)
CREATE TABLE IF NOT EXISTS public.merchant_payment_credentials (
  id UUID NOT NULL DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL,
  store_id UUID,
  public_key TEXT NOT NULL,
  access_token TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1.11 SITE_SETTINGS (Configurações do Site)
CREATE TABLE IF NOT EXISTS public.site_settings (
  id UUID NOT NULL DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  user_id UUID NOT NULL,
  store_id UUID,
  site_name TEXT,
  logo_url TEXT,
  background_urls TEXT[],
  primary_color TEXT DEFAULT '#FF6B6B',
  secondary_color TEXT DEFAULT '#4ECDC4',
  delivery_fee NUMERIC DEFAULT 0,
  min_order_value NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- 2. HABILITAR RLS EM TODAS AS TABELAS
-- ============================================

ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchant_payment_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. POLICIES RLS - STORES
-- ============================================
DROP POLICY IF EXISTS "Anyone can view active stores" ON public.stores;
CREATE POLICY "Anyone can view active stores" ON public.stores
  FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Owners can manage own stores" ON public.stores;
CREATE POLICY "Owners can manage own stores" ON public.stores
  FOR ALL USING (auth.uid() = owner_id);

-- ============================================
-- 4. POLICIES RLS - CATEGORIES
-- ============================================
DROP POLICY IF EXISTS "Anyone can view categories" ON public.categories;
CREATE POLICY "Anyone can view categories" ON public.categories
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Store owners can manage categories" ON public.categories;
CREATE POLICY "Store owners can manage categories" ON public.categories
  FOR ALL USING (
    EXISTS (SELECT 1 FROM stores WHERE stores.id = categories.store_id AND stores.owner_id = auth.uid())
  );

-- ============================================
-- 5. POLICIES RLS - PRODUCTS
-- ============================================
DROP POLICY IF EXISTS "Anyone can view available products" ON public.products;
CREATE POLICY "Anyone can view available products" ON public.products
  FOR SELECT USING (available = true);

DROP POLICY IF EXISTS "Store owners can manage products" ON public.products;
CREATE POLICY "Store owners can manage products" ON public.products
  FOR ALL USING (
    EXISTS (SELECT 1 FROM stores WHERE stores.id = products.store_id AND stores.owner_id = auth.uid())
  );

-- ============================================
-- 6. POLICIES RLS - INGREDIENTS
-- ============================================
DROP POLICY IF EXISTS "Anyone can view ingredients" ON public.ingredients;
CREATE POLICY "Anyone can view ingredients" ON public.ingredients
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Product owners can manage ingredients" ON public.ingredients;
CREATE POLICY "Product owners can manage ingredients" ON public.ingredients
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM products JOIN stores ON stores.id = products.store_id
      WHERE products.id = ingredients.product_id AND stores.owner_id = auth.uid()
    )
  );

-- ============================================
-- 7. POLICIES RLS - ORDERS
-- ============================================
DROP POLICY IF EXISTS "Anyone can view orders" ON public.orders;
CREATE POLICY "Anyone can view orders" ON public.orders
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can create orders" ON public.orders;
CREATE POLICY "Anyone can create orders" ON public.orders
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Store owners can manage orders" ON public.orders;
CREATE POLICY "Store owners can manage orders" ON public.orders
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM stores WHERE stores.id = orders.store_id AND stores.owner_id = auth.uid())
  );

-- ============================================
-- 8. POLICIES RLS - ORDER_ITEMS
-- ============================================
DROP POLICY IF EXISTS "Anyone can view order items" ON public.order_items;
CREATE POLICY "Anyone can view order items" ON public.order_items
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can create order items" ON public.order_items;
CREATE POLICY "Anyone can create order items" ON public.order_items
  FOR INSERT WITH CHECK (true);

-- ============================================
-- 9. POLICIES RLS - SUBSCRIPTION_PLANS
-- ============================================
DROP POLICY IF EXISTS "Anyone can view active plans" ON public.subscription_plans;
CREATE POLICY "Anyone can view active plans" ON public.subscription_plans
  FOR SELECT USING (is_active = true);

-- ============================================
-- 10. POLICIES RLS - USER_SUBSCRIPTIONS
-- ============================================
DROP POLICY IF EXISTS "Users can view own subscription" ON public.user_subscriptions;
CREATE POLICY "Users can view own subscription" ON public.user_subscriptions
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own subscription" ON public.user_subscriptions;
CREATE POLICY "Users can insert own subscription" ON public.user_subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own subscription" ON public.user_subscriptions;
CREATE POLICY "Users can update own subscription" ON public.user_subscriptions
  FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- 11. POLICIES RLS - SUBSCRIPTION_PAYMENTS
-- ============================================
DROP POLICY IF EXISTS "Users can view own payments" ON public.subscription_payments;
CREATE POLICY "Users can view own payments" ON public.subscription_payments
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own payments" ON public.subscription_payments;
CREATE POLICY "Users can create own payments" ON public.subscription_payments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own payments" ON public.subscription_payments;
CREATE POLICY "Users can update own payments" ON public.subscription_payments
  FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- 12. POLICIES RLS - MERCHANT_PAYMENT_CREDENTIALS
-- ============================================
DROP POLICY IF EXISTS "Users can view own credentials" ON public.merchant_payment_credentials;
CREATE POLICY "Users can view own credentials" ON public.merchant_payment_credentials
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own credentials" ON public.merchant_payment_credentials;
CREATE POLICY "Users can manage own credentials" ON public.merchant_payment_credentials
  FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 13. POLICIES RLS - SITE_SETTINGS
-- ============================================
DROP POLICY IF EXISTS "Anyone can view settings" ON public.site_settings;
CREATE POLICY "Anyone can view settings" ON public.site_settings
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own settings" ON public.site_settings;
CREATE POLICY "Users can manage own settings" ON public.site_settings
  FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 14. FUNÇÕES DO BANCO DE DADOS
-- ============================================

-- 14.1 Atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = 'public', 'pg_temp'
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- 14.2 Gerar slug único
CREATE OR REPLACE FUNCTION public.generate_unique_slug(base_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  generated_slug TEXT;
  counter INTEGER := 0;
BEGIN
  generated_slug := lower(regexp_replace(base_name, '[^a-zA-Z0-9]+', '-', 'g'));
  generated_slug := trim(both '-' from generated_slug);
  IF generated_slug = '' OR generated_slug IS NULL THEN
    generated_slug := 'loja';
  END IF;
  WHILE EXISTS (SELECT 1 FROM stores WHERE slug = generated_slug) LOOP
    counter := counter + 1;
    generated_slug := lower(regexp_replace(base_name, '[^a-zA-Z0-9]+', '-', 'g')) || '-' || counter;
    generated_slug := trim(both '-' from generated_slug);
  END LOOP;
  RETURN generated_slug;
END;
$$;

-- 14.3 Verificar se registro é permitido (apenas 1 usuário)
CREATE OR REPLACE FUNCTION public.is_registration_allowed()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT NOT EXISTS (SELECT 1 FROM auth.users LIMIT 1);
$$;

-- 14.4 Verificar se já usou trial
CREATE OR REPLACE FUNCTION public.has_used_trial(_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM public.user_subscriptions us
    JOIN public.subscription_plans sp ON us.subscription_plan_id = sp.id
    WHERE us.user_id = _user_id 
    AND sp.is_trial = true
  );
END;
$$;

-- 14.5 Buscar assinatura ativa
CREATE OR REPLACE FUNCTION public.get_active_subscription(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  subscription_plan_id UUID,
  status TEXT,
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  plan_name TEXT,
  plan_price NUMERIC,
  days_remaining INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'pg_temp'
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    us.id,
    us.user_id,
    us.subscription_plan_id,
    us.status,
    us.current_period_start,
    us.current_period_end,
    sp.name AS plan_name,
    sp.price AS plan_price,
    GREATEST(0, EXTRACT(day FROM us.current_period_end - now())::INTEGER) AS days_remaining
  FROM public.user_subscriptions us
  LEFT JOIN public.subscription_plans sp ON sp.id = us.subscription_plan_id
  WHERE us.user_id = p_user_id
  AND us.current_period_end > now()
  ORDER BY us.created_at DESC
  LIMIT 1;
END;
$$;

-- 14.6 Listar planos disponíveis
CREATE OR REPLACE FUNCTION public.get_available_plans(_user_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  slug TEXT,
  price NUMERIC,
  duration_days INTEGER,
  is_trial BOOLEAN,
  features JSONB,
  is_active BOOLEAN,
  is_available BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    sp.id, sp.name, sp.slug, sp.price, sp.duration_days,
    sp.is_trial, sp.features, sp.is_active,
    CASE 
      WHEN sp.is_trial = true THEN NOT public.has_used_trial(_user_id)
      ELSE true
    END AS is_available,
    sp.created_at, sp.updated_at
  FROM public.subscription_plans sp
  WHERE sp.is_active = true
  ORDER BY sp.price ASC;
END;
$$;

-- 14.7 Prevenir múltiplos trials (trigger function)
CREATE OR REPLACE FUNCTION public.prevent_multiple_trials()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
  is_trial_plan BOOLEAN;
  already_used_trial BOOLEAN;
BEGIN
  SELECT sp.is_trial INTO is_trial_plan
  FROM public.subscription_plans sp
  WHERE sp.id = NEW.subscription_plan_id;

  IF is_trial_plan THEN
    already_used_trial := public.has_used_trial(NEW.user_id);
    IF already_used_trial THEN
      RAISE EXCEPTION 'Você já utilizou o teste gratuito. Cada conta pode usar o teste apenas uma vez.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- ============================================
-- 15. TRIGGERS
-- ============================================

-- 15.1 Trigger para prevenir múltiplos trials
DROP TRIGGER IF EXISTS check_trial_usage ON public.user_subscriptions;
CREATE TRIGGER check_trial_usage
  BEFORE INSERT ON public.user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_multiple_trials();

-- 15.2 Triggers para updated_at automático
DROP TRIGGER IF EXISTS update_stores_updated_at ON public.stores;
CREATE TRIGGER update_stores_updated_at
  BEFORE UPDATE ON public.stores
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_categories_updated_at ON public.categories;
CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON public.categories
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_subscriptions_updated_at ON public.user_subscriptions;
CREATE TRIGGER update_user_subscriptions_updated_at
  BEFORE UPDATE ON public.user_subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_subscription_payments_updated_at ON public.subscription_payments;
CREATE TRIGGER update_subscription_payments_updated_at
  BEFORE UPDATE ON public.subscription_payments
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_site_settings_updated_at ON public.site_settings;
CREATE TRIGGER update_site_settings_updated_at
  BEFORE UPDATE ON public.site_settings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_merchant_credentials_updated_at ON public.merchant_payment_credentials;
CREATE TRIGGER update_merchant_credentials_updated_at
  BEFORE UPDATE ON public.merchant_payment_credentials
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- 16. HABILITAR REALTIME PARA PEDIDOS
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;

-- ============================================
-- 17. INSERIR PLANOS PADRÃO
-- ============================================
INSERT INTO public.subscription_plans (name, slug, price, duration_days, is_trial, features)
VALUES
  ('Teste Gratuito', 'trial', 0, 7, true, '["Loja online completa", "Gestão de pedidos ilimitados", "Dashboard com estatísticas", "Suporte por email"]'::jsonb),
  ('Plano Mensal', 'monthly', 29.90, 30, false, '["Todos os recursos do teste", "Pedidos ilimitados", "Produtos ilimitados", "Suporte prioritário", "Atualizações gratuitas"]'::jsonb),
  ('Plano Anual', 'yearly', 299.90, 365, false, '["Todos os recursos do mensal", "2 meses grátis", "Suporte VIP exclusivo", "Prioridade em novos recursos"]'::jsonb)
ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  price = EXCLUDED.price,
  duration_days = EXCLUDED.duration_days,
  is_trial = EXCLUDED.is_trial,
  features = EXCLUDED.features;

-- ============================================
-- 18. STORAGE BUCKET
-- ============================================
-- O bucket 'site-assets' já deve estar criado como público
-- Se não existir, crie manualmente no painel Storage do Supabase

-- ============================================
-- VERIFICAÇÃO FINAL
-- ============================================
SELECT 'TABELAS' AS tipo, table_name AS nome
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ============================================
-- FIM - SQL COMPLETO PRONTO! ✅
-- ============================================
