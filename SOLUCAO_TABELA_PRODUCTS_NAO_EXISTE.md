# ❌ Erro: Could not find the table 'public.products'

## Problema

O erro indica que a tabela `products` **não existe** no banco de dados Supabase.

```
Erro ao salvar produto: Could not find the table 'public.products' in the schema cache
```

## Possíveis Causas

1. **Migrations não foram executadas** no Supabase
2. **Tabela tem nome diferente** (ex: `produtos` em português)
3. **Tabela foi deletada** acidentalmente
4. **Schema cache desatualizado** no Supabase

## 🔍 Passo 1: Verificar Qual Tabela Existe

Execute no **SQL Editor do Supabase**:

```sql
-- Ver todas as tabelas
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
```

### Resultado Possível 1: Tabela `produtos` existe

Se você vir `produtos` (português) na lista:
- ✅ A tabela existe, mas com nome em português
- ❌ O código está procurando `products` (inglês)

**Solução**: Renomear a tabela ou atualizar o código

### Resultado Possível 2: Nenhuma tabela de produtos

Se não houver `products` nem `produtos`:
- ❌ A tabela não existe
- ✅ Precisa criar a tabela

**Solução**: Executar script de criação

## 🛠️ Solução 1: Criar Tabela `products`

Execute o script **`CRIAR_TABELA_PRODUCTS.sql`** no SQL Editor:

```sql
CREATE TABLE IF NOT EXISTS public.products (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  store_id UUID REFERENCES public.stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  image TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT 'outros',
  available BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Criar índices
CREATE INDEX IF NOT EXISTS products_store_id_idx ON public.products(store_id);

-- Habilitar RLS
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Criar políticas (ver script completo)
```

### Verificar se funcionou:

```sql
-- Deve retornar a estrutura da tabela
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'products';
```

## 🛠️ Solução 2: Renomear Tabela Existente

Se você já tem uma tabela `produtos` (português):

```sql
-- Renomear tabela
ALTER TABLE public.produtos RENAME TO products;

-- Renomear colunas (se necessário)
ALTER TABLE public.products RENAME COLUMN nome TO name;
ALTER TABLE public.products RENAME COLUMN descricao TO description;
ALTER TABLE public.products RENAME COLUMN preco TO price;
ALTER TABLE public.products RENAME COLUMN disponivel TO available;
```

## 🛠️ Solução 3: Atualizar Schema Cache do Supabase

Às vezes o Supabase não atualiza o cache automaticamente:

1. **Vá para o Supabase Dashboard**
2. **Table Editor** → Clique em qualquer tabela
3. **Faça uma pequena alteração** (adicione/remova uma coluna temporária)
4. **Ou force refresh**: Settings → Database → "Restart Database"

## 🛠️ Solução 4: Executar Migrations

Se você tem migrations no projeto:

```bash
# No terminal do projeto
cd supabase
supabase db reset
supabase db push
```

Ou execute as migrations manualmente no SQL Editor.

## 📋 Script Completo de Verificação

Use o arquivo **`VERIFICAR_TABELA_PRODUTOS.sql`**:

```sql
-- 1. Ver todas as tabelas
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2. Procurar tabelas de produtos
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (table_name LIKE '%product%' OR table_name LIKE '%produto%');

-- 3. Ver estrutura da tabela products
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'products'
ORDER BY ordinal_position;

-- 4. Ver estrutura da tabela produtos (se existir)
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'produtos'
ORDER BY ordinal_position;
```

## ✅ Passo a Passo Completo

### 1. Verificar Situação Atual

Execute **`VERIFICAR_TABELA_PRODUTOS.sql`** no Supabase SQL Editor.

### 2. Escolher Solução

**Se não houver nenhuma tabela:**
- Execute **`CRIAR_TABELA_PRODUCTS.sql`**

**Se houver tabela `produtos`:**
- Opção A: Renomear para `products` (SQL acima)
- Opção B: Atualizar código para usar `produtos`

**Se houver tabela `products` mas dá erro:**
- Restart do database no Supabase
- Ou force refresh do schema cache

### 3. Testar

Após executar a solução:

```sql
-- Testar insert manual
INSERT INTO public.products (
  store_id, name, description, price, image, category
) VALUES (
  '[ID-DA-SUA-LOJA]',
  'Produto Teste',
  'Teste de criação',
  10.00,
  'https://via.placeholder.com/300',
  'teste'
);

-- Verificar se foi inserido
SELECT * FROM public.products ORDER BY created_at DESC LIMIT 1;
```

### 4. Testar no App

1. **Recarregue a página** do admin
2. **Tente adicionar um produto**
3. **Deve funcionar** ✅

## 🎯 Resumo das Soluções

| Situação | Solução | Script |
|----------|---------|--------|
| Tabela não existe | Criar tabela `products` | `CRIAR_TABELA_PRODUCTS.sql` |
| Tabela `produtos` existe | Renomear para `products` | SQL de rename acima |
| Tabela existe mas dá erro | Restart database | Supabase Dashboard |
| Não sabe qual tabela existe | Verificar primeiro | `VERIFICAR_TABELA_PRODUTOS.sql` |

## 📝 Ordem de Execução

1. ✅ Execute **`VERIFICAR_TABELA_PRODUTOS.sql`**
2. ✅ Veja qual tabela existe (ou não existe)
3. ✅ Execute **`CRIAR_TABELA_PRODUCTS.sql`** (se necessário)
4. ✅ Teste inserir produto manualmente (SQL acima)
5. ✅ Teste no app (adicionar produto pela interface)

## 🚨 Importante

Após criar/renomear a tabela:

1. **Limpe produtos sem `store_id`**:
   ```sql
   DELETE FROM products WHERE store_id IS NULL;
   ```

2. **Verifique políticas RLS**:
   ```sql
   SELECT policyname FROM pg_policies WHERE tablename = 'products';
   ```

3. **Teste permissões**:
   - Tente criar produto pela interface
   - Verifique se salva no banco
   - Confirme que aparece na lista

## ✅ Resultado Esperado

Após executar a solução correta:

- ✅ Tabela `products` existe
- ✅ Estrutura correta (colunas em inglês)
- ✅ RLS habilitado
- ✅ Políticas configuradas
- ✅ Produtos podem ser criados
- ✅ Produtos aparecem na lista

Execute os scripts e me avise o resultado! 🚀
