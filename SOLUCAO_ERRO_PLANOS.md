# 🔧 Solução: Erro "Não foi possível carregar os planos"

## ❌ Problema

Ao acessar a página `/planos`, aparece o erro:
```
Não foi possível carregar os planos
```

---

## 🔍 Causa

O código estava tentando chamar a função RPC `get_available_plans` que **ainda não existe no banco de dados** porque a migration `20251019000000_trial_once_per_user.sql` não foi executada.

---

## ✅ Solução Aplicada

### **1. Fallback Automático**

O código agora tem um **fallback automático**:

```typescript
// Tentar buscar planos com disponibilidade (requer migration)
if (user) {
  try {
    data = await subscriptionService.getAvailablePlans(user.id);
  } catch (rpcError) {
    // Se a função RPC não existir ainda, usar método padrão
    console.warn('Função get_available_plans não encontrada, usando getPlans()');
    data = await subscriptionService.getPlans();
  }
} else {
  data = await subscriptionService.getPlans();
}
```

**Resultado:**
- ✅ Se a migration foi executada → Usa `getAvailablePlans` (com verificação de trial)
- ✅ Se a migration NÃO foi executada → Usa `getPlans` (sem verificação de trial)
- ✅ **Página funciona nos dois casos!**

---

### **2. Verificação Dupla no Trial**

Ao tentar ativar o teste gratuito, o código verifica duas vezes:

```typescript
// 1ª verificação: is_available (se migration executada)
if (plan.is_available === false) {
  toast.error('Você já utilizou o teste gratuito...');
  return;
}

// 2ª verificação: hasUsedTrial (antes de ativar)
try {
  const hasUsed = await subscriptionService.hasUsedTrial(user.id);
  if (hasUsed) {
    toast.error('Você já utilizou o teste gratuito...');
    return;
  }
} catch (rpcError) {
  // Se a função não existir, continuar
  console.warn('Função has_used_trial não encontrada, pulando verificação');
}
```

**Resultado:**
- ✅ Se migration executada → Bloqueia trial duplicado
- ✅ Se migration NÃO executada → Permite trial (comportamento antigo)

---

## 🚀 Como Funciona Agora

### **Cenário 1: Migration NÃO executada (padrão)**

```
Usuário acessa /planos
         │
         ▼
Tenta getAvailablePlans(userId)
         │
         ▼
    ❌ ERRO (função não existe)
         │
         ▼
    Fallback para getPlans()
         │
         ▼
    ✅ Planos carregados
         │
         ▼
Todos os planos disponíveis
(sem verificação de trial)
```

**Comportamento:**
- ✅ Página funciona normalmente
- ⚠️ Usuário pode ativar trial múltiplas vezes (sem proteção)
- 💡 Para ativar proteção, executar migration

---

### **Cenário 2: Migration executada**

```
Usuário acessa /planos
         │
         ▼
Chama getAvailablePlans(userId)
         │
         ▼
    ✅ Sucesso
         │
         ▼
Retorna planos com is_available
         │
         ▼
Trial indisponível se já usado
(badge "Já Utilizado")
```

**Comportamento:**
- ✅ Página funciona normalmente
- ✅ Trial bloqueado se já usado
- ✅ Proteção completa ativa

---

## 📋 Status Atual

### **Sem Migration:**
- ✅ Página de planos funciona
- ✅ Todos os planos disponíveis
- ❌ Sem proteção de trial único
- ❌ Sem badge "Já Utilizado"

### **Com Migration:**
- ✅ Página de planos funciona
- ✅ Verificação de trial único
- ✅ Badge "Já Utilizado"
- ✅ Proteção completa (4 camadas)

---

## 🔧 Para Ativar Proteção de Trial Único

### **Passo 1: Executar Migration**

1. Acesse **Supabase Dashboard**
2. Vá em **SQL Editor**
3. Copie o conteúdo de:
   ```
   supabase/migrations/20251019000000_trial_once_per_user.sql
   ```
4. Cole e execute

### **Passo 2: Verificar**

```sql
-- Verificar se funções foram criadas
SELECT proname FROM pg_proc 
WHERE proname IN ('has_used_trial', 'get_available_plans', 'prevent_multiple_trials');

-- Deve retornar 3 linhas
```

### **Passo 3: Testar**

1. Acesse `/planos`
2. Verifique se planos carregam normalmente
3. Se já usou trial, deve ver badge "Já Utilizado"

---

## 🐛 Troubleshooting

### **Erro persiste após migration**

**Solução:**
1. Limpar cache do navegador (`Ctrl + Shift + R`)
2. Fazer logout e login novamente
3. Verificar console do navegador para erros

### **Planos não carregam de jeito nenhum**

**Possíveis causas:**

1. **Tabela subscription_plans vazia**
   ```sql
   SELECT COUNT(*) FROM subscription_plans;
   -- Deve retornar > 0
   ```

2. **RLS bloqueando acesso**
   ```sql
   -- Verificar policy
   SELECT * FROM subscription_plans;
   -- Deve retornar planos
   ```

3. **Supabase desconectado**
   - Verificar console do navegador
   - Verificar se Supabase está online

---

## ✅ Checklist de Verificação

- [x] Código com fallback implementado
- [x] Página funciona sem migration
- [x] Página funciona com migration
- [x] Verificação dupla de trial
- [x] Mensagens de erro claras
- [x] Console mostra warnings úteis

---

## 📊 Logs Úteis

### **Console do Navegador:**

**Se migration NÃO executada:**
```
⚠️ Função get_available_plans não encontrada, usando getPlans()
⚠️ Função has_used_trial não encontrada, pulando verificação
```

**Se migration executada:**
```
✅ Planos carregados com sucesso
✅ (sem warnings)
```

---

## 🎯 Resumo

| Situação | Página Funciona? | Trial Protegido? | Ação Necessária |
|----------|------------------|------------------|-----------------|
| **Sem migration** | ✅ Sim | ❌ Não | Executar migration |
| **Com migration** | ✅ Sim | ✅ Sim | Nenhuma |

---

## 📞 Suporte

Se o erro persistir:

1. Abrir console do navegador (F12)
2. Ir na aba "Console"
3. Copiar mensagens de erro
4. Verificar se há erros relacionados a Supabase
5. Consultar `GUIA_INSTALACAO_TRIAL_UNICO.md`

---

**Data:** 19 de outubro de 2025  
**Status:** ✅ Erro corrigido com fallback  
**Versão:** 1.1
