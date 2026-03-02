# ✅ Correção: Isolamento de Dados no Dashboard

## Problema

No painel (Dashboard), os dados estavam aparecendo de forma geral, juntando informações de todos os usuários:
- Status dos Pedidos
- Visão Geral dos Pedidos
- Receita por Período
- Produtos Disponíveis
- Receita Total
- Total de Pedidos

Cada dono de negócio via dados de **todas as lojas**, não apenas da sua.

### Comportamento Anterior (❌):

```
Admin da Loja A:
  Total de Pedidos: 50 (Loja A + B + C) ❌
  Receita Total: R$ 5.000 (Loja A + B + C) ❌
  Produtos Disponíveis: 30 (Loja A + B + C) ❌

Admin da Loja B:
  Total de Pedidos: 50 (mesmos dados!) ❌
  Receita Total: R$ 5.000 (mesmos dados!) ❌
  Produtos Disponíveis: 30 (mesmos dados!) ❌
```

## Causa

O hook `useDashboardData` estava buscando **todos os pedidos e produtos** sem filtrar por `store_id`.

### Código Antigo (❌):

```typescript
// useDashboardData.ts
export const useDashboardData = () => {
  // ❌ Busca TODOS os pedidos
  const { data: orders = [] } = useQuery({
    queryKey: ['orders'],
    queryFn: ordersService.getAll, // Sem store_id
  });

  // ❌ Busca TODOS os produtos
  const { data: products = [] } = useQuery({
    queryKey: ['products'],
    queryFn: productsService.getAllForAdmin, // Sem store_id
  });
  
  // Cálculos baseados em TODOS os dados
  const totalOrders = orders.length;
  const totalRevenue = orders.reduce((sum, order) => sum + order.total, 0);
  const totalProducts = products.filter(p => p.available).length;
};
```

## Solução Aplicada

Modificado o hook para usar `StoreContext` e filtrar dados por `store_id`.

### Código Novo (✅):

```typescript
// useDashboardData.ts
import { useStore } from '@/contexts/StoreContext';

export const useDashboardData = () => {
  const { currentStore } = useStore();

  // ✅ Busca apenas pedidos da loja atual
  const { data: orders = [], refetch: refetchOrders } = useQuery({
    queryKey: ['orders', currentStore?.id],
    queryFn: () => currentStore?.id 
      ? ordersService.getAll(currentStore.id) 
      : Promise.resolve([]),
    enabled: !!currentStore?.id,
    refetchInterval: 30000,
  });

  // ✅ Busca apenas produtos da loja atual
  const { data: products = [], refetch: refetchProducts } = useQuery({
    queryKey: ['products', currentStore?.id],
    queryFn: () => currentStore?.id 
      ? productsService.getAllForAdmin(currentStore.id) 
      : Promise.resolve([]),
    enabled: !!currentStore?.id,
    refetchInterval: 30000,
  });
  
  // Cálculos baseados apenas nos dados da loja atual
  const totalOrders = orders.length;
  const totalRevenue = orders.reduce((sum, order) => sum + order.total, 0);
  const totalCustomers = new Set(orders.map(order => order.customerName)).size;
  const totalProducts = products.filter(p => p.available).length;
};
```

## Como Funciona Agora

### Fluxo:

```
1. Admin faz login
   ↓
2. StoreContext carrega loja do admin
   ↓
3. currentStore.id = "abc123..."
   ↓
4. Dashboard usa useDashboardData()
   ↓
5. useQuery chama ordersService.getAll(currentStore.id)
   ↓
6. Query SQL: SELECT * FROM orders WHERE store_id = 'abc123...'
   ↓
7. useQuery chama productsService.getAllForAdmin(currentStore.id)
   ↓
8. Query SQL: SELECT * FROM products WHERE store_id = 'abc123...'
   ↓
9. Cálculos baseados apenas nos dados da loja
   ↓
10. ✅ Dashboard mostra apenas dados da loja do admin
```

### Comportamento Novo (✅):

```
Admin da Loja A (store_id: abc123):
  Total de Pedidos: 20 (apenas Loja A) ✅
  Receita Total: R$ 2.000 (apenas Loja A) ✅
  Produtos Disponíveis: 10 (apenas Loja A) ✅

Admin da Loja B (store_id: def456):
  Total de Pedidos: 15 (apenas Loja B) ✅
  Receita Total: R$ 1.500 (apenas Loja B) ✅
  Produtos Disponíveis: 8 (apenas Loja B) ✅

Admin da Loja C (store_id: ghi789):
  Total de Pedidos: 15 (apenas Loja C) ✅
  Receita Total: R$ 1.500 (apenas Loja C) ✅
  Produtos Disponíveis: 12 (apenas Loja C) ✅
```

## Exemplo Prático

### Banco de Dados:

```sql
-- Tabela orders
id  | store_id | customer_name | total  | status
----|----------|---------------|--------|--------
#1  | abc123   | João          | 50.00  | delivered
#2  | def456   | Maria         | 30.00  | pending
#3  | abc123   | Pedro         | 70.00  | delivered
#4  | ghi789   | Ana           | 40.00  | preparing
#5  | abc123   | Carlos        | 60.00  | delivered

-- Tabela products
id  | store_id | name          | price  | available
----|----------|---------------|--------|----------
#1  | abc123   | X-Burger      | 25.00  | true
#2  | def456   | Pizza         | 35.00  | true
#3  | abc123   | X-Frango      | 20.00  | true
#4  | ghi789   | Suco          | 10.00  | true
#5  | abc123   | Coca          | 5.00   | false
```

### Antes (❌):

```typescript
// Admin da Loja A (store_id: abc123)
ordersService.getAll() // Sem filtro
// Retorna: #1, #2, #3, #4, #5 (todos!)
// Total de Pedidos: 5
// Receita Total: R$ 250.00

productsService.getAllForAdmin() // Sem filtro
// Retorna: #1, #2, #3, #4, #5 (todos!)
// Produtos Disponíveis: 4
```

### Depois (✅):

```typescript
// Admin da Loja A (store_id: abc123)
ordersService.getAll('abc123')
// Retorna: #1, #3, #5 (apenas Loja A)
// Total de Pedidos: 3
// Receita Total: R$ 180.00

productsService.getAllForAdmin('abc123')
// Retorna: #1, #3, #5 (apenas Loja A)
// Produtos Disponíveis: 2 (apenas available: true)

// Admin da Loja B (store_id: def456)
ordersService.getAll('def456')
// Retorna: #2 (apenas Loja B)
// Total de Pedidos: 1
// Receita Total: R$ 30.00

productsService.getAllForAdmin('def456')
// Retorna: #2 (apenas Loja B)
// Produtos Disponíveis: 1
```

## Dados Calculados

### Total de Pedidos

```typescript
const totalOrders = orders.length;
```

**Antes:** Contava todos os pedidos de todas as lojas
**Depois:** Conta apenas pedidos da loja atual

### Receita Total

```typescript
const totalRevenue = orders.reduce((sum, order) => sum + order.total, 0);
```

**Antes:** Somava receita de todas as lojas
**Depois:** Soma apenas receita da loja atual

### Total de Clientes

```typescript
const totalCustomers = new Set(orders.map(order => order.customerName)).size;
```

**Antes:** Contava clientes de todas as lojas
**Depois:** Conta apenas clientes da loja atual

### Produtos Disponíveis

```typescript
const totalProducts = products.filter(p => p.available).length;
```

**Antes:** Contava produtos de todas as lojas
**Depois:** Conta apenas produtos da loja atual

## Gráficos Também Isolados

### Gráfico de Pedidos por Dia

```typescript
export const generateOrdersChartData = (orders: Order[]) => {
  // Recebe apenas pedidos da loja atual
  // Gera dados apenas com esses pedidos
};
```

### Gráfico de Status dos Pedidos

```typescript
export const generateOrderStatusChartData = (orders: Order[]) => {
  // Recebe apenas pedidos da loja atual
  // Conta status apenas desses pedidos
};
```

### Gráfico de Receita

```typescript
// RevenueChart recebe orders filtrados
// Calcula receita apenas da loja atual
```

## Mudanças Implementadas

### 1. Importado `useStore`

```typescript
import { useStore } from '@/contexts/StoreContext';
```

### 2. Adicionado `currentStore`

```typescript
const { currentStore } = useStore();
```

### 3. Modificado Query de Pedidos

```typescript
// ANTES
queryKey: ['orders'],
queryFn: ordersService.getAll,

// DEPOIS
queryKey: ['orders', currentStore?.id],
queryFn: () => currentStore?.id 
  ? ordersService.getAll(currentStore.id) 
  : Promise.resolve([]),
enabled: !!currentStore?.id,
```

### 4. Modificado Query de Produtos

```typescript
// ANTES
queryKey: ['products'],
queryFn: productsService.getAllForAdmin,

// DEPOIS
queryKey: ['products', currentStore?.id],
queryFn: () => currentStore?.id 
  ? productsService.getAllForAdmin(currentStore.id) 
  : Promise.resolve([]),
enabled: !!currentStore?.id,
```

### 5. Adicionado `enabled`

```typescript
enabled: !!currentStore?.id
```

**Por que?**
- Só executa a query se `currentStore.id` existir
- Evita erros se loja ainda não foi carregada
- Melhora performance

## Real-time Updates

Os updates em tempo real também foram isolados:

```typescript
// Real-time para pedidos
useEffect(() => {
  const channel = supabase
    .channel('dashboard-orders')
    .on('postgres_changes', { table: 'orders' }, () => {
      refetchOrders(); // Refaz query com filtro de store_id
    })
    .subscribe();
}, [refetchOrders]);
```

**Como funciona:**
1. Pedido novo é criado na Loja A
2. Real-time detecta mudança
3. `refetchOrders()` é chamado
4. Query busca apenas pedidos da Loja A (com filtro)
5. Dashboard da Loja A atualiza ✅
6. Dashboard da Loja B não muda ✅

## Arquivo Modificado

**`src/hooks/useDashboardData.ts`**

### Mudanças:

**Linha 6:** Importado `useStore`
```typescript
import { useStore } from '@/contexts/StoreContext';
```

**Linha 18:** Adicionado `currentStore`
```typescript
const { currentStore } = useStore();
```

**Linhas 29-34:** Query de pedidos com filtro
```typescript
const { data: orders = [], refetch: refetchOrders } = useQuery({
  queryKey: ['orders', currentStore?.id],
  queryFn: () => currentStore?.id ? ordersService.getAll(currentStore.id) : Promise.resolve([]),
  enabled: !!currentStore?.id,
  refetchInterval: 30000,
});
```

**Linhas 37-42:** Query de produtos com filtro
```typescript
const { data: products = [], refetch: refetchProducts } = useQuery({
  queryKey: ['products', currentStore?.id],
  queryFn: () => currentStore?.id ? productsService.getAllForAdmin(currentStore.id) : Promise.resolve([]),
  enabled: !!currentStore?.id,
  refetchInterval: 30000,
});
```

## Teste

### Teste 1: Dashboard Isolado

```
1. Faça login como admin da Loja A
2. Vá para /admin/dashboard
3. Anote os números:
   - Total de Pedidos: X
   - Receita Total: Y
   - Produtos Disponíveis: Z
4. Faça logout
5. Faça login como admin da Loja B
6. Vá para /admin/dashboard
7. ✅ Números devem ser diferentes
8. ✅ Não deve mostrar dados da Loja A
```

### Teste 2: Gráficos Isolados

```
1. Login como admin da Loja A
2. Vá para /admin/dashboard
3. Veja o gráfico de "Pedidos por Dia"
4. ✅ Deve mostrar apenas pedidos da Loja A
5. Veja o gráfico de "Status dos Pedidos"
6. ✅ Deve contar apenas pedidos da Loja A
```

### Teste 3: Real-time Isolado

```
1. Abra 2 abas do navegador
2. Aba 1: Login como admin da Loja A
3. Aba 2: Login como admin da Loja B
4. Crie um pedido na Loja A (como cliente)
5. ✅ Dashboard da Loja A deve atualizar
6. ✅ Dashboard da Loja B não deve mudar
```

### Teste 4: Console

```
1. Abra DevTools (F12) → Network
2. Vá para /admin/dashboard
3. Procure requisição para /orders
4. ✅ Deve ter filtro: ?store_id=eq.abc123...
5. Procure requisição para /products
6. ✅ Deve ter filtro: ?store_id=eq.abc123...
```

## Checklist

- [x] Importado `useStore`
- [x] Adicionado `currentStore`
- [x] Query de pedidos com `store_id`
- [x] Query de produtos com `store_id`
- [x] Adicionado `enabled` nas queries
- [x] QueryKey inclui `currentStore?.id`
- [ ] **Recarregar aplicação** ← FAÇA AGORA!
- [ ] **Testar dashboard** ← VERIFIQUE!

## Próximos Passos

1. **Recarregue** a aplicação (Ctrl+R)
2. **Faça login** como admin
3. **Vá para** `/admin/dashboard`
4. **Verifique** que os números são apenas da sua loja ✅

---

**Recarregue a aplicação e verifique o dashboard!** 📊🔒
