# 🔐 Configuração de Assinatura Secreta do Webhook Mercado Pago

## Assinatura Secreta Recebida:
```
253f99545037c212cdab6e18365015fd7ebb470e51637eef0e749795666a9837
```

## O que é isso?
É uma **assinatura secreta (HMAC-SHA256)** que o Mercado Pago usa para assinar as notificações do webhook. Isso garante que:
- ✅ A notificação veio realmente do Mercado Pago
- ✅ O conteúdo não foi alterado
- ❌ Impede chamadas falsas ao webhook

## Como implementar:

### 1. Adicionar às variáveis de ambiente
No painel do Supabase, adicionar:
```
MERCADO_PAGO_WEBHOOK_SECRET=253f99545037c212cdab6e18365015fd7ebb470e51637eef0e749795666a9837
```

### 2. Implementar verificação nos webhooks
Nos webhooks `pedido-webhook` e `mercado-pago-webhook`, adicionar:

```typescript
// Verificar assinatura do webhook
const signature = req.headers.get("x-signature");
const timestamp = req.headers.get("x-request-id");
const secret = Deno.env.get("MERCADO_PAGO_WEBHOOK_SECRET");

if (signature && secret) {
  const computedSignature = await crypto.subtle.sign(
    "HMAC",
    await crypto.subtle.importKey(
      "raw",
      new TextEncoder().encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    ),
    new TextEncoder().encode(timestamp + JSON.stringify(body))
  );
  
  const expectedSignature = Array.from(new Uint8Array(computedSignature))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
    
  if (signature !== expectedSignature) {
    return new Response("Assinatura inválida", { status: 401 });
  }
}
```

### 3. Configurar no Mercado Pago
No painel do Mercado Pago, configurar:
- **Webhook URL**: `https://glzkaxpjwabwufzevkmt.supabase.co/functions/v1/pedido-webhook`
- **Assinatura Secreta**: `253f99545037c212cdab6e18365015fd7ebb470e51637eef0e749795666a9837`

## Benefícios:
- 🔒 **Segurança máxima** - Apenas o Mercado Pago pode chamar
- 🛡️ **Proteção contra fraudes** - Impede chamadas falsas
- ✅ **Integridade dos dados** - Garante que não foi alterado

## Próximos passos:
1. Adicionar a variável de ambiente no Supabase
2. Implementar verificação nos webhooks
3. Testar com uma notificação real

Essa assinatura será usada para proteger tanto o webhook de pedidos quanto o de assinaturas!
