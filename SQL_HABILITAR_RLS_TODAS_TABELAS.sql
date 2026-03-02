-- ============================================
-- HABILITAR RLS EM TODAS AS TABELAS
-- ============================================
-- Execute este SQL para corrigir as tabelas "Unrestricted"

-- ============================================
-- 1. HABILITAR RLS
-- ============================================

-- Categorias
ALTER TABLE public.categorias ENABLE ROW LEVEL SECURITY;

-- Ingredientes
ALTER TABLE public.ingredients ENABLE ROW LEVEL SECURITY;

-- Credenciais de Pagamento
ALTER TABLE public.merchant_payment_credentials ENABLE ROW LEVEL SECURITY;

-- Itens do Pedido
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Pedidos
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Produtos
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;

-- Stores (já deve estar, mas garantir)
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- Subscription Payments
ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;

-- Subscription Plans
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

-- User Subscriptions
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

-- Site Settings (se existir)
ALTER TABLE IF EXISTS public.site_settings ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 2. CRIAR POLÍTICAS RLS - CATEGORIAS
-- ============================================

DROP POLICY IF EXISTS "categorias_select" ON public.categorias;
CREATE POLICY "categorias_select" 
  ON public.categorias 
  FOR SELECT 
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE is_active = true
    )
  );

DROP POLICY IF EXISTS "categorias_all" ON public.categorias;
CREATE POLICY "categorias_all" 
  ON public.categorias 
  FOR ALL 
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- ============================================
-- 3. CRIAR POLÍTICAS RLS - PRODUTOS
-- ============================================

DROP POLICY IF EXISTS "produtos_select" ON public.produtos;
CREATE POLICY "produtos_select" 
  ON public.produtos 
  FOR SELECT 
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE is_active = true
    )
  );

DROP POLICY IF EXISTS "produtos_all" ON public.produtos;
CREATE POLICY "produtos_all" 
  ON public.produtos 
  FOR ALL 
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- ============================================
-- 4. CRIAR POLÍTICAS RLS - PEDIDOS
-- ============================================

DROP POLICY IF EXISTS "orders_select" ON public.orders;
CREATE POLICY "orders_select" 
  ON public.orders 
  FOR SELECT 
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "orders_insert" ON public.orders;
CREATE POLICY "orders_insert" 
  ON public.orders 
  FOR INSERT 
  WITH CHECK (true); -- Qualquer um pode criar pedido

DROP POLICY IF EXISTS "orders_update" ON public.orders;
CREATE POLICY "orders_update" 
  ON public.orders 
  FOR UPDATE 
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- ============================================
-- 5. CRIAR POLÍTICAS RLS - ORDER ITEMS
-- ============================================

DROP POLICY IF EXISTS "order_items_select" ON public.order_items;
CREATE POLICY "order_items_select" 
  ON public.order_items 
  FOR SELECT 
  USING (
    order_id IN (
      SELECT id FROM public.orders 
      WHERE store_id IN (
        SELECT id FROM public.stores WHERE owner_id = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS "order_items_insert" ON public.order_items;
CREATE POLICY "order_items_insert" 
  ON public.order_items 
  FOR INSERT 
  WITH CHECK (true); -- Qualquer um pode adicionar itens ao criar pedido

-- ============================================
-- 6. CRIAR POLÍTICAS RLS - CREDENCIAIS PAGAMENTO
-- ============================================

DROP POLICY IF EXISTS "credentials_select" ON public.merchant_payment_credentials;
CREATE POLICY "credentials_select" 
  ON public.merchant_payment_credentials 
  FOR SELECT 
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "credentials_all" ON public.merchant_payment_credentials;
CREATE POLICY "credentials_all" 
  ON public.merchant_payment_credentials 
  FOR ALL 
  USING (
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- ============================================
-- 7. CRIAR POLÍTICAS RLS - INGREDIENTS
-- ============================================

DROP POLICY IF EXISTS "ingredients_select" ON public.ingredients;
CREATE POLICY "ingredients_select" 
  ON public.ingredients 
  FOR SELECT 
  USING (true); -- Todos podem ver ingredientes

DROP POLICY IF EXISTS "ingredients_all" ON public.ingredients;
CREATE POLICY "ingredients_all" 
  ON public.ingredients 
  FOR ALL 
  USING (auth.uid() IS NOT NULL); -- Apenas usuários autenticados podem gerenciar

-- ============================================
-- 8. CRIAR POLÍTICAS RLS - STORES
-- ============================================

DROP POLICY IF EXISTS "stores_select" ON public.stores;
CREATE POLICY "stores_select" 
  ON public.stores 
  FOR SELECT 
  USING (is_active = true);

DROP POLICY IF EXISTS "stores_all" ON public.stores;
CREATE POLICY "stores_all" 
  ON public.stores 
  FOR ALL 
  USING (auth.uid() = owner_id);

-- ============================================
-- 9. CRIAR POLÍTICAS RLS - SUBSCRIPTION PLANS
-- ============================================

DROP POLICY IF EXISTS "plans_select" ON public.subscription_plans;
CREATE POLICY "plans_select" 
  ON public.subscription_plans 
  FOR SELECT 
  USING (is_active = true);

DROP POLICY IF EXISTS "plans_all" ON public.subscription_plans;
CREATE POLICY "plans_all" 
  ON public.subscription_plans 
  FOR ALL 
  USING (auth.uid() IS NOT NULL);

-- ============================================
-- 10. CRIAR POLÍTICAS RLS - USER SUBSCRIPTIONS
-- ============================================

DROP POLICY IF EXISTS "subs_select" ON public.user_subscriptions;
CREATE POLICY "subs_select" 
  ON public.user_subscriptions 
  FOR SELECT 
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "subs_insert" ON public.user_subscriptions;
CREATE POLICY "subs_insert" 
  ON public.user_subscriptions 
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "subs_update" ON public.user_subscriptions;
CREATE POLICY "subs_update" 
  ON public.user_subscriptions 
  FOR UPDATE 
  USING (auth.uid() = user_id);

-- ============================================
-- 11. CRIAR POLÍTICAS RLS - SUBSCRIPTION PAYMENTS
-- ============================================

DROP POLICY IF EXISTS "payments_select" ON public.subscription_payments;
CREATE POLICY "payments_select" 
  ON public.subscription_payments 
  FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM public.user_subscriptions 
      WHERE user_subscriptions.id = subscription_payments.subscription_id 
      AND user_subscriptions.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "payments_insert" ON public.subscription_payments;
CREATE POLICY "payments_insert" 
  ON public.subscription_payments 
  FOR INSERT 
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_subscriptions 
      WHERE user_subscriptions.id = subscription_payments.subscription_id 
      AND user_subscriptions.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "payments_update" ON public.subscription_payments;
CREATE POLICY "payments_update" 
  ON public.subscription_payments 
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM public.user_subscriptions 
      WHERE user_subscriptions.id = subscription_payments.subscription_id 
      AND user_subscriptions.user_id = auth.uid()
    )
  );

-- ============================================
-- 12. VERIFICAÇÃO FINAL
-- ============================================

DO $$
DECLARE
  unrestricted_count INTEGER;
BEGIN
  -- Contar tabelas sem RLS
  SELECT COUNT(*) INTO unrestricted_count
  FROM pg_tables
  WHERE schemaname = 'public'
    AND rowsecurity = false;
  
  IF unrestricted_count = 0 THEN
    RAISE NOTICE '✅ Todas as tabelas têm RLS habilitado!';
  ELSE
    RAISE WARNING '⚠️  Ainda há % tabelas sem RLS', unrestricted_count;
  END IF;
  
  -- Listar tabelas
  RAISE NOTICE '📊 Status das tabelas:';
END $$;

-- Listar todas as tabelas e seu status RLS
SELECT 
  tablename,
  CASE 
    WHEN rowsecurity THEN '✅ Protegido'
    ELSE '❌ Unrestricted'
  END AS status_rls,
  (SELECT COUNT(*) FROM pg_policies WHERE pg_policies.tablename = pg_tables.tablename) AS num_policies
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- ============================================
-- PRONTO! ✅
-- ============================================
-- Todas as tabelas agora têm RLS habilitado
-- e políticas de segurança configuradas
