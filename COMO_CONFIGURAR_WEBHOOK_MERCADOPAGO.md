# 🚀 Como Configurar o Webhook do Mercado Pago

## Passo 1: Obter a URL do Webhook

A URL do seu webhook é:
```
https://glzkaxpjwabwufzevkmt.supabase.co/functions/v1/mercado-pago-webhook
```

## Passo 2: Acessar o Painel do Mercado Pago

1. Faça login no [Mercado Pago](https://www.mercadopago.com.br/)
2. Vá para **"Desenvolvedores"** no menu lateral
3. Clique em **"Webhooks"** ou **"Notificações"**

## Passo 3: Configurar o Webhook

### 3.1. Adicionar URL do Webhook
- **URL de produção**: `https://glzkaxpjwabwufzevkmt.supabase.co/functions/v1/mercado-pago-webhook`
- **URL de teste**: `https://glzkaxpjwabwufzevkmt.supabase.co/functions/v1/mercado-pago-webhook`

### 3.2. Configurar Eventos
Selecione os seguintes eventos para receber notificações:
- ✅ **payment.created** - Quando um pagamento é criado
- ✅ **payment.updated** - Quando o status do pagamento muda
- ✅ **payment.approved** - Quando o pagamento é aprovado
- ✅ **payment.rejected** - Quando o pagamento é rejeitado
- ✅ **payment.cancelled** - Quando o pagamento é cancelado

### 3.3. Configurar Segurança (Opcional)
- Você pode configurar um **Bearer Token** para segurança adicional
- O webhook já está configurado para aceitar requisições públicas

## Passo 4: Testar o Webhook

### 4.1. Teste de Saúde
Faça uma requisição GET para verificar se está ativo:
```bash
curl https://glzkaxpjwabwufzevkmt.supabase.co/functions/v1/mercado-pago-webhook
```
Resposta esperada: `Webhook ativo`

### 4.2. Simular Notificação
Use o painel do Mercado Pago para enviar uma notificação de teste.

## Passo 5: Verificar Logs

Para verificar se está funcionando, acesse os logs da Edge Function:
1. Vá ao painel do Supabase
2. Clique em **"Edge Functions"**
3. Selecione `mercado-pago-webhook`
4. Veja os logs em tempo real

## 📋 Estrutura do Webhook

O webhook espera receber notificações neste formato:

```json
{
  "action": "payment.updated",
  "data": {
    "id": "123456789"
  },
  "date_created": "2026-03-02T19:00:00Z",
  "type": "payment"
}
```

## 🔧 O que o Webhook Faz

### Para Pagamentos de Assinatura:
1. ✅ Atualiza status do pagamento em `subscription_payments`
2. ✅ Se aprovado, cria/atualiza assinatura em `user_subscriptions`
3. ✅ Define período de acesso (30 dias padrão)

### Para Pagamentos de Pedidos:
1. ✅ Atualiza status do pagamento em `orders`
2. ✅ Marca como `approved`, `pending`, `rejected`, etc.

## 🚨 Importante

- **URL do Webhook**: `https://glzkaxpjwabwufzevkmt.supabase.co/functions/v1/mercado-pago-webhook`
- **Método**: POST
- **Content-Type**: application/json
- **Resposta esperada**: Status 200 com qualquer conteúdo

## 🔄 Fluxo Completo

1. **Cliente** → Escolhe plano → Faz pagamento PIX
2. **create-pix-payment** → Cria pagamento no Mercado Pago
3. **Mercado Pago** → Processa pagamento → Envia webhook
4. **mercado-pago-webhook** → Recebe notificação → Ativa assinatura
5. **Sistema** → Cliente ganha acesso ao plano

---

## 🎯 Pronto!

Após configurar o webhook, todos os pagamentos serão processados automaticamente e as assinaturas serão ativadas instantaneamente quando aprovadas.
