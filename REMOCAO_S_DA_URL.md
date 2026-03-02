# Remoção do /s/ da URL

## ✅ Alterações Implementadas

A estrutura de URL foi modificada para remover o prefixo `/s/` das URLs das lojas:

**Antes:** `https://cardapiolojista.vercel.app/s/mercadinhomvp`  
**Depois:** `https://cardapiolojista.vercel.app/mercadinhomvp`

---

## 📝 Arquivos Modificados

### 1. **src/App.tsx**
- ✅ Rota principal alterada de `/s/:slug` para `/:slug`
- ✅ Adicionada rota de redirecionamento `/s/:slug` → `/:slug` para compatibilidade com URLs antigas
- ✅ Rota `/:slug` movida para o final das rotas de cliente para evitar conflitos

### 2. **src/components/RedirectOldStoreUrl.tsx** (NOVO)
- ✅ Componente criado para redirecionar URLs antigas `/s/:slug` para o novo formato `/:slug`
- ✅ Usa `replace` para não adicionar entrada no histórico do navegador

### 3. **src/lib/utils/storeUrl.ts**
- ✅ Função `getStoreUrl()` atualizada para retornar `${baseUrl}/${slug}` ao invés de `${baseUrl}/s/${slug}`

### 4. **src/pages/customer/StoreSlug.tsx**
- ✅ localStorage agora salva `/${slug}` ao invés de `/s/${slug}` para o botão "Início"

### 5. **src/pages/admin/StoreSelector.tsx**
- ✅ Display da URL da loja alterado de `/s/{store.slug}` para `/{store.slug}`
- ✅ Link de visualização atualizado de `/s/${store.slug}` para `/${store.slug}`

### 6. **src/components/customer/BottomNavigation.tsx**
- ✅ Lógica de detecção de página de loja atualizada
- ✅ Agora verifica se NÃO é uma rota especial (admin, auth, store, product, etc.) ao invés de verificar se começa com `/s/`

### 7. **src/hooks/useStoreRedirect.ts**
- ✅ Lista de rotas excluídas atualizada para incluir mais rotas especiais
- ✅ Removida referência a `/s/` da lista de exclusões
- ✅ Corrigido `loading` para `isLoading` no AuthContext

---

## 🔄 Compatibilidade com URLs Antigas

Para garantir que links antigos continuem funcionando:

- URLs no formato `/s/mercadinhomvp` são automaticamente redirecionadas para `/mercadinhomvp`
- O redirecionamento usa `replace` para não poluir o histórico do navegador
- A rota de redirecionamento está posicionada ANTES da rota `/:slug` para ter prioridade

---

## 🚀 Como Testar

1. **Nova URL:**
   - Acesse: `https://cardapiolojista.vercel.app/mercadinhomvp`
   - Deve carregar a loja normalmente

2. **URL Antiga (redirecionamento):**
   - Acesse: `https://cardapiolojista.vercel.app/s/mercadinhomvp`
   - Deve redirecionar automaticamente para `/mercadinhomvp`

3. **Botão "Início":**
   - Na página da loja, clique no botão "Início" na navegação inferior
   - Deve rolar para o topo da página

4. **Seletor de Lojas (Admin):**
   - Acesse `/store-selector`
   - Verifique que as URLs exibidas não têm mais o `/s/`
   - Clique no botão de visualização externa - deve abrir a loja sem `/s/`

---

## ⚠️ Importante

- A rota `/:slug` agora captura QUALQUER URL que não seja uma rota especial
- Certifique-se de que todas as rotas especiais estejam definidas ANTES da rota `/:slug`
- O sistema de redirecionamento em `useStoreRedirect.ts` foi atualizado para excluir mais rotas

---

## 📋 Checklist de Verificação

- [x] Rota principal atualizada
- [x] Redirecionamento de URLs antigas implementado
- [x] Utilitário de URL atualizado
- [x] localStorage atualizado
- [x] Admin store selector atualizado
- [x] Navegação inferior atualizada
- [x] Hook de redirecionamento atualizado
- [x] Compatibilidade com URLs antigas garantida

---

## 🎯 Resultado Final

Agora todas as lojas são acessadas diretamente pelo slug, sem o prefixo `/s/`, tornando as URLs mais limpas e profissionais:

✅ `cardapiolojista.vercel.app/mercadinhomvp`  
✅ `cardapiolojista.vercel.app/minhaloja`  
✅ `cardapiolojista.vercel.app/restaurante123`
