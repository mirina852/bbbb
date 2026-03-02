-- ============================================
-- CRIAR TABELA ORDERS (PEDIDOS)
-- ============================================

-- 1. Criar tabela orders
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE NOT NULL,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  delivery_address TEXT,
  payment_method TEXT NOT NULL,
  total NUMERIC(10, 2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2. Criar índices
CREATE INDEX IF NOT EXISTS orders_store_id_idx ON public.orders(store_id);
CREATE INDEX IF NOT EXISTS orders_status_idx ON public.orders(status);
CREATE INDEX IF NOT EXISTS orders_created_at_idx ON public.orders(created_at DESC);

-- 3. Habilitar RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- 4. Criar políticas RLS
-- SELECT: Donos podem ver pedidos de suas lojas
CREATE POLICY "orders_select_policy" 
  ON public.orders 
  FOR SELECT 
  TO authenticated
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- INSERT: Qualquer um pode criar pedidos (clientes não autenticados)
CREATE POLICY "orders_insert_policy" 
  ON public.orders 
  FOR INSERT 
  WITH CHECK (true);

-- UPDATE: Apenas donos podem atualizar pedidos de suas lojas
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

-- DELETE: Apenas donos podem deletar pedidos de suas lojas
CREATE POLICY "orders_delete_policy" 
  ON public.orders 
  FOR DELETE 
  TO authenticated
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- 5. Criar trigger para atualizar updated_at
CREATE OR REPLACE FUNCTION public.update_orders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;

CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.update_orders_updated_at();

-- 6. Verificar estrutura
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'orders'
ORDER BY ordinal_position;

-- 7. Verificar políticas
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'orders'
ORDER BY cmd;

-- ============================================
-- PRONTO! ✅
-- ============================================
-- Tabela orders criada com:
-- ✅ RLS habilitado
-- ✅ 4 políticas de segurança
-- ✅ Índices para performance
-- ✅ Trigger para updated_at
