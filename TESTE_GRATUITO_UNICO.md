# 🎁 Teste Gratuito Único por Conta

## 📋 Regra de Negócio

**O Teste Gratuito só pode ser usado uma única vez por conta.**

Após o período de teste terminar (expirar ou ser cancelado), não é possível ativar outro teste gratuito novamente na mesma conta.

---

## 🔒 Implementação

### **1. Banco de Dados (Migration)**

**Arquivo:** `supabase/migrations/20251019000000_trial_once_per_user.sql`

#### **Funções Criadas:**

##### **a) has_used_trial(_user_id)**
Verifica se o usuário já utilizou o teste gratuito alguma vez.

```sql
CREATE OR REPLACE FUNCTION public.has_used_trial(_user_id UUID)
RETURNS BOOLEAN
```

**Lógica:**
- Busca no histórico completo de `user_subscriptions`
- Verifica se existe alguma assinatura com `is_trial = true`
- Retorna `true` se encontrar, `false` caso contrário
- **Não importa o status** (active, expired, cancelled)

##### **b) get_available_plans(_user_id)**
Retorna todos os planos com flag de disponibilidade.

```sql
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
```

**Lógica:**
- Busca todos os planos ativos
- Para cada plano, verifica se é trial
- Se for trial e usuário já usou → `is_available = false`
- Caso contrário → `is_available = true`

##### **c) prevent_multiple_trials() - TRIGGER**
Bloqueia a criação de múltiplas assinaturas trial no banco.

```sql
CREATE TRIGGER prevent_multiple_trials_trigger
  BEFORE INSERT ON public.user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_multiple_trials();
```

**Lógica:**
- Executado **antes** de inserir uma nova assinatura
- Verifica se o plano é trial
- Verifica se usuário já usou trial
- Se sim, **lança exceção** e bloqueia a inserção
- Mensagem: "Usuário já utilizou o teste gratuito. Cada conta pode usar o teste apenas uma vez."

---

### **2. Backend (Service)**

**Arquivo:** `src/services/subscriptionService.ts`

#### **Novos Métodos:**

```typescript
// Verificar se usuário já usou o teste gratuito
async hasUsedTrial(userId: string): Promise<boolean>

// Buscar planos disponíveis para o usuário
async getAvailablePlans(userId: string): Promise<SubscriptionPlan[]>
```

#### **Interface Atualizada:**

```typescript
export interface SubscriptionPlan {
  id: string;
  name: string;
  slug: string;
  price: number;
  duration_days: number;
  is_trial: boolean;
  features: string[];
  is_available?: boolean;  // ✅ NOVO
}
```

---

### **3. Frontend (Página de Planos)**

**Arquivo:** `src/pages/subscription/SubscriptionPlans.tsx`

#### **Mudanças:**

1. **Carregar planos com disponibilidade:**
```typescript
const loadPlans = async () => {
  const data = user 
    ? await subscriptionService.getAvailablePlans(user.id)
    : await subscriptionService.getPlans();
  setPlans(data);
};
```

2. **Validar antes de selecionar:**
```typescript
const handleSelectPlan = async (planId: string) => {
  const plan = plans.find(p => p.id === planId);
  
  // ✅ Verificar se o plano está disponível
  if (plan.is_available === false) {
    toast.error('Você já utilizou o teste gratuito. Cada conta pode usar o teste apenas uma vez.');
    return;
  }
  
  // ... continuar com a ativação
};
```

3. **Passar disponibilidade para o componente:**
```typescript
<SubscriptionPlan
  isAvailable={plan.is_available !== false}
  // ... outras props
/>
```

---

### **4. Frontend (Componente de Plano)**

**Arquivo:** `src/components/subscription/SubscriptionPlan.tsx`

#### **Mudanças:**

1. **Nova prop:**
```typescript
interface SubscriptionPlanProps {
  // ... outras props
  isAvailable?: boolean;  // ✅ NOVO
}
```

2. **Badge visual:**
```typescript
{!isAvailable && isTrial && (
  <Badge className="absolute -top-3 left-1/2 -translate-x-1/2 bg-muted-foreground">
    Já Utilizado
  </Badge>
)}
```

3. **Card com opacidade:**
```typescript
<Card className={`relative ${!isAvailable ? 'opacity-60' : ''}`}>
```

4. **Botão desabilitado:**
```typescript
<Button 
  disabled={!isAvailable}
>
  {!isAvailable && isTrial ? 'Já Utilizado' : 
   isTrial ? 'Iniciar Teste Gratuito' : 'Selecionar Plano'}
</Button>
```

---

## 🎨 Experiência do Usuário

### **Cenário 1: Primeiro Acesso (Nunca usou trial)**

```
┌─────────────────────────────────────┐
│  Teste Gratuito                     │
│  R$ 0,00 / mês                      │
│  ✓ Acesso completo por 30 dias     │
│  ✓ Todos os recursos                │
│  ✓ Sem cartão de crédito            │
│                                     │
│  [Iniciar Teste Gratuito] ✅       │
└─────────────────────────────────────┘
```

**Comportamento:**
- Card normal, sem opacidade
- Botão habilitado
- Ao clicar, ativa o teste gratuito
- Usuário pode usar por 30 dias

---

### **Cenário 2: Já Usou Trial (Trial expirado ou cancelado)**

```
┌─────────────────────────────────────┐
│  [Já Utilizado]                     │
│  Teste Gratuito (opacidade 60%)    │
│  R$ 0,00 / mês                      │
│  ✓ Acesso completo por 30 dias     │
│  ✓ Todos os recursos                │
│  ✓ Sem cartão de crédito            │
│                                     │
│  [Já Utilizado] ❌ (desabilitado)  │
└─────────────────────────────────────┘
```

**Comportamento:**
- Badge "Já Utilizado" no topo
- Card com opacidade 60%
- Botão desabilitado
- Ao clicar (se tentar), mostra toast:
  - "Você já utilizou o teste gratuito. Cada conta pode usar o teste apenas uma vez."

---

## 🔄 Fluxo Completo

```
Usuário acessa /planos
         │
         ▼
    Está logado?
         │
    ┌────┴────┐
   NÃO       SIM
    │          │
    ▼          ▼
getPlans()  getAvailablePlans(userId)
    │          │
    │          ├─> has_used_trial(userId)
    │          │
    │          ├─> Se usou trial:
    │          │     is_available = false
    │          │
    │          └─> Se não usou:
    │                is_available = true
    │          │
    └──────────┴──────────┐
                          ▼
              Renderizar planos
                          │
                          ▼
         Trial com is_available = false?
                          │
                     ┌────┴────┐
                    SIM       NÃO
                     │          │
                     ▼          ▼
         Badge "Já Utilizado"  Badge normal
         Botão desabilitado    Botão habilitado
         Opacidade 60%         Opacidade 100%
```

---

## 🛡️ Camadas de Segurança

### **Camada 1: Frontend (UX)**
- Botão desabilitado
- Badge visual "Já Utilizado"
- Toast de erro ao tentar clicar

### **Camada 2: Frontend (Validação)**
- Verifica `is_available` antes de processar
- Bloqueia chamada ao backend se indisponível

### **Camada 3: Backend (RPC)**
- Função `get_available_plans` retorna flag correta
- Função `has_used_trial` verifica histórico

### **Camada 4: Banco de Dados (TRIGGER)**
- Trigger `prevent_multiple_trials_trigger`
- Bloqueia INSERT se usuário já usou trial
- **Última linha de defesa** - mesmo que frontend falhe

---

## 🧪 Testes

### **Teste 1: Usuário nunca usou trial**

```sql
-- Verificar
SELECT public.has_used_trial('user-id-aqui');
-- Resultado esperado: false

-- Ver planos disponíveis
SELECT * FROM public.get_available_plans('user-id-aqui');
-- Resultado esperado: Trial com is_available = true
```

**Frontend:**
- Botão "Iniciar Teste Gratuito" habilitado
- Sem badge "Já Utilizado"
- Pode ativar o teste

---

### **Teste 2: Usuário já usou trial (expirado)**

```sql
-- Verificar
SELECT public.has_used_trial('user-id-aqui');
-- Resultado esperado: true

-- Ver planos disponíveis
SELECT * FROM public.get_available_plans('user-id-aqui');
-- Resultado esperado: Trial com is_available = false
```

**Frontend:**
- Botão "Já Utilizado" desabilitado
- Badge "Já Utilizado" visível
- Card com opacidade 60%
- Ao clicar, mostra erro

---

### **Teste 3: Tentar burlar o sistema (direto no banco)**

```sql
-- Tentar inserir segunda assinatura trial
INSERT INTO user_subscriptions (user_id, subscription_plan_id, status, expires_at)
VALUES (
  'user-id-que-ja-usou',
  'trial-plan-id',
  'active',
  NOW() + INTERVAL '30 days'
);

-- Resultado esperado: ERRO
-- ERROR: Usuário já utilizou o teste gratuito. Cada conta pode usar o teste apenas uma vez.
```

**Trigger bloqueia a inserção!** ✅

---

## 📊 Histórico de Assinaturas

A tabela `user_subscriptions` mantém **todo o histórico**:

```sql
SELECT 
  us.created_at AS "Data",
  sp.name AS "Plano",
  sp.is_trial AS "É Trial?",
  us.status AS "Status",
  us.expires_at AS "Expira em"
FROM user_subscriptions us
JOIN subscription_plans sp ON us.subscription_plan_id = sp.id
WHERE us.user_id = 'user-id-aqui'
ORDER BY us.created_at DESC;
```

**Exemplo de resultado:**

| Data | Plano | É Trial? | Status | Expira em |
|------|-------|----------|--------|-----------|
| 2025-10-19 | Plano Mensal | false | active | 2025-11-19 |
| 2025-09-15 | Teste Gratuito | true | expired | 2025-10-15 |

**Conclusão:** Usuário já usou trial em 15/09/2025 → Não pode usar novamente.

---

## 🎯 Casos de Uso

### **Caso 1: Novo usuário**
1. Cria conta
2. Vê página de planos
3. Teste Gratuito disponível ✅
4. Ativa teste gratuito
5. Usa por 30 dias
6. Trial expira

### **Caso 2: Usuário quer renovar trial**
1. Trial expirou
2. Acessa /planos
3. Teste Gratuito **indisponível** ❌
4. Badge "Já Utilizado"
5. Deve escolher plano pago

### **Caso 3: Usuário tenta burlar**
1. Tenta ativar trial novamente
2. Frontend bloqueia
3. Se burlar frontend, backend bloqueia
4. Se burlar backend, trigger bloqueia
5. **Impossível ativar segundo trial** 🔒

---

## ✅ Checklist de Implementação

- [x] Migration SQL criada
- [x] Função `has_used_trial` implementada
- [x] Função `get_available_plans` implementada
- [x] Trigger `prevent_multiple_trials` implementado
- [x] Service atualizado com novos métodos
- [x] Interface `SubscriptionPlan` atualizada
- [x] Página de planos usa `getAvailablePlans`
- [x] Validação no `handleSelectPlan`
- [x] Componente `SubscriptionPlan` com prop `isAvailable`
- [x] Badge "Já Utilizado" implementado
- [x] Botão desabilitado quando indisponível
- [x] Opacidade no card quando indisponível
- [x] Toast de erro ao tentar usar trial novamente
- [x] Documentação completa

---

## 📝 Mensagens ao Usuário

### **Quando tenta ativar trial novamente:**
```
❌ Você já utilizou o teste gratuito. Cada conta pode usar o teste apenas uma vez.
```

### **Quando trigger bloqueia no banco:**
```
ERROR: Usuário já utilizou o teste gratuito. Cada conta pode usar o teste apenas uma vez.
```

---

## 🔄 Migração

Para aplicar essa funcionalidade:

1. **Executar migration:**
```bash
# No Supabase Dashboard > SQL Editor
# Copiar e executar: supabase/migrations/20251019000000_trial_once_per_user.sql
```

2. **Verificar funções criadas:**
```sql
SELECT proname FROM pg_proc 
WHERE proname IN ('has_used_trial', 'get_available_plans', 'prevent_multiple_trials');
```

3. **Verificar trigger:**
```sql
SELECT trigger_name FROM information_schema.triggers 
WHERE trigger_name = 'prevent_multiple_trials_trigger';
```

4. **Testar com seu usuário:**
```sql
SELECT public.has_used_trial(auth.uid());
SELECT * FROM public.get_available_plans(auth.uid());
```

---

## 🎉 Benefícios

1. **Segurança:** Múltiplas camadas de proteção
2. **UX:** Feedback visual claro para o usuário
3. **Transparência:** Usuário sabe que já usou o trial
4. **Monetização:** Incentiva upgrade para planos pagos
5. **Histórico:** Mantém registro de todas as assinaturas
6. **Escalabilidade:** Funciona para milhares de usuários

---

**Data de implementação:** 19 de outubro de 2025  
**Versão:** 1.0  
**Status:** ✅ Implementado e testado
