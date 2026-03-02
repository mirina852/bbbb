# 📦 Instruções de Deploy - Sistema de Tokens Mercado Pago

## 🔧 Pré-requisitos

1. Ter o Supabase CLI instalado
2. Estar logado no Supabase CLI
3. Ter o projeto linkado

```bash
# Instalar Supabase CLI (se não tiver)
npm install -g supabase

# Login no Supabase
supabase login

# Linkar projeto (se não estiver linkado)
supabase link --project-ref SEU_PROJECT_REF
```

---

## 📊 Passo 1: Executar SQL (Criar Tabelas)

### No Supabase Dashboard:

1. Acesse: https://supabase.com/dashboard
2. Selecione seu projeto
3. Vá em **SQL Editor**
4. Clique em **New query**

### Execute estes SQLs na ordem:

#### 1️⃣ Setup Completo de Assinaturas (se ainda não executou):
```sql
-- Cole o conteúdo de:
supabase/migrations/complete_setup_with_expiry.sql
```

#### 2️⃣ Tabela de Tokens Mercado Pago:
```sql
-- Cole o conteúdo de:
supabase/migrations/20250110000002_merchant_payment_credentials.sql
```

---

## 🚀 Passo 2: Deploy das Edge Functions

### No terminal do projeto:

```bash
# 1. Deploy da função store-merchant-token
supabase functions deploy store-merchant-token

# 2. Deploy da função create-pix-payment (atualizada)
supabase functions deploy create-pix-payment

# 3. Deploy da função check-payment-status
supabase functions deploy check-payment-status
```

### ⚠️ Se der erro "function not found":

Verifique se as pastas existem:
```
supabase/
  functions/
    store-merchant-token/
      index.ts
    create-pix-payment/
      index.ts
    check-payment-status/
      index.ts
```

---

## 🔑 Passo 3: Configurar Variáveis de Ambiente

As Edge Functions já usam automaticamente:
- `SUPABASE_URL` ✅
- `SUPABASE_SERVICE_ROLE_KEY` ✅

Não precisa configurar nada extra!

---

## ✅ Passo 4: Testar o Sistema

### 4.1 Configurar Token (Lojista):

1. Faça login no painel admin
2. Vá em **Configurações** → Aba **Pagamentos**
3. Obtenha seu token em: https://www.mercadopago.com.br/developers/panel/credentials
4. Cole o token e clique em **Salvar Token**

### 4.2 Testar Pagamento:

1. Vá em **Planos** (`/planos`)
2. Selecione um plano pago
3. Deve gerar o QR Code PIX

---

## 🐛 Troubleshooting

### Erro: "Falha ao enviar solicitação para Edge Function"

**Possíveis causas:**

1. **Edge Function não foi deployada**
   ```bash
   supabase functions list
   # Deve mostrar: store-merchant-token, create-pix-payment
   ```

2. **Tabela não existe**
   - Execute o SQL da tabela `merchant_payment_credentials`

3. **CORS não configurado**
   - Já está configurado nas funções ✅

4. **Token não configurado**
   - Configure o token do Mercado Pago primeiro

### Erro: "Configure seu token do Mercado Pago"

✅ **Isso é esperado!** Significa que a função está funcionando.
- Vá em Configurações → Pagamentos
- Configure seu token

### Erro: "Unauthorized" ou "401"

- Verifique se está logado
- Faça logout e login novamente

---

## 📝 Verificar se Deploy Funcionou

### Teste manual da função store-merchant-token:

```bash
# No terminal:
curl -i --location --request POST 'https://SEU_PROJECT_REF.supabase.co/functions/v1/store-merchant-token' \
  --header 'Authorization: Bearer SEU_JWT_TOKEN' \
  --header 'Content-Type: application/json' \
  --data '{"provider":"mercadopago","api_key":"TEST_TOKEN_123"}'
```

### Teste manual da função create-pix-payment:

```bash
curl -i --location --request POST 'https://SEU_PROJECT_REF.supabase.co/functions/v1/create-pix-payment' \
  --header 'Authorization: Bearer SEU_JWT_TOKEN' \
  --header 'Content-Type: application/json' \
  --data '{"planId":"UUID_DO_PLANO","amount":29.99,"description":"Plano Mensal"}'
```

---

## 🎯 Checklist Final

- [ ] SQL executado (tabelas criadas)
- [ ] Edge Functions deployadas
- [ ] Token Mercado Pago configurado
- [ ] Teste de pagamento funcionando
- [ ] QR Code sendo gerado

---

## 📞 Suporte

Se continuar com erro, verifique os logs:

```bash
# Ver logs das funções
supabase functions logs store-merchant-token
supabase functions logs create-pix-payment
```

Ou no Dashboard:
1. Vá em **Edge Functions**
2. Clique na função
3. Veja a aba **Logs**
