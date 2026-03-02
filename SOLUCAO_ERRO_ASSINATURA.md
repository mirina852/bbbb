# 🔧 Solução: Erro ao Assinar Plano

## 🎯 Problema
"Pode ocorrer algum erro ao tentar assinar um plano para ativar o painel e utilizá-lo novamente."

---

## 🔍 Possíveis Causas

### **1. Tabelas de assinatura não existem**
As tabelas `subscription_plans` e `user_subscriptions` podem não ter sido criadas no banco.

### **2. Não há planos cadastrados**
Mesmo que as tabelas existam, pode não haver planos disponíveis para assinar.

### **3. Funções RPC não existem**
As funções `get_active_subscription` e `has_active_subscription` podem não estar criadas.

### **4. Erro no fluxo de pagamento**
O sistema de pagamento PIX pode estar com problemas de configuração.

---

## ✅ Solução Completa (Passo a Passo)

### **Passo 1: Verificar se as tabelas existem**

Execute no **Supabase SQL Editor**:

```sql
-- Verificar se tabelas de assinatura existem
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('subscription_plans', 'user_subscriptions', 'subscription_payments');
```

**Resultado esperado:**
```
subscription_plans
user_subscriptions
subscription_payments
```

**Se retornar vazio:** Execute o **Passo 2**

---

### **Passo 2: Criar tabelas de assinatura**

Execute a migration completa no **Supabase SQL Editor**:

**Arquivo:** `supabase/migrations/20251010193700_create_subscription_tables.sql`

Ou execute este SQL resumido:

```sql
-- 1. Criar tabela de planos
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

-- 2. Criar tabela de assinaturas de usuários
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subscription_plan_id UUID NOT NULL REFERENCES public.subscription_plans(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- 3. Criar índices
CREATE INDEX IF NOT EXISTS user_subscriptions_user_id_idx ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS user_subscriptions_status_idx ON public.user_subscriptions(status);

-- 4. Habilitar RLS
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

-- 5. Criar políticas
CREATE POLICY "Anyone can view subscription plans"
  ON public.subscription_plans FOR SELECT
  USING (is_active = true);

CREATE POLICY "Users can view own subscriptions"
  ON public.user_subscriptions FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscriptions"
  ON public.user_subscriptions FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
```

---

### **Passo 3: Criar planos de assinatura**

Execute no **Supabase SQL Editor**:

```sql
-- Inserir planos de assinatura
INSERT INTO subscription_plans (name, slug, price, duration_days, is_trial, features) VALUES
  ('Teste Gratuito', 'trial', 0, 7, true, 
   '["Loja online completa", "Gestão de pedidos", "Dashboard", "Suporte por email"]'::jsonb),
  
  ('Plano Mensal', 'monthly', 29.90, 30, false,
   '["Todos os recursos do teste", "Pedidos ilimitados", "Produtos ilimitados", "Suporte prioritário"]'::jsonb),
  
  ('Plano Anual', 'yearly', 299.90, 365, false,
   '["Todos os recursos do mensal", "2 meses grátis", "Suporte VIP", "Prioridade em novos recursos"]'::jsonb)
ON CONFLICT (slug) DO NOTHING;

-- Verificar se foram criados
SELECT id, name, slug, price, duration_days FROM subscription_plans ORDER BY price;
```

---

### **Passo 4: Criar funções RPC**

Execute no **Supabase SQL Editor**:

```sql
-- Função para buscar assinatura ativa
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

-- Função para verificar se tem assinatura ativa
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
```

---

### **Passo 5: Criar assinatura de teste para você**

Execute no **Supabase SQL Editor**:

```sql
-- 1. Buscar seu user_id
SELECT id, email FROM auth.users ORDER BY created_at DESC LIMIT 5;

-- 2. Criar assinatura de teste (SUBSTITUA USER_ID_AQUI)
INSERT INTO user_subscriptions (
  user_id,
  subscription_plan_id,
  status,
  expires_at
)
SELECT 
  'USER_ID_AQUI'::uuid,  -- ← SUBSTITUA pelo seu user_id
  id,
  'active',
  NOW() + INTERVAL '7 days'
FROM subscription_plans 
WHERE slug = 'trial'
LIMIT 1;

-- 3. Verificar se foi criada
SELECT 
  us.id,
  us.status,
  us.expires_at,
  sp.name as plan_name,
  EXTRACT(DAY FROM (us.expires_at - NOW()))::INTEGER as dias_restantes
FROM user_subscriptions us
JOIN subscription_plans sp ON sp.id = us.subscription_plan_id
WHERE us.user_id = 'USER_ID_AQUI'::uuid  -- ← SUBSTITUA pelo seu user_id
ORDER BY us.created_at DESC
LIMIT 1;
```

---

## 🧪 Script de Verificação Completo

Execute este script para verificar tudo de uma vez:

```sql
-- ============================================
-- SCRIPT DE VERIFICAÇÃO COMPLETA
-- ============================================

-- 1. Verificar se tabelas existem
SELECT 
  '📋 Tabelas de Assinatura:' as info,
  table_name,
  CASE 
    WHEN table_name IS NOT NULL THEN '✅ Existe'
    ELSE '❌ Não existe'
  END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('subscription_plans', 'user_subscriptions', 'subscription_payments');

-- 2. Verificar se há planos cadastrados
SELECT 
  '💳 Planos Disponíveis:' as info,
  COUNT(*) as total_planos,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Tem planos'
    ELSE '❌ Sem planos'
  END as status
FROM subscription_plans;

-- 3. Listar planos
SELECT 
  '📊 Detalhes dos Planos:' as info,
  name,
  slug,
  price,
  duration_days,
  is_trial
FROM subscription_plans
ORDER BY price;

-- 4. Verificar funções RPC
SELECT 
  '🔧 Funções RPC:' as info,
  routine_name,
  '✅ Existe' as status
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('get_active_subscription', 'has_active_subscription');

-- 5. Verificar sua assinatura
SELECT 
  '👤 Sua Assinatura:' as info,
  us.status,
  sp.name as plan_name,
  us.expires_at,
  EXTRACT(DAY FROM (us.expires_at - NOW()))::INTEGER as dias_restantes,
  CASE 
    WHEN us.expires_at > NOW() AND us.status = 'active' THEN '✅ Ativa'
    ELSE '❌ Inativa/Expirada'
  END as status_atual
FROM user_subscriptions us
JOIN subscription_plans sp ON sp.id = us.subscription_plan_id
WHERE us.user_id = auth.uid()
ORDER BY us.created_at DESC
LIMIT 1;

-- 6. Testar função get_active_subscription
SELECT 
  '🧪 Teste da Função:' as info,
  *
FROM get_active_subscription(auth.uid());
```

---

## 🎯 Solução Rápida (Copiar e Colar)

Se quiser resolver tudo de uma vez, execute este SQL completo:

```sql
-- ============================================
-- SOLUÇÃO COMPLETA - EXECUTE TUDO DE UMA VEZ
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

-- 5. Inserir planos
INSERT INTO subscription_plans (name, slug, price, duration_days, is_trial, features) VALUES
  ('Teste Gratuito', 'trial', 0, 7, true, 
   '["Loja online completa", "Gestão de pedidos", "Dashboard", "Suporte"]'::jsonb),
  ('Plano Mensal', 'monthly', 29.90, 30, false,
   '["Todos os recursos", "Pedidos ilimitados", "Suporte prioritário"]'::jsonb),
  ('Plano Anual', 'yearly', 299.90, 365, false,
   '["Todos os recursos", "2 meses grátis", "Suporte VIP"]'::jsonb)
ON CONFLICT (slug) DO NOTHING;

-- 6. Criar funções RPC
CREATE OR REPLACE FUNCTION get_active_subscription(_user_id UUID)
RETURNS TABLE (
  id UUID, plan_name TEXT, plan_slug TEXT, status TEXT,
  expires_at TIMESTAMP WITH TIME ZONE, created_at TIMESTAMP WITH TIME ZONE,
  days_remaining INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    us.id, sp.name, sp.slug, us.status, us.expires_at, us.created_at,
    GREATEST(0, EXTRACT(DAY FROM (us.expires_at - NOW()))::INTEGER)
  FROM user_subscriptions us
  JOIN subscription_plans sp ON sp.id = us.subscription_plan_id
  WHERE us.user_id = _user_id AND us.status = 'active' AND us.expires_at > NOW()
  ORDER BY us.created_at DESC LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION has_active_subscription(_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_subscriptions 
    WHERE user_id = _user_id AND status = 'active' AND expires_at > NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Criar assinatura de teste para você
INSERT INTO user_subscriptions (user_id, subscription_plan_id, status, expires_at)
SELECT 
  auth.uid(), id, 'active', NOW() + INTERVAL '7 days'
FROM subscription_plans 
WHERE slug = 'trial'
LIMIT 1
ON CONFLICT DO NOTHING;

-- 8. Verificar resultado
SELECT 
  '✅ TUDO PRONTO!' as status,
  sp.name as plano,
  us.expires_at as expira_em,
  EXTRACT(DAY FROM (us.expires_at - NOW()))::INTEGER as dias_restantes
FROM user_subscriptions us
JOIN subscription_plans sp ON sp.id = us.subscription_plan_id
WHERE us.user_id = auth.uid()
ORDER BY us.created_at DESC
LIMIT 1;
```

---

## ✅ Checklist de Verificação

Depois de executar os scripts, verifique:

- [ ] Tabelas `subscription_plans` e `user_subscriptions` existem
- [ ] Há pelo menos 3 planos cadastrados (trial, monthly, yearly)
- [ ] Funções `get_active_subscription` e `has_active_subscription` existem
- [ ] Você tem uma assinatura ativa no banco
- [ ] A página `/admin/subscription` mostra sua assinatura
- [ ] Você consegue acessar `/admin`, `/admin/products`, etc.

---

## 🆘 Troubleshooting

### **Erro: "Função get_active_subscription não existe"**
**Solução:** Execute o Passo 4 (criar funções RPC)

### **Erro: "Tabela subscription_plans não existe"**
**Solução:** Execute o Passo 2 (criar tabelas)

### **Erro: "Não há planos disponíveis"**
**Solução:** Execute o Passo 3 (inserir planos)

### **Ainda redireciona para /admin/subscription**
**Solução:** 
1. Verifique se você tem assinatura ativa no banco
2. Faça logout e login novamente
3. Limpe o cache do navegador (Ctrl + Shift + R)

### **Erro ao tentar assinar um plano**
**Solução:**
1. Verifique se as tabelas existem
2. Verifique se há planos cadastrados
3. Verifique o console do navegador (F12) para ver o erro específico
4. Use a "Solução Rápida" acima para criar assinatura manual

---

## 📝 Resumo

**Problema:** Erro ao tentar assinar plano

**Causas possíveis:**
1. Tabelas não existem
2. Planos não cadastrados
3. Funções RPC não criadas
4. Erro no fluxo de pagamento

**Solução:**
1. Execute o "Script de Solução Completa" acima
2. Verifique com o "Script de Verificação"
3. Faça logout e login
4. Teste acessar `/admin`

**Resultado esperado:**
✅ Você terá uma assinatura de teste de 7 dias
✅ Poderá acessar todas as páginas do admin
✅ Não será mais redirecionado para `/admin/subscription`
