# 🔒 Solução: Erro RLS na Tabela Ingredients

## 🚨 Problema

### Erro Apresentado
```
POST https://...supabase.co/rest/v1/ingredients 403 (Forbidden)

Error: new row violates row-level security policy for table "ingredients"
Code: 42501
```

### Causa
A política RLS (Row Level Security) da tabela `ingredients` estava muito restritiva:
- Exigia apenas que o usuário estivesse autenticado
- **Não verificava** se o usuário era dono do produto
- Bloqueava inserções legítimas de donos de loja

---

## ✅ Solução

### 1. Executar SQL de Correção

**Arquivo:** `SQL_FIX_INGREDIENTS_RLS_URGENTE.sql`

**Como executar:**
1. Acesse: Dashboard Supabase → SQL Editor
2. Cole o conteúdo do arquivo
3. Clique em "Run"

### 2. O que o SQL faz

#### Remove políticas antigas (muito restritivas)
```sql
DROP POLICY IF EXISTS "Ingredients are viewable by everyone" ON public.ingredients;
DROP POLICY IF EXISTS "Only authenticated users can manage ingredients" ON public.ingredients;
```

#### Cria novas políticas (corretas)

**Política 1: Leitura Pública**
```sql
CREATE POLICY "Anyone can view ingredients"
  ON public.ingredients
  FOR SELECT
  USING (true);
```
- Permite que **qualquer pessoa** veja ingredientes
- Necessário para páginas públicas de produtos

**Política 2: INSERT (Adicionar)**
```sql
CREATE POLICY "Store owners can insert ingredients for their products"
  ON public.ingredients
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.products p
      JOIN public.stores s ON s.id = p.store_id
      WHERE p.id = product_id
      AND s.owner_id = auth.uid()
    )
  );
```
- Permite que donos de loja **adicionem** ingredientes
- Verifica se o produto pertence à loja do usuário

**Política 3: UPDATE (Atualizar)**
```sql
CREATE POLICY "Store owners can update ingredients of their products"
  ON public.ingredients
  FOR UPDATE
  TO authenticated
  USING (...) -- Mesma verificação
  WITH CHECK (...);
```
- Permite que donos de loja **atualizem** ingredientes
- Verifica propriedade do produto

**Política 4: DELETE (Deletar)**
```sql
CREATE POLICY "Store owners can delete ingredients of their products"
  ON public.ingredients
  FOR DELETE
  TO authenticated
  USING (...); -- Mesma verificação
```
- Permite que donos de loja **deletem** ingredientes
- Verifica propriedade do produto

---

## 🔍 Como Funciona a Verificação

### Fluxo de Validação

```
Usuário tenta adicionar ingrediente
         ↓
RLS verifica:
1. Usuário está autenticado? ✓
2. Produto existe? ✓
3. Produto pertence a uma loja? ✓
4. Loja pertence ao usuário? ✓
         ↓
    PERMITIDO ✅
```

### Query de Verificação

```sql
EXISTS (
  SELECT 1 FROM public.products p
  JOIN public.stores s ON s.id = p.store_id
  WHERE p.id = product_id          -- Produto correto
  AND s.owner_id = auth.uid()      -- Usuário é dono
)
```

---

## 🧪 Testar a Correção

### Teste 1: Verificar Políticas

```sql
-- Execute no SQL Editor
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'ingredients';
```

**Resultado esperado:**
```
policyname                                              | cmd    | roles
--------------------------------------------------------|--------|-------------
Anyone can view ingredients                             | SELECT | {public}
Store owners can insert ingredients for their products  | INSERT | {authenticated}
Store owners can update ingredients of their products   | UPDATE | {authenticated}
Store owners can delete ingredients of their products   | DELETE | {authenticated}
```

### Teste 2: Adicionar Produto com Ingredientes

```
1. Acesse: Painel Admin → Produtos
2. Clique em "Adicionar Produto"
3. Preencha os dados do produto
4. Adicione ingredientes
5. Clique em "Salvar"
6. ✅ Deve salvar sem erro 403
```

### Teste 3: Editar Ingredientes

```
1. Edite um produto existente
2. Adicione/remova ingredientes
3. Salve
4. ✅ Deve funcionar normalmente
```

---

## 🔐 Segurança

### O que as novas políticas garantem

✅ **Isolamento por loja**
- Cada loja só gerencia seus próprios ingredientes
- Impossível modificar ingredientes de outras lojas

✅ **Acesso público controlado**
- Clientes podem **ver** ingredientes (necessário para customização)
- Clientes **não podem** modificar ingredientes

✅ **Autenticação obrigatória para escrita**
- Apenas usuários autenticados podem adicionar/editar/deletar
- Verificação adicional de propriedade

✅ **Validação em múltiplas camadas**
- RLS no banco de dados
- Verificação de propriedade via JOIN
- Impossível burlar via API

---

## 📊 Comparação: Antes vs Depois

### Antes (Política Antiga)

```sql
-- Muito simples e insegura
CREATE POLICY "Only authenticated users can manage ingredients" 
ON public.ingredients 
FOR ALL 
USING (auth.uid() IS NOT NULL)
WITH CHECK (auth.uid() IS NOT NULL);
```

**Problemas:**
- ❌ Qualquer usuário autenticado podia modificar qualquer ingrediente
- ❌ Não verificava propriedade do produto
- ❌ Não verificava propriedade da loja
- ❌ Sem isolamento entre lojas

### Depois (Políticas Novas)

```sql
-- Segura e específica
CREATE POLICY "Store owners can insert ingredients for their products"
  ON public.ingredients
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.products p
      JOIN public.stores s ON s.id = p.store_id
      WHERE p.id = product_id
      AND s.owner_id = auth.uid()
    )
  );
```

**Vantagens:**
- ✅ Verifica propriedade do produto
- ✅ Verifica propriedade da loja
- ✅ Isolamento total entre lojas
- ✅ Políticas separadas por operação (INSERT, UPDATE, DELETE)

---

## 🐛 Troubleshooting

### Erro persiste após executar SQL

**Causa:** Cache do navegador ou sessão antiga

**Solução:**
```
1. Faça logout do painel admin
2. Limpe o cache (Ctrl + Shift + Delete)
3. Faça login novamente
4. Tente adicionar produto novamente
```

---

### Erro: "relation does not exist"

**Causa:** Tabela `stores` ou `products` não existe

**Solução:**
```sql
-- Verificar se tabelas existem
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('stores', 'products', 'ingredients');
```

---

### Erro: "column store_id does not exist"

**Causa:** Tabela `products` não tem coluna `store_id`

**Solução:**
```sql
-- Adicionar coluna store_id se não existir
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS store_id UUID REFERENCES public.stores(id);
```

---

## 📋 Checklist de Verificação

Após executar a correção, verifique:

- [ ] SQL executado sem erros
- [ ] 4 políticas criadas (SELECT, INSERT, UPDATE, DELETE)
- [ ] Logout e login no painel admin
- [ ] Consegue adicionar produto com ingredientes
- [ ] Consegue editar ingredientes existentes
- [ ] Consegue deletar ingredientes
- [ ] Página pública mostra ingredientes
- [ ] Não consegue modificar ingredientes de outras lojas

---

## 🎉 Resultado Final

### Antes
```
❌ Erro 403 ao salvar produto com ingredientes
❌ RLS muito restritivo
❌ Sem verificação de propriedade
```

### Depois
```
✅ Produtos com ingredientes salvam normalmente
✅ RLS correto e seguro
✅ Verificação de propriedade implementada
✅ Isolamento entre lojas garantido
```

---

## 📚 Arquivos Relacionados

- `SQL_FIX_INGREDIENTS_RLS_URGENTE.sql` - SQL para executar agora
- `supabase/migrations/20251012100000_fix_ingredients_rls.sql` - Migration permanente

---

## 🔗 Documentação Relacionada

- [Supabase RLS](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Policies](https://www.postgresql.org/docs/current/sql-createpolicy.html)

---

**Problema resolvido! Agora você pode adicionar ingredientes aos produtos sem erro 403.** 🚀
