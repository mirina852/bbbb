# 🗺️ Estrutura de Rotas do Site

## ✅ Configuração Atual

A Landing Page **JÁ É** a página inicial do site!

```
http://localhost:8080/ → Landing Page (Marketing)
```

---

## 📍 Mapa Completo de Rotas

### **🏠 Página Inicial (Landing)**
```
URL: http://localhost:8080/
Componente: Landing.tsx
Descrição: Página de marketing com informações sobre o produto
Conteúdo:
  - Título: "Venda Mais com Seu Cardápio Digital"
  - Recursos do produto
  - Planos e preços
  - Depoimentos
  - Botões: "Começar Grátis" e "Ver Recursos"
```

---

### **🛍️ Páginas de Loja (Clientes)**

#### **Loja Genérica**
```
URL: http://localhost:8080/store
Componente: StoreFront.tsx
Descrição: Loja de demonstração (não vinculada a uma loja específica)
```

#### **Loja Específica (Multi-tenant)**
```
URL: http://localhost:8080/loja/[slug]
Componente: StoreSlug.tsx
Descrição: Loja personalizada de cada cliente
Exemplo: http://localhost:8080/loja/hamburgueria-do-ze
```

#### **Página de Produto**
```
URL: http://localhost:8080/product/:id
Componente: ProductPage.tsx
Descrição: Detalhes de um produto específico
```

#### **Sucesso do Pedido**
```
URL: http://localhost:8080/order-success
Componente: OrderSuccess.tsx
Descrição: Confirmação após fazer um pedido
```

#### **Rastreamento de Pedido**
```
URL: http://localhost:8080/track-order
Componente: OrderTracking.tsx
Descrição: Acompanhar status do pedido
```

---

### **🔐 Páginas de Autenticação**

#### **Login/Registro**
```
URL: http://localhost:8080/auth
Componente: Auth.tsx
Descrição: Página de login e cadastro
```

---

### **👨‍💼 Páginas Admin (Protegidas)**

#### **Dashboard**
```
URL: http://localhost:8080/admin
Componente: Dashboard.tsx
Descrição: Painel principal com estatísticas
Requer: Autenticação
```

#### **Produtos**
```
URL: http://localhost:8080/admin/products
Componente: Products.tsx
Descrição: Gerenciar produtos do cardápio
Requer: Autenticação
```

#### **Pedidos**
```
URL: http://localhost:8080/admin/orders
Componente: Orders.tsx
Descrição: Gerenciar pedidos dos clientes
Requer: Autenticação
```

#### **Configurações**
```
URL: http://localhost:8080/admin/settings
Componente: Settings.tsx
Descrição: Configurações da loja (personalização, notificações, pagamentos)
Requer: Autenticação
```

#### **Assinatura**
```
URL: http://localhost:8080/admin/subscription
Componente: Subscription.tsx
Descrição: Gerenciar plano de assinatura
Requer: Autenticação
```

#### **Seletor de Loja**
```
URL: http://localhost:8080/store-selector
Componente: StoreSelector.tsx
Descrição: Escolher qual loja gerenciar (multi-tenant)
Requer: Autenticação
```

#### **Configuração de Loja**
```
URL: http://localhost:8080/store-setup
Componente: StoreSetup.tsx
Descrição: Criar/configurar nova loja
Requer: Autenticação
```

---

### **💳 Páginas de Planos**

#### **Planos de Assinatura**
```
URL: http://localhost:8080/planos
Componente: SubscriptionPlans.tsx
Descrição: Ver e escolher planos disponíveis
```

---

## 🔄 Fluxo de Navegação

### **Fluxo do Cliente (Fazer Pedido)**
```
1. Landing Page (/)
   ↓ Clica "Começar Grátis" ou acessa link da loja
2. Loja Específica (/loja/[slug])
   ↓ Adiciona produtos ao carrinho
3. Checkout (modal na mesma página)
   ↓ Confirma pedido
4. Página de Sucesso (/order-success)
   ↓ Pode rastrear pedido
5. Rastreamento (/track-order)
```

### **Fluxo do Lojista (Criar Loja)**
```
1. Landing Page (/)
   ↓ Clica "Começar Grátis"
2. Registro/Login (/auth)
   ↓ Faz cadastro
3. Configuração de Loja (/store-setup)
   ↓ Cria loja
4. Dashboard Admin (/admin)
   ↓ Adiciona produtos
5. Produtos (/admin/products)
   ↓ Compartilha link da loja
6. Clientes acessam (/loja/[slug])
```

---

## 🎯 Hierarquia de Rotas

```
/ (Landing Page) ← PÁGINA INICIAL
├── /auth (Login/Registro)
├── /planos (Planos)
│
├── /store (Loja genérica)
├── /loja/:slug (Loja específica)
│   ├── /product/:id (Produto)
│   ├── /order-success (Sucesso)
│   └── /track-order (Rastreamento)
│
└── /admin (Painel Admin)
    ├── /admin/products (Produtos)
    ├── /admin/orders (Pedidos)
    ├── /admin/settings (Configurações)
    ├── /admin/subscription (Assinatura)
    ├── /store-selector (Seletor)
    └── /store-setup (Configuração)
```

---

## 🔒 Proteção de Rotas

### **Rotas Públicas** (Qualquer um pode acessar)
- ✅ `/` (Landing)
- ✅ `/store` (Loja genérica)
- ✅ `/loja/:slug` (Loja específica)
- ✅ `/product/:id` (Produto)
- ✅ `/order-success` (Sucesso)
- ✅ `/track-order` (Rastreamento)
- ✅ `/auth` (Login)
- ✅ `/planos` (Planos)

### **Rotas Protegidas** (Precisa estar autenticado)
- 🔒 `/admin` (Dashboard)
- 🔒 `/admin/products` (Produtos)
- 🔒 `/admin/orders` (Pedidos)
- 🔒 `/admin/settings` (Configurações)
- 🔒 `/admin/subscription` (Assinatura)
- 🔒 `/store-selector` (Seletor)
- 🔒 `/store-setup` (Configuração)

---

## 🚀 Como Acessar

### **Desenvolvimento (Local)**
```
Landing Page:     http://localhost:8080/
Loja Exemplo:     http://localhost:8080/loja/hamburgueria-do-ze
Admin:            http://localhost:8080/admin
Login:            http://localhost:8080/auth
```

### **Produção (Vercel)**
```
Landing Page:     https://cardapiolojista.vercel.app/
Loja Exemplo:     https://cardapiolojista.vercel.app/loja/hamburgueria-do-ze
Admin:            https://cardapiolojista.vercel.app/admin
Login:            https://cardapiolojista.vercel.app/auth
```

---

## 📝 Código das Rotas

```typescript
// src/App.tsx (linhas 54-110)
<BrowserRouter>
  <Routes>
    {/* Página Inicial - Landing Page */}
    <Route path="/" element={<Landing />} />
    
    {/* Lojas */}
    <Route path="/store" element={<StoreFront />} />
    <Route path="/loja/:slug" element={<StoreSlug />} />
    
    {/* Produtos e Pedidos */}
    <Route path="/product/:id" element={<ProductPage />} />
    <Route path="/order-success" element={<OrderSuccess />} />
    <Route path="/track-order" element={<OrderTracking />} />
    
    {/* Autenticação */}
    <Route path="/auth" element={<Auth />} />
    <Route path="/planos" element={<SubscriptionPlans />} />
    
    {/* Admin (Protegido) */}
    <Route path="/admin" element={
      <ProtectedRoute requireAdmin>
        <Dashboard />
      </ProtectedRoute>
    } />
    
    {/* Outras rotas admin... */}
  </Routes>
</BrowserRouter>
```

---

## ✅ Confirmação

### **Sua configuração atual:**
```
✅ http://localhost:8080/ → Landing Page (Marketing)
✅ A Landing Page JÁ É a página inicial
✅ Não precisa fazer nenhuma alteração
```

### **Para testar:**
1. Abra o navegador
2. Acesse: `http://localhost:8080/`
3. ✅ Deve aparecer a Landing Page com:
   - Logo "Petisco"
   - Título "Venda Mais com Seu Cardápio Digital"
   - Botões "Começar Grátis" e "Ver Recursos"

---

## 🎨 Personalização da Landing Page

Se quiser personalizar a Landing Page:

**Arquivo:** `src/pages/customer/Landing.tsx`

**Você pode alterar:**
- Título e descrição
- Recursos exibidos
- Planos e preços
- Depoimentos
- Cores e estilos
- Botões de ação

---

## 🔄 Redirecionamentos

### **Rota não encontrada**
```
URL: http://localhost:8080/qualquer-coisa-invalida
Comportamento: Redireciona para / (Landing Page)
```

### **Usuário não autenticado tenta acessar admin**
```
URL: http://localhost:8080/admin
Comportamento: Redireciona para /auth (Login)
```

---

## 📊 Resumo

| URL | Página | Público |
|-----|--------|---------|
| `/` | Landing Page | ✅ Sim |
| `/loja/:slug` | Loja do Cliente | ✅ Sim |
| `/admin` | Dashboard Admin | ❌ Não (Requer login) |

---

## 🎉 Conclusão

**Tudo está configurado corretamente!**

A Landing Page já é a página inicial do seu site em `http://localhost:8080/`. Não é necessário fazer nenhuma alteração.

Se você quiser mudar o conteúdo da Landing Page, edite o arquivo:
- `src/pages/customer/Landing.tsx`
