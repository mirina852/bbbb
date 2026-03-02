# 🔧 Solução: Filtro de Categorias Não Funciona

## Problema Identificado

Quando você seleciona uma categoria no dropdown (ex: "hambúrguerbebidas"), **nenhum produto aparece**.

### Imagem 1:
- Mostra produto "X-FRANGO" com badge "Outros"
- Categoria selecionada não está filtrando

### Imagem 2:
- Dropdown mostra "hambúrguerbebidas" (com acento)
- Slug não está normalizado corretamente

## Causa do Problema

O código gera slugs **normalizados** (sem acentos):
```typescript
// StoreSlug.tsx linha 176-180
categorySlug = category.slug || category.name.toLowerCase()
  .normalize('NFD')
  .replace(/[\u0300-\u036f]/g, '') // Remove acentos
  .replace(/[^a-z0-9]+/g, '-')
  .replace(/^-+|-+$/g, '');
```

**Exemplo:**
- Nome da categoria: `"Hambúrguer"`
- Slug gerado: `"hamburguer"` (sem acento)

Mas se a categoria no banco tem `slug = "hambúrguerbebidas"` (com acento), há **incompatibilidade**!

## Solução

### Opção 1: Normalizar Slugs no Banco (Recomendado)

Execute este SQL:

```sql
-- Normalizar todos os slugs das categorias
UPDATE categories
SET slug = LOWER(
  REGEXP_REPLACE(
    TRANSLATE(
      name,
      'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ',
      'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'
    ),
    '[^a-z0-9]+', '-', 'g'
  )
);

-- Remover hífens do início e fim
UPDATE categories
SET slug = TRIM(BOTH '-' FROM slug);

-- Verificar resultado
SELECT name, slug FROM categories ORDER BY display_order;
```

**Resultado esperado:**
```
name                | slug
--------------------|-------------------
Hambúrguer          | hamburguer
Bebidas             | bebidas
Hambúrguer & Bebidas| hamburguer-bebidas
Açaí                | acai
```

### Opção 2: Usar `category.slug` Sempre

Se o banco já tem slugs corretos, garantir que sempre use `category.slug`:

```typescript
// StoreSlug.tsx linha 174-181
let categorySlug = 'sem-categoria';
if (category) {
  // ✅ Sempre usar category.slug se existir
  categorySlug = category.slug || category.name.toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}
```

## Como Funciona o Agrupamento

### 1. Produtos são agrupados por slug:
```typescript
// Para cada produto
const category = categories.find(cat => cat.id === product.category_id);
const categorySlug = category.slug || normalizar(category.name);
categorizedProducts[categorySlug].push(product);
```

**Exemplo:**
```javascript
categorizedProducts = {
  "hamburguer": [produto1, produto2],
  "bebidas": [produto3],
  "sem-categoria": []
}
```

### 2. Tabs usam o mesmo slug:
```typescript
<TabsTrigger value={slug}>
  {category.name}
  <Badge>{categorizedProducts[slug]?.length || 0}</Badge>
</TabsTrigger>
```

### 3. Conteúdo da tab:
```typescript
<TabsContent value={slug}>
  <ProductList products={categorizedProducts[slug] || []} />
</TabsContent>
```

## Verificar Problema

Execute este SQL:

```sql
-- Ver categorias e seus slugs
SELECT 
  c.name as categoria,
  c.slug,
  COUNT(p.id) as total_produtos,
  STRING_AGG(p.name, ', ') as produtos
FROM categories c
LEFT JOIN products p ON p.category_id = c.id
GROUP BY c.id, c.name, c.slug
ORDER BY c.display_order;
```

**Se o slug tiver acentos:**
```
categoria   | slug              | total_produtos | produtos
------------|-------------------|----------------|----------
Hambúrguer  | hambúrguerbebidas | 4              | X-file, cola, vvvv
```

**Problema:** Slug `"hambúrguerbebidas"` (com acento) ≠ Slug gerado `"hamburguerbebidas"` (sem acento)

## Teste no Console

Abra o Console (F12) na página pública e veja:

```javascript
📦 Produto: X-file | categoria_id: 484e0f43... | categoria encontrada: Hambúrguer | slug gerado: hamburguer
📊 Produtos agrupados: {hamburguer: Array(4)}
👁️ Categorias visíveis: 1 [Hambúrguer]
```

**Se o slug gerado for diferente do `category.slug`:**
- Produtos vão para um slug
- Tabs usam outro slug
- **Resultado:** Nenhum produto aparece!

## Solução Rápida

Execute este SQL agora:

```sql
-- 1. Ver problema
SELECT name, slug FROM categories;

-- 2. Corrigir slugs
UPDATE categories
SET slug = LOWER(REGEXP_REPLACE(
  TRANSLATE(name, 'áéíóúàèìòùâêîôûãõçÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇ', 
                  'aeiouaeiouaeiouaocAEIOUAEIOUAEIOUAOC'),
  '[^a-z0-9]+', '-', 'g'
));

-- 3. Limpar hífens extras
UPDATE categories
SET slug = REGEXP_REPLACE(slug, '^-+|-+$', '', 'g');

-- 4. Verificar
SELECT name, slug FROM categories;
```

## Resultado Esperado

Após corrigir os slugs:

### Banco de Dados:
```
name                | slug
--------------------|-------------------
Hambúrguer          | hamburguer
Bebidas             | bebidas
```

### Console:
```
📦 Produto: X-file | slug gerado: hamburguer
📊 Produtos agrupados: {hamburguer: Array(4)}
👁️ Categorias visíveis: 1
```

### Página:
```
┌─────────────────────────────────┐
│  Hambúrguer (4)  │  Bebidas (0) │
├─────────────────────────────────┤
│  ✅ X-file                       │
│  ✅ cola                         │
│  ✅ vvvv                         │
│  ✅ X-file                       │
└─────────────────────────────────┘
```

## Checklist

- [ ] Executar SQL para normalizar slugs
- [ ] Verificar que slugs não têm acentos
- [ ] Recarregar página pública
- [ ] Selecionar categoria
- [ ] Produtos devem aparecer

Execute o SQL agora! 🚀
