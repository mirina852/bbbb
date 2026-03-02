# 🏪 Guia Rápido: Como Configurar o Mercado Pago na Sua Loja

## 📱 Para Lojistas (Guia Simplificado)

Este guia explica como configurar o Mercado Pago para receber pagamentos dos seus clientes **diretamente na sua conta**.

---

## ✅ Pré-requisitos

Antes de começar, você precisa:

1. ✅ Ter uma conta no Mercado Pago (gratuito)
2. ✅ Ter uma loja criada no sistema
3. ✅ Ter uma assinatura ativa no sistema

---

## 🚀 Passo a Passo (5 minutos)

### Passo 1: Criar Conta no Mercado Pago

Se você ainda não tem uma conta:

1. Acesse: https://www.mercadopago.com.br
2. Clique em **"Criar conta"**
3. Preencha seus dados
4. Confirme seu e-mail
5. Complete o cadastro

**💡 Dica:** Use a mesma conta que você já usa para compras online!

---

### Passo 2: Obter Suas Credenciais

1. Acesse: https://www.mercadopago.com.br/developers/panel
2. Faça login com sua conta
3. Vá em **"Suas integrações"** → **"Credenciais"**
4. Você verá duas opções:
   - **Credenciais de teste** (para testar)
   - **Credenciais de produção** (para receber dinheiro de verdade)

#### Para Começar (Recomendado):

Use as **credenciais de TESTE** primeiro:

- **Public Key de teste**: `TEST-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- **Access Token de teste**: `TEST-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

#### Para Receber Pagamentos Reais:

Use as **credenciais de PRODUÇÃO**:

- **Public Key**: `APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- **Access Token**: `APP_USR-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

**⚠️ IMPORTANTE:** Copie e guarde essas credenciais em um lugar seguro!

---

### Passo 3: Configurar no Sistema

1. **Faça login** no sistema
2. Vá em **Configurações** → **Pagamentos**
3. Cole suas credenciais:
   - **Public Key**: Cole a Public Key que você copiou
   - **Access Token**: Cole o Access Token que você copiou
4. Clique em **Salvar**

**✅ Pronto!** Sua loja já está configurada para receber pagamentos!

---

## 🎯 Como Funciona

```
┌─────────────────────────────────────────────────────────┐
│                                                           │
│  1. Cliente acessa sua loja                              │
│     ↓                                                     │
│  2. Adiciona produtos ao carrinho                        │
│     ↓                                                     │
│  3. Clica em "Finalizar Pedido"                          │
│     ↓                                                     │
│  4. Sistema gera QR Code PIX                             │
│     ↓                                                     │
│  5. Cliente paga com PIX                                 │
│     ↓                                                     │
│  6. Dinheiro cai na SUA conta do Mercado Pago! 💰        │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

---

## 💰 Quando o Dinheiro Cai na Minha Conta?

### Com Credenciais de TESTE:
- ❌ Não cai dinheiro real
- ✅ Serve apenas para testar se está funcionando

### Com Credenciais de PRODUÇÃO:
- ✅ Dinheiro cai na sua conta do Mercado Pago
- ⏱️ Tempo: Instantâneo após o cliente pagar
- 💳 Você pode transferir para sua conta bancária depois

---

## 🔒 Segurança

### ✅ Suas credenciais são seguras:

- 🔐 Armazenadas de forma criptografada
- 🔐 Apenas você tem acesso
- 🔐 Não compartilhadas com outras lojas
- 🔐 Protegidas por políticas de segurança

### ⚠️ NUNCA compartilhe:

- ❌ Seu Access Token
- ❌ Suas credenciais com terceiros
- ❌ Sua senha do Mercado Pago

---

## 🧪 Como Testar

### Teste 1: Verificar se Configurou Corretamente

1. Acesse **Configurações** → **Pagamentos**
2. Você deve ver uma mensagem: **"Mercado Pago configurado!"**
3. Se não aparecer, verifique se salvou as credenciais

### Teste 2: Fazer um Pedido de Teste

1. Acesse sua loja (página pública)
2. Adicione um produto ao carrinho
3. Clique em "Finalizar Pedido"
4. Deve aparecer um QR Code PIX
5. Se aparecer, está funcionando! ✅

### Teste 3: Pagar de Verdade (com credenciais de teste)

1. Use o app do Mercado Pago
2. Escaneie o QR Code de teste
3. O pagamento será simulado (não sai dinheiro real)
4. Verifique se o pedido foi confirmado

---

## 🐛 Problemas Comuns

### Problema 1: "Mercado Pago não configurado"

**Solução:**
1. Verifique se você copiou as credenciais corretamente
2. Verifique se clicou em "Salvar"
3. Tente fazer logout e login novamente

### Problema 2: "QR Code não aparece"

**Solução:**
1. Verifique se configurou as credenciais
2. Verifique se sua assinatura está ativa
3. Tente recarregar a página

### Problema 3: "Pagamento não foi confirmado"

**Solução:**
1. Se está usando credenciais de TESTE, o pagamento não será real
2. Se está usando credenciais de PRODUÇÃO, aguarde alguns minutos
3. Verifique no painel do Mercado Pago se o pagamento foi registrado

### Problema 4: "Dinheiro não caiu na minha conta"

**Solução:**
1. Verifique se está usando credenciais de PRODUÇÃO (não teste)
2. Verifique se o cliente realmente pagou
3. Acesse sua conta do Mercado Pago para ver o saldo
4. O dinheiro fica disponível para saque após 14 dias (política do Mercado Pago)

---

## 📱 Acessar Sua Conta do Mercado Pago

Para ver seus pagamentos e saldo:

1. Acesse: https://www.mercadopago.com.br
2. Faça login
3. Vá em **"Atividade"** para ver pagamentos recebidos
4. Vá em **"Dinheiro disponível"** para ver seu saldo
5. Clique em **"Transferir"** para enviar para sua conta bancária

---

## 💡 Dicas Importantes

### ✅ Boas Práticas:

1. **Comece com credenciais de TESTE** para validar tudo
2. **Depois mude para PRODUÇÃO** quando estiver pronto
3. **Verifique regularmente** sua conta do Mercado Pago
4. **Configure notificações** no app do Mercado Pago
5. **Mantenha suas credenciais atualizadas**

### ⚠️ Cuidados:

1. **Não compartilhe** suas credenciais
2. **Não exponha** seu Access Token
3. **Não use credenciais de teste** em produção
4. **Não confie** em e-mails suspeitos
5. **Sempre verifique** se o pagamento foi confirmado

---

## 🎓 Perguntas Frequentes

### 1. Preciso pagar para usar o Mercado Pago?

**Não!** Criar uma conta no Mercado Pago é gratuito. Você só paga uma pequena taxa quando recebe um pagamento (cerca de 4,99%).

### 2. Posso ter várias lojas com a mesma conta do Mercado Pago?

**Sim!** Mas recomendamos usar contas diferentes para cada loja, para facilitar o controle financeiro.

### 3. O que acontece se eu mudar minhas credenciais?

Você pode atualizar suas credenciais a qualquer momento. Basta ir em **Configurações** → **Pagamentos** e salvar as novas credenciais.

### 4. Meus clientes precisam ter conta no Mercado Pago?

**Não!** Seus clientes podem pagar com PIX usando qualquer banco.

### 5. Quanto tempo demora para o dinheiro cair?

O pagamento é instantâneo, mas o Mercado Pago libera o dinheiro para saque após 14 dias (política de segurança deles).

### 6. Posso usar a mesma credencial em várias lojas?

**Tecnicamente sim**, mas **NÃO recomendamos**. Cada loja deve ter suas próprias credenciais para:
- Facilitar o controle financeiro
- Evitar confusão nos pagamentos
- Manter a segurança

### 7. O que é a diferença entre Public Key e Access Token?

- **Public Key**: Usada no frontend (segura para expor)
- **Access Token**: Usada no backend (NUNCA exponha)

Ambas são necessárias para o sistema funcionar.

### 8. Posso cancelar um pagamento?

Sim, você pode fazer reembolsos pelo painel do Mercado Pago. Acesse sua conta → Atividade → Selecione o pagamento → Devolver dinheiro.

---

## 📞 Precisa de Ajuda?

### Suporte do Mercado Pago:
- Site: https://www.mercadopago.com.br/ajuda
- Telefone: 0800 275 0000
- Chat: Disponível no site

### Suporte do Sistema:
- Entre em contato com o suporte técnico
- Envie um e-mail para suporte@seusite.com
- Acesse a central de ajuda

---

## ✅ Checklist Final

Antes de começar a receber pagamentos, verifique:

- [ ] Criei minha conta no Mercado Pago
- [ ] Obtive minhas credenciais (Public Key + Access Token)
- [ ] Configurei as credenciais no sistema
- [ ] Testei com credenciais de TESTE
- [ ] Mudei para credenciais de PRODUÇÃO
- [ ] Fiz um pedido de teste e funcionou
- [ ] Verifiquei minha conta do Mercado Pago
- [ ] Configurei notificações no app do Mercado Pago

---

## 🎉 Parabéns!

Sua loja já está pronta para receber pagamentos! 🚀

Agora é só divulgar sua loja e começar a vender! 💰

---

**Última atualização:** Outubro 2024  
**Versão:** 1.0
