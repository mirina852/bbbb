# 💳 Configurar Mercado Pago - Pagamentos PIX Reais

## ⚠️ Problema Atual

O QR Code PIX está aparecendo, mas **não funciona** porque é um código simulado/fake. Para aceitar pagamentos reais, você precisa configurar a integração com o Mercado Pago.

---

## 🎯 Solução: Integração Real com Mercado Pago

### Passo 1: Obter Credenciais do Mercado Pago

1. **Acesse:** https://www.mercadopago.com.br/developers/panel
2. **Faça login** com sua conta Mercado Pago
3. **Vá em:** "Suas integrações" → "Credenciais"
4. **Escolha o ambiente:**
   - **Teste (Sandbox):** Para testar sem dinheiro real
   - **Produção:** Para aceitar pagamentos reais

5. **Copie as credenciais:**
   - **Public Key:** `APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - **Access Token:** `APP_USR-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-xxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx-xxxxxxxxx`

---

### Passo 2: Configurar Variáveis de Ambiente no Supabase

1. **Acesse:** Dashboard do Supabase → Settings → Edge Functions → Environment Variables

2. **Adicione as variáveis:**

```
PLATFORM_MERCADOPAGO_ACCESS_TOKEN=seu_access_token_aqui
PLATFORM_MERCADOPAGO_PUBLIC_KEY=sua_public_key_aqui
```

**⚠️ IMPORTANTE:**
- Use as credenciais de **PRODUÇÃO** da sua conta (plataforma)
- Essas credenciais são para receber pagamentos de **assinaturas**
- NÃO confunda com as credenciais dos usuários (merchants)

---

### Passo 3: Fazer Deploy da Edge Function Atualizada

A função agora está configurada para:
- ✅ Chamar a API real do Mercado Pago
- ✅ Gerar QR Code PIX válido
- ✅ Retornar código que funciona de verdade
- ✅ Fallback para código simulado se a API falhar

**Como fazer deploy:**

#### Opção A: Via Dashboard (Mais Fácil)
1. Dashboard do Supabase → Edge Functions
2. Clique em `create-pix-payment`
3. Cole o código atualizado do arquivo `supabase/functions/create-pix-payment/index.ts`
4. Clique em "Deploy"

#### Opção B: Via CLI
```bash
supabase functions deploy create-pix-payment
```

---

### Passo 4: Testar Pagamento

1. **Acesse a loja** (página store)
2. **Adicione produtos** ao carrinho
3. **Clique em "Pagar com PIX"**
4. **Verifique:**
   - ✅ QR Code aparece
   - ✅ Código PIX pode ser copiado
   - ✅ Ao escanear, abre o app do banco

5. **Teste o pagamento:**
   - Escaneie o QR Code com o app do banco
   - Confirme o pagamento
   - Aguarde a confirmação

---

## 🔍 Como Verificar se Está Funcionando

### Logs da Edge Function

1. Dashboard do Supabase → Edge Functions → create-pix-payment → Logs
2. Tente criar um pagamento
3. Veja os logs:

**✅ Sucesso (API real):**
```
Criando pagamento PIX no Mercado Pago...
Resposta do Mercado Pago: {id: 123456789, ...}
✅ Pagamento PIX criado no Mercado Pago: 123456789
```

**⚠️ Fallback (API falhou):**
```
Erro ao criar pagamento no Mercado Pago: ...
⚠️ Usando QR Code simulado como fallback
```

---

### Console do Navegador (F12)

**✅ Sucesso:**
```
Creating PIX payment with data: {...}
Resposta da função: {success: true, data: {id: "123456789", qr_code: "..."}}
Gerando QR Code visual para: 00020126...
QR Code visual gerado com sucesso
```

---

## 🧪 Testar com Dinheiro Fake (Sandbox)

Se quiser testar sem usar dinheiro real:

1. **Use credenciais de TESTE** (Sandbox) no Supabase
2. **Acesse:** https://www.mercadopago.com.br/developers/pt/docs/checkout-api/testing
3. **Use cartões de teste** ou **contas de teste**
4. **Simule pagamentos** sem cobrar de verdade

---

## 💰 Fluxo de Pagamento Real

### Para Assinaturas (Plataforma recebe)

1. **Usuário** clica em "Assinar Plano"
2. **Sistema** gera QR Code PIX via Mercado Pago
3. **Usuário** paga via PIX
4. **Mercado Pago** envia webhook confirmando pagamento
5. **Sistema** ativa assinatura do usuário
6. **Dinheiro** vai para conta da plataforma

### Para Pedidos da Loja (Merchant recebe)

1. **Cliente** faz pedido na loja do merchant
2. **Sistema** gera QR Code PIX via credenciais do merchant
3. **Cliente** paga via PIX
4. **Mercado Pago** envia webhook
5. **Sistema** confirma pedido
6. **Dinheiro** vai para conta do merchant

---

## 🔐 Segurança

### Credenciais da Plataforma
- Armazenadas em **variáveis de ambiente** do Supabase
- Usadas apenas para **pagamentos de assinaturas**
- Nunca expostas no frontend

### Credenciais dos Merchants
- Armazenadas na tabela `merchant_payment_credentials`
- Criptografadas no banco de dados
- Usadas apenas para **pagamentos de pedidos dos clientes**

---

## ❓ Troubleshooting

### Erro: "Mercado Pago API error: Unauthorized"

**Causa:** Access Token inválido ou expirado

**Solução:**
1. Verifique se copiou o token completo
2. Gere um novo token no painel do Mercado Pago
3. Atualize a variável de ambiente no Supabase

---

### Erro: "QR Code não retornado pelo Mercado Pago"

**Causa:** Resposta da API não contém o QR Code

**Solução:**
1. Verifique os logs da Edge Function
2. Veja a resposta completa do Mercado Pago
3. Confirme que está usando `payment_method_id: 'pix'`

---

### QR Code aparece mas não funciona

**Causa:** Usando código simulado (fallback)

**Solução:**
1. Verifique os logs: deve mostrar "⚠️ Usando QR Code simulado"
2. Configure as credenciais corretas no Supabase
3. Faça deploy da função atualizada

---

## 📋 Checklist

- [ ] Criei conta no Mercado Pago
- [ ] Obtive credenciais (Public Key + Access Token)
- [ ] Configurei variáveis de ambiente no Supabase
- [ ] Fiz deploy da Edge Function atualizada
- [ ] Testei criar pagamento
- [ ] QR Code aparece
- [ ] QR Code funciona (abre app do banco)
- [ ] Pagamento é confirmado via webhook

---

## 🎉 Resultado Final

Quando tudo estiver configurado:

1. ✅ QR Code PIX **real** é gerado
2. ✅ Cliente pode **pagar de verdade**
3. ✅ Pagamento é **confirmado automaticamente**
4. ✅ Sistema **ativa assinatura** ou **confirma pedido**
5. ✅ Dinheiro cai na **conta correta**

---

## 📚 Documentação Oficial

- **Mercado Pago API:** https://www.mercadopago.com.br/developers/pt/reference
- **PIX via API:** https://www.mercadopago.com.br/developers/pt/docs/checkout-api/integration-configuration/integrate-with-pix
- **Webhooks:** https://www.mercadopago.com.br/developers/pt/docs/your-integrations/notifications/webhooks

---

## 💡 Dica Final

Para testar rapidamente sem configurar tudo:
- O sistema usa **fallback** (código simulado) se a API falhar
- Você pode desenvolver e testar a interface
- Quando estiver pronto para produção, configure as credenciais reais

**Boa sorte com os pagamentos! 💰**
