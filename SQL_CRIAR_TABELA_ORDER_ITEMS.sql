-- ============================================
-- CRIAR TABELA ORDER_ITEMS (ITENS DO PEDIDO)
-- ============================================

-- 1. Criar tabela order_items
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES public.produtos(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  price NUMERIC(10, 2) NOT NULL,
  removed_ingredients JSONB DEFAULT '[]'::jsonb,
  extra_ingredients JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2. Criar índices
CREATE INDEX IF NOT EXISTS order_items_order_id_idx ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS order_items_product_id_idx ON public.order_items(product_id);

-- 3. Habilitar RLS
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- 4. Criar políticas RLS
-- SELECT: Donos podem ver itens de pedidos de suas lojas
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

-- INSERT: Qualquer um pode criar itens de pedido (clientes não autenticados)
CREATE POLICY "order_items_insert_policy" 
  ON public.order_items 
  FOR INSERT 
  WITH CHECK (true);

-- UPDATE: Apenas donos podem atualizar itens de pedidos de suas lojas
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

-- DELETE: Apenas donos podem deletar itens de pedidos de suas lojas
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

-- 5. Verificar estrutura
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'order_items'
ORDER BY ordinal_position;

-- 6. Verificar políticas
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'order_items'
ORDER BY cmd;

-- ============================================
-- PRONTO! ✅
-- ============================================
-- Tabela order_items criada com:
-- ✅ RLS habilitado
-- ✅ 4 políticas de segurança
-- ✅ Índices para performance
-- ✅ Suporte para ingredientes removidos/extras
