# 🔧 Erro ao Salvar Token do Mercado Pago

## ⚠️ Erro

```
Erro ao salvar
Não foi possível salvar as credenciais. Tente novamente.
```

---

## 🔍 Diagnóstico

### Passo 1: Abrir Console do Navegador

1. Pressione **F12**
2. Vá na aba **Console**
3. Tente salvar as credenciais novamente
4. Veja os logs de erro

---

## 🎯 Possíveis Causas e Soluções

### Causa 1: Migration Não Executada ❌

**Sintoma no console:**
```
Erro ao salvar credenciais: {message: "relation 'merchant_payment_credentials' does not exist"}
```

**Solução:**
Execute a migration `20251010145200_create_merchant_payment_credentials.sql`:

```sql
-- Cole no SQL Editor do Supabase
CREATE TABLE IF NOT EXISTS public.merchant_payment_credentials (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  public_key TEXT NOT NULL,
  access_token TEXT NOT NULL,
  environment TEXT NOT NULL DEFAULT 'production' CHECK (environment IN ('sandbox', 'production')),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS merchant_payment_credentials_user_id_idx 
  ON public.merchant_payment_credentials(user_id);

CREATE INDEX IF NOT EXISTS merchant_payment_credentials_active_idx 
  ON public.merchant_payment_credentials(is_active);

-- Enable RLS
ALTER TABLE public.merchant_payment_credentials ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own credentials"
  ON public.merchant_payment_credentials
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own credentials"
  ON public.merchant_payment_credentials
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own credentials"
  ON public.merchant_payment_credentials
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own credentials"
  ON public.merchant_payment_credentials
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
```

---

### Causa 2: Função `update_updated_at_column()` Não Existe ❌

**Sintoma no console:**
```
Erro ao salvar credenciais: {message: "function update_updated_at_column() does not exist"}
```

**Solução:**
Crie a função no Supabase:

```sql
-- Criar função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Adicionar trigger na tabela
CREATE TRIGGER update_merchant_payment_credentials_updated_at
  BEFORE UPDATE ON public.merchant_payment_credentials
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
```

---

### Causa 3: Usuário Sem Assinatura Ativa ❌

**Sintoma no console:**
```
Erro ao salvar credenciais: {message: "new row violates row-level security policy"}
```

**Explicação:**
O formulário deveria estar bloqueado, mas pode haver um bug na verificação.

**Solução:**
1. Verifique se você tem uma assinatura ativa:
   ```sql
   SELECT * FROM public.user_subscriptions 
   WHERE user_id = 'seu-user-id' 
   AND status = 'active' 
   AND expires_at > NOW();
   ```

2. Se não tiver, ative o teste gratuito primeiro:
   - Vá em `/planos`
   - Clique em "Iniciar Teste Gratuito"

---

### Causa 4: Token Inválido ou Vazio ❌

**Sintoma:**
Campos vazios ou token incompleto

**Solução:**
1. Verifique se preencheu ambos os campos:
   - Public Key (começa com `APP_USR-`)
   - Access Token (começa com `APP_USR-`)

2. Copie novamente do Mercado Pago Developers:
   - https://www.mercadopago.com.br/developers/panel
   - Suas integrações → Credenciais

---

## 🧪 Teste Manual

### Verificar se a Tabela Existe

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'merchant_payment_credentials';
```

**Resultado esperado:** 1 linha com `merchant_payment_credentials`

---

### Verificar Estrutura da Tabela

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'merchant_payment_credentials'
ORDER BY ordinal_position;
```

**Colunas esperadas:**
- id (uuid)
- user_id (uuid)
- public_key (text)
- access_token (text)
- environment (text)
- is_active (boolean)
- created_at (timestamp)
- updated_at (timestamp)

---

### Verificar Políticas RLS

```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'merchant_payment_credentials';
```

**Políticas esperadas:**
- Users can view own credentials (SELECT)
- Users can insert own credentials (INSERT)
- Users can update own credentials (UPDATE)
- Users can delete own credentials (DELETE)

---

### Testar Insert Manual

```sql
-- Substitua 'seu-user-id' pelo seu ID real
INSERT INTO public.merchant_payment_credentials (
  user_id,
  public_key,
  access_token,
  environment,
  is_active
) VALUES (
  'seu-user-id',
  'APP_USR-test-public-key',
  'APP_USR-test-access-token',
  'production',
  true
);
```

Se der erro, copie a mensagem completa.

---

## 📋 Checklist de Verificação

- [ ] Tabela `merchant_payment_credentials` existe
- [ ] Função `update_updated_at_column()` existe
- [ ] Políticas RLS estão ativas
- [ ] Usuário tem assinatura ativa
- [ ] Tokens do Mercado Pago são válidos
- [ ] Console do navegador mostra erro detalhado

---

## 🎯 Logs Esperados (Sucesso)

Quando funcionar corretamente:

**Console do navegador:**
```
Credenciais do Mercado Pago salvas com sucesso.
```

**Toast verde:**
```
Sucesso!
Credenciais do Mercado Pago salvas com sucesso.
```

**Banco de dados:**
```sql
SELECT * FROM public.merchant_payment_credentials 
WHERE user_id = 'seu-user-id' 
ORDER BY created_at DESC 
LIMIT 1;
```

Deve mostrar o registro inserido.

---

## 🆘 Ainda com Erro?

Se após seguir todos os passos ainda houver erro:

1. **Abra o console (F12)**
2. **Tente salvar novamente**
3. **Copie os logs completos:**
   ```
   Erro ao salvar credenciais: {...}
   Detalhes do erro: {...}
   ```
4. **Tire um print** da tela
5. **Compartilhe** para análise

Os logs detalhados vão mostrar exatamente qual é o problema! 🔍

---

## 💡 Dica

Agora o sistema mostra mensagens de erro mais específicas:

- ✅ "Tabela não encontrada. Execute a migration primeiro."
- ✅ "Você não tem permissão. Verifique se tem uma assinatura ativa."
- ✅ "Erro de configuração do banco. Entre em contato com o suporte."

Isso facilita identificar o problema rapidamente!
