# 🔍 Diagnóstico: "planId ou amount faltando"

## ⚠️ Erro

```
planId ou amount faltando
```

**Significado:** A Edge Function `create-pix-payment` não está recebendo os parâmetros `planId` e `amount` no body da requisição.

---

## 🎯 Possíveis Causas

### 1. Migration Não Executada ❌

**Sintoma:** Tabela `subscription_plans` não existe

**Como verificar:**
1. Abra o console do navegador (F12)
2. Tente criar um pagamento
3. Procure por: `❌ Erro ao buscar plano`

**Solução:**
- Execute a migration conforme `EXECUTAR_MIGRATION.md`

---

### 2. Planos Não Cadastrados ❌

**Sintoma:** Tabela existe mas está vazia

**Como verificar:**
```sql
SELECT * FROM public.subscription_plans;
```

**Resultado esperado:** 3 planos (Trial, Mensal, Anual)

**Solução:**
```sql
INSERT INTO public.subscription_plans (name, slug, price, duration_days, is_trial, features) VALUES
('Teste Gratuito', 'trial', 0, 7, true, '["Acesso completo por 7 dias"]'::jsonb),
('Mensal', 'monthly', 29.90, 30, false, '["Acesso completo"]'::jsonb),
('Anual', 'yearly', 299.90, 365, false, '["Acesso completo", "Desconto"]'::jsonb);
```

---

### 3. Edge Function Desatualizada ❌

**Sintoma:** Função ainda usa código antigo

**Como verificar:**
1. Vá no dashboard do Supabase
2. Edge Functions → create-pix-payment
3. Veja se tem os comentários: `// 🔹 Lê corpo da requisição`

**Solução:**
- Faça deploy da função atualizada (veja `DEPLOY_FUNCAO.md`)

---

### 4. Variáveis de Ambiente Incorretas ❌

**Sintoma:** Função reclama de credenciais

**Como verificar logs:**
```
PLATFORM_MERCADOPAGO_TOKEN definido: false
PLATFORM_MERCADOPAGO_PUBLIC_KEY definido: false
```

**Solução:**
No dashboard do Supabase, configure:
```
PLATFORM_MERCADOPAGO_ACCESS_TOKEN=seu_token
PLATFORM_MERCADOPAGO_PUBLIC_KEY=sua_chave
```

---

## 🧪 Passo a Passo de Diagnóstico

### Passo 1: Abrir Console do Navegador

1. Pressione **F12**
2. Vá na aba **Console**
3. Limpe o console (ícone 🚫)

### Passo 2: Tentar Criar Pagamento

1. Acesse `/planos`
2. Clique em qualquer plano (ex: Mensal)
3. Observe os logs no console

### Passo 3: Identificar o Erro

Procure por estas mensagens:

#### ✅ Cenário 1: Tudo OK até a função
```
subscriptionService.createPayment chamado: {userId: "...", planId: "..."}
✅ Plano encontrado: {price: 29.9, name: "Mensal"}
📤 Invocando create-pix-payment com: {planId: "...", amount: 29.9, ...}
```

**Diagnóstico:** Frontend está OK, problema é na Edge Function
**Próximo passo:** Verificar logs da Edge Function no Supabase

---

#### ❌ Cenário 2: Erro ao buscar plano
```
subscriptionService.createPayment chamado: {userId: "...", planId: "..."}
❌ Erro ao buscar plano: {message: "relation 'subscription_plans' does not exist"}
```

**Diagnóstico:** Migration não foi executada
**Solução:** Execute a migration (veja `EXECUTAR_MIGRATION.md`)

---

#### ❌ Cenário 3: Plano não encontrado
```
subscriptionService.createPayment chamado: {userId: "...", planId: "..."}
❌ Plano não encontrado: abc-123-def
```

**Diagnóstico:** Planos não foram cadastrados
**Solução:** Insira os planos no banco

---

### Passo 4: Verificar Logs da Edge Function

1. Dashboard do Supabase
2. Edge Functions → create-pix-payment
3. Aba **Logs**
4. Tente criar pagamento novamente
5. Veja os logs em tempo real

#### Logs esperados (sucesso):
```
🧾 Criando pagamento para plano: abc-123
PLATFORM_MERCADOPAGO_TOKEN definido: true
PLATFORM_MERCADOPAGO_PUBLIC_KEY definido: true
Usando token da plataforma para pagamento de assinatura...
✅ Pagamento criado com sucesso: xyz-789
```

#### Logs de erro:
```
planId ou amount faltando
```
**Causa:** Body chegou vazio na função
**Possível motivo:** Erro antes de chamar a função (veja console do navegador)

---

## 🔧 Soluções Rápidas

### Solução 1: Executar Migration Completa

```sql
-- Cole no SQL Editor do Supabase
-- (veja arquivo EXECUTAR_MIGRATION.md para SQL completo)
```

### Solução 2: Verificar Estrutura do Banco

```sql
-- Ver tabelas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%subscription%';

-- Ver planos
SELECT id, name, slug, price, is_trial 
FROM public.subscription_plans;

-- Ver estrutura de user_subscriptions
\d public.user_subscriptions
```

### Solução 3: Testar Chamada Manual

No console do navegador:

```javascript
// Obter token
const { data: { session } } = await supabase.auth.getSession();
const token = session.access_token;

// Chamar função
const { data, error } = await supabase.functions.invoke('create-pix-payment', {
  body: {
    planId: 'cole-um-id-valido-aqui',
    amount: 29.90,
    description: 'Teste'
  }
});

console.log('Resposta:', data);
console.log('Erro:', error);
```

---

## 📋 Checklist de Verificação

- [ ] Migration executada (tabelas criadas)
- [ ] Planos cadastrados (3 planos visíveis)
- [ ] Edge Function atualizada (código novo)
- [ ] Variáveis de ambiente configuradas
- [ ] Console do navegador sem erros
- [ ] Logs da Edge Function mostram sucesso

---

## 🎯 Resultado Esperado

Quando tudo estiver correto:

1. **Console do navegador:**
   ```
   ✅ Plano encontrado: {price: 29.9, name: "Mensal"}
   📤 Invocando create-pix-payment com: {...}
   Resposta da função: {success: true, data: {...}}
   ✅ Pagamento criado: {id: "...", qr_code: "..."}
   ```

2. **Logs da Edge Function:**
   ```
   🧾 Criando pagamento para plano: ...
   ✅ Pagamento criado com sucesso: ...
   ```

3. **Interface:**
   - Modal PIX abre
   - QR Code aparece
   - Valor correto exibido

---

## ❓ Ainda com Problema?

Se após seguir todos os passos ainda houver erro:

1. **Copie** os logs do console do navegador
2. **Copie** os logs da Edge Function
3. **Tire** um print da tela
4. **Compartilhe** para análise detalhada

Os logs vão mostrar exatamente onde está travando! 🔍
