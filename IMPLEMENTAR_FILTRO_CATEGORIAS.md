# 🎯 Implementar Filtro de Categorias

## Objetivo

Ao selecionar uma categoria (ex: "Hambúrguer"), mostrar **apenas** os produtos dessa categoria.

## Como Funciona Atualmente

O código já tem um sistema de **Tabs** (abas) que filtra por categoria:

```typescript
<Tabs defaultValue={primeiraCategoria}>
  <TabsList>
    <TabsTrigger value="hamburguer">Hambúrguer (4)</TabsTrigger>
    <TabsTrigger value="bebidas">Bebidas (2)</TabsTrigger>
  </TabsList>
  
  <TabsContent value="hamburguer">
    <ProductList products={produtosDaCategoria} />
  </TabsContent>
  
  <TabsContent value="bebidas">
    <ProductList products={produtosDaCategoria} />
  </TabsContent>
</Tabs>
```

## Problema Atual

Os produtos **não aparecem** porque os **slugs não estão normalizados**:

### Exemplo do Problema:

**Categoria no banco:**
```sql
name: "Hambúrguer"
slug: "hambúrguerbebidas"  -- ❌ Com acento!
```

**Slug gerado pelo código:**
```typescript
categorySlug = "hamburguerbebidas"  // ✅ Sem acento
```

**Resultado:**
- Produtos são agrupados em `categorizedProducts["hamburguerbebidas"]`
- Tabs procuram por `categorizedProducts["hambúrguerbebidas"]`
- **Não encontra nada!** ❌

## Solução em 2 Passos

### Passo 1: Normalizar Slugs no Banco

Execute este SQL:

```sql
-- 1. Ver slugs atuais (com problema)
SELECT 
  id,
  name,
  slug,
  LOWER(REGEXP_REPLACE(
    TRANSLATE(
      name, 
      'áéíóúàèìòùâêîôûãõçÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇ', 
      'aeiouaeiouaeiouaocAEIOUAEIOUAEIOUAOC'
    ),
    '[^a-z0-9]+', '-', 'g'
  )) as slug_correto
FROM categories
ORDER BY display_order;

-- 2. Atualizar slugs (remover acentos)
UPDATE categories
SET slug = LOWER(REGEXP_REPLACE(
  TRANSLATE(
    name, 
    'áéíóúàèìòùâêîôûãõçÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇ', 
    'aeiouaeiouaeiouaocAEIOUAEIOUAEIOUAOC'
  ),
  '[^a-z0-9]+', '-', 'g'
));

-- 3. Remover hífens extras
UPDATE categories
SET slug = TRIM(BOTH '-' FROM slug);

-- 4. Verificar resultado
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

### Passo 2: Verificar Agrupamento de Produtos

Após normalizar os slugs, verifique no Console (F12):

```javascript
📦 Produto: X-file | categoria_id: 484e0f43... | categoria encontrada: Hambúrguer | slug gerado: hamburguer
📦 Produto: cola | categoria_id: 484e0f43... | categoria encontrada: Hambúrguer | slug gerado: hamburguer
📊 Produtos agrupados: {
  hamburguer: [X-file, cola, vvvv, X-file],
  bebidas: [Coca-Cola, Suco]
}
👁️ Categorias visíveis: 2 [Hambúrguer, Bebidas]
```

## Como Funciona o Filtro

### 1. Produtos são Agrupados por Categoria

```typescript
// StoreSlug.tsx linha 165-187
const categorizedProducts: Record<string, Product[]> = {};
products.forEach(product => {
  const categoriaId = product.category_id;
  const category = categories.find(cat => cat.id === categoriaId);
  
  // Gera slug normalizado
  const categorySlug = category.slug || normalizar(category.name);
  
  // Agrupa produtos por slug
  if (!categorizedProducts[categorySlug]) {
    categorizedProducts[categorySlug] = [];
  }
  categorizedProducts[categorySlug].push(product);
});
```

**Resultado:**
```javascript
categorizedProducts = {
  "hamburguer": [produto1, produto2, produto3, produto4],
  "bebidas": [produto5, produto6]
}
```

### 2. Tabs Filtram por Slug

```typescript
// StoreSlug.tsx linha 289-295
<TabsTrigger value="hamburguer">
  <Icon />
  Hambúrguer
  <Badge>4</Badge>  {/* categorizedProducts["hamburguer"].length */}
</TabsTrigger>
```

### 3. Conteúdo Mostra Produtos da Categoria

```typescript
// StoreSlug.tsx linha 326-330
<TabsContent value="hamburguer">
  <ProductList products={categorizedProducts["hamburguer"]} />
  {/* Mostra apenas os 4 produtos de hambúrguer */}
</TabsContent>
```

## Teste Passo a Passo

### 1. Executar SQL
```sql
UPDATE categories
SET slug = LOWER(REGEXP_REPLACE(
  TRANSLATE(name, 'áéíóúàèìòùâêîôûãõçÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇ', 
                  'aeiouaeiouaeiouaocAEIOUAEIOUAEIOUAOC'),
  '[^a-z0-9]+', '-', 'g'
));

SELECT name, slug FROM categories;
```

### 2. Verificar no Banco
```
name        | slug
------------|------------
Hambúrguer  | hamburguer  ✅
Bebidas     | bebidas     ✅
```

### 3. Recarregar Página
```
1. Abra /s/mercadinhowp
2. Pressione Ctrl+R
3. Abra Console (F12)
```

### 4. Ver Logs
```javascript
📊 Produtos agrupados: {hamburguer: Array(4), bebidas: Array(2)}
👁️ Categorias visíveis: 2
```

### 5. Clicar nas Abas
```
┌─────────────────────────────────────┐
│ [Hambúrguer (4)] [Bebidas (2)]      │
├─────────────────────────────────────┤
│ ✅ X-file - R$ 25,00                │
│ ✅ cola - R$ 7,00                   │
│ ✅ vvvv - R$ 10,00                  │
│ ✅ X-file - R$ 15,00                │
└─────────────────────────────────────┘
```

Ao clicar em "Bebidas", deve mostrar apenas bebidas!

## Verificar Problema Específico

Se ainda não funcionar, execute:

```sql
-- Ver produtos e suas categorias
SELECT 
  p.name as produto,
  c.name as categoria,
  c.slug as categoria_slug,
  p.category_id
FROM products p
LEFT JOIN categories c ON c.id = p.category_id
WHERE p.store_id = (SELECT id FROM stores WHERE slug = 'mercadinhowp')
ORDER BY c.slug, p.name;
```

**Deve retornar:**
```
produto | categoria   | categoria_slug | category_id
--------|-------------|----------------|-------------
cola    | Hambúrguer  | hamburguer     | 484e0f43... ✅
vvvv    | Hambúrguer  | hamburguer     | 484e0f43... ✅
x-file  | Hambúrguer  | hamburguer     | 484e0f43... ✅
```

**Se `category_id` for NULL:**
```sql
-- Atribuir produtos à primeira categoria
UPDATE products
SET category_id = (
  SELECT id FROM categories 
  WHERE store_id = products.store_id 
  ORDER BY display_order 
  LIMIT 1
)
WHERE category_id IS NULL;
```

## Resultado Final

### Antes (❌):
```
- Slugs com acentos: "hambúrguerbebidas"
- Código gera sem acentos: "hamburguerbebidas"
- Incompatibilidade = produtos não aparecem
- Todas as categorias vazias
```

### Depois (✅):
```
- Slugs normalizados: "hamburguer", "bebidas"
- Código gera igual: "hamburguer", "bebidas"
- Compatibilidade = produtos aparecem
- Cada categoria mostra seus produtos
```

### Comportamento Esperado:

1. **Ao carregar a página:**
   - Primeira categoria selecionada automaticamente
   - Mostra produtos dessa categoria

2. **Ao clicar em "Hambúrguer":**
   - Mostra apenas produtos de hambúrguer
   - Badge mostra quantidade: (4)

3. **Ao clicar em "Bebidas":**
   - Mostra apenas produtos de bebidas
   - Badge mostra quantidade: (2)

4. **Ao clicar em "Outros":**
   - Mostra produtos sem categoria específica
   - Badge mostra quantidade: (0)

## Checklist

- [ ] Executar SQL para normalizar slugs
- [ ] Verificar que slugs não têm acentos
- [ ] Verificar que produtos têm `category_id`
- [ ] Recarregar página pública
- [ ] Abrir Console (F12)
- [ ] Ver logs de agrupamento
- [ ] Clicar em cada categoria
- [ ] Verificar que produtos mudam

Execute o SQL agora! 🚀
