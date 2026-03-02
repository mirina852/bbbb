-- ============================================
-- 🚨 EXECUTAR AGORA NO SUPABASE SQL EDITOR
-- Fix COMPLETO: Datas e Dias Restantes da Assinatura
-- ============================================

-- 🐛 PROBLEMAS:
-- 1. DATE(expires_at) - DATE(NOW()) ignora horas, causando diferença de 1 dia
-- 2. created_at não estava sendo retornado pela função
-- 3. Data de início estava sendo calculada retroativamente no frontend

-- ✅ SOLUÇÕES:
-- 1. Usar EXTRACT(EPOCH) para calcular dias com precisão (inclui horas)
-- 2. Retornar created_at real da assinatura
-- 3. Frontend usará created_at ao invés de calcular retroativamente

-- Recriar função com cálculo correto e created_at
CREATE OR REPLACE FUNCTION public.get_active_subscription(_user_id UUID)
RETURNS TABLE (
  id UUID,
  plan_name TEXT,
  plan_slug TEXT,
  status TEXT,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE,  -- ✅ Data de início REAL
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
    us.created_at,  -- ✅ Retornar data real de criação
    -- ✅ Cálculo CORRETO considerando horas, minutos e segundos
    GREATEST(
      0, 
      FLOOR(EXTRACT(EPOCH FROM (us.expires_at - NOW())) / 86400)::INTEGER
    ) AS days_remaining
  FROM public.user_subscriptions us
  JOIN public.subscription_plans sp ON us.subscription_plan_id = sp.id
  WHERE us.user_id = _user_id
  ORDER BY us.created_at DESC
  LIMIT 1;
END;
$$;

-- Adicionar comentário explicativo
COMMENT ON FUNCTION public.get_active_subscription IS 
  'Retorna a assinatura ativa do usuário com:
   - created_at: Data real de quando a assinatura foi criada
   - days_remaining: Dias restantes calculados com precisão (usando EPOCH)
   - expires_at: Data de expiração
   
   Cálculo de dias: EXTRACT(EPOCH) converte para segundos, divide por 86400 (segundos em 1 dia),
   e FLOOR arredonda para baixo. Isso garante precisão considerando horas, minutos e segundos.';

-- ============================================
-- 📊 EXPLICAÇÃO DO CÁLCULO
-- ============================================

-- ANTES (ERRADO):
-- DATE(expires_at) - DATE(NOW())
-- Problema: Converte para DATE, perdendo informação de hora
-- Exemplo:
--   expires_at: 2025-10-19 23:59:59
--   NOW():      2025-10-12 10:30:00
--   DATE('2025-10-19') - DATE('2025-10-12') = 7 dias
--   Mas na verdade faltam 7 dias + 13h29m59s ≈ 7.56 dias
--   Arredondamento pode causar diferença de 1 dia

-- DEPOIS (CORRETO):
-- EXTRACT(EPOCH FROM (expires_at - NOW())) / 86400
-- Solução: Calcula diferença em segundos, depois converte para dias
-- Exemplo:
--   expires_at: 2025-10-19 23:59:59
--   NOW():      2025-10-12 10:30:00
--   Diferença:  7 dias 13h29m59s = 653399 segundos
--   653399 / 86400 = 7.56 dias
--   FLOOR(7.56) = 7 dias ✅ (arredonda para baixo)

-- ============================================
-- ✅ VERIFICAR SE FUNCIONOU
-- ============================================

-- Ver sua assinatura com datas e cálculo corretos
SELECT 
  plan_name AS "Plano",
  TO_CHAR(created_at, 'DD/MM/YYYY HH24:MI:SS') AS "Data de Início (Real)",
  TO_CHAR(expires_at, 'DD/MM/YYYY HH24:MI:SS') AS "Expira em",
  days_remaining AS "Dias Restantes",
  -- Verificação manual do cálculo
  FLOOR(EXTRACT(EPOCH FROM (expires_at - NOW())) / 86400)::INTEGER AS "Verificação Manual",
  -- Diferença em horas (para debug)
  ROUND(EXTRACT(EPOCH FROM (expires_at - NOW())) / 3600, 2) AS "Horas Restantes"
FROM get_active_subscription(auth.uid());

-- Se "Dias Restantes" = "Verificação Manual", está CORRETO! ✅

-- ============================================
-- 🧪 EXEMPLOS DE CÁLCULO
-- ============================================

-- Exemplo 1: Expira hoje às 23:59
-- created_at:  2025-10-05 00:00:00
-- expires_at:  2025-10-12 23:59:59
-- NOW():       2025-10-12 10:00:00
-- Diferença:   13h59m59s = 50399 segundos
-- Dias:        50399 / 86400 = 0.58 dias → FLOOR = 0 dias ✅

-- Exemplo 2: Expira daqui 7 dias
-- created_at:  2025-10-05 10:00:00
-- expires_at:  2025-10-19 10:00:00
-- NOW():       2025-10-12 10:00:00
-- Diferença:   7 dias = 604800 segundos
-- Dias:        604800 / 86400 = 7 dias ✅

-- Exemplo 3: Expira daqui 7 dias e meio
-- created_at:  2025-10-05 10:00:00
-- expires_at:  2025-10-19 22:00:00
-- NOW():       2025-10-12 10:00:00
-- Diferença:   7 dias 12h = 648000 segundos
-- Dias:        648000 / 86400 = 7.5 dias → FLOOR = 7 dias ✅

-- ============================================
-- 🧪 TESTAR NO PAINEL
-- ============================================

-- Após executar este SQL:
-- 1. Volte ao painel admin
-- 2. Acesse: Admin → Assinatura
-- 3. Verifique:
--    ✅ "Data de Início" mostra quando você criou a assinatura
--    ✅ "Expira em" mostra a data correta de expiração
--    ✅ "Dias Restantes" está correto (considerando horas)
--    ✅ Barra de progresso coerente com os dias

-- ============================================
-- 📝 NOTAS IMPORTANTES
-- ============================================

-- 1. EPOCH = Segundos desde 1970-01-01 00:00:00 UTC
-- 2. 86400 = Segundos em 1 dia (24 * 60 * 60)
-- 3. FLOOR = Arredonda para baixo (7.9 dias → 7 dias)
-- 4. GREATEST(0, ...) = Garante que nunca seja negativo
