# 📋 Como Funciona o Sistema de Assinatura

## 🎯 Visão Geral

O sistema de assinatura controla o acesso dos usuários ao painel administrativo. Sem assinatura ativa, o usuário não pode gerenciar sua loja.

---

## 📦 Planos Disponíveis

### 1. 🆓 Teste Gratuito (Trial)
- **Preço:** R$ 0,00
- **Duração:** 7 dias
- **Identificador:** `trial`
- **Recursos:**
  - ✅ Acesso completo por 7 dias
  - ✅ Gestão de produtos
  - ✅ Dashboard básico
  - ✅ Sem cartão de crédito

**Ideal para:** Testar o sistema antes de assinar

---

### 2. 💳 Plano Mensal
- **Preço:** R$ 29,90/mês
- **Duração:** 30 dias
- **Identificador:** `monthly`
- **Recursos:**
  - ✅ Acesso completo
  - ✅ Gestão de produtos e pedidos
  - ✅ Dashboard com estatísticas
  - ✅ Suporte prioritário

**Ideal para:** Quem quer flexibilidade mensal

---

### 3. 🏆 Plano Anual
- **Preço:** R$ 299,90/ano (R$ 24,99/mês)
- **Duração:** 365 dias
- **Identificador:** `yearly`
- **Desconto:** 16% (economiza R$ 59,00)
- **Recursos:**
  - ✅ Acesso completo
  - ✅ Gestão de produtos e pedidos
  - ✅ Dashboard com estatísticas
  - ✅ Suporte VIP exclusivo
  - ✅ Desconto de 16%

**Ideal para:** Quem quer economia e compromisso de longo prazo

---

## 🔄 Fluxo de Assinatura

### 1. **Novo Usuário (Sem Assinatura)**

```
Usuário se cadastra
    ↓
Faz login no painel
    ↓
Vê tela: "Sem Assinatura Ativa"
    ↓
Clica em "Ver Planos Disponíveis"
    ↓
Escolhe um plano
    ↓
Realiza pagamento (PIX via Mercado Pago)
    ↓
Assinatura ativada automaticamente
    ↓
Acesso liberado ao painel admin
```

---

### 2. **Usuário com Assinatura Ativa**

```
Usuário faz login
    ↓
Acessa: Admin → Assinatura
    ↓
Vê informações:
  - Nome do plano
  - Status (Ativa/Expirando/Expirada)
  - Data de início
  - Data de expiração
  - Dias restantes
  - Barra de progresso
    ↓
Pode renovar antes de expirar
```

---

### 3. **Assinatura Expirando (≤ 7 dias)**

```
Sistema detecta: dias_remaining ≤ 7
    ↓
Status muda para: "Expirando em Breve"
    ↓
Badge laranja aparece
    ↓
Botão "Renovar Assinatura" aparece
    ↓
Usuário pode renovar antes de expirar
```

---

### 4. **Assinatura Expirada**

```
Sistema detecta: expires_at < NOW()
    ↓
Status muda para: "Expirada"
    ↓
Badge vermelho aparece
    ↓
Acesso ao painel bloqueado (opcional)
    ↓
Botão "Renovar Assinatura Agora" aparece
    ↓
Usuário precisa renovar para continuar
```

---

## 📊 Página "Gerencie sua Assinatura"

### Localização
**Admin → Assinatura** (`/admin/subscription`)

### O que é exibido:

#### 1. **Sem Assinatura**
```
┌─────────────────────────────────────────┐
│ ⚠️ Sem Assinatura Ativa                 │
│                                         │
│ Você não possui uma assinatura ativa.  │
│                                         │
│ Para acessar todos os recursos do      │
│ sistema, você precisa escolher um      │
│ plano de assinatura.                   │
│                                         │
│ [Ver Planos Disponíveis]               │
└─────────────────────────────────────────┘
```

---

#### 2. **Assinatura Ativa**
```
┌─────────────────────────────────────────┐
│ ✅ Teste Gratuito          [Badge]      │
│    Status: Ativa                        │
│                                         │
│ ⏰ Dias Restantes                       │
│    5 dias                               │
│                                         │
│ Progresso do Período          71%      │
│ ████████████████████░░░░░░              │
│                                         │
│ 📅 Data de Início                       │
│    12 de outubro de 2025                │
│                                         │
│ 📅 Expira em                            │
│    19 de outubro de 2025                │
└─────────────────────────────────────────┘
```

---

#### 3. **Assinatura Expirando (≤ 7 dias)**
```
┌─────────────────────────────────────────┐
│ ⚠️ Teste Gratuito                       │
│    Status: Expirando em Breve           │
│                                         │
│ ⏰ Dias Restantes                       │
│    3 dias                               │
│                                         │
│ Progresso do Período          86%      │
│ ████████████████████████░░              │
│                                         │
│ 📅 Data de Início                       │
│    12 de outubro de 2025                │
│                                         │
│ 📅 Expira em                            │
│    19 de outubro de 2025                │
│                                         │
│ ⚠️ Sua assinatura está próxima do      │
│    vencimento. Renove agora para       │
│    não perder o acesso.                │
│                                         │
│ [Renovar Assinatura]                   │
└─────────────────────────────────────────┘
```

---

#### 4. **Assinatura Expirada**
```
┌─────────────────────────────────────────┐
│ ❌ Teste Gratuito                       │
│    Status: Expirada                     │
│                                         │
│ ⏰ Dias Restantes                       │
│    0 dias                               │
│                                         │
│ 📅 Data de Início                       │
│    1 de setembro de 2025                │
│                                         │
│ 📅 Expirou em                           │
│    8 de setembro de 2025                │
│                                         │
│ ❌ Sua assinatura expirou.              │
│    Renove agora para continuar         │
│    acessando o painel.                 │
│                                         │
│ [Renovar Assinatura Agora]             │
└─────────────────────────────────────────┘
```

---

## 🎨 Elementos Visuais

### Status e Cores

| Status | Cor | Badge | Ícone |
|--------|-----|-------|-------|
| Ativa | 🟢 Verde | `default` | ✅ CheckCircle |
| Expirando | 🟠 Laranja | `outline` | ⏰ Clock |
| Expirada | 🔴 Vermelho | `destructive` | ❌ AlertCircle |

### Barra de Progresso

```typescript
// Cálculo da porcentagem
const totalDays = plan_slug === 'yearly' ? 365 : 30;
const percentageRemaining = (days_remaining / totalDays) * 100;
```

**Cores:**
- Verde: Assinatura ativa (> 7 dias)
- Laranja: Expirando em breve (≤ 7 dias)
- Não exibida: Assinatura expirada

---

## 🔧 Como Funciona Tecnicamente

### 1. **Banco de Dados**

#### Tabela: `subscription_plans`
```sql
id              | uuid
name            | text (ex: "Teste Gratuito")
slug            | text (ex: "trial")
price           | numeric (ex: 0.00)
duration_days   | integer (ex: 7)
is_trial        | boolean
features        | jsonb (array de recursos)
is_active       | boolean
```

#### Tabela: `user_subscriptions`
```sql
id                      | uuid
user_id                 | uuid (FK → auth.users)
subscription_plan_id    | uuid (FK → subscription_plans)
status                  | text (active/expired/cancelled)
expires_at              | timestamptz
created_at              | timestamptz
```

#### Função: `get_active_subscription`
```sql
-- Retorna assinatura ativa do usuário
SELECT 
  us.id,
  sp.name AS plan_name,
  sp.slug AS plan_slug,
  us.status,
  us.expires_at,
  us.created_at,
  -- Cálculo preciso de dias restantes
  GREATEST(0, FLOOR(EXTRACT(EPOCH FROM (us.expires_at - NOW())) / 86400))::INTEGER AS days_remaining
FROM user_subscriptions us
JOIN subscription_plans sp ON us.subscription_plan_id = sp.id
WHERE us.user_id = auth.uid()
ORDER BY us.created_at DESC
LIMIT 1;
```

---

### 2. **Frontend (React)**

#### Context: `SubscriptionContext`
```typescript
// Gerencia estado da assinatura
const { subscription, isSubscriptionActive } = useSubscription();

// subscription contém:
{
  id: string;
  plan_name: string;
  plan_slug: string;
  status: 'active' | 'expired' | 'cancelled';
  expires_at: string;
  created_at: string;
  days_remaining: number;
}
```

#### Componente: `Subscription.tsx`
```typescript
// Exibe informações da assinatura
- Status (Ativa/Expirando/Expirada)
- Dias restantes
- Datas (início e expiração)
- Barra de progresso
- Botões de ação
```

---

### 3. **Fluxo de Pagamento**

```
1. Usuário escolhe plano
    ↓
2. Frontend chama: createSubscription()
    ↓
3. Backend cria pagamento PIX no Mercado Pago
    ↓
4. Retorna QR Code PIX
    ↓
5. Usuário paga via PIX
    ↓
6. Webhook do Mercado Pago notifica
    ↓
7. Backend atualiza status do pagamento
    ↓
8. Se aprovado: cria user_subscription
    ↓
9. Assinatura ativada automaticamente
    ↓
10. Usuário recebe acesso ao painel
```

---

## 🔒 Controle de Acesso

### Verificação de Assinatura

```typescript
// SubscriptionContext verifica automaticamente
useEffect(() => {
  if (!isSubscriptionActive) {
    // Redireciona para página de planos
    navigate('/planos');
  }
}, [isSubscriptionActive]);
```

### Proteção de Rotas

```typescript
// ProtectedRoute verifica assinatura
<Route 
  path="/admin/*" 
  element={
    <ProtectedRoute requiresSubscription>
      <AdminLayout />
    </ProtectedRoute>
  } 
/>
```

---

## 📅 Cálculo de Datas

### Data de Início
```typescript
// Usa created_at real do banco
subscription.created_at
// Exemplo: "2025-10-12T10:00:00Z"
```

### Data de Expiração
```typescript
// Calculada ao criar assinatura
expires_at = created_at + duration_days
// Exemplo: "2025-10-19T10:00:00Z" (7 dias depois)
```

### Dias Restantes
```sql
-- Cálculo preciso com EPOCH (considera horas)
FLOOR(EXTRACT(EPOCH FROM (expires_at - NOW())) / 86400)::INTEGER

-- Exemplo:
-- expires_at: 2025-10-19 10:00:00
-- NOW():      2025-10-15 14:30:00
-- Diferença:  3 dias, 19h, 30min
-- Resultado:  3 dias (arredondado para baixo)
```

---

## 🎯 Casos de Uso

### Caso 1: Novo Usuário Testando
```
1. Cadastra-se no sistema
2. Escolhe "Teste Gratuito"
3. Não precisa pagar
4. Recebe 7 dias de acesso completo
5. Pode testar todos os recursos
6. Após 7 dias, precisa assinar
```

### Caso 2: Usuário Satisfeito Assinando
```
1. Termina teste gratuito
2. Gosta do sistema
3. Escolhe plano Mensal ou Anual
4. Paga via PIX
5. Assinatura ativada automaticamente
6. Continua usando sem interrupção
```

### Caso 3: Assinatura Expirando
```
1. Sistema detecta: 7 dias ou menos
2. Exibe aviso: "Expirando em Breve"
3. Mostra botão "Renovar Assinatura"
4. Usuário pode renovar antecipadamente
5. Nova assinatura começa após expiração da atual
```

### Caso 4: Assinatura Expirada
```
1. Sistema detecta: expires_at < NOW()
2. Status muda para "Expirada"
3. Acesso ao painel bloqueado (opcional)
4. Exibe: "Renovar Assinatura Agora"
5. Usuário precisa renovar para continuar
```

---

## 🔄 Renovação de Assinatura

### Como Renovar

1. **Antes de Expirar:**
   - Clique em "Renovar Assinatura"
   - Escolha o mesmo plano ou outro
   - Pague via PIX
   - Nova assinatura começa após expiração da atual

2. **Após Expirar:**
   - Clique em "Renovar Assinatura Agora"
   - Escolha um plano
   - Pague via PIX
   - Assinatura ativada imediatamente

### Lógica de Renovação

```typescript
// Se assinatura ainda ativa
nova_expires_at = assinatura_atual.expires_at + duration_days

// Se assinatura expirada
nova_expires_at = NOW() + duration_days
```

---

## 📊 Estatísticas e Monitoramento

### Queries Úteis

```sql
-- Ver todas as assinaturas ativas
SELECT 
  u.email,
  sp.name AS plano,
  us.status,
  us.expires_at,
  FLOOR(EXTRACT(EPOCH FROM (us.expires_at - NOW())) / 86400) AS dias_restantes
FROM user_subscriptions us
JOIN subscription_plans sp ON us.subscription_plan_id = sp.id
JOIN auth.users u ON us.user_id = u.id
WHERE us.status = 'active'
ORDER BY us.expires_at;

-- Ver assinaturas expirando em breve (7 dias)
SELECT 
  u.email,
  sp.name AS plano,
  us.expires_at,
  FLOOR(EXTRACT(EPOCH FROM (us.expires_at - NOW())) / 86400) AS dias_restantes
FROM user_subscriptions us
JOIN subscription_plans sp ON us.subscription_plan_id = sp.id
JOIN auth.users u ON us.user_id = u.id
WHERE us.status = 'active'
AND us.expires_at <= NOW() + INTERVAL '7 days'
ORDER BY us.expires_at;

-- Ver receita por plano
SELECT 
  sp.name AS plano,
  COUNT(*) AS assinaturas,
  SUM(sp.price) AS receita_total
FROM user_subscriptions us
JOIN subscription_plans sp ON us.subscription_plan_id = sp.id
WHERE us.status = 'active'
GROUP BY sp.name, sp.price
ORDER BY receita_total DESC;
```

---

## 🎉 Resumo

### O Sistema de Assinatura:

✅ **Controla acesso** ao painel administrativo  
✅ **3 planos** disponíveis (Trial, Mensal, Anual)  
✅ **Pagamento via PIX** (Mercado Pago)  
✅ **Ativação automática** após pagamento  
✅ **Avisos de expiração** (7 dias antes)  
✅ **Renovação fácil** (antes ou depois de expirar)  
✅ **Cálculos precisos** (datas e dias restantes)  
✅ **Interface clara** (status, progresso, datas)  
✅ **Seguro** (RLS habilitado)  

---

## 📚 Arquivos Relacionados

### Backend
- `supabase/migrations/20251010193700_create_subscription_tables.sql`
- Função: `get_active_subscription`

### Frontend
- `src/contexts/SubscriptionContext.tsx`
- `src/pages/admin/Subscription.tsx`
- `src/services/subscriptionService.ts`

### Documentação
- `SOLUCAO_COMPLETA_ASSINATURA.md`
- `SQL_FIX_SUBSCRIPTION_COMPLETO.sql`

---

**Sistema de assinatura completo e funcionando!** 🚀
