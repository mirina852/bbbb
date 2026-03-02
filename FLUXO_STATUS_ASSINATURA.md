# 📋 Fluxo de Status da Assinatura

## 🎯 Visão Geral

O sistema gerencia assinaturas com 3 status principais e diferentes estados visuais baseados nos dias restantes.

---

## 📊 Status da Assinatura

### 1. **Status no Banco de Dados**

A tabela `user_subscriptions` armazena o status:

```sql
status: 'active' | 'expired' | 'cancelled'
```

### 2. **Cálculo de Dias Restantes**

A função `get_active_subscription()` calcula automaticamente:

```sql
GREATEST(0, (DATE(expires_at) - DATE(NOW()))::INTEGER) AS days_remaining
```

**Lógica:**
- Subtrai a data atual da data de expiração
- Retorna 0 se o resultado for negativo (já expirou)
- Retorna o número de dias se positivo

---

## 🎨 Estados Visuais no Frontend

### **Estado 1: Assinatura Ativa** ✅
- **Condição:** `status === 'active' && days_remaining > 7`
- **Badge:** Verde - "Ativa"
- **Ícone:** `CheckCircle` (verde)
- **Borda do Card:** Verde
- **Barra de Progresso:** Verde
- **Ação:** Nenhuma ação necessária

### **Estado 2: Expirando em Breve** ⚠️
- **Condição:** `status === 'active' && days_remaining <= 7 && days_remaining > 0`
- **Badge:** Laranja - "Expirando em Breve"
- **Ícone:** `Clock` (laranja)
- **Borda do Card:** Laranja
- **Barra de Progresso:** Laranja
- **Ação:** Botão "Renovar Assinatura" (laranja)
- **Dias Restantes:** Exibido em laranja

### **Estado 3: Expirada** ❌
- **Condição:** `status === 'expired' || days_remaining === 0`
- **Badge:** Vermelho - "Expirada"
- **Ícone:** `AlertCircle` (vermelho)
- **Borda do Card:** Vermelho
- **Barra de Progresso:** Oculta
- **Ação:** Botão "Renovar Assinatura Agora" (vermelho, destrutivo)
- **Dias Restantes:** Mostra "0" em vermelho

### **Estado 4: Sem Assinatura** 🚫
- **Condição:** `subscription === null`
- **Visual:** Card laranja com alerta
- **Título:** "Assinatura Necessária"
- **Ação:** Botão "🚀 Ver Planos e Ativar Agora"
- **Acesso:** Bloqueado ao Dashboard, Produtos, Pedidos e Configurações

---

## 🔄 Fluxo de Transição de Status

```
┌─────────────────┐
│  Sem Assinatura │ (subscription = null)
└────────┬────────┘
         │ Usuário escolhe plano
         ▼
┌─────────────────┐
│  Ativa (> 7d)   │ status: 'active', days_remaining > 7
└────────┬────────┘
         │ Tempo passa
         ▼
┌─────────────────┐
│ Expirando (≤7d) │ status: 'active', days_remaining ≤ 7
└────────┬────────┘
         │ Tempo passa ou não renova
         ▼
┌─────────────────┐
│    Expirada     │ status: 'expired', days_remaining = 0
└────────┬────────┘
         │ Usuário renova
         ▼
┌─────────────────┐
│  Ativa (> 7d)   │ Nova assinatura criada
└─────────────────┘
```

---

## 🧮 Cálculo de Progresso

### Fórmula da Barra de Progresso

```typescript
const totalDays = subscription.plan_slug === 'yearly' ? 365 : 30;
const percentageRemaining = Math.max(0, Math.min(100, (daysRemaining / totalDays) * 100));
```

**Exemplo:**
- Plano Mensal (30 dias), 15 dias restantes: `(15/30) * 100 = 50%`
- Plano Anual (365 dias), 182 dias restantes: `(182/365) * 100 ≈ 50%`

---

## 📁 Arquivos Envolvidos

### **Backend (Supabase)**
1. **Tabela:** `user_subscriptions`
   - Campos: `id`, `user_id`, `subscription_plan_id`, `status`, `expires_at`, `created_at`

2. **Função RPC:** `get_active_subscription(_user_id UUID)`
   - Retorna: `id`, `plan_name`, `plan_slug`, `status`, `expires_at`, `created_at`, `days_remaining`
   - Localização: `supabase/migrations/20251012130000_fix_subscription_dates.sql`

3. **Função RPC:** `has_active_subscription(_user_id UUID)`
   - Retorna: `boolean`

### **Frontend (React)**
1. **Serviço:** `src/services/subscriptionService.ts`
   - `getActiveSubscription(userId)`: Busca assinatura ativa
   - `hasActiveSubscription(userId)`: Verifica se tem assinatura ativa

2. **Contexto:** `src/contexts/SubscriptionContext.tsx`
   - Gerencia estado global da assinatura
   - Provê: `subscription`, `isSubscriptionActive`, `isLoading`, `refreshSubscription()`

3. **Página:** `src/pages/admin/Subscription.tsx`
   - Exibe detalhes da assinatura
   - Calcula estados visuais
   - Mostra botões de ação

4. **Componente:** `src/components/subscription/SubscriptionWarning.tsx`
   - Alerta quando assinatura está inativa
   - Diferencia entre teste expirado e sem assinatura

---

## 🎯 Lógica de Decisão no Frontend

```typescript
// Arquivo: src/pages/admin/Subscription.tsx

const daysRemaining = subscription.days_remaining;
const isExpiringSoon = daysRemaining <= 7;
const isExpired = subscription.status === 'expired';

// Definir badge e ícone
if (isExpired) {
  badgeVariant = 'destructive';
  statusText = 'Expirada';
  statusIcon = <AlertCircle className="h-5 w-5 text-red-600" />;
} else if (isExpiringSoon) {
  badgeVariant = 'outline';
  statusText = 'Expirando em Breve';
  statusIcon = <Clock className="h-5 w-5 text-orange-600" />;
} else {
  badgeVariant = 'default';
  statusText = 'Ativa';
  statusIcon = <CheckCircle className="h-5 w-5 text-green-600" />;
}
```

---

## 🔍 Verificação de Status

### **No Contexto**
```typescript
const isSubscriptionActive = subscription !== null && subscription.status === 'active' && subscription.days_remaining > 0;
```

**Importante:** A verificação inclui 3 condições:
1. `subscription !== null` - Existe uma assinatura
2. `subscription.status === 'active'` - Status é "active" no banco
3. `subscription.days_remaining > 0` - Ainda há dias restantes

### **Na Página**
```typescript
if (!subscription) {
  // Mostrar card "Assinatura Necessária"
}

if (isExpired) {
  // Mostrar card vermelho com "Renovar Agora"
}

if (isExpiringSoon) {
  // Mostrar card laranja com "Renovar"
}
```

---

## 🎨 Componentes Visuais

### **Badge de Status**
```typescript
<Badge variant={badgeVariant}>{statusText}</Badge>
```

### **Dias Restantes**
```typescript
<p className={`text-3xl font-bold ${
  isExpired ? 'text-red-600' : 
  isExpiringSoon ? 'text-orange-600' : 
  'text-green-600'
}`}>
  {isExpired ? '0' : daysRemaining}
</p>
```

### **Barra de Progresso**
```typescript
{!isExpired && (
  <Progress 
    value={percentageRemaining} 
    className={`h-3 ${
      isExpiringSoon ? '[&>div]:bg-orange-500' : '[&>div]:bg-green-500'
    }`}
  />
)}
```

### **Botão de Ação**
```typescript
{(isExpiringSoon || isExpired) && (
  <Button 
    onClick={() => navigate('/planos')}
    variant={isExpired ? 'destructive' : 'default'}
    size="lg"
    className="w-full"
  >
    {isExpired ? 'Renovar Assinatura Agora' : 'Renovar Assinatura'}
  </Button>
)}
```

---

## 🧪 Cenários de Teste

### **Teste 1: Assinatura Nova (30 dias)**
- `days_remaining`: 30
- **Esperado:** Badge verde "Ativa", barra 100%, sem botão de renovar

### **Teste 2: Assinatura com 7 dias**
- `days_remaining`: 7
- **Esperado:** Badge laranja "Expirando em Breve", barra ~23%, botão "Renovar"

### **Teste 3: Assinatura com 1 dia**
- `days_remaining`: 1
- **Esperado:** Badge laranja "Expirando em Breve", barra ~3%, botão "Renovar"

### **Teste 4: Assinatura Expirada**
- `days_remaining`: 0, `status`: 'expired'
- **Esperado:** Badge vermelho "Expirada", sem barra, botão "Renovar Agora" (vermelho)

### **Teste 5: Sem Assinatura**
- `subscription`: null
- **Esperado:** Card laranja "Assinatura Necessária", botão "Ver Planos"

---

## 📝 Notas Importantes

1. **Cálculo Automático:** Os dias restantes são calculados automaticamente pela função SQL, não pelo frontend
2. **Threshold de 7 dias:** O sistema considera "expirando em breve" quando restam 7 dias ou menos
3. **Data de Início Real:** O campo `created_at` mostra quando a assinatura foi realmente criada
4. **Refresh Automático:** O contexto carrega a assinatura sempre que o usuário muda
5. **Proteção de Rotas:** Páginas protegidas verificam `isSubscriptionActive` antes de permitir acesso

---

## 🔄 Atualização de Status

O status é atualizado:
1. **Automaticamente:** Quando o usuário faz login ou navega
2. **Manualmente:** Chamando `refreshSubscription()` do contexto
3. **Após Pagamento:** Quando um pagamento PIX é confirmado

---

## 📞 Funções Úteis

### **Verificar se tem assinatura ativa**
```typescript
const { isSubscriptionActive } = useSubscription();
```

### **Obter dados da assinatura**
```typescript
const { subscription } = useSubscription();
console.log(subscription.days_remaining);
console.log(subscription.status);
```

### **Forçar atualização**
```typescript
const { refreshSubscription } = useSubscription();
await refreshSubscription();
```

---

## ✅ Checklist de Implementação

- [x] Função SQL `get_active_subscription` com cálculo de dias
- [x] Serviço `subscriptionService` com métodos de busca
- [x] Contexto `SubscriptionContext` para estado global
- [x] Página `Subscription.tsx` com todos os estados visuais
- [x] Componente `SubscriptionWarning` para alertas
- [x] Lógica de threshold (7 dias) implementada
- [x] Cores e badges diferenciados por status
- [x] Botões de ação condicionais
- [x] Barra de progresso com cálculo correto
- [x] Tratamento de assinatura nula

---

## 🐛 Correções Aplicadas

### **Bug: Acesso ao painel com assinatura expirada**

**Problema identificado:**
1. As rotas do admin não tinham `requireSubscription`
2. O `isSubscriptionActive` não verificava `days_remaining > 0`

**Correções aplicadas:**

1. **App.tsx** - Adicionado `requireSubscription` nas rotas protegidas:
```typescript
<Route path="/admin" element={
  <ProtectedRoute requireAdmin requireSubscription>
    <Dashboard />
  </ProtectedRoute>
} />
```

2. **SubscriptionContext.tsx** - Corrigida verificação de assinatura ativa:
```typescript
const isSubscriptionActive = subscription !== null && 
  subscription.status === 'active' && 
  subscription.days_remaining > 0;
```

**Resultado:**
- ✅ Usuários com assinatura expirada (0 dias) são redirecionados para `/admin/subscription`
- ✅ Acesso bloqueado ao Dashboard, Produtos, Pedidos e Configurações
- ✅ Usuário pode ver o status da assinatura e renovar

---

**Última atualização:** 19 de outubro de 2025
