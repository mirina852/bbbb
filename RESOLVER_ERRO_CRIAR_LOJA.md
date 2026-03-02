# 🔧 Resolver: Erro ao Criar Loja

## ❌ Problema

Ao tentar criar uma loja (registro ou `/store-setup`), aparece:
```
Erro ao criar loja. Tente novamente.
```

## 🔍 Possíveis Causas

1. ❌ **Função `generate_unique_slug` não existe**
2. ❌ **Tabela `stores` sem RLS correto**
3. ❌ **Campos faltando na tabela**
4. ❌ **Políticas RLS bloqueando insert**

## ✅ Solução Completa

### Passo 1: Execute o SQL de Correção

**Arquivo:** `SQL_CORRIGIR_ERRO_CRIAR_LOJA.sql`

Execute no Supabase SQL Editor. Este SQL:

1. ✅ **Cria função `generate_unique_slug`**
   - Gera slugs únicos a partir do nome
   - Remove acentos e caracteres especiais
   - Adiciona número se slug já existir

2. ✅ **Verifica estrutura da tabela `stores`**
   - Adiciona campos faltantes
   - Garante que todos os campos necessários existem

3. ✅ **Habilita RLS** na tabela `stores`

4. ✅ **Cria 4 políticas RLS:**
   - SELECT (qualquer um vê lojas ativas)
   - INSERT (usuários autenticados criam lojas)
   - UPDATE (apenas donos atualizam)
   - DELETE (apenas donos deletam)

5. ✅ **Cria índices** para performance

6. ✅ **Testa a função** de geração de slug

### Passo 2: Verificar Resultado

Após executar o SQL, você deve ver:

```
✅ Função generate_unique_slug existe
✅ RLS está HABILITADO na tabela stores
🛡️  Políticas RLS: 4
✅ Todas as políticas criadas (SELECT, INSERT, UPDATE, DELETE)
🏪 Total de lojas: X
```

### Passo 3: Testar Criação de Loja

#### Opção A: Via Interface

1. **Logout** (se estiver logado)
2. **Clique em "Criar Conta"**
3. Preencha:
   - Nome da Loja: "Minha Loja Teste"
   - Seu Nome: "João Silva"
   - E-mail: "teste@email.com"
   - Senha: "123456"
4. **Clique em "Criar Conta e Loja"**

**Resultado esperado:**
```
✅ Conta criada com sucesso! 🎉
Sua loja está no ar: http://localhost:8080/s/minha-loja-teste
```

#### Opção B: Via SQL (Teste Manual)

```sql
-- Pegar seu user_id
SELECT id, email FROM auth.users LIMIT 1;

-- Testar função de slug
SELECT public.generate_unique_slug('Minha Loja Teste');

-- Criar loja manualmente
INSERT INTO public.stores (
  owner_id,
  name,
  slug,
  description,
  primary_color,
  delivery_fee,
  is_active,
  is_open
) VALUES (
  'SEU_USER_ID_AQUI',  -- ⚠️ SUBSTITUA
  'Loja Teste',
  public.generate_unique_slug('Loja Teste'),
  'Loja de teste',
  '#FF7A30',
  5.00,
  true,
  true
)
RETURNING *;
```

## 🔍 Diagnóstico de Erros

### Erro 1: "function generate_unique_slug() does not exist"

**Causa:** Função não foi criada

**Solução:**
```sql
-- Execute a seção 1 do SQL_CORRIGIR_ERRO_CRIAR_LOJA.sql
CREATE OR REPLACE FUNCTION public.generate_unique_slug(store_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
-- ... (código completo no arquivo SQL)
$$;
```

### Erro 2: "new row violates row-level security policy"

**Causa:** Políticas RLS bloqueando insert

**Solução:**
```sql
-- Verificar políticas
SELECT * FROM pg_policies WHERE tablename = 'stores';

-- Recriar política de INSERT
DROP POLICY IF EXISTS "stores_insert" ON public.stores;
CREATE POLICY "stores_insert" 
  ON public.stores 
  FOR INSERT 
  WITH CHECK (auth.uid() = owner_id);
```

### Erro 3: "column does not exist"

**Causa:** Campo faltando na tabela

**Solução:**
```sql
-- Ver campos da tabela
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'stores';

-- Execute a seção 5 do SQL_CORRIGIR_ERRO_CRIAR_LOJA.sql
-- para adicionar campos faltantes
```

### Erro 4: "duplicate key value violates unique constraint"

**Causa:** Slug já existe

**Solução:**
A função `generate_unique_slug` deve resolver isso automaticamente.
Se persistir:
```sql
-- Ver slugs existentes
SELECT slug FROM public.stores ORDER BY slug;

-- Testar geração de slug único
SELECT public.generate_unique_slug('Minha Loja');
```

## 📋 Checklist de Verificação

Execute estes comandos no Supabase SQL Editor:

### 1. Verificar Função
```sql
SELECT EXISTS (
  SELECT 1 FROM pg_proc WHERE proname = 'generate_unique_slug'
) AS function_exists;
-- Deve retornar: true ✅
```

### 2. Verificar RLS
```sql
SELECT rowsecurity FROM pg_tables WHERE tablename = 'stores';
-- Deve retornar: true ✅
```

### 3. Verificar Políticas
```sql
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'stores';
-- Deve retornar: 4 políticas (SELECT, INSERT, UPDATE, DELETE) ✅
```

### 4. Verificar Campos
```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'stores' 
ORDER BY ordinal_position;
-- Deve incluir: owner_id, name, slug, is_active, is_open, etc. ✅
```

### 5. Testar Função
```sql
SELECT public.generate_unique_slug('Teste') AS slug;
-- Deve retornar: 'teste' ou 'teste-1' ✅
```

## 🎯 Estrutura Correta da Tabela

```sql
CREATE TABLE public.stores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  phone TEXT,
  email TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  zip_code TEXT,
  logo_url TEXT,
  background_urls TEXT[],
  primary_color TEXT DEFAULT '#FF7A30',
  delivery_fee DECIMAL(10,2) DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  is_open BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

-- RLS Habilitado
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- Políticas
CREATE POLICY "stores_select" ON public.stores FOR SELECT USING (is_active = true);
CREATE POLICY "stores_insert" ON public.stores FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "stores_update" ON public.stores FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "stores_delete" ON public.stores FOR DELETE USING (auth.uid() = owner_id);
```

## 🚀 Solução Rápida (Tudo de Uma Vez)

Se nada funcionar, execute este SQL que recria tudo:

```sql
-- 1. Recriar função
CREATE OR REPLACE FUNCTION public.generate_unique_slug(store_name TEXT)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE base_slug TEXT; final_slug TEXT; counter INTEGER := 0;
BEGIN
  base_slug := lower(translate(store_name, 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ', 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'));
  base_slug := regexp_replace(base_slug, '[^a-z0-9]+', '-', 'g');
  base_slug := trim(both '-' from base_slug);
  IF base_slug = '' THEN base_slug := 'loja'; END IF;
  final_slug := base_slug;
  WHILE EXISTS (SELECT 1 FROM public.stores WHERE slug = final_slug) LOOP
    counter := counter + 1;
    final_slug := base_slug || '-' || counter;
  END LOOP;
  RETURN final_slug;
END; $$;

-- 2. Habilitar RLS
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- 3. Recriar políticas
DROP POLICY IF EXISTS "stores_select" ON public.stores;
DROP POLICY IF EXISTS "stores_insert" ON public.stores;
DROP POLICY IF EXISTS "stores_update" ON public.stores;
DROP POLICY IF EXISTS "stores_delete" ON public.stores;

CREATE POLICY "stores_select" ON public.stores FOR SELECT USING (is_active = true);
CREATE POLICY "stores_insert" ON public.stores FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "stores_update" ON public.stores FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "stores_delete" ON public.stores FOR DELETE USING (auth.uid() = owner_id);
```

## ✅ Resultado Final

Após aplicar as correções:

### Antes:
```
❌ Erro ao criar loja. Tente novamente.
```

### Agora:
```
✅ Conta criada com sucesso! 🎉
Sua loja está no ar: http://localhost:8080/s/minha-loja-teste
```

## 📝 Arquivos Modificados

```
1. SQL_CORRIGIR_ERRO_CRIAR_LOJA.sql (NOVO)
   └── Corrige função, tabela e RLS

2. src/components/auth/RegisterForm.tsx (MODIFICADO)
   └── Mensagens de erro mais específicas
```

## 🎉 Pronto!

Execute o SQL e teste criar uma loja novamente! 🚀

## 📞 Se Ainda Não Funcionar

1. **Abra o Console** (F12)
2. **Veja o erro exato** na aba Console
3. **Me envie a mensagem de erro** completa
4. **Execute:** `SELECT * FROM pg_policies WHERE tablename = 'stores';`
5. **Me envie o resultado**

Assim posso ajudar com o problema específico!
