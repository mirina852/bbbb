# 🔍 Erros Comuns no Sistema de Assinaturas

## 📋 Checklist de Verificação

Execute o arquivo `SQL_DIAGNOSTICO_ASSINATURA.sql` no Supabase para identificar automaticamente os problemas.

---

## ❌ Erro 1: "Tabela subscription_plans não existe"

### **Sintomas:**
- Erro no console: `relation "subscription_plans" does not exist`
- Página de planos não carrega
- Erro ao tentar assinar

### **Causa:**
As tabelas de assinatura não foram criadas no banco de dados.

### **Solução:**
Execute no Supabase SQL Editor:

```sql
-- Criar tabelas
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  duration_days INTEGER NOT NULL,
  is_trial BOOLEAN NOT NULL DEFAULT false,
  features JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subscription_plan_id UUID NOT NULL REFERENCES public.subscription_plans(id),
  status TEXT NOT NULL DEFAULT 'active',
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

---

## ❌ Erro 2: "Não há planos disponíveis"

### **Sintomas:**
- Página de planos aparece vazia
- Mensagem: "Não foi possível carregar os planos"
- Array vazio ao buscar planos

### **Causa:**
Nenhum plano foi cadastrado no banco de dados.

### **Solução:**
Execute no Supabase SQL Editor:

```sql
INSERT INTO subscription_plans (name, slug, price, duration_days, is_trial, features) VALUES
  ('Teste Gratuito', 'trial', 0, 7, true, 
   '["Loja online completa", "Gestão de pedidos", "Dashboard", "Suporte"]'::jsonb),
  ('Plano Mensal', 'monthly', 29.90, 30, false,
   '["Todos os recursos", "Pedidos ilimitados", "Suporte prioritário"]'::jsonb),
  ('Plano Anual', 'yearly', 299.90, 365, false,
   '["Todos os recursos", "2 meses grátis", "Suporte VIP"]'::jsonb)
ON CONFLICT (slug) DO NOTHING;
```

---

## ❌ Erro 3: "Função get_active_subscription não existe"

### **Sintomas:**
- Erro no console: `function get_active_subscription(uuid) does not exist`
- Página de assinatura não carrega status
- Sistema não reconhece assinatura ativa

### **Causa:**
As funções RPC não foram criadas.

### **Solução:**
Execute no Supabase SQL Editor:

```sql
CREATE OR REPLACE FUNCTION get_active_subscription(_user_id UUID)
RETURNS TABLE (
  id UUID, plan_name TEXT, plan_slug TEXT, status TEXT,
  expires_at TIMESTAMP WITH TIME ZONE, created_at TIMESTAMP WITH TIME ZONE,
  days_remaining INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT us.id, sp.name, sp.slug, us.status, us.expires_at, us.created_at,
    GREATEST(0, EXTRACT(DAY FROM (us.expires_at - NOW()))::INTEGER)
  FROM user_subscriptions us
  JOIN subscription_plans sp ON sp.id = us.subscription_plan_id
  WHERE us.user_id = _user_id AND us.status = 'active' AND expires_at > NOW()
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
```

---

## ❌ Erro 4: "Você não tem assinatura ativa"

### **Sintomas:**
- Redirecionado para `/admin/subscription`
- Não consegue acessar dashboard
- Mensagem: "Assinatura Necessária"

### **Causa:**
Você não tem nenhuma assinatura cadastrada no banco.

### **Solução:**
Execute no Supabase SQL Editor:

```sql
-- Criar assinatura de teste (7 dias grátis)
INSERT INTO user_subscriptions (user_id, subscription_plan_id, status, expires_at)
SELECT auth.uid(), id, 'active', NOW() + INTERVAL '7 days'
FROM subscription_plans WHERE slug = 'trial' LIMIT 1;

-- Verificar
SELECT * FROM user_subscriptions WHERE user_id = auth.uid();
```

---

## ❌ Erro 5: "Assinatura expirada"

### **Sintomas:**
- Página mostra "Expirada"
- Dias restantes = 0
- Não consegue acessar funcionalidades

### **Causa:**
A data de expiração (`expires_at`) já passou.

### **Solução:**
Execute no Supabase SQL Editor:

```sql
-- Renovar assinatura (adicionar 30 dias)
UPDATE user_subscriptions
SET expires_at = NOW() + INTERVAL '30 days',
    status = 'active'
WHERE user_id = auth.uid()
  AND id = (SELECT id FROM user_subscriptions WHERE user_id = auth.uid() ORDER BY created_at DESC LIMIT 1);

-- Verificar
SELECT 
  status,
  expires_at,
  EXTRACT(DAY FROM (expires_at - NOW()))::INTEGER as dias_restantes
FROM user_subscriptions 
WHERE user_id = auth.uid()
ORDER BY created_at DESC LIMIT 1;
```

---

## ❌ Erro 6: "Erro ao criar pagamento"

### **Sintomas:**
- Erro ao clicar em "Assinar"
- Console mostra erro de Edge Function
- Mensagem: "Não foi possível processar o pagamento"

### **Causa:**
Edge Function de pagamento não está configurada ou há erro nas credenciais do Mercado Pago.

### **Solução Temporária (Teste):**
Ative o plano gratuito manualmente:

```sql
-- Criar assinatura de teste sem pagamento
INSERT INTO user_subscriptions (user_id, subscription_plan_id, status, expires_at)
SELECT auth.uid(), id, 'active', NOW() + INTERVAL '7 days'
FROM subscription_plans WHERE slug = 'trial' LIMIT 1;
```

### **Solução Definitiva:**
1. Configure as credenciais do Mercado Pago
2. Verifique se a Edge Function está deployada
3. Teste o fluxo de pagamento

---

## ❌ Erro 7: "RLS Policy bloqueando acesso"

### **Sintomas:**
- Erro: "new row violates row-level security policy"
- Não consegue criar assinatura
- Tabelas retornam vazio mesmo tendo dados

### **Causa:**
Políticas RLS (Row Level Security) estão bloqueando o acesso.

### **Solução:**
Execute no Supabase SQL Editor:

```sql
-- Recriar políticas
DROP POLICY IF EXISTS "Users can view own subscriptions" ON user_subscriptions;
DROP POLICY IF EXISTS "Users can insert own subscriptions" ON user_subscriptions;

CREATE POLICY "Users can view own subscriptions"
  ON user_subscriptions FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscriptions"
  ON user_subscriptions FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
```

---

## ❌ Erro 8: "Plano não aparece na lista"

### **Sintomas:**
- Alguns planos não aparecem
- Lista de planos incompleta

### **Causa:**
Plano está marcado como `is_active = false`.

### **Solução:**
Execute no Supabase SQL Editor:

```sql
-- Ativar todos os planos
UPDATE subscription_plans SET is_active = true;

-- Verificar
SELECT id, name, slug, is_active FROM subscription_plans;
```

---

## ❌ Erro 9: "Dias restantes incorretos"

### **Sintomas:**
- Dias restantes mostra valor negativo
- Cálculo de dias está errado

### **Causa:**
Problema no cálculo da função `get_active_subscription`.

### **Solução:**
Execute no Supabase SQL Editor:

```sql
-- Recriar função com cálculo correto
CREATE OR REPLACE FUNCTION get_active_subscription(_user_id UUID)
RETURNS TABLE (
  id UUID, plan_name TEXT, plan_slug TEXT, status TEXT,
  expires_at TIMESTAMP WITH TIME ZONE, created_at TIMESTAMP WITH TIME ZONE,
  days_remaining INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT us.id, sp.name, sp.slug, us.status, us.expires_at, us.created_at,
    GREATEST(0, EXTRACT(DAY FROM (us.expires_at - NOW()))::INTEGER) -- GREATEST garante mínimo 0
  FROM user_subscriptions us
  JOIN subscription_plans sp ON sp.id = us.subscription_plan_id
  WHERE us.user_id = _user_id AND us.status = 'active' AND us.expires_at > NOW()
  ORDER BY us.created_at DESC LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## ❌ Erro 10: "Múltiplas assinaturas ativas"

### **Sintomas:**
- Usuário tem mais de uma assinatura ativa
- Comportamento inconsistente

### **Causa:**
Foram criadas múltiplas assinaturas sem cancelar as antigas.

### **Solução:**
Execute no Supabase SQL Editor:

```sql
-- Cancelar assinaturas antigas, manter apenas a mais recente
UPDATE user_subscriptions
SET status = 'cancelled'
WHERE user_id = auth.uid()
  AND id NOT IN (
    SELECT id FROM user_subscriptions 
    WHERE user_id = auth.uid() 
    ORDER BY created_at DESC LIMIT 1
  );

-- Verificar
SELECT id, status, created_at, expires_at 
FROM user_subscriptions 
WHERE user_id = auth.uid()
ORDER BY created_at DESC;
```

---

## 🔧 Script de Diagnóstico Automático

Execute o arquivo `SQL_DIAGNOSTICO_ASSINATURA.sql` para:
- ✅ Verificar se tabelas existem
- ✅ Verificar se planos estão cadastrados
- ✅ Verificar se funções RPC existem
- ✅ Verificar sua assinatura atual
- ✅ Identificar problemas automaticamente
- ✅ Sugerir ações corretivas

---

## 📊 Resumo de Soluções Rápidas

| Erro | Solução Rápida |
|------|----------------|
| Tabelas não existem | Execute `SQL_ATIVAR_ASSINATURA_TESTE.sql` |
| Planos não cadastrados | Execute seção 5 do script |
| Funções não existem | Execute seção 6 do script |
| Sem assinatura | Execute seção 7 do script |
| Assinatura expirada | UPDATE expires_at |
| Erro de pagamento | Ative plano gratuito manualmente |
| RLS bloqueando | Recrie políticas |
| Plano inativo | UPDATE is_active = true |
| Dias incorretos | Recrie função |
| Múltiplas assinaturas | Cancele as antigas |

---

## ✅ Checklist Final

Depois de resolver os erros:

- [ ] Tabelas `subscription_plans` e `user_subscriptions` existem
- [ ] Há pelo menos 1 plano cadastrado
- [ ] Funções `get_active_subscription` e `has_active_subscription` existem
- [ ] Você tem uma assinatura com `status = 'active'`
- [ ] A data `expires_at` está no futuro
- [ ] Dias restantes > 0
- [ ] Consegue acessar `/admin` sem redirecionamento
- [ ] Página `/admin/subscription` mostra sua assinatura

---

## 🆘 Ainda com Problemas?

1. **Execute o diagnóstico:** `SQL_DIAGNOSTICO_ASSINATURA.sql`
2. **Copie o resultado** da seção "POSSÍVEIS PROBLEMAS DETECTADOS"
3. **Siga a ação recomendada** na seção "AÇÕES RECOMENDADAS"
4. **Faça logout e login** após aplicar correções
5. **Limpe o cache** do navegador (Ctrl + Shift + R)

Se ainda não funcionar, verifique o console do navegador (F12) e me envie o erro específico.
