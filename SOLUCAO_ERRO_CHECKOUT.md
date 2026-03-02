# 🔧 Solução: Erro ao Criar Pedido (Checkout)

## Erro

```
POST /rest/v1/orders 401 (Unauthorized)
Error: new row violates row-level security policy for table "orders"
```

## Problema

Clientes **não autenticados** (sem login) estão tentando criar pedidos, mas as políticas RLS da tabela `orders` **bloqueiam** a inserção.

### Contexto:

Na página pública (`/s/[slug]`), clientes:
1. ✅ Veem produtos
2. ✅ Adicionam ao carrinho
3. ✅ Preenchem dados de entrega
4. ❌ **Erro ao finalizar pedido** (checkout)

### Causa:

A tabela `orders` tem RLS habilitado mas **não tem política pública** para permitir que clientes não autenticados criem pedidos.

## Solução

Criar políticas RLS que permitem:
- ✅ **Clientes (público)** podem criar pedidos
- ✅ **Admin (autenticado)** pode gerenciar pedidos da sua loja

## Scripts SQL

### 1. Corrigir RLS da Tabela `orders`

Execute **`CORRIGIR_RLS_ORDERS.sql`** ou copie este SQL:

```sql
-- Habilitar RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Remover políticas antigas
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create own orders" ON public.orders;
DROP POLICY IF EXISTS "Store owners can view their orders" ON public.orders;

-- Política 1: Clientes podem criar pedidos (SEM autenticação)
CREATE POLICY "allow_public_insert_orders"
ON public.orders
FOR INSERT
TO public
WITH CHECK (true);

-- Política 2: Admin pode ver pedidos da sua loja
CREATE POLICY "store_owners_can_view_orders"
ON public.orders
FOR SELECT
TO authenticated
USING (
  store_id IN (
    SELECT id FROM stores WHERE owner_id = auth.uid()
  )
);

-- Política 3: Admin pode atualizar pedidos
CREATE POLICY "store_owners_can_update_orders"
ON public.orders
FOR UPDATE
TO authenticated
USING (
  store_id IN (
    SELECT id FROM stores WHERE owner_id = auth.uid()
  )
)
WITH CHECK (
  store_id IN (
    SELECT id FROM stores WHERE owner_id = auth.uid()
  )
);

-- Política 4: Admin pode deletar pedidos
CREATE POLICY "store_owners_can_delete_orders"
ON public.orders
FOR DELETE
TO authenticated
USING (
  store_id IN (
    SELECT id FROM stores WHERE owner_id = auth.uid()
  )
);

-- Verificar
SELECT policyname, cmd, roles
FROM pg_policies
WHERE tablename = 'orders';
```

### 2. Corrigir RLS da Tabela `order_items`

Execute **`CORRIGIR_RLS_ORDER_ITEMS.sql`** ou copie este SQL:

```sql
-- Habilitar RLS
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Remover políticas antigas
DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can create own order items" ON public.order_items;

-- Política 1: Clientes podem criar itens de pedido
CREATE POLICY "allow_public_insert_order_items"
ON public.order_items
FOR INSERT
TO public
WITH CHECK (true);

-- Política 2: Admin pode ver itens dos pedidos da sua loja
CREATE POLICY "store_owners_can_view_order_items"
ON public.order_items
FOR SELECT
TO authenticated
USING (
  order_id IN (
    SELECT o.id FROM orders o
    JOIN stores s ON s.id = o.store_id
    WHERE s.owner_id = auth.uid()
  )
);

-- Política 3: Admin pode atualizar itens
CREATE POLICY "store_owners_can_update_order_items"
ON public.order_items
FOR UPDATE
TO authenticated
USING (
  order_id IN (
    SELECT o.id FROM orders o
    JOIN stores s ON s.id = o.store_id
    WHERE s.owner_id = auth.uid()
  )
);

-- Política 4: Admin pode deletar itens
CREATE POLICY "store_owners_can_delete_order_items"
ON public.order_items
FOR DELETE
TO authenticated
USING (
  order_id IN (
    SELECT o.id FROM orders o
    JOIN stores s ON s.id = o.store_id
    WHERE s.owner_id = auth.uid()
  )
);

-- Verificar
SELECT policyname, cmd, roles
FROM pg_policies
WHERE tablename = 'order_items';
```

## Como Funciona

### Fluxo do Pedido:

1. **Cliente (não autenticado)** acessa `/s/fcebook`
2. **Adiciona produtos** ao carrinho
3. **Preenche dados**:
   - Nome: "João Silva"
   - Telefone: "11999999999"
   - Endereço: "Rua A, 123"
   - Pagamento: "pix"
4. **Clica em "Finalizar Pedido"**
5. **Código tenta inserir** em `orders`:
   ```sql
   INSERT INTO orders (store_id, customer_name, ...) VALUES (...)
   ```
6. **RLS verifica** política `allow_public_insert_orders`
7. **Política permite** (`WITH CHECK (true)`)
8. **Pedido criado** ✅
9. **Código insere** itens em `order_items`
10. **RLS verifica** política `allow_public_insert_order_items`
11. **Política permite** (`WITH CHECK (true)`)
12. **Itens criados** ✅

### Políticas RLS:

#### Tabela `orders`:

| Política | Operação | Quem | Condição |
|----------|----------|------|----------|
| `allow_public_insert_orders` | INSERT | 🌐 Público | Sempre permite |
| `store_owners_can_view_orders` | SELECT | 🔐 Admin | Apenas pedidos da sua loja |
| `store_owners_can_update_orders` | UPDATE | 🔐 Admin | Apenas pedidos da sua loja |
| `store_owners_can_delete_orders` | DELETE | 🔐 Admin | Apenas pedidos da sua loja |

#### Tabela `order_items`:

| Política | Operação | Quem | Condição |
|----------|----------|------|----------|
| `allow_public_insert_order_items` | INSERT | 🌐 Público | Sempre permite |
| `store_owners_can_view_order_items` | SELECT | 🔐 Admin | Apenas itens de pedidos da sua loja |
| `store_owners_can_update_order_items` | UPDATE | 🔐 Admin | Apenas itens de pedidos da sua loja |
| `store_owners_can_delete_order_items` | DELETE | 🔐 Admin | Apenas itens de pedidos da sua loja |

## Segurança

### ✅ O que é permitido:

- Clientes podem criar pedidos (INSERT)
- Admin pode ver apenas pedidos da sua loja
- Admin pode atualizar/deletar apenas pedidos da sua loja

### ❌ O que é bloqueado:

- Clientes NÃO podem ver pedidos de outras pessoas
- Clientes NÃO podem atualizar/deletar pedidos
- Admin NÃO pode ver pedidos de outras lojas
- Admin NÃO pode modificar pedidos de outras lojas

### Exemplo de Isolamento:

```sql
-- Loja A (fcebook)
Pedidos: #1, #2, #3

-- Loja B (mercadinhowp)
Pedidos: #4, #5

-- Admin da Loja A (autenticado)
SELECT * FROM orders;
-- Retorna: #1, #2, #3 ✅
-- NÃO retorna: #4, #5 ❌

-- Cliente (não autenticado)
SELECT * FROM orders;
-- Retorna: nada ❌ (sem política SELECT para público)

-- Cliente (não autenticado)
INSERT INTO orders (...) VALUES (...);
-- Funciona! ✅ (política permite)
```

## Teste

### 1. Executar SQL
```
1. Abra Supabase SQL Editor
2. Execute CORRIGIR_RLS_ORDERS.sql
3. Execute CORRIGIR_RLS_ORDER_ITEMS.sql
4. Verifique que 4 políticas foram criadas em cada tabela
```

### 2. Testar Checkout
```
1. Abra /s/fcebook em aba anônima
2. Adicione produtos ao carrinho
3. Clique no carrinho
4. Preencha dados:
   - Nome: Teste Cliente
   - Telefone: 11999999999
   - Endereço: Rua Teste, 123
   - Pagamento: PIX
5. Clique em "Finalizar Pedido"
6. ✅ Pedido deve ser criado com sucesso!
7. ✅ Mensagem de sucesso deve aparecer
```

### 3. Verificar no Admin
```
1. Faça login como admin
2. Vá para /admin/orders
3. ✅ Pedido de teste deve aparecer
4. ✅ Deve mostrar itens do pedido
```

### 4. Verificar no Banco
```sql
-- Ver pedidos criados
SELECT 
  id,
  customer_name,
  total,
  status,
  created_at
FROM orders
ORDER BY created_at DESC
LIMIT 5;

-- Ver itens dos pedidos
SELECT 
  o.id as order_id,
  o.customer_name,
  oi.product_name,
  oi.quantity,
  oi.price
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
ORDER BY o.created_at DESC
LIMIT 10;
```

## Resultado Esperado

### Antes (❌):
```
Cliente tenta fazer pedido
→ POST /orders 401 Unauthorized
→ Erro: "violates row-level security policy"
→ Pedido NÃO é criado
```

### Depois (✅):
```
Cliente tenta fazer pedido
→ POST /orders 201 Created
→ Pedido criado com sucesso
→ Itens criados
→ Mensagem de sucesso
→ Admin vê o pedido
```

## Checklist

- [ ] Executar `CORRIGIR_RLS_ORDERS.sql`
- [ ] Executar `CORRIGIR_RLS_ORDER_ITEMS.sql`
- [ ] Verificar 4 políticas em `orders`
- [ ] Verificar 4 políticas em `order_items`
- [ ] Testar checkout na página pública
- [ ] Verificar pedido no admin
- [ ] Confirmar que pedido foi salvo no banco

## Arquivos Criados

1. **`CORRIGIR_RLS_ORDERS.sql`** - Corrigir políticas da tabela orders
2. **`CORRIGIR_RLS_ORDER_ITEMS.sql`** - Corrigir políticas da tabela order_items
3. **`SOLUCAO_ERRO_CHECKOUT.md`** - Este guia completo

---

**Execute os scripts SQL agora e o checkout vai funcionar!** 🎉🛒
