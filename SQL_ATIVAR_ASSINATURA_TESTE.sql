-- ============================================
-- ATIVAR ASSINATURA DE TESTE - SOLUÇÃO RÁPIDA
-- Execute este SQL no Supabase SQL Editor
-- ============================================

-- 1. Criar tabelas (se não existirem)
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  duration_days INTEGER NOT NULL,
  is_trial BOOLEAN NOT NULL DEFAULT false,
  features JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subscription_plan_id UUID NOT NULL REFERENCES public.subscription_plans(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- 2. Criar índices
CREATE INDEX IF NOT EXISTS user_subscriptions_user_id_idx ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS user_subscriptions_status_idx ON public.user_subscriptions(status);

-- 3. Habilitar RLS
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

-- 4. Criar políticas
DROP POLICY IF EXISTS "Anyone can view subscription plans" ON public.subscription_plans;
CREATE POLICY "Anyone can view subscription plans"
  ON public.subscription_plans FOR SELECT
  USING (is_active = true);

DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can view own subscriptions"
  ON public.user_subscriptions FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can insert own subscriptions"
  ON public.user_subscriptions FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 5. Inserir planos de assinatura
INSERT INTO subscription_plans (name, slug, price, duration_days, is_trial, features) VALUES
  ('Teste Gratuito', 'trial', 0, 7, true, 
   '["Loja online completa", "Gestão de pedidos ilimitados", "Dashboard com estatísticas", "Suporte por email"]'::jsonb),
  
  ('Plano Mensal', 'monthly', 29.90, 30, false,
   '["Todos os recursos do teste", "Pedidos ilimitados", "Produtos ilimitados", "Suporte prioritário", "Atualizações gratuitas"]'::jsonb),
  
  ('Plano Anual', 'yearly', 299.90, 365, false,
   '["Todos os recursos do mensal", "2 meses grátis", "Suporte VIP exclusivo", "Prioridade em novos recursos"]'::jsonb)
ON CONFLICT (slug) DO NOTHING;

-- 6. Criar funções RPC
CREATE OR REPLACE FUNCTION get_active_subscription(_user_id UUID)
RETURNS TABLE (
  id UUID,
  plan_name TEXT,
  plan_slug TEXT,
  status TEXT,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE,
  days_remaining INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    us.id,
    sp.name as plan_name,
    sp.slug as plan_slug,
    us.status,
    us.expires_at,
    us.created_at,
    GREATEST(0, EXTRACT(DAY FROM (us.expires_at - NOW()))::INTEGER) as days_remaining
  FROM user_subscriptions us
  JOIN subscription_plans sp ON sp.id = us.subscription_plan_id
  WHERE us.user_id = _user_id
    AND us.status = 'active'
    AND us.expires_at > NOW()
  ORDER BY us.created_at DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION has_active_subscription(_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM user_subscriptions 
    WHERE user_id = _user_id 
      AND status = 'active' 
      AND expires_at > NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Criar assinatura de teste para você (7 dias grátis)
INSERT INTO user_subscriptions (user_id, subscription_plan_id, status, expires_at)
SELECT 
  auth.uid(),
  id,
  'active',
  NOW() + INTERVAL '7 days'
FROM subscription_plans 
WHERE slug = 'trial'
LIMIT 1
ON CONFLICT DO NOTHING;

-- ============================================
-- VERIFICAÇÃO FINAL
-- ============================================

-- Verificar se tudo foi criado corretamente
SELECT 
  '✅ ASSINATURA ATIVADA!' as status,
  sp.name as plano,
  us.status as status_assinatura,
  us.expires_at as expira_em,
  EXTRACT(DAY FROM (us.expires_at - NOW()))::INTEGER as dias_restantes,
  '🎉 Você pode acessar o painel agora!' as mensagem
FROM user_subscriptions us
JOIN subscription_plans sp ON sp.id = us.subscription_plan_id
WHERE us.user_id = auth.uid()
  AND us.status = 'active'
ORDER BY us.created_at DESC
LIMIT 1;

-- Se não retornar nada acima, veja os detalhes:
SELECT 
  '📊 Detalhes:' as info,
  (SELECT COUNT(*) FROM subscription_plans) as total_planos,
  (SELECT COUNT(*) FROM user_subscriptions WHERE user_id = auth.uid()) as suas_assinaturas,
  auth.uid() as seu_user_id;

-- ============================================
-- PRONTO! ✅
-- ============================================
-- Agora:
-- 1. Faça logout e login novamente
-- 2. Acesse /admin
-- 3. Você terá 7 dias de teste gratuito!
