-- ============================================
-- DIAGNÓSTICO COMPLETO DO SISTEMA DE ASSINATURAS
-- Execute este SQL no Supabase SQL Editor
-- ============================================

-- 1. Verificar se tabelas existem
SELECT 
  '📋 1. VERIFICAÇÃO DE TABELAS' as secao,
  table_name,
  CASE 
    WHEN table_name IS NOT NULL THEN '✅ Existe'
    ELSE '❌ Não existe'
  END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('subscription_plans', 'user_subscriptions', 'subscription_payments')
ORDER BY table_name;

-- 2. Verificar estrutura da tabela subscription_plans
SELECT 
  '📊 2. ESTRUTURA: subscription_plans' as secao,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'subscription_plans'
ORDER BY ordinal_position;

-- 3. Verificar estrutura da tabela user_subscriptions
SELECT 
  '📊 3. ESTRUTURA: user_subscriptions' as secao,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'user_subscriptions'
ORDER BY ordinal_position;

-- 4. Verificar se há planos cadastrados
SELECT 
  '💳 4. PLANOS CADASTRADOS' as secao,
  id,
  name,
  slug,
  price,
  duration_days,
  is_trial,
  is_active,
  CASE 
    WHEN is_active THEN '✅ Ativo'
    ELSE '❌ Inativo'
  END as status
FROM subscription_plans
ORDER BY price;

-- 5. Contar planos por tipo
SELECT 
  '📈 5. ESTATÍSTICAS DE PLANOS' as secao,
  COUNT(*) as total_planos,
  COUNT(*) FILTER (WHERE is_trial = true) as planos_gratuitos,
  COUNT(*) FILTER (WHERE is_trial = false) as planos_pagos,
  COUNT(*) FILTER (WHERE is_active = true) as planos_ativos,
  COUNT(*) FILTER (WHERE is_active = false) as planos_inativos
FROM subscription_plans;

-- 6. Verificar funções RPC
SELECT 
  '🔧 6. FUNÇÕES RPC' as secao,
  routine_name,
  routine_type,
  '✅ Existe' as status
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('get_active_subscription', 'has_active_subscription', 'generate_unique_slug')
ORDER BY routine_name;

-- 7. Verificar políticas RLS
SELECT 
  '🔒 7. POLÍTICAS RLS (subscription_plans)' as secao,
  policyname,
  cmd as comando,
  qual as condicao
FROM pg_policies
WHERE tablename = 'subscription_plans'
ORDER BY cmd;

SELECT 
  '🔒 8. POLÍTICAS RLS (user_subscriptions)' as secao,
  policyname,
  cmd as comando,
  qual as condicao
FROM pg_policies
WHERE tablename = 'user_subscriptions'
ORDER BY cmd;

-- 9. Verificar sua assinatura atual
SELECT 
  '👤 9. SUA ASSINATURA ATUAL' as secao,
  us.id,
  sp.name as plano,
  us.status,
  us.created_at as inicio,
  us.expires_at as expira,
  EXTRACT(DAY FROM (us.expires_at - NOW()))::INTEGER as dias_restantes,
  CASE 
    WHEN us.expires_at > NOW() AND us.status = 'active' THEN '✅ Ativa'
    WHEN us.expires_at <= NOW() THEN '❌ Expirada'
    ELSE '⚠️ Inativa'
  END as status_real
FROM user_subscriptions us
JOIN subscription_plans sp ON sp.id = us.subscription_plan_id
WHERE us.user_id = auth.uid()
ORDER BY us.created_at DESC
LIMIT 5;

-- 10. Verificar histórico de assinaturas
SELECT 
  '📜 10. HISTÓRICO DE ASSINATURAS' as secao,
  COUNT(*) as total_assinaturas,
  COUNT(*) FILTER (WHERE status = 'active') as ativas,
  COUNT(*) FILTER (WHERE status = 'expired') as expiradas,
  COUNT(*) FILTER (WHERE status = 'cancelled') as canceladas
FROM user_subscriptions
WHERE user_id = auth.uid();

-- 11. Testar função get_active_subscription
SELECT 
  '🧪 11. TESTE: get_active_subscription' as secao,
  *
FROM get_active_subscription(auth.uid());

-- 12. Testar função has_active_subscription
SELECT 
  '🧪 12. TESTE: has_active_subscription' as secao,
  has_active_subscription(auth.uid()) as tem_assinatura_ativa,
  CASE 
    WHEN has_active_subscription(auth.uid()) THEN '✅ Sim'
    ELSE '❌ Não'
  END as status;

-- 13. Verificar índices
SELECT 
  '📇 13. ÍNDICES' as secao,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('subscription_plans', 'user_subscriptions')
ORDER BY tablename, indexname;

-- 14. Verificar seu user_id
SELECT 
  '🆔 14. SEU USER ID' as secao,
  auth.uid() as seu_user_id,
  (SELECT email FROM auth.users WHERE id = auth.uid()) as seu_email;

-- 15. Verificar se há problemas de data
SELECT 
  '⏰ 15. VERIFICAÇÃO DE DATAS' as secao,
  us.id,
  sp.name as plano,
  us.created_at,
  us.expires_at,
  NOW() as data_atual,
  us.expires_at > NOW() as ainda_valida,
  EXTRACT(DAY FROM (us.expires_at - NOW()))::INTEGER as dias_restantes,
  CASE 
    WHEN us.expires_at > NOW() THEN '✅ Válida'
    ELSE '❌ Expirada'
  END as status
FROM user_subscriptions us
JOIN subscription_plans sp ON sp.id = us.subscription_plan_id
WHERE us.user_id = auth.uid()
ORDER BY us.created_at DESC
LIMIT 1;

-- ============================================
-- RESUMO FINAL
-- ============================================

SELECT 
  '📊 RESUMO FINAL' as secao,
  (SELECT COUNT(*) FROM subscription_plans) as total_planos_disponiveis,
  (SELECT COUNT(*) FROM user_subscriptions WHERE user_id = auth.uid()) as suas_assinaturas,
  (SELECT COUNT(*) FROM user_subscriptions WHERE user_id = auth.uid() AND status = 'active' AND expires_at > NOW()) as assinaturas_ativas,
  CASE 
    WHEN EXISTS (SELECT 1 FROM user_subscriptions WHERE user_id = auth.uid() AND status = 'active' AND expires_at > NOW()) 
    THEN '✅ Você tem assinatura ativa'
    ELSE '❌ Você NÃO tem assinatura ativa'
  END as seu_status;

-- ============================================
-- POSSÍVEIS PROBLEMAS DETECTADOS
-- ============================================

-- Problema 1: Tabelas não existem?
SELECT 
  '⚠️ PROBLEMA 1: Tabelas faltando?' as problema,
  CASE 
    WHEN (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('subscription_plans', 'user_subscriptions')) = 2
    THEN '✅ OK - Todas as tabelas existem'
    ELSE '❌ ERRO - Tabelas faltando! Execute a migration.'
  END as diagnostico;

-- Problema 2: Planos não cadastrados?
SELECT 
  '⚠️ PROBLEMA 2: Planos não cadastrados?' as problema,
  CASE 
    WHEN (SELECT COUNT(*) FROM subscription_plans) >= 1
    THEN '✅ OK - Há ' || (SELECT COUNT(*) FROM subscription_plans) || ' plano(s) cadastrado(s)'
    ELSE '❌ ERRO - Nenhum plano cadastrado! Execute o script de inserção.'
  END as diagnostico;

-- Problema 3: Funções RPC não existem?
SELECT 
  '⚠️ PROBLEMA 3: Funções RPC faltando?' as problema,
  CASE 
    WHEN (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name IN ('get_active_subscription', 'has_active_subscription')) = 2
    THEN '✅ OK - Todas as funções existem'
    ELSE '❌ ERRO - Funções faltando! Execute o script de criação.'
  END as diagnostico;

-- Problema 4: Você não tem assinatura?
SELECT 
  '⚠️ PROBLEMA 4: Sem assinatura ativa?' as problema,
  CASE 
    WHEN EXISTS (SELECT 1 FROM user_subscriptions WHERE user_id = auth.uid() AND status = 'active' AND expires_at > NOW())
    THEN '✅ OK - Você tem assinatura ativa'
    ELSE '❌ ERRO - Você não tem assinatura ativa! Crie uma assinatura de teste.'
  END as diagnostico;

-- Problema 5: Assinatura expirada?
SELECT 
  '⚠️ PROBLEMA 5: Assinatura expirada?' as problema,
  CASE 
    WHEN NOT EXISTS (SELECT 1 FROM user_subscriptions WHERE user_id = auth.uid())
    THEN '⚠️ N/A - Você nunca teve assinatura'
    WHEN EXISTS (SELECT 1 FROM user_subscriptions WHERE user_id = auth.uid() AND expires_at <= NOW())
    THEN '❌ ERRO - Sua assinatura expirou em ' || (SELECT expires_at::TEXT FROM user_subscriptions WHERE user_id = auth.uid() ORDER BY created_at DESC LIMIT 1)
    ELSE '✅ OK - Assinatura ainda válida'
  END as diagnostico;

-- ============================================
-- AÇÕES RECOMENDADAS
-- ============================================

SELECT 
  '💡 AÇÕES RECOMENDADAS' as secao,
  CASE 
    -- Caso 1: Tabelas não existem
    WHEN (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('subscription_plans', 'user_subscriptions')) < 2
    THEN '1️⃣ Execute a migration: 20251010193700_create_subscription_tables.sql'
    
    -- Caso 2: Planos não cadastrados
    WHEN (SELECT COUNT(*) FROM subscription_plans) = 0
    THEN '2️⃣ Execute o script: SQL_ATIVAR_ASSINATURA_TESTE.sql (seção de inserir planos)'
    
    -- Caso 3: Funções não existem
    WHEN (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'public' AND routine_name IN ('get_active_subscription', 'has_active_subscription')) < 2
    THEN '3️⃣ Execute o script: SQL_ATIVAR_ASSINATURA_TESTE.sql (seção de criar funções)'
    
    -- Caso 4: Sem assinatura
    WHEN NOT EXISTS (SELECT 1 FROM user_subscriptions WHERE user_id = auth.uid() AND status = 'active' AND expires_at > NOW())
    THEN '4️⃣ Execute o script: SQL_ATIVAR_ASSINATURA_TESTE.sql (seção de criar assinatura)'
    
    -- Caso 5: Tudo OK
    ELSE '✅ Tudo está funcionando! Você pode usar o sistema normalmente.'
  END as acao;
