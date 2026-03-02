# 🗄️ Estrutura do Banco de Dados - Supabase

## 📊 Tabelas Principais (via MCP)

### 1. 🏪 **stores** (3 registros)
**Descrição:** Lojas/restaurantes no sistema multi-tenant

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | ID único da loja |
| owner_id | uuid | Dono da loja (FK → auth.users) |
| name | text | Nome da loja |
| slug | text | URL amigável (único) |
| description | text | Descrição da loja |
| phone | text | Telefone |
| email | text | Email |
| address | text | Endereço |
| city | text | Cidade |
| state | text | Estado |
| zip_code | text | CEP |
| logo_url | text | URL do logo |
| background_urls | text[] | URLs de imagens de fundo |
| primary_color | text | Cor primária (#FF7A30) |
| delivery_fee | numeric | Taxa de entrega (padrão: 0) |
| is_active | boolean | Loja ativa? (padrão: true) |
| is_open | boolean | Loja aberta? (padrão: true) |
| created_at | timestamptz | Data de criação |
| updated_at | timestamptz | Última atualização |

**RLS:** ✅ Habilitado

---

### 2. 🍔 **products** (10 registros)
**Descrição:** Produtos/itens do cardápio

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | ID único do produto |
| store_id | uuid | Loja do produto (FK → stores) |
| name | text | Nome do produto |
| description | text | Descrição |
| price | numeric | Preço |
| image | text | URL da imagem (campo antigo) |
| category | text | Categoria (campo antigo) |
| category_id | uuid | ID da categoria (FK → categories) |
| available | boolean | Disponível? (padrão: true) |
| created_at | timestamptz | Data de criação |
| updated_at | timestamptz | Última atualização |

**RLS:** ✅ Habilitado

---

### 3. 🏷️ **categories** (6 registros)
**Descrição:** Categorias de produtos

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | ID único da categoria |
| store_id | uuid | Loja da categoria (FK → stores) |
| name | text | Nome da categoria |
| slug | text | URL amigável |
| icon | text | Ícone da categoria |
| position | integer | Posição de ordenação (padrão: 0) |
| display_order | integer | Ordem de exibição (padrão: 999) |
| created_at | timestamptz | Data de criação |
| updated_at | timestamptz | Última atualização |

**RLS:** ✅ Habilitado

---

### 4. 🧪 **ingredients** (19 registros)
**Descrição:** Ingredientes dos produtos

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | ID único do ingrediente |
| product_id | uuid | Produto (FK → products) |
| name | text | Nome do ingrediente |
| is_extra | boolean | É ingrediente extra? (padrão: false) |
| price | numeric | Preço adicional (se extra) |
| created_at | timestamptz | Data de criação |

**RLS:** ✅ Habilitado

---

### 5. 📦 **orders** (10 registros)
**Descrição:** Pedidos dos clientes

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | ID único do pedido |
| store_id | uuid | Loja do pedido (FK → stores) |
| customer_name | text | Nome do cliente |
| customer_phone | text | Telefone do cliente |
| delivery_address | text | Endereço de entrega |
| payment_method | text | Método de pagamento |
| total | numeric | Total do pedido (padrão: 0) |
| status | text | Status (padrão: 'pending') |
| created_at | timestamptz | Data de criação |
| updated_at | timestamptz | Última atualização |

**Status possíveis:** pending, confirmed, preparing, ready, delivered, cancelled

**RLS:** ✅ Habilitado

---

### 6. 📋 **order_items** (11 registros)
**Descrição:** Itens dos pedidos

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | ID único do item |
| order_id | uuid | Pedido (FK → orders) |
| product_id | uuid | Produto (FK → products) |
| product_name | text | Nome do produto (snapshot) |
| quantity | integer | Quantidade (> 0) |
| price | numeric | Preço unitário |
| removed_ingredients | jsonb | Ingredientes removidos (array JSON) |
| extra_ingredients | jsonb | Ingredientes extras (array JSON) |
| created_at | timestamptz | Data de criação |

**RLS:** ✅ Habilitado

---

### 7. 💳 **subscription_plans** (3 registros)
**Descrição:** Planos de assinatura disponíveis

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | ID único do plano |
| name | text | Nome do plano |
| slug | text | Identificador único |
| price | numeric | Preço (padrão: 0) |
| duration_days | integer | Duração em dias |
| is_trial | boolean | É teste gratuito? (padrão: false) |
| features | jsonb | Recursos do plano (array JSON) |
| is_active | boolean | Plano ativo? (padrão: true) |
| created_at | timestamptz | Data de criação |
| updated_at | timestamptz | Última atualização |

**Planos cadastrados:**
- Teste Gratuito (trial, 7 dias, R$ 0)
- Mensal (monthly, 30 dias, R$ 29.90)
- Anual (yearly, 365 dias, R$ 299.90)

**RLS:** ✅ Habilitado

---

### 8. 👤 **user_subscriptions** (4 registros)
**Descrição:** Assinaturas dos usuários

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | ID único da assinatura |
| user_id | uuid | Usuário (FK → auth.users) |
| subscription_plan_id | uuid | Plano (FK → subscription_plans) |
| status | text | Status (padrão: 'active') |
| expires_at | timestamptz | Data de expiração |
| created_at | timestamptz | Data de criação |
| updated_at | timestamptz | Última atualização |

**Status possíveis:** active, expired, cancelled

**RLS:** ✅ Habilitado

---

### 9. 💰 **subscription_payments** (3 registros)
**Descrição:** Pagamentos de assinaturas

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | ID único do pagamento |
| user_id | uuid | Usuário (FK → auth.users) |
| subscription_id | uuid | Assinatura (FK → user_subscriptions) |
| subscription_plan_id | uuid | Plano (FK → subscription_plans) |
| amount | numeric | Valor |
| status | text | Status (padrão: 'pending') |
| payment_method | text | Método (padrão: 'pix') |
| payment_id | text | ID interno |
| external_payment_id | text | ID externo (Mercado Pago) |
| qr_code | text | Código QR PIX |
| qr_code_base64 | text | QR Code em base64 |
| created_at | timestamptz | Data de criação |
| updated_at | timestamptz | Última atualização |

**Status possíveis:** pending, approved, rejected, cancelled

**RLS:** ✅ Habilitado

---

### 10. 🔑 **merchant_payment_credentials** (1 registro)
**Descrição:** Credenciais de pagamento do lojista

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | ID único |
| user_id | uuid | Usuário (FK → auth.users) |
| store_id | uuid | Loja (opcional) |
| public_key | text | Chave pública Mercado Pago |
| access_token | text | Token de acesso |
| environment | text | Ambiente (padrão: 'production') |
| is_active | boolean | Ativo? (padrão: true) |
| created_at | timestamptz | Data de criação |
| updated_at | timestamptz | Última atualização |

**Ambientes:** sandbox, production

**RLS:** ❌ Desabilitado

---

### 11. ⚙️ **site_settings** (1 registro)
**Descrição:** Configurações do site (legado)

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid | ID único |
| user_id | uuid | Usuário (FK → auth.users) |
| site_title | text | Título do site |
| logo_url | text | URL do logo |
| background_url | text | URL de fundo (singular) |
| background_urls | text[] | URLs de fundo (array) |
| primary_color | text | Cor primária (#FF7A30) |
| delivery_fee | numeric | Taxa de entrega (padrão: 5.00) |
| created_at | timestamptz | Data de criação |
| updated_at | timestamptz | Última atualização |

**RLS:** ❌ Desabilitado

---

## 📈 Estatísticas

| Tabela | Registros | RLS |
|--------|-----------|-----|
| stores | 3 | ✅ |
| products | 10 | ✅ |
| categories | 6 | ✅ |
| ingredients | 19 | ✅ |
| orders | 10 | ✅ |
| order_items | 11 | ✅ |
| subscription_plans | 3 | ✅ |
| user_subscriptions | 4 | ✅ |
| subscription_payments | 3 | ✅ |
| merchant_payment_credentials | 1 | ❌ |
| site_settings | 1 | ❌ |

**Total:** 11 tabelas principais

---

## 🔗 Relacionamentos

```
auth.users (Supabase Auth)
    ↓
    ├─→ stores (owner_id)
    │       ↓
    │       ├─→ products (store_id)
    │       │       ↓
    │       │       └─→ ingredients (product_id)
    │       │
    │       ├─→ categories (store_id)
    │       │       ↓
    │       │       └─→ products (category_id)
    │       │
    │       └─→ orders (store_id)
    │               ↓
    │               └─→ order_items (order_id)
    │                       ↓
    │                       └─→ products (product_id)
    │
    ├─→ user_subscriptions (user_id)
    │       ↓
    │       ├─→ subscription_plans (subscription_plan_id)
    │       └─→ subscription_payments (subscription_id)
    │
    ├─→ merchant_payment_credentials (user_id)
    └─→ site_settings (user_id)
```

---

## 🛡️ Segurança (RLS)

### Tabelas com RLS Habilitado ✅
- stores
- products
- categories
- ingredients
- orders
- order_items
- subscription_plans
- user_subscriptions
- subscription_payments

### Tabelas sem RLS ❌
- merchant_payment_credentials (credenciais sensíveis)
- site_settings (configurações legadas)

---

## 🔍 Queries Úteis via MCP

### Ver todas as lojas
```typescript
mcp0_execute_sql({
  project_id: "vnyrvgtioorpyohfvbim",
  query: "SELECT * FROM stores ORDER BY created_at DESC"
})
```

### Ver produtos de uma loja
```typescript
mcp0_execute_sql({
  project_id: "vnyrvgtioorpyohfvbim",
  query: "SELECT * FROM products WHERE store_id = 'uuid-da-loja'"
})
```

### Ver assinatura ativa
```typescript
mcp0_execute_sql({
  project_id: "vnyrvgtioorpyohfvbim",
  query: "SELECT * FROM get_active_subscription(auth.uid())"
})
```

---

## 📝 Notas

1. **Multi-tenant:** Sistema baseado em `stores` (lojas)
2. **RLS:** Maioria das tabelas tem Row Level Security
3. **Timestamps:** Todas as tabelas têm `created_at` e `updated_at`
4. **UUIDs:** Todos os IDs são UUID v4
5. **Soft Delete:** Não implementado (usa `is_active` em algumas tabelas)

---

**Estrutura mapeada via MCP do Supabase!** 🚀
