# 🚨 INSTRUÇÕES DE CORREÇÃO URGENTE

## ⚠️ EXECUTAR IMEDIATAMENTE

### 1. Corrigir Exposição de Tokens de Pagamento (CRÍTICO)

**Execute este SQL no Supabase SQL Editor AGORA:**

```sql
-- PASSO 1: Remover políticas perigosas
DROP POLICY IF EXISTS "Public can view active store credentials" 
  ON public.merchant_payment_credentials;

DROP POLICY IF EXISTS "Allow public read of active credentials" 
  ON public.merchant_payment_credentials;

-- PASSO 2: Criar política segura
CREATE POLICY "Store owners view own credentials"
  ON public.merchant_payment_credentials
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = merchant_payment_credentials.store_id 
      AND stores.owner_id = (SELECT auth.uid())
    )
  );

-- PASSO 3: Verificar que a política foi aplicada
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'merchant_payment_credentials';
```

**PASSO 4: Rotacionar Tokens**
1. Acesse cada conta do Mercado Pago dos lojistas
2. Revogue os tokens antigos
3. Gere novos tokens
4. Atualize no banco de dados

---

### 2. Mover Credenciais para Variáveis de Ambiente

**Edite `src/integrations/supabase/client.ts`:**

```typescript
import { createClient } from '@supabase/supabase-js';
import type { Database } from './types';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_PUBLISHABLE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_PUBLISHABLE_KEY) {
  throw new Error('Missing required Supabase environment variables');
}

export const supabase = createClient<Database>(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: {
    storage: localStorage,
    persistSession: true,
    autoRefreshToken: true,
  }
});
```

**Crie arquivo `.env.local`:**

```bash
VITE_SUPABASE_URL=https://vnyrvgtioorpyohfvbim.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZueXJ2Z3Rpb29ycHlvaGZ2YmltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAyMDQ4MzIsImV4cCI6MjA3NTc4MDgzMn0.YHTCPvL9pWSsWNq6J8m4BRU_H2ScbNGesJW7KUFmU0g
```

**Adicione ao `.gitignore`:**

```
.env.local
.env
```

---

### 3. Adicionar Validação de Assinatura no Webhook

**Edite `supabase/functions/payment-webhook/index.ts`:**

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { createHmac } from "https://deno.land/std@0.168.0/node/crypto.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-signature, x-request-id',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // VALIDAR ASSINATURA DO MERCADO PAGO
    const signature = req.headers.get('x-signature');
    const requestId = req.headers.get('x-request-id');
    
    if (!signature || !requestId) {
      console.error('Missing signature or request ID');
      return new Response(
        JSON.stringify({ error: 'Unauthorized - Missing signature' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }, 
          status: 401 
        }
      );
    }

    const body = await req.text();
    const webhookSecret = Deno.env.get('MERCADOPAGO_WEBHOOK_SECRET');
    
    if (!webhookSecret) {
      console.error('Webhook secret not configured');
      throw new Error('Server configuration error');
    }

    // Validar assinatura HMAC SHA-256
    const parts = signature.split(',');
    const ts = parts.find(p => p.startsWith('ts='))?.split('=')[1];
    const hash = parts.find(p => p.startsWith('v1='))?.split('=')[1];
    
    if (!ts || !hash) {
      console.error('Invalid signature format');
      return new Response(
        JSON.stringify({ error: 'Invalid signature format' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }, 
          status: 401 
        }
      );
    }

    const manifest = `id:${requestId};request-id:${requestId};ts:${ts};`;
    const expectedSignature = createHmac('sha256', webhookSecret)
      .update(manifest)
      .digest('hex');

    if (hash !== expectedSignature) {
      console.error('Invalid signature - potential attack');
      return new Response(
        JSON.stringify({ error: 'Invalid signature' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }, 
          status: 401 
        }
      );
    }

    console.log('✅ Signature validated successfully');

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { paymentId, status } = JSON.parse(body);

    console.log('Webhook received:', { paymentId, status });

    const { data: payment, error: paymentError } = await supabaseClient
      .from('subscription_payments')
      .select('*, subscription_plans(*)')
      .eq('external_payment_id', paymentId)
      .single();

    if (paymentError || !payment) {
      console.error('Payment not found:', paymentError);
      throw new Error('Pagamento não encontrado');
    }

    console.log('Payment found:', payment.id);

    if (status === 'approved' && payment.status === 'pending') {
      console.log('Approving payment and creating subscription...');
      
      const { error: updateError } = await supabaseClient
        .from('subscription_payments')
        .update({
          status: 'approved',
          paid_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .eq('id', payment.id);

      if (updateError) {
        console.error('Error updating payment:', updateError);
        throw updateError;
      }

      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + payment.subscription_plans.duration_days);

      const { error: subError } = await supabaseClient
        .from('user_subscriptions')
        .insert({
          user_id: payment.user_id,
          subscription_plan_id: payment.subscription_plan_id,
          status: 'active',
          expires_at: expiresAt.toISOString()
        });

      if (subError) {
        console.error('Error creating subscription:', subError);
        throw subError;
      }

      console.log('Subscription activated successfully');
    }

    return new Response(
      JSON.stringify({ success: true }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    );

  } catch (error: any) {
    console.error('Error in payment-webhook:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    );
  }
});
```

**Configure no Supabase Dashboard:**
1. Vá em Edge Functions > Secrets
2. Adicione: `MERCADOPAGO_WEBHOOK_SECRET` com o valor do seu webhook secret do Mercado Pago

---

### 4. Corrigir Funções SECURITY DEFINER

**Execute no Supabase SQL Editor:**

```sql
-- Corrigir get_active_subscription
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
SET search_path = public, pg_temp
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

-- Corrigir has_active_subscription
CREATE OR REPLACE FUNCTION public.has_active_subscription(_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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

-- Corrigir get_user_store_id
CREATE OR REPLACE FUNCTION public.get_user_store_id()
RETURNS UUID 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN (
    SELECT id FROM public.stores 
    WHERE owner_id = auth.uid() 
    AND is_active = true
    LIMIT 1
  );
END;
$$;

-- Corrigir generate_unique_slug
CREATE OR REPLACE FUNCTION public.generate_unique_slug(store_name TEXT)
RETURNS TEXT 
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
BEGIN
  base_slug := lower(regexp_replace(
    unaccent(store_name), 
    '[^a-z0-9]+', 
    '-', 
    'g'
  ));
  
  base_slug := trim(both '-' from base_slug);
  final_slug := base_slug;
  
  WHILE EXISTS (SELECT 1 FROM public.stores WHERE slug = final_slug) LOOP
    counter := counter + 1;
    final_slug := base_slug || '-' || counter;
  END LOOP;
  
  RETURN final_slug;
END;
$$;
```

---

### 5. Habilitar Proteção Contra Senhas Vazadas

**No Supabase Dashboard:**
1. Vá em Authentication > Policies
2. Encontre "Password Requirements"
3. Habilite "Check for leaked passwords (HaveIBeenPwned)"
4. Salve as alterações

---

### 6. Restringir CORS nas Edge Functions

**Edite `supabase/functions/create-pix-payment/index.ts`:**

```typescript
// No início do arquivo
const ALLOWED_ORIGINS = [
  'https://seu-dominio-producao.vercel.app',
  'https://www.seu-dominio.com',
  ...(Deno.env.get('ENVIRONMENT') === 'development' ? ['http://localhost:8080', 'http://localhost:5173'] : [])
];

const getCorsHeaders = (origin: string | null) => {
  const isAllowed = origin && ALLOWED_ORIGINS.includes(origin);
  
  return {
    'Access-Control-Allow-Origin': isAllowed ? origin : ALLOWED_ORIGINS[0],
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Max-Age': '86400',
  };
};

serve(async (req) => {
  const origin = req.headers.get('origin');
  const corsHeaders = getCorsHeaders(origin);
  
  if (req.method === 'OPTIONS') {
    return new Response(JSON.stringify({ success: true }), {
      headers: corsHeaders,
      status: 200
    });
  }
  
  // Resto do código...
});
```

---

## ✅ CHECKLIST DE VERIFICAÇÃO

Após executar as correções, verifique:

- [ ] Política RLS de `merchant_payment_credentials` removida
- [ ] Novos tokens do Mercado Pago gerados e atualizados
- [ ] Credenciais movidas para `.env.local`
- [ ] Arquivo `.env.local` adicionado ao `.gitignore`
- [ ] Validação de assinatura implementada no webhook
- [ ] Secret `MERCADOPAGO_WEBHOOK_SECRET` configurado no Supabase
- [ ] Funções SECURITY DEFINER atualizadas com `search_path`
- [ ] Proteção contra senhas vazadas habilitada
- [ ] CORS restrito nas Edge Functions
- [ ] Teste de criação de pagamento funcionando
- [ ] Teste de webhook funcionando

---

## 🧪 TESTES DE VALIDAÇÃO

### Teste 1: Verificar Política RLS

```sql
-- Como usuário anônimo, não deve retornar nada
SELECT * FROM merchant_payment_credentials;

-- Como usuário autenticado, deve retornar apenas suas credenciais
SELECT * FROM merchant_payment_credentials 
WHERE store_id IN (
  SELECT id FROM stores WHERE owner_id = auth.uid()
);
```

### Teste 2: Testar Webhook

```bash
# Simular webhook do Mercado Pago (deve falhar sem assinatura válida)
curl -X POST https://vnyrvgtioorpyohfvbim.supabase.co/functions/v1/payment-webhook \
  -H "Content-Type: application/json" \
  -d '{"paymentId": "123", "status": "approved"}'

# Resposta esperada: 401 Unauthorized
```

### Teste 3: Verificar Variáveis de Ambiente

```bash
# No terminal do projeto
npm run dev

# Deve iniciar sem erros
# Verificar no console do navegador que não há credenciais expostas
```

---

## 📞 SUPORTE

Se encontrar problemas durante a correção:
1. Verifique os logs do Supabase Dashboard
2. Revise as mensagens de erro no console
3. Consulte a documentação oficial do Supabase

**Importante:** Não faça commit das credenciais no Git!
