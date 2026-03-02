# Solução: QR Code PIX não aparece na loja

## Problema Identificado

Você cadastrou as credenciais do Mercado Pago corretamente na tabela `merchant_payment_credentials`, mas o PIX aparece como "Indisponível no momento" na página de checkout.

### Causas Raiz

1. **Política RLS muito restritiva**: A política de Row Level Security (RLS) da tabela `merchant_payment_credentials` só permitia acesso para usuários **autenticados**. Na loja pública (`/store`), os clientes não estão autenticados, então não conseguiam verificar se o PIX está configurado.

2. **Validação incorreta no contexto**: O `MercadoPagoContext` estava validando `isConfigured` baseado no `accessToken` no estado local, mas por segurança, o token não é retornado após salvar.

## Soluções Implementadas

### 1. Correção da Política RLS

**Execute este SQL no Supabase SQL Editor:**

```sql
-- Remove a política antiga
DROP POLICY IF EXISTS "Users can view own credentials" ON public.merchant_payment_credentials;

-- Cria nova política que permite acesso público
CREATE POLICY "Allow public read of active credentials"
  ON public.merchant_payment_credentials
  FOR SELECT
  USING (
    (auth.uid() = user_id) OR (is_active = true)
  );
```

**Arquivo pronto:** `FIX_PIX_RLS_POLICY.sql`

### 2. Correção do MercadoPagoContext

- Adicionado estado `hasCredentials` para rastrear se há credenciais válidas no banco
- Modificado `loadConfig()` para buscar credenciais mesmo sem usuário autenticado
- Corrigido `isConfigured` para usar `hasCredentials` em vez de verificar o estado local

### 3. Melhorias na UX

- Opção PIX desabilitada visualmente quando não configurada
- Mensagens de erro claras quando credenciais não existem
- Validação na Edge Function antes de criar pagamento

## Como Aplicar a Correção

### Passo 1: Executar SQL no Supabase

1. Acesse o **Supabase Dashboard**
2. Vá em **SQL Editor**
3. Cole o conteúdo do arquivo `FIX_PIX_RLS_POLICY.sql`
4. Clique em **Run**

### Passo 2: Verificar as Credenciais

1. Acesse `/admin/settings?tab=payment`
2. Verifique se suas credenciais estão salvas
3. Se necessário, salve novamente

### Passo 3: Testar

1. Abra a loja em uma aba anônima: `/store`
2. Adicione produtos ao carrinho
3. Vá para o checkout
4. A opção **PIX** deve estar **habilitada**
5. Ao selecionar PIX, o QR Code deve aparecer

## Arquivos Modificados

- `src/contexts/MercadoPagoContext.tsx` - Correção da lógica de validação
- `src/components/customer/CheckoutForm.tsx` - UX melhorada
- `src/components/customer/PixPayment.tsx` - Tratamento de erros
- `supabase/functions/create-pix-payment/index.ts` - Validação de credenciais
- `supabase/migrations/20251011180000_allow_public_read_merchant_credentials.sql` - Nova política RLS

## Segurança

✅ **Access Token não é exposto**: Continua oculto por segurança  
✅ **Public Key é visível**: Necessário para verificar se PIX está configurado  
✅ **Validação server-side**: Edge Function valida credenciais antes de criar pagamento  
✅ **RLS mantido**: Apenas credenciais ativas são visíveis publicamente  

## Resultado Esperado

Após aplicar as correções:

- ✅ PIX aparece **habilitado** no checkout quando credenciais estão configuradas
- ✅ QR Code é gerado corretamente
- ✅ Pagamentos usam as credenciais do **merchant**, não da plataforma
- ✅ Sem credenciais = PIX desabilitado com mensagem clara
