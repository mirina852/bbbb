# 🍔 Webhook para Cardápio Online - Pagamentos PIX

## ✅ Webhook Criado e Implantado!

**URL do Webhook de Pedidos:**
```
https://glzkaxpjwabwufzevkmt.supabase.co/functions/v1/pedido-webhook
```

## 🚀 Como Configurar no Mercado Pago

### 1. Acessar Painel do Mercado Pago
- Faça login em [mercadopago.com.br](https://www.mercadopago.com.br/)
- Vá para **"Desenvolvedores"** → **"Webhooks"**

### 2. Adicionar Novo Webhook
- **URL**: `https://glzkaxpjwabwufzevkmt.supabase.co/functions/v1/pedido-webhook`
- **Eventos**:
  - ✅ `payment.created`
  - ✅ `payment.updated`
  - ✅ `payment.approved`

### 3. Salvar e Testar
- Clique em "Salvar"
- Use "Testar webhook" para verificar

## 🔄 Como Funciona

### Fluxo do Pedido:
1. **Cliente** → Faz pedido no cardápio online
2. **Sistema** → Gera pagamento PIX via `create-pix-payment`
3. **Cliente** → Paga o PIX
4. **Mercado Pago** → Envia notificação para `pedido-webhook`
5. **Webhook** → Atualiza status do pedido para "confirmed"

### O que o Webhook Faz:
- ✅ **Busca o pedido** pelo `external_payment_id`
- ✅ **Verifica status** no Mercado Pago
- ✅ **Atualiza pedido** para "confirmed" se aprovado
- ✅ **Registra logs** para debugging

## 📋 Estrutura das Tabelas

### Orders (Pedidos)
```sql
orders {
  id: UUID
  store_id: UUID
  customer_name: TEXT
  payment_status: TEXT  -- pending, approved, rejected
  status: TEXT         -- pending, confirmed, cancelled
  external_payment_id: TEXT  -- ID do Mercado Pago
  created_at: TIMESTAMP
  updated_at: TIMESTAMP
}
```

### Merchant Credentials (Credenciais da Loja)
```sql
merchant_payment_credentials {
  id: UUID
  store_id: UUID
  access_token: TEXT
  public_key: TEXT
  is_active: BOOLEAN
}
```

## 🧪 Testar Webhook

### Health Check:
```bash
curl https://glzkaxpjwabwufzevkmt.supabase.co/functions/v1/pedido-webhook
```
Resposta: `Webhook de Pedidos Online ativo`

### Simular Pagamento:
1. Crie um pedido de teste
2. Gere pagamento PIX
3. Simule aprovação no Mercado Pago
4. Verifique se o pedido é atualizado

## 📱 Notificações (Opcional)

Você pode estender o webhook para enviar:
- 📧 Email de confirmação para cliente
- 📱 Push notification para loja
- 📦 Atualização de estoque
- 🎫 Notificação na cozinha

## 🔧 Diferenças Entre os Webhooks

| Webhook | Finalidade | URL |
|---------|------------|-----|
| `mercado-pago-webhook` | Assinaturas (planos) | `/functions/v1/mercado-pago-webhook` |
| `pedido-webhook` | Pedidos do cardápio | `/functions/v1/pedido-webhook` |

## 🎯 Pronto!

Agora seu cardápio online tem um webhook dedicado para processar pagamentos PIX automaticamente! 🍕✨

Quando um cliente pagar o PIX, o pedido será confirmado instantaneamente.
