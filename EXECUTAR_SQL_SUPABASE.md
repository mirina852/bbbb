# 🚀 Como Executar SQL no Supabase

## 📋 Método 1: Supabase Dashboard (RECOMENDADO)

### **Passo 1: Acessar Supabase**

1. Acesse: [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Faça login com sua conta
3. Selecione seu projeto

### **Passo 2: Abrir SQL Editor**

1. No menu lateral esquerdo, clique em **"SQL Editor"**
2. Clique no botão **"+ New query"** (ou "New query")

### **Passo 3: Copiar o SQL**

1. Abra o arquivo: `SETUP_COMPLETO_ASSINATURAS.sql`
2. Selecione TODO o conteúdo (`Ctrl + A`)
3. Copie (`Ctrl + C`)

### **Passo 4: Colar e Executar**

1. Cole no SQL Editor do Supabase (`Ctrl + V`)
2. Clique no botão **"RUN"** (ou pressione `Ctrl + Enter`)
3. Aguarde a execução (10-30 segundos)

### **Passo 5: Verificar Sucesso**

Você deve ver esta mensagem:

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
```

---

## 📋 Método 2: Supabase CLI (Avançado)

### **Pré-requisitos**
```bash
# Instalar Supabase CLI
npm install -g supabase

# Fazer login
supabase login
```

### **Executar SQL**
```bash
# Navegar até a pasta do projeto
cd d:\petisco-saas-app-11-main

# Executar SQL
supabase db execute -f SETUP_COMPLETO_ASSINATURAS.sql --project-ref SEU_PROJECT_REF
```

---

## 📋 Método 3: Copiar e Colar Direto

Se preferir, aqui está o SQL completo para copiar:

### **📄 Conteúdo do SETUP_COMPLETO_ASSINATURAS.sql**

```sql
-- Copie daqui para baixo ↓
```

**(Abra o arquivo SETUP_COMPLETO_ASSINATURAS.sql e copie todo o conteúdo)**

---

## ✅ Verificação Após Execução

Execute estas queries para confirmar:

### **1. Ver planos criados**
```sql
SELECT 
  name AS "Plano",
  price AS "Preço",
  duration_days AS "Duração",
  is_trial AS "Trial?"
FROM subscription_plans 
ORDER BY price;
```

### **2. Ver funções criadas**
```sql
SELECT proname AS "Função"
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

### **3. Ver tabelas criadas**
```sql
SELECT table_name AS "Tabela"
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
  'subscription_plans',
  'user_subscriptions',
  'subscription_payments'
);
```

---

## 🎯 Resultado Esperado

### **Tabelas (3)**
- ✅ subscription_plans
- ✅ user_subscriptions
- ✅ subscription_payments

### **Funções (5)**
- ✅ get_active_subscription
- ✅ has_active_subscription
- ✅ has_used_trial
- ✅ get_available_plans
- ✅ prevent_multiple_trials

### **Planos (3)**
- ✅ Teste Gratuito (R$ 0,00)
- ✅ Plano Mensal (R$ 29,90)
- ✅ Plano Anual (R$ 299,90)

---

## 🐛 Problemas Comuns

### **Erro: "relation already exists"**

**Solução:** As tabelas já existem. Delete antes:

```sql
DROP TABLE IF EXISTS public.subscription_payments CASCADE;
DROP TABLE IF EXISTS public.user_subscriptions CASCADE;
DROP TABLE IF EXISTS public.subscription_plans CASCADE;
```

Depois execute o `SETUP_COMPLETO_ASSINATURAS.sql` novamente.

---

### **Erro: "permission denied"**

**Solução:** Você precisa ser admin do projeto Supabase.

1. Verificar se está logado no projeto correto
2. Verificar se tem permissões de admin

---

### **Erro: "syntax error"**

**Solução:** Certifique-se de copiar TODO o arquivo, do início ao fim.

---

## 📞 Suporte

Se tiver problemas:

1. Verificar logs do Supabase
2. Copiar mensagem de erro completa
3. Consultar `GUIA_INSTALACAO_COMPLETA.md`

---

## 🎉 Pronto!

Após executar com sucesso, teste no frontend:

```
http://localhost:5173/planos
```

Você deve ver os 3 planos disponíveis!

---

**Data:** 19 de outubro de 2025  
**Método Recomendado:** Supabase Dashboard  
**Tempo:** 5 minutos
