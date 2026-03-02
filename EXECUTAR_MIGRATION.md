# 🗄️ Como Executar a Migration de Assinaturas

## ⚠️ Problema

Erro: **"Não foi possível encontrar a coluna 'plan_id' de 'user_subscriptions'"**

**Causa:** As tabelas de assinatura não existem ou estão com estrutura incorreta.

---

## ✅ Solução: Executar Migration

### Opção 1: Via Dashboard do Supabase (Recomendado)

1. **Acesse:** https://supabase.com/dashboard
2. **Vá em:** Seu projeto → SQL Editor
3. **Clique em:** "New Query"
4. **Cole o SQL abaixo**
5. **Clique em:** "Run" ou pressione Ctrl+Enter

### Opção 2: Via Arquivo Local

Se você tiver acesso ao SQL Editor local:

1. Abra o arquivo: `supabase/migrations/20251010193700_create_subscription_tables.sql`
2. Copie todo o conteúdo
3. Execute no SQL Editor do Supabase

---

## 📄 SQL para Executar

```sql
-- Create subscription_plans table
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

-- Create user_subscriptions table
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subscription_plan_id UUID NOT NULL REFERENCES public.subscription_plans(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create subscription_payments table
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

-- Create indexes
CREATE INDEX IF NOT EXISTS user_subscriptions_user_id_idx ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS user_subscriptions_status_idx ON public.user_subscriptions(status);
CREATE INDEX IF NOT EXISTS subscription_payments_user_id_idx ON public.subscription_payments(user_id);
CREATE INDEX IF NOT EXISTS subscription_payments_status_idx ON public.subscription_payments(status);
CREATE INDEX IF NOT EXISTS subscription_payments_payment_id_idx ON public.subscription_payments(payment_id);
CREATE INDEX IF NOT EXISTS subscription_payments_external_payment_id_idx ON public.subscription_payments(external_payment_id);

-- Enable RLS
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;

-- Policies for subscription_plans (everyone can view)
CREATE POLICY "Anyone can view subscription plans"
  ON public.subscription_plans
  FOR SELECT
  USING (is_active = true);

-- Policies for user_subscriptions
CREATE POLICY "Users can view own subscriptions"
  ON public.user_subscriptions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscriptions"
  ON public.user_subscriptions
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscriptions"
  ON public.user_subscriptions
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

-- Policies for subscription_payments
CREATE POLICY "Users can view own payments"
  ON public.subscription_payments
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own payments"
  ON public.subscription_payments
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_subscription_plans_updated_at
  BEFORE UPDATE ON public.subscription_plans
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_subscriptions_updated_at
  BEFORE UPDATE ON public.user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_subscription_payments_updated_at
  BEFORE UPDATE ON public.subscription_payments
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Create function to get active subscription
CREATE OR REPLACE FUNCTION public.get_active_subscription(_user_id UUID)
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
    GREATEST(0, EXTRACT(DAY FROM (us.expires_at - NOW()))::INTEGER) AS days_remaining
  FROM public.user_subscriptions us
  JOIN public.subscription_plans sp ON us.subscription_plan_id = sp.id
  WHERE us.user_id = _user_id
  ORDER BY us.created_at DESC
  LIMIT 1;
END;
$$;

-- Create function to check if user has active subscription
CREATE OR REPLACE FUNCTION public.has_active_subscription(_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  has_subscription BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 
    FROM public.user_subscriptions 
    WHERE user_id = _user_id 
    AND status = 'active' 
    AND expires_at > NOW()
  ) INTO has_subscription;
  
  RETURN has_subscription;
END;
$$;

-- Insert default subscription plans
INSERT INTO public.subscription_plans (name, slug, price, duration_days, is_trial, features) VALUES
('Teste Gratuito', 'trial', 0, 7, true, '["Acesso completo por 7 dias", "Gestão de produtos", "Dashboard básico", "Sem cartão de crédito"]'::jsonb),
('Mensal', 'monthly', 29.90, 30, false, '["Acesso completo", "Gestão de produtos e pedidos", "Dashboard com estatísticas", "Suporte prioritário"]'::jsonb),
('Anual', 'yearly', 299.90, 365, false, '["Acesso completo", "Gestão de produtos e pedidos", "Dashboard com estatísticas", "Suporte VIP exclusivo", "Desconto de 16%"]'::jsonb)
ON CONFLICT (slug) DO NOTHING;
```

---

## 🧪 Verificar se Funcionou

Após executar o SQL, verifique:

### 1. Tabelas Criadas

Execute este SQL para confirmar:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%subscription%';
```

**Resultado esperado:**
- subscription_plans
- user_subscriptions
- subscription_payments

### 2. Planos Cadastrados

```sql
SELECT * FROM public.subscription_plans;
```

**Resultado esperado:** 3 planos (Trial, Mensal, Anual)

### 3. Estrutura da Tabela

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'user_subscriptions';
```

**Colunas esperadas:**
- id
- user_id
- subscription_plan_id ✅ (não plan_id)
- status
- expires_at
- created_at
- updated_at

---

## 🎯 Testar Novamente

Após executar a migration:

1. **Recarregue** a página de planos
2. **Clique** em "Iniciar Teste Gratuito"
3. **Verifique:**
   - ✅ Não deve mais dar erro de coluna
   - ✅ Assinatura deve ser criada
   - ✅ Redireciona para /admin

---

## ❓ Ainda com Erro?

### Erro: "relation 'subscription_plans' already exists"

**Solução:** A tabela já existe, mas pode estar com estrutura diferente.

Execute:
```sql
-- Ver estrutura atual
\d public.user_subscriptions

-- Se necessário, adicionar coluna
ALTER TABLE public.user_subscriptions 
ADD COLUMN IF NOT EXISTS subscription_plan_id UUID 
REFERENCES public.subscription_plans(id);

-- Remover coluna antiga se existir
ALTER TABLE public.user_subscriptions 
DROP COLUMN IF EXISTS plan_id;
```

### Erro: "function update_updated_at_column() does not exist"

**Solução:** Criar a função primeiro:

```sql
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## 📝 Checklist

- [ ] Acessei o SQL Editor do Supabase
- [ ] Executei o SQL completo
- [ ] Verifiquei que as 3 tabelas foram criadas
- [ ] Confirmei que os 3 planos foram inseridos
- [ ] Testei criar assinatura gratuita
- [ ] Funcionou sem erros

---

## 🎉 Pronto!

Agora as tabelas estão criadas corretamente e o sistema de assinaturas deve funcionar!
