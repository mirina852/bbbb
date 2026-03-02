-- ============================================
-- 🚨 EXECUTAR AGORA NO SUPABASE SQL EDITOR
-- Fix: Cálculo Correto dos Dias Restantes
-- ============================================

-- 🐛 PROBLEMA:
-- A função estava usando EXTRACT(DAY FROM interval) que só pega
-- a parte dos "dias", ignorando meses.
-- Exemplo: 1 mês e 6 dias = retornava apenas 6 dias (ERRADO!)

-- ✅ SOLUÇÃO:
-- Usar subtração direta de datas: DATE - DATE
-- Exemplo: 1 mês e 6 dias = retorna 36 ou 37 dias (CORRETO!)

-- Recriar função com cálculo correto
CREATE OR REPLACE FUNCTION public.get_active_subscription(_user_id UUID)
RETURNS TABLE (
  id UUID,
  plan_name TEXT,
  plan_slug TEXT,
  status TEXT,
  expires_at TIMESTAMP WITH TIME ZONE,
  days_remaining INTEGER
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    us.id,
    sp.name AS plan_name,
    sp.slug AS plan_slug,
    us.status,
    us.expires_at,
    -- ✅ CÁLCULO CORRETO: Subtrai datas diretamente
    GREATEST(0, (DATE(us.expires_at) - DATE(NOW()))::INTEGER) AS days_remaining
  FROM public.user_subscriptions us
  JOIN public.subscription_plans sp ON us.subscription_plan_id = sp.id
  WHERE us.user_id = _user_id
  ORDER BY us.created_at DESC
  LIMIT 1;
END;
$$;

-- ============================================
-- ✅ VERIFICAR SE FUNCIONOU
-- ============================================

-- 1️⃣ Verificar sua assinatura atual
-- (Substitua 'seu-user-id' pelo seu ID de usuário)
SELECT 
  plan_name AS "Plano",
  expires_at AS "Expira em",
  days_remaining AS "Dias Restantes (Novo Cálculo)",
  (DATE(expires_at) - DATE(NOW()))::INTEGER AS "Verificação Manual"
FROM get_active_subscription(auth.uid());

-- Se "Dias Restantes" = "Verificação Manual", está CORRETO! ✅

-- ============================================
-- 📊 EXEMPLOS DE CÁLCULO
-- ============================================

-- Exemplo 1: Expira em 19 de outubro de 2025
-- Hoje: 12 de outubro de 2025
-- Dias restantes: 7 dias ✅

-- Exemplo 2: Expira em 19 de novembro de 2025
-- Hoje: 12 de outubro de 2025
-- Dias restantes: 38 dias ✅ (não 7!)

-- ============================================
-- 🧪 TESTAR NO PAINEL
-- ============================================

-- Após executar este SQL:
-- 1. Volte ao painel admin
-- 2. Acesse: Admin → Assinatura
-- 3. Verifique se os "Dias Restantes" estão corretos
-- 4. Deve mostrar o número real de dias até expirar!

-- ============================================
-- 📝 EXPLICAÇÃO TÉCNICA
-- ============================================

-- ANTES (ERRADO):
-- EXTRACT(DAY FROM (expires_at - NOW()))
-- 
-- Problema: EXTRACT(DAY) só pega a parte "dias" do intervalo
-- Intervalo: 1 month 7 days → EXTRACT(DAY) = 7 (ignora o mês!)

-- DEPOIS (CORRETO):
-- (DATE(expires_at) - DATE(NOW()))::INTEGER
--
-- Solução: Subtração direta de datas
-- DATE('2025-11-19') - DATE('2025-10-12') = 38 dias (correto!)
