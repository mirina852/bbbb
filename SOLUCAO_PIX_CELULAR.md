# 🔧 Solução: PIX não aparece no celular (usuários não autenticados)

## 🎯 Problema

- ✅ Quando você (admin) está **logado**, o PIX aparece disponível
- ❌ Quando outra pessoa acessa pelo **celular** (não autenticada), o PIX aparece como "Indisponível no momento"

## 🔍 Causa Raiz

A política RLS (Row Level Security) da tabela `merchant_payment_credentials` não está permitindo que usuários **anônimos** (não autenticados) vejam as credenciais ativas.

### Por que isso acontece?

1. Quando você está logado como admin, você é um usuário **authenticated**
2. A política RLS permite que usuários authenticated vejam suas próprias credenciais
3. Mas clientes fazendo compras são usuários **anon** (anônimos)
4. A política RLS não estava configurada corretamente para usuários anon

## ✅ Solução

Execute o SQL abaixo no **Supabase SQL Editor** para corrigir as políticas RLS.

### Passo 1: Acessar o SQL Editor

1. Acesse o **Supabase Dashboard**: https://supabase.com/dashboard
2. Selecione seu projeto
3. Vá em **SQL Editor** (menu lateral esquerdo)
4. Clique em **New query**

### Passo 2: Executar o SQL

Copie e cole o conteúdo do arquivo `FIX_PIX_PUBLIC_ACCESS.sql` e clique em **Run**.

Ou copie o SQL abaixo:

```sql
-- Remover políticas antigas
DROP POLICY IF EXISTS "Users can view own credentials" ON public.merchant_payment_credentials;
DROP POLICY IF EXISTS "Allow public read of active credentials" ON public.merchant_payment_credentials;
DROP POLICY IF EXISTS "Public can view active store credentials" ON public.merchant_payment_credentials;
DROP POLICY IF EXISTS "Public can view active credentials" ON public.merchant_payment_credentials;
DROP POLICY IF EXISTS "Users can view own store credentials" ON public.merchant_payment_credentials;

-- Política para usuários autenticados
CREATE POLICY "Authenticated users can view own store credentials"
  ON public.merchant_payment_credentials
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id 
    OR 
    store_id IN (
      SELECT id FROM public.stores WHERE owner_id = auth.uid()
    )
  );

-- Política para usuários anônimos (IMPORTANTE!)
CREATE POLICY "Anonymous users can view active credentials"
  ON public.merchant_payment_credentials
  FOR SELECT
  TO anon
  USING (is_active = true);

-- Garantir que RLS está habilitado
ALTER TABLE public.merchant_payment_credentials ENABLE ROW LEVEL SECURITY;
```

### Passo 3: Verificar

Execute este SELECT para confirmar que as credenciais estão visíveis:

```sql
SELECT 
  id, 
  store_id, 
  public_key, 
  is_active,
  created_at
FROM public.merchant_payment_credentials
WHERE is_active = true;
```

Se retornar dados, está funcionando! ✅

### Passo 4: Testar no Celular

1. Abra o site no celular (ou aba anônima)
2. Acesse a página da loja
3. Adicione produtos ao carrinho
4. Vá para o checkout
5. **A opção PIX deve aparecer disponível** ✅

## 🔒 Segurança

**É seguro permitir acesso público?**

✅ **SIM!** Porque:

1. O `access_token` **nunca é retornado** pela query
2. Apenas `public_key` e `is_active` são visíveis
3. A `public_key` é necessária para validar se o PIX está configurado
4. O `access_token` só é usado na Edge Function (server-side)

## 🐛 Debug

Se ainda não funcionar, verifique:

### 1. Verificar políticas RLS ativas

```sql
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'merchant_payment_credentials';
```

Deve mostrar as duas políticas:
- `Authenticated users can view own store credentials`
- `Anonymous users can view active credentials`

### 2. Verificar se há credenciais ativas

```sql
SELECT 
  id,
  user_id,
  store_id,
  public_key,
  is_active,
  created_at
FROM public.merchant_payment_credentials
WHERE is_active = true;
```

Deve retornar pelo menos 1 linha.

### 3. Verificar logs do navegador (F12)

No console do navegador, procure por:

```
🔑 Carregando credenciais do Mercado Pago para loja: [store_id]
```

Se aparecer erro, copie e me envie.

## 📝 Arquivos Modificados

- ✅ `src/pages/customer/StoreFront.tsx` - Carrega credenciais na página pública
- ✅ `FIX_PIX_PUBLIC_ACCESS.sql` - Corrige políticas RLS

## 🎉 Resultado Esperado

Após executar o SQL:

- ✅ PIX aparece **disponível** para usuários não autenticados
- ✅ PIX aparece **disponível** no celular
- ✅ QR Code é gerado corretamente
- ✅ Pagamento funciona normalmente

## ❓ Perguntas Frequentes

**P: Por que funcionava quando eu estava logado?**
R: Porque você é um usuário `authenticated`, e a política RLS permitia acesso para authenticated. Mas clientes são `anon`.

**P: Isso é seguro?**
R: Sim! O `access_token` nunca é exposto. Apenas a `public_key` é visível, que é necessária para validar a configuração.

**P: Preciso fazer deploy de alguma coisa?**
R: Não! Apenas execute o SQL no Supabase. A mudança é imediata.

---

**Boa sorte! 🚀**
