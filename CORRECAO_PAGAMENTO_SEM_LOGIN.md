# 🔧 Correção: Pagamento PIX sem Login

## 📋 Problema Identificado

**Erro:** "Token inválido ou usuário não encontrado" ao tentar finalizar compra sem estar logado.

**Causa:** A Edge Function `create-pix-payment` estava exigindo autenticação para TODOS os pagamentos, incluindo pedidos de clientes não autenticados.

## ✅ Solução Implementada

A função foi modificada para:
- ✅ **Assinaturas**: Autenticação OBRIGATÓRIA (admin pagando plano)
- ✅ **Pedidos**: Autenticação OPCIONAL (cliente comprando produtos)

## 🚀 Como Fazer o Deploy

### Opção 1: Deploy via Dashboard do Supabase (Recomendado)

1. **Acesse o Dashboard:**
   - URL: https://supabase.com/dashboard
   - Faça login e selecione seu projeto

2. **Navegue até Edge Functions:**
   - Menu lateral → **"Edge Functions"**
   - Encontre **"create-pix-payment"**

3. **Atualize a Função:**
   - Clique na função
   - Clique em **"Edit"** ou **"Code"**
   - Copie o conteúdo do arquivo: `supabase/functions/create-pix-payment/index.ts`
   - Cole no editor do dashboard
   - Clique em **"Deploy"**

4. **Verifique as Variáveis de Ambiente:**
   - Vá em **"Edge Functions"** → **"Secrets"**
   - Confirme que existem:
     - `PLATFORM_MERCADOPAGO_ACCESS_TOKEN`
     - `PLATFORM_MERCADOPAGO_PUBLIC_KEY`
   - Se não existirem, adicione-as com suas credenciais do Mercado Pago

### Opção 2: Deploy via CLI (Se disponível)

```bash
# No terminal, na raiz do projeto:
npx supabase functions deploy create-pix-payment
```

## 🧪 Como Testar

### Teste 1: Cliente Não Autenticado (Pedido)

1. **Abra o site em uma aba anônima** (Ctrl + Shift + N)
2. Navegue até a loja (`/store`)
3. Adicione produtos ao carrinho
4. Clique em "Finalizar Pedido"
5. Preencha: nome, telefone, endereço
6. Selecione **"PIX"** como forma de pagamento
7. Clique em **"Pagar com PIX"**

**Resultado Esperado:**
- ✅ QR Code PIX deve ser gerado
- ✅ Nenhum erro de autenticação
- ✅ Pagamento criado com sucesso

### Teste 2: Admin Autenticado (Assinatura)

1. Faça login como admin (`/auth`)
2. Vá para planos (`/planos`)
3. Escolha um plano
4. Clique em "Assinar"

**Resultado Esperado:**
- ✅ QR Code PIX deve ser gerado
- ✅ Pagamento vinculado ao usuário autenticado

## 📝 Mudanças Técnicas

### Antes (Com Erro)
```typescript
// Verificava autenticação SEMPRE
const authHeader = req.headers.get("Authorization");
if (!authHeader) {
  return error("Não autorizado");
}
```

### Depois (Corrigido)
```typescript
// Verifica tipo de pagamento primeiro
const isSubscriptionPayment = !!planId;
const isOrderPayment = !planId && !!amount;

// Autenticação OBRIGATÓRIA apenas para assinaturas
if (isSubscriptionPayment) {
  if (!authHeader) {
    return error("Autenticação necessária para assinatura");
  }
  // Valida token...
} else if (isOrderPayment) {
  // Autenticação OPCIONAL para pedidos
  // Cliente pode ou não estar logado
}
```

## 🔍 Verificar Logs

Após o deploy, monitore os logs:

1. Dashboard → **"Edge Functions"** → **"create-pix-payment"** → **"Logs"**
2. Faça um teste de pagamento
3. Procure por:
   - ✅ `"Tipo de pagamento: pedido"`
   - ✅ `"Pagamento de pedido sem autenticação - permitido"`
   - ✅ `"✅ Pagamento de pedido criado com sucesso"`

## ⚠️ Importante

- **Clientes NÃO precisam criar conta** para comprar
- **Apenas admins** precisam de conta (para acessar painel)
- **Pagamentos de pedidos** funcionam sem autenticação
- **Pagamentos de assinaturas** exigem autenticação

## 📞 Suporte

Se após o deploy ainda houver erro:

1. Verifique os logs da Edge Function
2. Confirme que as variáveis de ambiente estão configuradas
3. Limpe o cache do navegador (Ctrl + Shift + Delete)
4. Teste em aba anônima
5. Compartilhe os logs para análise

---

**Status:** ✅ Código corrigido localmente  
**Próximo Passo:** Fazer deploy da função atualizada
