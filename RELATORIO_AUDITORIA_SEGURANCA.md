# 🔒 RELATÓRIO DE AUDITORIA DE SEGURANÇA E CONFIABILIDADE

**Data:** 12 de outubro de 2025  
**Projeto:** Petisco SaaS - Sistema Multi-Tenant de Delivery  
**Instância Supabase:** vnyrvgtioorpyohfvbim  
**Status:** ACTIVE_HEALTHY

---

## 📊 RESUMO EXECUTIVO

### Severidade dos Achados
- 🔴 **CRÍTICO:** 3 vulnerabilidades
- 🟠 **ALTO:** 5 vulnerabilidades  
- 🟡 **MÉDIO:** 8 problemas
- 🔵 **BAIXO:** 6 melhorias

### Score de Segurança: 62/100 ⚠️

---

## 🔴 VULNERABILIDADES CRÍTICAS

### 1. Credenciais Hardcoded no Código-Fonte
**Arquivo:** `src/integrations/supabase/client.ts` (linhas 5-6)

**Problema:** URL e chave anônima do Supabase expostas no código.

**Correção:**
```typescript
const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_PUBLISHABLE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_PUBLISHABLE_KEY) {
  throw new Error('Missing Supabase environment variables');
}
```

---

### 2. Tokens de Pagamento Expostos Publicamente
**Tabela:** `merchant_payment_credentials`

**Problema:** Política RLS permite leitura pública de tokens do Mercado Pago.

**Correção URGENTE:**
```sql
DROP POLICY IF EXISTS "Public can view active store credentials" 
  ON public.merchant_payment_credentials;

CREATE POLICY "Store owners view own credentials"
  ON public.merchant_payment_credentials
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.stores 
      WHERE stores.id = merchant_payment_credentials.store_id 
      AND stores.owner_id = (SELECT auth.uid())
    )
  );
```

**Ação Adicional:** Rotacionar TODOS os tokens do Mercado Pago imediatamente.

---

### 3. Webhook Sem Validação de Assinatura
**Arquivo:** `supabase/functions/payment-webhook/index.ts`

**Problema:** Webhook aceita requisições sem validar assinatura do Mercado Pago.

**Correção:**
```typescript
const signature = req.headers.get('x-signature');
const requestId = req.headers.get('x-request-id');

if (!signature || !requestId) {
  return new Response(
    JSON.stringify({ error: 'Unauthorized' }),
    { status: 401, headers: corsHeaders }
  );
}

const webhookSecret = Deno.env.get('MERCADOPAGO_WEBHOOK_SECRET');
const expectedSignature = createHmac('sha256', webhookSecret)
  .update(requestId + body)
  .digest('hex');

if (signature !== expectedSignature) {
  return new Response(
    JSON.stringify({ error: 'Invalid signature' }),
    { status: 401, headers: corsHeaders }
  );
}
```

---

## 🟠 VULNERABILIDADES ALTAS

### 4. Controle de Acesso Inadequado
**Arquivo:** `src/contexts/AuthContext.tsx` (linha 120)

**Problema:** `const isAdmin = !!user;` - Todos usuários autenticados são admin.

**Correção:**
```sql
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  role TEXT CHECK (role IN ('admin', 'store_owner', 'customer')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 5. SQL Injection via Search Path Mutable
**Funções:** `get_active_subscription`, `has_active_subscription`

**Correção:**
```sql
CREATE OR REPLACE FUNCTION public.get_active_subscription(_user_id UUID)
RETURNS TABLE (...) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp  -- FIX
AS $$ ... $$;
```

---

### 6. Extensão em Schema Público
**Extensão:** `unaccent`

**Correção:**
```sql
CREATE SCHEMA IF NOT EXISTS extensions;
ALTER EXTENSION unaccent SET SCHEMA extensions;
```

---

### 7. Proteção Contra Senhas Vazadas Desabilitada

**Correção:** Habilitar no Supabase Dashboard > Authentication > Policies > "Leaked Password Protection"

---

### 8. CORS Permissivo
**Arquivos:** Todas Edge Functions

**Problema:** `"Access-Control-Allow-Origin": "*"`

**Correção:**
```typescript
const ALLOWED_ORIGINS = [
  'https://seu-app.vercel.app',
  'http://localhost:8080'
];

const getCorsHeaders = (origin: string | null) => {
  const isAllowed = origin && ALLOWED_ORIGINS.includes(origin);
  return {
    'Access-Control-Allow-Origin': isAllowed ? origin : ALLOWED_ORIGINS[0],
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };
};
```

---

## 🟡 PROBLEMAS MÉDIOS

### 9. Políticas RLS com Performance Subótima

**Correção:**
```sql
-- Usar subquery ao invés de chamada direta
CREATE POLICY "policy_name"
  ON table_name
  FOR SELECT
  USING ((SELECT auth.uid()) = user_id);  -- FIX
```

---

### 10. Múltiplas Políticas Redundantes
**Tabelas:** `stores`, `subscription_plans`

**Correção:** Consolidar políticas duplicadas em uma única política otimizada.

---

### 11. localStorage para Dados Sensíveis
**Arquivos:** `StoreSlug.tsx`, `OrderSuccess.tsx`

**Correção:** Usar `sessionStorage` ou Context API.

---

### 12. Falta de Rate Limiting

**Correção:** Implementar rate limiting com Upstash Redis nas Edge Functions.

---

### 13. Falta de Validação de Input

**Correção:** Usar Zod para validar inputs nas Edge Functions.

---

### 14. Logs Excessivos em Produção

**Correção:** Criar utilitário de logging com níveis configuráveis.

---

### 15. Falta de Timeout em Requisições HTTP

**Correção:** Adicionar AbortController com timeout de 10s.

---

### 16. Falta de Índices Otimizados

**Correção:**
```sql
CREATE INDEX idx_products_store_available 
  ON public.products(store_id, available) WHERE available = true;

CREATE INDEX idx_orders_store_status 
  ON public.orders(store_id, status, created_at DESC);
```

---

## 🔵 MELHORIAS RECOMENDADAS

### 17. Content Security Policy (CSP)
### 18. Headers de Segurança
### 19. Auditoria de Ações Sensíveis
### 20. Backup Automático
### 21. Monitoramento com Sentry
### 22. Testes de Segurança Automatizados

---

## 📋 PLANO DE AÇÃO PRIORIZADO

### Fase 1 - URGENTE (Executar Hoje)
1. ✅ Remover política RLS pública de `merchant_payment_credentials`
2. ✅ Rotacionar todos tokens do Mercado Pago
3. ✅ Implementar validação de assinatura no webhook
4. ✅ Mover credenciais para variáveis de ambiente

### Fase 2 - Curto Prazo (Esta Semana)
5. Implementar sistema de roles
6. Corrigir search_path em funções SECURITY DEFINER
7. Mover extensão unaccent para schema dedicado
8. Habilitar proteção contra senhas vazadas
9. Restringir CORS nas Edge Functions

### Fase 3 - Médio Prazo (Este Mês)
10. Otimizar políticas RLS
11. Consolidar políticas redundantes
12. Implementar rate limiting
13. Adicionar validação de inputs
14. Criar índices otimizados
15. Implementar logging adequado

### Fase 4 - Longo Prazo (Próximos 3 Meses)
16. Implementar CSP e headers de segurança
17. Configurar auditoria de ações
18. Configurar backups automáticos
19. Integrar monitoramento
20. Implementar testes de segurança

---

## 📞 CONTATOS E RECURSOS

- [Supabase Security Best Practices](https://supabase.com/docs/guides/database/database-linter)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Mercado Pago Security](https://www.mercadopago.com.br/developers/pt/docs/security)

---

**Relatório gerado automaticamente em:** 12/10/2025
