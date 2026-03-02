# 🚨 SOLUÇÃO RÁPIDA - "Falha ao enviar solicitação"

## ❌ Erro que você está vendo:
```
Falha ao enviar uma solicitação para a função Edge
```

---

## ✅ SOLUÇÃO IMEDIATA

### Opção 1: Deploy via Supabase CLI (Recomendado)

```bash
# 1. Verificar se CLI está instalado
supabase --version

# 2. Se não estiver, instalar:
npm install -g supabase

# 3. Login
supabase login

# 4. Linkar projeto
supabase link --project-ref tboghergvgbhmjzgzxaj

# 5. Deploy das funções
supabase functions deploy store-merchant-token
supabase functions deploy create-pix-payment
```

---

### Opção 2: Deploy Manual via Dashboard

Se o CLI não funcionar, faça manualmente:

#### 1️⃣ Criar função `store-merchant-token`:

1. Acesse: https://supabase.com/dashboard/project/tboghergvgbhmjzgzxaj/functions
2. Clique em **New Edge Function**
3. Nome: `store-merchant-token`
4. Cole o código de: `supabase/functions/store-merchant-token/index.ts`
5. Clique em **Deploy**

#### 2️⃣ Atualizar função `create-pix-payment`:

1. Vá em **Edge Functions**
2. Clique em `create-pix-payment`
3. Clique em **Edit**
4. Cole o código ATUALIZADO de: `supabase/functions/create-pix-payment/index.ts`
5. Clique em **Deploy**

---

## 🔍 Verificar se Função Existe

### Via Dashboard:
1. https://supabase.com/dashboard/project/tboghergvgbhmjzgzxaj/functions
2. Deve aparecer:
   - ✅ `store-merchant-token`
   - ✅ `create-pix-payment`
   - ✅ `check-payment-status`

### Via CLI:
```bash
supabase functions list
```

---

## 🧪 Testar Função Manualmente

### No Dashboard:

1. Vá em **Edge Functions** → `store-merchant-token`
2. Clique em **Invoke**
3. Cole este JSON:
```json
{
  "provider": "mercadopago",
  "api_key": "TEST_TOKEN_123456"
}
```
4. Adicione header:
   - Key: `Authorization`
   - Value: `Bearer SEU_JWT_TOKEN`
5. Clique em **Send**

**Resposta esperada:**
```json
{
  "success": true,
  "message": "Token salvo com sucesso"
}
```

---

## 🐛 Outros Erros Comuns

### "Table merchant_payment_credentials does not exist"

**Solução:** Execute o SQL primeiro!
```sql
-- No SQL Editor do Supabase Dashboard:
-- Cole o conteúdo de: supabase/migrations/20250110000002_merchant_payment_credentials.sql
```

### "Unauthorized" ou "401"

**Solução:** Token JWT expirado
1. Faça logout
2. Faça login novamente
3. Tente de novo

### "CORS error"

**Solução:** Já está configurado nas funções ✅
- Se ainda der erro, limpe cache do navegador

---

## 📞 Ainda não funcionou?

### Verifique os logs:

**Via Dashboard:**
1. Edge Functions → `store-merchant-token`
2. Aba **Logs**
3. Veja o erro específico

**Via CLI:**
```bash
supabase functions logs store-merchant-token --tail
```

---

## ✅ Checklist de Verificação

- [ ] Edge Function `store-merchant-token` existe no dashboard
- [ ] Tabela `merchant_payment_credentials` existe (SQL executado)
- [ ] Você está logado no sistema
- [ ] Tentou fazer logout/login
- [ ] Limpou cache do navegador

---

## 🎯 Teste Final

Depois de fazer o deploy, teste assim:

1. **Login** no painel admin
2. **Configurações** → Aba **Pagamentos**
3. Cole um token de teste: `TEST_123456789`
4. Clique em **Salvar Token**

**Se aparecer:** ✅ "Token salvo com sucesso!"
**Está funcionando!** 🎉

**Se aparecer erro:** Veja os logs da função
