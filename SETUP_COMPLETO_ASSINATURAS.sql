-- ============================================
-- SETUP COMPLETO - SISTEMA DE ASSINATURAS
-- ============================================
-- Este arquivo contém TUDO que é necessário para configurar
-- o sistema de assinaturas no Supabase do zero.
--
-- INSTRUÇÕES:
-- 1. Acesse Supabase Dashboard > SQL Editor
-- 2. Copie e cole TODO este arquivo
-- 3. Execute (RUN)
-- 4. Aguarde confirmação de sucesso
--
-- Data: 19 de outubro de 2025
-- Versão: 2.0 (com proteção de trial único)
-- ============================================

-- ============================================
-- PARTE 1: CRIAR TABELAS
-- ============================================

-- 1.1 Tabela de Planos de Assinatura
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

-- 1.2 Tabela de Assinaturas dos Usuários
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subscription_plan_id UUID NOT NULL REFERENCES public.subscription_plans(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- 1.3 Tabela de Pagamentos
CREATE TABLE IF NOT EXISTS public.subscription_payments (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subscription_plan_id UUID NOT NULL REFERENCES public.subscription_plans(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'expired', 'cancelled')),
  payment_method TEXT DEFAULT 'pix',
  payment_id TEXT,
  external_payment_id TEXT,
  qr_code TEXT,
  qr_code_base64 TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- ============================================
-- PARTE 2: CRIAR ÍNDICES
-- ============================================

CREATE INDEX IF NOT EXISTS user_subscriptions_user_id_idx ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS user_subscriptions_status_idx ON public.user_subscriptions(status);
CREATE INDEX IF NOT EXISTS subscription_payments_user_id_idx ON public.subscription_payments(user_id);
CREATE INDEX IF NOT EXISTS subscription_payments_status_idx ON public.subscription_payments(status);
CREATE INDEX IF NOT EXISTS subscription_payments_payment_id_idx ON public.subscription_payments(payment_id);
CREATE INDEX IF NOT EXISTS subscription_payments_external_payment_id_idx ON public.subscription_payments(external_payment_id);

-- ============================================
-- PARTE 3: HABILITAR ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PARTE 4: CRIAR POLÍTICAS DE SEGURANÇA (RLS)
-- ============================================

-- 4.1 Políticas para subscription_plans (todos podem ver planos ativos)
DROP POLICY IF EXISTS "Anyone can view subscription plans" ON public.subscription_plans;
CREATE POLICY "Anyone can view subscription plans"
  ON public.subscription_plans
  FOR SELECT
  USING (is_active = true);

-- 4.2 Políticas para user_subscriptions (usuários veem apenas suas assinaturas)
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can view own subscriptions"
  ON public.user_subscriptions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can insert own subscriptions"
  ON public.user_subscriptions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own subscriptions" ON public.user_subscriptions;
CREATE POLICY "Users can update own subscriptions"
  ON public.user_subscriptions
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

-- 4.3 Políticas para subscription_payments
DROP POLICY IF EXISTS "Users can view own payments" ON public.subscription_payments;
CREATE POLICY "Users can view own payments"
  ON public.subscription_payments
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own payments" ON public.subscription_payments;
CREATE POLICY "Users can insert own payments"
  ON public.subscription_payments
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- PARTE 5: CRIAR TRIGGERS PARA UPDATED_AT
-- ============================================

-- 5.1 Função para atualizar updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- 5.2 Triggers
DROP TRIGGER IF EXISTS update_subscription_plans_updated_at ON public.subscription_plans;
CREATE TRIGGER update_subscription_plans_updated_at
  BEFORE UPDATE ON public.subscription_plans
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_subscriptions_updated_at ON public.user_subscriptions;
CREATE TRIGGER update_user_subscriptions_updated_at
  BEFORE UPDATE ON public.user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_subscription_payments_updated_at ON public.subscription_payments;
CREATE TRIGGER update_subscription_payments_updated_at
  BEFORE UPDATE ON public.subscription_payments
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- PARTE 6: FUNÇÕES RPC
-- ============================================

-- 6.1 Função para buscar assinatura ativa do usuário
CREATE OR REPLACE FUNCTION public.get_active_subscription(_user_id UUID)
RETURNS TABLE (
  id UUID,
  plan_name TEXT,
  plan_slug TEXT,
  status TEXT,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE,
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
    us.created_at,
    -- Cálculo correto dos dias restantes
    GREATEST(0, (DATE(us.expires_at) - DATE(NOW()))::INTEGER) AS days_remaining
  FROM public.user_subscriptions us
  JOIN public.subscription_plans sp ON us.subscription_plan_id = sp.id
  WHERE us.user_id = _user_id
  ORDER BY us.created_at DESC
  LIMIT 1;
END;
$$;

COMMENT ON FUNCTION public.get_active_subscription IS 
  'Retorna a assinatura ativa do usuário com data de início real (created_at) 
   e cálculo correto dos dias restantes.';

-- 6.2 Função para verificar se usuário tem assinatura ativa
CREATE OR REPLACE FUNCTION public.has_active_subscription(_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS(
    SELECT 1 
    FROM public.user_subscriptions 
    WHERE user_id = _user_id 
    AND status = 'active' 
    AND expires_at > NOW()
  );
END;
$$;

COMMENT ON FUNCTION public.has_active_subscription IS 
  'Verifica se o usuário possui uma assinatura ativa e não expirada.';

-- 6.3 Função para verificar se usuário já usou teste gratuito
CREATE OR REPLACE FUNCTION public.has_used_trial(_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.user_subscriptions us
    JOIN public.subscription_plans sp ON us.subscription_plan_id = sp.id
    WHERE us.user_id = _user_id
      AND sp.is_trial = true
  );
END;
$$;

COMMENT ON FUNCTION public.has_used_trial IS 
  'Verifica se o usuário já utilizou o teste gratuito alguma vez. 
   Retorna true se encontrar qualquer assinatura trial no histórico (independente do status).';

-- 6.4 Função para obter planos disponíveis para o usuário
CREATE OR REPLACE FUNCTION public.get_available_plans(_user_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  slug TEXT,
  price DECIMAL(10,2),
  duration_days INTEGER,
  is_trial BOOLEAN,
  features JSONB,
  is_available BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_has_used_trial BOOLEAN;
BEGIN
  -- Verificar se usuário já usou trial
  user_has_used_trial := public.has_used_trial(_user_id);
  
  -- Retornar todos os planos com flag de disponibilidade
  RETURN QUERY
  SELECT 
    sp.id,
    sp.name,
    sp.slug,
    sp.price,
    sp.duration_days,
    sp.is_trial,
    sp.features,
    -- Se for trial e usuário já usou, não está disponível
    CASE 
      WHEN sp.is_trial AND user_has_used_trial THEN false
      ELSE true
    END AS is_available
  FROM public.subscription_plans sp
  WHERE sp.is_active = true
  ORDER BY sp.price;
END;
$$;

COMMENT ON FUNCTION public.get_available_plans IS 
  'Retorna todos os planos de assinatura com flag indicando se está disponível para o usuário.
   Planos trial ficam indisponíveis se o usuário já os utilizou anteriormente.';

-- ============================================
-- PARTE 7: TRIGGER PARA PREVENIR MÚLTIPLOS TRIALS
-- ============================================

-- 7.1 Função do trigger
CREATE OR REPLACE FUNCTION public.prevent_multiple_trials()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  plan_is_trial BOOLEAN;
  user_has_trial BOOLEAN;
BEGIN
  -- Verificar se o plano sendo inserido é trial
  SELECT is_trial INTO plan_is_trial
  FROM public.subscription_plans
  WHERE id = NEW.subscription_plan_id;
  
  -- Se não for trial, permitir
  IF NOT plan_is_trial THEN
    RETURN NEW;
  END IF;
  
  -- Verificar se usuário já tem trial
  user_has_trial := public.has_used_trial(NEW.user_id);
  
  -- Se já usou trial, bloquear
  IF user_has_trial THEN
    RAISE EXCEPTION 'Usuário já utilizou o teste gratuito. Cada conta pode usar o teste apenas uma vez.';
  END IF;
  
  -- Permitir inserção
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.prevent_multiple_trials IS 
  'Trigger function que previne a criação de múltiplas assinaturas trial para o mesmo usuário.
   Lança exceção se o usuário tentar ativar um segundo teste gratuito.';

-- 7.2 Criar trigger
DROP TRIGGER IF EXISTS prevent_multiple_trials_trigger ON public.user_subscriptions;
CREATE TRIGGER prevent_multiple_trials_trigger
  BEFORE INSERT ON public.user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_multiple_trials();

-- ============================================
-- PARTE 8: INSERIR PLANOS DE ASSINATURA
-- ============================================

-- 8.1 Deletar planos existentes (se houver)
DELETE FROM public.subscription_plans;

-- 8.2 Inserir planos
INSERT INTO public.subscription_plans (id, name, slug, price, duration_days, is_trial, features) VALUES
  (
    '1a375586-9c50-49e7-9f47-6656c401988f',
    'Teste Gratuito',
    'trial',
    0.00,
    30,
    true,
    '["Acesso completo por 30 dias", "Todos os recursos", "Sem cartão de crédito", "Suporte por email"]'::jsonb
  ),
  (
    '7ef25147-395e-4cea-88f8-42d032b74f35',
    'Plano Mensal',
    'monthly',
    29.90,
    30,
    false,
    '["Acesso completo", "Suporte prioritário", "Atualizações gratuitas", "Dashboard completo"]'::jsonb
  ),
  (
    'a8f3c2d1-4b5e-6c7d-8e9f-0a1b2c3d4e5f',
    'Plano Anual',
    'yearly',
    299.90,
    365,
    false,
    '["Acesso completo", "Suporte VIP", "2 meses grátis", "Atualizações gratuitas", "Prioridade em novos recursos"]'::jsonb
  )
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  price = EXCLUDED.price,
  duration_days = EXCLUDED.duration_days,
  is_trial = EXCLUDED.is_trial,
  features = EXCLUDED.features;

-- ============================================
-- PARTE 9: COMENTÁRIOS NAS TABELAS
-- ============================================

COMMENT ON TABLE public.subscription_plans IS 'Planos de assinatura disponíveis';
COMMENT ON TABLE public.user_subscriptions IS 'Assinaturas dos usuários aos planos';
COMMENT ON TABLE public.subscription_payments IS 'Registro de pagamentos de assinaturas';
COMMENT ON COLUMN public.user_subscriptions.subscription_plan_id IS 'Referência ao plano de assinatura';
COMMENT ON COLUMN public.subscription_payments.subscription_plan_id IS 'Referência ao plano de assinatura';

-- ============================================
-- PARTE 10: VERIFICAÇÃO FINAL
-- ============================================

DO $$
DECLARE
  table_count INTEGER;
  function_count INTEGER;
  trigger_count INTEGER;
  plan_count INTEGER;
BEGIN
  -- Contar tabelas
  SELECT COUNT(*) INTO table_count
  FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_name IN ('subscription_plans', 'user_subscriptions', 'subscription_payments');
  
  -- Contar funções
  SELECT COUNT(*) INTO function_count
  FROM pg_proc
  WHERE proname IN ('get_active_subscription', 'has_active_subscription', 'has_used_trial', 'get_available_plans', 'prevent_multiple_trials')
    AND pronamespace = 'public'::regnamespace;
  
  -- Contar triggers
  SELECT COUNT(*) INTO trigger_count
  FROM information_schema.triggers
  WHERE trigger_name = 'prevent_multiple_trials_trigger';
  
  -- Contar planos
  SELECT COUNT(*) INTO plan_count
  FROM public.subscription_plans;
  
  -- Exibir resultados
  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'VERIFICAÇÃO FINAL - SISTEMA DE ASSINATURAS';
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Tabelas criadas: % de 3', table_count;
  RAISE NOTICE '✅ Funções RPC criadas: % de 5', function_count;
  RAISE NOTICE '✅ Triggers criados: % de 1', trigger_count;
  RAISE NOTICE '✅ Planos inseridos: % de 3', plan_count;
  RAISE NOTICE '';
  
  IF table_count = 3 AND function_count = 5 AND trigger_count = 1 AND plan_count = 3 THEN
    RAISE NOTICE '🎉 SUCESSO! Sistema de assinaturas configurado completamente!';
    RAISE NOTICE '';
    RAISE NOTICE 'Próximos passos:';
    RAISE NOTICE '1. Testar no frontend acessando /planos';
    RAISE NOTICE '2. Verificar se planos aparecem corretamente';
    RAISE NOTICE '3. Testar ativação de teste gratuito';
    RAISE NOTICE '';
  ELSE
    RAISE WARNING '⚠️ ATENÇÃO! Alguns componentes podem não ter sido criados.';
    RAISE WARNING 'Verifique os logs acima para detalhes.';
  END IF;
  
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
END;
$$;

-- ============================================
-- QUERIES DE TESTE (OPCIONAL - COMENTADAS)
-- ============================================

-- Para testar após a instalação, descomente as queries abaixo:

-- 1. Ver todos os planos
-- SELECT * FROM subscription_plans ORDER BY price;

-- 2. Ver suas assinaturas
-- SELECT * FROM user_subscriptions WHERE user_id = auth.uid();

-- 3. Verificar se você já usou o trial
-- SELECT public.has_used_trial(auth.uid()) AS "Já usou trial?";

-- 4. Ver planos disponíveis para você
-- SELECT * FROM public.get_available_plans(auth.uid());

-- 5. Ver sua assinatura ativa
-- SELECT * FROM public.get_active_subscription(auth.uid());

-- ============================================
-- FIM DO SETUP
-- ============================================
-- 
-- ✅ Se você viu a mensagem de SUCESSO acima, o sistema está pronto!
-- 
-- 📚 Documentação adicional:
-- - TESTE_GRATUITO_UNICO.md
-- - GUIA_INSTALACAO_TRIAL_UNICO.md
-- - FLUXO_STATUS_ASSINATURA.md
-- 
-- 🐛 Se houver problemas:
-- - Verifique os logs acima
-- - Consulte SOLUCAO_ERRO_PLANOS.md
-- 
-- Data de criação: 19 de outubro de 2025
-- Versão: 2.0
-- ============================================
