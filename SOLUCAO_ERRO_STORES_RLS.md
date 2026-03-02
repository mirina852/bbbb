# 🔒 Solução: Erro RLS ao Criar Loja

## 🚨 Problema

### Erro Apresentado
```
Error: new row violates row-level security policy for table "stores"
Code: 42501
```

### Causa
A política RLS da tabela `stores` estava usando `FOR ALL` com apenas `USING`, mas para operações de **INSERT** é necessário também ter `WITH CHECK`.

#### Política Antiga (Incorreta)
```sql
CREATE POLICY "Owners can manage their stores"
  ON public.stores
  FOR ALL
  USING (auth.uid() = owner_id);  -- ❌ Falta WITH CHECK
```

**Problema:**
- `FOR ALL` abrange SELECT, INSERT, UPDATE, DELETE
- `USING` funciona para SELECT, UPDATE, DELETE
- **INSERT precisa de `WITH CHECK`** para validar novos registros
- Sem `WITH CHECK`, INSERT é bloqueado

---

## ✅ Solução

### 1. Executar SQL de Correção

**Arquivo:** `SQL_FIX_STORES_RLS_URGENTE.sql`

**Como executar:**
1. Acesse: **Dashboard Supabase** → **SQL Editor**
2. Cole o conteúdo do arquivo
3. Clique em **"Run"**

### 2. O que o SQL faz

#### Remove políticas antigas
```sql
DROP POLICY IF EXISTS "Active stores are viewable by everyone" ON public.stores;
DROP POLICY IF EXISTS "Owners can manage their stores" ON public.stores;
```

#### Cria políticas específicas

**Política 1: Leitura Pública**
```sql
CREATE POLICY "Anyone can view active stores"
  ON public.stores
  FOR SELECT
  USING (is_active = true);
```
- Permite que **qualquer pessoa** veja lojas ativas
- Necessário para páginas públicas

**Política 2: Leitura do Dono**
```sql
CREATE POLICY "Owners can view their stores"
  ON public.stores
  FOR SELECT
  TO authenticated
  USING (auth.uid() = owner_id);
```
- Permite que donos vejam suas próprias lojas (mesmo inativas)

**Política 3: INSERT (Criar Loja)**
```sql
CREATE POLICY "Authenticated users can create stores"
  ON public.stores
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);  -- ✅ WITH CHECK obrigatório
```
- Permite que usuários autenticados criem lojas
- Valida que `owner_id` = usuário logado

**Política 4: UPDATE (Atualizar)**
```sql
CREATE POLICY "Owners can update their stores"
  ON public.stores
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);
```
- Permite que donos atualizem suas lojas
- `USING`: Verifica se pode acessar o registro
- `WITH CHECK`: Valida os novos valores

**Política 5: DELETE (Deletar)**
```sql
CREATE POLICY "Owners can delete their stores"
  ON public.stores
  FOR DELETE
  TO authenticated
  USING (auth.uid() = owner_id);
```
- Permite que donos deletem suas lojas

---

## 🔍 Como Funciona

### Fluxo de Criação de Loja

```
Usuário clica em "Criar Loja"
         ↓
Frontend envia dados:
{
  name: "Minha Loja",
  slug: "minha-loja",
  owner_id: auth.uid()
}
         ↓
RLS verifica:
1. Usuário está autenticado? ✓
2. owner_id = auth.uid()? ✓
         ↓
    PERMITIDO ✅
```

### Query de Verificação

```sql
WITH CHECK (auth.uid() = owner_id)
```

Garante que:
- O `owner_id` inserido é o mesmo do usuário logado
- Usuário não pode criar loja para outro usuário
- Segurança garantida

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
WHERE tablename = 'stores';
```

**Resultado esperado:**
```
policyname                              | cmd    | roles
----------------------------------------|--------|-------------
Anyone can view active stores           | SELECT | {public}
Owners can view their stores            | SELECT | {authenticated}
Authenticated users can create stores   | INSERT | {authenticated}
Owners can update their stores          | UPDATE | {authenticated}
Owners can delete their stores          | DELETE | {authenticated}
```

### Teste 2: Criar Loja

```
1. Acesse o painel
2. Vá em "Configurar Loja" ou "Criar Nova Loja"
3. Preencha os dados:
   - Nome da loja
   - Slug
   - Outros campos
4. Clique em "Salvar"
5. ✅ Deve criar sem erro 403
```

### Teste 3: Ver Loja Pública

```
1. Acesse a URL pública da loja (ex: /minha-loja)
2. ✅ Deve mostrar a loja
```

---

## 🔐 Segurança

### O que as novas políticas garantem

✅ **Isolamento por usuário**
- Cada usuário só gerencia suas próprias lojas
- Impossível modificar lojas de outros usuários

✅ **Acesso público controlado**
- Clientes podem ver lojas ativas
- Clientes não podem ver lojas inativas
- Clientes não podem modificar nada

✅ **Validação em múltiplas camadas**
- RLS no banco de dados
- Verificação de propriedade via `owner_id`
- Impossível burlar via API

✅ **Criação segura**
- `WITH CHECK` valida novos registros
- Usuário não pode criar loja para outro usuário
- `owner_id` sempre validado

---

## 📊 Comparação: Antes vs Depois

### Antes (Política Única)

```sql
-- Política antiga (insegura)
CREATE POLICY "Owners can manage their stores"
  ON public.stores
  FOR ALL 
  USING (auth.uid() = owner_id);
```

**Problemas:**
- ❌ INSERT bloqueado (falta WITH CHECK)
- ❌ Política genérica demais
- ❌ Difícil de debugar
- ❌ Não permite leitura pública

### Depois (Políticas Específicas)

```sql
-- 5 políticas específicas
1. Anyone can view active stores (SELECT - público)
2. Owners can view their stores (SELECT - autenticado)
3. Authenticated users can create stores (INSERT)
4. Owners can update their stores (UPDATE)
5. Owners can delete their stores (DELETE)
```

**Vantagens:**
- ✅ INSERT funciona (WITH CHECK presente)
- ✅ Políticas específicas por operação
- ✅ Fácil de entender e debugar
- ✅ Permite leitura pública de lojas ativas

---

## 🐛 Troubleshooting

### Erro persiste após executar SQL

**Causa:** Cache do navegador ou sessão antiga

**Solução:**
```
1. Faça logout do painel
2. Limpe o cache (Ctrl + Shift + Delete)
3. Faça login novamente
4. Tente criar loja novamente
```

---

### Erro: "relation does not exist"

**Causa:** Tabela `stores` não existe

**Solução:**
```sql
-- Verificar se tabela existe
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'stores';

-- Se não existir, execute a migration:
-- supabase/migrations/20251011200000_create_stores_multi_tenant.sql
```

---

### Erro: "column owner_id does not exist"

**Causa:** Tabela `stores` não tem coluna `owner_id`

**Solução:**
```sql
-- Adicionar coluna se não existir
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL;
```

---

## 📋 Checklist de Verificação

Após executar a correção:

- [ ] SQL executado sem erros
- [ ] 5 políticas criadas (SELECT x2, INSERT, UPDATE, DELETE)
- [ ] Logout e login no painel
- [ ] Consegue criar nova loja
- [ ] Consegue editar loja existente
- [ ] Consegue ver loja pública
- [ ] Não consegue modificar lojas de outros usuários

---

## 🎉 Resultado Final

### Antes
```
❌ Erro 403 ao criar loja
❌ RLS bloqueando INSERT
❌ Política sem WITH CHECK
```

### Depois
```
✅ Lojas criadas normalmente
✅ RLS correto e seguro
✅ Políticas específicas com WITH CHECK
✅ Isolamento entre usuários garantido
```

---

## 📚 Arquivos Relacionados

- `SQL_FIX_STORES_RLS_URGENTE.sql` - SQL para executar agora
- `supabase/migrations/20251012120000_fix_stores_rls.sql` - Migration permanente
- `src/contexts/StoreContext.tsx` - Context que cria lojas

---

## 🔗 Documentação Relacionada

- [Supabase RLS](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Policies](https://www.postgresql.org/docs/current/sql-createpolicy.html)
- [RLS WITH CHECK](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)

---

**Execute o SQL agora e você poderá criar lojas sem erro 403!** 🚀
