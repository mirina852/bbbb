# 🎨 Diagrama Visual - Status da Assinatura

## 📸 Referência da Interface

Baseado na imagem fornecida, aqui está o mapeamento completo dos elementos visuais:

---

## 🖼️ Elementos da Interface

### **Card Principal**
```
┌─────────────────────────────────────────────────────────────┐
│  🕐 Teste Gratuito                                          │
│  Status: [Expirando em Breve]                    [Gratuito] │
│                                                               │
│  🕐 Dias Restantes                                           │
│     0                                                         │
│                                                               │
│  Progresso do Período                              0%        │
│  [████████████████████████████████████████████████] (laranja)│
│                                                               │
│  📅 Data de Início        📅 Expira em                       │
│     N/A                      19 de outubro de 2025           │
│                                                               │
│  [        Renovar Assinatura        ] (botão laranja)       │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Mapeamento de Cores por Status

### **1. Ativa (> 7 dias)** ✅

```
┌──────────────────────────────────────────────── VERDE ──────┐
│  ✓ Plano Mensal                                             │
│  Status: [Ativa] (verde)                                    │
│                                                               │
│  🕐 Dias Restantes (verde)                                   │
│     23                                                        │
│                                                               │
│  Progresso do Período                             76%        │
│  [████████████████████████████████░░░░░░░░░░░░] (verde)     │
│                                                               │
│  📅 Data de Início        📅 Expira em                       │
│     01 de outubro de 2025    24 de outubro de 2025          │
└─────────────────────────────────────────────────────────────┘
```

**Características:**
- Borda: `border-green-500`
- Badge: Verde - "Ativa"
- Ícone: `CheckCircle` verde
- Dias: Texto verde
- Barra: Verde (`[&>div]:bg-green-500`)
- Botão: Nenhum (não mostra)

---

### **2. Expirando em Breve (≤ 7 dias)** ⚠️

```
┌─────────────────────────────────────────────── LARANJA ─────┐
│  🕐 Teste Gratuito                                          │
│  Status: [Expirando em Breve] (laranja)       [Gratuito]   │
│                                                               │
│  🕐 Dias Restantes (laranja)                                 │
│     5                                                         │
│                                                               │
│  Progresso do Período                             16%        │
│  [████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] (laranja)    │
│                                                               │
│  📅 Data de Início        📅 Expira em                       │
│     12 de outubro de 2025    19 de outubro de 2025          │
│                                                               │
│  [        Renovar Assinatura        ] (laranja)             │
└─────────────────────────────────────────────────────────────┘
```

**Características:**
- Borda: `border-orange-500`
- Badge: Laranja - "Expirando em Breve"
- Ícone: `Clock` laranja
- Dias: Texto laranja
- Barra: Laranja (`[&>div]:bg-orange-500`)
- Botão: "Renovar Assinatura" (laranja, variant default)

---

### **3. Expirada** ❌

```
┌──────────────────────────────────────────────── VERMELHO ───┐
│  ⚠ Teste Gratuito                                           │
│  Status: [Expirada] (vermelho)                              │
│                                                               │
│  🕐 Dias Restantes (vermelho)                                │
│     0                                                         │
│                                                               │
│  (Sem barra de progresso)                                    │
│                                                               │
│  📅 Data de Início        📅 Expirou em                      │
│     01 de outubro de 2025    18 de outubro de 2025          │
│                                                               │
│  [     Renovar Assinatura Agora     ] (vermelho)            │
└─────────────────────────────────────────────────────────────┘
```

**Características:**
- Borda: `border-red-500`
- Badge: Vermelho - "Expirada"
- Ícone: `AlertCircle` vermelho
- Dias: "0" em vermelho
- Barra: Oculta (não renderiza)
- Botão: "Renovar Assinatura Agora" (vermelho, variant destructive)

---

### **4. Sem Assinatura** 🚫

```
┌─────────────────────────────────────────────── LARANJA ─────┐
│  ⚠ Assinatura Necessária                                    │
│                                                               │
│  Você precisa ativar um plano para acessar o sistema.       │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ⚠️ Acesso Bloqueado                                  │   │
│  │                                                       │   │
│  │ Para acessar o Dashboard, Produtos, Pedidos e        │   │
│  │ Configurações, você precisa escolher e ativar um     │   │
│  │ plano de assinatura.                                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                               │
│  O que você pode fazer com uma assinatura:                  │
│  ✓ Gerenciar produtos e categorias                          │
│  ✓ Receber e processar pedidos                              │
│  ✓ Visualizar estatísticas e dashboard                      │
│  ✓ Configurar sua loja online                               │
│                                                               │
│  [    🚀 Ver Planos e Ativar Agora    ] (laranja)          │
└─────────────────────────────────────────────────────────────┘
```

**Características:**
- Borda: `border-2 border-orange-500`
- Header: Fundo laranja (`bg-orange-50`)
- Ícone: `AlertCircle` laranja
- Alerta: Fundo laranja claro
- Botão: "🚀 Ver Planos e Ativar Agora" (laranja)

---

## 🔢 Tabela de Valores por Status

| Status | days_remaining | status DB | Badge | Cor Borda | Cor Texto | Barra | Botão |
|--------|---------------|-----------|-------|-----------|-----------|-------|-------|
| **Ativa** | > 7 | active | Verde "Ativa" | Verde | Verde | Verde | Nenhum |
| **Expirando** | 1-7 | active | Laranja "Expirando em Breve" | Laranja | Laranja | Laranja | "Renovar" |
| **Expirada** | 0 | expired | Vermelho "Expirada" | Vermelho | Vermelho | Oculta | "Renovar Agora" |
| **Sem Assinatura** | - | - | - | Laranja | - | - | "Ver Planos" |

---

## 🎨 Classes CSS Utilizadas

### **Cores de Borda**
```typescript
className={
  isExpired ? 'border-red-500' : 
  isExpiringSoon ? 'border-orange-500' : 
  'border-green-500'
}
```

### **Cores de Texto (Dias Restantes)**
```typescript
className={`text-3xl font-bold ${
  isExpired ? 'text-red-600' : 
  isExpiringSoon ? 'text-orange-600' : 
  'text-green-600'
}`}
```

### **Cores da Barra de Progresso**
```typescript
className={`h-3 ${
  isExpiringSoon ? '[&>div]:bg-orange-500' : '[&>div]:bg-green-500'
}`}
```

### **Variantes de Badge**
```typescript
variant={
  isExpired ? 'destructive' : 
  isExpiringSoon ? 'outline' : 
  'default'
}
```

### **Variantes de Botão**
```typescript
variant={isExpired ? 'destructive' : 'default'}
```

---

## 📊 Exemplos de Cálculo de Progresso

### **Plano Mensal (30 dias)**

| Dias Restantes | Cálculo | Porcentagem | Cor |
|----------------|---------|-------------|-----|
| 30 | (30/30) × 100 | 100% | Verde |
| 15 | (15/30) × 100 | 50% | Verde |
| 7 | (7/30) × 100 | 23% | Laranja |
| 3 | (3/30) × 100 | 10% | Laranja |
| 1 | (1/30) × 100 | 3% | Laranja |
| 0 | - | Oculta | - |

### **Plano Anual (365 dias)**

| Dias Restantes | Cálculo | Porcentagem | Cor |
|----------------|---------|-------------|-----|
| 365 | (365/365) × 100 | 100% | Verde |
| 180 | (180/365) × 100 | 49% | Verde |
| 30 | (30/365) × 100 | 8% | Verde |
| 7 | (7/365) × 100 | 2% | Laranja |
| 1 | (1/365) × 100 | 0.3% | Laranja |
| 0 | - | Oculta | - |

---

## 🔄 Transições de Estado Visual

```
NOVA ASSINATURA (30 dias)
    │
    │ Verde, 100%, "Ativa"
    ▼
DIA 23 (8 dias restantes)
    │
    │ Ainda verde, 27%, "Ativa"
    ▼
DIA 24 (7 dias restantes) ⚠️ THRESHOLD
    │
    │ Muda para laranja, 23%, "Expirando em Breve"
    │ Aparece botão "Renovar"
    ▼
DIA 29 (1 dia restante)
    │
    │ Laranja, 3%, "Expirando em Breve"
    ▼
DIA 30 (0 dias) ❌ EXPIROU
    │
    │ Vermelho, sem barra, "Expirada"
    │ Botão "Renovar Agora" (vermelho)
    ▼
USUÁRIO RENOVA
    │
    │ Volta para verde, 100%, "Ativa"
    └─> Nova assinatura criada
```

---

## 🎯 Elementos Específicos da Imagem

### **Conforme a imagem fornecida:**

1. **Título:** "Teste Gratuito"
2. **Status:** "Expirando em Breve" (badge laranja)
3. **Badge Secundário:** "Gratuito" (canto superior direito)
4. **Dias Restantes:** "0" (em laranja)
5. **Progresso:** "0%" (barra laranja vazia)
6. **Data de Início:** "N/A" (teste gratuito sem data definida)
7. **Expira em:** "19 de outubro de 2025"
8. **Botão:** "Renovar Assinatura" (laranja)

### **Código correspondente:**

```typescript
// Badge de teste gratuito
{subscription.plan_slug === 'trial' && !isExpired && (
  <Badge variant="secondary" className="text-sm px-4 py-2">
    Teste Gratuito
  </Badge>
)}

// Status "Expirando em Breve"
const isExpiringSoon = daysRemaining <= 7;

// Data de início N/A
{subscription.created_at
  ? new Date(subscription.created_at).toLocaleDateString('pt-BR')
  : 'N/A'}
```

---

## 📝 Observações Importantes

1. **Teste Gratuito:** Mostra badge "Gratuito" adicional no canto superior
2. **Data N/A:** Quando `created_at` é null, mostra "N/A"
3. **Threshold de 7 dias:** É o ponto de mudança de verde para laranja
4. **Dias = 0:** Pode estar "Expirando em Breve" (último dia) ou "Expirada"
5. **Barra de Progresso:** Só é ocultada quando `isExpired === true`

---

**Última atualização:** 19 de outubro de 2025
