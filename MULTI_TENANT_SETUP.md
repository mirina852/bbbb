# Guia de Migração: Multi-Tenant

Este guia explica como transformar o sistema de single-tenant para multi-tenant, permitindo múltiplas lojas independentes.

## Arquitetura

### Estrutura de URLs
- **Loja pública**: `/s/{slug}` (ex: `/s/hamburgueria-do-ze`)
- **Admin**: `/admin` (área autenticada do proprietário)
- **Seleção de loja**: `/stores` (para proprietários com múltiplas lojas)

### Isolamento de Dados
Cada loja tem seus próprios:
- Produtos
- Categorias
- Pedidos
- Credenciais do Mercado Pago
- Configurações visuais

## Passo 1: Executar Migration no Supabase

1. Acesse o **Supabase Dashboard**
2. Vá em **SQL Editor**
3. Execute o arquivo: `supabase/migrations/20251011200000_create_stores_multi_tenant.sql`

Esta migration irá:
- ✅ Criar tabela `stores`
- ✅ Adicionar `store_id` em todas as tabelas
- ✅ Atualizar políticas RLS para isolamento por loja
- ✅ Criar funções auxiliares (`generate_unique_slug`, `get_user_store_id`)

## Passo 2: Regenerar Tipos TypeScript

Após executar a migration, regenere os tipos do Supabase:

```bash
npx supabase gen types typescript --project-id YOUR_PROJECT_ID > src/integrations/supabase/types.ts
```

Ou manualmente no dashboard:
1. Settings > API
2. Copie os tipos TypeScript gerados
3. Cole em `src/integrations/supabase/types.ts`

## Passo 3: Migrar Dados Existentes (Opcional)

Se você já tem dados no sistema, execute este SQL para migrar para a primeira loja:

```sql
-- Criar loja padrão para o primeiro usuário
INSERT INTO public.stores (
  owner_id,
  name,
  slug,
  description,
  delivery_fee,
  is_active,
  is_open
)
SELECT 
  id as owner_id,
  'Minha Loja' as name,
  'minha-loja' as slug,
  'Loja migrada automaticamente' as description,
  5.00 as delivery_fee,
  true as is_active,
  true as is_open
FROM auth.users
LIMIT 1;

-- Associar produtos existentes à primeira loja
UPDATE public.products
SET store_id = (SELECT id FROM public.stores LIMIT 1)
WHERE store_id IS NULL;

-- Associar pedidos existentes à primeira loja
UPDATE public.orders
SET store_id = (SELECT id FROM public.stores LIMIT 1)
WHERE store_id IS NULL;

-- Associar categorias existentes à primeira loja
UPDATE public.categories
SET store_id = (SELECT id FROM public.stores LIMIT 1)
WHERE store_id IS NULL;

-- Associar credenciais existentes à primeira loja
UPDATE public.merchant_payment_credentials
SET store_id = (SELECT id FROM public.stores LIMIT 1)
WHERE store_id IS NULL;
```

## Passo 4: Atualizar Rotas

Adicione as novas rotas no arquivo de rotas principal:

```tsx
import StoreSlug from '@/pages/customer/StoreSlug';
import StoreSetup from '@/pages/admin/StoreSetup';
import StoreSelector from '@/pages/admin/StoreSelector';

// Adicionar nas rotas:
<Route path="/s/:slug" element={<StoreSlug />} />
<Route path="/stores" element={<StoreSelector />} />
<Route path="/store-setup" element={<StoreSetup />} />
```

## Passo 5: Adicionar StoreProvider

Envolva a aplicação com o `StoreProvider`:

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

## Arquivos Criados

### Contextos
- ✅ `src/contexts/StoreContext.tsx` - Gerenciamento de lojas

### Páginas
- ✅ `src/pages/customer/StoreSlug.tsx` - Loja pública dinâmica
- ⏳ `src/pages/admin/StoreSetup.tsx` - Configuração inicial da loja
- ⏳ `src/pages/admin/StoreSelector.tsx` - Seleção de loja (multi-lojas)

### Services
- ✅ `productsService.getAllByStore(storeId)` - Produtos por loja
- ⏳ `categoriesService.getAllByStore(storeId)` - Categorias por loja
- ⏳ `ordersService.createForStore(storeId, orderData)` - Pedidos por loja

### Migrations
- ✅ `20251011200000_create_stores_multi_tenant.sql`

## Fluxo de Uso

### Para Proprietários

1. **Primeiro acesso**:
   - Após login, é redirecionado para `/store-setup`
   - Preenche informações da loja (nome, endereço, etc.)
   - Sistema gera slug único automaticamente

2. **Com loja criada**:
   - Acessa `/admin` normalmente
   - Gerencia produtos, pedidos, configurações
   - Compartilha URL da loja: `/s/{slug}`

3. **Múltiplas lojas** (futuro):
   - Acessa `/stores` para selecionar qual loja gerenciar
   - Cada loja tem dados completamente isolados

### Para Clientes

1. Acessa `/s/{slug}` (ex: `/s/hamburgueria-do-ze`)
2. Navega pelo cardápio
3. Faz pedidos
4. Paga via PIX (usando credenciais do merchant daquela loja)

## Benefícios

✅ **Escalabilidade**: Suporta infinitas lojas  
✅ **Isolamento**: Dados completamente separados  
✅ **URLs únicas**: Cada loja tem sua URL personalizada  
✅ **Multi-tenant**: Vários proprietários no mesmo sistema  
✅ **Segurança**: RLS garante que cada proprietário vê apenas seus dados  

## Próximos Passos

1. ✅ Executar migration
2. ✅ Regenerar tipos TypeScript
3. ⏳ Criar página de setup de loja
4. ⏳ Criar página de seleção de lojas
5. ⏳ Atualizar componentes admin para usar `store_id`
6. ⏳ Testar isolamento de dados
7. ⏳ Atualizar Edge Functions para suportar multi-tenant

## Notas Importantes

- **Backward compatibility**: Dados existentes podem ser migrados
- **RLS**: Garante isolamento automático no banco
- **Slugs únicos**: Sistema gera automaticamente slugs sem conflito
- **Credenciais**: Cada loja tem suas próprias credenciais do Mercado Pago
