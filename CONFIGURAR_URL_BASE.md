# 🌐 Configurar URL Base da Aplicação

## ✅ Problema Resolvido

Agora o sistema gera URLs exclusivas para cada loja usando a URL base correta!

## 📋 Como Funciona

### Site Principal:
```
http://localhost:8080/.vercel.app/store
```

### URLs das Lojas (Exclusivas):
```
http://localhost:8080/s/hamburgueria-do-ze
http://localhost:8080/s/pizzaria-bella
http://localhost:8080/s/lanchonete-central
```

## 🔧 Configuração

### 1. Criar arquivo `.env`

Copie o arquivo `.env.example` para `.env`:

```bash
cp .env.example .env
```

### 2. Editar o arquivo `.env`

Abra o arquivo `.env` e configure a URL base:

```env
# ============================================
# URL DA APLICAÇÃO
# ============================================
# URL base da aplicação (usado para gerar links de lojas)
# Em desenvolvimento: http://localhost:8080
# Em produção: https://seu-app.vercel.app
VITE_APP_URL=http://localhost:8080
```

### 3. Configurações por Ambiente

#### Desenvolvimento Local:
```env
VITE_APP_URL=http://localhost:8080
```

#### Produção (Vercel):
```env
VITE_APP_URL=https://seu-app.vercel.app
```

#### Produção (Domínio Personalizado):
```env
VITE_APP_URL=https://seudominio.com
```

## 📁 Arquivos Criados/Modificados

### 1. **`src/lib/utils/storeUrl.ts`** (NOVO)
Funções helper para gerar URLs:

```typescript
import { getStoreUrl } from '@/lib/utils/storeUrl';

// Gera URL da loja
const url = getStoreUrl('minha-loja'); 
// Resultado: http://localhost:8080/s/minha-loja
```

**Funções disponíveis:**
- `getBaseUrl()` - Retorna URL base
- `getStoreUrl(slug)` - URL da loja pública
- `getAdminUrl()` - URL do admin
- `getProductUrl(id)` - URL de produto

### 2. **`.env.example`** (ATUALIZADO)
Adicionada configuração `VITE_APP_URL`

### 3. **Componentes Atualizados:**
- ✅ `src/components/settings/StoreUrlDisplay.tsx`
- ✅ `src/pages/admin/StoreSetup.tsx`
- ✅ `src/components/auth/RegisterForm.tsx`

## 🎯 Como as URLs São Geradas

### Lógica de Prioridade:

```typescript
1. Se VITE_APP_URL está definido → Usa ele
2. Se está no Vercel → Usa window.location.origin
3. Se está em desenvolvimento → Usa window.location.origin
4. Fallback → http://localhost:8080
```

### Exemplo em Produção:

```env
# .env
VITE_APP_URL=https://meu-saas.vercel.app
```

**Resultado:**
- Loja 1: `https://meu-saas.vercel.app/s/hamburgueria-do-ze`
- Loja 2: `https://meu-saas.vercel.app/s/pizzaria-bella`
- Admin: `https://meu-saas.vercel.app/admin`

## 🚀 Testando

### 1. Configure o `.env`:
```env
VITE_APP_URL=http://localhost:8080
```

### 2. Reinicie o servidor:
```bash
npm run dev
```

### 3. Crie uma loja:
- Faça login
- Crie uma loja chamada "Minha Loja Teste"

### 4. Veja a URL gerada:
```
✅ Sua loja foi criada! 🎉
Acesse: http://localhost:8080/s/minha-loja-teste
```

### 5. Verifique em Configurações:
- Vá em Configurações → Personalização
- Veja o card "URL da Sua Loja"
- URL deve ser: `http://localhost:8080/s/minha-loja-teste`

## 📱 URLs Geradas

### Desenvolvimento:
```
Base: http://localhost:8080
Loja: http://localhost:8080/s/minha-loja
Admin: http://localhost:8080/admin
Produto: http://localhost:8080/product/123
```

### Produção (Vercel):
```
Base: https://meu-saas.vercel.app
Loja: https://meu-saas.vercel.app/s/minha-loja
Admin: https://meu-saas.vercel.app/admin
Produto: https://meu-saas.vercel.app/product/123
```

### Produção (Domínio Próprio):
```
Base: https://meudominio.com
Loja: https://meudominio.com/s/minha-loja
Admin: https://meudominio.com/admin
Produto: https://meudominio.com/product/123
```

## 🔐 Variáveis de Ambiente no Vercel

### Como Configurar no Vercel:

1. **Acesse seu projeto no Vercel**
2. **Vá em Settings → Environment Variables**
3. **Adicione:**
   ```
   Name: VITE_APP_URL
   Value: https://seu-app.vercel.app
   ```
4. **Salve e faça redeploy**

## ✅ Checklist

- [ ] Copiei `.env.example` para `.env`
- [ ] Configurei `VITE_APP_URL` no `.env`
- [ ] Reiniciei o servidor de desenvolvimento
- [ ] Testei criar uma loja
- [ ] Verifiquei a URL gerada
- [ ] URL está correta (http://localhost:8080/s/...)

## 🎯 Resumo

### Antes:
```
❌ URLs usando window.location.origin
❌ Não funcionava corretamente em produção
❌ Difícil de configurar
```

### Agora:
```
✅ URLs usando VITE_APP_URL (configurável)
✅ Funciona em desenvolvimento e produção
✅ Fácil de configurar via .env
✅ Cada loja tem URL exclusiva
```

## 📝 Exemplos de Uso

### No Código:

```typescript
import { getStoreUrl, getAdminUrl } from '@/lib/utils/storeUrl';

// Gerar URL de loja
const storeUrl = getStoreUrl('minha-loja');
console.log(storeUrl); 
// http://localhost:8080/s/minha-loja

// Gerar URL do admin
const adminUrl = getAdminUrl();
console.log(adminUrl); 
// http://localhost:8080/admin
```

### Em Componentes:

```tsx
import { getStoreUrl } from '@/lib/utils/storeUrl';

const MyComponent = () => {
  const store = useStore();
  const url = getStoreUrl(store.slug);
  
  return (
    <a href={url} target="_blank">
      Ver Loja
    </a>
  );
};
```

## 🎉 Pronto!

Agora cada loja tem sua **URL exclusiva** e você pode configurar facilmente a URL base da aplicação! 🚀

### URLs Finais:

- **Site Principal**: `http://localhost:8080/store`
- **Loja 1**: `http://localhost:8080/s/hamburgueria-do-ze`
- **Loja 2**: `http://localhost:8080/s/pizzaria-bella`
- **Admin**: `http://localhost:8080/admin`

Cada dono de negócio recebe sua URL exclusiva automaticamente! ✅
