# ⚙️ Configuração Inicial - Guia Rápido

## 🎯 O que você precisa fazer ANTES de rodar o sistema

### 1. Obter Credenciais do Mercado Pago

Você (dono da plataforma) precisa ter uma conta no Mercado Pago para receber os pagamentos das assinaturas.

#### Passo a passo:

1. **Acesse:** https://www.mercadopago.com.br/developers/panel
2. **Faça login** na sua conta Mercado Pago
3. **Vá em:** "Suas integrações" → "Credenciais"
4. **Copie:**
   - ✅ Public Key (começa com `APP_USR-`)
   - ✅ Access Token (começa com `APP_USR-`)

⚠️ **Importante:** Use as credenciais de **PRODUÇÃO** para receber pagamentos reais, ou **TESTE** para desenvolvimento.

---

### 2. Configurar Variáveis de Ambiente

#### Para Desenvolvimento Local

Crie um arquivo `.env` na raiz do projeto:

```bash
# Copie do .env.example
cp .env.example .env
```

Edite o arquivo `.env` e adicione suas credenciais:

```bash
# Suas credenciais do Mercado Pago
VITE_MERCADOPAGO_PUBLIC_KEY=APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
VITE_MERCADOPAGO_ACCESS_TOKEN=APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# URL da API (deixe como está para desenvolvimento)
VITE_API_URL=http://localhost:3000
```

#### Para Produção (Supabase Edge Functions)

No painel do Supabase:

1. **Acesse:** Dashboard → Project Settings → Edge Functions
2. **Vá em:** "Secrets" ou "Environment Variables"
3. **Adicione:**

```bash
MERCADOPAGO_ACCESS_TOKEN=APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
MERCADOPAGO_PUBLIC_KEY=APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

4. **Salve** e faça o deploy das Edge Functions novamente

---

### 3. Configurar Banco de Dados

Execute as migrations do Supabase:

```bash
# Se ainda não fez
supabase db push

# Ou rode as migrations manualmente
supabase migration up
```

Certifique-se de que as seguintes tabelas existem:
- ✅ `subscription_plans`
- ✅ `user_subscriptions`
- ✅ `subscription_payments`
- ✅ `merchant_payment_credentials`

---

### 4. Popular Planos de Assinatura

Você precisa ter planos cadastrados no banco. Execute este SQL no Supabase:

```sql
-- Inserir planos de exemplo
INSERT INTO subscription_plans (name, slug, price, duration_days, is_trial, features) VALUES
('Teste Gratuito', 'trial', 0, 7, true, '["Acesso completo por 7 dias", "Gestão de produtos", "Dashboard básico"]'),
('Mensal', 'monthly', 29.90, 30, false, '["Acesso completo", "Gestão de produtos e pedidos", "Dashboard com estatísticas", "Suporte prioritário"]'),
('Anual', 'yearly', 299.90, 365, false, '["Acesso completo", "Gestão de produtos e pedidos", "Dashboard com estatísticas", "Suporte VIP exclusivo", "Desconto de 16%"]');
```

---

## 🚀 Testando o Fluxo

### Teste 1: Pagamento de Assinatura

1. **Acesse:** http://localhost:3000/planos
2. **Escolha** um plano (ex: Teste Gratuito)
3. **Clique** em "Assinar"
4. **Verifique:**
   - ✅ QR Code PIX aparece
   - ✅ Valor está correto
   - ✅ Não pede credenciais do usuário

### Teste 2: Acesso ao Painel

1. **Após pagar** (ou simular pagamento)
2. **Acesse:** http://localhost:3000/admin
3. **Verifique:**
   - ✅ Dashboard carrega
   - ✅ Menu lateral funciona
   - ✅ Assinatura aparece como ativa

### Teste 3: Configuração de Pagamento

1. **Acesse:** Configurações → Pagamento
2. **Verifique:**
   - ✅ Formulário está liberado (não bloqueado)
   - ✅ Pode adicionar credenciais do Mercado Pago
   - ✅ Salva com sucesso

### Teste 4: Sem Assinatura

1. **Crie** um novo usuário
2. **NÃO** pague assinatura
3. **Tente acessar:** Configurações → Pagamento
4. **Verifique:**
   - ✅ Formulário está bloqueado
   - ✅ Mensagem: "Você precisa ter uma assinatura ativa"
   - ✅ Botão: "Ver Planos Disponíveis"

---

## 🔧 Troubleshooting

### Erro: "Erro de configuração do sistema"

**Causa:** Variáveis de ambiente não configuradas

**Solução:**
1. Verifique se o arquivo `.env` existe
2. Confirme que as variáveis começam com `VITE_`
3. Reinicie o servidor de desenvolvimento

### Erro: "Planos não encontrados"

**Causa:** Tabela `subscription_plans` vazia

**Solução:**
1. Execute o SQL de popular planos (acima)
2. Verifique no Supabase se os dados foram inseridos

### Erro: "Cannot find module 'https://deno.land/...'"

**Causa:** IDE tentando validar arquivo Deno com TypeScript

**Solução:**
- ✅ Ignore este erro - é esperado
- ✅ O arquivo funciona corretamente no Supabase
- ✅ Não afeta o funcionamento

---

## 📝 Checklist Final

Antes de considerar a configuração completa:

- [ ] Credenciais do Mercado Pago obtidas
- [ ] Arquivo `.env` criado e configurado
- [ ] Variáveis de ambiente no Supabase configuradas
- [ ] Migrations do banco executadas
- [ ] Planos de assinatura cadastrados
- [ ] Teste de pagamento realizado
- [ ] Teste de acesso ao painel realizado
- [ ] Teste de bloqueio de configuração realizado

---

## 🎉 Pronto!

Agora seu sistema está configurado e pronto para uso. Os usuários podem:

1. ✅ Escolher um plano
2. ✅ Pagar a assinatura (dinheiro cai na SUA conta)
3. ✅ Acessar o painel admin
4. ✅ Configurar Mercado Pago deles (para receber dos clientes)
5. ✅ Começar a vender produtos

**Dúvidas?** Consulte o arquivo `FLUXO_PAGAMENTOS.md` para entender a arquitetura completa.
