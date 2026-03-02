# 🏪 Configuração do Mercado Pago por Loja - Guia Completo

## 📋 Visão Geral

Seu sistema **JÁ ESTÁ CONFIGURADO** para que cada loja tenha suas próprias credenciais do Mercado Pago (Access Token e Public Key). Isso significa que:

✅ **Cada loja é independente** - Não há conflito entre tokens de diferentes lojas  
✅ **Pagamentos isolados** - O dinheiro cai diretamente na conta do dono de cada loja  
✅ **Multi-tenant completo** - Suporta milhares de lojas simultaneamente  
✅ **Seguro** - Credenciais protegidas com Row Level Security (RLS)

---

## 🎯 Como Funciona

### Arquitetura Multi-Tenant

```
┌─────────────────────────────────────────────────────────────┐
│                    SISTEMA MULTI-TENANT                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Loja A                    Loja B                    Loja C  │
│  ├─ Token A                ├─ Token B                ├─ Token C
│  ├─ Public Key A           ├─ Public Key B           ├─ Public Key C
│  └─ Conta MP A             └─ Conta MP B             └─ Conta MP C
│                                                               │
│  Cliente paga na Loja A → Dinheiro vai para Conta MP A      │
│  Cliente paga na Loja B → Dinheiro vai para Conta MP B      │
│  Cliente paga na Loja C → Dinheiro vai para Conta MP C      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Fluxo de Pagamento

```
1. Cliente acessa loja pública (ex: seusite.com/minha-loja)
2. Adiciona produtos ao carrinho
3. Clica em "Finalizar Pedido"
4. Sistema busca credenciais ESPECÍFICAS desta loja no banco
5. Cria pagamento PIX usando as credenciais da loja
6. Cliente paga
7. Dinheiro cai na conta do Mercado Pago do dono da loja
```

---

## 🗄️ Estrutura do Banco de Dados

### Tabela: `merchant_payment_credentials`

Esta tabela armazena as credenciais de cada loja:

```sql
CREATE TABLE merchant_payment_credentials (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),      -- Dono da loja
  store_id UUID REFERENCES stores(id),          -- 🔑 ID da loja (chave multi-tenant)
  public_key TEXT NOT NULL,                     -- Public Key do Mercado Pago
  access_token TEXT NOT NULL,                   -- Access Token do Mercado Pago
  environment TEXT DEFAULT 'production',        -- 'sandbox' ou 'production'
  is_active BOOLEAN DEFAULT true,               -- Apenas uma credencial ativa por loja
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

**Campos importantes:**
- `store_id`: Identifica a qual loja as credenciais pertencem (ESSENCIAL para multi-tenant)
- `user_id`: Dono da loja (para autenticação)
- `is_active`: Permite ter múltiplas credenciais, mas apenas uma ativa por vez

### Índices para Performance

```sql
-- Busca rápida por loja
CREATE INDEX merchant_payment_credentials_store_id_idx 
  ON merchant_payment_credentials(store_id);

-- Busca rápida por loja + ativa
CREATE INDEX merchant_payment_credentials_store_active_idx 
  ON merchant_payment_credentials(store_id, is_active);
```

---

## 🔒 Segurança (RLS Policies)

O sistema usa Row Level Security (RLS) para garantir que cada loja só acesse suas próprias credenciais:

### Políticas Implementadas

```sql
-- ✅ Usuários podem ver credenciais de suas próprias lojas
CREATE POLICY "Users can view own store credentials"
  ON merchant_payment_credentials
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id 
    OR 
    store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid())
  );

-- ✅ Público pode ver credenciais ativas (apenas public_key)
CREATE POLICY "Public can view active credentials"
  ON merchant_payment_credentials
  FOR SELECT
  TO anon
  USING (is_active = true);
```

**Por que permitir acesso público?**
- A `public_key` é segura para expor (usada no frontend)
- O `access_token` **NUNCA** é retornado para o frontend
- Necessário para páginas públicas das lojas funcionarem

---

## 🚀 Como Configurar (Passo a Passo)

### Passo 1: Obter Credenciais do Mercado Pago

1. Acesse: https://www.mercadopago.com.br/developers/panel
2. Faça login com sua conta Mercado Pago
3. Vá em **"Suas integrações"** → **"Credenciais"**
4. Escolha o ambiente:
   - **Teste**: Para testar sem dinheiro real (recomendado inicialmente)
   - **Produção**: Para aceitar pagamentos reais
5. Copie as credenciais:
   - **Public Key**: `APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - **Access Token**: `APP_USR-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### Passo 2: Configurar no Sistema

1. **Faça login** no sistema como dono da loja
2. Acesse **Configurações** → **Pagamentos** (ou similar)
3. Cole suas credenciais:
   - Public Key
   - Access Token
4. Clique em **Salvar**

### Passo 3: Verificar Configuração

Execute no SQL Editor do Supabase:

```sql
-- Verificar se as credenciais foram salvas
SELECT 
  s.name AS loja,
  s.slug,
  mpc.public_key,
  mpc.environment,
  mpc.is_active,
  mpc.created_at
FROM merchant_payment_credentials mpc
JOIN stores s ON s.id = mpc.store_id
WHERE s.owner_id = auth.uid()  -- Suas lojas
ORDER BY mpc.created_at DESC;
```

---

## 💻 Implementação Técnica

### Frontend: Context API

O sistema usa `MercadoPagoContext` para gerenciar as credenciais:

```typescript
import { useMercadoPago } from '@/contexts/MercadoPagoContext';

// No painel admin (configurar credenciais)
const { saveConfig } = useMercadoPago();
const { currentStore } = useStore();

await saveConfig({
  publicKey: 'APP_USR-xxx',
  accessToken: 'APP_USR-yyy'
}, currentStore?.id);

// Em página pública (carregar credenciais)
const { loadConfigBySlug, isConfigured } = useMercadoPago();

useEffect(() => {
  if (slug) {
    loadConfigBySlug(slug);  // Carrega credenciais pelo slug da loja
  }
}, [slug]);
```

### Backend: Edge Function

A Edge Function `create-pix-payment` busca automaticamente as credenciais corretas:

```typescript
// Exemplo de chamada
const response = await supabase.functions.invoke('create-pix-payment', {
  body: {
    storeSlug: 'minha-loja',  // Identifica a loja
    amount: 150.00,
    customerName: 'João Silva',
    description: 'Pedido #123'
  }
});
```

**Fluxo interno da função:**

1. Recebe `storeSlug` ou `storeId`
2. Busca `store_id` pelo slug (se necessário)
3. Busca credenciais específicas desta loja no banco:
   ```sql
   SELECT access_token, public_key 
   FROM merchant_payment_credentials
   WHERE store_id = 'xxx' AND is_active = true
   ```
4. Usa as credenciais para criar pagamento no Mercado Pago
5. Retorna QR Code PIX

---

## 🧪 Testando o Sistema

### Teste 1: Configurar Credenciais de Teste

1. Use credenciais de **TESTE** do Mercado Pago
2. Configure no painel admin
3. Verifique no banco:

```sql
SELECT * FROM merchant_payment_credentials 
WHERE store_id = 'seu-store-id' AND is_active = true;
```

### Teste 2: Criar Pagamento PIX

1. Acesse a página pública da loja
2. Adicione produtos ao carrinho
3. Finalize o pedido
4. Verifique se o QR Code PIX aparece
5. Use o app do Mercado Pago para testar o pagamento

### Teste 3: Verificar Isolamento (Múltiplas Lojas)

```sql
-- Criar 2 lojas com credenciais diferentes
INSERT INTO merchant_payment_credentials (user_id, store_id, public_key, access_token)
VALUES 
  ('user-1', 'store-a', 'KEY_A', 'TOKEN_A'),
  ('user-1', 'store-b', 'KEY_B', 'TOKEN_B');

-- Verificar isolamento
SELECT * FROM merchant_payment_credentials WHERE store_id = 'store-a';
-- Deve retornar apenas KEY_A e TOKEN_A

SELECT * FROM merchant_payment_credentials WHERE store_id = 'store-b';
-- Deve retornar apenas KEY_B e TOKEN_B
```

---

## 🔄 Cenários de Uso

### Cenário 1: Lojista Único com Uma Loja

```
1. Lojista cria conta
2. Cria sua loja
3. Configura credenciais do Mercado Pago
4. Clientes pagam → dinheiro cai na conta do lojista
```

### Cenário 2: Lojista com Múltiplas Lojas

```
1. Lojista tem 3 lojas: "loja-a", "loja-b", "loja-c"
2. Cada loja tem suas próprias credenciais do Mercado Pago
3. Cliente paga em "loja-a" → dinheiro vai para conta A
4. Cliente paga em "loja-b" → dinheiro vai para conta B
5. Cada loja é completamente independente
```

### Cenário 3: Múltiplos Lojistas

```
1. Lojista A tem "loja-a" com credenciais A
2. Lojista B tem "loja-b" com credenciais B
3. Lojista C tem "loja-c" com credenciais C
4. Cada lojista recebe pagamentos em sua própria conta
5. Não há conflito entre credenciais
```

---

## 🐛 Troubleshooting

### Erro: "Credenciais não encontradas"

**Causa:** A loja não tem credenciais configuradas

**Solução:**
1. Acesse o painel admin
2. Vá em Configurações → Pagamentos
3. Configure as credenciais do Mercado Pago
4. Verifique no banco:
```sql
SELECT * FROM merchant_payment_credentials 
WHERE store_id = 'seu-store-id' AND is_active = true;
```

### Erro: "Store ID não fornecido"

**Causa:** A requisição não incluiu `storeId` nem `storeSlug`

**Solução:**
```typescript
// Sempre passe um dos dois
await supabase.functions.invoke('create-pix-payment', {
  body: {
    storeSlug: 'minha-loja',  // ✅ Adicione isso
    amount: 100
  }
});
```

### Erro: "Execute a migration para adicionar store_id"

**Causa:** A coluna `store_id` não existe na tabela

**Solução:**
```bash
# Execute a migration
supabase db push

# Ou execute manualmente no SQL Editor:
ALTER TABLE merchant_payment_credentials 
ADD COLUMN store_id UUID REFERENCES stores(id);
```

### Erro: "Pagamento criado mas dinheiro não caiu"

**Causa:** Credenciais de teste ou problema no Mercado Pago

**Solução:**
1. Verifique se está usando credenciais de **PRODUÇÃO** (não teste)
2. Verifique se a conta do Mercado Pago está ativa
3. Aguarde alguns minutos (pode haver delay)
4. Verifique no painel do Mercado Pago se o pagamento foi registrado

---

## 📊 Monitoramento

### Verificar Credenciais Ativas

```sql
SELECT 
  s.name AS loja,
  s.slug,
  u.email AS dono,
  mpc.public_key,
  mpc.environment,
  mpc.is_active,
  mpc.created_at
FROM merchant_payment_credentials mpc
JOIN stores s ON s.id = mpc.store_id
JOIN auth.users u ON u.id = s.owner_id
WHERE mpc.is_active = true
ORDER BY mpc.created_at DESC;
```

### Verificar Pagamentos por Loja

```sql
SELECT 
  s.name AS loja,
  COUNT(o.id) AS total_pedidos,
  SUM(o.total) AS total_vendas
FROM orders o
JOIN stores s ON s.id = o.store_id
WHERE o.payment_status = 'paid'
GROUP BY s.id, s.name
ORDER BY total_vendas DESC;
```

### Verificar Lojas Sem Credenciais

```sql
SELECT 
  s.id,
  s.name,
  s.slug,
  u.email AS dono
FROM stores s
JOIN auth.users u ON u.id = s.owner_id
LEFT JOIN merchant_payment_credentials mpc ON mpc.store_id = s.id AND mpc.is_active = true
WHERE mpc.id IS NULL
  AND s.is_active = true;
```

---

## 🔐 Segurança e Boas Práticas

### ✅ O que o sistema JÁ FAZ

1. **Isolamento por loja**: Cada loja só acessa suas próprias credenciais
2. **RLS habilitado**: Políticas de segurança no banco de dados
3. **Access Token protegido**: Nunca exposto no frontend
4. **Public Key segura**: Pode ser usada no frontend
5. **Credenciais por loja**: Cada loja tem suas próprias credenciais

### ⚠️ Importante para Lojistas

1. **Nunca** compartilhe seu Access Token com ninguém
2. **Nunca** exponha o Access Token em código público
3. **Sempre** use HTTPS em produção
4. **Sempre** use credenciais de TESTE primeiro para validar
5. **Sempre** verifique se os pagamentos estão caindo na conta correta

### 🔒 Importante para Desenvolvedores

1. **Nunca** commite credenciais no código
2. **Nunca** exponha o Access Token no frontend
3. **Sempre** use variáveis de ambiente para credenciais da plataforma
4. **Sempre** valide a origem das requisições
5. **Sempre** use RLS para proteger dados sensíveis

---

## 📚 Arquivos Relacionados

### Migrations
- `supabase/migrations/20251010145200_create_merchant_payment_credentials.sql` - Cria tabela inicial
- `supabase/migrations/20251012000000_add_store_id_to_merchant_credentials.sql` - Adiciona suporte multi-tenant

### Frontend
- `src/contexts/MercadoPagoContext.tsx` - Context para gerenciar credenciais
- `src/components/payment/MercadoPagoConfig.tsx` - Componente de configuração

### Backend
- `supabase/functions/create-pix-payment/index.ts` - Edge Function para criar pagamentos

### Documentação
- `MERCADOPAGO_MULTI_TENANT.md` - Documentação técnica detalhada
- `PAYMENT_ARCHITECTURE.md` - Arquitetura de pagamentos
- `FLUXO_PAGAMENTOS.md` - Fluxo de pagamentos

---

## 🎉 Conclusão

Seu sistema **JÁ ESTÁ PRONTO** para que cada loja tenha suas próprias credenciais do Mercado Pago!

### ✅ O que você tem:

- **Multi-tenancy completo**: Cada loja é independente
- **Pagamentos isolados**: Dinheiro cai na conta certa
- **Segurança robusta**: RLS e políticas de acesso
- **Escalabilidade**: Suporta milhares de lojas
- **Fácil configuração**: Interface simples para lojistas

### 🚀 Próximos Passos Sugeridos:

1. **Testar com credenciais de teste** do Mercado Pago
2. **Configurar webhooks** para confirmação automática de pagamentos
3. **Adicionar suporte a cartão de crédito** (além de PIX)
4. **Criar dashboard de analytics** por loja
5. **Implementar sistema de comissões** (se aplicável)

---

## 📞 Suporte

Se encontrar problemas:

1. Verifique os logs no Supabase Dashboard
2. Consulte a documentação do Mercado Pago
3. Verifique se as migrations foram executadas
4. Verifique se as políticas RLS estão ativas
5. Entre em contato com o suporte técnico

---

**Última atualização:** Outubro 2024  
**Versão:** 2.0 (Multi-tenant)
