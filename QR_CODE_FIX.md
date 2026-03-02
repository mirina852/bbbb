# Correção: QR Code não aparece no pagamento PIX

## 🐛 Problema Identificado

O QR Code não estava aparecendo no modal de pagamento PIX para assinaturas porque:

1. **Edge Function retornava dados em formato diferente**: A função `create-pix-payment` retornava `{ success: true, data: {...} }`, mas o código esperava os dados diretamente
2. **Campos incorretos na busca de credenciais**: A Edge Function buscava `owner_id` e `provider`, mas a tabela tem `user_id`
3. **Campo incorreto no insert**: Usava `subscription_plan_id` mas a tabela tem `plan_id`

---

## ✅ Correções Aplicadas

### 1. **subscriptionService.ts**
Adicionado tratamento para extrair os dados do formato `{ success, data }`:

```typescript
// A função retorna { success: true, data: {...} }
if (data && data.success && data.data) {
  console.log('Pagamento criado:', data.data);
  return data.data;
}

// Se não tiver success, pode ser erro
if (data && !data.success) {
  throw new Error(data.error || 'Erro ao criar pagamento');
}
```

### 2. **create-pix-payment/index.ts**
Corrigidos os campos da query:

**Antes:**
```typescript
.select("api_key, is_active")
.eq("owner_id", user.id)
.eq("provider", "mercadopago")
```

**Depois:**
```typescript
.select("access_token, public_key, is_active")
.eq("user_id", user.id)
```

**E também:**
```typescript
// Antes
subscription_plan_id: planId,

// Depois
plan_id: planId,
```

---

## 🧪 Como Testar

1. **Certifique-se de ter aplicado a migration**:
   - Execute o SQL de `supabase/migrations/20251010145200_create_merchant_payment_credentials.sql`

2. **Configure suas credenciais do Mercado Pago**:
   - Vá em **Pagamentos** → **Configuração do Mercado Pago**
   - Insira Public Key e Access Token
   - Clique em **Salvar Configurações**

3. **Teste o pagamento de assinatura**:
   - Vá em **Planos de Assinatura**
   - Clique em **Selecionar Plano**
   - O modal PIX deve abrir mostrando:
     - ✅ Valor da assinatura
     - ✅ QR Code (imagem)
     - ✅ Código PIX para copiar
     - ✅ Timer de expiração

---

## 📋 Checklist de Verificação

- [ ] Migration `merchant_payment_credentials` aplicada no Supabase
- [ ] Credenciais do Mercado Pago configuradas
- [ ] Edge Function `create-pix-payment` atualizada (deploy automático)
- [ ] Código frontend atualizado
- [ ] QR Code aparece no modal
- [ ] Código PIX pode ser copiado

---

## 🔍 Debug

Se o QR Code ainda não aparecer, verifique:

1. **Console do navegador** - Procure por erros
2. **Logs da Edge Function** - No Supabase Dashboard → Edge Functions → Logs
3. **Dados retornados**:
   ```javascript
   console.log('Resposta da função:', data);
   ```
4. **Credenciais salvas**:
   ```sql
   SELECT * FROM merchant_payment_credentials WHERE user_id = 'seu-user-id';
   ```

---

## 🚀 Próximos Passos

Para integrar com a API real do Mercado Pago:

1. Substituir o QR Code mock na Edge Function
2. Fazer chamada real para `https://api.mercadopago.com/v1/payments`
3. Usar o `access_token` das credenciais
4. Retornar o QR Code real da resposta

Exemplo:
```typescript
const response = await fetch('https://api.mercadopago.com/v1/payments', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${merchantToken}`
  },
  body: JSON.stringify({
    transaction_amount: amount,
    description: description,
    payment_method_id: 'pix',
    payer: {
      email: user.email
    }
  })
});

const paymentData = await response.json();
const qrCode = paymentData.point_of_interaction.transaction_data.qr_code;
const qrCodeBase64 = paymentData.point_of_interaction.transaction_data.qr_code_base64;
```
