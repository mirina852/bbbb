# 🔧 Resolver: URL da Loja Não Aparece

## ❌ Problema

Ao acessar **Configurações → Personalização**, aparece:
```
URL da Loja
Nenhuma loja selecionada
```

## 🔍 Diagnóstico

### Passo 1: Verificar se a Loja Existe no Banco

Execute este SQL no Supabase SQL Editor:

```sql
-- Ver todas as lojas
SELECT 
  id,
  owner_id,
  name,
  slug,
  is_active,
  created_at
FROM public.stores
ORDER BY created_at DESC;
```

**Resultado esperado:**
- ✅ Se aparecer sua loja → Vá para Passo 2
- ❌ Se não aparecer nenhuma loja → Vá para Solução 1

### Passo 2: Verificar Console do Navegador

1. Abra o DevTools (F12)
2. Vá na aba **Console**
3. Procure por mensagens como:
   ```
   StoreUrlDisplay - currentStore: null
   StoreUrlDisplay - userStores: []
   ```

**Resultado:**
- Se `userStores: []` (vazio) → Problema de RLS ou query
- Se `userStores: [...]` mas `currentStore: null` → Problema de seleção

---

## ✅ Soluções

### Solução 1: Criar Loja (Se não existir)

#### Opção A: Via Interface
1. Acesse: `http://localhost:8080/store-setup`
2. Preencha o formulário
3. Clique "Criar conta"

#### Opção B: Via SQL
```sql
-- IMPORTANTE: Pegue seu user_id em Authentication > Users no Supabase
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
  'SEU_USER_ID_AQUI',  -- ⚠️ SUBSTITUA AQUI
  'Minha Loja',
  'minha-loja',
  'Descrição da minha loja',
  '#FF7A30',
  5.00,
  true,
  true
)
RETURNING *;
```

### Solução 2: Verificar e Corrigir RLS

Execute este SQL:

```sql
-- 1. Verificar se RLS está habilitado
SELECT 
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'stores';

-- 2. Se rowsecurity = false, habilitar:
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- 3. Recriar políticas RLS
DROP POLICY IF EXISTS "stores_select" ON public.stores;
CREATE POLICY "stores_select" 
  ON public.stores 
  FOR SELECT 
  USING (is_active = true);

DROP POLICY IF EXISTS "stores_all" ON public.stores;
CREATE POLICY "stores_all" 
  ON public.stores 
  FOR ALL 
  USING (auth.uid() = owner_id);
```

### Solução 3: Forçar Recarregamento

#### No Navegador:
1. Abra as Configurações
2. Clique no botão **"Recarregar Lojas"** (novo botão adicionado)
3. Veja se as lojas aparecem

#### Via Código (Temporário):
Adicione este código no `StoreContext.tsx` linha 192:

```typescript
useEffect(() => {
  if (user?.id) {
    console.log('🔄 Carregando lojas para user:', user.id);
    loadUserStores();
  } else {
    setUserStores([]);
  }
}, [user?.id]);
```

### Solução 4: Verificar Função generate_unique_slug

```sql
-- Verificar se existe
SELECT EXISTS (
  SELECT FROM pg_proc 
  WHERE proname = 'generate_unique_slug'
) AS function_exists;

-- Se não existir, criar:
CREATE OR REPLACE FUNCTION public.generate_unique_slug(store_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 0;
BEGIN
  base_slug := lower(translate(store_name, 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ', 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'));
  base_slug := regexp_replace(base_slug, '[^a-z0-9]+', '-', 'g');
  base_slug := trim(both '-' from base_slug);
  final_slug := base_slug;
  
  WHILE EXISTS (SELECT 1 FROM public.stores WHERE slug = final_slug) LOOP
    counter := counter + 1;
    final_slug := base_slug || '-' || counter;
  END LOOP;
  
  RETURN final_slug;
END;
$$;
```

### Solução 5: Limpar Cache e Relogar

1. **Fazer logout**
2. **Limpar cache do navegador** (Ctrl+Shift+Del)
3. **Fazer login novamente**
4. **Ir em Configurações**

---

## 🎯 Checklist de Verificação

Execute na ordem:

- [ ] **1. Verificar se loja existe no banco**
  ```sql
  SELECT * FROM public.stores;
  ```

- [ ] **2. Verificar RLS**
  ```sql
  SELECT rowsecurity FROM pg_tables WHERE tablename = 'stores';
  ```

- [ ] **3. Verificar políticas RLS**
  ```sql
  SELECT * FROM pg_policies WHERE tablename = 'stores';
  ```

- [ ] **4. Verificar função generate_unique_slug**
  ```sql
  SELECT EXISTS (SELECT FROM pg_proc WHERE proname = 'generate_unique_slug');
  ```

- [ ] **5. Verificar console do navegador** (F12)

- [ ] **6. Tentar recarregar lojas** (botão na interface)

- [ ] **7. Criar loja se não existir** (`/store-setup`)

---

## 📊 Diagnóstico Automático

Execute este SQL completo:

```sql
-- DIAGNÓSTICO COMPLETO
DO $$
DECLARE
  store_count INTEGER;
  user_count INTEGER;
  rls_enabled BOOLEAN;
  function_exists BOOLEAN;
BEGIN
  -- Contar lojas
  SELECT COUNT(*) INTO store_count FROM public.stores;
  RAISE NOTICE '📊 Total de lojas: %', store_count;
  
  -- Contar usuários
  SELECT COUNT(*) INTO user_count FROM auth.users;
  RAISE NOTICE '👥 Total de usuários: %', user_count;
  
  -- Verificar RLS
  SELECT rowsecurity INTO rls_enabled FROM pg_tables WHERE tablename = 'stores';
  IF rls_enabled THEN
    RAISE NOTICE '🔒 RLS está HABILITADO';
  ELSE
    RAISE WARNING '⚠️  RLS está DESABILITADO';
  END IF;
  
  -- Verificar função
  SELECT EXISTS (SELECT FROM pg_proc WHERE proname = 'generate_unique_slug') INTO function_exists;
  IF function_exists THEN
    RAISE NOTICE '✅ Função generate_unique_slug existe';
  ELSE
    RAISE WARNING '❌ Função generate_unique_slug NÃO existe';
  END IF;
  
  -- Resumo
  IF store_count = 0 THEN
    RAISE WARNING '⚠️  PROBLEMA: Nenhuma loja criada. Execute /store-setup';
  ELSIF NOT rls_enabled THEN
    RAISE WARNING '⚠️  PROBLEMA: RLS desabilitado. Execute: ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;';
  ELSIF NOT function_exists THEN
    RAISE WARNING '⚠️  PROBLEMA: Função generate_unique_slug não existe. Execute SQL_FINAL_COMPLETO.sql';
  ELSE
    RAISE NOTICE '✅ Tudo parece OK! Verifique o console do navegador.';
  END IF;
END $$;
```

---

## 🚀 Solução Rápida (Tudo de Uma Vez)

Se nada funcionar, execute este SQL que recria tudo:

```sql
-- 1. Recriar tabela stores (CUIDADO: apaga dados existentes)
DROP TABLE IF EXISTS public.stores CASCADE;

CREATE TABLE public.stores (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
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
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2. Habilitar RLS
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- 3. Criar políticas
CREATE POLICY "stores_select" ON public.stores FOR SELECT USING (is_active = true);
CREATE POLICY "stores_all" ON public.stores FOR ALL USING (auth.uid() = owner_id);

-- 4. Criar função
CREATE OR REPLACE FUNCTION public.generate_unique_slug(store_name TEXT)
RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE base_slug TEXT; final_slug TEXT; counter INTEGER := 0;
BEGIN
  base_slug := lower(translate(store_name, 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ', 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'));
  base_slug := regexp_replace(base_slug, '[^a-z0-9]+', '-', 'g');
  base_slug := trim(both '-' from base_slug);
  final_slug := base_slug;
  WHILE EXISTS (SELECT 1 FROM public.stores WHERE slug = final_slug) LOOP
    counter := counter + 1;
    final_slug := base_slug || '-' || counter;
  END LOOP;
  RETURN final_slug;
END; $$;

-- 5. Criar índices
CREATE INDEX IF NOT EXISTS stores_owner_id_idx ON public.stores(owner_id);
CREATE INDEX IF NOT EXISTS stores_slug_idx ON public.stores(slug);
```

---

## ✅ Resultado Esperado

Após aplicar as soluções, você deve ver:

```
┌─────────────────────────────────────────┐
│ 🔗 URL da Sua Loja                      │
├─────────────────────────────────────────┤
│ Compartilhe este link com seus clientes│
│                                         │
│ http://localhost:8080/s/minha-loja [📋]│
│                                         │
│ [Copiar Link]  [Compartilhar]          │
└─────────────────────────────────────────┘
```

---

## 📝 Resumo

### Causas Comuns:
1. ❌ Loja não foi criada
2. ❌ RLS bloqueando acesso
3. ❌ Função `generate_unique_slug` não existe
4. ❌ Cache do navegador

### Soluções:
1. ✅ Criar loja via `/store-setup`
2. ✅ Executar `SQL_FINAL_COMPLETO.sql`
3. ✅ Verificar RLS e políticas
4. ✅ Limpar cache e relogar

---

## 🎉 Pronto!

Após seguir estes passos, sua URL da loja deve aparecer corretamente! 🚀
