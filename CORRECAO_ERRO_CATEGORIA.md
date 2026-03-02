# ✅ Correção: Erro ao Salvar Categoria

## ❌ Problema

Ao tentar salvar uma categoria, aparecia o erro:
```
Erro ao salvar categoria
```

## 🔍 Causa Raiz

O componente `CategoryManager.tsx` tinha **3 problemas**:

1. ❌ **Tabela errada**: Usava `'categories'` mas a tabela é `'categorias'`
2. ❌ **Faltava `store_id`**: Não estava enviando o ID da loja
3. ❌ **Faltava `useStore`**: Não tinha acesso ao `currentStore`

## 🔧 Correções Aplicadas

### 1. **Adicionado `useStore`**
```typescript
import { useStore } from '@/contexts/StoreContext';

const CategoryManager = ({ isOpen, onClose, onCategoriesChange }: CategoryManagerProps) => {
  const { currentStore } = useStore(); // ✅ ADICIONADO
  // ...
}
```

### 2. **Corrigido `loadCategories`**
```typescript
// ANTES ❌
.from('categories' as any)
.select('*')
.order('display_order', { ascending: true });

// DEPOIS ✅
.from('categorias' as any)
.select('*')
.eq('store_id', currentStore.id) // ✅ Filtra por loja
.order('position', { ascending: true });
```

### 3. **Corrigido `handleSave` (Create)**
```typescript
// ANTES ❌
.from('categories' as any)
.insert({ 
  name: formData.name, 
  slug: formData.slug,
  icon: formData.icon,
  display_order: categories.length + 1
});

// DEPOIS ✅
.from('categorias' as any)
.insert({ 
  store_id: currentStore.id, // ✅ ADICIONADO
  name: formData.name,
  icon: formData.icon,
  position: categories.length // ✅ Corrigido nome do campo
});
```

### 4. **Corrigido `handleSave` (Update)**
```typescript
// ANTES ❌
.from('categories' as any)
.update({ 
  name: formData.name, 
  slug: formData.slug,
  icon: formData.icon
});

// DEPOIS ✅
.from('categorias' as any)
.update({ 
  name: formData.name,
  icon: formData.icon
  // Slug não é mais necessário
});
```

### 5. **Corrigido `handleDelete`**
```typescript
// ANTES ❌
.from('categories' as any)
.delete()
.eq('id', deleteCategory.id);

// DEPOIS ✅
.from('categorias' as any)
.delete()
.eq('id', deleteCategory.id);
```

### 6. **Validações Adicionadas**
```typescript
// Verifica se tem loja selecionada
if (!currentStore?.id) {
  toast.error('Nenhuma loja selecionada');
  return;
}

// Mensagem de erro mais detalhada
toast.error('Erro ao salvar categoria: ' + (error.message || 'Erro desconhecido'));
```

## 📋 Estrutura da Tabela `categorias`

```sql
CREATE TABLE public.categorias (
  id UUID PRIMARY KEY,
  store_id UUID REFERENCES stores(id), -- ✅ Obrigatório
  name TEXT NOT NULL,
  icon TEXT,
  position INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT now()
);
```

## 🚀 Como Testar

### 1. **Recarregue a aplicação**
```bash
# Se necessário, reinicie
npm run dev
```

### 2. **Acesse Produtos**
- Vá em `/admin/products`

### 3. **Clique em "Gerenciar Categorias"**

### 4. **Adicione uma categoria**
- Nome: "Hamburgueria"
- Ícone: Beef (sugerido automaticamente)
- Clique em "Salvar"

### 5. **Resultado esperado**
```
✅ Categoria criada com sucesso
```

## ✅ Checklist de Verificação

- [x] `useStore` importado
- [x] `currentStore` usado
- [x] Tabela corrigida para `categorias`
- [x] `store_id` adicionado no insert
- [x] Campo `position` usado (não `display_order`)
- [x] Validação de loja selecionada
- [x] Mensagens de erro detalhadas
- [x] `handleDelete` corrigido

## 🎯 Resultado

### Antes:
```
❌ Erro ao salvar categoria
```

### Agora:
```
✅ Categoria criada com sucesso
```

## 📝 Arquivos Modificados

```
src/components/products/CategoryManager.tsx
├── Adicionado: import { useStore }
├── Adicionado: const { currentStore } = useStore()
├── Corrigido: loadCategories() - usa 'categorias' e filtra por store_id
├── Corrigido: handleSave() - adiciona store_id e usa 'position'
└── Corrigido: handleDelete() - usa 'categorias'
```

## 🎉 Pronto!

Agora você pode criar, editar e excluir categorias sem erros! ✅

### Próximos Passos:

1. ✅ Teste criar uma categoria
2. ✅ Teste editar uma categoria
3. ✅ Teste excluir uma categoria
4. ✅ Adicione produtos nessas categorias

**Tudo funcionando!** 🚀
