# 🧪 Como Testar o PIX no Celular

## ✅ Correções Aplicadas

1. **Políticas RLS atualizadas** - Usuários anônimos podem ver credenciais ativas
2. **StoreFront.tsx modificado** - Carrega credenciais da primeira loja ativa
3. **MercadoPagoContext.tsx ajustado** - Não reseta credenciais quando não há usuário
4. **CheckoutForm.tsx com debug** - Logs para verificar estado do PIX

## 🔍 Como Testar

### Opção 1: Aba Anônima (Mais Rápido)

1. Abra o navegador
2. Pressione **Ctrl+Shift+N** (Chrome) ou **Ctrl+Shift+P** (Firefox)
3. Acesse: `http://localhost:5173/store` (ou sua URL)
4. Abra o **Console** (F12)
5. Procure por estas mensagens:
   ```
   🔑 Carregando credenciais do Mercado Pago para loja: [store_id]
   🔍 CheckoutForm - PIX configurado? true
   ```
6. Adicione produtos ao carrinho
7. Vá para o checkout
8. **Verifique se PIX aparece disponível**

### Opção 2: Celular (Teste Real)

1. Certifique-se que o celular está na **mesma rede WiFi**
2. No computador, descubra seu IP local:
   - Windows: `ipconfig` (procure por IPv4)
   - Mac/Linux: `ifconfig` (procure por inet)
3. No celular, acesse: `http://[SEU_IP]:5173/store`
   - Exemplo: `http://192.168.1.100:5173/store`
4. Adicione produtos ao carrinho
5. Vá para o checkout
6. **Verifique se PIX aparece disponível**

## 🐛 Debug - O que Verificar

### 1. Console do Navegador (F12)

Procure por estas mensagens:

✅ **Sucesso:**
```
🔑 Carregando credenciais do Mercado Pago para loja: edefa921-0c5e-48f9-886d-4ccb105ffedf
🔍 CheckoutForm - PIX configurado? true
🔍 CheckoutForm - Config: {publicKey: "APP_USR-...", accessToken: ""}
```

❌ **Erro:**
```
⚠️ Nenhuma loja ativa encontrada
🔍 CheckoutForm - PIX configurado? false
🔍 CheckoutForm - Config: null
```

### 2. Verificar Políticas RLS no Supabase

Execute este SQL no Supabase SQL Editor:

```sql
SELECT 
  policyname,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'merchant_payment_credentials'
ORDER BY policyname;
```

Deve retornar:
- `Anonymous users can view active credentials` (roles: {anon})
- `Authenticated users can view own store credentials` (roles: {authenticated})

### 3. Verificar Credenciais Ativas

```sql
SELECT 
  id,
  store_id,
  public_key,
  is_active
FROM public.merchant_payment_credentials
WHERE is_active = true;
```

Deve retornar pelo menos 1 linha.

## ❓ Problemas Comuns

### PIX ainda não aparece

**Causa:** Credenciais não foram carregadas

**Solução:**
1. Verifique os logs do console
2. Confirme que há uma loja ativa no banco
3. Confirme que há credenciais ativas
4. Limpe o cache do navegador (Ctrl+Shift+Delete)

### Erro: "Nenhuma loja ativa encontrada"

**Causa:** Não há lojas com `is_active = true`

**Solução:**
```sql
UPDATE public.stores 
SET is_active = true 
WHERE id = 'edefa921-0c5e-48f9-886d-4ccb105ffedf';
```

### Erro de permissão no console

**Causa:** Políticas RLS não foram aplicadas

**Solução:**
1. Execute novamente o SQL do arquivo `FIX_PIX_PUBLIC_ACCESS.sql`
2. Verifique se as políticas foram criadas

## 📱 Teste em Produção

Se estiver testando em produção (site publicado):

1. Acesse o site em aba anônima
2. Ou peça para alguém acessar pelo celular
3. Verifique se PIX aparece
4. **Não use credenciais de teste em produção!**

## ✅ Checklist Final

- [ ] SQL executado no Supabase
- [ ] Políticas RLS verificadas
- [ ] Credenciais ativas no banco
- [ ] Loja ativa no banco
- [ ] Código atualizado (StoreFront.tsx, MercadoPagoContext.tsx)
- [ ] Testado em aba anônima
- [ ] PIX aparece disponível
- [ ] Logs do console sem erros

## 🎉 Sucesso!

Se tudo estiver funcionando:
- ✅ PIX aparece para usuários não autenticados
- ✅ PIX aparece no celular
- ✅ Mensagem "Pagamento imediato" em vez de "Indisponível no momento"

---

**Qualquer dúvida, verifique os logs do console e me envie!** 🚀
