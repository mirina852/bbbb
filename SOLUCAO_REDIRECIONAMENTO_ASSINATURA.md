# 🔧 Solução: Redirecionamento para Assinatura ao Recarregar

## 🎯 Problema Identificado
Quando você recarrega qualquer página do admin (F5), está sendo redirecionado para `/admin/subscription`.

**Causa:** O sistema verifica se você tem uma assinatura ativa. Se não tiver, redireciona automaticamente.

---

## 🚀 Soluções (escolha uma)

### **Solução 1: Desabilitar verificação de assinatura (DESENVOLVIMENTO)**
Use esta solução se estiver em **desenvolvimento/teste** e não quiser lidar com assinaturas ainda.

### **Solução 2: Criar assinatura de teste gratuita (PRODUÇÃO)**
Use esta solução se quiser testar o fluxo completo com assinatura.

---

## 📝 Solução 1: Desabilitar Verificação (Desenvolvimento)

### **Passo 1: Editar App.tsx**
Remova `requireSubscription` das rotas protegidas:

**Arquivo:** `src/App.tsx`

**Antes:**
```typescript
<Route path="/admin" element={
  <ProtectedRoute requireAdmin requireSubscription>
    <Dashboard />
  </ProtectedRoute>
} />
```

**Depois:**
```typescript
<Route path="/admin" element={
  <ProtectedRoute requireAdmin>
    <Dashboard />
  </ProtectedRoute>
} />
```

**Faça isso para TODAS as rotas admin:**
- `/admin` (Dashboard)
- `/admin/products` (Produtos)
- `/admin/orders` (Pedidos)
- `/admin/settings` (Configurações)

### **Resultado:**
✅ Você poderá acessar todas as páginas sem assinatura
✅ Não será mais redirecionado ao recarregar

---

## 💳 Solução 2: Criar Assinatura de Teste (Produção)

### **Passo 1: Verificar se as tabelas existem**
Execute no **Supabase SQL Editor**:

```sql
-- Verificar se tabelas de assinatura existem
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('subscription_plans', 'user_subscriptions');
```

**Se retornar vazio**, execute a migration:
```sql
-- Arquivo: supabase/migrations/20251010193700_create_subscription_tables.sql
-- (Copie e execute o conteúdo desse arquivo)
```

### **Passo 2: Criar plano gratuito**
Execute no **Supabase SQL Editor**:

```sql
-- Criar plano de teste gratuito (7 dias)
INSERT INTO subscription_plans (
  name, 
  slug, 
  price, 
  duration_days, 
  is_trial, 
  features
) VALUES (
  'Teste Gratuito',
  'teste-gratuito',
  0,
  7,
  true,
  ARRAY['Loja online completa', 'Gestão de pedidos', 'Dashboard', 'Suporte']
) ON CONFLICT (slug) DO NOTHING;

-- Verificar se foi criado
SELECT * FROM subscription_plans WHERE slug = 'teste-gratuito';
```

### **Passo 3: Criar assinatura para seu usuário**
Execute no **Supabase SQL Editor**:

```sql
-- Buscar seu user_id
SELECT id, email FROM auth.users ORDER BY created_at DESC LIMIT 5;

-- Copie seu user_id e use abaixo
-- Criar assinatura de teste (substitua USER_ID_AQUI)
INSERT INTO user_subscriptions (
  user_id,
  subscription_plan_id,
  status,
  expires_at
)
SELECT 
  'USER_ID_AQUI'::uuid,  -- ← Substitua pelo seu user_id
  id,
  'active',
  NOW() + INTERVAL '7 days'
FROM subscription_plans 
WHERE slug = 'teste-gratuito'
LIMIT 1;

-- Verificar se foi criada
SELECT 
  us.*,
  sp.name as plan_name
FROM user_subscriptions us
JOIN subscription_plans sp ON sp.id = us.subscription_plan_id
WHERE us.user_id = 'USER_ID_AQUI'::uuid;  -- ← Substitua pelo seu user_id
```

### **Passo 4: Recarregar a página**
1. Volte para o painel admin
2. Aperte **F5**
3. ✅ Agora deve permanecer na página sem redirecionar

---

## 🔍 Como Funciona o Redirecionamento

### **Fluxo atual:**
```
1. Usuário recarrega página (F5)
   ↓
2. ProtectedRoute verifica autenticação
   ✅ Usuário está autenticado
   ↓
3. ProtectedRoute verifica assinatura
   ❌ Não tem assinatura ativa
   ↓
4. Redireciona para /admin/subscription
```

### **Código responsável:**
```typescript
// src/components/auth/ProtectedRoute.tsx (linha 40-43)
if (requireSubscription && !isSubscriptionActive) {
  return <Navigate to="/admin/subscription" state={{ from: location }} replace />;
}
```

### **Verificação de assinatura:**
```typescript
// src/contexts/SubscriptionContext.tsx (linha 46)
const isSubscriptionActive = subscription !== null && subscription.status === 'active';
```

---

## 🧪 Como Testar

### **Teste 1: Verificar se tem assinatura**
Execute no **Supabase SQL Editor**:

```sql
-- Verificar assinatura do usuário logado
SELECT 
  us.id,
  us.status,
  us.expires_at,
  sp.name as plan_name,
  CASE 
    WHEN us.expires_at > NOW() THEN 'Ativa'
    ELSE 'Expirada'
  END as status_atual
FROM user_subscriptions us
JOIN subscription_plans sp ON sp.id = us.subscription_plan_id
WHERE us.user_id = auth.uid()
ORDER BY us.created_at DESC
LIMIT 1;
```

**Resultado esperado:**
- ✅ Se retornar dados com `status = 'active'` e `expires_at` no futuro → Tem assinatura
- ❌ Se retornar vazio ou expirada → Não tem assinatura (por isso redireciona)

### **Teste 2: Verificar função RPC**
Execute no **Supabase SQL Editor**:

```sql
-- Testar função que busca assinatura ativa
SELECT * FROM get_active_subscription(auth.uid());
```

**Resultado esperado:**
- ✅ Se retornar dados → Função funciona
- ❌ Se der erro → Função não existe (precisa executar migration)

---

## 📊 Comparação das Soluções

| Aspecto | Solução 1 (Desabilitar) | Solução 2 (Criar Teste) |
|---------|-------------------------|-------------------------|
| **Rapidez** | ⚡ Imediato (1 minuto) | 🐢 Requer SQL (5 minutos) |
| **Produção** | ❌ Não recomendado | ✅ Recomendado |
| **Teste completo** | ❌ Não testa assinaturas | ✅ Testa fluxo completo |
| **Reversível** | ✅ Fácil de reverter | ✅ Pode expirar/deletar |

---

## 🎯 Recomendação

### **Para desenvolvimento:**
Use **Solução 1** (desabilitar verificação) para trabalhar sem interrupções.

### **Para testar antes de produção:**
Use **Solução 2** (criar assinatura de teste) para garantir que tudo funciona.

### **Para produção:**
Mantenha a verificação ativa e implemente o fluxo de pagamento completo.

---

## 🔧 Script SQL Completo (Solução 2)

Execute tudo de uma vez no **Supabase SQL Editor**:

```sql
-- 1. Criar plano gratuito
INSERT INTO subscription_plans (
  name, slug, price, duration_days, is_trial, features
) VALUES (
  'Teste Gratuito', 'teste-gratuito', 0, 7, true,
  ARRAY['Loja online completa', 'Gestão de pedidos', 'Dashboard', 'Suporte']
) ON CONFLICT (slug) DO NOTHING;

-- 2. Buscar seu user_id
SELECT id, email FROM auth.users ORDER BY created_at DESC LIMIT 5;

-- 3. Criar assinatura (SUBSTITUA USER_ID_AQUI)
INSERT INTO user_subscriptions (
  user_id, subscription_plan_id, status, expires_at
)
SELECT 
  'USER_ID_AQUI'::uuid,  -- ← SUBSTITUA AQUI
  id, 'active', NOW() + INTERVAL '7 days'
FROM subscription_plans 
WHERE slug = 'teste-gratuito'
LIMIT 1;

-- 4. Verificar se funcionou
SELECT 
  us.status,
  us.expires_at,
  sp.name as plan_name,
  EXTRACT(DAY FROM (us.expires_at - NOW())) as dias_restantes
FROM user_subscriptions us
JOIN subscription_plans sp ON sp.id = us.subscription_plan_id
WHERE us.user_id = 'USER_ID_AQUI'::uuid  -- ← SUBSTITUA AQUI
ORDER BY us.created_at DESC
LIMIT 1;
```

---

## ✅ Checklist

### **Depois de aplicar a solução:**
- [ ] Recarreguei a página (F5)
- [ ] Não fui redirecionado para /admin/subscription
- [ ] Consigo acessar todas as páginas do admin
- [ ] Dados carregam normalmente

### **Se ainda redirecionar:**
- [ ] Verifiquei se a assinatura está ativa no banco
- [ ] Limpei o cache do navegador (Ctrl + Shift + R)
- [ ] Verifiquei o console (F12) para erros
- [ ] Tentei fazer logout e login novamente

---

## 🆘 Troubleshooting

### **Erro: "Função get_active_subscription não existe"**
**Solução:** Execute a migration `20251010193700_create_subscription_tables.sql`

### **Erro: "Tabela subscription_plans não existe"**
**Solução:** Execute a migration `20251010193700_create_subscription_tables.sql`

### **Ainda redireciona após criar assinatura**
**Solução:** 
1. Verifique se `expires_at` está no futuro
2. Verifique se `status = 'active'`
3. Faça logout e login novamente
4. Limpe o cache do navegador

---

## 📝 Resumo

**Problema:** Redirecionamento para `/admin/subscription` ao recarregar

**Causa:** Sistema verifica assinatura ativa

**Soluções:**
1. **Desenvolvimento:** Remover `requireSubscription` das rotas
2. **Produção:** Criar assinatura de teste no banco

**Recomendação:** Use Solução 1 para desenvolvimento rápido, Solução 2 para teste completo.
