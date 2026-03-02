# 🔔 Diagnóstico: Notificações não funcionando

## Problema
Você não está recebendo notificações quando pedidos são feitos, mesmo com as configurações habilitadas.

---

## ✅ Sistema de Notificações (Como funciona)

### 1. **Supabase Realtime**
- O sistema usa **Supabase Realtime** para detectar novos pedidos em tempo real
- Quando um pedido é inserido na tabela `orders`, o Supabase dispara um evento
- O hook `useOrderNotifications` escuta esse evento e mostra a notificação

### 2. **Componentes envolvidos**
- **Hook:** `src/hooks/useOrderNotifications.ts` (escuta novos pedidos)
- **Context:** `src/contexts/NotificationSettingsContext.tsx` (configurações)
- **Componente:** `src/components/settings/NotificationSettings.tsx` (interface)
- **Layout:** `src/layouts/AdminLayout.tsx` (ativa o hook)

---

## 🔍 Possíveis Causas

### ❌ Causa 1: Realtime não habilitado no Supabase
O Supabase Realtime pode estar desabilitado para a tabela `orders`.

**Como verificar:**
1. Abra o **Supabase Dashboard**
2. Vá em **Database → Replication**
3. Verifique se a tabela `orders` está na lista
4. Se não estiver, clique em **"Enable Replication"** para `orders`

**Solução SQL:**
```sql
-- Habilitar Realtime para a tabela orders
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
```

---

### ❌ Causa 2: Configurações desabilitadas
As notificações podem estar desabilitadas nas configurações.

**Como verificar:**
1. Acesse **Admin → Configurações → Notificações**
2. Verifique se **"Notificações de Novos Pedidos"** está **ATIVADO** (laranja)
3. Verifique se **"Som de Notificação"** está **ATIVADO**

**Solução:**
- Ative os toggles nas configurações
- Clique em **"Testar Som"** para verificar se funciona

---

### ❌ Causa 3: store_id NULL nos pedidos
Se os pedidos não têm `store_id`, o filtro do Realtime não funciona.

**Como verificar:**
```sql
-- Ver últimos pedidos e verificar se store_id está preenchido
SELECT id, customer_name, store_id, total, created_at 
FROM orders 
ORDER BY created_at DESC 
LIMIT 10;
```

**Solução:**
- Execute o script `SQL_CORRIGIR_ORDER_ITEMS_URGENTE.sql` que já foi criado
- Isso garante que `store_id` seja obrigatório

---

### ❌ Causa 4: Navegador bloqueando som
Navegadores modernos bloqueiam sons automáticos até que o usuário interaja com a página.

**Como verificar:**
1. Abra o **Console do navegador** (F12)
2. Procure por erros como: `"The AudioContext was not allowed to start"`

**Solução:**
- Clique em qualquer lugar da página para ativar o contexto de áudio
- Teste o som nas configurações após clicar na página

---

### ❌ Causa 5: Você não está na página de admin
O hook `useOrderNotifications` só funciona dentro do `AdminLayout`.

**Como verificar:**
- As notificações **SÓ FUNCIONAM** quando você está logado como admin
- Você precisa estar em uma página como: `/admin/dashboard`, `/admin/orders`, etc.

**Solução:**
- Faça login como admin
- Acesse qualquer página do painel administrativo
- Deixe a aba aberta enquanto aguarda pedidos

---

## 🧪 Como Testar

### Teste 1: Verificar se o Realtime está conectado
1. Abra o **Console do navegador** (F12)
2. Faça login no admin
3. Procure por logs como:
   ```
   Iniciando subscription de notificações para loja: [uuid]
   Status da subscription: SUBSCRIBED
   ```
4. ✅ Se aparecer `SUBSCRIBED`, o Realtime está funcionando

### Teste 2: Criar um pedido de teste
1. Abra **duas abas** do navegador:
   - **Aba 1:** Painel admin (ex: `/admin/dashboard`)
   - **Aba 2:** Loja pública (ex: `/loja/seu-slug`)
2. Na **Aba 2**, faça um pedido
3. Na **Aba 1**, você deve ver:
   - ✅ Notificação toast no canto da tela
   - ✅ Som de notificação (se habilitado)

### Teste 3: Testar som manualmente
1. Vá em **Admin → Configurações → Notificações**
2. Clique em **"Testar Som"**
3. ✅ Você deve ouvir o som configurado

---

## 🚀 Solução Rápida (Passo a Passo)

### Passo 1: Habilitar Realtime no Supabase
```sql
-- Execute no Supabase SQL Editor
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
```

### Passo 2: Verificar configurações
1. Acesse **Admin → Configurações → Notificações**
2. Ative **"Notificações de Novos Pedidos"**
3. Ative **"Som de Notificação"**
4. Clique em **"Testar Som"**

### Passo 3: Garantir que store_id está preenchido
```sql
-- Execute no Supabase SQL Editor
-- Verificar se store_id existe e está preenchido
SELECT 
  COUNT(*) as total_pedidos,
  COUNT(store_id) as pedidos_com_store_id,
  COUNT(*) - COUNT(store_id) as pedidos_sem_store_id
FROM orders;
```

Se houver pedidos sem `store_id`, execute:
```sql
-- Corrigir pedidos antigos (ajuste o UUID da sua loja)
UPDATE orders 
SET store_id = 'SEU_STORE_ID_AQUI'
WHERE store_id IS NULL;
```

### Passo 4: Testar
1. Abra o painel admin
2. Abra o console (F12) para ver logs
3. Faça um pedido de teste
4. ✅ Deve aparecer notificação + som

---

## 📊 Logs de Debug

### Logs esperados (Console do navegador)
```
✅ Iniciando subscription de notificações para loja: abc123...
✅ Status da subscription: SUBSCRIBED
✅ Novo pedido recebido: { new: { id: "...", customer_name: "..." } }
```

### Logs de erro comuns
```
❌ Nenhuma loja disponível para receber notificações
   → Solução: Faça login e selecione uma loja

❌ Store ID não disponível para notificações
   → Solução: Verifique se você tem uma loja criada

❌ Notificações desabilitadas
   → Solução: Ative nas configurações

❌ The AudioContext was not allowed to start
   → Solução: Clique na página antes de testar o som
```

---

## 🔧 Script de Verificação Completo

Execute este SQL no Supabase para verificar tudo:

```sql
-- 1. Verificar se Realtime está habilitado
SELECT schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename = 'orders';

-- 2. Verificar estrutura da tabela orders
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND column_name IN ('id', 'store_id', 'customer_name', 'total', 'created_at')
ORDER BY ordinal_position;

-- 3. Verificar últimos pedidos
SELECT 
  id, 
  customer_name, 
  store_id, 
  total, 
  status,
  created_at 
FROM orders 
ORDER BY created_at DESC 
LIMIT 5;

-- 4. Contar pedidos por loja
SELECT 
  s.name as loja,
  COUNT(o.id) as total_pedidos
FROM stores s
LEFT JOIN orders o ON o.store_id = s.id
GROUP BY s.id, s.name
ORDER BY total_pedidos DESC;
```

---

## ✅ Checklist Final

- [ ] Realtime habilitado para tabela `orders`
- [ ] Notificações ativadas nas configurações
- [ ] Som de notificação ativado
- [ ] Teste de som funcionando
- [ ] `store_id` preenchido nos pedidos
- [ ] Console mostra "SUBSCRIBED"
- [ ] Pedido de teste dispara notificação

---

## 🆘 Ainda não funciona?

Se após seguir todos os passos ainda não funcionar:

1. **Verifique o console do navegador** (F12) e copie os logs
2. **Tire um print** da aba de Notificações nas Configurações
3. **Execute o script de verificação SQL** e copie o resultado
4. **Verifique se há erros** na aba Network (F12) relacionados ao Supabase

Com essas informações, será possível identificar o problema específico.
