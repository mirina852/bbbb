# 🚀 Guia de Instalação Completa - Sistema de Assinaturas

## 📋 O Que Será Instalado

Este guia configura **TUDO** necessário para o sistema de assinaturas funcionar:

- ✅ 3 Tabelas (planos, assinaturas, pagamentos)
- ✅ 5 Funções RPC (buscar assinatura, verificar trial, etc.)
- ✅ 1 Trigger (prevenir múltiplos trials)
- ✅ Políticas de Segurança (RLS)
- ✅ 3 Planos pré-configurados (Trial, Mensal, Anual)

---

## ⏱️ Tempo Estimado

- **5 minutos** para instalação completa
- **2 minutos** para testes

---

## 🔧 Pré-requisitos

- ✅ Conta no Supabase
- ✅ Projeto criado no Supabase
- ✅ Acesso ao Supabase Dashboard

---

## 📝 Passo a Passo

### **Passo 1: Acessar Supabase Dashboard**

1. Acesse [https://supabase.com](https://supabase.com)
2. Faça login
3. Selecione seu projeto

---

### **Passo 2: Abrir SQL Editor**

1. No menu lateral, clique em **SQL Editor**
2. Clique em **New Query** (ou `+ New query`)

![SQL Editor](https://via.placeholder.com/800x400?text=SQL+Editor)

---

### **Passo 3: Copiar e Colar o SQL**

1. Abra o arquivo:
   ```
   SETUP_COMPLETO_ASSINATURAS.sql
   ```

2. **Copie TODO o conteúdo** do arquivo (`Ctrl + A`, `Ctrl + C`)

3. **Cole no SQL Editor** do Supabase (`Ctrl + V`)

---

### **Passo 4: Executar o SQL**

1. Clique no botão **RUN** (ou pressione `Ctrl + Enter`)
2. Aguarde a execução (pode levar 10-30 segundos)

**Resultado esperado:**

```
Success. No rows returned

NOTICE:  
NOTICE:  ============================================
NOTICE:  VERIFICAÇÃO FINAL - SISTEMA DE ASSINATURAS
NOTICE:  ============================================
NOTICE:  
NOTICE:  ✅ Tabelas criadas: 3 de 3
NOTICE:  ✅ Funções RPC criadas: 5 de 5
NOTICE:  ✅ Triggers criados: 1 de 1
NOTICE:  ✅ Planos inseridos: 3 de 3
NOTICE:  
NOTICE:  🎉 SUCESSO! Sistema de assinaturas configurado completamente!
NOTICE:  
NOTICE:  Próximos passos:
NOTICE:  1. Testar no frontend acessando /planos
NOTICE:  2. Verificar se planos aparecem corretamente
NOTICE:  3. Testar ativação de teste gratuito
NOTICE:  
NOTICE:  ============================================
```

---

### **Passo 5: Verificar Instalação**

Execute estas queries para confirmar:

#### **a) Ver planos criados:**
```sql
SELECT 
  name AS "Plano",
  price AS "Preço",
  duration_days AS "Duração (dias)",
  is_trial AS "É Trial?"
FROM subscription_plans 
ORDER BY price;
```

**Resultado esperado:**
```
Plano           | Preço  | Duração (dias) | É Trial?
────────────────┼────────┼────────────────┼─────────
Teste Gratuito  | 0.00   | 30             | true
Plano Mensal    | 29.90  | 30             | false
Plano Anual     | 299.90 | 365            | false
```

#### **b) Verificar funções:**
```sql
SELECT proname AS "Função Criada"
FROM pg_proc 
WHERE proname IN (
  'get_active_subscription', 
  'has_active_subscription', 
  'has_used_trial', 
  'get_available_plans', 
  'prevent_multiple_trials'
)
AND pronamespace = 'public'::regnamespace;
```

**Resultado esperado:** 5 linhas

#### **c) Verificar trigger:**
```sql
SELECT trigger_name, event_object_table
FROM information_schema.triggers 
WHERE trigger_name = 'prevent_multiple_trials_trigger';
```

**Resultado esperado:** 1 linha

---

## 🎨 Testar no Frontend

### **Passo 1: Acessar página de planos**

```
http://localhost:5173/planos
```

ou

```
https://seu-dominio.com/planos
```

### **Passo 2: Verificar visual**

Você deve ver **3 planos**:

```
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│  Teste Gratuito     │  │  Plano Mensal       │  │  Plano Anual        │
│  R$ 0,00 / mês      │  │  R$ 29,90 / mês     │  │  R$ 299,90 / ano    │
│                     │  │  [Mais Popular]     │  │                     │
│  [Iniciar Teste]    │  │  [Selecionar]       │  │  [Selecionar]       │
└─────────────────────┘  └─────────────────────┘  └─────────────────────┘
```

### **Passo 3: Testar ativação de teste gratuito**

1. Clique em **"Iniciar Teste Gratuito"**
2. Deve ativar instantaneamente
3. Deve redirecionar para `/admin`
4. Deve mostrar toast: **"Plano ativado com sucesso! Bem-vindo!"**

### **Passo 4: Verificar assinatura ativa**

1. Acesse `/admin/subscription`
2. Deve mostrar:
   - ✅ Card verde "Ativa"
   - ✅ Dias restantes: 30
   - ✅ Barra de progresso: 100%
   - ✅ Data de expiração

---

## 🧪 Testes Avançados

### **Teste 1: Verificar se trial está ativo**

```sql
SELECT * FROM public.get_active_subscription(auth.uid());
```

**Resultado esperado:**
```
plan_name       | status | days_remaining
────────────────┼────────┼───────────────
Teste Gratuito  | active | 30
```

### **Teste 2: Verificar se já usou trial**

```sql
SELECT public.has_used_trial(auth.uid()) AS "Já usou trial?";
```

**Resultado esperado:**
```
Já usou trial?
──────────────
true
```

### **Teste 3: Ver planos disponíveis**

```sql
SELECT 
  name AS "Plano",
  price AS "Preço",
  is_available AS "Disponível?"
FROM public.get_available_plans(auth.uid());
```

**Resultado esperado (após usar trial):**
```
Plano           | Preço  | Disponível?
────────────────┼────────┼────────────
Teste Gratuito  | 0.00   | false ❌
Plano Mensal    | 29.90  | true ✅
Plano Anual     | 299.90 | true ✅
```

### **Teste 4: Tentar ativar trial novamente**

1. Acesse `/planos`
2. Teste Gratuito deve mostrar:
   - Badge "Já Utilizado"
   - Botão desabilitado
   - Card com opacidade 60%
3. Ao clicar, deve mostrar erro:
   - "Você já utilizou o teste gratuito..."

---

## 🔍 Troubleshooting

### **Problema 1: Erro ao executar SQL**

**Sintoma:**
```
ERROR: relation "subscription_plans" already exists
```

**Solução:**
As tabelas já existem. Você pode:
1. Deletar as tabelas antigas manualmente
2. Ou pular a criação de tabelas

**SQL para deletar:**
```sql
DROP TABLE IF EXISTS public.subscription_payments CASCADE;
DROP TABLE IF EXISTS public.user_subscriptions CASCADE;
DROP TABLE IF EXISTS public.subscription_plans CASCADE;
```

Depois execute o `SETUP_COMPLETO_ASSINATURAS.sql` novamente.

---

### **Problema 2: Planos não aparecem no frontend**

**Possíveis causas:**

1. **RLS bloqueando acesso**
   ```sql
   -- Verificar se você consegue ver os planos
   SELECT * FROM subscription_plans;
   ```
   
   Se retornar vazio, execute:
   ```sql
   -- Recriar policy
   DROP POLICY IF EXISTS "Anyone can view subscription plans" ON public.subscription_plans;
   CREATE POLICY "Anyone can view subscription plans"
     ON public.subscription_plans
     FOR SELECT
     USING (is_active = true);
   ```

2. **Supabase URL/Key incorretos**
   - Verificar arquivo `.env` ou configuração do Supabase
   - Verificar console do navegador (F12) para erros

---

### **Problema 3: Erro "Não foi possível carregar os planos"**

**Solução:**
1. Limpar cache do navegador (`Ctrl + Shift + R`)
2. Verificar console do navegador (F12)
3. Verificar se Supabase está online
4. Consultar `SOLUCAO_ERRO_PLANOS.md`

---

### **Problema 4: Trial não ativa**

**Sintoma:** Clica em "Iniciar Teste Gratuito" mas nada acontece

**Solução:**
1. Verificar console do navegador (F12)
2. Verificar se está logado
3. Executar no SQL:
   ```sql
   -- Ver se há alguma assinatura
   SELECT * FROM user_subscriptions WHERE user_id = auth.uid();
   ```

---

## ✅ Checklist de Instalação

- [ ] SQL executado com sucesso
- [ ] Mensagem "🎉 SUCESSO!" apareceu
- [ ] 3 planos criados
- [ ] 5 funções criadas
- [ ] 1 trigger criado
- [ ] Frontend mostra 3 planos
- [ ] Teste gratuito ativa corretamente
- [ ] Assinatura aparece em `/admin/subscription`
- [ ] Badge "Já Utilizado" aparece após usar trial

---

## 📊 O Que Foi Instalado

### **Tabelas:**
1. `subscription_plans` - Planos disponíveis
2. `user_subscriptions` - Assinaturas dos usuários
3. `subscription_payments` - Pagamentos

### **Funções RPC:**
1. `get_active_subscription` - Busca assinatura ativa
2. `has_active_subscription` - Verifica se tem assinatura
3. `has_used_trial` - Verifica se já usou trial
4. `get_available_plans` - Lista planos com disponibilidade
5. `prevent_multiple_trials` - Trigger para bloquear múltiplos trials

### **Planos:**
1. **Teste Gratuito** - R$ 0,00 / 30 dias
2. **Plano Mensal** - R$ 29,90 / 30 dias
3. **Plano Anual** - R$ 299,90 / 365 dias

---

## 🎯 Próximos Passos

Após instalação bem-sucedida:

1. ✅ Personalizar valores dos planos (se necessário)
2. ✅ Configurar integração de pagamento (PIX, cartão, etc.)
3. ✅ Testar fluxo completo de assinatura
4. ✅ Configurar emails de notificação
5. ✅ Monitorar assinaturas no dashboard

---

## 📚 Documentação Adicional

- **FLUXO_STATUS_ASSINATURA.md** - Como funciona o sistema de status
- **TESTE_GRATUITO_UNICO.md** - Detalhes da proteção de trial
- **CORRECAO_BUG_ASSINATURA.md** - Bugs corrigidos
- **SOLUCAO_ERRO_PLANOS.md** - Solução de erros comuns

---

## 📞 Suporte

Se encontrar problemas:

1. Verificar logs do Supabase
2. Verificar console do navegador (F12)
3. Consultar documentação adicional
4. Verificar se todas as etapas foram seguidas

---

## 🎉 Instalação Completa!

Se todos os checks passaram, o sistema está **100% funcional**!

**Aproveite seu sistema de assinaturas!** 🚀

---

**Data:** 19 de outubro de 2025  
**Versão:** 2.0  
**Status:** ✅ Pronto para produção
