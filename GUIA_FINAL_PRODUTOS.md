# 🎯 GUIA FINAL: Por Que Produtos Não Aparecem

## 📊 Análise das Imagens

### ✅ O que está CORRETO:

1. **Produtos existem no banco** (Imagem 1)
   - `x-file` (R$ 25,00)
   - `coca` (R$ 7,00)
   - `x-file` (R$ 15,00)
   - `vvvv` (R$ 10,00)

2. **Produtos têm `store_id`** (Imagem 2)
   - Loja `fcebook`: 2 produtos ✅
   - Loja `mercadinhowp`: 2 produtos ✅
   - Loja `topburger`: 0 produtos (produtos NULL)

3. **Produtos estão disponíveis** (Imagem 2)
   - Todos marcados como `disponivel = true` ✅

4. **Admin vê produtos** (Imagem 4)
   - Página `/admin/products` mostra produtos ✅

### ❌ O que está ERRADO:

1. **Página pública NÃO mostra produtos**
   - URL `/s/fcebook` está vazia
   - Clientes não conseguem ver produtos

2. **Causa provável:**
   - **Políticas RLS** bloqueando acesso público
   - Código precisa de política `TO public`

## 🔧 Solução Definitiva

### Execute o script: **`CORRECAO_DEFINITIVA_PRODUTOS.sql`**

Ou copie e cole este SQL:

```sql
-- 1. Remover TODAS as políticas antigas
DO $$ 
DECLARE pol RECORD;
BEGIN
  FOR pol IN 
    SELECT policyname FROM pg_policies WHERE tablename = 'products'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.products', pol.policyname);
  END LOOP;
END $$;

-- 2. Criar política para ACESSO PÚBLICO
CREATE POLICY "public_read_available_products"
ON public.products
FOR SELECT
TO public
USING (available = true);

-- 3. Criar políticas para ADMIN
CREATE POLICY "authenticated_read_own_store_products"
ON public.products FOR SELECT TO authenticated
USING (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

CREATE POLICY "authenticated_insert_own_store_products"
ON public.products FOR INSERT TO authenticated
WITH CHECK (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

CREATE POLICY "authenticated_update_own_store_products"
ON public.products FOR UPDATE TO authenticated
USING (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()))
WITH CHECK (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

CREATE POLICY "authenticated_delete_own_store_products"
ON public.products FOR DELETE TO authenticated
USING (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

-- 4. Garantir que RLS está habilitado
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- 5. Testar acesso público
SELECT 
  p.name,
  p.price,
  s.slug as loja
FROM products p
JOIN stores s ON s.id = p.store_id
WHERE p.available = true AND s.slug = 'fcebook';
```

## ✅ Verificar se Funcionou

### Teste 1: Verificar Políticas

```sql
SELECT policyname, roles
FROM pg_policies
WHERE tablename = 'products';
```

**Resultado esperado:**
```
policyname                                  | roles
--------------------------------------------|----------------
public_read_available_products              | {public}
authenticated_read_own_store_products       | {authenticated}
authenticated_insert_own_store_products     | {authenticated}
authenticated_update_own_store_products     | {authenticated}
authenticated_delete_own_store_products     | {authenticated}
```

**Importante:** Deve ter uma política com `roles = {public}`!

### Teste 2: Simular Acesso Público

```sql
-- Este SELECT simula o que um cliente vê
SELECT name, price
FROM products
WHERE store_id = (SELECT id FROM stores WHERE slug = 'fcebook')
  AND available = true;
```

**Resultado esperado:**
```
name    | price
--------|-------
coca    | 7.00
x-file  | 25.00
```

Se retornar produtos aqui, deve funcionar na página!

### Teste 3: Verificar na Página

1. **Abra** `/s/fcebook` em aba anônima
2. **Abra Console** (F12)
3. **Veja os logs**:
   ```
   🔍 getAllByStore - Buscando produtos para loja: [id]
   ✅ Produtos encontrados: 2
   ```
4. **Produtos devem aparecer!**

## 🔍 Diagnóstico Adicional

Se ainda não funcionar, execute:

```sql
-- Ver detalhes completos
SELECT 
  'Loja fcebook' as info,
  COUNT(*) as total_produtos,
  COUNT(CASE WHEN available = true THEN 1 END) as disponiveis,
  STRING_AGG(name, ', ') as produtos
FROM products
WHERE store_id = (SELECT id FROM stores WHERE slug = 'fcebook');
```

E envie o resultado!

## 📋 Checklist Final

Execute em ordem:

- [ ] **1. Executar** `CORRECAO_DEFINITIVA_PRODUTOS.sql`
- [ ] **2. Verificar** que política `public_read_available_products` existe
- [ ] **3. Testar** SELECT público (deve retornar produtos)
- [ ] **4. Recarregar** página `/s/fcebook`
- [ ] **5. Abrir Console** (F12) e ver logs
- [ ] **6. Confirmar** que produtos aparecem

## 🎯 Resumo do Problema

### Antes (❌):
```
Políticas RLS:
- ❌ Apenas "authenticated" (admin)
- ❌ Nenhuma política "public"

Resultado:
- ✅ Admin vê produtos
- ❌ Clientes NÃO veem produtos
```

### Depois (✅):
```
Políticas RLS:
- ✅ "public" (qualquer pessoa)
- ✅ "authenticated" (admin)

Resultado:
- ✅ Admin vê produtos
- ✅ Clientes veem produtos
```

## 🚀 Ação Imediata

**Execute AGORA:**

1. Abra **Supabase SQL Editor**
2. Cole o script **`CORRECAO_DEFINITIVA_PRODUTOS.sql`**
3. Clique em **Run**
4. Recarregue `/s/fcebook`
5. **Produtos devem aparecer!** 🎉

## 📞 Se Ainda Não Funcionar

Envie os resultados de:

```sql
-- 1. Políticas
SELECT * FROM pg_policies WHERE tablename = 'products';

-- 2. Produtos
SELECT * FROM products WHERE store_id = (SELECT id FROM stores WHERE slug = 'fcebook');

-- 3. RLS Status
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'products';
```

Execute o script agora! 🚀
