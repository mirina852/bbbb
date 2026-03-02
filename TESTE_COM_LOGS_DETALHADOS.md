# 🔍 Teste com Logs Detalhados - PIX

## 📊 Logs Adicionados

Adicionei logs detalhados no `MercadoPagoContext` para rastrear exatamente o que acontece quando as credenciais são carregadas.

## 🧪 Como Testar

### 1. Abra em Aba Anônima
- Pressione **Ctrl+Shift+N**
- Acesse sua loja pelo slug

### 2. Abra o Console (F12)
- Clique em **Console**
- Limpe o console (ícone 🚫 ou Ctrl+L)

### 3. Recarregue a Página (F5)

### 4. Procure pelos Logs

## ✅ Logs Esperados (SUCESSO)

Se tudo estiver funcionando, você verá:

```
🔑 Carregando credenciais do Mercado Pago para loja: edefa921-0c5e-48f9-886d-4ccb105ffedf
🔍 MercadoPagoContext.loadConfig - Iniciando...
🔍 storeId recebido: edefa921-0c5e-48f9-886d-4ccb105ffedf
🔍 Usuário autenticado? false
🔍 Buscando credenciais para store_id: edefa921-0c5e-48f9-886d-4ccb105ffedf
🔍 Dados retornados: SIM
✅ Credenciais encontradas!
✅ Public Key: PRESENTE
✅ Access Token: PRESENTE
✅ Credenciais válidas? true
🔍 CheckoutForm - PIX configurado? true
🔍 CheckoutForm - Config: {publicKey: "APP_USR-...", accessToken: ""}
```

## ❌ Logs de Erro (PROBLEMA)

Se houver problema, você verá um destes erros:

### Erro 1: Store ID não passado
```
🔑 Carregando credenciais do Mercado Pago para loja: undefined
🔍 MercadoPagoContext.loadConfig - Iniciando...
🔍 storeId recebido: undefined
🔍 Usuário autenticado? false
❌ Nenhum store_id disponível para carregar credenciais
```

**Solução:** O `StoreSlug.tsx` não está passando o `store_id` corretamente.

### Erro 2: Credenciais não encontradas
```
🔍 Buscando credenciais para store_id: edefa921-0c5e-48f9-886d-4ccb105ffedf
🔍 Dados retornados: NÃO
❌ Nenhuma credencial encontrada no banco
```

**Solução:** Verifique se há credenciais ativas no banco:
```sql
SELECT * FROM merchant_payment_credentials 
WHERE store_id = 'edefa921-0c5e-48f9-886d-4ccb105ffedf' 
AND is_active = true;
```

### Erro 3: Erro de permissão RLS
```
❌ Erro ao buscar credenciais: {code: "42501", message: "..."}
❌ Detalhes do erro: {
  code: "42501",
  message: "new row violates row-level security policy",
  ...
}
```

**Solução:** As políticas RLS não estão permitindo acesso anônimo. Execute novamente:
```sql
CREATE POLICY "Anonymous users can view active credentials"
  ON public.merchant_payment_credentials
  FOR SELECT
  TO anon
  USING (is_active = true);
```

### Erro 4: Access Token ausente
```
✅ Credenciais encontradas!
✅ Public Key: PRESENTE
✅ Access Token: AUSENTE
✅ Credenciais válidas? false
```

**Solução:** O `access_token` não está salvo no banco. Salve novamente no admin.

## 🔍 Análise dos Logs

### Campos Importantes:

1. **storeId recebido** - Deve ser o UUID da loja
2. **Usuário autenticado?** - Deve ser `false` para clientes
3. **Dados retornados** - Deve ser `SIM`
4. **Public Key** - Deve ser `PRESENTE`
5. **Access Token** - Deve ser `PRESENTE`
6. **Credenciais válidas?** - Deve ser `true`
7. **PIX configurado?** - Deve ser `true`

## 📋 Checklist de Verificação

Baseado nos logs, verifique:

- [ ] `storeId recebido` não é `undefined`
- [ ] `Dados retornados: SIM`
- [ ] `Public Key: PRESENTE`
- [ ] `Access Token: PRESENTE`
- [ ] `Credenciais válidas? true`
- [ ] `PIX configurado? true`

## 🐛 Troubleshooting por Log

### Se `storeId recebido: undefined`
**Problema:** `StoreSlug.tsx` não está passando o store_id

**Verificar:**
```typescript
// Em StoreSlug.tsx, linha ~77
loadMercadoPagoCredentials(currentStore.id);
```

### Se `Dados retornados: NÃO`
**Problema:** Não há credenciais no banco ou RLS está bloqueando

**Verificar no Supabase:**
```sql
-- Como admin (authenticated)
SELECT * FROM merchant_payment_credentials 
WHERE store_id = 'edefa921-0c5e-48f9-886d-4ccb105ffedf';

-- Verificar políticas RLS
SELECT policyname, roles 
FROM pg_policies 
WHERE tablename = 'merchant_payment_credentials';
```

### Se `Access Token: AUSENTE`
**Problema:** Token não foi salvo

**Solução:**
1. Vá para `/admin/settings?tab=payment`
2. Cole novamente o Access Token
3. Clique em Salvar

## 📱 Teste no Celular

Depois que funcionar na aba anônima:

1. Descubra seu IP: `ipconfig` (Windows)
2. No celular: `http://[SEU_IP]:5173/[slug]`
3. Verifique se PIX aparece

## 🎯 Resultado Final

Quando tudo estiver funcionando:

```
✅ Credenciais válidas? true
🔍 CheckoutForm - PIX configurado? true
```

E no checkout:
- ✅ PIX aparece **disponível**
- ✅ Mensagem: "Pagamento imediato"
- ❌ NÃO aparece: "Indisponível no momento"

---

**Teste agora e me envie os logs completos do console!** 🚀
