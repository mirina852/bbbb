-- ============================================
-- SQL COMPLETO - EXECUTAR NA ORDEM
-- ============================================
-- Execute TODO este SQL de uma vez no Supabase SQL Editor

-- ============================================
-- 1. CRIAR TABELA STORES PRIMEIRO
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

-- Índices
CREATE INDEX IF NOT EXISTS stores_owner_id_idx ON public.stores(owner_id);
CREATE INDEX IF NOT EXISTS stores_slug_idx ON public.stores(slug);
CREATE INDEX IF NOT EXISTS stores_is_active_idx ON public.stores(is_active);

-- RLS
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Active stores are viewable by everyone" ON public.stores;
CREATE POLICY "Active stores are viewable by everyone"
  ON public.stores FOR SELECT
  USING (is_active = true);

DROP POLICY IF EXISTS "Owners can manage their stores" ON public.stores;
CREATE POLICY "Owners can manage their stores"
  ON public.stores FOR ALL
  USING (auth.uid() = owner_id);

-- ============================================
-- 2. CRIAR FUNÇÕES AUXILIARES
-- ============================================

-- Função para gerar slug único
CREATE OR REPLACE FUNCTION public.generate_unique_slug(store_name TEXT)
RETURNS TEXT AS $$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
BEGIN
  base_slug := lower(
    translate(
      store_name,
      'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ',
      'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'
    )
  );
  
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

-- Função para obter store_id do usuário (IMPORTANTE!)
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
-- 3. ADICIONAR store_id NAS TABELAS EXISTENTES
-- ============================================

-- Produtos
ALTER TABLE public.produtos 
ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS produtos_store_id_idx ON public.produtos(store_id);

-- Orders
ALTER TABLE public.orders 
ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS orders_store_id_idx ON public.orders(store_id);

-- Categorias
ALTER TABLE public.categorias 
ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS categorias_store_id_idx ON public.categorias(store_id);

-- Credenciais de pagamento
ALTER TABLE public.credenciais_de_pagamento_comercial 
ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS credenciais_pagamento_store_id_idx 
ON public.credenciais_de_pagamento_comercial(store_id);

-- ============================================
-- 4. ATUALIZAR POLÍTICAS RLS DAS TABELAS
-- ============================================

-- Produtos
DROP POLICY IF EXISTS "Products are viewable by store" ON public.produtos;
CREATE POLICY "Products are viewable by store"
  ON public.produtos FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = produtos.store_id 
      AND stores.is_active = true
    )
  );

DROP POLICY IF EXISTS "Store owners can manage their products" ON public.produtos;
CREATE POLICY "Store owners can manage their products"
  ON public.produtos FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = produtos.store_id 
      AND stores.owner_id = auth.uid()
    )
  );

-- Orders
DROP POLICY IF EXISTS "Anyone can create orders" ON public.orders;
CREATE POLICY "Anyone can create orders"
  ON public.orders FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = orders.store_id 
      AND stores.is_active = true
    )
  );

DROP POLICY IF EXISTS "Store owners can view their orders" ON public.orders;
CREATE POLICY "Store owners can view their orders"
  ON public.orders FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = orders.store_id 
      AND stores.owner_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Store owners can update their orders" ON public.orders;
CREATE POLICY "Store owners can update their orders"
  ON public.orders FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = orders.store_id 
      AND stores.owner_id = auth.uid()
    )
  );

-- Categorias
DROP POLICY IF EXISTS "Categories are viewable by store" ON public.categorias;
CREATE POLICY "Categories are viewable by store"
  ON public.categorias FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = categorias.store_id 
      AND stores.is_active = true
    )
  );

DROP POLICY IF EXISTS "Store owners can manage their categories" ON public.categorias;
CREATE POLICY "Store owners can manage their categories"
  ON public.categorias FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = categorias.store_id 
      AND stores.owner_id = auth.uid()
    )
  );

-- Credenciais
DROP POLICY IF EXISTS "Public can view active store credentials" ON public.credenciais_de_pagamento_comercial;
CREATE POLICY "Public can view active store credentials"
  ON public.credenciais_de_pagamento_comercial FOR SELECT
  USING (
    is_active = true AND
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = credenciais_de_pagamento_comercial.store_id 
      AND stores.is_active = true
    )
  );

DROP POLICY IF EXISTS "Store owners can manage their credentials" ON public.credenciais_de_pagamento_comercial;
CREATE POLICY "Store owners can manage their credentials"
  ON public.credenciais_de_pagamento_comercial FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = credenciais_de_pagamento_comercial.store_id 
      AND stores.owner_id = auth.uid()
    )
  );

-- ============================================
-- 5. VERIFICAÇÃO FINAL
-- ============================================

-- Verificar se a tabela stores foi criada
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'stores') THEN
    RAISE NOTICE '✅ Tabela stores criada com sucesso!';
  ELSE
    RAISE EXCEPTION '❌ Erro: Tabela stores não foi criada!';
  END IF;
END $$;

-- Verificar se a função existe
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_user_store_id') THEN
    RAISE NOTICE '✅ Função get_user_store_id criada com sucesso!';
  ELSE
    RAISE EXCEPTION '❌ Erro: Função get_user_store_id não foi criada!';
  END IF;
END $$;

-- ============================================
-- PRONTO! ✅
-- ============================================
-- Agora você pode:
-- 1. Fazer login
-- 2. Será redirecionado para /store-setup
-- 3. Criar sua primeira loja
-- 4. Começar a usar o sistema!
