-- ============================================
-- INSERIR PLANO GRATUITO
-- ============================================

-- Verificar qual tabela existe
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscription_plans') THEN
    RAISE NOTICE '✅ Tabela subscription_plans existe';
    
    -- Inserir plano gratuito
    INSERT INTO public.subscription_plans (
      id,
      name,
      slug,
      price,
      duration_days,
      is_trial,
      features
    ) VALUES (
      '1a375586-9c50-49e7-9f47-6656c401988f',
      'Teste Gratuito',
      'free-trial',
      0.00,
      7,
      true,
      ARRAY['Acesso completo por 7 dias', 'Gestão de produtos e pedidos', 'Dashboard com estatísticas', 'Sem compromisso']
    )
    ON CONFLICT (id) DO UPDATE SET
      name = EXCLUDED.name,
      price = EXCLUDED.price,
      duration_days = EXCLUDED.duration_days,
      is_trial = EXCLUDED.is_trial,
      features = EXCLUDED.features;
    
    RAISE NOTICE '✅ Plano gratuito inserido/atualizado';
  ELSE
    RAISE WARNING '❌ Tabela subscription_plans NÃO existe';
  END IF;
END $$;

-- Verificar se foi inserido
SELECT 
  id,
  name,
  price,
  duration_days,
  is_trial,
  features
FROM public.subscription_plans
WHERE id = '1a375586-9c50-49e7-9f47-6656c401988f';

-- ============================================
-- VERIFICAR ESTRUTURA DA TABELA
-- ============================================
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'subscription_plans'
ORDER BY ordinal_position;
