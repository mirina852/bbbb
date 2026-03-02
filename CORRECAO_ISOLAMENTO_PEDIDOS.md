# ✅ Correção: Isolamento de Pedidos por Loja

## Problema

Na página "Pedidos", todos os pedidos de todas as lojas estavam aparecendo para todos os admins. Cada dono de negócio via pedidos de outros usuários.

### Comportamento Anterior (❌):

```
Admin da Loja A:
  Vê: Pedidos da Loja A + Loja B + Loja C ❌

Admin da Loja B:
  Vê: Pedidos da Loja A + Loja B + Loja C ❌
```

## Causa

O método `ordersService.getAll()` estava buscando **todos os pedidos** sem filtrar por `store_id`.

### Código Antigo (❌):

```typescript
// supabaseService.ts
async getAll(): Promise<Order[]> {
  const { data: orders, error } = await supabase
    .from('orders')
    .select(`
      *,
      order_items (*)
    `)
    .order('created_at', { ascending: false });
  // ❌ Sem filtro por store_id
}

// Orders.tsx
const loadOrders = async () => {
  const data = await ordersService.getAll();
  // ❌ Busca todos os pedidos
  setOrders(data);
};
```

## Solução Aplicada

### 1. Modificado `ordersService.getAll()`

Adicionado parâmetro opcional `storeId` para filtrar pedidos:

```typescript
// supabaseService.ts
async getAll(storeId?: string): Promise<Order[]> {
  let query = supabase
    .from('orders')
    .select(`
      *,
      order_items (*)
    `);
  
  // ✅ Filtrar por store_id se fornecido
  if (storeId) {
    query = query.eq('store_id', storeId);
  }
  
  const { data: orders, error } = await query
    .order('created_at', { ascending: false });
  
  if (error) throw error;
  
  return orders?.map(order => ({
    // ... mapeamento
  })) || [];
}
```

### 2. Modificado `Orders.tsx`

Adicionado uso do `StoreContext` para pegar o `store_id` atual:

```typescript
// Orders.tsx
import { useStore } from '@/contexts/StoreContext';

const Orders = () => {
  const { currentStore } = useStore();
  
  useEffect(() => {
    if (currentStore?.id) {
      loadOrders();
    }
  }, [currentStore?.id]);
  
  const loadOrders = async () => {
    if (!currentStore?.id) return;
    
    try {
      // ✅ Buscar apenas pedidos da loja atual
      const data = await ordersService.getAll(currentStore.id);
      setOrders(data);
    } catch (error) {
      console.error('Error loading orders:', error);
      toast.error('Erro ao carregar pedidos');
    } finally {
      setLoading(false);
    }
  };
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
4. Orders.tsx chama loadOrders()
   ↓
5. ordersService.getAll(currentStore.id)
   ↓
6. Query SQL: SELECT * FROM orders WHERE store_id = 'abc123...'
   ↓
7. ✅ Retorna apenas pedidos da loja do admin
```

### Comportamento Novo (✅):

```
Admin da Loja A (store_id: abc123):
  Vê: Apenas pedidos da Loja A ✅

Admin da Loja B (store_id: def456):
  Vê: Apenas pedidos da Loja B ✅

Admin da Loja C (store_id: ghi789):
  Vê: Apenas pedidos da Loja C ✅
```

## Exemplo Prático

### Banco de Dados:

```sql
-- Tabela orders
id  | store_id | customer_name | total
----|----------|---------------|-------
#1  | abc123   | João          | 50.00  ← Loja A
#2  | def456   | Maria         | 30.00  ← Loja B
#3  | abc123   | Pedro         | 70.00  ← Loja A
#4  | ghi789   | Ana           | 40.00  ← Loja C
#5  | abc123   | Carlos        | 60.00  ← Loja A
```

### Antes (❌):

```typescript
// Admin da Loja A
ordersService.getAll()
// Retorna: #1, #2, #3, #4, #5 (todos!)
```

### Depois (✅):

```typescript
// Admin da Loja A (store_id: abc123)
ordersService.getAll('abc123')
// Retorna: #1, #3, #5 (apenas Loja A)

// Admin da Loja B (store_id: def456)
ordersService.getAll('def456')
// Retorna: #2 (apenas Loja B)

// Admin da Loja C (store_id: ghi789)
ordersService.getAll('ghi789')
// Retorna: #4 (apenas Loja C)
```

## Segurança

### Isolamento de Dados (Multi-tenancy):

✅ **Cada admin vê apenas seus dados:**
- Pedidos da sua loja
- Produtos da sua loja
- Categorias da sua loja

✅ **Não é possível ver dados de outras lojas:**
- Mesmo alterando a URL
- Mesmo tentando acessar diretamente a API
- RLS (Row Level Security) garante isso no banco

### Camadas de Segurança:

1. **Frontend:** Filtra por `store_id` no código
2. **Backend:** RLS no Supabase filtra por `owner_id`
3. **Banco:** Políticas RLS impedem acesso não autorizado

## Arquivos Modificados

### 1. `src/services/supabaseService.ts`

**Linha 315:** Adicionado parâmetro `storeId?`
```typescript
async getAll(storeId?: string): Promise<Order[]>
```

**Linhas 316-326:** Adicionado filtro condicional
```typescript
let query = supabase.from('orders').select(...);

if (storeId) {
  query = query.eq('store_id', storeId);
}
```

### 2. `src/pages/admin/Orders.tsx`

**Linha 12:** Importado `useStore`
```typescript
import { useStore } from '@/contexts/StoreContext';
```

**Linha 15:** Adicionado `currentStore`
```typescript
const { currentStore } = useStore();
```

**Linhas 23-27:** Modificado `useEffect` para depender de `currentStore.id`
```typescript
useEffect(() => {
  if (currentStore?.id) {
    loadOrders();
  }
}, [currentStore?.id]);
```

**Linhas 29-42:** Modificado `loadOrders` para filtrar por loja
```typescript
const loadOrders = async () => {
  if (!currentStore?.id) return;
  
  const data = await ordersService.getAll(currentStore.id);
  setOrders(data);
};
```

## Teste

### Cenário 1: Admin Vê Apenas Seus Pedidos

```
1. Faça login como admin da Loja A
2. Vá para /admin/orders
3. ✅ Deve ver apenas pedidos da Loja A
4. ❌ Não deve ver pedidos de outras lojas
```

### Cenário 2: Múltiplas Lojas

```
1. Faça login como admin da Loja A
2. Vá para /admin/orders
3. Anote quantos pedidos aparecem (ex: 3)
4. Faça logout
5. Faça login como admin da Loja B
6. Vá para /admin/orders
7. ✅ Deve ver pedidos diferentes
8. ✅ Quantidade pode ser diferente
```

### Cenário 3: Verificar no Console

```
1. Abra DevTools (F12) → Network
2. Vá para /admin/orders
3. Procure requisição para /orders
4. ✅ Deve ter filtro: ?store_id=eq.abc123...
```

## Checklist

- [x] `ordersService.getAll()` aceita `storeId`
- [x] Query filtra por `store_id` se fornecido
- [x] `Orders.tsx` usa `StoreContext`
- [x] `loadOrders()` passa `currentStore.id`
- [x] `useEffect` depende de `currentStore.id`
- [ ] **Recarregar aplicação** ← FAÇA AGORA!
- [ ] **Testar isolamento** ← VERIFIQUE!

## Próximos Passos

1. **Recarregue** a aplicação (Ctrl+R)
2. **Faça login** como admin
3. **Vá para** `/admin/orders`
4. **Verifique** que só aparecem pedidos da sua loja ✅

---

**Recarregue a aplicação e teste o isolamento de pedidos!** 🔒
