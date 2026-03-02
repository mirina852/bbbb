# ✅ Solução: Produtos de Exemplo Aparecendo em Novas Contas

## Problema Identificado

Novas contas estão vendo produtos já cadastrados (hambúrgueres) que não deveriam aparecer. Isso acontece porque:

1. **Migrations antigas** inserem produtos de exemplo
2. Esses produtos foram inseridos **ANTES** do sistema multi-tenant
3. Os produtos **não têm `store_id`** (são "globais")
4. As políticas RLS não filtram corretamente produtos sem `store_id`

## Como Aconteceu

### Ordem das Migrations:

```
1. 20250724135601 - Cria tabela products SEM store_id
   └─ INSERT produtos de exemplo (X-Frango, X-Tudo, etc.)

2. 20251011200000 - Adiciona store_id às tabelas (multi-tenant)
   └─ ALTER TABLE products ADD COLUMN store_id
   └─ Produtos antigos ficam com store_id = NULL
```

### Resultado:

- ❌ Produtos de exemplo têm `store_id = NULL`
- ❌ Aparecem para TODAS as lojas
- ❌ Novas contas veem produtos que não criaram

## Soluções

### Opção 1: Deletar Produtos de Exemplo (Recomendado)

**Vantagens:**
- ✅ Limpa o banco de dados
- ✅ Cada loja começa do zero
- ✅ Sem confusão com produtos de outras lojas

**Como fazer:**

```sql
-- Ver produtos sem loja
SELECT * FROM products WHERE store_id IS NULL;

-- Deletar produtos sem loja
DELETE FROM products WHERE store_id IS NULL;
```

### Opção 2: Atribuir Produtos a Uma Loja Específica

**Vantagens:**
- ✅ Mantém os produtos de exemplo
- ✅ Útil se você quiser usar esses produtos

**Como fazer:**

```sql
-- Ver suas lojas
SELECT id, name FROM stores;

-- Atribuir produtos a uma loja
UPDATE products 
SET store_id = '[ID-DA-SUA-LOJA]'
WHERE store_id IS NULL;
```

### Opção 3: Tornar store_id Obrigatório

**Vantagens:**
- ✅ Previne novos produtos sem loja
- ✅ Garante isolamento entre lojas

**Como fazer:**

```sql
-- Primeiro limpe ou atribua os produtos existentes
DELETE FROM products WHERE store_id IS NULL;

-- Depois torne obrigatório
ALTER TABLE products 
ALTER COLUMN store_id SET NOT NULL;
```

## 🧪 Como Executar

### Passo 1: Verificar o Problema

Execute no SQL Editor do Supabase:

```sql
-- Ver quantos produtos sem loja existem
SELECT COUNT(*) FROM products WHERE store_id IS NULL;

-- Ver detalhes
SELECT id, name, price, store_id 
FROM products 
WHERE store_id IS NULL;
```

### Passo 2: Escolher Solução

**Se quiser deletar:**

```sql
DELETE FROM products WHERE store_id IS NULL;
```

**Se quiser manter e atribuir a uma loja:**

```sql
-- Substitua [ID-DA-LOJA] pelo ID real
UPDATE products 
SET store_id = '[ID-DA-LOJA]'
WHERE store_id IS NULL;
```

### Passo 3: Verificar Resultado

```sql
-- Deve retornar 0
SELECT COUNT(*) FROM products WHERE store_id IS NULL;

-- Ver produtos por loja
SELECT 
  s.name as loja,
  COUNT(p.id) as total_produtos
FROM stores s
LEFT JOIN products p ON p.store_id = s.id
GROUP BY s.id, s.name;
```

## 📋 Script Completo

Use o arquivo **`LIMPAR_PRODUTOS_EXEMPLO.sql`** que contém:

1. ✅ Queries para verificar o problema
2. ✅ Comando para deletar produtos sem loja
3. ✅ Alternativa para atribuir a uma loja
4. ✅ Comando para tornar store_id obrigatório
5. ✅ Queries de verificação

## 🔧 Prevenir no Futuro

### 1. Remover INSERTs das Migrations

Edite as migrations antigas e comente os INSERTs:

```sql
-- ❌ REMOVER ISSO:
-- INSERT INTO products (name, description, price, ...) VALUES
-- ('X-Frango', '...', 15.00, ...),
-- ('X-Tudo', '...', 20.00, ...);
```

### 2. Atualizar Políticas RLS

Garantir que produtos sem `store_id` não apareçam:

```sql
-- Política para SELECT de produtos
DROP POLICY IF EXISTS "Products are viewable by everyone" ON products;

CREATE POLICY "Products are viewable by store"
ON products FOR SELECT
USING (
  store_id IS NOT NULL  -- ✅ Só mostra produtos com loja
);
```

### 3. Adicionar Validação no Código

No código TypeScript, sempre enviar `store_id`:

```typescript
// ✅ CORRETO
await supabase
  .from('products')
  .insert({
    name: 'Novo Produto',
    store_id: currentStore.id,  // ✅ Sempre enviar!
    // ... outros campos
  });

// ❌ ERRADO
await supabase
  .from('products')
  .insert({
    name: 'Novo Produto',
    // store_id faltando!
  });
```

## ✅ Resultado Final

Após aplicar a solução:

1. ✅ **Produtos sem `store_id` removidos** ou atribuídos
2. ✅ **Cada loja vê apenas seus produtos**
3. ✅ **Novas contas começam sem produtos**
4. ✅ **Sistema multi-tenant funcionando corretamente**

## 🎯 Recomendação

**Execute a Opção 1** (deletar produtos de exemplo):

```sql
-- Simples e eficaz
DELETE FROM products WHERE store_id IS NULL;
```

Depois, cada loja cria seus próprios produtos através da interface admin.

## 📊 Verificação Final

Após limpar, execute:

```sql
-- Deve retornar 0
SELECT COUNT(*) as produtos_sem_loja 
FROM products 
WHERE store_id IS NULL;

-- Ver produtos por loja
SELECT 
  s.name as loja,
  s.slug,
  COUNT(p.id) as total_produtos
FROM stores s
LEFT JOIN products p ON p.store_id = s.id
GROUP BY s.id, s.name, s.slug
ORDER BY s.name;
```

Resultado esperado:
```
produtos_sem_loja: 0

loja          | slug        | total_produtos
--------------|-------------|---------------
vefff         | vefff       | 0
brunonobru    | brunonobru  | 2
```

Agora cada loja tem apenas seus próprios produtos! 🎉
