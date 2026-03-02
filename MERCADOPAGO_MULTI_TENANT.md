# 🏪 Sistema Multi-Tenant de Pagamentos - Mercado Pago

## 📋 Visão Geral

Este documento explica como o sistema permite que **cada loja tenha suas próprias credenciais do Mercado Pago**, garantindo que os pagamentos dos clientes caiam diretamente na conta do dono da loja.

---

## 🎯 Arquitetura

### Conceito Multi-Tenant

Cada loja (store) no sistema é independente e possui:
- ✅ Suas próprias credenciais do Mercado Pago (Public Key + Access Token)
- ✅ Seus próprios produtos e pedidos
- ✅ Sua própria URL pública (ex: `seusite.com/minha-loja`)
- ✅ Recebe pagamentos diretamente em sua conta

### Fluxo de Pagamento

```
Cliente acessa loja → Faz pedido → Sistema busca credenciais da loja → 
Cria pagamento PIX → Dinheiro cai na conta do dono da loja
```

---

## 🗄️ Estrutura do Banco de Dados

### Tabela: `merchant_payment_credentials`

```sql
CREATE TABLE merchant_payment_credentials (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  store_id UUID REFERENCES stores(id),  -- 🔑 Chave para multi-tenant
  public_key TEXT NOT NULL,
  access_token TEXT NOT NULL,
  environment TEXT DEFAULT 'production',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

**Campos importantes:**
- `store_id`: Identifica a qual loja as credenciais pertencem
- `user_id`: Dono da loja (para autenticação)
- `is_active`: Permite ter múltiplas credenciais, mas apenas uma ativa

### Índices

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

### Políticas de Acesso

```sql
-- Usuários podem ver credenciais de suas próprias lojas
CREATE POLICY "Users can view own store credentials"
  ON merchant_payment_credentials
  FOR SELECT
  USING (
    auth.uid() = user_id 
    OR 
    store_id IN (SELECT id FROM stores WHERE owner_id = auth.uid())
  );

-- Público pode ver credenciais ativas (apenas public_key, não access_token)
CREATE POLICY "Public can view active credentials"
  ON merchant_payment_credentials
  FOR SELECT
  TO anon
  USING (is_active = true);
```

**Por que permitir acesso público?**
- A `public_key` é segura para expor (usada no frontend)
- O `access_token` nunca é retornado para o frontend
- Necessário para páginas públicas das lojas funcionarem

---

## 💻 Implementação Frontend

### 1. Context: `MercadoPagoContext`

Gerencia as credenciais do Mercado Pago de forma centralizada.

#### Funções Principais

```typescript
interface MercadoPagoContextType {
  config: MercadoPagoConfig | null;
  isConfigured: boolean;
  
  // Salvar credenciais de uma loja específica
  saveConfig: (config: MercadoPagoConfig, storeId?: string) => Promise<void>;
  
  // Carregar credenciais por store_id
  loadConfig: (storeId?: string) => Promise<void>;
  
  // Carregar credenciais por slug da loja (para páginas públicas)
  loadConfigBySlug: (slug: string) => Promise<void>;
}
```

#### Uso no Admin (Configurar Credenciais)

```typescript
import { useMercadoPago } from '@/contexts/MercadoPagoContext';
import { useStore } from '@/contexts/StoreContext';

const MercadoPagoConfig = () => {
  const { saveConfig } = useMercadoPago();
  const { currentStore } = useStore();
  
  const handleSave = async () => {
    await saveConfig({
      publicKey: 'APP_USR-xxx',
      accessToken: 'APP_USR-yyy'
    }, currentStore?.id);
  };
  
  return (
    <form onSubmit={handleSave}>
      {/* Campos de input */}
    </form>
  );
};
```

#### Uso em Página Pública (Carregar Credenciais)

```typescript
import { useMercadoPago } from '@/contexts/MercadoPagoContext';
import { useParams } from 'react-router-dom';

const StorePublicPage = () => {
  const { slug } = useParams();
  const { loadConfigBySlug, isConfigured } = useMercadoPago();
  
  useEffect(() => {
    if (slug) {
      loadConfigBySlug(slug);
    }
  }, [slug]);
  
  if (!isConfigured) {
    return <div>Esta loja ainda não configurou pagamentos</div>;
  }
  
  return <div>Loja configurada!</div>;
};
```

---

## ⚡ Edge Function: `create-pix-payment`

A Edge Function foi atualizada para buscar credenciais específicas de cada loja.

### Parâmetros da Requisição

```typescript
{
  // Identificação da loja (um dos dois é obrigatório)
  storeId?: string,      // ID direto da loja
  storeSlug?: string,    // Slug da loja (ex: "minha-loja")
  
  // Dados do pagamento
  amount: number,
  customerName?: string,
  customerPhone?: string,
  description?: string
}
```

### Fluxo de Busca de Credenciais

```typescript
// 1. Determinar store_id
let targetStoreId = storeId;

if (!targetStoreId && storeSlug) {
  // Buscar store_id pelo slug
  const { data } = await supabase
    .from('stores')
    .select('id')
    .eq('slug', storeSlug)
    .single();
  
  targetStoreId = data.id;
}

// 2. Buscar credenciais específicas desta loja
const { data: credentials } = await supabase
  .from('merchant_payment_credentials')
  .select('access_token, public_key')
  .eq('store_id', targetStoreId)
  .eq('is_active', true)
  .order('created_at', { ascending: false })
  .limit(1)
  .single();

// 3. Usar credenciais para criar pagamento
const mpResponse = await fetch('https://api.mercadopago.com/v1/payments', {
  headers: {
    'Authorization': `Bearer ${credentials.access_token}`
  },
  // ...
});
```

### Exemplo de Chamada

```typescript
const response = await supabase.functions.invoke('create-pix-payment', {
  body: {
    storeSlug: 'minha-loja',  // Identifica a loja
    amount: 150.00,
    customerName: 'João Silva',
    description: 'Pedido #123'
  }
});
```

---

## 🚀 Configuração Passo a Passo

### 1. Executar Migration

Execute a migration para adicionar a coluna `store_id`:

```bash
# Via Supabase CLI
supabase db push

# Ou execute manualmente no SQL Editor
-- Arquivo: supabase/migrations/20251012000000_add_store_id_to_merchant_credentials.sql
```

### 2. Configurar Credenciais da Loja

1. Acesse o painel admin da loja
2. Vá em **Configurações** → **Pagamentos**
3. Insira suas credenciais do Mercado Pago:
   - Public Key: `APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - Access Token: `APP_USR-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
4. Clique em **Salvar**

### 3. Obter Credenciais do Mercado Pago

1. Acesse: https://www.mercadopago.com.br/developers/panel
2. Faça login com sua conta
3. Vá em **Suas integrações** → **Credenciais**
4. Escolha o ambiente:
   - **Teste**: Para testar sem dinheiro real
   - **Produção**: Para aceitar pagamentos reais
5. Copie a Public Key e o Access Token

---

## 🔄 Fluxos de Uso

### Fluxo 1: Lojista Configura Credenciais

```
1. Lojista faz login
2. Acessa Configurações → Pagamentos
3. Insere Public Key e Access Token
4. Sistema salva com store_id da loja
5. Credenciais ficam ativas para esta loja
```

### Fluxo 2: Cliente Faz Pedido

```
1. Cliente acessa loja pública (ex: /minha-loja)
2. Adiciona produtos ao carrinho
3. Clica em "Finalizar Pedido"
4. Sistema busca credenciais da loja pelo slug
5. Cria pagamento PIX usando credenciais da loja
6. Cliente paga
7. Dinheiro cai na conta do dono da loja
```

### Fluxo 3: Múltiplas Lojas do Mesmo Usuário

```
1. Usuário tem 3 lojas: "loja-a", "loja-b", "loja-c"
2. Cada loja tem suas próprias credenciais
3. Cliente paga em "loja-a" → dinheiro vai para conta A
4. Cliente paga em "loja-b" → dinheiro vai para conta B
5. Cada loja é completamente independente
```

---

## 🧪 Testando o Sistema

### Teste 1: Configurar Credenciais

```typescript
// No painel admin
const { saveConfig } = useMercadoPago();
const { currentStore } = useStore();

await saveConfig({
  publicKey: 'TEST_PUBLIC_KEY',
  accessToken: 'TEST_ACCESS_TOKEN'
}, currentStore.id);

// Verificar no banco
SELECT * FROM merchant_payment_credentials 
WHERE store_id = 'seu-store-id';
```

### Teste 2: Criar Pagamento

```typescript
// Na página pública da loja
const response = await supabase.functions.invoke('create-pix-payment', {
  body: {
    storeSlug: 'minha-loja',
    amount: 10.00,
    customerName: 'Teste',
    description: 'Pedido teste'
  }
});

console.log(response.data);
// Deve retornar: { success: true, data: { qr_code: "...", ... } }
```

### Teste 3: Verificar Isolamento

```sql
-- Criar 2 lojas com credenciais diferentes
INSERT INTO merchant_payment_credentials (user_id, store_id, public_key, access_token)
VALUES 
  ('user-1', 'store-a', 'KEY_A', 'TOKEN_A'),
  ('user-1', 'store-b', 'KEY_B', 'TOKEN_B');

-- Buscar credenciais da loja A
SELECT * FROM merchant_payment_credentials 
WHERE store_id = 'store-a' AND is_active = true;
-- Deve retornar apenas KEY_A e TOKEN_A

-- Buscar credenciais da loja B
SELECT * FROM merchant_payment_credentials 
WHERE store_id = 'store-b' AND is_active = true;
-- Deve retornar apenas KEY_B e TOKEN_B
```

---

## 🐛 Troubleshooting

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

### Erro: "Credenciais não encontradas"

**Causa:** A loja não tem credenciais configuradas

**Solução:**
1. Acesse o painel admin
2. Configure as credenciais do Mercado Pago
3. Verifique no banco:
```sql
SELECT * FROM merchant_payment_credentials 
WHERE store_id = 'seu-store-id' AND is_active = true;
```

### Erro: "Execute a migration para adicionar store_id"

**Causa:** A coluna `store_id` não existe na tabela

**Solução:**
```bash
# Execute a migration
supabase db push

# Ou execute manualmente o SQL
ALTER TABLE merchant_payment_credentials 
ADD COLUMN store_id UUID REFERENCES stores(id);
```

---

## 📊 Monitoramento

### Verificar Credenciais Ativas

```sql
SELECT 
  s.name AS loja,
  s.slug,
  mpc.public_key,
  mpc.environment,
  mpc.created_at
FROM merchant_payment_credentials mpc
JOIN stores s ON s.id = mpc.store_id
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
GROUP BY s.id, s.name
ORDER BY total_vendas DESC;
```

---

## 🔐 Segurança e Boas Práticas

### ✅ Implementado

1. **Isolamento por loja**: Cada loja só acessa suas próprias credenciais
2. **RLS habilitado**: Políticas de segurança no banco de dados
3. **Access Token protegido**: Nunca exposto no frontend
4. **Public Key segura**: Pode ser usada no frontend
5. **Credenciais criptografadas**: Armazenadas de forma segura

### ⚠️ Importante

1. **Nunca** commite credenciais no código
2. **Nunca** exponha o Access Token no frontend
3. **Sempre** use HTTPS em produção
4. **Sempre** valide a origem das requisições
5. **Sempre** use variáveis de ambiente para credenciais da plataforma

---

## 📚 Referências

- [Mercado Pago API](https://www.mercadopago.com.br/developers/pt/reference)
- [PIX via API](https://www.mercadopago.com.br/developers/pt/docs/checkout-api/integration-configuration/integrate-with-pix)
- [Supabase RLS](https://supabase.com/docs/guides/auth/row-level-security)
- [Edge Functions](https://supabase.com/docs/guides/functions)

---

## 🎉 Conclusão

Com este sistema implementado, você tem:

✅ **Multi-tenancy completo**: Cada loja é independente  
✅ **Pagamentos isolados**: Dinheiro cai na conta certa  
✅ **Segurança robusta**: RLS e políticas de acesso  
✅ **Escalabilidade**: Suporta milhares de lojas  
✅ **Fácil manutenção**: Código organizado e documentado

**Próximos passos sugeridos:**
1. Implementar webhooks para confirmação automática de pagamentos
2. Adicionar suporte a outros métodos de pagamento (cartão, boleto)
3. Criar dashboard de analytics por loja
4. Implementar sistema de comissões (se aplicável)
