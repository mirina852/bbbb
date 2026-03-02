# ✅ Correção Final - PIX no Celular

## 🎯 Problema Resolvido

O PIX não aparecia para usuários não autenticados porque:

1. ❌ As políticas RLS não permitiam acesso anônimo
2. ❌ O código só carregava credenciais em `/store`, mas não em `/:slug`
3. ❌ O `MercadoPagoContext` resetava credenciais quando não havia usuário

## ✅ Correções Aplicadas

### 1. Políticas RLS (Banco de Dados)
```sql
-- Permite usuários anônimos verem credenciais ativas
CREATE POLICY "Anonymous users can view active credentials"
  ON public.merchant_payment_credentials
  FOR SELECT
  TO anon
  USING (is_active = true);
```

### 2. StoreSlug.tsx (Página Principal)
- ✅ Importado `useMercadoPago`
- ✅ Adicionada função `loadMercadoPagoCredentials()`
- ✅ Carrega credenciais quando a loja é carregada

### 3. StoreFront.tsx (Página /store)
- ✅ Carrega credenciais da primeira loja ativa

### 4. MercadoPagoContext.tsx
- ✅ Não reseta credenciais quando não há usuário autenticado

### 5. CheckoutForm.tsx
- ✅ Logs de debug para verificar estado do PIX

## 🧪 Como Testar AGORA

### Teste 1: Aba Anônima

1. **Abra aba anônima** (Ctrl+Shift+N)
2. **Acesse sua loja** pelo slug: `http://localhost:5173/[seu-slug]`
   - Exemplo: `http://localhost:5173/hamburgueria`
3. **Abra o Console** (F12)
4. **Procure por:**
   ```
   🔑 Carregando credenciais do Mercado Pago para loja: edefa921-0c5e-48f9-886d-4ccb105ffedf
   🔍 CheckoutForm - PIX configurado? true
   ```
5. **Adicione produtos** ao carrinho
6. **Vá para o checkout**
7. **PIX deve aparecer disponível** ✅

### Teste 2: Celular

1. **Descubra seu IP local:**
   - Windows: `ipconfig` (procure IPv4)
   - Exemplo: `192.168.1.100`

2. **No celular, acesse:**
   - `http://192.168.1.100:5173/[seu-slug]`
   - Exemplo: `http://192.168.1.100:5173/hamburgueria`

3. **Adicione produtos e vá para checkout**
4. **PIX deve aparecer disponível** ✅

## 🔍 Logs Esperados

### ✅ Sucesso:
```
🔑 Carregando credenciais do Mercado Pago para loja: edefa921-0c5e-48f9-886d-4ccb105ffedf
🔍 CheckoutForm - PIX configurado? true
🔍 CheckoutForm - Config: {publicKey: "APP_USR-...", accessToken: ""}
```

### ❌ Erro (se ainda acontecer):
```
❌ Erro ao carregar credenciais do Mercado Pago: [erro]
🔍 CheckoutForm - PIX configurado? false
🔍 CheckoutForm - Config: null
```

## 📊 Verificação no Banco

### 1. Verificar Políticas RLS
```sql
SELECT 
  policyname,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'merchant_payment_credentials'
ORDER BY policyname;
```

**Deve retornar:**
- `Anonymous users can view active credentials` (roles: {anon})
- `Authenticated users can view own store credentials` (roles: {authenticated})

### 2. Verificar Credenciais Ativas
```sql
SELECT 
  id,
  store_id,
  public_key,
  is_active
FROM public.merchant_payment_credentials
WHERE is_active = true;
```

**Deve retornar:**
- Store ID: `edefa921-0c5e-48f9-886d-4ccb105ffedf`
- Public Key: `APP_USR-f4ce3055-8ee6-4b1f-a0a3-bab554409cc7`
- is_active: `true`

### 3. Verificar Loja Ativa
```sql
SELECT 
  id,
  name,
  slug,
  is_active
FROM public.stores
WHERE id = 'edefa921-0c5e-48f9-886d-4ccb105ffedf';
```

**Deve retornar:**
- is_active: `true`

## 🐛 Troubleshooting

### PIX ainda não aparece

**1. Limpe o cache do navegador:**
- Ctrl+Shift+Delete
- Selecione "Imagens e arquivos em cache"
- Clique em "Limpar dados"

**2. Verifique os logs do console:**
- Procure por mensagens de erro
- Verifique se `isPixConfigured` é `true`

**3. Verifique se a loja está ativa:**
```sql
UPDATE public.stores 
SET is_active = true 
WHERE id = 'edefa921-0c5e-48f9-886d-4ccb105ffedf';
```

**4. Verifique se as credenciais estão ativas:**
```sql
UPDATE public.merchant_payment_credentials 
SET is_active = true 
WHERE store_id = 'edefa921-0c5e-48f9-886d-4ccb105ffedf';
```

## 📱 Teste em Produção

Se estiver testando em produção:

1. **Não use credenciais de teste!**
2. Use credenciais de **produção** do Mercado Pago
3. Teste com valores pequenos primeiro
4. Verifique se os webhooks estão configurados

## ✅ Checklist Final

- [x] SQL executado no Supabase
- [x] Políticas RLS verificadas
- [x] Credenciais ativas no banco
- [x] Loja ativa no banco
- [x] StoreSlug.tsx atualizado
- [x] StoreFront.tsx atualizado
- [x] MercadoPagoContext.tsx atualizado
- [x] CheckoutForm.tsx com logs
- [ ] Testado em aba anônima
- [ ] PIX aparece disponível
- [ ] Testado no celular

## 🎉 Resultado Esperado

Após todas as correções:

- ✅ PIX aparece **disponível** para usuários não autenticados
- ✅ PIX aparece **disponível** no celular
- ✅ Mensagem "Pagamento imediato" em vez de "Indisponível no momento"
- ✅ QR Code é gerado corretamente
- ✅ Pagamento funciona normalmente

---

**Teste agora e me avise o resultado! 🚀**

Se ainda não funcionar, envie os logs do console (F12) que eu ajudo a identificar o problema.
