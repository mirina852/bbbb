# Configuração do Webhook do Mercado Pago

## URL do Webhook

Configure no painel do Mercado Pago a seguinte URL:

```
https://bckitzkupgkagzswaidb.supabase.co/functions/v1/mercado-pago-webhook
```

## Passos para Configurar

1. Acesse: https://www.mercadopago.com.br/developers/panel/app
2. Selecione sua aplicação
3. Vá em **Webhooks** ou **Notificações IPN**
4. Clique em **Configurar notificações**
5. Cole a URL do webhook acima
6. Ative os eventos:
   - ✅ `payment.created`
   - ✅ `payment.updated`
7. Salve as configurações

## Como Funciona

### Pagamentos de Assinatura
Quando um usuário paga uma assinatura via PIX:
1. O pagamento é criado com `metadata.type = "subscription"`
2. Mercado Pago notifica o webhook quando o status muda
3. O webhook atualiza `subscription_payments` e cria/estende `user_subscriptions`

### Pagamentos de Pedidos
Quando um cliente paga um pedido via PIX:
1. O pagamento é criado com `metadata.type = "order"` e `metadata.order_id`
2. Mercado Pago notifica o webhook quando o status muda
3. O webhook atualiza `orders.payment_status` para "approved", "pending", etc.

## Testar o Webhook

Você pode testar se o webhook está funcionando acessando:

```
GET https://bckitzkupgkagzswaidb.supabase.co/functions/v1/mercado-pago-webhook
```

Deve retornar: "Webhook ativo"

## Status Possíveis

- `pending` - Aguardando pagamento
- `approved` - Pagamento aprovado
- `rejected` - Pagamento rejeitado
- `cancelled` - Pagamento cancelado
- `in_process` - Em processamento

## Solução de Problemas

Se os pagamentos não estão sendo atualizados:

1. Verifique se a URL do webhook está correta no painel do MP
2. Verifique se os eventos `payment.created` e `payment.updated` estão ativos
3. Consulte os logs da Edge Function no Supabase
