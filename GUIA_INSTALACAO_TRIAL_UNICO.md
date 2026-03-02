# 🚀 Guia de Instalação - Teste Gratuito Único

## 📋 Pré-requisitos

- ✅ Projeto já configurado com Supabase
- ✅ Tabelas `subscription_plans` e `user_subscriptions` criadas
- ✅ Acesso ao Supabase Dashboard

---

## 🔧 Passo a Passo

### **1. Executar Migration SQL**

1. Acesse o **Supabase Dashboard**
2. Vá em **SQL Editor**
3. Clique em **New Query**
4. Copie todo o conteúdo do arquivo:
   ```
   supabase/migrations/20251019000000_trial_once_per_user.sql
   ```
5. Cole no editor SQL
6. Clique em **RUN** (ou pressione `Ctrl + Enter`)

**Resultado esperado:**
```
Success. No rows returned
```

---

### **2. Verificar Instalação**

Execute estas queries para confirmar que tudo foi criado:

#### **a) Verificar funções:**
```sql
SELECT proname AS "Função Criada"
FROM pg_proc 
WHERE proname IN ('has_used_trial', 'get_available_plans', 'prevent_multiple_trials')
  AND pronamespace = 'public'::regnamespace;
```

**Resultado esperado:**
```
Função Criada
─────────────────────────
has_used_trial
get_available_plans
prevent_multiple_trials
```

#### **b) Verificar trigger:**
```sql
SELECT 
  trigger_name AS "Trigger",
  event_manipulation AS "Evento",
  event_object_table AS "Tabela"
FROM information_schema.triggers 
WHERE trigger_name = 'prevent_multiple_trials_trigger';
```

**Resultado esperado:**
```
Trigger                          | Evento | Tabela
─────────────────────────────────┼────────┼────────────────────
prevent_multiple_trials_trigger  | INSERT | user_subscriptions
```

---

### **3. Testar Funcionalidade**

#### **a) Verificar se você já usou o trial:**
```sql
SELECT public.has_used_trial(auth.uid()) AS "Já usou trial?";
```

**Resultados possíveis:**
- `false` → Você nunca usou o trial
- `true` → Você já usou o trial

#### **b) Ver planos disponíveis:**
```sql
SELECT 
  name AS "Plano",
  price AS "Preço",
  is_trial AS "É Trial?",
  is_available AS "Disponível?"
FROM public.get_available_plans(auth.uid());
```

**Exemplo de resultado (nunca usou trial):**
```
Plano           | Preço | É Trial? | Disponível?
────────────────┼───────┼──────────┼────────────
Teste Gratuito  | 0.00  | true     | true ✅
Plano Mensal    | 29.90 | false    | true ✅
Plano Anual     | 299.90| false    | true ✅
```

**Exemplo de resultado (já usou trial):**
```
Plano           | Preço | É Trial? | Disponível?
────────────────┼───────┼──────────┼────────────
Teste Gratuito  | 0.00  | true     | false ❌
Plano Mensal    | 29.90 | false    | true ✅
Plano Anual     | 299.90| false    | true ✅
```

---

### **4. Testar Trigger (Opcional)**

Tente inserir uma segunda assinatura trial manualmente:

```sql
-- Primeiro, veja o ID do plano trial
SELECT id FROM subscription_plans WHERE is_trial = true LIMIT 1;

-- Tente inserir (vai falhar se você já usou)
INSERT INTO user_subscriptions (user_id, subscription_plan_id, status, expires_at)
VALUES (
  auth.uid(),
  'ID-DO-PLANO-TRIAL-AQUI',
  'active',
  NOW() + INTERVAL '30 days'
);
```

**Se você já usou o trial, verá este erro:**
```
ERROR: Usuário já utilizou o teste gratuito. Cada conta pode usar o teste apenas uma vez.
```

**Se nunca usou, a inserção funcionará normalmente.** ✅

---

## 🎨 Testar no Frontend

### **1. Acessar página de planos**
```
http://localhost:5173/planos
```

### **2. Verificar visual**

#### **Se NUNCA usou trial:**
- Card do "Teste Gratuito" normal (sem opacidade)
- Botão "Iniciar Teste Gratuito" **habilitado** ✅
- Sem badge "Já Utilizado"

#### **Se JÁ usou trial:**
- Card do "Teste Gratuito" com opacidade 60%
- Badge "Já Utilizado" no topo
- Botão "Já Utilizado" **desabilitado** ❌

### **3. Tentar clicar no trial (se já usou)**

**Resultado esperado:**
```
❌ Você já utilizou o teste gratuito. Cada conta pode usar o teste apenas uma vez.
```

---

## 🔍 Troubleshooting

### **Problema 1: Funções não foram criadas**

**Sintoma:**
```
ERROR: function public.has_used_trial(uuid) does not exist
```

**Solução:**
1. Verifique se a migration foi executada completamente
2. Execute novamente o SQL
3. Verifique se há erros no log

---

### **Problema 2: Trigger não está funcionando**

**Sintoma:** Consegue inserir múltiplas assinaturas trial

**Solução:**
```sql
-- Recriar trigger
DROP TRIGGER IF EXISTS prevent_multiple_trials_trigger ON public.user_subscriptions;

CREATE TRIGGER prevent_multiple_trials_trigger
  BEFORE INSERT ON public.user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_multiple_trials();
```

---

### **Problema 3: Frontend não mostra "Já Utilizado"**

**Sintoma:** Botão continua habilitado mesmo tendo usado trial

**Solução:**
1. Limpar cache do navegador (`Ctrl + Shift + R`)
2. Fazer logout e login novamente
3. Verificar console do navegador para erros
4. Verificar se `getAvailablePlans` está sendo chamado:
   ```javascript
   console.log('Plans:', plans);
   // Deve mostrar is_available: false para trial
   ```

---

### **Problema 4: Erro ao carregar planos**

**Sintoma:**
```
Não foi possível carregar os planos
```

**Solução:**
1. Verificar se as funções RPC existem no Supabase
2. Verificar permissões (RLS) das tabelas
3. Verificar console do navegador para detalhes do erro

---

## ✅ Checklist de Instalação

- [ ] Migration SQL executada com sucesso
- [ ] 3 funções criadas (`has_used_trial`, `get_available_plans`, `prevent_multiple_trials`)
- [ ] 1 trigger criado (`prevent_multiple_trials_trigger`)
- [ ] Teste SQL: `has_used_trial` retorna boolean
- [ ] Teste SQL: `get_available_plans` retorna planos com flag
- [ ] Teste SQL: Trigger bloqueia múltiplos trials
- [ ] Frontend: Página de planos carrega corretamente
- [ ] Frontend: Badge "Já Utilizado" aparece (se aplicável)
- [ ] Frontend: Botão desabilitado (se já usou trial)
- [ ] Frontend: Toast de erro ao tentar usar trial novamente

---

## 📊 Verificação Final

Execute este SQL para ver um resumo completo:

```sql
SELECT 
  '1. Funções' AS "Categoria",
  COUNT(*) AS "Quantidade"
FROM pg_proc 
WHERE proname IN ('has_used_trial', 'get_available_plans', 'prevent_multiple_trials')
  AND pronamespace = 'public'::regnamespace

UNION ALL

SELECT 
  '2. Triggers',
  COUNT(*)
FROM information_schema.triggers 
WHERE trigger_name = 'prevent_multiple_trials_trigger'

UNION ALL

SELECT 
  '3. Planos Trial',
  COUNT(*)
FROM subscription_plans
WHERE is_trial = true

UNION ALL

SELECT 
  '4. Usuários que usaram trial',
  COUNT(DISTINCT us.user_id)
FROM user_subscriptions us
JOIN subscription_plans sp ON us.subscription_plan_id = sp.id
WHERE sp.is_trial = true;
```

**Resultado esperado:**
```
Categoria                      | Quantidade
───────────────────────────────┼───────────
1. Funções                     | 3
2. Triggers                    | 1
3. Planos Trial                | 1
4. Usuários que usaram trial   | X (número de usuários)
```

---

## 🎉 Instalação Completa!

Se todos os checks acima passaram, a funcionalidade está **100% instalada e funcionando**!

### **Próximos Passos:**

1. ✅ Testar com usuários reais
2. ✅ Monitorar logs para erros
3. ✅ Ajustar mensagens se necessário
4. ✅ Documentar para equipe

---

## 📞 Suporte

Se encontrar problemas:

1. Verificar logs do Supabase
2. Verificar console do navegador
3. Consultar `TESTE_GRATUITO_UNICO.md` para detalhes técnicos
4. Verificar se todas as migrations anteriores foram executadas

---

**Data:** 19 de outubro de 2025  
**Versão:** 1.0  
**Status:** ✅ Pronto para produção
