# 🎁 Teste Gratuito - Como Funciona

## 🎯 Objetivo

O plano **Teste Gratuito** deve ser ativado **instantaneamente**, sem necessidade de pagamento PIX.

---

## ✅ Fluxo Implementado

### Para Planos GRATUITOS (Trial ou R$ 0,00)

```
┌─────────────────────────────────────┐
│  Usuário clica em                   │
│  "Iniciar Teste Gratuito"           │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Sistema detecta:                   │
│  - is_trial = true OU               │
│  - price = 0                        │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Cria assinatura DIRETAMENTE        │
│  - Sem pagamento                    │
│  - Status: active                   │
│  - Expira em: +7 dias (trial)       │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Mostra mensagem:                   │
│  "Plano ativado com sucesso!"       │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Redireciona para /admin            │
│  - Usuário já tem acesso total      │
└─────────────────────────────────────┘
```

### Para Planos PAGOS (Mensal, Anual)

```
┌─────────────────────────────────────┐
│  Usuário clica em                   │
│  "Selecionar Plano"                 │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Sistema detecta:                   │
│  - price > 0                        │
│  - is_trial = false                 │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Cria pagamento PIX                 │
│  - Mostra QR Code                   │
│  - Aguarda confirmação              │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Pagamento confirmado               │
│  - Assinatura ativada               │
│  - Redireciona para /admin          │
└─────────────────────────────────────┘
```

---

## 🔧 Código Implementado

### Arquivo: `src/pages/subscription/SubscriptionPlans.tsx`

```typescript
const handleSelectPlan = async (planId: string) => {
  // ... validações ...

  const plan = plans.find(p => p.id === planId);
  if (!plan) return;

  setIsSelecting(true);
  try {
    // ✅ Se for plano GRATUITO, ativar direto
    if (plan.is_trial || plan.price === 0) {
      console.log('Plano gratuito detectado, ativando direto:', planId);
      
      await subscriptionService.createSubscription(user.id, planId);
      await refreshSubscription();
      
      toast.success('Plano ativado com sucesso! Bem-vindo!');
      
      setTimeout(() => navigate('/admin'), 1000);
      return;
    }

    // ❌ Se for plano PAGO, criar pagamento PIX
    const payment = await subscriptionService.createPayment(user.id, planId);
    
    setPaymentData(payment);
    setSelectedPlan(plan);
    setShowPixPayment(true);
  } catch (error: any) {
    toast.error(error.message || 'Erro ao processar');
  } finally {
    setIsSelecting(false);
  }
};
```

---

## 🧪 Testando

### Teste 1: Plano Gratuito

1. **Acesse:** http://localhost:3000/planos
2. **Clique em:** "Iniciar Teste Gratuito" (plano Trial)
3. **Verifique:**
   - ✅ NÃO mostra QR Code PIX
   - ✅ Mostra toast: "Plano ativado com sucesso!"
   - ✅ Redireciona para /admin em 1 segundo
   - ✅ Dashboard carrega normalmente
   - ✅ Assinatura aparece como ativa

### Teste 2: Plano Pago

1. **Acesse:** http://localhost:3000/planos
2. **Clique em:** "Selecionar Plano" (Mensal ou Anual)
3. **Verifique:**
   - ✅ Mostra QR Code PIX
   - ✅ Aguarda pagamento
   - ✅ Só redireciona após confirmação

---

## 📊 Banco de Dados

### Registro Criado para Teste Gratuito

Tabela: `user_subscriptions`

| Campo | Valor |
|-------|-------|
| user_id | UUID do usuário |
| plan_id | UUID do plano trial |
| status | `active` |
| expires_at | Data atual + 7 dias |
| created_at | Timestamp atual |

**Não cria registro em:** `subscription_payments` (porque não houve pagamento)

### Registro Criado para Plano Pago

Tabela: `subscription_payments`

| Campo | Valor |
|-------|-------|
| user_id | UUID do usuário |
| plan_id | UUID do plano |
| amount | Valor do plano |
| status | `pending` → `approved` |
| qr_code | Código PIX |

**Depois cria em:** `user_subscriptions` (após pagamento aprovado)

---

## 🎯 Vantagens

### Para o Usuário
- ✅ Experiência instantânea no teste gratuito
- ✅ Sem fricção para experimentar o sistema
- ✅ Pode testar antes de pagar

### Para a Plataforma
- ✅ Maior conversão (menos barreiras)
- ✅ Usuários testam o produto facilmente
- ✅ Fluxo claro entre gratuito e pago

---

## 🔍 Verificação

### Como Saber se Funcionou?

1. **Console do navegador (F12):**
   ```
   Plano gratuito detectado, ativando direto: [uuid]
   subscriptionService.createSubscription chamado: {...}
   Plano encontrado: {...}
   Criando assinatura com expiração: 2025-10-17...
   Assinatura criada com sucesso: {...}
   ```

2. **Banco de dados (Supabase):**
   - Tabela `user_subscriptions` tem novo registro
   - Status = `active`
   - `expires_at` = 7 dias no futuro

3. **Interface:**
   - Toast verde: "Plano ativado com sucesso!"
   - Redirecionamento automático para /admin
   - Dashboard carrega sem erros

---

## ❓ Troubleshooting

### Erro: "Erro ao criar assinatura"

**Causa:** Problema ao inserir no banco

**Solução:**
1. Verifique se a tabela `user_subscriptions` existe
2. Confirme que o `plan_id` é válido
3. Veja os logs do console para detalhes

### Erro: "Plano não encontrado"

**Causa:** `plan_id` não existe na tabela `subscription_plans`

**Solução:**
1. Execute o SQL para popular planos (veja `CONFIGURACAO_INICIAL.md`)
2. Verifique se os planos aparecem na página

### Ainda mostra QR Code para teste gratuito

**Causa:** Plano não está marcado como trial ou preço não é 0

**Solução:**
1. Verifique no banco: `SELECT * FROM subscription_plans WHERE slug = 'trial'`
2. Confirme: `is_trial = true` E `price = 0`
3. Se necessário, atualize:
   ```sql
   UPDATE subscription_plans 
   SET is_trial = true, price = 0 
   WHERE slug = 'trial';
   ```

---

## 📝 Resumo

- ✅ Teste gratuito ativa instantaneamente
- ✅ Planos pagos mostram QR Code PIX
- ✅ Fluxo diferenciado e intuitivo
- ✅ Sem fricção para novos usuários
