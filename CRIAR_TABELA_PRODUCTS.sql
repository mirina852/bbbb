-- ============================================
-- CRIAR TABELA products (SE NÃO EXISTIR)
-- ============================================

-- 1. Criar tabela products
CREATE TABLE IF NOT EXISTS public.products (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  image TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT 'outros',
  available BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- 2. Criar índices
CREATE INDEX IF NOT EXISTS products_store_id_idx ON public.products(store_id);
CREATE INDEX IF NOT EXISTS products_category_idx ON public.products(category);
CREATE INDEX IF NOT EXISTS products_available_idx ON public.products(available);

-- 3. Habilitar RLS
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- 4. Criar políticas RLS
-- Remover políticas antigas se existirem
DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
DROP POLICY IF EXISTS "Only authenticated users can manage products" ON public.products;
DROP POLICY IF EXISTS "Users can view own store products" ON public.products;
DROP POLICY IF EXISTS "Users can manage own store products" ON public.products;

-- Política para SELECT (visualizar produtos da própria loja)
CREATE POLICY "Users can view own store products"
ON public.products FOR SELECT
USING (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
);

-- Política para INSERT (criar produtos na própria loja)
CREATE POLICY "Users can insert own store products"
ON public.products FOR INSERT
WITH CHECK (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
);

-- Política para UPDATE (atualizar produtos da própria loja)
CREATE POLICY "Users can update own store products"
ON public.products FOR UPDATE
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

-- Política para DELETE (deletar produtos da própria loja)
CREATE POLICY "Users can delete own store products"
ON public.products FOR DELETE
USING (
  store_id IN (
    SELECT id FROM public.stores WHERE owner_id = auth.uid()
  )
);

-- 5. Criar trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_products_updated_at ON public.products;

CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- VERIFICAR RESULTADO
-- ============================================

-- Ver estrutura da tabela
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'products'
ORDER BY ordinal_position;

-- Ver políticas RLS
SELECT 
  policyname,
  cmd as operacao
FROM pg_policies
WHERE tablename = 'products'
ORDER BY policyname;

-- Ver se RLS está habilitado
SELECT 
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'products';

-- ============================================
-- MIGRAR DADOS (SE HOUVER TABELA produtos)
-- ============================================
-- Se você tinha uma tabela 'produtos' (português), migre os dados:

-- Descomente as linhas abaixo se necessário:

-- INSERT INTO public.products (
--   id, store_id, name, description, price, 
--   image, category, available, created_at, updated_at
-- )
-- SELECT 
--   id, 
--   store_id,
--   COALESCE(name, nome) as name,
--   COALESCE(description, descricao) as description,
--   COALESCE(price, preco) as price,
--   COALESCE(image, image_url, '') as image,
--   COALESCE(category, categoria, 'outros') as category,
--   COALESCE(available, disponivel, true) as available,
--   created_at,
--   updated_at
-- FROM public.produtos
-- WHERE NOT EXISTS (
--   SELECT 1 FROM public.products WHERE products.id = produtos.id
-- );

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- ✅ Tabela products criada
-- ✅ Índices criados
-- ✅ RLS habilitado
-- ✅ 4 políticas criadas (SELECT, INSERT, UPDATE, DELETE)
-- ✅ Trigger de updated_at criado
