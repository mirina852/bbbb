-- ============================================
-- CRIAR TABELA STORES COMPLETA
-- Execute no Supabase SQL Editor
-- ============================================

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

-- 2. Criar índices para performance
CREATE INDEX IF NOT EXISTS stores_owner_id_idx ON public.stores(owner_id);
CREATE INDEX IF NOT EXISTS stores_slug_idx ON public.stores(slug);
CREATE INDEX IF NOT EXISTS stores_is_active_idx ON public.stores(is_active);

-- 3. Habilitar RLS
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- 4. Remover políticas antigas (se existirem)
DROP POLICY IF EXISTS "Active stores are viewable by everyone" ON public.stores;
DROP POLICY IF EXISTS "Owners can manage their stores" ON public.stores;
DROP POLICY IF EXISTS "Anyone can view active stores" ON public.stores;
DROP POLICY IF EXISTS "Owners can view their stores" ON public.stores;
DROP POLICY IF EXISTS "Authenticated users can create stores" ON public.stores;
DROP POLICY IF EXISTS "Owners can update their stores" ON public.stores;
DROP POLICY IF EXISTS "Owners can delete their stores" ON public.stores;

-- 5. Criar políticas RLS corretas

-- SELECT: Qualquer um pode ver lojas ativas (para clientes)
CREATE POLICY "Anyone can view active stores"
  ON public.stores
  FOR SELECT
  USING (is_active = true);

-- SELECT: Donos podem ver suas próprias lojas (mesmo inativas)
CREATE POLICY "Owners can view their stores"
  ON public.stores
  FOR SELECT
  TO authenticated
  USING (auth.uid() = owner_id);

-- INSERT: Usuários autenticados podem criar lojas
CREATE POLICY "Authenticated users can create stores"
  ON public.stores
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);

-- UPDATE: Apenas donos podem atualizar suas lojas
CREATE POLICY "Owners can update their stores"
  ON public.stores
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- DELETE: Apenas donos podem deletar suas lojas
CREATE POLICY "Owners can delete their stores"
  ON public.stores
  FOR DELETE
  TO authenticated
  USING (auth.uid() = owner_id);

-- 6. Criar função para gerar slug único
CREATE OR REPLACE FUNCTION public.generate_unique_slug(store_name TEXT)
RETURNS TEXT AS $$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
BEGIN
  -- Normalizar nome para slug
  base_slug := lower(
    translate(
      store_name,
      'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ',
      'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'
    )
  );
  
  -- Remover caracteres especiais
  base_slug := regexp_replace(base_slug, '[^a-z0-9]+', '-', 'g');
  base_slug := trim(both '-' from base_slug);
  
  final_slug := base_slug;
  
  -- Verificar se slug já existe e adicionar contador
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

-- 8. Criar trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION public.update_stores_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_stores_updated_at ON public.stores;

CREATE TRIGGER update_stores_updated_at
  BEFORE UPDATE ON public.stores
  FOR EACH ROW
  EXECUTE FUNCTION public.update_stores_updated_at();

-- ============================================
-- VERIFICAÇÃO
-- ============================================

-- Ver estrutura da tabela
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

-- Ver políticas RLS
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'stores'
ORDER BY cmd;

-- ============================================
-- ✅ PRONTO!
-- ============================================
-- Execute este SQL no Supabase SQL Editor:
-- 1. Acesse: https://supabase.com/dashboard
-- 2. Selecione seu projeto
-- 3. Vá em "SQL Editor"
-- 4. Cole este SQL
-- 5. Clique em "RUN"
-- ============================================
