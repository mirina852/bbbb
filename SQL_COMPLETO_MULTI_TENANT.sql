-- ============================================
-- SQL COMPLETO PARA SISTEMA MULTI-TENANT
-- ============================================
-- Execute este SQL completo no Supabase SQL Editor
-- Versão: Multi-Tenant com Redirecionamento Automático

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
-- 2. CRIAR TABELA STORES (LOJAS)
-- ============================================
CREATE TABLE IF NOT EXISTS public.stores (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  -- Informações básicas
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  
  -- Contato
  phone TEXT,
  email TEXT,
  
  -- Endereço
  address TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  
  -- Configurações visuais
  logo_url TEXT,
  background_urls TEXT[],
  primary_color TEXT DEFAULT '#FF7A30',
  
  -- Configurações operacionais
  delivery_fee DECIMAL(10,2) DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  is_open BOOLEAN DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Índices para stores
CREATE INDEX IF NOT EXISTS stores_owner_id_idx ON public.stores(owner_id);
CREATE INDEX IF NOT EXISTS stores_slug_idx ON public.stores(slug);
CREATE INDEX IF NOT EXISTS stores_is_active_idx ON public.stores(is_active);

-- Trigger para stores
CREATE TRIGGER update_stores_updated_at
  BEFORE UPDATE ON public.stores
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- RLS para stores
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Active stores are viewable by everyone"
  ON public.stores FOR SELECT
  USING (is_active = true);

CREATE POLICY "Owners can manage their stores"
  ON public.stores FOR ALL
  USING (auth.uid() = owner_id);

-- ============================================
-- 3. CRIAR TABELA PRODUCTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.products (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  image TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('burger', 'pizza', 'churrasco', 'steak', 'drink', 'dessert', 'snack', 'combo')),
  available BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Índices para products
CREATE INDEX IF NOT EXISTS products_store_id_idx ON public.products(store_id);
CREATE INDEX IF NOT EXISTS products_category_idx ON public.products(category);
CREATE INDEX IF NOT EXISTS products_available_idx ON public.products(available);

-- Trigger para products
CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- RLS para products
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Products are viewable by store"
  ON public.products FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = products.store_id 
      AND stores.is_active = true
    )
  );

CREATE POLICY "Store owners can manage their products"
  ON public.products FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = products.store_id 
      AND stores.owner_id = auth.uid()
    )
  );

-- ============================================
-- 4. CRIAR TABELA ORDERS
-- ============================================
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
  customer_name TEXT NOT NULL,
  customer_phone TEXT,
  delivery_address TEXT,
  payment_method TEXT,
  total DECIMAL(10,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'preparing', 'ready', 'delivered', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Índices para orders
CREATE INDEX IF NOT EXISTS orders_store_id_idx ON public.orders(store_id);
CREATE INDEX IF NOT EXISTS orders_status_idx ON public.orders(status);
CREATE INDEX IF NOT EXISTS orders_created_at_idx ON public.orders(created_at DESC);

-- Trigger para orders
CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- RLS para orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can create orders"
  ON public.orders FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = orders.store_id 
      AND stores.is_active = true
    )
  );

CREATE POLICY "Store owners can view their orders"
  ON public.orders FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = orders.store_id 
      AND stores.owner_id = auth.uid()
    )
  );

CREATE POLICY "Store owners can update their orders"
  ON public.orders FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = orders.store_id 
      AND stores.owner_id = auth.uid()
    )
  );

-- ============================================
-- 5. CRIAR TABELA ORDER_ITEMS
-- ============================================
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id),
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  price DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Índices para order_items
CREATE INDEX IF NOT EXISTS order_items_order_id_idx ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS order_items_product_id_idx ON public.order_items(product_id);

-- RLS para order_items
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can create order items"
  ON public.order_items FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Store owners can view their order items"
  ON public.order_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.orders
      JOIN public.stores ON stores.id = orders.store_id
      WHERE orders.id = order_items.order_id
      AND stores.owner_id = auth.uid()
    )
  );

-- ============================================
-- 6. CRIAR TABELA INGREDIENTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.ingredients (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_extra BOOLEAN DEFAULT false,
  price DECIMAL(10,2),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Índices para ingredients
CREATE INDEX IF NOT EXISTS ingredients_product_id_idx ON public.ingredients(product_id);

-- RLS para ingredients
ALTER TABLE public.ingredients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ingredients are viewable by store"
  ON public.ingredients FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.products
      JOIN public.stores ON stores.id = products.store_id
      WHERE products.id = ingredients.product_id
      AND stores.is_active = true
    )
  );

CREATE POLICY "Store owners can manage their ingredients"
  ON public.ingredients FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.products
      JOIN public.stores ON stores.id = products.store_id
      WHERE products.id = ingredients.product_id
      AND stores.owner_id = auth.uid()
    )
  );

-- ============================================
-- 7. CRIAR TABELA CATEGORIES
-- ============================================
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  icon TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Índices para categories
CREATE INDEX IF NOT EXISTS categories_store_id_idx ON public.categories(store_id);
CREATE INDEX IF NOT EXISTS categories_display_order_idx ON public.categories(display_order);

-- RLS para categories
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Categories are viewable by store"
  ON public.categories FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = categories.store_id 
      AND stores.is_active = true
    )
  );

CREATE POLICY "Store owners can manage their categories"
  ON public.categories FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = categories.store_id 
      AND stores.owner_id = auth.uid()
    )
  );

-- ============================================
-- 8. CRIAR TABELA MERCHANT_PAYMENT_CREDENTIALS
-- ============================================
CREATE TABLE IF NOT EXISTS public.merchant_payment_credentials (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
  public_key TEXT NOT NULL,
  access_token TEXT NOT NULL,
  environment TEXT NOT NULL DEFAULT 'production' CHECK (environment IN ('sandbox', 'production')),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Índices para merchant_payment_credentials
CREATE INDEX IF NOT EXISTS merchant_payment_credentials_user_id_idx ON public.merchant_payment_credentials(user_id);
CREATE INDEX IF NOT EXISTS merchant_payment_credentials_store_id_idx ON public.merchant_payment_credentials(store_id);
CREATE INDEX IF NOT EXISTS merchant_payment_credentials_active_idx ON public.merchant_payment_credentials(is_active);

-- Trigger para merchant_payment_credentials
CREATE TRIGGER update_merchant_payment_credentials_updated_at
  BEFORE UPDATE ON public.merchant_payment_credentials
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- RLS para merchant_payment_credentials
ALTER TABLE public.merchant_payment_credentials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active store credentials"
  ON public.merchant_payment_credentials FOR SELECT
  USING (
    is_active = true AND
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = merchant_payment_credentials.store_id 
      AND stores.is_active = true
    )
  );

CREATE POLICY "Store owners can manage their credentials"
  ON public.merchant_payment_credentials FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = merchant_payment_credentials.store_id 
      AND stores.owner_id = auth.uid()
    )
  );

-- ============================================
-- 9. CRIAR TABELA SITE_SETTINGS (LEGADO)
-- ============================================
CREATE TABLE IF NOT EXISTS public.site_settings (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  logo_url TEXT,
  background_urls TEXT[],
  primary_color TEXT DEFAULT '#FF7A30',
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- RLS para site_settings
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their settings"
  ON public.site_settings FOR ALL
  USING (auth.uid() = user_id);

-- ============================================
-- 10. FUNÇÕES AUXILIARES
-- ============================================

-- Função para gerar slug único
CREATE OR REPLACE FUNCTION public.generate_unique_slug(store_name TEXT)
RETURNS TEXT AS $$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
BEGIN
  -- Remove acentos e converte para lowercase
  base_slug := lower(
    translate(
      store_name,
      'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ',
      'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'
    )
  );
  
  -- Substitui caracteres não alfanuméricos por hífen
  base_slug := regexp_replace(base_slug, '[^a-z0-9]+', '-', 'g');
  
  -- Remove hífens no início e fim
  base_slug := trim(both '-' from base_slug);
  
  final_slug := base_slug;
  
  -- Verifica se slug já existe e adiciona número se necessário
  WHILE EXISTS (SELECT 1 FROM public.stores WHERE slug = final_slug) LOOP
    counter := counter + 1;
    final_slug := base_slug || '-' || counter;
  END LOOP;
  
  RETURN final_slug;
END;
$$ LANGUAGE plpgsql;

-- Função para obter store_id do usuário atual
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

-- ============================================
-- 11. COMENTÁRIOS
-- ============================================
COMMENT ON TABLE public.stores IS 'Stores/restaurants in the multi-tenant system';
COMMENT ON COLUMN public.stores.slug IS 'Unique URL-friendly identifier (e.g., hamburgueria-do-ze)';
COMMENT ON COLUMN public.stores.owner_id IS 'User who owns and manages this store';

COMMENT ON TABLE public.merchant_payment_credentials IS 'Mercado Pago credentials per store';
COMMENT ON FUNCTION public.generate_unique_slug(TEXT) IS 'Generates unique URL-friendly slug';
COMMENT ON FUNCTION public.get_user_store_id() IS 'Returns store_id for current authenticated user';

-- ============================================
-- FIM DO SQL
-- ============================================
-- Após executar este SQL:
-- 1. Regenere os tipos TypeScript
-- 2. Adicione as rotas no frontend
-- 3. Adicione o StoreProvider
-- 4. (Opcional) Migre dados existentes
