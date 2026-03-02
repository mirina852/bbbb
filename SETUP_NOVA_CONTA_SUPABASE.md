# Setup para Nova Conta do Supabase

## 📋 Checklist Completo

### ✅ 1. Executar SQL no Supabase

1. Acesse o **Supabase Dashboard** da sua nova conta
2. Vá em **SQL Editor**
3. Clique em **New Query**
4. Cole TODO o conteúdo do arquivo: `SQL_COMPLETO_MULTI_TENANT.sql`
5. Clique em **RUN** (ou Ctrl+Enter)
6. Aguarde a execução (deve levar alguns segundos)
7. Verifique se não há erros

### ✅ 2. Configurar Autenticação

1. Vá em **Authentication** → **Providers**
2. Habilite **Email**:
   - ✅ Enable Email provider
   - Para desenvolvimento: **DESABILITE** "Confirm email"
   - Para produção: **HABILITE** "Confirm email"

### ✅ 3. Pegar Credenciais do Projeto

1. Vá em **Settings** → **API**
2. Copie:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGc...` (chave longa)

### ✅ 4. Atualizar Frontend

Edite o arquivo: `src/integrations/supabase/client.ts`

```typescript
const SUPABASE_URL = "SUA_PROJECT_URL_AQUI";
const SUPABASE_PUBLISHABLE_KEY = "SUA_ANON_KEY_AQUI";
```

### ✅ 5. Regenerar Tipos TypeScript

```bash
npx supabase gen types typescript --project-id SEU_PROJECT_ID > src/integrations/supabase/types.ts
```

**Ou manualmente:**
1. Vá em **Settings** → **API** → **Generate Types**
2. Copie o código TypeScript gerado
3. Cole em `src/integrations/supabase/types.ts`

### ✅ 6. Configurar Edge Functions (Mercado Pago)

Se você usa pagamento PIX, configure as variáveis de ambiente:

1. Vá em **Edge Functions** → **Settings**
2. Adicione as variáveis:
   ```
   PLATFORM_MERCADOPAGO_ACCESS_TOKEN=seu_token_aqui
   PLATFORM_MERCADOPAGO_PUBLIC_KEY=sua_public_key_aqui
   ```

### ✅ 7. Testar o Sistema

1. **Inicie o projeto:**
   ```bash
   npm run dev
   ```

2. **Crie uma conta:**
   - Acesse `/login` ou `/signup`
   - Cadastre-se com email e senha

3. **Crie uma loja:**
   - Após login, será redirecionado para `/store-setup`
   - Preencha os dados da loja
   - Clique em "Criar Loja"

4. **Verifique a URL da loja:**
   - Você verá um toast com a URL: `/s/sua-loja`
   - Acesse essa URL em uma aba anônima (cliente)

5. **Teste o fluxo completo:**
   - ✅ Criar produtos no admin
   - ✅ Ver produtos na loja pública
   - ✅ Fazer pedido como cliente
   - ✅ Ver pedido no admin

## 🔧 Comandos Úteis

### Verificar se as tabelas foram criadas:

No SQL Editor, execute:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;
```

Você deve ver:
- ✅ stores
- ✅ products
- ✅ orders
- ✅ order_items
- ✅ ingredients
- ✅ categories
- ✅ merchant_payment_credentials
- ✅ site_settings

### Verificar políticas RLS:

```sql
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename;
```

### Criar primeiro usuário admin (opcional):

```sql
-- Criar usuário de teste
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'admin@teste.com',
  crypt('senha123', gen_salt('bf')),
  now(),
  now(),
  now()
);
```

## 🚨 Problemas Comuns

### Erro: "relation does not exist"
**Solução:** Execute o SQL completo novamente

### Erro: "permission denied for table"
**Solução:** Verifique as políticas RLS

### Erro: "Invalid API key"
**Solução:** Verifique se copiou a chave correta em `client.ts`

### Tipos TypeScript com erro
**Solução:** Regenere os tipos após executar o SQL

### Edge Function não funciona
**Solução:** Configure as variáveis de ambiente do Mercado Pago

## 📝 Arquivo de Configuração Atual

Seu arquivo atual (`src/integrations/supabase/client.ts`):

```typescript
const SUPABASE_URL = "https://tboghergvgbhmjzgzxaj.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = "eyJhbGc...";
```

**⚠️ IMPORTANTE:** Atualize esses valores com as credenciais da sua NOVA conta!

## ✅ Checklist Final

Antes de começar a usar:

- [ ] SQL executado sem erros
- [ ] Autenticação habilitada
- [ ] Credenciais atualizadas no `client.ts`
- [ ] Tipos TypeScript regenerados
- [ ] Projeto rodando (`npm run dev`)
- [ ] Consegue criar conta
- [ ] Consegue criar loja
- [ ] Consegue acessar loja pública
- [ ] Consegue fazer pedido

## 🎉 Pronto!

Após completar todos os passos, seu sistema multi-tenant estará funcionando na nova conta do Supabase!
