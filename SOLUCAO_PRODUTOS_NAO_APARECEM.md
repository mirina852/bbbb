# 🔧 Solução Completa: Produtos Não Aparecem na Página Pública

## Situação Atual

- ✅ Produtos existem no banco (`x-file`, `coca`)
- ✅ Produtos estão marcados como `available = true`
- ❌ Produtos **NÃO aparecem** na página pública `/s/fcebook`

## Possíveis Causas

### 1. Produtos sem `store_id`
Os produtos podem não estar vinculados à loja correta.

### 2. Políticas RLS bloqueando acesso público
As políticas de segurança podem estar impedindo acesso não autenticado.

### 3. Produtos sem categoria
A interface pode estar filtrando por categoria e não encontrando nada.

### 4. Código buscando tabela errada
O código pode estar buscando em `produtos` em vez de `products`.

## 🛠️ Solução Passo a Passo

### Passo 1: Verificar Detalhes dos Produtos

Execute **`VERIFICAR_PRODUTOS_DETALHES.sql`** no SQL Editor:

```sql
-- Ver todos os campos
SELECT 
  id,
  store_id,
  name,
  category,
  available
FROM products;
```

**Resultado esperado:**
```
name    | store_id           | category | available
--------|--------------------|-----------|-----------
x-file  | [uuid-da-loja]    | burger   | true
coca    | [uuid-da-loja]    | bebida   | true
```

**Problemas comuns:**

#### Problema A: `store_id` é NULL
```sql
-- Atribuir produtos à loja 'fcebook'
UPDATE products 
SET store_id = (SELECT id FROM stores WHERE slug = 'fcebook' LIMIT 1)
WHERE store_id IS NULL;
```

#### Problema B: `category` é NULL ou vazio
```sql
-- Definir categoria padrão
UPDATE products 
SET category = 'outros'
WHERE category IS NULL OR category = '';
```

#### Problema C: `available` é false
```sql
-- Tornar produtos disponíveis
UPDATE products 
SET available = true;
```

### Passo 2: Corrigir Políticas RLS

Execute **`CORRIGIR_RLS_PRODUTOS_PUBLICO.sql`**:

```sql
-- Remover políticas antigas
DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
DROP POLICY IF EXISTS "Users can view own store products" ON public.products;

-- Criar política para acesso PÚBLICO
CREATE POLICY "Public can view available products"
ON public.products FOR SELECT
TO public
USING (available = true);
```

**Por que isso é importante:**

- ✅ Permite que **clientes não autenticados** vejam produtos
- ✅ Filtra apenas produtos `available = true`
- ✅ Não requer login para ver a loja

### Passo 3: Verificar Código (Já Corrigido)

O código já foi corrigido para usar a tabela correta:

```typescript
// ✅ CORRETO
async getAllByStore(storeId: string) {
  const { data } = await supabase
    .from('products')  // ✅ Tabela correta
    .select('*')
    .eq('store_id', storeId)
    .eq('available', true);
}
```

### Passo 4: Testar Acesso Público

Execute no SQL Editor:

```sql
-- Simular acesso público (sem autenticação)
-- Este SELECT deve retornar produtos
SELECT 
  name,
  price,
  category,
  available,
  store_id
FROM products
WHERE available = true
  AND store_id = (SELECT id FROM stores WHERE slug = 'fcebook' LIMIT 1);
```

**Resultado esperado:**
```
name    | price | category | available | store_id
--------|-------|----------|-----------|----------
x-file  | 15.00 | burger   | true      | [uuid]
coca    | 5.00  | bebida   | true      | [uuid]
```

Se retornar produtos aqui, o problema é no código frontend.
Se não retornar, o problema é no banco de dados.

## 🧪 Teste Completo

### Teste 1: Verificar no Banco

```sql
-- 1. Ver lojas
SELECT id, name, slug FROM stores;

-- 2. Ver produtos da loja 'fcebook'
SELECT 
  p.name,
  p.category,
  p.available,
  p.store_id,
  s.slug as loja_slug
FROM products p
JOIN stores s ON s.id = p.store_id
WHERE s.slug = 'fcebook';
```

### Teste 2: Verificar Políticas RLS

```sql
-- Ver políticas de products
SELECT policyname, cmd, roles
FROM pg_policies
WHERE tablename = 'products';
```

**Deve ter:**
- ✅ `Public can view available products` (SELECT, public)
- ✅ `Authenticated users can...` (INSERT/UPDATE/DELETE, authenticated)

### Teste 3: Testar na Interface

1. **Abra o Console** (F12) na página `/s/fcebook`
2. **Veja os logs**:
   ```
   🔍 getAllByStore - Buscando produtos para loja: [id]
   ✅ Produtos encontrados: 2
   ```
3. **Se mostrar 0 produtos**, o problema é no banco
4. **Se mostrar 2 produtos mas não aparecer**, o problema é no frontend

## 📋 Checklist de Diagnóstico

Execute em ordem:

- [ ] **1. Produtos existem no banco?**
  ```sql
  SELECT COUNT(*) FROM products;
  ```

- [ ] **2. Produtos têm `store_id`?**
  ```sql
  SELECT name, store_id FROM products;
  ```

- [ ] **3. Produtos estão disponíveis?**
  ```sql
  SELECT name, available FROM products;
  ```

- [ ] **4. Produtos têm categoria?**
  ```sql
  SELECT name, category FROM products;
  ```

- [ ] **5. RLS permite acesso público?**
  ```sql
  SELECT policyname FROM pg_policies WHERE tablename = 'products' AND roles = '{public}';
  ```

- [ ] **6. Código busca tabela correta?**
  - Verificar: `from('products')` ✅
  - Não: `from('produtos')` ❌

## 🎯 Script de Correção Rápida

Execute este script para corrigir tudo de uma vez:

```sql
-- 1. Atribuir produtos à loja 'fcebook'
UPDATE products 
SET store_id = (SELECT id FROM stores WHERE slug = 'fcebook' LIMIT 1)
WHERE store_id IS NULL;

-- 2. Definir categoria padrão
UPDATE products 
SET category = 'outros'
WHERE category IS NULL OR category = '';

-- 3. Tornar produtos disponíveis
UPDATE products 
SET available = true;

-- 4. Remover políticas antigas
DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
DROP POLICY IF EXISTS "Users can view own store products" ON public.products;

-- 5. Criar política pública
CREATE POLICY "Public can view available products"
ON public.products FOR SELECT
TO public
USING (available = true);

-- 6. Verificar resultado
SELECT 
  p.name,
  p.category,
  p.available,
  s.slug as loja
FROM products p
JOIN stores s ON s.id = p.store_id
WHERE s.slug = 'fcebook';
```

## ✅ Resultado Esperado

Após executar as correções:

### No Banco de Dados:
```sql
SELECT name, store_id, category, available FROM products;
```
```
name    | store_id           | category | available
--------|--------------------|-----------|-----------
x-file  | [uuid-fcebook]    | burger   | true
coca    | [uuid-fcebook]    | bebida   | true
```

### Na Página Pública:
```
/s/fcebook
├── 🍔 fcebook (nome da loja)
├── 📦 Categorias
│   ├── Burger (1 produto)
│   └── Bebida (1 produto)
└── 🛒 Produtos
    ├── X-file - R$ 15,00
    └── Coca - R$ 5,00
```

## 🚀 Ordem de Execução

1. ✅ Execute **`VERIFICAR_PRODUTOS_DETALHES.sql`**
2. ✅ Execute **`CORRIGIR_RLS_PRODUTOS_PUBLICO.sql`**
3. ✅ Execute o **Script de Correção Rápida** acima
4. ✅ Recarregue a página `/s/fcebook`
5. ✅ Produtos devem aparecer!

## 📞 Se Ainda Não Funcionar

Envie os resultados de:

```sql
-- 1. Estrutura da tabela
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'products';

-- 2. Produtos existentes
SELECT * FROM products;

-- 3. Políticas RLS
SELECT * FROM pg_policies WHERE tablename = 'products';

-- 4. Lojas existentes
SELECT * FROM stores;
```

Execute os scripts agora e me avise o resultado! 🎉
