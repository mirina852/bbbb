# ✅ Correção: Badge Mostrando "Outros" em Vez da Categoria Correta

## Problema

Produtos apareciam com badge "Outros" mesmo tendo `category_id` correto no banco.

### Exemplo:
```
Produto: X-FRANGO
Badge mostrava: "Outros" ❌
Deveria mostrar: "Hambúrguer" ✅
```

## Causa

O componente `ProductCard` estava mostrando `product.category` (campo de texto) em vez de buscar o nome da categoria pelo `product.category_id`.

### Código Antigo (❌):
```typescript
// ProductCard.tsx linha 34
<Badge>
  {product.category}  // ❌ Mostra "hambur" ou "outros"
</Badge>
```

### Dados no Banco:
```sql
-- Produto
name: "X-FRANGO"
category: "hambur"        -- ❌ Texto genérico
category_id: "ff2d8098..."  -- ✅ ID correto da categoria

-- Categoria
id: "ff2d8098..."
name: "Hambúrguer"        -- ✅ Nome correto
slug: "hambur"
```

## Solução Aplicada

### 1. Modificado `ProductCard.tsx`

**Adicionado:**
- Import de `Category`
- Prop `categories?: Category[]`
- Lógica para buscar nome da categoria

```typescript
// ProductCard.tsx
import { Category } from '@/services/supabaseService';

interface ProductCardProps {
  product: Product;
  categories?: Category[];  // ✅ Novo
  onEdit: (product: Product) => void;
  onDelete: (id: string) => void;
}

const ProductCard = ({ product, categories, onEdit, onDelete }) => {
  // ✅ Buscar nome da categoria pelo category_id
  const category = categories?.find(cat => cat.id === product.category_id);
  const categoryName = category?.name || product.category || 'Outros';
  
  return (
    <Badge>
      {categoryName}  // ✅ Mostra "Hambúrguer"
    </Badge>
  );
};
```

### 2. Modificado `Products.tsx`

**Adicionado:**
- Passar `categories` como prop para `ProductCard`

```typescript
// Products.tsx linha 240
<ProductCard
  product={product}
  categories={categories}  // ✅ Novo
  onEdit={handleEditProduct}
  onDelete={handleDeleteProduct}
/>
```

## Como Funciona Agora

### Fluxo:

1. **Produto tem `category_id`:**
   ```javascript
   product = {
     id: "...",
     name: "X-FRANGO",
     category: "hambur",           // Texto antigo
     category_id: "ff2d8098..."    // ✅ ID da categoria
   }
   ```

2. **Busca categoria pelo ID:**
   ```javascript
   const category = categories.find(cat => cat.id === product.category_id);
   // Retorna: { id: "ff2d8098...", name: "Hambúrguer", slug: "hambur" }
   ```

3. **Mostra nome da categoria:**
   ```javascript
   const categoryName = category?.name || product.category || 'Outros';
   // Resultado: "Hambúrguer" ✅
   ```

4. **Badge exibe:**
   ```html
   <Badge>Hambúrguer</Badge>
   ```

## Resultado

### Antes (❌):
```
┌─────────────────┐
│ [Outros]        │  ← Badge errada
│                 │
│   X-FRANGO      │
│   R$ 25,00      │
└─────────────────┘
```

### Depois (✅):
```
┌─────────────────┐
│ [Hambúrguer]    │  ← Badge correta
│                 │
│   X-FRANGO      │
│   R$ 25,00      │
└─────────────────┘
```

## Fallbacks

O código tem 3 níveis de fallback:

```typescript
const categoryName = 
  category?.name ||        // 1. Nome da categoria (✅ ideal)
  product.category ||      // 2. Campo texto (fallback)
  'Outros';                // 3. Padrão se nada existir
```

### Exemplos:

| Situação | category_id | category | Resultado |
|----------|-------------|----------|-----------|
| ✅ Normal | ff2d8098... | hambur | "Hambúrguer" |
| ⚠️ Sem ID | null | hambur | "hambur" |
| ⚠️ Sem nada | null | null | "Outros" |

## Teste

### 1. Recarregar Página Admin
```
1. Abra /admin/products
2. Pressione Ctrl+R
3. Badge deve mostrar nome correto da categoria
```

### 2. Verificar Console (F12)
Não deve ter erros relacionados a `categories`.

### 3. Verificar Produtos
```
✅ X-FRANGO → Badge "Hambúrguer"
✅ coca → Badge "Hambúrguer"
✅ X-file → Badge "Hambúrguer"
```

## Arquivos Modificados

1. **`src/components/products/ProductCard.tsx`**
   - Linha 8: Import `Category`
   - Linha 12: Prop `categories?: Category[]`
   - Linhas 18-20: Lógica de busca
   - Linha 40: Usar `categoryName`

2. **`src/pages/admin/Products.tsx`**
   - Linha 240: Passar `categories={categories}`

## Checklist

- [x] `ProductCard` recebe `categories`
- [x] Busca categoria pelo `category_id`
- [x] Mostra nome da categoria
- [x] Fallback para `product.category`
- [x] Fallback para "Outros"
- [ ] **Recarregar página admin** ← FAÇA AGORA!
- [ ] **Verificar badges** ← VERIFICAR!

## Próximos Passos

Se quiser aplicar a mesma correção na **página pública** (customer), verificar se `ProductList` ou componente similar também precisa das categorias.

---

**Recarregue a página `/admin/products` agora e as badges vão mostrar os nomes corretos!** 🎉
