# 🐛 Solução: Dias Restantes Calculados Incorretamente

## 🚨 Problema Identificado

### Sintoma
Na página de assinatura, os "Dias Restantes" mostram valores errados:
- Mostra **6 dias** quando na verdade faltam **36 dias**
- Mostra **7 dias** quando na verdade faltam **38 dias**
- A barra de progresso também fica incorreta

### Causa Raiz
A função SQL `get_active_subscription` estava usando `EXTRACT(DAY FROM interval)` para calcular os dias restantes.

**Problema:** `EXTRACT(DAY)` só extrai a **parte dos dias** do intervalo, ignorando meses e anos.

#### Exemplo do Bug

```sql
-- Data de expiração: 19 de novembro de 2025
-- Data atual: 12 de outubro de 2025
-- Diferença real: 38 dias

-- Cálculo ERRADO (antigo):
expires_at - NOW() = INTERVAL '1 month 7 days'
EXTRACT(DAY FROM INTERVAL '1 month 7 days') = 7  ❌ (ignora o mês!)

-- Cálculo CORRETO (novo):
DATE('2025-11-19') - DATE('2025-10-12') = 38  ✅
```

---

## ✅ Solução

### SQL de Correção

**Arquivo:** `SQL_FIX_DIAS_RESTANTES_URGENTE.sql`

### Como Executar

1. **Acesse:** Dashboard Supabase → SQL Editor
2. **Cole** o conteúdo do arquivo
3. **Execute** (Run)
4. **Recarregue** a página de assinatura

### O que foi corrigido

#### Antes (Errado)
```sql
EXTRACT(DAY FROM (us.expires_at - NOW()))::INTEGER AS days_remaining
```
- ❌ Só pega a parte "dias" do intervalo
- ❌ Ignora meses e anos
- ❌ Resultado incorreto

#### Depois (Correto)
```sql
(DATE(us.expires_at) - DATE(NOW()))::INTEGER AS days_remaining
```
- ✅ Subtrai datas diretamente
- ✅ Calcula total de dias
- ✅ Resultado correto

---

## 📊 Exemplos de Cálculo

### Exemplo 1: Assinatura de 30 dias

```
Data de início: 19 de setembro de 2025
Data de expiração: 19 de outubro de 2025
Data atual: 12 de outubro de 2025

ANTES (errado):
Intervalo: 7 days
EXTRACT(DAY) = 7 dias ❌

DEPOIS (correto):
DATE('2025-10-19') - DATE('2025-10-12') = 7 dias ✅
```

### Exemplo 2: Assinatura de 365 dias (anual)

```
Data de início: 19 de setembro de 2025
Data de expiração: 19 de setembro de 2026
Data atual: 12 de outubro de 2025

ANTES (errado):
Intervalo: 11 months 7 days
EXTRACT(DAY) = 7 dias ❌ (deveria ser ~342!)

DEPOIS (correto):
DATE('2026-09-19') - DATE('2025-10-12') = 342 dias ✅
```

### Exemplo 3: Teste Gratuito (7 dias)

```
Data de início: 19 de setembro de 2025
Data de expiração: 26 de setembro de 2025
Data atual: 12 de outubro de 2025

ANTES (errado):
Intervalo: -16 days
EXTRACT(DAY) = -16 → GREATEST(0, -16) = 0 dias ✅ (funciona por acaso)

DEPOIS (correto):
DATE('2025-09-26') - DATE('2025-10-12') = -16 → GREATEST(0, -16) = 0 dias ✅
```

---

## 🔍 Como Verificar se Está Correto

### Teste 1: Verificar no SQL Editor

```sql
-- Execute no Supabase SQL Editor
SELECT 
  plan_name AS "Plano",
  expires_at AS "Expira em",
  days_remaining AS "Dias Restantes",
  (DATE(expires_at) - DATE(NOW()))::INTEGER AS "Verificação Manual"
FROM get_active_subscription(auth.uid());
```

**Resultado esperado:**
- "Dias Restantes" = "Verificação Manual" ✅

### Teste 2: Verificar no Painel

```
1. Acesse: Admin → Assinatura
2. Veja "Dias Restantes"
3. Calcule manualmente: (Data de Expiração - Hoje)
4. Valores devem ser iguais ✅
```

### Teste 3: Verificar Barra de Progresso

```
1. Acesse: Admin → Assinatura
2. Veja "Progresso do Período"
3. Deve ser coerente com os dias restantes
4. Exemplo: 15 dias restantes de 30 = 50% ✅
```

---

## 🧪 Casos de Teste

### Teste 1: Assinatura Nova (30 dias)

```
Criada hoje: 12 de outubro de 2025
Expira em: 11 de novembro de 2025
Dias restantes: 30 dias ✅
Progresso: 100% (início do período)
```

### Teste 2: Assinatura no Meio (30 dias)

```
Criada em: 27 de setembro de 2025
Expira em: 27 de outubro de 2025
Hoje: 12 de outubro de 2025
Dias restantes: 15 dias ✅
Progresso: 50% (metade do período)
```

### Teste 3: Assinatura Expirando (30 dias)

```
Criada em: 5 de setembro de 2025
Expira em: 5 de outubro de 2025
Hoje: 12 de outubro de 2025
Dias restantes: 0 dias ✅ (expirada)
Status: Expirada
```

### Teste 4: Assinatura Anual (365 dias)

```
Criada em: 1 de janeiro de 2025
Expira em: 1 de janeiro de 2026
Hoje: 12 de outubro de 2025
Dias restantes: 81 dias ✅
Progresso: ~78% (284 dias passados de 365)
```

---

## 📈 Impacto da Correção

### Antes da Correção

```
Plano: Teste Gratuito (30 dias)
Data de expiração: 19 de outubro de 2025
Data atual: 12 de outubro de 2025

Dias restantes mostrados: 7 dias ❌ (errado!)
Barra de progresso: 23% ❌ (errado!)
```

### Depois da Correção

```
Plano: Teste Gratuito (30 dias)
Data de expiração: 19 de outubro de 2025
Data atual: 12 de outubro de 2025

Dias restantes mostrados: 7 dias ✅ (correto!)
Barra de progresso: 23% ✅ (correto!)
```

**Nota:** Neste caso específico, o valor estava correto por coincidência, mas em outros casos (como assinaturas anuais) estava muito errado.

---

## 🔧 Detalhes Técnicos

### Por que EXTRACT(DAY) não funciona?

```sql
-- Intervalo PostgreSQL tem 3 componentes:
-- [anos] [meses] [dias]

-- Exemplo: 1 ano, 2 meses, 15 dias
SELECT INTERVAL '1 year 2 months 15 days';

-- EXTRACT(DAY) só pega a parte [dias]:
SELECT EXTRACT(DAY FROM INTERVAL '1 year 2 months 15 days');
-- Resultado: 15 (ignora ano e meses!)

-- Solução: Subtrair datas diretamente
SELECT DATE '2026-03-27' - DATE '2025-01-12';
-- Resultado: 439 (total de dias correto!)
```

### Por que converter para DATE?

```sql
-- TIMESTAMP WITH TIME ZONE inclui horas, minutos, segundos
-- Isso pode causar problemas no cálculo

-- Exemplo:
-- expires_at: 2025-10-19 23:59:59
-- NOW(): 2025-10-12 10:30:00
-- Diferença: 7 days 13:29:59

-- Se não converter para DATE:
EXTRACT(DAY FROM '7 days 13:29:59') = 7

-- Convertendo para DATE:
DATE('2025-10-19') - DATE('2025-10-12') = 7

-- Ambos dão 7, mas DATE é mais confiável e previsível
```

---

## 🐛 Troubleshooting

### Problema: Dias restantes ainda aparecem errados

**Causa:** Cache do navegador ou sessão antiga

**Solução:**
```
1. Faça logout do painel admin
2. Limpe o cache (Ctrl + Shift + Delete)
3. Feche e abra o navegador
4. Faça login novamente
5. Acesse Admin → Assinatura
```

---

### Problema: Erro ao executar SQL

**Causa:** Função não existe ou tabelas não existem

**Solução:**
```sql
-- Verificar se função existe
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name = 'get_active_subscription';

-- Se não existir, execute a migration completa:
-- supabase/migrations/20251010193700_create_subscription_tables.sql
```

---

### Problema: Barra de progresso ainda incorreta

**Causa:** Cálculo no frontend usa dias restantes

**Solução:**
O cálculo da barra de progresso está correto no código:
```typescript
const totalDays = subscription.plan_slug === 'yearly' ? 365 : 30;
const percentageRemaining = (daysRemaining / totalDays) * 100;
```

Se os dias restantes estiverem corretos, a barra também estará.

---

## 📋 Checklist de Verificação

Após executar a correção:

- [ ] SQL executado sem erros
- [ ] Função `get_active_subscription` recriada
- [ ] Logout e login no painel admin
- [ ] Dias restantes mostram valor correto
- [ ] Barra de progresso coerente
- [ ] Data de expiração correta
- [ ] Status da assinatura correto

---

## 🎉 Resultado Final

### Antes
```
❌ Dias restantes incorretos (mostra 6 quando são 36)
❌ Barra de progresso errada
❌ Usuários confusos sobre quando expira
❌ Cálculo usando EXTRACT(DAY) bugado
```

### Depois
```
✅ Dias restantes corretos
✅ Barra de progresso precisa
✅ Informação clara para usuários
✅ Cálculo usando subtração de datas
```

---

## 📚 Arquivos Relacionados

- `SQL_FIX_DIAS_RESTANTES_URGENTE.sql` - SQL para executar agora
- `supabase/migrations/20251012110000_fix_days_remaining_calculation.sql` - Migration permanente
- `src/pages/admin/Subscription.tsx` - Página que exibe os dados
- `src/contexts/SubscriptionContext.tsx` - Context que carrega os dados

---

## 🔗 Referências

- [PostgreSQL EXTRACT](https://www.postgresql.org/docs/current/functions-datetime.html#FUNCTIONS-DATETIME-EXTRACT)
- [PostgreSQL Date/Time Operators](https://www.postgresql.org/docs/current/functions-datetime.html#OPERATORS-DATETIME-TABLE)

---

**Execute o SQL agora e os dias restantes serão calculados corretamente!** 🚀
