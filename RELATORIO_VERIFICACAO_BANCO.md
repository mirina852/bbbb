# 🔍 Relatório de Verificação do Banco de Dados (via MCP)

**Data:** 12/10/2025  
**Projeto:** vnyrvgtioorpyohfvbim  
**Método:** Supabase MCP

---

## 📊 Resumo Executivo

| Categoria | Status | Problemas |
|-----------|--------|-----------|
| **Segurança** | ⚠️ **CRÍTICO** | 7 erros, 10 avisos |
| **Performance** | ⚠️ **ATENÇÃO** | 6 infos, 45 avisos |
| **Funcionalidade** | ✅ **OK** | Site funciona |

---

## 🚨 PROBLEMAS CRÍTICOS DE SEGURANÇA

### 1. ❌ RLS Desabilitado em Tabelas Públicas (5 tabelas)

**Gravidade:** 🔴 **ERRO CRÍTICO**

Tabelas expostas publicamente **SEM** Row Level Security:

| Tabela | Registros | Risco |
|--------|-----------|-------|
| `produtos` | 0 | 🔴 Alto - Tem políticas mas RLS desabilitado |
| `site_settings` | 1 | 🔴 Alto - Tem políticas mas RLS desabilitado |
| `test_user_id` | 1 | 🔴 Alto - Tabela de teste exposta |
| `v_store_id` | 0 | 🔴 Alto - View exposta |
| `merchant_payment_credentials` | 1 | 🔴 **CRÍTICO** - Credenciais de pagamento expostas! |

**Impacto:**
- ❌ Qualquer pessoa pode acessar dados sensíveis
- ❌ Credenciais de pagamento do Mercado Pago expostas
- ❌ Possível vazamento de dados

**Solução Urgente:**
```sql
-- Habilitar RLS nas tabelas
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchant_payment_credentials ENABLE ROW LEVEL SECURITY;

-- Remover tabelas de teste
DROP TABLE IF EXISTS public.test_user_id;
DROP TABLE IF EXISTS public.v_store_id;
```

---

### 2. ⚠️ Políticas Existem mas RLS Desabilitado (2 tabelas)

**Gravidade:** 🟠 **ERRO**

| Tabela | Políticas | Problema |
|--------|-----------|----------|
| `produtos` | 4 políticas | RLS desabilitado - políticas inúteis |
| `site_settings` | 1 política | RLS desabilitado - política inútil |

**Solução:**
```sql
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
```

---

### 3. ⚠️ Funções sem search_path (8 funções)

**Gravidade:** 🟡 **AVISO**

Funções vulneráveis a ataques de injeção de schema:

- `update_categories_updated_at`
- `get_active_subscription`
- `update_updated_at_column`
- `update_orders_updated_at`
- `get_user_store_id`
- `has_active_subscription`
- `generate_unique_slug`
- `update_produtos_updated_at`

**Solução:**
```sql
-- Exemplo para get_active_subscription
ALTER FUNCTION public.get_active_subscription 
SET search_path = public, pg_temp;
```

---

### 4. ⚠️ Proteção contra Senhas Vazadas Desabilitada

**Gravidade:** 🟡 **AVISO**

O Supabase Auth não está verificando senhas comprometidas contra HaveIBeenPwned.org.

**Solução:**
1. Acesse: Dashboard Supabase → Authentication → Policies
2. Ative: "Leaked Password Protection"

---

### 5. ⚠️ Extensão no Schema Public

**Gravidade:** 🟡 **AVISO**

Extensão `unaccent` instalada no schema `public` (deveria estar em `extensions`).

**Solução:**
```sql
ALTER EXTENSION unaccent SET SCHEMA extensions;
```

---

## ⚡ PROBLEMAS DE PERFORMANCE

### 1. 📊 Foreign Keys sem Índice (6 casos)

**Gravidade:** 🔵 **INFO**

Chaves estrangeiras sem índice podem causar lentidão:

| Tabela | Foreign Key | Impacto |
|--------|-------------|---------|
| `merchant_payment_credentials` | `user_id` | Consultas lentas |
| `products` | `store_id` | Consultas lentas |
| `site_settings` | `user_id` | Consultas lentas |
| `subscription_payments` | `subscription_plan_id` | Consultas lentas |
| `subscription_payments` | `user_id` | Consultas lentas |
| `user_subscriptions` | `subscription_plan_id` | Consultas lentas |

**Solução:**
```sql
-- Criar índices
CREATE INDEX idx_merchant_payment_credentials_user_id 
  ON merchant_payment_credentials(user_id);

CREATE INDEX idx_products_store_id 
  ON products(store_id);

CREATE INDEX idx_site_settings_user_id 
  ON site_settings(user_id);

CREATE INDEX idx_subscription_payments_plan_id 
  ON subscription_payments(subscription_plan_id);

CREATE INDEX idx_subscription_payments_user_id 
  ON subscription_payments(user_id);

CREATE INDEX idx_user_subscriptions_plan_id 
  ON user_subscriptions(subscription_plan_id);
```

---

### 2. ⚠️ Políticas RLS Ineficientes (15 casos)

**Gravidade:** 🟡 **AVISO**

Políticas RLS que re-avaliam `auth.uid()` para cada linha:

**Tabelas afetadas:**
- `categories` (2 políticas)
- `stores` (3 políticas)
- `orders` (1 política)
- `ingredients` (3 políticas)
- `products` (3 políticas)
- `subscription_payments` (2 políticas)
- `user_subscriptions` (1 política)

**Problema:**
```sql
-- LENTO (re-avalia para cada linha)
USING (auth.uid() = owner_id)

-- RÁPIDO (avalia uma vez)
USING ((SELECT auth.uid()) = owner_id)
```

**Solução:**
Adicionar `SELECT` em todas as chamadas `auth.uid()`:
```sql
-- Exemplo
CREATE POLICY "policy_name"
  ON table_name
  FOR SELECT
  USING ((SELECT auth.uid()) = owner_id);  -- ✅ Com SELECT
```

---

### 3. ⚠️ Múltiplas Políticas Permissivas (45 casos!)

**Gravidade:** 🟡 **AVISO**

Muitas tabelas têm políticas duplicadas/redundantes:

**Casos críticos:**
- `stores`: 4 políticas SELECT para `authenticated` (redundante!)
- `orders`: 3 políticas INSERT (redundante!)
- `products`: 3 políticas SELECT (redundante!)

**Impacto:**
- Cada política é executada separadamente
- Performance degradada em escala
- Queries mais lentas

**Solução:**
Consolidar políticas redundantes em uma única política.

---

## ✅ PONTOS POSITIVOS

### Segurança
✅ RLS habilitado em 9 tabelas principais:
- `stores`
- `products`
- `categories`
- `ingredients`
- `orders`
- `order_items`
- `subscription_plans`
- `user_subscriptions`
- `subscription_payments`

### Estrutura
✅ Tabelas bem estruturadas
✅ Foreign keys configuradas
✅ Timestamps automáticos
✅ UUIDs como chaves primárias

### Funcionalidade
✅ Sistema multi-tenant funcionando
✅ Assinaturas funcionando
✅ Pedidos funcionando
✅ Produtos e categorias OK

---

## 🎯 AÇÕES PRIORITÁRIAS

### 🔴 URGENTE (Fazer AGORA)

1. **Habilitar RLS em `merchant_payment_credentials`**
   ```sql
   ALTER TABLE public.merchant_payment_credentials 
   ENABLE ROW LEVEL SECURITY;
   
   CREATE POLICY "Users manage own credentials"
     ON merchant_payment_credentials
     FOR ALL
     TO authenticated
     USING ((SELECT auth.uid()) = user_id)
     WITH CHECK ((SELECT auth.uid()) = user_id);
   ```

2. **Remover tabelas de teste**
   ```sql
   DROP TABLE IF EXISTS public.test_user_id;
   DROP TABLE IF EXISTS public.v_store_id;
   ```

3. **Habilitar RLS em `produtos` e `site_settings`**
   ```sql
   ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
   ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
   ```

---

### 🟠 IMPORTANTE (Fazer esta semana)

4. **Criar índices para Foreign Keys**
   - Executar SQL da seção "Foreign Keys sem Índice"

5. **Otimizar políticas RLS**
   - Adicionar `SELECT` em `auth.uid()`
   - Consolidar políticas redundantes

6. **Configurar search_path nas funções**
   - Proteger contra injeção de schema

---

### 🟡 RECOMENDADO (Fazer quando possível)

7. **Ativar proteção contra senhas vazadas**
   - Dashboard → Authentication → Policies

8. **Mover extensão unaccent**
   - Do schema `public` para `extensions`

9. **Limpar políticas duplicadas**
   - Consolidar políticas redundantes

---

## 📋 SQL COMPLETO DE CORREÇÃO

```sql
-- ============================================
-- 🔴 CORREÇÕES URGENTES
-- ============================================

-- 1. Habilitar RLS em tabelas críticas
ALTER TABLE public.merchant_payment_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

-- 2. Criar política para merchant_payment_credentials
CREATE POLICY "Users manage own credentials"
  ON public.merchant_payment_credentials
  FOR ALL
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- 3. Remover tabelas de teste
DROP TABLE IF EXISTS public.test_user_id;
DROP TABLE IF EXISTS public.v_store_id;

-- ============================================
-- 🟠 MELHORIAS DE PERFORMANCE
-- ============================================

-- 4. Criar índices para Foreign Keys
CREATE INDEX IF NOT EXISTS idx_merchant_payment_credentials_user_id 
  ON public.merchant_payment_credentials(user_id);

CREATE INDEX IF NOT EXISTS idx_products_store_id 
  ON public.products(store_id);

CREATE INDEX IF NOT EXISTS idx_site_settings_user_id 
  ON public.site_settings(user_id);

CREATE INDEX IF NOT EXISTS idx_subscription_payments_plan_id 
  ON public.subscription_payments(subscription_plan_id);

CREATE INDEX IF NOT EXISTS idx_subscription_payments_user_id 
  ON public.subscription_payments(user_id);

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_plan_id 
  ON public.user_subscriptions(subscription_plan_id);

-- 5. Configurar search_path nas funções
ALTER FUNCTION public.get_active_subscription 
  SET search_path = public, pg_temp;

ALTER FUNCTION public.has_active_subscription 
  SET search_path = public, pg_temp;

ALTER FUNCTION public.get_user_store_id 
  SET search_path = public, pg_temp;

ALTER FUNCTION public.generate_unique_slug 
  SET search_path = public, pg_temp;

ALTER FUNCTION public.update_updated_at_column 
  SET search_path = public, pg_temp;

ALTER FUNCTION public.update_categories_updated_at 
  SET search_path = public, pg_temp;

ALTER FUNCTION public.update_orders_updated_at 
  SET search_path = public, pg_temp;

ALTER FUNCTION public.update_produtos_updated_at 
  SET search_path = public, pg_temp;

-- ============================================
-- ✅ VERIFICAÇÃO
-- ============================================

-- Verificar RLS habilitado
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Verificar índices criados
SELECT 
  tablename,
  indexname
FROM pg_indexes
WHERE schemaname = 'public'
AND indexname LIKE 'idx_%'
ORDER BY tablename;
```

---

## 🎯 CONCLUSÃO

### Status Geral: ⚠️ **FUNCIONA MAS PRECISA DE CORREÇÕES**

**O site está funcionando**, mas há **problemas críticos de segurança** que precisam ser corrigidos:

✅ **Funcionalidade:** OK  
⚠️ **Segurança:** CRÍTICO (credenciais expostas)  
⚠️ **Performance:** Pode melhorar  

### Prioridades:
1. 🔴 **URGENTE:** Proteger `merchant_payment_credentials`
2. 🔴 **URGENTE:** Remover tabelas de teste
3. 🟠 **IMPORTANTE:** Criar índices
4. 🟡 **RECOMENDADO:** Otimizar políticas RLS

---

## 📚 Documentação

- [Supabase RLS](https://supabase.com/docs/guides/auth/row-level-security)
- [Database Linter](https://supabase.com/docs/guides/database/database-linter)
- [Performance Tips](https://supabase.com/docs/guides/database/postgres/row-level-security#call-functions-with-select)

---

**Relatório gerado via MCP em 12/10/2025** 🔍
