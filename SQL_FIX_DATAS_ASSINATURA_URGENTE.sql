-- ============================================
-- 🚨 EXECUTAR AGORA NO SUPABASE SQL EDITOR
-- Fix: Datas da Assinatura (Data de Início e Expiração)
-- ============================================

-- 🐛 PROBLEMA:
-- A "Data de Início" estava sendo calculada retroativamente no frontend,
-- subtraindo dias da data de expiração. Isso gera datas incorretas.

-- ✅ SOLUÇÃO:
-- Retornar o created_at real da assinatura (quando foi criada)

-- Recriar função incluindo created_at
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
    us.created_at,  -- ✅ Data real de quando a assinatura foi criada
    -- Cálculo correto dos dias restantes
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

-- Ver sua assinatura com datas corretas
SELECT 
  plan_name AS "Plano",
  TO_CHAR(created_at, 'DD/MM/YYYY HH24:MI') AS "Data de Início (Real)",
  TO_CHAR(expires_at, 'DD/MM/YYYY HH24:MI') AS "Expira em",
  days_remaining AS "Dias Restantes"
FROM get_active_subscription(auth.uid());

-- ============================================
-- 🧪 TESTAR NO PAINEL
-- ============================================

-- Após executar este SQL:
-- 1. Volte ao painel admin
-- 2. Acesse: Admin → Assinatura
-- 3. Verifique:
--    - "Data de Início" deve mostrar quando você criou a assinatura
--    - "Expira em" deve mostrar a data correta de expiração
--    - "Dias Restantes" deve estar correto
