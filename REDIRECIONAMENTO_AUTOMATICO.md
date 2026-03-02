# Sistema de Redirecionamento Automático por Loja

## Implementação Completa

O sistema agora detecta automaticamente a loja do proprietário e redireciona para o local correto.

## Fluxo de Redirecionamento

### 1. Proprietário faz login

```
Login → Verificação de lojas → Redirecionamento
```

**Cenários:**

#### A) Sem lojas
```
Login → /store-setup (criar primeira loja)
```

#### B) 1 loja
```
Login → Define loja como atual → /admin (ou mantém na rota atual)
```

#### C) Múltiplas lojas
```
Login → /stores (seleção de loja)
```

## Arquivos Criados

### 1. Página de Setup
**`src/pages/admin/StoreSetup.tsx`**
- Formulário completo de criação de loja
- Gera slug automaticamente
- Mostra URL da loja após criação
- Redireciona para `/admin` após sucesso

### 2. Página de Seleção
**`src/pages/admin/StoreSelector.tsx`**
- Lista todas as lojas do proprietário
- Cards com informações de cada loja
- Botão para criar nova loja
- Botão para abrir loja em nova aba
- Seleção define `currentStore`

### 3. Hook de Redirecionamento
**`src/hooks/useStoreRedirect.ts`**
- Detecta quantidade de lojas
- Redireciona automaticamente
- Evita loops de redirecionamento
- Retorna informações úteis

### 4. Layout Admin
**`src/components/admin/AdminLayout.tsx`**
- Protege rotas admin
- Garante autenticação
- Usa `useStoreRedirect`
- Mostra loading states

### 5. MercadoPagoContext Atualizado
**`src/contexts/MercadoPagoContext.tsx`**
- Agora usa `store_id` em vez de `user_id`
- Busca credenciais da loja ativa
- Valida existência de loja antes de salvar

## Como Usar

### Passo 1: Adicionar Rotas

```tsx
// Em App.tsx ou routes.tsx
import StoreSetup from '@/pages/admin/StoreSetup';
import StoreSelector from '@/pages/admin/StoreSelector';
import AdminLayout from '@/components/admin/AdminLayout';

// Rotas públicas
<Route path="/s/:slug" element={<StoreSlug />} />

// Rotas de setup (autenticadas mas sem loja)
<Route path="/store-setup" element={<StoreSetup />} />
<Route path="/stores" element={<StoreSelector />} />

// Rotas admin (protegidas)
<Route element={<AdminLayout />}>
  <Route path="/admin" element={<AdminDashboard />} />
  <Route path="/admin/products" element={<ProductsPage />} />
  <Route path="/admin/orders" element={<OrdersPage />} />
  <Route path="/admin/settings" element={<SettingsPage />} />
</Route>
```

### Passo 2: Usar o Hook (Opcional)

```tsx
import { useStoreRedirect } from '@/hooks/useStoreRedirect';

function MyComponent() {
  const { hasStores, hasMultipleStores, currentStore } = useStoreRedirect();
  
  if (!hasStores) {
    return <p>Crie sua primeira loja!</p>;
  }
  
  return (
    <div>
      <h1>Loja: {currentStore?.name}</h1>
      {hasMultipleStores && (
        <Button onClick={() => navigate('/stores')}>
          Trocar de loja
        </Button>
      )}
    </div>
  );
}
```

### Passo 3: Atualizar Providers

```tsx
// Em App.tsx
import { StoreProvider } from '@/contexts/StoreProvider';

<AuthProvider>
  <StoreProvider>
    <MercadoPagoProvider>
      <SubscriptionProvider>
        <CartProvider>
          {/* app */}
        </CartProvider>
      </SubscriptionProvider>
    </MercadoPagoProvider>
  </StoreProvider>
</AuthProvider>
```

## Exemplo Completo de Fluxo

### Novo Usuário

1. **Cadastro/Login**
   ```
   /login → Autenticação bem-sucedida
   ```

2. **Sem lojas detectadas**
   ```
   Redirecionamento automático → /store-setup
   ```

3. **Preenche formulário**
   ```
   Nome: "Hamburgueria do Zé"
   Endereço: "Rua ABC, 123"
   Telefone: "(11) 99999-9999"
   Taxa de entrega: R$ 5,00
   ```

4. **Loja criada**
   ```
   Slug gerado: "hamburgueria-do-ze"
   URL da loja: https://seusite.com/s/hamburgueria-do-ze
   Toast com URL para compartilhar
   ```

5. **Redirecionado para admin**
   ```
   /admin → Painel de controle
   currentStore definido automaticamente
   ```

### Usuário com 1 Loja

1. **Login**
   ```
   /login → Autenticação
   ```

2. **1 loja detectada**
   ```
   Define automaticamente como currentStore
   Mantém na rota atual (ou /admin se estava em /login)
   ```

3. **Acessa qualquer rota admin**
   ```
   /admin/products → Vê produtos da sua loja
   /admin/orders → Vê pedidos da sua loja
   /admin/settings → Configura sua loja
   ```

### Usuário com Múltiplas Lojas

1. **Login**
   ```
   /login → Autenticação
   ```

2. **Múltiplas lojas detectadas**
   ```
   Redirecionamento → /stores
   ```

3. **Seleção de loja**
   ```
   Vê lista de todas as lojas:
   - Hamburgueria do Zé
   - Pizzaria Bella
   - Churrascaria Gaúcha
   ```

4. **Clica em "Gerenciar"**
   ```
   Define loja selecionada como currentStore
   Redirecionamento → /admin
   ```

5. **Trabalha na loja selecionada**
   ```
   Todas as ações afetam apenas a loja atual
   Pode trocar de loja a qualquer momento em /stores
   ```

## Componentes Admin Atualizados

Para garantir isolamento, componentes admin devem usar `currentStore.id`:

```tsx
import { useStore } from '@/contexts/StoreContext';

function ProductsPage() {
  const { currentStore } = useStore();
  
  useEffect(() => {
    if (currentStore?.id) {
      loadProducts(currentStore.id);
    }
  }, [currentStore?.id]);
  
  const handleCreateProduct = async (productData) => {
    await productsService.create({
      ...productData,
      store_id: currentStore.id
    });
  };
}
```

## Segurança

✅ **RLS garante isolamento**: Mesmo que `store_id` seja manipulado, RLS bloqueia  
✅ **Validação server-side**: Edge Functions validam `store_id`  
✅ **Credenciais por loja**: Cada loja tem suas próprias credenciais MP  
✅ **Redirecionamento automático**: Impossível acessar admin sem loja  

## Melhorias Futuras

- [ ] Adicionar troca rápida de loja no header admin
- [ ] Dashboard com métricas de todas as lojas
- [ ] Permissões granulares (gerentes, funcionários)
- [ ] Histórico de atividades por loja
- [ ] Exportação de dados por loja

## Notas Importantes

- **Erros de TypeScript**: Normais até executar migration e regenerar tipos
- **`currentStore` pode ser null**: Sempre verificar antes de usar
- **Redirecionamento só ocorre após autenticação**: Não afeta rotas públicas
- **Rotas excluídas**: `/store-setup`, `/stores`, `/s/*` não redirecionam

## Troubleshooting

### Problema: Loop de redirecionamento
**Solução**: Verifique se as rotas estão nas `excludedPaths` do hook

### Problema: currentStore sempre null
**Solução**: Verifique se `StoreProvider` está envolvendo a aplicação

### Problema: Não redireciona após login
**Solução**: Verifique se `useStoreRedirect` está sendo chamado em componente protegido

### Problema: Vê dados de outra loja
**Solução**: Verifique se está usando `currentStore.id` nos filtros
