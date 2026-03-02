# Configuração do Mercado Pago - Instruções

## 📋 O que foi implementado

Agora as credenciais do Mercado Pago são salvas de forma segura no Supabase, ao invés do localStorage.

### Arquivos Modificados/Criados:

1. **Migration criada**: `supabase/migrations/20251010145200_create_merchant_payment_credentials.sql`
2. **Tipos atualizados**: `src/integrations/supabase/types.ts`
3. **Contexto atualizado**: `src/contexts/MercadoPagoContext.tsx`

---

## 🚀 Como aplicar a migration no Supabase

### Opção 1: Via Supabase Dashboard (Recomendado)

1. Acesse seu projeto no [Supabase Dashboard](https://supabase.com/dashboard)
2. Vá em **Database** → **SQL Editor**
3. Clique em **New Query**
4. Copie e cole o conteúdo do arquivo:
   ```
   supabase/migrations/20251010145200_create_merchant_payment_credentials.sql
   ```
5. Clique em **Run** para executar

### Opção 2: Via CLI do Supabase

```bash
# Se você tem o Supabase CLI instalado
supabase db push
```

---

## 🔐 Estrutura da Tabela Criada

**Tabela**: `merchant_payment_credentials`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | UUID | ID único |
| `user_id` | UUID | ID do usuário (FK para auth.users) |
| `public_key` | TEXT | Public Key do Mercado Pago |
| `access_token` | TEXT | Access Token do Mercado Pago |
| `environment` | TEXT | 'sandbox' ou 'production' |
| `is_active` | BOOLEAN | Se a credencial está ativa |
| `created_at` | TIMESTAMPTZ | Data de criação |
| `updated_at` | TIMESTAMPTZ | Data de atualização |

### Políticas RLS (Row Level Security)

✅ Usuários podem ver apenas suas próprias credenciais
✅ Usuários podem inserir/atualizar/deletar apenas suas próprias credenciais
✅ Credenciais são isoladas por usuário

---

## 📝 Como Funciona

1. **Ao salvar credenciais**:
   - Desativa todas as credenciais antigas do usuário
   - Insere nova credencial como ativa
   - Mantém histórico de credenciais antigas

2. **Ao carregar credenciais**:
   - Busca apenas a credencial ativa mais recente do usuário
   - Carrega automaticamente quando o usuário faz login

3. **Segurança**:
   - RLS habilitado (cada usuário vê apenas suas credenciais)
   - Access Token armazenado de forma segura no Supabase
   - Não expõe credenciais de outros usuários

---

## ✅ Testando

1. Faça login na aplicação
2. Vá para **Pagamentos** → **Configuração do Mercado Pago**
3. Insira suas credenciais:
   - **Public Key**: `APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - **Access Token**: `APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
4. Clique em **Salvar Configurações**
5. Verifique no Supabase Dashboard:
   - Vá em **Database** → **Table Editor**
   - Selecione a tabela `merchant_payment_credentials`
   - Veja suas credenciais salvas

---

## 🔧 Próximos Passos (Opcional)

### Criptografia Adicional

Para maior segurança, você pode criptografar o `access_token` antes de salvar:

```typescript
// Exemplo usando crypto-js
import CryptoJS from 'crypto-js';

const encryptToken = (token: string) => {
  return CryptoJS.AES.encrypt(token, 'sua-chave-secreta').toString();
};

const decryptToken = (encryptedToken: string) => {
  const bytes = CryptoJS.AES.decrypt(encryptedToken, 'sua-chave-secreta');
  return bytes.toString(CryptoJS.enc.Utf8);
};
```

### Validação de Credenciais

Adicionar validação para verificar se as credenciais são válidas antes de salvar:

```typescript
const validateCredentials = async (publicKey: string, accessToken: string) => {
  try {
    const response = await fetch('https://api.mercadopago.com/v1/payment_methods', {
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    });
    return response.ok;
  } catch {
    return false;
  }
};
```

---

## 📞 Suporte

Se tiver problemas:
1. Verifique se a migration foi aplicada corretamente
2. Verifique se o usuário está autenticado
3. Verifique as políticas RLS no Supabase
4. Veja os logs do console do navegador

---

## ✨ Benefícios

✅ **Seguro**: Credenciais protegidas por RLS
✅ **Multi-usuário**: Cada usuário tem suas próprias credenciais
✅ **Histórico**: Mantém registro de credenciais antigas
✅ **Sincronizado**: Funciona em qualquer dispositivo
✅ **Backup**: Dados salvos no Supabase (não se perde ao limpar cache)
