# 🔧 Solução Final - Erro no Checkout

## Problema Identificado

O erro persiste porque pode haver um dos seguintes problemas:

1. **Cliente Supabase está autenticado** (usando token de admin)
2. **Políticas RLS não estão sendo aplicadas corretamente**
3. **Permissões GRANT não foram dadas**
4. **Há políticas conflitantes**

## 🎯 Solução em 3 Passos

### PASSO 1: Execute o Diagnóstico

Execute **`DIAGNOSTICO_RLS_COMPLETO.sql`** e me envie os resultados dos testes que falharem.

### PASSO 2: Solução Temporária (Teste)

Se você precisa que funcione AGORA, execute isto:

```sql
-- DESABILITAR RLS TEMPORARIAMENTE (apenas para teste)
ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items DISABLE ROW LEVEL SECURITY;
```

**ATENÇÃO:** Isso remove toda a segurança! Use apenas para testar se o problema é RLS.

Depois de testar, **reabilite**:

```sql
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
```

### PASSO 3: Solução Definitiva

Se o PASSO 2 funcionou, o problema é nas políticas. Execute:

```sql
-- ============================================
-- SOLUÇÃO DEFINITIVA - FORÇAR PERMISSÕES
-- ============================================

-- 1. Limpar tudo
DO $$ 
DECLARE r RECORD;
BEGIN
    FOR r IN (
        SELECT policyname
        FROM pg_policies
        WHERE tablename IN ('orders', 'order_items')
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', 
            r.policyname, 
            CASE 
                WHEN EXISTS (SELECT 1 FROM pg_policies WHERE policyname = r.policyname AND tablename = 'orders')
                THEN 'orders'
                ELSE 'order_items'
            END
        );
    END LOOP;
END $$;

-- 2. Habilitar RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- 3. Revogar e dar permissões
REVOKE ALL ON public.orders FROM PUBLIC;
REVOKE ALL ON public.order_items FROM PUBLIC;
REVOKE ALL ON public.orders FROM anon;
REVOKE ALL ON public.order_items FROM anon;

GRANT INSERT ON public.orders TO anon;
GRANT INSERT ON public.order_items TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.orders TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.order_items TO authenticated;

-- 4. Criar políticas simples
CREATE POLICY "allow_anon_insert_orders"
ON public.orders
FOR INSERT
TO anon
WITH CHECK (true);

CREATE POLICY "allow_anon_insert_order_items"
ON public.order_items
FOR INSERT
TO anon
WITH CHECK (true);

CREATE POLICY "allow_authenticated_all_orders"
ON public.orders
FOR ALL
TO authenticated
USING (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()))
WITH CHECK (store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid()));

CREATE POLICY "allow_authenticated_all_order_items"
ON public.order_items
FOR ALL
TO authenticated
USING (order_id IN (
  SELECT o.id FROM orders o
  JOIN stores s ON s.id = o.store_id
  WHERE s.owner_id = auth.uid()
));

-- 5. Verificar
SELECT 
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename IN ('orders', 'order_items')
ORDER BY tablename, roles;

-- Deve mostrar:
-- orders: 2 políticas (anon INSERT, authenticated ALL)
-- order_items: 2 políticas (anon INSERT, authenticated ALL)
```

## 🔍 Diagnóstico Alternativo

Se nada funcionar, o problema pode ser:

### 1. Cliente está usando token de admin

Verifique no console do navegador (F12):

```javascript
// No console
localStorage.getItem('supabase.auth.token')
```

Se retornar um token, o cliente está autenticado. Para limpar:

```javascript
localStorage.clear()
```

Depois recarregue a página.

### 2. Supabase não está usando a chave anon

Verifique em `src/integrations/supabase/client.ts`:

```typescript
const SUPABASE_PUBLISHABLE_KEY = "eyJ..."; // Deve ser a chave anon
```

### 3. Há uma sessão ativa

O cliente pode estar usando uma sessão de admin. Para testar:

1. Abra **aba anônima** (Ctrl+Shift+N)
2. Acesse `/s/fcebook`
3. Tente fazer checkout

Se funcionar na aba anônima mas não na normal, o problema é sessão ativa.

## 🚨 Solução de Emergência

Se NADA funcionar, use esta solução temporária:

```sql
-- DESABILITAR RLS (SEM SEGURANÇA!)
ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.products DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.stores DISABLE ROW LEVEL SECURITY;
```

**ATENÇÃO:** Isso remove TODA a segurança! Qualquer pessoa pode fazer qualquer coisa!

Use apenas para:
1. Testar se o checkout funciona
2. Confirmar que o problema é RLS
3. Depois, reabilite RLS e configure corretamente

## 📊 Checklist de Diagnóstico

Execute na ordem e me diga onde falha:

- [ ] Execute `DIAGNOSTICO_RLS_COMPLETO.sql`
- [ ] TESTE 1: RLS está habilitado?
- [ ] TESTE 2: Políticas existem?
- [ ] TESTE 3: Permissões GRANT foram dadas?
- [ ] TESTE 4: Role 'anon' existe?
- [ ] TESTE 5: Inserção como 'anon' funciona?
- [ ] TESTE 6: Há políticas duplicadas?
- [ ] TESTE 7: Configurações corretas?
- [ ] TESTE 8: Sem triggers bloqueando?

## 🎯 Próximos Passos

1. **Execute** `DIAGNOSTICO_RLS_COMPLETO.sql`
2. **Me envie** os resultados (screenshot ou texto)
3. **Vou criar** a solução específica para o seu caso

---

**Execute o diagnóstico e me envie os resultados!** 🔍
