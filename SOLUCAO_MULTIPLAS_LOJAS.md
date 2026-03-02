# ✅ Solução: Login Redirecionando para Loja Errada

## Problema Identificado

Quando você tem **múltiplas lojas** (2 ou mais), o sistema não selecionava automaticamente nenhuma loja após o login, causando confusão sobre qual loja estava sendo gerenciada.

## Como Funcionava Antes (❌)

1. Login bem-sucedido
2. Redirecionado para `/admin`
3. Sistema tentava carregar lojas
4. **Se tivesse apenas 1 loja**: selecionava automaticamente
5. **Se tivesse 2+ lojas**: nenhuma era selecionada
6. Usuário ficava sem saber qual loja estava gerenciando

## Como Funciona Agora (✅)

1. Login bem-sucedido
2. Sistema verifica quantas lojas você tem:
   - **0 lojas**: Redireciona para `/store-setup` (criar loja)
   - **1 loja**: Seleciona automaticamente e vai para `/admin`
   - **2+ lojas**: Redireciona para `/store-selector` (escolher loja)
3. Você escolhe qual loja quer gerenciar
4. Redirecionado para `/admin` com a loja selecionada

## Correções Implementadas

### 1. `AdminLayout.tsx` (linhas 41-53)

**Adicionado**: Lógica de redirecionamento inteligente

```typescript
// Se tem múltiplas lojas e nenhuma selecionada, redirecionar para seletor
const isStoreSelectorPage = location.pathname === '/store-selector';
const isStoreSetupPage = location.pathname === '/store-setup';

if (!currentStore && userStores.length > 1 && !isStoreSelectorPage && !isStoreSetupPage) {
  return <Navigate to="/store-selector" replace />;
}

// Se não tem nenhuma loja, redirecionar para criação
if (userStores.length === 0 && !isStoreSetupPage) {
  return <Navigate to="/store-setup" replace />;
}
```

### 2. `App.tsx` (linha 66-70)

**Adicionado**: Rota para seleção de lojas

```typescript
<Route path="/store-selector" element={
  <ProtectedRoute requireAdmin>
    <StoreSelector />
  </ProtectedRoute>
} />
```

### 3. Página `StoreSelector.tsx`

Já existia! Uma página bonita que mostra:
- ✅ Cards com todas as suas lojas
- ✅ Informações de cada loja (nome, slug, endereço, telefone)
- ✅ Status (aberta/fechada)
- ✅ Botão para gerenciar cada loja
- ✅ Botão para abrir a loja em nova aba
- ✅ Card para criar nova loja

## 🧪 Como Testar

### Cenário 1: Você tem 2+ lojas

1. **Faça logout** (se estiver logado)
2. **Faça login** novamente
3. **Você será redirecionado** para `/store-selector`
4. **Escolha a loja** que quer gerenciar
5. **Clique em "Gerenciar"**
6. **Será redirecionado** para `/admin` com a loja selecionada

### Cenário 2: Você tem apenas 1 loja

1. **Faça login**
2. **Será redirecionado** diretamente para `/admin`
3. **A loja é selecionada** automaticamente

### Cenário 3: Você não tem lojas

1. **Faça login**
2. **Será redirecionado** para `/store-setup`
3. **Crie sua primeira loja**

## 🎯 Trocar de Loja Depois

Se você quiser trocar de loja depois de já estar logado:

1. **Acesse manualmente**: `/store-selector`
2. **Ou adicione um botão** no menu/sidebar para trocar de loja
3. **Escolha outra loja**

## 📋 Estrutura do Seletor de Lojas

A página `/store-selector` mostra:

```
┌─────────────────────────────────────────┐
│         Minhas Lojas                    │
│  Selecione uma loja para gerenciar      │
└─────────────────────────────────────────┘

┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ 🏪 Loja 1    │  │ 🏪 Loja 2    │  │ ➕ Criar     │
│ /s/loja-1    │  │ /s/loja-2    │  │   Nova Loja  │
│ Aberta       │  │ Fechada      │  │              │
│              │  │              │  │              │
│ [Gerenciar]  │  │ [Gerenciar]  │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
```

## 🔧 Melhorias Futuras (Opcional)

### 1. Adicionar botão no Sidebar para trocar de loja

```typescript
// No Sidebar.tsx
<Button onClick={() => navigate('/store-selector')}>
  Trocar de Loja
</Button>
```

### 2. Salvar última loja selecionada no localStorage

```typescript
// Ao selecionar loja
localStorage.setItem('lastSelectedStore', store.id);

// Ao carregar
const lastStoreId = localStorage.getItem('lastSelectedStore');
if (lastStoreId) {
  const lastStore = userStores.find(s => s.id === lastStoreId);
  if (lastStore) setCurrentStore(lastStore);
}
```

### 3. Mostrar nome da loja atual no header

```typescript
// No header do AdminLayout
<div className="flex items-center gap-2">
  <Store className="h-4 w-4" />
  <span>{currentStore?.name}</span>
</div>
```

## ✅ Resultado Final

Agora quando você faz login:

1. ✅ **Sistema detecta** quantas lojas você tem
2. ✅ **Redireciona automaticamente** para a página correta
3. ✅ **Você escolhe** qual loja quer gerenciar (se tiver múltiplas)
4. ✅ **Sempre sabe** qual loja está gerenciando
5. ✅ **Pode trocar** de loja facilmente acessando `/store-selector`

Não há mais confusão sobre qual loja você está gerenciando! 🎉
