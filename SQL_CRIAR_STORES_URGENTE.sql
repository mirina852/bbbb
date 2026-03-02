-- ============================================
-- SQL URGENTE: CRIAR TABELA STORES
-- ============================================
-- Execute este SQL para resolver o redirecionamento

-- 1. Criar tabela stores
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

-- 2. Criar índices
CREATE INDEX IF NOT EXISTS stores_owner_id_idx ON public.stores(owner_id);
CREATE INDEX IF NOT EXISTS stores_slug_idx ON public.stores(slug);
CREATE INDEX IF NOT EXISTS stores_is_active_idx ON public.stores(is_active);

-- 3. Habilitar RLS
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- 4. Criar políticas RLS
CREATE POLICY "Active stores are viewable by everyone"
  ON public.stores FOR SELECT
  USING (is_active = true);

CREATE POLICY "Owners can manage their stores"
  ON public.stores FOR ALL
  USING (auth.uid() = owner_id);

-- 5. Adicionar store_id nas tabelas existentes
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;
ALTER TABLE public.categorias ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;
ALTER TABLE public.credenciais_de_pagamento_comercial ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE;

-- 6. Criar função para gerar slug único
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

-- 7. Criar função para obter store_id do usuário
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
-- PRONTO! Agora o redirecionamento vai funcionar
-- ============================================
