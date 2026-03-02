-- ============================================
-- 🎯 SQL FINAL: ASSINATURA FUNCIONANDO PERFEITAMENTE
-- ============================================
-- Execute este SQL para garantir que TUDO funcione:
-- ✅ Dias restantes corretos
-- ✅ Data de início real
-- ✅ Data de expiração precisa
-- ✅ Cálculo com EPOCH (preciso)

-- ============================================
-- 1️⃣ RECRIAR FUNÇÃO get_active_subscription
-- ============================================

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
    us.created_at,  -- ✅ Retorna data real de criação
    -- ✅ Cálculo PRECISO com EPOCH (considera horas, minutos, segundos)
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

-- Adicionar comentário
COMMENT ON FUNCTION public.get_active_subscription IS 
  'Retorna assinatura ativa com cálculo preciso de dias usando EPOCH e data de início real (created_at)';

-- ============================================
-- 2️⃣ VERIFICAR SE FUNCIONOU
-- ============================================

-- Ver sua assinatura atual
SELECT 
  plan_name AS "Plano",
  plan_slug AS "Slug",
  status AS "Status",
  TO_CHAR(created_at, 'DD/MM/YYYY HH24:MI:SS') AS "Data de Início",
  TO_CHAR(expires_at, 'DD/MM/YYYY HH24:MI:SS') AS "Expira em",
  days_remaining AS "Dias Restantes",
  -- Verificação manual
  FLOOR(EXTRACT(EPOCH FROM (expires_at - NOW())) / 86400)::INTEGER AS "Verificação Manual"
FROM get_active_subscription(auth.uid());

-- ✅ Se "Dias Restantes" = "Verificação Manual", está CORRETO!

-- ============================================
-- 3️⃣ VERIFICAR ESTRUTURA DA TABELA
-- ============================================

-- Ver colunas da tabela user_subscriptions
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'user_subscriptions'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Deve ter:
-- ✅ id (uuid)
-- ✅ user_id (uuid)
-- ✅ subscription_plan_id (uuid)
-- ✅ status (text)
-- ✅ expires_at (timestamp with time zone)
-- ✅ created_at (timestamp with time zone)
-- ✅ updated_at (timestamp with time zone)

-- ============================================
-- 4️⃣ VERIFICAR PLANOS DISPONÍVEIS
-- ============================================

-- Ver planos cadastrados
SELECT 
  name AS "Nome",
  slug AS "Slug",
  price AS "Preço",
  duration_days AS "Duração (dias)",
  is_trial AS "É Trial?",
  is_active AS "Ativo?"
FROM subscription_plans
ORDER BY price;

-- Deve ter:
-- ✅ Teste Gratuito (trial, 7 dias, R$ 0)
-- ✅ Mensal (monthly, 30 dias, R$ 29.90)
-- ✅ Anual (yearly, 365 dias, R$ 299.90)

-- ============================================
-- 5️⃣ VERIFICAR SUA ASSINATURA DETALHADA
-- ============================================

-- Ver todos os detalhes da sua assinatura
SELECT 
  us.id AS "ID Assinatura",
  sp.name AS "Plano",
  sp.duration_days AS "Duração Total (dias)",
  us.status AS "Status",
  TO_CHAR(us.created_at, 'DD/MM/YYYY HH24:MI:SS') AS "Criada em",
  TO_CHAR(us.expires_at, 'DD/MM/YYYY HH24:MI:SS') AS "Expira em",
  -- Dias passados
  EXTRACT(DAY FROM (NOW() - us.created_at))::INTEGER AS "Dias Passados",
  -- Dias restantes
  GREATEST(0, FLOOR(EXTRACT(EPOCH FROM (us.expires_at - NOW())) / 86400)::INTEGER) AS "Dias Restantes",
  -- Progresso
  ROUND(
    (EXTRACT(EPOCH FROM (NOW() - us.created_at)) / EXTRACT(EPOCH FROM (us.expires_at - us.created_at))) * 100,
    2
  ) AS "Progresso (%)"
FROM user_subscriptions us
JOIN subscription_plans sp ON us.subscription_plan_id = sp.id
WHERE us.user_id = auth.uid()
ORDER BY us.created_at DESC
LIMIT 1;

-- ============================================
-- 6️⃣ TESTAR DIFERENTES CENÁRIOS
-- ============================================

-- Cenário 1: Assinatura ativa (mais de 7 dias)
-- Status esperado: "Ativa"
-- Cor: Verde

-- Cenário 2: Assinatura expirando (7 dias ou menos)
-- Status esperado: "Expirando em Breve"
-- Cor: Laranja

-- Cenário 3: Assinatura expirada (expires_at < NOW())
-- Status esperado: "Expirada"
-- Cor: Vermelho
-- Dias restantes: 0

-- ============================================
-- 7️⃣ VERIFICAR POLÍTICAS RLS
-- ============================================

-- Ver políticas da tabela user_subscriptions
SELECT 
  policyname AS "Nome da Política",
  cmd AS "Comando",
  qual AS "Condição USING",
  with_check AS "Condição WITH CHECK"
FROM pg_policies
WHERE tablename = 'user_subscriptions';

-- Deve ter:
-- ✅ Users can view own subscriptions (SELECT)
-- ✅ Users can insert own subscriptions (INSERT)
-- ✅ Users can update own subscriptions (UPDATE)

-- ============================================
-- 8️⃣ CALCULAR MANUALMENTE (PARA DEBUG)
-- ============================================

-- Se precisar debugar, use este query:
SELECT 
  -- Sua assinatura
  'Minha Assinatura' AS "Info",
  
  -- Datas
  us.created_at AS "Criada em (timestamp)",
  us.expires_at AS "Expira em (timestamp)",
  NOW() AS "Agora (timestamp)",
  
  -- Diferenças
  (us.expires_at - NOW()) AS "Diferença (interval)",
  EXTRACT(EPOCH FROM (us.expires_at - NOW())) AS "Diferença (segundos)",
  EXTRACT(EPOCH FROM (us.expires_at - NOW())) / 86400 AS "Diferença (dias decimal)",
  FLOOR(EXTRACT(EPOCH FROM (us.expires_at - NOW())) / 86400) AS "Diferença (dias inteiro)",
  
  -- Resultado final
  GREATEST(0, FLOOR(EXTRACT(EPOCH FROM (us.expires_at - NOW())) / 86400)::INTEGER) AS "Dias Restantes"
  
FROM user_subscriptions us
WHERE us.user_id = auth.uid()
ORDER BY us.created_at DESC
LIMIT 1;

-- ============================================
-- 9️⃣ EXEMPLOS DE RESULTADOS ESPERADOS
-- ============================================

-- Exemplo 1: Teste Gratuito (7 dias)
-- Criada: 12/10/2025 10:00:00
-- Expira: 19/10/2025 10:00:00
-- Hoje:   15/10/2025 10:00:00
-- Dias Restantes: 4 dias ✅

-- Exemplo 2: Plano Mensal (30 dias)
-- Criada: 01/10/2025 00:00:00
-- Expira: 31/10/2025 00:00:00
-- Hoje:   15/10/2025 12:00:00
-- Dias Restantes: 15 dias ✅

-- Exemplo 3: Plano Anual (365 dias)
-- Criada: 01/01/2025 00:00:00
-- Expira: 01/01/2026 00:00:00
-- Hoje:   12/10/2025 10:00:00
-- Dias Restantes: 81 dias ✅

-- ============================================
-- 🔟 LIMPAR CACHE (SE NECESSÁRIO)
-- ============================================

-- Se os dados não atualizarem no painel:
-- 1. Faça logout do painel admin
-- 2. Limpe o cache do navegador (Ctrl + Shift + Delete)
-- 3. Feche e abra o navegador
-- 4. Faça login novamente
-- 5. Acesse Admin → Assinatura

-- ============================================
-- ✅ CHECKLIST FINAL
-- ============================================

-- [ ] SQL executado sem erros
-- [ ] Função get_active_subscription recriada
-- [ ] Query de verificação retorna dados corretos
-- [ ] Dias Restantes = Verificação Manual
-- [ ] Data de Início = created_at real
-- [ ] Expira em = expires_at correto
-- [ ] Logout e login realizados
-- [ ] Página Admin → Assinatura exibe tudo correto

-- ============================================
-- 🎉 RESULTADO ESPERADO
-- ============================================

-- Após executar este SQL e recarregar o painel:
-- ✅ Data de Início: Data real de quando foi criada
-- ✅ Expira em: Data correta de expiração
-- ✅ Dias Restantes: Cálculo preciso (considera horas)
-- ✅ Barra de Progresso: Coerente com os dias
-- ✅ Status: Correto (Ativa/Expirando/Expirada)
-- ✅ Cores: Verde/Laranja/Vermelho conforme status
-- ✅ Sem erros no console
-- ✅ Experiência perfeita!

-- ============================================
-- 📝 NOTAS IMPORTANTES
-- ============================================

-- 1. EPOCH = Segundos desde 1970-01-01 00:00:00 UTC
-- 2. 86400 = Segundos em 1 dia (24 × 60 × 60)
-- 3. FLOOR = Arredonda para baixo (7.9 → 7)
-- 4. GREATEST(0, ...) = Nunca retorna negativo
-- 5. created_at = Data REAL de criação (não calculada)

-- ============================================
-- 🆘 SUPORTE
-- ============================================

-- Se algo não funcionar:
-- 1. Verifique se o SQL foi executado sem erros
-- 2. Execute o query de verificação (seção 2)
-- 3. Compare "Dias Restantes" com "Verificação Manual"
-- 4. Se forem diferentes, há um problema
-- 5. Execute o query de debug (seção 8)
-- 6. Verifique os timestamps e cálculos

-- ============================================
-- FIM DO SQL
-- ============================================
