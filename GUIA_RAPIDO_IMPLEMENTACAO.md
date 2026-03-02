# Guia Rápido: Implementação Multi-Tenant

## ✅ O que foi implementado

Sistema completo de **múltiplas lojas independentes** com redirecionamento automático.

## 🚀 Checklist de Implementação

### 1️⃣ Executar Migration no Supabase

```sql
-- Copie e execute no Supabase SQL Editor:
-- Arquivo: supabase/migrations/20251011200000_create_stores_multi_tenant.sql
```

**O que faz:**
- ✅ Cria tabela `stores`
- ✅ Adiciona `store_id` em todas as tabelas
- ✅ Atualiza políticas RLS
- ✅ Cria funções auxiliares

### 2️⃣ Regenerar Tipos TypeScript

```bash
npx supabase gen types typescript --project-id SEU_PROJECT_ID > src/integrations/supabase/types.ts
```

**Importante:** Isso resolve todos os erros de TypeScript.

### 3️⃣ Adicionar Rotas

Adicione no seu arquivo de rotas (ex: `App.tsx`):

```tsx
import StoreSlug from '@/pages/customer/StoreSlug';
import StoreSetup from '@/pages/admin/StoreSetup';
import StoreSelector from '@/pages/admin/StoreSelector';
import AdminLayout from '@/components/admin/AdminLayout';

// Rotas públicas
<Route path="/s/:slug" element={<StoreSlug />} />

// Setup de loja
<Route path="/store-setup" element={<StoreSetup />} />
<Route path="/stores" element={<StoreSelector />} />

// Rotas admin protegidas
<Route element={<AdminLayout />}>
  <Route path="/admin" element={<AdminDashboard />} />
  <Route path="/admin/*" element={<AdminPages />} />
</Route>
```

### 4️⃣ Adicionar Providers

Envolva a aplicação com `StoreProvider`:

```tsx
import { StoreProvider } from '@/contexts/StoreContext';

<AuthProvider>
  <StoreProvider>
    <MercadoPagoProvider>
      {/* resto da aplicação */}
    </MercadoPagoProvider>
  </StoreProvider>
</AuthProvider>
```

### 5️⃣ (Opcional) Migrar Dados Existentes

Se já tem dados, execute no Supabase:

```sql
-- Criar loja padrão
INSERT INTO public.stores (owner_id, name, slug, delivery_fee, is_active, is_open)
SELECT id, 'Minha Loja', 'minha-loja', 5.00, true, true
FROM auth.users LIMIT 1;

-- Associar dados à loja
UPDATE public.products SET store_id = (SELECT id FROM stores LIMIT 1) WHERE store_id IS NULL;
UPDATE public.orders SET store_id = (SELECT id FROM stores LIMIT 1) WHERE store_id IS NULL;
UPDATE public.categories SET store_id = (SELECT id FROM stores LIMIT 1) WHERE store_id IS NULL;
UPDATE public.merchant_payment_credentials SET store_id = (SELECT id FROM stores LIMIT 1) WHERE store_id IS NULL;
```

## 📋 Arquivos Criados

```
src/
├── contexts/
│   └── StoreContext.tsx              ✅ Gerenciamento de lojas
├── pages/
│   ├── admin/
│   │   ├── StoreSetup.tsx            ✅ Setup inicial
│   │   └── StoreSelector.tsx         ✅ Seleção de lojas
│   └── customer/
│       └── StoreSlug.tsx             ✅ Loja pública dinâmica
├── components/
│   └── admin/
│       └── AdminLayout.tsx           ✅ Proteção de rotas
├── hooks/
│   └── useStoreRedirect.ts           ✅ Redirecionamento automático
└── types/
    └── index.ts                      ✅ Tipos atualizados

supabase/migrations/
└── 20251011200000_create_stores_multi_tenant.sql  ✅ Migration

Documentação/
├── MULTI_TENANT_SETUP.md             ✅ Setup completo
├── RESUMO_MULTI_TENANT.md            ✅ Visão geral
├── REDIRECIONAMENTO_AUTOMATICO.md    ✅ Sistema de redirecionamento
└── GUIA_RAPIDO_IMPLEMENTACAO.md      ✅ Este arquivo
```

## 🎯 Como Funciona

### Fluxo do Proprietário

```
1. Login
   ↓
2. Sistema detecta lojas
   ↓
3. Redirecionamento:
   - Sem lojas → /store-setup
   - 1 loja → /admin (define automaticamente)
   - Múltiplas → /stores (seleção)
   ↓
4. Gerencia loja selecionada
```

### Fluxo do Cliente

```
1. Acessa /s/hamburgueria-do-ze
   ↓
2. Vê cardápio da loja
   ↓
3. Faz pedido
   ↓
4. Paga via PIX (credenciais da loja)
```

## 🔧 Atualizar Componentes Admin

Componentes admin devem usar `currentStore.id`:

```tsx
import { useStore } from '@/contexts/StoreContext';

function ProductsPage() {
  const { currentStore } = useStore();
  
  // ✅ Correto: Filtra por loja
  const loadProducts = async () => {
    const products = await productsService.getAllByStore(currentStore.id);
  };
  
  // ✅ Correto: Cria com store_id
  const createProduct = async (data) => {
    await productsService.create({
      ...data,
      store_id: currentStore.id
    });
  };
}
```

## ⚠️ Importante

### Antes de Testar

1. ✅ Execute a migration
2. ✅ Regenere os tipos TypeScript
3. ✅ Adicione as rotas
4. ✅ Adicione o StoreProvider
5. ✅ (Opcional) Migre dados existentes

### Erros Comuns

**TypeScript reclamando de `stores`:**
→ Você ainda não regenerou os tipos após a migration

**`currentStore` sempre null:**
→ Verifique se `StoreProvider` está envolvendo a aplicação

**Loop de redirecionamento:**
→ Verifique se as rotas estão corretas no `useStoreRedirect`

## 🎉 Resultado Final

Após implementação:

✅ **Múltiplas lojas independentes**
- Cada proprietário pode ter várias lojas
- Dados completamente isolados

✅ **URLs únicas**
- `/s/hamburgueria-do-ze`
- `/s/pizzaria-bella`
- `/s/churrascaria-gaucha`

✅ **Redirecionamento automático**
- Sem lojas → Setup
- 1 loja → Admin direto
- Múltiplas → Seleção

✅ **Segurança garantida**
- RLS isola dados por loja
- Credenciais MP por loja
- Validação server-side

## 📞 Suporte

Dúvidas? Consulte:
- `MULTI_TENANT_SETUP.md` - Setup detalhado
- `RESUMO_MULTI_TENANT.md` - Visão geral
- `REDIRECIONAMENTO_AUTOMATICO.md` - Sistema de redirecionamento

## 🚀 Próximos Passos

Após implementação básica:

1. [ ] Testar criação de loja
2. [ ] Testar redirecionamento
3. [ ] Atualizar componentes admin para usar `store_id`
4. [ ] Testar isolamento de dados
5. [ ] Configurar Mercado Pago por loja
6. [ ] Compartilhar URL da loja com clientes
7. [ ] Testar pedidos na loja pública

---

**Tempo estimado de implementação:** 15-30 minutos

**Complexidade:** Média (requer migration no banco)

**Impacto:** Alto (transforma sistema em multi-tenant)
