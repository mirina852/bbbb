# 🔧 Correção: Bloqueio de Requisições sem Autenticação

## 📋 Problema Identificado

**Erro:** A função Edge Function `create-pix-payment` estava retornando erro de autenticação mesmo para pagamentos de pedidos simples (que não requerem login).

**Causa Raiz:** No arquivo `supabase/config.toml`, a configuração `verify_jwt = true` estava **forçando a verificação de JWT** para TODAS as requisições à função, ignorando a lógica interna que permite pagamentos sem autenticação.

## 🔍 Análise Técnica

### Configuração Anterior (Com Erro)
```toml
[functions.create-pix-payment]
verify_jwt = true  # ❌ Bloqueava TODAS as requisições sem JWT
```

### Configuração Corrigida
```toml
[functions.create-pix-payment]
verify_jwt = false  # ✅ Permite que a função gerencie autenticação internamente
```

## ✅ O Que Foi Corrigido

1. **Arquivo:** `supabase/config.toml`
2. **Mudança:** `verify_jwt = true` → `verify_jwt = false`
3. **Impacto:** A função agora pode receber requisições sem token JWT e decidir internamente se autenticação é necessária

## 🛡️ Segurança Mantida

A função **continua segura** porque:

1. **Lógica interna de autenticação** (linhas 63-114 do `index.ts`):
   - ✅ **Assinaturas**: Autenticação OBRIGATÓRIA
   - ✅ **Pedidos**: Autenticação OPCIONAL
   
2. **Validação de dados**:
   - Verifica `amount`, `storeId/storeSlug`
   - Valida credenciais do merchant no banco
   - Usa `SERVICE_ROLE_KEY` para operações privilegiadas

3. **Políticas RLS**:
   - Tabela `merchant_payment_credentials` permite leitura pública apenas de credenciais ativas
   - Proteção contra acesso não autorizado aos dados sensíveis

## 🚀 Como Fazer o Deploy

### Opção 1: Deploy via Supabase CLI (Recomendado)

```bash
# 1. Certifique-se de estar na raiz do projeto
cd d:\petisco-saas-app-11-main

# 2. Faça login no Supabase (se ainda não estiver logado)
npx supabase login

# 3. Link com seu projeto (se ainda não estiver linkado)
npx supabase link --project-ref tboghergvgbhmjzgzxaj

# 4. Deploy da função com a nova configuração
npx supabase functions deploy create-pix-payment
```

### Opção 2: Deploy Manual via Dashboard

1. **Acesse o Dashboard do Supabase:**
   - URL: https://supabase.com/dashboard/project/tboghergvgbhmjzgzxaj
   - Faça login

2. **Navegue até Edge Functions:**
   - Menu lateral → **"Edge Functions"**
   - Encontre **"create-pix-payment"**

3. **Atualize a Configuração:**
   - Clique na função
   - Vá em **"Settings"** ou **"Configuration"**
   - Procure por **"JWT Verification"** ou **"verify_jwt"**
   - **Desabilite** a verificação JWT obrigatória
   - Salve as alterações

4. **Redeploy da Função:**
   - Clique em **"Deploy"** ou **"Redeploy"**
   - Aguarde a conclusão do deploy

## 🧪 Como Testar

### Teste 1: Pagamento de Pedido SEM Login (Deve Funcionar)

```bash
# Teste via cURL (substitua os valores)
curl -X POST https://vnyrvgtioorpyohfvbim.supabase.co/functions/v1/create-pix-payment \
  -H "Content-Type: application/json" \
  -H "apikey: YOUR_ANON_KEY" \
  -d '{
    "amount": 50.00,
    "customerName": "João Silva",
    "customerPhone": "11999999999",
    "description": "Pedido #123",
    "storeSlug": "sua-loja"
  }'
```

**Resultado Esperado:**
```json
{
  "success": true,
  "data": {
    "id": "payment_id_here",
    "status": "pending",
    "qr_code": "00020126...",
    "qr_code_base64": "00020126..."
  }
}
```

### Teste 2: Pagamento de Pedido COM Login (Deve Funcionar)

```bash
curl -X POST https://vnyrvgtioorpyohfvbim.supabase.co/functions/v1/create-pix-payment \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -H "apikey: YOUR_ANON_KEY" \
  -d '{
    "amount": 50.00,
    "customerName": "João Silva",
    "customerPhone": "11999999999",
    "description": "Pedido #123",
    "storeSlug": "sua-loja"
  }'
```

### Teste 3: Pagamento de Assinatura SEM Login (Deve Falhar)

```bash
curl -X POST https://vnyrvgtioorpyohfvbim.supabase.co/functions/v1/create-pix-payment \
  -H "Content-Type: application/json" \
  -H "apikey: YOUR_ANON_KEY" \
  -d '{
    "planId": "plan_123",
    "amount": 99.90
  }'
```

**Resultado Esperado:**
```json
{
  "success": false,
  "error": "Autenticação necessária para pagamento de assinatura"
}
```

### Teste 4: Pagamento de Assinatura COM Login (Deve Funcionar)

```bash
curl -X POST https://vnyrvgtioorpyohfvbim.supabase.co/functions/v1/create-pix-payment \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -H "apikey: YOUR_ANON_KEY" \
  -d '{
    "planId": "plan_123",
    "amount": 99.90
  }'
```

## 🔍 Verificar Logs

Após o deploy, monitore os logs para confirmar que está funcionando:

1. **Dashboard → Edge Functions → create-pix-payment → Logs**

2. **Procure por:**
   - ✅ `"Tipo de pagamento: pedido"`
   - ✅ `"Pagamento de pedido sem autenticação - permitido"`
   - ✅ `"✅ Pagamento de pedido criado com sucesso"`

3. **Logs de erro esperados (se houver):**
   - ❌ `"Autenticação necessária para pagamento de assinatura"` (quando tentar assinatura sem login)

## 📊 Comparação: Antes vs Depois

| Cenário | Antes (verify_jwt=true) | Depois (verify_jwt=false) |
|---------|-------------------------|---------------------------|
| Pedido sem login | ❌ Erro de autenticação | ✅ Funciona |
| Pedido com login | ✅ Funciona | ✅ Funciona |
| Assinatura sem login | ❌ Erro de autenticação | ❌ Erro de autenticação (esperado) |
| Assinatura com login | ✅ Funciona | ✅ Funciona |

## ⚠️ Notas Importantes

1. **CORS está configurado corretamente** (linhas 4-7 do `index.ts`)
2. **A função usa `SERVICE_ROLE_KEY`** para operações privilegiadas
3. **Políticas RLS protegem dados sensíveis** na tabela `merchant_payment_credentials`
4. **A lógica de autenticação interna** garante segurança para assinaturas

## 🎯 Próximos Passos

1. ✅ **Deploy da função** com a nova configuração
2. ✅ **Testar** pagamentos sem login
3. ✅ **Verificar logs** para confirmar funcionamento
4. ✅ **Testar** em produção com clientes reais

## 📞 Suporte

Se após o deploy ainda houver problemas:

1. Verifique os logs da Edge Function
2. Confirme que as variáveis de ambiente estão configuradas:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `PLATFORM_MERCADOPAGO_ACCESS_TOKEN` (para assinaturas)
   - `PLATFORM_MERCADOPAGO_PUBLIC_KEY` (para assinaturas)
3. Verifique se a tabela `merchant_payment_credentials` tem credenciais ativas para a loja
4. Limpe o cache do navegador
5. Teste em aba anônima

---

**Status:** ✅ Correção aplicada localmente  
**Próximo Passo:** Deploy da configuração atualizada  
**Arquivo Modificado:** `supabase/config.toml`
