# 📦 Sistema de Assinaturas - Documentação Completa

## 🎯 Visão Geral

Sistema completo de assinaturas com:
- ✅ Teste Gratuito (30 dias)
- ✅ Planos Mensais e Anuais
- ✅ Proteção contra múltiplos trials
- ✅ Controle de acesso por assinatura
- ✅ 4 camadas de segurança
- ✅ Dashboard de status

---

## 🚀 Instalação Rápida

### **1 arquivo SQL = Sistema completo**

```bash
1. Abrir: SETUP_COMPLETO_ASSINATURAS.sql
2. Copiar TODO o conteúdo
3. Colar no Supabase SQL Editor
4. Executar (RUN)
5. Pronto! ✅
```

**Tempo:** 5 minutos

**Guia detalhado:** `GUIA_INSTALACAO_COMPLETA.md`

---

## 📁 Arquivos Principais

### **🔧 Instalação**
- `SETUP_COMPLETO_ASSINATURAS.sql` - **SQL completo para instalação**
- `GUIA_INSTALACAO_COMPLETA.md` - Guia passo a passo

### **📚 Documentação Técnica**
- `FLUXO_STATUS_ASSINATURA.md` - Como funciona o sistema de status
- `DIAGRAMA_VISUAL_STATUS.md` - Diagramas visuais dos estados
- `TESTE_GRATUITO_UNICO.md` - Proteção de trial único (400+ linhas)

### **🐛 Correções e Soluções**
- `CORRECAO_BUG_ASSINATURA.md` - Bugs corrigidos
- `SOLUCAO_ERRO_PLANOS.md` - Solução de erros comuns
- `RESUMO_CORRECOES.md` - Resumo executivo

### **🎓 Guias Específicos**
- `GUIA_INSTALACAO_TRIAL_UNICO.md` - Instalação da proteção de trial

---

## 🎨 Funcionalidades

### **1. Gestão de Planos**
- 3 planos pré-configurados (Trial, Mensal, Anual)
- Preços personalizáveis
- Recursos por plano (features)
- Ativação/desativação de planos

### **2. Teste Gratuito Único**
- Cada usuário pode usar **apenas 1 vez**
- 4 camadas de proteção:
  1. **UX** - Badge "Já Utilizado" + botão desabilitado
  2. **Validação Frontend** - Verifica antes de processar
  3. **RPC Backend** - Função `has_used_trial`
  4. **Trigger Banco** - Bloqueia INSERT duplicado

### **3. Controle de Acesso**
- Rotas protegidas por assinatura
- Verificação de dias restantes
- Redirecionamento automático
- Bloqueio ao expirar

### **4. Status da Assinatura**
- **Ativa** (> 7 dias) - Verde
- **Expirando** (≤ 7 dias) - Laranja
- **Expirada** (0 dias) - Vermelho
- **Sem assinatura** - Bloqueado

---

## 🔄 Fluxo do Usuário

```
1. Novo Usuário
   └─> Acessa /planos
       └─> Vê 3 planos
           └─> Clica "Iniciar Teste Gratuito"
               └─> Ativa instantaneamente
                   └─> Redireciona para /admin
                       └─> Usa por 30 dias

2. Trial Expira
   └─> Acesso bloqueado
       └─> Redireciona para /admin/subscription
           └─> Vê status "Expirada"
               └─> Clica "Renovar Assinatura"
                   └─> Acessa /planos
                       └─> Trial mostra "Já Utilizado" ❌
                           └─> Escolhe plano pago
                               └─> Paga e acesso liberado

3. Assinatura Ativa
   └─> Acesso completo ao sistema
       └─> Dashboard mostra dias restantes
           └─> Alerta quando faltam 7 dias
               └─> Pode renovar antes de expirar
```

---

## 📊 Estrutura do Banco de Dados

### **Tabelas**

```sql
subscription_plans
├─ id (UUID)
├─ name (TEXT)
├─ slug (TEXT)
├─ price (DECIMAL)
├─ duration_days (INTEGER)
├─ is_trial (BOOLEAN)
├─ features (JSONB)
└─ is_active (BOOLEAN)

user_subscriptions
├─ id (UUID)
├─ user_id (UUID) → auth.users
├─ subscription_plan_id (UUID) → subscription_plans
├─ status (TEXT) → 'active' | 'expired' | 'cancelled'
├─ expires_at (TIMESTAMP)
└─ created_at (TIMESTAMP)

subscription_payments
├─ id (UUID)
├─ user_id (UUID)
├─ subscription_plan_id (UUID)
├─ amount (DECIMAL)
├─ status (TEXT) → 'pending' | 'approved' | 'expired' | 'cancelled'
├─ payment_method (TEXT)
└─ payment_id (TEXT)
```

### **Funções RPC**

```sql
get_active_subscription(user_id)
├─ Retorna assinatura ativa
├─ Calcula days_remaining
└─ Inclui created_at real

has_active_subscription(user_id)
└─ Retorna boolean

has_used_trial(user_id)
└─ Verifica se já usou trial

get_available_plans(user_id)
├─ Lista todos os planos
└─ Marca trial como indisponível se já usado

prevent_multiple_trials()
└─ Trigger que bloqueia múltiplos trials
```

---

## 🛡️ Segurança

### **Row Level Security (RLS)**

```sql
subscription_plans
└─ Todos podem ver planos ativos

user_subscriptions
├─ Usuários veem apenas suas assinaturas
├─ Usuários inserem apenas suas assinaturas
└─ Usuários atualizam apenas suas assinaturas

subscription_payments
├─ Usuários veem apenas seus pagamentos
└─ Usuários inserem apenas seus pagamentos
```

### **Proteção de Trial**

1. **Frontend:** Badge + botão desabilitado
2. **Validação:** Verifica `is_available`
3. **RPC:** Função `has_used_trial`
4. **Trigger:** Bloqueia INSERT no banco

---

## 🎯 Casos de Uso

### **Caso 1: Novo Usuário**
```typescript
// Frontend detecta que usuário não tem assinatura
if (!subscription) {
  // Redireciona para /admin/subscription
  // Mostra card "Assinatura Necessária"
  // Botão "Ver Planos e Ativar Agora"
}
```

### **Caso 2: Trial Ativo**
```typescript
// Frontend verifica status
if (subscription.status === 'active' && subscription.days_remaining > 7) {
  // Badge verde "Ativa"
  // Acesso completo ao sistema
}
```

### **Caso 3: Expirando em Breve**
```typescript
if (subscription.days_remaining <= 7 && subscription.days_remaining > 0) {
  // Badge laranja "Expirando em Breve"
  // Botão "Renovar Assinatura"
  // Alerta visual
}
```

### **Caso 4: Expirada**
```typescript
if (subscription.status === 'expired' || subscription.days_remaining === 0) {
  // Badge vermelho "Expirada"
  // Acesso bloqueado
  // Redireciona para renovação
}
```

---

## 🧪 Testes

### **Teste 1: Instalação**
```sql
-- Ver planos
SELECT * FROM subscription_plans ORDER BY price;

-- Ver funções
SELECT proname FROM pg_proc 
WHERE proname IN ('get_active_subscription', 'has_used_trial');
```

### **Teste 2: Ativar Trial**
```
1. Acessar /planos
2. Clicar "Iniciar Teste Gratuito"
3. Verificar redirecionamento para /admin
4. Verificar toast de sucesso
```

### **Teste 3: Verificar Status**
```sql
-- Ver assinatura ativa
SELECT * FROM get_active_subscription(auth.uid());

-- Verificar se já usou trial
SELECT has_used_trial(auth.uid());
```

### **Teste 4: Tentar Trial Novamente**
```
1. Acessar /planos
2. Verificar badge "Já Utilizado"
3. Verificar botão desabilitado
4. Tentar clicar (deve mostrar erro)
```

---

## 📈 Monitoramento

### **Queries Úteis**

```sql
-- Total de assinaturas ativas
SELECT COUNT(*) FROM user_subscriptions WHERE status = 'active';

-- Assinaturas expirando em 7 dias
SELECT COUNT(*) FROM user_subscriptions 
WHERE status = 'active' 
AND expires_at <= NOW() + INTERVAL '7 days';

-- Usuários que usaram trial
SELECT COUNT(DISTINCT us.user_id)
FROM user_subscriptions us
JOIN subscription_plans sp ON us.subscription_plan_id = sp.id
WHERE sp.is_trial = true;

-- Receita mensal (estimada)
SELECT SUM(sp.price) as receita_mensal
FROM user_subscriptions us
JOIN subscription_plans sp ON us.subscription_plan_id = sp.id
WHERE us.status = 'active' AND sp.duration_days = 30;
```

---

## 🔧 Personalização

### **Alterar Preços**
```sql
UPDATE subscription_plans 
SET price = 39.90 
WHERE slug = 'monthly';
```

### **Alterar Duração do Trial**
```sql
UPDATE subscription_plans 
SET duration_days = 7 
WHERE slug = 'trial';
```

### **Adicionar Novo Plano**
```sql
INSERT INTO subscription_plans (name, slug, price, duration_days, features)
VALUES (
  'Plano Trimestral',
  'quarterly',
  79.90,
  90,
  '["Acesso completo", "Suporte prioritário"]'::jsonb
);
```

---

## 📞 Suporte

### **Problemas Comuns**

1. **Planos não carregam**
   - Consultar: `SOLUCAO_ERRO_PLANOS.md`

2. **Trial não ativa**
   - Verificar console do navegador
   - Verificar se está logado

3. **Acesso não bloqueia ao expirar**
   - Consultar: `CORRECAO_BUG_ASSINATURA.md`

4. **Badge "Já Utilizado" não aparece**
   - Verificar se migration foi executada
   - Limpar cache do navegador

---

## 📚 Documentação Completa

| Arquivo | Descrição | Linhas |
|---------|-----------|--------|
| `SETUP_COMPLETO_ASSINATURAS.sql` | SQL de instalação | 500+ |
| `GUIA_INSTALACAO_COMPLETA.md` | Guia passo a passo | 400+ |
| `FLUXO_STATUS_ASSINATURA.md` | Documentação técnica | 350+ |
| `TESTE_GRATUITO_UNICO.md` | Proteção de trial | 400+ |
| `DIAGRAMA_VISUAL_STATUS.md` | Diagramas visuais | 300+ |
| `CORRECAO_BUG_ASSINATURA.md` | Bugs corrigidos | 350+ |
| `SOLUCAO_ERRO_PLANOS.md` | Solução de erros | 250+ |
| `RESUMO_CORRECOES.md` | Resumo executivo | 250+ |

**Total:** 2.800+ linhas de documentação

---

## ✅ Checklist de Produção

- [ ] SQL executado com sucesso
- [ ] 3 planos criados
- [ ] 5 funções RPC criadas
- [ ] 1 trigger criado
- [ ] Frontend testado
- [ ] Trial único funcionando
- [ ] Acesso bloqueado ao expirar
- [ ] Renovação funcionando
- [ ] Documentação lida
- [ ] Testes realizados

---

## 🎉 Pronto para Produção!

Se todos os checks acima passaram, o sistema está **100% pronto para produção**!

---

**Desenvolvido em:** 19 de outubro de 2025  
**Versão:** 2.0  
**Status:** ✅ Produção  
**Licença:** MIT
