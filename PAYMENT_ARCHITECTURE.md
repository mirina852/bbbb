# 💰 Arquitetura de Pagamentos

Este documento explica como funcionam os **dois fluxos de pagamento separados** no sistema.

---

## 🎯 Visão Geral

O sistema possui **dois tipos de pagamento completamente independentes**:

### 1. 💳 Pagamento de Assinaturas (Plataforma)
- **Quem paga**: Dono do negócio (lojista)
- **Para quem**: Plataforma (você)
- **Token usado**: Credenciais da **plataforma** (configuradas em `.env`)
- **Destino do dinheiro**: Conta Mercado Pago da **plataforma**

### 2. 🛒 Pagamento de Pedidos (Lojista)
- **Quem paga**: Cliente final (consumidor)
- **Para quem**: Dono do negócio (lojista)
- **Token usado**: Credenciais do **lojista** (configuradas no painel admin)
- **Destino do dinheiro**: Conta Mercado Pago do **lojista**

---

## 📁 Estrutura de Arquivos

```
src/
├── contexts/
│   └── MercadoPagoContext.tsx          # Gerencia credenciais do LOJISTA
│
├── services/
│   ├── platformPaymentService.ts       # Pagamentos de ASSINATURAS (plataforma)
│   └── merchantPaymentService.ts       # Pagamentos de PEDIDOS (lojista)
│
├── components/
│   ├── payment/
│   │   └── MercadoPagoConfig.tsx       # Página para lojista configurar suas credenciais
│   ├── subscription/
│   │   └── SubscriptionPaymentButton.tsx  # Botão para pagar assinatura
│   └── checkout/
│       └── OrderPaymentButton.tsx      # Botão para cliente pagar pedido
│
└── pages/
    └── admin/
        └── Settings.tsx                # Aba "Pagamentos" para configurar MP
```

---

## 🔧 Configuração

### 1. Credenciais da Plataforma (Assinaturas)

Crie um arquivo `.env` na raiz do projeto:

```env
# Suas credenciais do Mercado Pago (plataforma)
VITE_MERCADOPAGO_PUBLIC_KEY=APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
VITE_MERCADOPAGO_ACCESS_TOKEN=APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

**Onde obter:**
1. Acesse https://www.mercadopago.com.br/developers
2. Vá em "Suas integrações" > "Credenciais"
3. Copie a Public Key e o Access Token

### 2. Credenciais do Lojista (Pedidos)

O lojista configura suas próprias credenciais:
1. Acessa o painel admin
2. Vai em **Configurações** > **Pagamentos**
3. Insere sua Public Key e Access Token
4. Salva as configurações

---

## 🔄 Fluxo de Pagamento

### Fluxo 1: Assinatura (Plataforma → Você)

```
1. Lojista escolhe um plano em /planos
2. Clica em "Assinar"
3. Sistema usa platformPaymentService.ts
4. Usa token da PLATAFORMA (.env)
5. Cria pagamento no Mercado Pago
6. Dinheiro cai na conta da PLATAFORMA
7. Sistema ativa assinatura do lojista
```

**Código:**
```tsx
import { createSubscriptionPayment } from '@/services/platformPaymentService';

const payment = await createSubscriptionPayment({
  planId: 'monthly',
  planName: 'Plano Mensal',
  amount: 99.90,
  userId: user.id,
  userEmail: user.email
});
```

### Fluxo 2: Pedido (Cliente → Lojista)

```
1. Cliente adiciona produtos ao carrinho
2. Vai para checkout
3. Preenche dados e clica em "Finalizar Pedido"
4. Sistema usa merchantPaymentService.ts
5. Usa token do LOJISTA (MercadoPagoContext)
6. Cria pagamento no Mercado Pago
7. Dinheiro cai na conta do LOJISTA
8. Sistema registra o pedido
```

**Código:**
```tsx
import { createOrderPayment } from '@/services/merchantPaymentService';
import { useMercadoPago } from '@/contexts/MercadoPagoContext';

const { config } = useMercadoPago();

const payment = await createOrderPayment(
  {
    orderId: 'ORD-123',
    amount: 150.00,
    items: [...],
    customerEmail: 'cliente@email.com',
    customerName: 'João Silva'
  },
  config.accessToken  // Token do LOJISTA
);
```

---

## 🎨 Componentes Prontos

### SubscriptionPaymentButton
Botão para pagamento de assinatura (usa token da plataforma):

```tsx
import SubscriptionPaymentButton from '@/components/subscription/SubscriptionPaymentButton';

<SubscriptionPaymentButton
  planId="monthly"
  planName="Plano Mensal"
  amount={99.90}
  onSuccess={() => console.log('Assinatura ativada!')}
/>
```

### OrderPaymentButton
Botão para pagamento de pedido (usa token do lojista):

```tsx
import OrderPaymentButton from '@/components/checkout/OrderPaymentButton';

<OrderPaymentButton
  customerEmail="cliente@email.com"
  customerName="João Silva"
  onSuccess={(paymentId) => console.log('Pedido pago!', paymentId)}
/>
```

---

## 🔒 Segurança

### ✅ Boas Práticas Implementadas

1. **Separação de credenciais**: Tokens da plataforma e lojista são completamente separados
2. **Variáveis de ambiente**: Token da plataforma nunca é exposto no código
3. **Context API**: Credenciais do lojista gerenciadas de forma centralizada
4. **Validação**: Sistema verifica se lojista configurou MP antes de permitir vendas

### ⚠️ Importante

- **NUNCA** commite o arquivo `.env` no Git
- **NUNCA** exponha o Access Token no frontend
- Use o Access Token **apenas no backend** para operações sensíveis
- A Public Key pode ser usada no frontend

---

## 🚀 Próximos Passos

### Backend (TODO)

1. Criar endpoints para salvar/buscar credenciais do lojista:
   - `POST /api/merchant/mercadopago-config`
   - `GET /api/merchant/mercadopago-config`

2. Implementar webhooks do Mercado Pago:
   - `POST /api/webhooks/mercadopago/subscription` (assinaturas)
   - `POST /api/webhooks/mercadopago/order` (pedidos)

3. Validar credenciais do Mercado Pago antes de salvar

4. Criptografar Access Tokens no banco de dados

### Frontend (TODO)

1. Integrar SDK do Mercado Pago para checkout transparente
2. Adicionar suporte a diferentes métodos de pagamento (PIX, cartão, boleto)
3. Implementar página de confirmação de pagamento
4. Adicionar histórico de transações

---

## 📚 Documentação Mercado Pago

- [Documentação Oficial](https://www.mercadopago.com.br/developers/pt/docs)
- [SDK JavaScript](https://www.mercadopago.com.br/developers/pt/docs/checkout-api/integration-configuration/integrate-with-javascript)
- [Webhooks](https://www.mercadopago.com.br/developers/pt/docs/your-integrations/notifications/webhooks)

---

## 💡 Exemplo Completo

### Página de Planos (Assinatura)

```tsx
import SubscriptionPaymentButton from '@/components/subscription/SubscriptionPaymentButton';

const SubscriptionPlans = () => {
  return (
    <div className="grid grid-cols-3 gap-6">
      <Card>
        <CardHeader>
          <CardTitle>Plano Mensal</CardTitle>
          <CardDescription>R$ 99,90/mês</CardDescription>
        </CardHeader>
        <CardContent>
          <SubscriptionPaymentButton
            planId="monthly"
            planName="Plano Mensal"
            amount={99.90}
          />
        </CardContent>
      </Card>
    </div>
  );
};
```

### Checkout (Pedido)

```tsx
import OrderPaymentButton from '@/components/checkout/OrderPaymentButton';

const Checkout = () => {
  const [email, setEmail] = useState('');
  const [name, setName] = useState('');

  return (
    <div>
      <Input
        placeholder="Seu email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
      />
      <Input
        placeholder="Seu nome"
        value={name}
        onChange={(e) => setName(e.target.value)}
      />
      <OrderPaymentButton
        customerEmail={email}
        customerName={name}
      />
    </div>
  );
};
```

---

## ❓ FAQ

**P: O lojista precisa ter conta no Mercado Pago?**  
R: Sim, cada lojista precisa ter sua própria conta para receber os pagamentos dos clientes.

**P: Eu (plataforma) recebo alguma comissão dos pedidos?**  
R: Não diretamente. Você recebe apenas o valor da assinatura. Se quiser comissão, implemente um sistema de split payment.

**P: Posso usar outro gateway de pagamento?**  
R: Sim! Basta criar novos serviços seguindo o mesmo padrão (platformPaymentService e merchantPaymentService).

**P: Como testar sem credenciais reais?**  
R: Use as credenciais de teste do Mercado Pago disponíveis no painel de desenvolvedor.
