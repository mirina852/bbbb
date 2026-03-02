# ✅ Solução: Campos Obrigatórios em subscription_payments

## Estrutura da Tabela

A tabela `subscription_payments` tem a seguinte estrutura:

```sql
CREATE TABLE public.subscription_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,                          -- ✅ OBRIGATÓRIO
  subscription_plan_id UUID NOT NULL,             -- ✅ OBRIGATÓRIO (NÃO subscription_id!)
  amount DECIMAL(10,2) NOT NULL,                  -- ✅ OBRIGATÓRIO
  status TEXT NOT NULL DEFAULT 'pending',         -- ✅ OBRIGATÓRIO (tem default)
  payment_method TEXT DEFAULT 'pix',              -- ✅ Opcional (tem default)
  payment_id TEXT,                                -- ✅ Opcional
  external_payment_id TEXT,                       -- ✅ Opcional
  qr_code TEXT,                                   -- ✅ Opcional
  qr_code_base64 TEXT,                            -- ✅ Opcional
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

## ⚠️ IMPORTANTE: NÃO existe `subscription_id`!

A coluna se chama **`subscription_plan_id`**, não `subscription_id`.

- ❌ **ERRADO**: `subscription_id` (não existe!)
- ✅ **CORRETO**: `subscription_plan_id`

## Campos Obrigatórios (NOT NULL)

### 1. `user_id` ✅
**Onde preencher**: Obtido do usuário autenticado

```typescript
const { data: { user } } = await supabase.auth.getUser();
if (!user) throw new Error('Usuário não autenticado');

// Usar user.id
```

### 2. `subscription_plan_id` ✅
**Onde preencher**: ID do plano escolhido

```typescript
// Recebido do frontend
const { planId } = body;

// Validar se existe
const { data: plan } = await supabase
  .from('subscription_plans')
  .select('id')
  .eq('id', planId)
  .single();

if (!plan) throw new Error('Plano não encontrado');
```

### 3. `amount` ✅
**Onde preencher**: Valor do pagamento

```typescript
// Buscar do plano
const { data: plan } = await supabase
  .from('subscription_plans')
  .select('price')
  .eq('id', planId)
  .single();

const amount = plan.price; // Sempre tem valor
```

### 4. `status` ✅
**Onde preencher**: Status do pagamento (tem default 'pending')

```typescript
// Pode omitir (usa default) ou especificar
status: 'pending' // ou 'approved', 'expired', 'cancelled'
```

### 5. `payment_method` ✅
**Onde preencher**: Método de pagamento (tem default 'pix')

```typescript
// Pode omitir (usa default) ou especificar
payment_method: 'pix'
```

## ✅ Código Correto na Edge Function

**Arquivo**: `supabase/functions/create-pix-payment/index.ts` (linhas 286-296)

```typescript
// ✅ CORRETO - Todos os campos obrigatórios preenchidos
const result = await supabaseClient
  .from("subscription_payments")
  .insert({
    user_id: user.id,                    // ✅ Obrigatório
    subscription_plan_id: planId,        // ✅ Obrigatório (NÃO subscription_id!)
    amount,                              // ✅ Obrigatório
    status: "pending",                   // ✅ Obrigatório (ou usa default)
    payment_method: "pix",               // ✅ Opcional (tem default)
    payment_id: paymentId,               // ✅ Opcional
    external_payment_id: paymentId,      // ✅ Opcional
    qr_code: qrCode,                     // ✅ Opcional
    qr_code_base64: qrCodeBase64         // ✅ Opcional
  })
  .select()
  .single();
```

## ❌ Erros Comuns

### Erro 1: "null value in column subscription_id"
**Causa**: Tentando inserir com `subscription_id` (coluna não existe)  
**Solução**: Usar `subscription_plan_id`

```typescript
// ❌ ERRADO
subscription_id: planId  // Coluna não existe!

// ✅ CORRETO
subscription_plan_id: planId
```

### Erro 2: "null value in column user_id"
**Causa**: Não está enviando `user_id`  
**Solução**: Sempre obter do usuário autenticado

```typescript
// ✅ CORRETO
const { data: { user } } = await supabase.auth.getUser(token);
if (!user) throw new Error('Não autorizado');

// Usar user.id no insert
user_id: user.id
```

### Erro 3: "null value in column amount"
**Causa**: Não está enviando `amount`  
**Solução**: Buscar do plano

```typescript
// ✅ CORRETO
const { data: plan } = await supabase
  .from('subscription_plans')
  .select('price')
  .eq('id', planId)
  .single();

amount: plan.price
```

## 🧪 Verificar no Banco

```sql
-- Ver estrutura da tabela
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'subscription_payments'
ORDER BY ordinal_position;

-- Ver pagamentos criados
SELECT 
  id,
  user_id,
  subscription_plan_id,  -- ✅ NÃO subscription_id!
  amount,
  status,
  payment_method,
  created_at
FROM subscription_payments
ORDER BY created_at DESC
LIMIT 10;
```

## 📋 Checklist de Validação

Antes de inserir um pagamento, verificar:

- [ ] `user_id` está preenchido (do usuário autenticado)
- [ ] `subscription_plan_id` está preenchido (ID do plano válido)
- [ ] `amount` está preenchido (valor > 0)
- [ ] `status` está preenchido ou usa default ('pending')
- [ ] `payment_method` está preenchido ou usa default ('pix')
- [ ] **NÃO** usar `subscription_id` (coluna não existe!)

## ✅ Código Atual Está Correto!

A Edge Function `create-pix-payment` **JÁ está correta** (linha 286-296). Ela preenche todos os campos obrigatórios:

- ✅ `user_id`: user.id
- ✅ `subscription_plan_id`: planId
- ✅ `amount`: amount
- ✅ `status`: "pending"
- ✅ `payment_method`: "pix"

Se você está recebendo erro de `subscription_id`, pode ser:
1. Código antigo em outro lugar tentando usar `subscription_id`
2. Migration antiga que criou a coluna errada
3. Types do Supabase desatualizados

Execute `npx supabase gen types typescript` para atualizar os types!
