# ⚡ Guia Rápido: Configurar Pagamentos Multi-Tenant

## 🎯 O que foi implementado?

Agora cada loja tem suas **próprias credenciais do Mercado Pago**. Quando um cliente faz um pedido, o sistema usa automaticamente as credenciais da loja correta.

---

## 📋 Checklist de Implementação

### ✅ Passo 1: Executar Migration

Execute a migration para adicionar a coluna `store_id`:

**Opção A: Via Supabase Dashboard**
1. Acesse: Dashboard → SQL Editor
2. Cole o conteúdo de: `supabase/migrations/20251012000000_add_store_id_to_merchant_credentials.sql`
3. Clique em "Run"

**Opção B: Via CLI**
```bash
supabase db push
```

**Verificar se funcionou:**
```sql
-- Execute no SQL Editor
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'merchant_payment_credentials';

-- Deve mostrar a coluna 'store_id'
```

---

### ✅ Passo 2: Atualizar Edge Function

A Edge Function já foi atualizada no código. Faça o deploy:

**Opção A: Via Dashboard**
1. Dashboard → Edge Functions → `create-pix-payment`
2. Cole o código atualizado de: `supabase/functions/create-pix-payment/index.ts`
3. Clique em "Deploy"

**Opção B: Via CLI**
```bash
supabase functions deploy create-pix-payment
```

---

### ✅ Passo 3: Configurar Credenciais da Loja

Cada lojista deve configurar suas próprias credenciais:

1. **Obter credenciais do Mercado Pago:**
   - Acesse: https://www.mercadopago.com.br/developers/panel
   - Faça login
   - Vá em "Suas integrações" → "Credenciais"
   - Copie a Public Key e o Access Token

2. **Configurar no sistema:**
   - Acesse o painel admin da loja
   - Vá em **Configurações** → **Pagamentos**
   - Insira as credenciais
   - Clique em **Salvar**

---

## 🧪 Testar o Sistema

### Teste 1: Verificar se credenciais foram salvas

```sql
-- Execute no SQL Editor do Supabase
SELECT 
  s.name AS loja,
  s.slug,
  mpc.public_key,
  mpc.is_active,
  mpc.created_at
FROM merchant_payment_credentials mpc
JOIN stores s ON s.id = mpc.store_id
WHERE mpc.is_active = true;
```

**Resultado esperado:** Deve mostrar as lojas com credenciais configuradas.

---

### Teste 2: Criar pagamento de teste

No console do navegador (F12), na página pública da loja:

```javascript
// Teste criar pagamento PIX
const response = await supabase.functions.invoke('create-pix-payment', {
  body: {
    storeSlug: 'minha-loja',  // Substitua pelo slug da sua loja
    amount: 10.00,
    customerName: 'Teste',
    description: 'Pedido teste'
  }
});

console.log(response);
```

**Resultado esperado:**
```json
{
  "success": true,
  "data": {
    "id": "123456789",
    "status": "pending",
    "qr_code": "00020126580014br.gov.bcb.pix..."
  }
}
```

---

### Teste 3: Verificar isolamento entre lojas

Se você tem múltiplas lojas, teste que cada uma usa suas próprias credenciais:

```sql
-- Criar 2 lojas de teste
INSERT INTO stores (owner_id, name, slug, is_active)
VALUES 
  ('seu-user-id', 'Loja A', 'loja-a', true),
  ('seu-user-id', 'Loja B', 'loja-b', true);

-- Configurar credenciais diferentes para cada loja
INSERT INTO merchant_payment_credentials (user_id, store_id, public_key, access_token, is_active)
VALUES 
  ('seu-user-id', 'store-a-id', 'KEY_A', 'TOKEN_A', true),
  ('seu-user-id', 'store-b-id', 'KEY_B', 'TOKEN_B', true);

-- Verificar que cada loja tem suas credenciais
SELECT s.name, mpc.public_key 
FROM merchant_payment_credentials mpc
JOIN stores s ON s.id = mpc.store_id;
```

---

## 🔧 Atualizar Componentes (Se Necessário)

### Componente de Checkout

Se você tem um componente de checkout customizado, atualize para passar o `storeSlug`:

```typescript
// Antes
const response = await supabase.functions.invoke('create-pix-payment', {
  body: {
    amount: total
  }
});

// Depois
const response = await supabase.functions.invoke('create-pix-payment', {
  body: {
    storeSlug: currentStore.slug,  // ✅ Adicione isso
    amount: total,
    customerName: customerName,
    description: `Pedido #${orderId}`
  }
});
```

### Página Pública da Loja

Carregue as credenciais quando a página abrir:

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
    return (
      <Alert>
        <AlertCircle className="h-4 w-4" />
        <AlertDescription>
          Esta loja ainda não configurou pagamentos. 
          Entre em contato com o vendedor.
        </AlertDescription>
      </Alert>
    );
  }
  
  return <div>Loja pronta para receber pagamentos!</div>;
};
```

---

## 🐛 Problemas Comuns

### ❌ Erro: "column 'store_id' does not exist"

**Causa:** Migration não foi executada

**Solução:**
```bash
# Execute a migration
supabase db push

# Ou execute manualmente no SQL Editor
ALTER TABLE merchant_payment_credentials 
ADD COLUMN store_id UUID REFERENCES stores(id);
```

---

### ❌ Erro: "Store ID não fornecido"

**Causa:** Requisição não incluiu `storeId` ou `storeSlug`

**Solução:** Sempre passe o slug da loja:
```typescript
await supabase.functions.invoke('create-pix-payment', {
  body: {
    storeSlug: 'minha-loja',  // ✅ Obrigatório
    amount: 100
  }
});
```

---

### ❌ Erro: "Credenciais não encontradas"

**Causa:** Loja não tem credenciais configuradas

**Solução:**
1. Acesse o painel admin
2. Vá em Configurações → Pagamentos
3. Configure as credenciais do Mercado Pago
4. Salve

**Verificar no banco:**
```sql
SELECT * FROM merchant_payment_credentials 
WHERE store_id = 'seu-store-id' AND is_active = true;
```

---

### ❌ Credenciais não salvam

**Causa:** RLS bloqueando ou loja não existe

**Solução:**
```sql
-- Verificar se a loja existe
SELECT * FROM stores WHERE id = 'seu-store-id';

-- Verificar RLS policies
SELECT * FROM pg_policies 
WHERE tablename = 'merchant_payment_credentials';

-- Desabilitar RLS temporariamente (apenas para debug)
ALTER TABLE merchant_payment_credentials DISABLE ROW LEVEL SECURITY;
-- Tente salvar novamente
-- Depois reabilite:
ALTER TABLE merchant_payment_credentials ENABLE ROW LEVEL SECURITY;
```

---

## 📊 Monitoramento

### Ver todas as lojas configuradas

```sql
SELECT 
  s.name AS loja,
  s.slug,
  s.owner_id,
  mpc.environment,
  mpc.created_at AS configurado_em
FROM merchant_payment_credentials mpc
JOIN stores s ON s.id = mpc.store_id
WHERE mpc.is_active = true
ORDER BY mpc.created_at DESC;
```

### Ver pagamentos por loja

```sql
SELECT 
  s.name AS loja,
  COUNT(o.id) AS total_pedidos,
  SUM(o.total) AS total_vendas
FROM orders o
JOIN stores s ON s.id = o.store_id
WHERE o.created_at >= NOW() - INTERVAL '30 days'
GROUP BY s.id, s.name
ORDER BY total_vendas DESC;
```

---

## ✅ Checklist Final

Antes de ir para produção, verifique:

- [ ] Migration executada com sucesso
- [ ] Edge Function atualizada e deployada
- [ ] Credenciais de teste configuradas
- [ ] Pagamento de teste criado com sucesso
- [ ] QR Code PIX aparece corretamente
- [ ] Múltiplas lojas isoladas (se aplicável)
- [ ] RLS policies funcionando
- [ ] Logs da Edge Function sem erros
- [ ] Documentação lida e compreendida

---

## 🎉 Pronto!

Seu sistema agora suporta **múltiplas lojas com credenciais independentes**!

**Próximos passos:**
1. Configure credenciais de produção do Mercado Pago
2. Teste com pagamentos reais (valores baixos)
3. Configure webhooks para confirmação automática
4. Monitore os logs para garantir que tudo funciona

**Dúvidas?** Consulte a documentação completa em `MERCADOPAGO_MULTI_TENANT.md`
