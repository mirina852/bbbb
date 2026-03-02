-- ============================================
-- CRIAR FUNÇÃO get_active_subscription
-- ============================================

-- Função para buscar assinatura ativa do usuário
CREATE OR REPLACE FUNCTION public.get_active_subscription(_user_id UUID)
RETURNS TABLE (
  id UUID,
  plan_name TEXT,
  plan_slug TEXT,
  status TEXT,
  expires_at TIMESTAMP WITH TIME ZONE,
  days_remaining INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    us.id,
    sp.name AS plan_name,
    sp.slug AS plan_slug,
    us.status,
    us.expires_at,
    CASE 
      WHEN us.expires_at > NOW() THEN EXTRACT(DAY FROM us.expires_at - NOW())::INTEGER
      ELSE 0
    END AS days_remaining
  FROM public.user_subscriptions us
  JOIN public.subscription_plans sp ON sp.id = us.subscription_plan_id
  WHERE us.user_id = _user_id
    AND us.status = 'active'
    AND us.expires_at > NOW()
  ORDER BY us.expires_at DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para verificar se tem assinatura ativa (boolean)
CREATE OR REPLACE FUNCTION public.has_active_subscription(_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_subscriptions
    WHERE user_id = _user_id
      AND status = 'active'
      AND expires_at > NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TESTAR AS FUNÇÕES
-- ============================================

-- Testar get_active_subscription (substitua pelo seu user_id)
SELECT * FROM public.get_active_subscription('1a375586-9c50-49e7-9f47-6656c401988f');

-- Testar has_active_subscription
SELECT public.has_active_subscription('1a375586-9c50-49e7-9f47-6656c401988f');

-- Ver todas as assinaturas ativas
SELECT 
  us.id,
  us.user_id,
  sp.name AS plan_name,
  us.status,
  us.expires_at,
  CASE 
    WHEN us.expires_at > NOW() THEN 'Ativa'
    ELSE 'Expirada'
  END AS situacao
FROM public.user_subscriptions us
JOIN public.subscription_plans sp ON sp.id = us.subscription_plan_id
WHERE us.status = 'active'
ORDER BY us.expires_at DESC;

-- ============================================
-- VERIFICAR SE AS FUNÇÕES FORAM CRIADAS
-- ============================================
SELECT 
  proname AS function_name,
  pg_get_function_arguments(oid) AS arguments,
  pg_get_function_result(oid) AS return_type
FROM pg_proc
WHERE proname IN ('get_active_subscription', 'has_active_subscription')
  AND pronamespace = 'public'::regnamespace;
