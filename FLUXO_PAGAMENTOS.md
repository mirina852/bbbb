# 🔄 Fluxo de Pagamentos - Arquitetura

## 📋 Visão Geral

Este sistema possui **dois tipos de pagamentos** com fluxos distintos:

### 1️⃣ Pagamento de Assinatura (Usuário → Plataforma)
**Quem paga:** Usuário/Lojista que quer usar o sistema  
**Quem recebe:** Você (dono da plataforma SaaS)  
**Credenciais usadas:** Suas credenciais do Mercado Pago (configuradas nas variáveis de ambiente)

### 2️⃣ Pagamento de Pedidos (Cliente → Lojista)
**Quem paga:** Cliente final do lojista  
**Quem recebe:** Lojista (usuário do seu sistema)  
**Credenciais usadas:** Credenciais do lojista (cadastradas em Configurações > Pagamento)

---

## 🚀 Fluxo Completo do Usuário

### Passo 1: Escolher Plano (SEM assinatura)
```
┌─────────────────────────────────────┐
│  Usuário acessa /planos             │
│  - Vê planos disponíveis            │
│  - Escolhe um plano                 │
│  - Clica em "Assinar"               │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Sistema gera pagamento PIX         │
│  - Usa SUAS credenciais             │
│  - Mostra QR Code                   │
│  - Aguarda confirmação              │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Pagamento confirmado               │
│  - Assinatura ativada               │
│  - Usuário redireciona para /admin  │
└─────────────────────────────────────┘
```

### Passo 2: Configurar Mercado Pago (COM assinatura ativa)
```
┌─────────────────────────────────────┐
│  Usuário acessa Configurações       │
│  - Vai em "Pagamento"               │
│  - Vê formulário desbloqueado       │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Usuário adiciona credenciais       │
│  - Public Key do Mercado Pago       │
│  - Access Token do Mercado Pago     │
│  - Salva configurações              │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Sistema armazena no banco          │
│  - Tabela: merchant_payment_creds   │
│  - Vinculado ao user_id             │
└─────────────────────────────────────┘
```

### Passo 3: Receber Pagamentos dos Clientes
```
┌─────────────────────────────────────┐
│  Cliente acessa loja do usuário     │
│  - Adiciona produtos ao carrinho    │
│  - Finaliza pedido                  │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Sistema gera pagamento PIX         │
│  - Usa credenciais DO LOJISTA       │
│  - Dinheiro cai na conta do lojista │
└─────────────────────────────────────┘
```

---

## 🔐 Proteções Implementadas

### ✅ Página de Configuração de Pagamento
**Arquivo:** `src/components/payment/MercadoPagoConfig.tsx`

```typescript
// Verifica se usuário tem assinatura ativa
if (!subscription || !isSubscriptionActive) {
  // Mostra tela bloqueada
  // Botão: "Ver Planos Disponíveis"
}
```

**Comportamento:**
- ❌ **SEM assinatura:** Formulário bloqueado, mensagem explicativa
- ✅ **COM assinatura:** Formulário liberado para cadastrar credenciais

### ✅ Função de Pagamento de Assinatura
**Arquivo:** `supabase/functions/create-pix-payment/index.ts`

```typescript
// Usa credenciais da PLATAFORMA (não do usuário)
const PLATFORM_MERCADOPAGO_TOKEN = Deno.env.get("MERCADOPAGO_ACCESS_TOKEN");
```

**Comportamento:**
- Não busca credenciais do usuário
- Usa variáveis de ambiente do sistema
- Pagamento cai na conta da plataforma

---

## ⚙️ Configuração das Variáveis de Ambiente

### Para Desenvolvimento Local
Arquivo: `.env`

```bash
# Suas credenciais (dono da plataforma)
VITE_MERCADOPAGO_PUBLIC_KEY=APP_USR-xxxxxxxx
VITE_MERCADOPAGO_ACCESS_TOKEN=APP_USR-xxxxxxxx
```

### Para Produção (Supabase)
Painel do Supabase > Edge Functions > Secrets

```bash
MERCADOPAGO_ACCESS_TOKEN=APP_USR-xxxxxxxx
MERCADOPAGO_PUBLIC_KEY=APP_USR-xxxxxxxx
```

---

## 📊 Tabelas do Banco de Dados

### `subscription_payments`
Armazena pagamentos de **assinaturas** (usuário → plataforma)

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | UUID | ID do pagamento |
| user_id | UUID | Usuário que está pagando |
| plan_id | UUID | Plano escolhido |
| amount | DECIMAL | Valor pago |
| status | TEXT | pending, approved, expired |
| qr_code | TEXT | QR Code PIX |

### `merchant_payment_credentials`
Armazena credenciais dos **lojistas** (para receber de clientes)

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | UUID | ID da credencial |
| user_id | UUID | Lojista dono da credencial |
| public_key | TEXT | Public Key do Mercado Pago |
| access_token | TEXT | Access Token do Mercado Pago |
| is_active | BOOLEAN | Se está ativa |

---

## 🎯 Resumo

### Antes (❌ Problema)
- Usuário precisava configurar Mercado Pago ANTES de pagar assinatura
- Não fazia sentido: como ele vai pagar se não tem acesso?

### Agora (✅ Solução)
1. **Primeiro:** Usuário paga assinatura (usando SUAS credenciais)
2. **Depois:** Usuário ganha acesso ao painel
3. **Por último:** Usuário configura Mercado Pago dele (para receber dos clientes)

### Benefícios
- ✅ Fluxo lógico e intuitivo
- ✅ Usuário não precisa ter Mercado Pago para testar
- ✅ Separação clara: assinaturas vs. pagamentos de clientes
- ✅ Você (plataforma) recebe as assinaturas
- ✅ Lojistas recebem pagamentos dos clientes deles
