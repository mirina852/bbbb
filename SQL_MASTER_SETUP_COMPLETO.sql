-- ============================================
-- 🎯 SQL MASTER - SETUP COMPLETO
-- ============================================
-- Execute este arquivo no Supabase SQL Editor
-- Ele irá criar/atualizar TODAS as tabelas, funções e políticas
-- ============================================

-- ============================================
-- 1️⃣ CRIAR ENUMS
-- ============================================

DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN
    CREATE TYPE public.app_role AS ENUM ('admin', 'moderator', 'user');
  END IF;
END $$;

-- ============================================
-- 2️⃣ TABELA: STORES (LOJAS)
-- ============================================

CREATE TABLE IF NOT EXISTS public.stores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  logo_url TEXT,
  banner_url TEXT,
  primary_color TEXT DEFAULT '#FF7A30',
  phone TEXT,
  address TEXT,
  delivery_fee DECIMAL(10, 2) DEFAULT 5.00,
  min_order_value DECIMAL(10, 2) DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  is_open BOOLEAN DEFAULT true,
  opening_hours JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS stores_owner_id_idx ON public.stores(owner_id);
CREATE INDEX IF NOT EXISTS stores_slug_idx ON public.stores(slug);
CREATE INDEX IF NOT EXISTS stores_is_active_idx ON public.stores(is_active);

-- RLS para stores
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view active stores" ON public.stores;
DROP POLICY IF EXISTS "Owners can view their stores" ON public.stores;
DROP POLICY IF EXISTS "Authenticated users can create stores" ON public.stores;
DROP POLICY IF EXISTS "Owners can update their stores" ON public.stores;
DROP POLICY IF EXISTS "Owners can delete their stores" ON public.stores;

CREATE POLICY "Anyone can view active stores"
  ON public.stores FOR SELECT
  USING (is_active = true);

CREATE POLICY "Owners can view their stores"
  ON public.stores FOR SELECT
  TO authenticated
  USING (auth.uid() = owner_id);

CREATE POLICY "Authenticated users can create stores"
  ON public.stores FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update their stores"
  ON public.stores FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can delete their stores"
  ON public.stores FOR DELETE
  TO authenticated
  USING (auth.uid() = owner_id);

-- ============================================
-- 3️⃣ TABELA: CATEGORIES (CATEGORIAS)
-- ============================================

CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  icon TEXT,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(store_id, slug)
);

CREATE INDEX IF NOT EXISTS categories_store_id_idx ON public.categories(store_id);
CREATE INDEX IF NOT EXISTS categories_slug_idx ON public.categories(slug);

-- RLS para categories
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view categories" ON public.categories;
DROP POLICY IF EXISTS "Store owners can insert categories" ON public.categories;
DROP POLICY IF EXISTS "Store owners can update categories" ON public.categories;
DROP POLICY IF EXISTS "Store owners can delete categories" ON public.categories;

CREATE POLICY "Anyone can view categories"
  ON public.categories FOR SELECT
  USING (true);

CREATE POLICY "Store owners can insert categories"
  ON public.categories FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE id = store_id AND owner_id = auth.uid()
    )
  );

CREATE POLICY "Store owners can update categories"
  ON public.categories FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE id = store_id AND owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE id = store_id AND owner_id = auth.uid()
    )
  );

CREATE POLICY "Store owners can delete categories"
  ON public.categories FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE id = store_id AND owner_id = auth.uid()
    )
  );

-- ============================================
-- 4️⃣ TABELA: PRODUCTS (PRODUTOS)
-- ============================================

CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  image TEXT,
  category TEXT,
  available BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS products_store_id_idx ON public.products(store_id);
CREATE INDEX IF NOT EXISTS products_category_id_idx ON public.products(category_id);
CREATE INDEX IF NOT EXISTS products_available_idx ON public.products(available);

-- RLS para products
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view available products" ON public.products;
DROP POLICY IF EXISTS "Store owners can view their products" ON public.products;
DROP POLICY IF EXISTS "Store owners can insert products" ON public.products;
DROP POLICY IF EXISTS "Store owners can update products" ON public.products;
DROP POLICY IF EXISTS "Store owners can delete products" ON public.products;

CREATE POLICY "Anyone can view available products"
  ON public.products FOR SELECT
  USING (available = true);

CREATE POLICY "Store owners can view their products"
  ON public.products FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE id = store_id AND owner_id = auth.uid()
    )
  );

CREATE POLICY "Store owners can insert products"
  ON public.products FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE id = store_id AND owner_id = auth.uid()
    )
  );

CREATE POLICY "Store owners can update products"
  ON public.products FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE id = store_id AND owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE id = store_id AND owner_id = auth.uid()
    )
  );

CREATE POLICY "Store owners can delete products"
  ON public.products FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE id = store_id AND owner_id = auth.uid()
    )
  );

-- ============================================
-- 5️⃣ TABELA: INGREDIENTS (INGREDIENTES)
-- ============================================

CREATE TABLE IF NOT EXISTS public.ingredients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  price DECIMAL(10, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ingredients_product_id_idx ON public.ingredients(product_id);

-- RLS para ingredients
ALTER TABLE public.ingredients ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view ingredients" ON public.ingredients;
DROP POLICY IF EXISTS "Store owners can insert ingredients for their products" ON public.ingredients;
DROP POLICY IF EXISTS "Store owners can update ingredients of their products" ON public.ingredients;
DROP POLICY IF EXISTS "Store owners can delete ingredients of their products" ON public.ingredients;

CREATE POLICY "Anyone can view ingredients"
  ON public.ingredients FOR SELECT
  USING (true);

CREATE POLICY "Store owners can insert ingredients for their products"
  ON public.ingredients FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.products p
      JOIN public.stores s ON s.id = p.store_id
      WHERE p.id = product_id AND s.owner_id = auth.uid()
    )
  );

CREATE POLICY "Store owners can update ingredients of their products"
  ON public.ingredients FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.products p
      JOIN public.stores s ON s.id = p.store_id
      WHERE p.id = product_id AND s.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.products p
      JOIN public.stores s ON s.id = p.store_id
      WHERE p.id = product_id AND s.owner_id = auth.uid()
    )
  );

CREATE POLICY "Store owners can delete ingredients of their products"
  ON public.ingredients FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.products p
      JOIN public.stores s ON s.id = p.store_id
      WHERE p.id = product_id AND s.owner_id = auth.uid()
    )
  );

-- ============================================
-- 6️⃣ TABELA: ORDERS (PEDIDOS)
-- ============================================

CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE NOT NULL,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  delivery_address TEXT,
  payment_method TEXT NOT NULL,
  total DECIMAL(10, 2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS orders_store_id_idx ON public.orders(store_id);
CREATE INDEX IF NOT EXISTS orders_status_idx ON public.orders(status);
CREATE INDEX IF NOT EXISTS orders_created_at_idx ON public.orders(created_at DESC);

-- RLS para orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Store owners can view their orders" ON public.orders;
DROP POLICY IF EXISTS "Anyone can create orders" ON public.orders;
DROP POLICY IF EXISTS "Store owners can update their orders" ON public.orders;
DROP POLICY IF EXISTS "Store owners can delete their orders" ON public.orders;

CREATE POLICY "Store owners can view their orders"
  ON public.orders FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE id = store_id AND owner_id = auth.uid()
    )
  );

CREATE POLICY "Anyone can create orders"
  ON public.orders FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Store owners can update their orders"
  ON public.orders FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE id = store_id AND owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE id = store_id AND owner_id = auth.uid()
    )
  );

CREATE POLICY "Store owners can delete their orders"
  ON public.orders FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE id = store_id AND owner_id = auth.uid()
    )
  );

-- ============================================
-- 7️⃣ TABELA: ORDER_ITEMS (ITENS DO PEDIDO)
-- ============================================

CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  price DECIMAL(10, 2) NOT NULL,
  removed_ingredients JSONB DEFAULT '[]'::jsonb,
  extra_ingredients JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS order_items_order_id_idx ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS order_items_product_id_idx ON public.order_items(product_id);

-- RLS para order_items
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Store owners can view order items" ON public.order_items;
DROP POLICY IF EXISTS "Anyone can create order items" ON public.order_items;
DROP POLICY IF EXISTS "Store owners can update order items" ON public.order_items;
DROP POLICY IF EXISTS "Store owners can delete order items" ON public.order_items;

CREATE POLICY "Store owners can view order items"
  ON public.order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.stores s ON s.id = o.store_id
      WHERE o.id = order_id AND s.owner_id = auth.uid()
    )
  );

CREATE POLICY "Anyone can create order items"
  ON public.order_items FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Store owners can update order items"
  ON public.order_items FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.stores s ON s.id = o.store_id
      WHERE o.id = order_id AND s.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.stores s ON s.id = o.store_id
      WHERE o.id = order_id AND s.owner_id = auth.uid()
    )
  );

CREATE POLICY "Store owners can delete order items"
  ON public.order_items FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.stores s ON s.id = o.store_id
      WHERE o.id = order_id AND s.owner_id = auth.uid()
    )
  );

-- ============================================
-- 8️⃣ TABELA: SUBSCRIPTION_PLANS (PLANOS)
-- ============================================

CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  duration_days INTEGER NOT NULL,
  features JSONB DEFAULT '[]'::jsonb,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS para subscription_plans
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view active plans" ON public.subscription_plans;

CREATE POLICY "Anyone can view active plans"
  ON public.subscription_plans FOR SELECT
  USING (is_active = true);

-- Inserir planos padrão
INSERT INTO public.subscription_plans (id, name, slug, price, duration_days, features, is_active)
VALUES 
  ('free', 'Teste Grátis', 'free', 0, 30, '["Acesso completo por 30 dias", "1 loja", "Produtos ilimitados", "Pedidos ilimitados"]'::jsonb, true),
  ('monthly', 'Plano Mensal', 'monthly', 29.90, 30, '["Todas as funcionalidades", "Lojas ilimitadas", "Produtos ilimitados", "Suporte prioritário"]'::jsonb, true),
  ('annual', 'Plano Anual', 'annual', 299.90, 365, '["Todas as funcionalidades", "Lojas ilimitadas", "Produtos ilimitados", "Suporte prioritário", "2 meses grátis"]'::jsonb, true)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  price = EXCLUDED.price,
  duration_days = EXCLUDED.duration_days,
  features = EXCLUDED.features,
  is_active = EXCLUDED.is_active;

-- ============================================
-- 9️⃣ TABELA: USER_SUBSCRIPTIONS (ASSINATURAS)
-- ============================================

CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  subscription_plan_id TEXT REFERENCES public.subscription_plans(id) NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS user_subscriptions_user_id_idx ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS user_subscriptions_status_idx ON public.user_subscriptions(status);
CREATE INDEX IF NOT EXISTS user_subscriptions_expires_at_idx ON public.user_subscriptions(expires_at);

-- RLS para user_subscriptions
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.user_subscriptions;
DROP POLICY IF EXISTS "Users can create own subscriptions" ON public.user_subscriptions;

CREATE POLICY "Users can view own subscriptions"
  ON public.user_subscriptions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own subscriptions"
  ON public.user_subscriptions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 🔟 TABELA: SUBSCRIPTION_PAYMENTS (PAGAMENTOS)
-- ============================================

CREATE TABLE IF NOT EXISTS public.subscription_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  plan_id TEXT REFERENCES public.subscription_plans(id) NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'cancelled', 'expired')),
  payment_method TEXT NOT NULL DEFAULT 'pix',
  external_payment_id TEXT UNIQUE,
  qr_code TEXT,
  qr_code_base64 TEXT,
  ticket_url TEXT,
  expires_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS subscription_payments_user_id_idx ON public.subscription_payments(user_id);
CREATE INDEX IF NOT EXISTS subscription_payments_status_idx ON public.subscription_payments(status);
CREATE INDEX IF NOT EXISTS subscription_payments_external_id_idx ON public.subscription_payments(external_payment_id);

-- RLS para subscription_payments
ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own payments" ON public.subscription_payments;
DROP POLICY IF EXISTS "Users can create own payments" ON public.subscription_payments;

CREATE POLICY "Users can view own payments"
  ON public.subscription_payments FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own payments"
  ON public.subscription_payments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 1️⃣1️⃣ TABELA: USER_ROLES (FUNÇÕES DE USUÁRIO)
-- ============================================

CREATE TABLE IF NOT EXISTS public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role app_role NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, role)
);

CREATE INDEX IF NOT EXISTS user_roles_user_id_idx ON public.user_roles(user_id);

-- RLS para user_roles
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own roles" ON public.user_roles;

CREATE POLICY "Users can view own roles"
  ON public.user_roles FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- ============================================
-- 🔧 FUNÇÕES RPC
-- ============================================

-- Função: has_role
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = _user_id AND role = _role
  )
$$;

-- Função: generate_unique_slug
CREATE OR REPLACE FUNCTION public.generate_unique_slug(_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
BEGIN
  base_slug := LOWER(
    REGEXP_REPLACE(
      TRANSLATE(
        _name,
        'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ',
        'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'
      ),
      '[^a-z0-9]+', '-', 'g'
    )
  );
  
  final_slug := base_slug;
  
  WHILE EXISTS (SELECT 1 FROM public.stores WHERE slug = final_slug) LOOP
    counter := counter + 1;
    final_slug := base_slug || '-' || counter;
  END LOOP;
  
  RETURN final_slug;
END;
$$;

-- Função: get_user_store_id
CREATE OR REPLACE FUNCTION public.get_user_store_id(_user_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  store_id UUID;
BEGIN
  SELECT id INTO store_id
  FROM public.stores
  WHERE owner_id = _user_id
  ORDER BY created_at DESC
  LIMIT 1;
  
  RETURN store_id;
END;
$$;

-- Função: get_active_subscription
CREATE OR REPLACE FUNCTION public.get_active_subscription(_user_id UUID)
RETURNS TABLE (
  id UUID,
  plan_name TEXT,
  plan_slug TEXT,
  status TEXT,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  days_remaining INTEGER
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    us.id,
    sp.name AS plan_name,
    sp.slug AS plan_slug,
    us.status,
    us.expires_at,
    us.created_at,
    GREATEST(0, (DATE(us.expires_at) - DATE(NOW()))::INTEGER) AS days_remaining
  FROM public.user_subscriptions us
  JOIN public.subscription_plans sp ON us.subscription_plan_id = sp.id
  WHERE us.user_id = _user_id
  ORDER BY us.created_at DESC
  LIMIT 1;
END;
$$;

-- Função: has_active_subscription
CREATE OR REPLACE FUNCTION public.has_active_subscription(_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_subscriptions
    WHERE user_id = _user_id
      AND status = 'active'
      AND expires_at > NOW()
  );
END;
$$;

-- Função: has_used_trial
CREATE OR REPLACE FUNCTION public.has_used_trial(_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_subscriptions us
    JOIN public.subscription_plans sp ON us.subscription_plan_id = sp.id
    WHERE us.user_id = _user_id
      AND sp.slug = 'free'
  );
END;
$$;

-- Função: get_available_plans
CREATE OR REPLACE FUNCTION public.get_available_plans(_user_id UUID)
RETURNS TABLE (
  id TEXT,
  name TEXT,
  slug TEXT,
  price DECIMAL,
  duration_days INTEGER,
  features JSONB
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  used_trial BOOLEAN;
BEGIN
  SELECT public.has_used_trial(_user_id) INTO used_trial;
  
  RETURN QUERY
  SELECT 
    sp.id,
    sp.name,
    sp.slug,
    sp.price,
    sp.duration_days,
    sp.features
  FROM public.subscription_plans sp
  WHERE sp.is_active = true
    AND (sp.slug != 'free' OR used_trial = false)
  ORDER BY sp.price;
END;
$$;

-- ============================================
-- ⚡ TRIGGERS
-- ============================================

-- Trigger: update_stores_updated_at
CREATE OR REPLACE FUNCTION public.update_stores_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_stores_updated_at ON public.stores;
CREATE TRIGGER update_stores_updated_at
  BEFORE UPDATE ON public.stores
  FOR EACH ROW
  EXECUTE FUNCTION public.update_stores_updated_at();

-- Trigger: update_orders_updated_at
CREATE OR REPLACE FUNCTION public.update_orders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.update_orders_updated_at();

-- Trigger: update_user_subscriptions_updated_at
CREATE OR REPLACE FUNCTION public.update_user_subscriptions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_user_subscriptions_updated_at ON public.user_subscriptions;
CREATE TRIGGER update_user_subscriptions_updated_at
  BEFORE UPDATE ON public.user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_user_subscriptions_updated_at();

-- ============================================
-- 📡 HABILITAR REALTIME
-- ============================================

-- Habilitar replica identity para realtime
ALTER TABLE public.orders REPLICA IDENTITY FULL;

-- Adicionar à publicação realtime
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND tablename = 'orders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
  END IF;
END $$;

-- ============================================
-- ✅ VERIFICAÇÃO FINAL
-- ============================================

DO $$
DECLARE
  table_count INTEGER;
  function_count INTEGER;
BEGIN
  -- Contar tabelas criadas
  SELECT COUNT(*) INTO table_count
  FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_name IN (
      'stores', 'categories', 'products', 'ingredients',
      'orders', 'order_items', 'subscription_plans',
      'user_subscriptions', 'subscription_payments', 'user_roles'
    );
  
  RAISE NOTICE '✅ Tabelas criadas: % de 10', table_count;
  
  -- Contar funções criadas
  SELECT COUNT(*) INTO function_count
  FROM pg_proc
  WHERE proname IN (
    'has_role', 'generate_unique_slug', 'get_user_store_id',
    'get_active_subscription', 'has_active_subscription',
    'has_used_trial', 'get_available_plans'
  );
  
  RAISE NOTICE '✅ Funções criadas: % de 7', function_count;
  
  IF table_count = 10 AND function_count = 7 THEN
    RAISE NOTICE '🎉 SETUP COMPLETO! Todas as tabelas e funções foram criadas com sucesso!';
  ELSE
    RAISE WARNING '⚠️ Algumas tabelas ou funções podem não ter sido criadas. Verifique os logs acima.';
  END IF;
END $$;
