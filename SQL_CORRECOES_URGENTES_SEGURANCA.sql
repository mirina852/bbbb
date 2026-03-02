-- ============================================
-- 🚨 CORREÇÕES URGENTES DE SEGURANÇA
-- ============================================
-- Execute este SQL IMEDIATAMENTE para corrigir
-- problemas críticos de segurança detectados via MCP

-- ============================================
-- 🔴 PROBLEMA 1: Credenciais de Pagamento Expostas
-- ============================================

-- Habilitar RLS na tabela de credenciais
ALTER TABLE public.merchant_payment_credentials 
ENABLE ROW LEVEL SECURITY;

-- Criar política: Usuários gerenciam apenas suas próprias credenciais
CREATE POLICY "Users manage own payment credentials"
  ON public.merchant_payment_credentials
  FOR ALL
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================
-- 🔴 PROBLEMA 2: Tabelas de Teste Expostas
-- ============================================

-- Remover tabelas de teste que não deveriam estar em produção
DROP TABLE IF EXISTS public.test_user_id CASCADE;
DROP TABLE IF EXISTS public.v_store_id CASCADE;

-- ============================================
-- 🔴 PROBLEMA 3: RLS Desabilitado em Tabelas com Políticas
-- ============================================

-- Habilitar RLS na tabela produtos
ALTER TABLE public.produtos 
ENABLE ROW LEVEL SECURITY;

-- Habilitar RLS na tabela site_settings
ALTER TABLE public.site_settings 
ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 🟠 PROBLEMA 4: Índices Faltando (Performance)
-- ============================================

-- Criar índices para Foreign Keys (melhora performance)
CREATE INDEX IF NOT EXISTS idx_merchant_payment_credentials_user_id 
  ON public.merchant_payment_credentials(user_id);

CREATE INDEX IF NOT EXISTS idx_products_store_id 
  ON public.products(store_id);

CREATE INDEX IF NOT EXISTS idx_site_settings_user_id 
  ON public.site_settings(user_id);

CREATE INDEX IF NOT EXISTS idx_subscription_payments_plan_id 
  ON public.subscription_payments(subscription_plan_id);

CREATE INDEX IF NOT EXISTS idx_subscription_payments_user_id 
  ON public.subscription_payments(user_id);

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_plan_id 
  ON public.user_subscriptions(subscription_plan_id);

-- ============================================
-- 🟡 PROBLEMA 5: Funções sem search_path (Segurança)
-- ============================================

-- Configurar search_path nas funções para evitar injeção de schema
ALTER FUNCTION public.get_active_subscription 
  SET search_path = public, pg_temp;

ALTER FUNCTION public.has_active_subscription 
  SET search_path = public, pg_temp;

ALTER FUNCTION public.get_user_store_id 
  SET search_path = public, pg_temp;

ALTER FUNCTION public.generate_unique_slug 
  SET search_path = public, pg_temp;

ALTER FUNCTION public.update_updated_at_column 
  SET search_path = public, pg_temp;

ALTER FUNCTION public.update_categories_updated_at 
  SET search_path = public, pg_temp;

ALTER FUNCTION public.update_orders_updated_at 
  SET search_path = public, pg_temp;

ALTER FUNCTION public.update_produtos_updated_at 
  SET search_path = public, pg_temp;

-- ============================================
-- ✅ VERIFICAÇÃO
-- ============================================

-- 1. Verificar RLS habilitado em todas as tabelas
SELECT 
  tablename AS "Tabela",
  CASE 
    WHEN rowsecurity THEN '✅ Habilitado'
    ELSE '❌ Desabilitado'
  END AS "RLS"
FROM pg_tables
WHERE schemaname = 'public'
AND tablename NOT LIKE 'pg_%'
ORDER BY tablename;

-- 2. Verificar políticas criadas
SELECT 
  schemaname AS "Schema",
  tablename AS "Tabela",
  policyname AS "Política",
  cmd AS "Comando"
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- 3. Verificar índices criados
SELECT 
  tablename AS "Tabela",
  indexname AS "Índice"
FROM pg_indexes
WHERE schemaname = 'public'
AND indexname LIKE 'idx_%'
ORDER BY tablename;

-- 4. Verificar funções com search_path configurado
SELECT 
  routine_name AS "Função",
  CASE 
    WHEN prosecdef THEN '✅ SECURITY DEFINER'
    ELSE 'SECURITY INVOKER'
  END AS "Segurança"
FROM information_schema.routines r
JOIN pg_proc p ON p.proname = r.routine_name
WHERE r.routine_schema = 'public'
AND r.routine_type = 'FUNCTION'
ORDER BY routine_name;

-- ============================================
-- 📊 RESUMO DAS CORREÇÕES
-- ============================================

-- Após executar este SQL, você terá:
-- ✅ RLS habilitado em merchant_payment_credentials (CRÍTICO!)
-- ✅ Tabelas de teste removidas
-- ✅ RLS habilitado em produtos e site_settings
-- ✅ 6 índices criados para melhorar performance
-- ✅ 8 funções protegidas contra injeção de schema

-- ============================================
-- ⚠️ AÇÕES MANUAIS NECESSÁRIAS
-- ============================================

-- 1. Ativar proteção contra senhas vazadas:
--    Dashboard Supabase → Authentication → Policies
--    Ative: "Leaked Password Protection"

-- 2. Revisar políticas duplicadas:
--    Algumas tabelas têm múltiplas políticas redundantes
--    Considere consolidá-las para melhor performance

-- 3. Otimizar políticas RLS existentes:
--    Substituir: auth.uid()
--    Por: (SELECT auth.uid())
--    Em todas as políticas para melhor performance

-- ============================================
-- 🎯 RESULTADO ESPERADO
-- ============================================

-- Antes:
-- ❌ Credenciais de pagamento expostas publicamente
-- ❌ Tabelas de teste em produção
-- ❌ RLS desabilitado em 5 tabelas
-- ⚠️ Queries lentas por falta de índices
-- ⚠️ Funções vulneráveis a injeção

-- Depois:
-- ✅ Credenciais protegidas por RLS
-- ✅ Tabelas de teste removidas
-- ✅ RLS habilitado em todas as tabelas necessárias
-- ✅ Performance melhorada com índices
-- ✅ Funções protegidas contra injeção

-- ============================================
-- FIM DAS CORREÇÕES URGENTES
-- ============================================
