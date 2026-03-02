-- ============================================
-- CORRIGIR RLS DAS TABELAS DE ASSINATURAS
-- ============================================
-- Execute este SQL para corrigir as políticas RLS

-- ============================================
-- 1. HABILITAR RLS NAS TABELAS
-- ============================================

-- Subscription Plans
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

-- User Subscriptions
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

-- Subscription Payments
ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 2. CRIAR POLÍTICAS PARA SUBSCRIPTION_PLANS
-- ============================================

-- Todos podem ver planos ativos
DROP POLICY IF EXISTS "Active plans are viewable by everyone" ON public.subscription_plans;
CREATE POLICY "Active plans are viewable by everyone"
  ON public.subscription_plans FOR SELECT
  USING (is_active = true);

-- Apenas admins podem gerenciar planos (opcional)
DROP POLICY IF EXISTS "Admins can manage plans" ON public.subscription_plans;
CREATE POLICY "Admins can manage plans"
  ON public.subscription_plans FOR ALL
  USING (auth.uid() IS NOT NULL);

-- ============================================
-- 3. CRIAR POLÍTICAS PARA USER_SUBSCRIPTIONS
-- ============================================

-- Usuários podem ver suas próprias assinaturas
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can view own subscriptions"
  ON public.user_subscriptions FOR SELECT
  USING (auth.uid() = user_id);

-- Usuários podem criar suas próprias assinaturas
DROP POLICY IF EXISTS "Users can create own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can create own subscriptions"
  ON public.user_subscriptions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Usuários podem atualizar suas próprias assinaturas
DROP POLICY IF EXISTS "Users can update own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can update own subscriptions"
  ON public.user_subscriptions FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================
-- 4. CRIAR POLÍTICAS PARA SUBSCRIPTION_PAYMENTS
-- ============================================

-- Usuários podem ver seus próprios pagamentos
DROP POLICY IF EXISTS "Users can view own payments" ON public.subscription_payments;
CREATE POLICY "Users can view own payments"
  ON public.subscription_payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_subscriptions
      WHERE user_subscriptions.id = subscription_payments.subscription_id
      AND user_subscriptions.user_id = auth.uid()
    )
  );

-- Usuários podem criar seus próprios pagamentos
DROP POLICY IF EXISTS "Users can create own payments" ON public.subscription_payments;
CREATE POLICY "Users can create own payments"
  ON public.subscription_payments FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_subscriptions
      WHERE user_subscriptions.id = subscription_payments.subscription_id
      AND user_subscriptions.user_id = auth.uid()
    )
  );

-- Usuários podem atualizar seus próprios pagamentos
DROP POLICY IF EXISTS "Users can update own payments" ON public.subscription_payments;
CREATE POLICY "Users can update own payments"
  ON public.subscription_payments FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.user_subscriptions
      WHERE user_subscriptions.id = subscription_payments.subscription_id
      AND user_subscriptions.user_id = auth.uid()
    )
  );

-- ============================================
-- 5. VERIFICAR SE RLS ESTÁ HABILITADO
-- ============================================

DO $$
DECLARE
  rls_enabled BOOLEAN;
BEGIN
  -- Verificar subscription_plans
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'subscription_plans';
  
  IF rls_enabled THEN
    RAISE NOTICE '✅ RLS habilitado em subscription_plans';
  ELSE
    RAISE WARNING '❌ RLS NÃO habilitado em subscription_plans';
  END IF;
  
  -- Verificar user_subscriptions
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'user_subscriptions';
  
  IF rls_enabled THEN
    RAISE NOTICE '✅ RLS habilitado em user_subscriptions';
  ELSE
    RAISE WARNING '❌ RLS NÃO habilitado em user_subscriptions';
  END IF;
  
  -- Verificar subscription_payments
  SELECT relrowsecurity INTO rls_enabled
  FROM pg_class
  WHERE relname = 'subscription_payments';
  
  IF rls_enabled THEN
    RAISE NOTICE '✅ RLS habilitado em subscription_payments';
  ELSE
    RAISE WARNING '❌ RLS NÃO habilitado em subscription_payments';
  END IF;
END $$;

-- ============================================
-- 6. LISTAR TODAS AS POLÍTICAS CRIADAS
-- ============================================

SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('subscription_plans', 'user_subscriptions', 'subscription_payments')
ORDER BY tablename, policyname;

-- ============================================
-- PRONTO! ✅
-- ============================================
-- Agora as tabelas de assinaturas estão protegidas com RLS
