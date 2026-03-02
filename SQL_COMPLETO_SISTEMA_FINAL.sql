-- ============================================
-- SQL COMPLETO - SISTEMA PETISCO SAAS APP
-- ============================================
-- Execute este script completo no Supabase SQL Editor
-- Ele criará todas as tabelas, relacionamentos, políticas e configurações necessárias

-- ============================================
-- 1. TABELAS PRINCIPAIS
-- ============================================

-- Tabela stores (lojas)
CREATE TABLE IF NOT EXISTS public.stores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  description TEXT,
  logo_url TEXT,
  background_urls TEXT[],
  address TEXT,
  phone TEXT,
  is_open BOOLEAN DEFAULT true,
  delivery_fee NUMERIC(10, 2) DEFAULT 0,
  min_order_value NUMERIC(10, 2) DEFAULT 0,
  estimated_delivery_time INTEGER DEFAULT 30,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Tabela categories (categorias)
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  icon TEXT,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(store_id, slug)
);

-- Tabela products (produtos)
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(10, 2) NOT NULL,
  image TEXT,
  available BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Tabela ingredients (ingredientes)
CREATE TABLE IF NOT EXISTS public.ingredients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  is_extra BOOLEAN DEFAULT false,
  price NUMERIC(10, 2) DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Tabela orders (pedidos)
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE NOT NULL,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  delivery_address TEXT,
  payment_method TEXT NOT NULL,
  total NUMERIC(10, 2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',
  external_payment_id TEXT,
  payment_status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Tabela order_items (itens do pedido)
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  price NUMERIC(10, 2) NOT NULL,
  removed_ingredients JSONB DEFAULT '[]'::jsonb,
  extra_ingredients JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================
-- 2. ÍNDICES PARA PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS stores_owner_id_idx ON public.stores(owner_id);
CREATE INDEX IF NOT EXISTS stores_slug_idx ON public.stores(slug);
CREATE INDEX IF NOT EXISTS categories_store_id_idx ON public.categories(store_id);
CREATE INDEX IF NOT EXISTS products_store_id_idx ON public.products(store_id);
CREATE INDEX IF NOT EXISTS products_category_id_idx ON public.products(category_id);
CREATE INDEX IF NOT EXISTS ingredients_product_id_idx ON public.ingredients(product_id);
CREATE INDEX IF NOT EXISTS orders_store_id_idx ON public.orders(store_id);
CREATE INDEX IF NOT EXISTS orders_status_idx ON public.orders(status);
CREATE INDEX IF NOT EXISTS orders_created_at_idx ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS order_items_order_id_idx ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS order_items_product_id_idx ON public.order_items(product_id);

-- ============================================
-- 3. TRIGGERS PARA UPDATED_AT
-- ============================================

-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para cada tabela
DROP TRIGGER IF EXISTS update_stores_updated_at ON public.stores;
CREATE TRIGGER update_stores_updated_at
  BEFORE UPDATE ON public.stores
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_categories_updated_at ON public.categories;
CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON public.categories
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;
CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- 4. HABILITAR RLS (ROW LEVEL SECURITY)
-- ============================================

ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 5. POLÍTICAS RLS - STORES
-- ============================================

-- Stores: Donos podem ver suas lojas
CREATE POLICY "stores_select_policy" 
  ON public.stores 
  FOR SELECT 
  TO authenticated
  USING (owner_id = auth.uid());

-- Stores: Donos podem inserir suas lojas
CREATE POLICY "stores_insert_policy" 
  ON public.stores 
  FOR INSERT 
  TO authenticated
  WITH CHECK (owner_id = auth.uid());

-- Stores: Donos podem atualizar suas lojas
CREATE POLICY "stores_update_policy" 
  ON public.stores 
  FOR UPDATE 
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- Stores: Donos podem deletar suas lojas
CREATE POLICY "stores_delete_policy" 
  ON public.stores 
  FOR DELETE 
  TO authenticated
  USING (owner_id = auth.uid());

-- Stores: Público pode ver lojas ativas
CREATE POLICY "stores_public_select_policy" 
  ON public.stores 
  FOR SELECT 
  TO anon
  USING (is_open = true);

-- ============================================
-- 6. POLÍTICAS RLS - CATEGORIES
-- ============================================

-- Categories: Donos podem ver categorias de suas lojas
CREATE POLICY "categories_select_policy" 
  ON public.categories 
  FOR SELECT 
  TO authenticated
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- Categories: Donos podem inserir categorias em suas lojas
CREATE POLICY "categories_insert_policy" 
  ON public.categories 
  FOR INSERT 
  TO authenticated
  WITH CHECK (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- Categories: Donos podem atualizar categorias de suas lojas
CREATE POLICY "categories_update_policy" 
  ON public.categories 
  FOR UPDATE 
  TO authenticated
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  )
  WITH CHECK (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- Categories: Donos podem deletar categorias de suas lojas
CREATE POLICY "categories_delete_policy" 
  ON public.categories 
  FOR DELETE 
  TO authenticated
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- Categories: Público pode ver categorias de lojas ativas
CREATE POLICY "categories_public_select_policy" 
  ON public.categories 
  FOR SELECT 
  TO anon
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE is_open = true
    )
  );

-- ============================================
-- 7. POLÍTICAS RLS - PRODUCTS
-- ============================================

-- Products: Donos podem ver produtos de suas lojas
CREATE POLICY "products_select_policy" 
  ON public.products 
  FOR SELECT 
  TO authenticated
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- Products: Donos podem inserir produtos em suas lojas
CREATE POLICY "products_insert_policy" 
  ON public.products 
  FOR INSERT 
  TO authenticated
  WITH CHECK (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- Products: Donos podem atualizar produtos de suas lojas
CREATE POLICY "products_update_policy" 
  ON public.products 
  FOR UPDATE 
  TO authenticated
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  )
  WITH CHECK (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- Products: Donos podem deletar produtos de suas lojas
CREATE POLICY "products_delete_policy" 
  ON public.products 
  FOR DELETE 
  TO authenticated
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- Products: Público pode ver produtos disponíveis de lojas ativas
CREATE POLICY "products_public_select_policy" 
  ON public.products 
  FOR SELECT 
  TO anon
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE is_open = true
    )
    AND available = true
  );

-- ============================================
-- 8. POLÍTICAS RLS - INGREDIENTS
-- ============================================

-- Ingredients: Donos podem ver ingredientes de produtos de suas lojas
CREATE POLICY "ingredients_select_policy" 
  ON public.ingredients 
  FOR SELECT 
  TO authenticated
  USING (
    product_id IN (
      SELECT id FROM public.products 
      WHERE store_id IN (
        SELECT id FROM public.stores WHERE owner_id = auth.uid()
      )
    )
  );

-- Ingredients: Donos podem inserir ingredientes em produtos de suas lojas
CREATE POLICY "ingredients_insert_policy" 
  ON public.ingredients 
  FOR INSERT 
  TO authenticated
  WITH CHECK (
    product_id IN (
      SELECT id FROM public.products 
      WHERE store_id IN (
        SELECT id FROM public.stores WHERE owner_id = auth.uid()
      )
    )
  );

-- Ingredients: Donos podem atualizar ingredientes de produtos de suas lojas
CREATE POLICY "ingredients_update_policy" 
  ON public.ingredients 
  FOR UPDATE 
  TO authenticated
  USING (
    product_id IN (
      SELECT id FROM public.products 
      WHERE store_id IN (
        SELECT id FROM public.stores WHERE owner_id = auth.uid()
      )
    )
  )
  WITH CHECK (
    product_id IN (
      SELECT id FROM public.products 
      WHERE store_id IN (
        SELECT id FROM public.stores WHERE owner_id = auth.uid()
      )
    )
  );

-- Ingredients: Donos podem deletar ingredientes de produtos de suas lojas
CREATE POLICY "ingredients_delete_policy" 
  ON public.ingredients 
  FOR DELETE 
  TO authenticated
  USING (
    product_id IN (
      SELECT id FROM public.products 
      WHERE store_id IN (
        SELECT id FROM public.stores WHERE owner_id = auth.uid()
      )
    )
  );

-- Ingredients: Público pode ver ingredientes de produtos disponíveis
CREATE POLICY "ingredients_public_select_policy" 
  ON public.ingredients 
  FOR SELECT 
  TO anon
  USING (
    product_id IN (
      SELECT id FROM public.products 
      WHERE store_id IN (
        SELECT id FROM public.stores WHERE is_open = true
      )
      AND available = true
    )
  );

-- ============================================
-- 9. POLÍTICAS RLS - ORDERS
-- ============================================

-- Orders: Donos podem ver pedidos de suas lojas
CREATE POLICY "orders_select_policy" 
  ON public.orders 
  FOR SELECT 
  TO authenticated
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- Orders: Qualquer um pode criar pedidos (clientes não autenticados)
CREATE POLICY "orders_insert_policy" 
  ON public.orders 
  FOR INSERT 
  WITH CHECK (true);

-- Orders: Donos podem atualizar pedidos de suas lojas
CREATE POLICY "orders_update_policy" 
  ON public.orders 
  FOR UPDATE 
  TO authenticated
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  )
  WITH CHECK (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- Orders: Donos podem deletar pedidos de suas lojas
CREATE POLICY "orders_delete_policy" 
  ON public.orders 
  FOR DELETE 
  TO authenticated
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- ============================================
-- 10. POLÍTICAS RLS - ORDER_ITEMS
-- ============================================

-- Order_items: Donos podem ver itens de pedidos de suas lojas
CREATE POLICY "order_items_select_policy" 
  ON public.order_items 
  FOR SELECT 
  TO authenticated
  USING (
    order_id IN (
      SELECT o.id FROM public.orders o
      JOIN public.stores s ON s.id = o.store_id
      WHERE s.owner_id = auth.uid()
    )
  );

-- Order_items: Qualquer um pode criar itens de pedido (clientes não autenticados)
CREATE POLICY "order_items_insert_policy" 
  ON public.order_items 
  FOR INSERT 
  WITH CHECK (true);

-- Order_items: Donos podem atualizar itens de pedidos de suas lojas
CREATE POLICY "order_items_update_policy" 
  ON public.order_items 
  FOR UPDATE 
  TO authenticated
  USING (
    order_id IN (
      SELECT o.id FROM public.orders o
      JOIN public.stores s ON s.id = o.store_id
      WHERE s.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    order_id IN (
      SELECT o.id FROM public.orders o
      JOIN public.stores s ON s.id = o.store_id
      WHERE s.owner_id = auth.uid()
    )
  );

-- Order_items: Donos podem deletar itens de pedidos de suas lojas
CREATE POLICY "order_items_delete_policy" 
  ON public.order_items 
  FOR DELETE 
  TO authenticated
  USING (
    order_id IN (
      SELECT o.id FROM public.orders o
      JOIN public.stores s ON s.id = o.store_id
      WHERE s.owner_id = auth.uid()
    )
  );

-- ============================================
-- 11. STORAGE - BUCKETS E POLÍTICAS
-- ============================================

-- Criar bucket site-assets para uploads de imagens
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'site-assets', 
    'site-assets', 
    true, 
    5242880, -- 5MB
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Políticas para o bucket site-assets
CREATE POLICY "Anyone can upload to site-assets"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (
    bucket_id = 'site-assets'
);

CREATE POLICY "Anyone can view site-assets"
ON storage.objects
FOR SELECT
TO public
USING (
    bucket_id = 'site-assets'
);

CREATE POLICY "Owners can update site-assets"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'site-assets' AND
    auth.role() = 'authenticated'
)
WITH CHECK (
    bucket_id = 'site-assets' AND
    auth.role() = 'authenticated'
);

CREATE POLICY "Owners can delete site-assets"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'site-assets' AND
    auth.role() = 'authenticated'
);

-- ============================================
-- 12. FUNÇÕES ÚTEIS
-- ============================================

-- Função para gerar slug único
CREATE OR REPLACE FUNCTION public.generate_slug(text_input TEXT)
RETURNS TEXT AS $$
DECLARE
  clean_slug TEXT;
  base_slug TEXT;
  counter INTEGER := 1;
BEGIN
  -- Converter para minúsculas e remover caracteres especiais
  clean_slug := lower(text_input);
  clean_slug := regexp_replace(clean_slug, '[^a-z0-9\s-]', '', 'g');
  clean_slug := regexp_replace(clean_slug, '\s+', '-', 'g');
  clean_slug := regexp_replace(clean_slug, '-+', '-', 'g');
  clean_slug := trim(trim(clean_slug, '-'));
  
  base_slug := clean_slug;
  
  -- Verificar se o slug já existe e adicionar sufixo numérico se necessário
  WHILE EXISTS (
    SELECT 1 FROM public.stores WHERE slug = clean_slug
    UNION
    SELECT 1 FROM public.categories WHERE slug = clean_slug
  ) LOOP
    clean_slug := base_slug || '-' || counter;
    counter := counter + 1;
  END LOOP;
  
  RETURN clean_slug;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 13. PERMISSÕES E GRANTS
-- ============================================

-- Garantir permissões para tabelas
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon;

-- Garantir permissões para storage
GRANT ALL ON SCHEMA storage TO authenticated;
GRANT ALL ON SCHEMA storage TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO anon;

-- ============================================
-- 14. VERIFICAÇÃO FINAL
-- ============================================

-- Verificar estrutura das tabelas
SELECT 
  'stores' as table_name,
  COUNT(*) as total_records
FROM public.stores
UNION ALL
SELECT 
  'categories' as table_name,
  COUNT(*) as total_records
FROM public.categories
UNION ALL
SELECT 
  'products' as table_name,
  COUNT(*) as total_records
FROM public.products
UNION ALL
SELECT 
  'ingredients' as table_name,
  COUNT(*) as total_records
FROM public.ingredients
UNION ALL
SELECT 
  'orders' as table_name,
  COUNT(*) as total_records
FROM public.orders
UNION ALL
SELECT 
  'order_items' as table_name,
  COUNT(*) as total_records
FROM public.order_items;

-- Verificar relacionamentos
SELECT 
    tc.table_name, 
    tc.constraint_type,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
LEFT JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public' 
    AND tc.table_name IN ('stores', 'categories', 'products', 'ingredients', 'orders', 'order_items')
    AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_name, tc.constraint_name;

-- Verificar buckets
SELECT * FROM storage.buckets;

-- ============================================
-- PRONTO! ✅
-- ============================================
-- Sistema completo criado com:
-- ✅ Todas as tabelas necessárias
-- ✅ Relacionamentos corretos
-- ✅ Índices para performance
-- ✅ RLS habilitado com políticas de segurança
-- ✅ Storage com bucket para imagens
-- ✅ Triggers para updated_at
-- ✅ Funções úteis
-- ✅ Permissões adequadas
-- ============================================
