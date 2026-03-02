# ✅ Adição: Botão de Login no Header

## Objetivo

Adicionar um botão "Entrar" ao lado do carrinho no header da página da loja que redireciona para `/auth` quando o usuário não está logado.

## Implementação

### Código Adicionado:

```typescript
// StoreSlug.tsx

// 1. Importar ícone e hook de autenticação
import { Utensils, AlertCircle, LogIn } from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';

// 2. Obter usuário do contexto
const { user } = useAuth();

// 3. Adicionar botão no header (ao lado do carrinho)
<header className="bg-white py-4 sticky top-0 z-10 shadow-sm">
  <div className="container mx-auto px-4 flex justify-between items-center">
    <div className="flex items-center gap-2">
      <Utensils className="h-6 w-6 text-[#FF7A30]" />
      <h1 className="text-xl font-bold">{currentStore.name}</h1>
    </div>
    <div className="flex items-center gap-3">
      {/* ✅ Botão de Login (só aparece se não estiver logado) */}
      {!user && (
        <Button
          variant="outline"
          size="sm"
          onClick={() => navigate('/auth')}
          className="flex items-center gap-2"
        >
          <LogIn className="h-4 w-4" />
          <span className="hidden sm:inline">Entrar</span>
        </Button>
      )}
      
      {/* Carrinho */}
      <Cart
        cartItems={cartItems}
        onRemoveFromCart={removeFromCart}
        onUpdateQuantity={updateQuantity}
        onCheckout={handleCheckout}
      />
    </div>
  </div>
</header>
```

## Como Funciona

### Lógica Condicional:

```typescript
{!user && (
  <Button onClick={() => navigate('/auth')}>
    <LogIn className="h-4 w-4" />
    <span className="hidden sm:inline">Entrar</span>
  </Button>
)}
```

**Comportamento:**
- Se `user` é `null` (não logado) → Botão aparece ✅
- Se `user` existe (logado) → Botão não aparece ❌

### Responsividade:

```typescript
<span className="hidden sm:inline">Entrar</span>
```

**Comportamento:**
- **Mobile** (< 640px): Mostra apenas ícone 📱
- **Desktop** (≥ 640px): Mostra ícone + texto "Entrar" 💻

## Fluxo do Usuário

### Cenário 1: Usuário Não Logado

```
1. Usuário acessa /s/appp
   ↓
2. user = null
   ↓
3. Botão "Entrar" aparece no header ✅
   ↓
4. Usuário clica em "Entrar"
   ↓
5. navigate('/auth')
   ↓
6. Redireciona para página de autenticação
   ↓
7. Usuário faz login
   ↓
8. Volta para /s/appp (logado)
   ↓
9. Botão "Entrar" desaparece ✅
```

### Cenário 2: Usuário Logado

```
1. Admin faz login
   ↓
2. user = { id: '...', email: '...' }
   ↓
3. Acessa /s/appp
   ↓
4. Botão "Entrar" NÃO aparece ✅
   ↓
5. Vê apenas carrinho no header
```

## Layout

### Desktop (≥ 640px):

```
┌────────────────────────────────────────────────┐
│  🍴 mercadinhomvp    [🔓 Entrar]  [🛒 Carrinho] │
└────────────────────────────────────────────────┘
```

### Mobile (< 640px):

```
┌────────────────────────────────┐
│  🍴 mercadinhomvp  [🔓] [🛒]   │
└────────────────────────────────┘
```

## Estilos

### Botão:

```typescript
<Button
  variant="outline"      // Borda, fundo branco
  size="sm"              // Tamanho pequeno
  className="flex items-center gap-2"  // Ícone + texto
>
```

**Visual:**
- Borda cinza
- Fundo branco
- Hover: Fundo cinza claro
- Ícone + texto alinhados

### Ícone:

```typescript
<LogIn className="h-4 w-4" />
```

**Visual:**
- Tamanho: 16x16px
- Cor: Herda do botão
- Ícone de "entrar" (seta para dentro)

## Arquivo Modificado

**`src/pages/customer/StoreSlug.tsx`**

### Mudanças:

**Linha 12:** Importado ícone `LogIn`
```typescript
import { Utensils, AlertCircle, LogIn } from 'lucide-react';
```

**Linha 19:** Importado `useAuth`
```typescript
import { useAuth } from '@/contexts/AuthContext';
```

**Linha 34:** Obtido `user`
```typescript
const { user } = useAuth();
```

**Linhas 275-285:** Adicionado botão de login
```typescript
{!user && (
  <Button
    variant="outline"
    size="sm"
    onClick={() => navigate('/auth')}
    className="flex items-center gap-2"
  >
    <LogIn className="h-4 w-4" />
    <span className="hidden sm:inline">Entrar</span>
  </Button>
)}
```

## Benefícios

### 1. Acesso Fácil ao Login

```
Antes (❌):
- Usuário não sabia como fazer login
- Precisava digitar /auth na URL
- Confuso

Depois (✅):
- Botão visível no header
- Um clique para fazer login
- Intuitivo
```

### 2. UX Melhorada

```
- Botão sempre visível (sticky header)
- Responsivo (mobile e desktop)
- Só aparece quando necessário
```

### 3. Conversão

```
- Facilita cadastro de novos usuários
- Incentiva login
- Melhora engajamento
```

## Casos de Uso

### Caso 1: Cliente Quer Acompanhar Pedido

```
1. Cliente faz pedido sem login
2. Quer acompanhar pedido
3. Vê botão "Entrar" no header
4. Clica e faz login
5. ✅ Pode acompanhar pedidos
```

### Caso 2: Dono de Loja Visita Outra Loja

```
1. Admin da Loja A faz logout
2. Visita Loja B como cliente
3. Vê botão "Entrar"
4. Clica e faz login
5. ✅ Volta ao painel admin
```

### Caso 3: Cliente Quer Salvar Favoritos (futuro)

```
1. Cliente navega pela loja
2. Quer salvar produtos favoritos
3. Vê botão "Entrar"
4. Clica e cria conta
5. ✅ Pode salvar favoritos
```

## Teste

### Teste 1: Botão Aparece (Não Logado)

```
1. Abra aba anônima (Ctrl+Shift+N)
2. Acesse /s/appp
3. ✅ Deve ver botão "Entrar" no header
4. ✅ Botão deve estar ao lado do carrinho
```

### Teste 2: Botão Redireciona

```
1. Abra aba anônima
2. Acesse /s/appp
3. Clique em "Entrar"
4. ✅ Deve redirecionar para /auth
5. ✅ Deve ver página de login
```

### Teste 3: Botão Desaparece (Logado)

```
1. Faça login como admin
2. Acesse /s/appp
3. ✅ Botão "Entrar" NÃO deve aparecer
4. ✅ Deve ver apenas carrinho
```

### Teste 4: Responsividade

```
1. Acesse /s/appp (não logado)
2. Desktop (> 640px):
   ✅ Deve mostrar ícone + "Entrar"
3. Redimensione para mobile (< 640px):
   ✅ Deve mostrar apenas ícone
4. Clique no ícone:
   ✅ Deve redirecionar para /auth
```

### Teste 5: Fluxo Completo

```
1. Abra aba anônima
2. Acesse /s/appp
3. Veja botão "Entrar"
4. Clique no botão
5. Faça login
6. ✅ Volta para /s/appp
7. ✅ Botão "Entrar" desapareceu
8. Faça logout
9. ✅ Botão "Entrar" aparece novamente
```

## Melhorias Futuras

### 1. Dropdown de Usuário (quando logado)

```typescript
{user ? (
  <DropdownMenu>
    <DropdownMenuTrigger>
      <Avatar>
        <AvatarFallback>{user.email[0].toUpperCase()}</AvatarFallback>
      </Avatar>
    </DropdownMenuTrigger>
    <DropdownMenuContent>
      <DropdownMenuItem>Meus Pedidos</DropdownMenuItem>
      <DropdownMenuItem>Perfil</DropdownMenuItem>
      <DropdownMenuItem onClick={logout}>Sair</DropdownMenuItem>
    </DropdownMenuContent>
  </DropdownMenu>
) : (
  <Button onClick={() => navigate('/auth')}>Entrar</Button>
)}
```

### 2. Badge de Notificações

```typescript
<Button onClick={() => navigate('/auth')}>
  <LogIn className="h-4 w-4" />
  <span>Entrar</span>
  <Badge className="ml-2">Novo</Badge>
</Button>
```

### 3. Tooltip

```typescript
<TooltipProvider>
  <Tooltip>
    <TooltipTrigger asChild>
      <Button onClick={() => navigate('/auth')}>
        <LogIn className="h-4 w-4" />
      </Button>
    </TooltipTrigger>
    <TooltipContent>
      <p>Faça login para acompanhar seus pedidos</p>
    </TooltipContent>
  </Tooltip>
</TooltipProvider>
```

## Checklist

- [x] Importado `LogIn` icon
- [x] Importado `useAuth`
- [x] Obtido `user` do contexto
- [x] Adicionado botão condicional
- [x] Configurado redirecionamento
- [x] Adicionado responsividade
- [ ] **Recarregar aplicação** ← FAÇA AGORA!
- [ ] **Testar botão** ← VERIFIQUE!

## Próximos Passos

1. **Recarregue** a aplicação (Ctrl+R)
2. **Abra aba anônima** (Ctrl+Shift+N)
3. **Acesse** `/s/appp`
4. **Veja** o botão "Entrar" no header ✅
5. **Clique** no botão
6. **Deve redirecionar** para `/auth` ✅

---

**Recarregue a aplicação e teste o botão de login!** 🔓🔐
