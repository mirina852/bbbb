# 🔄 Renovação Antecipada de Assinatura

## 🎯 Funcionalidade

Permite que usuários **renovem sua assinatura antes dela expirar**. O novo período é **adicionado ao final** da assinatura atual, sem perder os dias restantes.

---

## 📊 Como Funciona

### **Cenário 1: Sem Assinatura Ativa**

```
Usuário sem assinatura
         │
         ▼
Escolhe plano de 30 dias
         │
         ▼
Assinatura criada
Expira em: HOJE + 30 dias
```

**Exemplo:**
- Hoje: 19/10/2025
- Expira em: 18/11/2025

---

### **Cenário 2: Com Assinatura Ativa (Renovação Antecipada)**

```
Usuário com assinatura ativa
(Expira em 30/10/2025 - 11 dias restantes)
         │
         ▼
Escolhe renovar com plano de 30 dias
         │
         ▼
Novo período ADICIONADO ao final
Expira em: 30/10/2025 + 30 dias = 29/11/2025
```

**Exemplo:**
- Assinatura atual expira: 30/10/2025
- Dias restantes: 11 dias
- Renova com plano de 30 dias
- **Nova data de expiração: 29/11/2025**
- **Total de dias: 11 + 30 = 41 dias**

---

## 🎨 Experiência do Usuário

### **1. Usuário com Assinatura Ativa**

Ao acessar `/planos`, vê:

```
┌─────────────────────────────────────────────────────────┐
│  ℹ️ Você já possui uma assinatura ativa                │
│  (Plano Mensal - 11 dias restantes).                   │
│  Ao renovar agora, o novo período será adicionado      │
│  ao final da sua assinatura atual.                     │
└─────────────────────────────────────────────────────────┘

┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Teste Gratuito │  │  Plano Mensal   │  │  Plano Anual    │
│  [Já Utilizado] │  │  [Selecionar]✅ │  │  [Selecionar]✅ │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### **2. Clicar em "Selecionar Plano"**

- ✅ Permite selecionar qualquer plano (exceto trial se já usado)
- ✅ Mostra alerta informativo
- ✅ Processa renovação normalmente

### **3. Após Renovar**

```
Assinatura renovada com sucesso!

Antes:  Expira em 30/10/2025 (11 dias)
Depois: Expira em 29/11/2025 (41 dias)

✅ Você ganhou mais 30 dias!
```

---

## 🔧 Implementação

### **Frontend (SubscriptionPlans.tsx)**

#### **Antes:**
```typescript
// Bloqueava acesso se já tivesse assinatura ativa
useEffect(() => {
  if (isSubscriptionActive) {
    toast.info('Você já possui uma assinatura ativa!');
    navigate('/admin');
  }
}, [isSubscriptionActive, navigate]);
```

#### **Depois:**
```typescript
// REMOVIDO: Permite renovação antecipada
// Usuários com assinatura ativa podem acessar /planos

// Mostra alerta informativo
{isSubscriptionActive && (
  <Alert>
    <AlertCircle className="h-4 w-4" />
    <AlertDescription>
      Você já possui uma assinatura ativa ({subscription?.plan_name} - {subscription?.days_remaining} dias restantes).
      Ao renovar agora, o novo período será adicionado ao final da sua assinatura atual.
    </AlertDescription>
  </Alert>
)}
```

---

### **Backend (subscriptionService.ts)**

#### **Lógica de Renovação:**

```typescript
// Verificar se usuário já tem assinatura ativa
const currentSubscription = await this.getActiveSubscription(userId);

// Calcular data de expiração
let expiresAt = new Date();

if (currentSubscription && currentSubscription.status === 'active' && currentSubscription.days_remaining > 0) {
  // Se tem assinatura ativa, adicionar novo período ao final
  expiresAt = new Date(currentSubscription.expires_at);
  console.log('Assinatura ativa encontrada, adicionando ao final:', expiresAt);
}

expiresAt.setDate(expiresAt.getDate() + plan.duration_days);
```

---

### **Banco de Dados (Função SQL)**

#### **Função: create_subscription_with_renewal**

```sql
CREATE FUNCTION public.create_subscription_with_renewal(
  _user_id UUID,
  _plan_id UUID
)
RETURNS UUID
```

**Lógica:**
1. Busca assinatura ativa atual
2. Se existe:
   - Calcula nova data: `expires_at_atual + duração_do_plano`
   - Atualiza assinatura existente
3. Se não existe:
   - Cria nova assinatura
   - Data de expiração: `NOW() + duração_do_plano`

---

## 🧪 Exemplos de Uso

### **Exemplo 1: Renovar Plano Mensal**

**Situação Atual:**
- Plano: Mensal (30 dias)
- Expira em: 30/10/2025
- Dias restantes: 11

**Ação:** Renovar com Plano Mensal (30 dias)

**Resultado:**
- Nova data de expiração: 29/11/2025
- Total de dias: 41 dias
- Mensagem: "Assinatura renovada! Você ganhou mais 30 dias."

---

### **Exemplo 2: Upgrade de Mensal para Anual**

**Situação Atual:**
- Plano: Mensal (30 dias)
- Expira em: 30/10/2025
- Dias restantes: 11

**Ação:** Renovar com Plano Anual (365 dias)

**Resultado:**
- Nova data de expiração: 29/10/2026
- Total de dias: 376 dias (11 + 365)
- Mensagem: "Assinatura renovada! Você ganhou mais 365 dias."

---

### **Exemplo 3: Primeira Assinatura**

**Situação Atual:**
- Sem assinatura

**Ação:** Escolher Plano Mensal (30 dias)

**Resultado:**
- Data de expiração: 18/11/2025 (hoje + 30 dias)
- Total de dias: 30 dias
- Mensagem: "Plano ativado com sucesso!"

---

## 📊 Comparação: Antes vs Depois

| Situação | Antes | Depois |
|----------|-------|--------|
| **Usuário com assinatura ativa tenta renovar** | ❌ Bloqueado, redireciona para /admin | ✅ Permitido, adiciona ao final |
| **Dias restantes** | Perdidos ao renovar | ✅ Mantidos + novo período |
| **Mensagem** | "Você já possui assinatura ativa!" | ℹ️ "Novo período será adicionado ao final" |
| **Flexibilidade** | Baixa | ✅ Alta |

---

## 🎯 Casos de Uso

### **Caso 1: Renovação de Segurança**
Usuário com 20 dias restantes quer garantir que não vai esquecer de renovar.
- ✅ Pode renovar agora
- ✅ Ganha mais 30 dias (total: 50 dias)

### **Caso 2: Upgrade Antecipado**
Usuário com plano mensal quer mudar para anual antes de expirar.
- ✅ Pode fazer upgrade agora
- ✅ Não perde dias restantes do plano atual

### **Caso 3: Promoção Limitada**
Usuário vê promoção de plano anual e quer aproveitar antes que acabe.
- ✅ Pode comprar agora
- ✅ Novo período começa após o atual

---

## 🛡️ Proteção de Trial

**Importante:** O teste gratuito continua sendo **único por conta**.

- ✅ Se já usou trial, não pode usar novamente
- ✅ Badge "Já Utilizado" aparece
- ✅ Botão desabilitado
- ✅ Pode renovar com planos pagos

---

## 📝 Mensagens ao Usuário

### **Alerta Informativo (Assinatura Ativa):**
```
ℹ️ Você já possui uma assinatura ativa (Plano Mensal - 11 dias restantes).
   Ao renovar agora, o novo período será adicionado ao final da sua assinatura atual.
```

### **Alerta de Expiração:**
```
⚠️ Seu plano Plano Mensal expirou.
   Escolha um novo plano para continuar usando o sistema.
```

### **Sucesso ao Renovar:**
```
✅ Assinatura renovada com sucesso!
   Sua nova data de expiração é 29/11/2025.
```

---

## 🔄 Fluxo Completo

```
Usuário com assinatura ativa (11 dias restantes)
         │
         ▼
Clica em "Renovar Assinatura" no dashboard
         │
         ▼
Redireciona para /planos
         │
         ▼
Vê alerta: "Novo período será adicionado ao final"
         │
         ▼
Escolhe plano (Mensal, Anual, etc.)
         │
         ▼
Confirma pagamento (se plano pago)
         │
         ▼
Sistema calcula: expires_at_atual + duração_do_plano
         │
         ▼
Atualiza assinatura no banco
         │
         ▼
Mostra sucesso: "Você ganhou mais X dias!"
         │
         ▼
Redireciona para /admin/subscription
         │
         ▼
Dashboard mostra nova data de expiração
```

---

## ✅ Benefícios

1. **Flexibilidade** - Usuário renova quando quiser
2. **Sem Perda** - Dias restantes são mantidos
3. **Segurança** - Não precisa esperar expirar
4. **Upgrade Fácil** - Pode mudar de plano a qualquer momento
5. **Promoções** - Pode aproveitar ofertas sem perder tempo

---

## 🧪 Testes

### **Teste 1: Renovar com Assinatura Ativa**

1. Ter assinatura ativa com 10 dias restantes
2. Acessar `/planos`
3. Ver alerta informativo
4. Escolher plano de 30 dias
5. Confirmar renovação
6. Verificar nova data: atual + 30 dias

**Resultado esperado:** ✅ 40 dias totais

---

### **Teste 2: Primeira Assinatura**

1. Não ter assinatura
2. Acessar `/planos`
3. Não ver alerta
4. Escolher plano de 30 dias
5. Confirmar ativação
6. Verificar data: hoje + 30 dias

**Resultado esperado:** ✅ 30 dias totais

---

### **Teste 3: Trial Já Usado**

1. Ter usado trial anteriormente
2. Ter assinatura ativa
3. Acessar `/planos`
4. Ver trial com badge "Já Utilizado"
5. Trial desabilitado
6. Planos pagos habilitados

**Resultado esperado:** ✅ Pode renovar com planos pagos

---

## 📚 Arquivos Modificados

1. **src/pages/subscription/SubscriptionPlans.tsx**
   - Removido bloqueio de acesso
   - Adicionado alerta informativo

2. **src/services/subscriptionService.ts**
   - Modificado `createSubscription` para adicionar ao final

3. **Banco de Dados (Migration)**
   - Criada função `create_subscription_with_renewal`

---

## 🎉 Resultado Final

Agora os usuários podem:
- ✅ Renovar antecipadamente
- ✅ Fazer upgrade a qualquer momento
- ✅ Não perder dias restantes
- ✅ Aproveitar promoções
- ✅ Ter mais controle sobre suas assinaturas

---

**Data de implementação:** 19 de outubro de 2025  
**Versão:** 2.1  
**Status:** ✅ Implementado e testado
