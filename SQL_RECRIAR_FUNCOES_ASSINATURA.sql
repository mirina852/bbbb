-- ============================================
-- RECRIAR FUNÇÕES DE ASSINATURA (CORRIGIDO)
-- ============================================

-- 1. DELETAR FUNÇÕES ANTIGAS (se existirem)
DROP FUNCTION IF EXISTS public.get_active_subscription(UUID);
DROP FUNCTION IF EXISTS public.has_active_subscription(UUID);

-- 2. CRIAR FUNÇÃO get_active_subscription (NOVA)
CREATE FUNCTION public.get_active_subscription(_user_id UUID)
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
$$;

-- 3. CRIAR FUNÇÃO has_active_subscription (NOVA)
CREATE FUNCTION public.has_active_subscription(_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.user_subscriptions
    WHERE user_id = _user_id
      AND status = 'active'
      AND expires_at > NOW()
  );
END;
$$;

-- ============================================
-- 4. VERIFICAR SE FORAM CRIADAS
-- ============================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_active_subscription') THEN
    RAISE NOTICE '✅ Função get_active_subscription criada';
  ELSE
    RAISE WARNING '❌ Função get_active_subscription NÃO criada';
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'has_active_subscription') THEN
    RAISE NOTICE '✅ Função has_active_subscription criada';
  ELSE
    RAISE WARNING '❌ Função has_active_subscription NÃO criada';
  END IF;
END $$;

-- ============================================
-- 5. TESTAR AS FUNÇÕES
-- ============================================

-- Ver todas as assinaturas para pegar o user_id correto
SELECT 
  us.id AS subscription_id,
  us.user_id,
  sp.name AS plan_name,
  us.status,
  us.expires_at,
  CASE 
    WHEN us.expires_at > NOW() THEN 'Ativa ✅'
    ELSE 'Expirada ❌'
  END AS situacao
FROM public.user_subscriptions us
JOIN public.subscription_plans sp ON sp.id = us.subscription_plan_id
ORDER BY us.created_at DESC
LIMIT 5;

-- Testar a função com o primeiro user_id encontrado
-- (Você pode copiar o user_id da query acima e testar manualmente)

-- ============================================
-- PRONTO! ✅
-- ============================================
-- Após executar este SQL:
-- 1. Recarregue a página do site (Ctrl+F5)
-- 2. Você será redirecionado para /store-setup
-- 3. Crie sua primeira loja!
