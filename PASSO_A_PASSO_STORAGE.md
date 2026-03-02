# 📦 Passo a Passo: Configurar Storage no Supabase

## 🎯 Objetivo
Criar o bucket `site-assets` e configurar as permissões para upload de imagens.

---

## 📋 PASSO 1: Criar o Bucket

1. Acesse o **Supabase Dashboard**: https://app.supabase.com
2. Selecione seu projeto
3. No menu lateral, clique em **Storage**
4. Clique no botão **New Bucket** (canto superior direito)
5. Preencha:
   ```
   Name: site-assets
   Public bucket: ✅ ATIVAR (muito importante!)
   File size limit: 50 MB
   Allowed MIME types: (deixe vazio)
   ```
6. Clique em **Create Bucket**

---

## 📋 PASSO 2: Criar Policies (Via SQL - Mais Rápido)

1. No menu lateral, clique em **SQL Editor**
2. Clique em **New Query**
3. Cole o conteúdo do arquivo `CRIAR_STORAGE_POLICIES.sql`:

```sql
-- 1. Policy para permitir upload (INSERT)
CREATE POLICY "Authenticated users can upload to site-assets"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'site-assets');

-- 2. Policy para permitir leitura pública (SELECT)
CREATE POLICY "Public read access to site-assets"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'site-assets');

-- 3. Policy para permitir update
CREATE POLICY "Authenticated users can update site-assets"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'site-assets')
WITH CHECK (bucket_id = 'site-assets');

-- 4. Policy para permitir delete
CREATE POLICY "Authenticated users can delete from site-assets"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'site-assets');
```

4. Clique em **Run** (ou pressione Ctrl+Enter)
5. Verifique se apareceu "Success. No rows returned"

---

## 📋 PASSO 3: Verificar Configuração

Execute este SQL para confirmar:

```sql
-- Verificar se o bucket existe e está público
SELECT name, public FROM storage.buckets WHERE name = 'site-assets';
-- Deve retornar: site-assets | true

-- Verificar se as 4 policies foram criadas
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND (qual LIKE '%site-assets%' OR with_check LIKE '%site-assets%')
ORDER BY cmd;
-- Deve retornar 4 linhas (DELETE, INSERT, SELECT, UPDATE)
```

---

## 📋 PASSO 4: Testar Upload

1. Acesse sua aplicação
2. Faça login como admin
3. Vá em **Settings** > **Personalização**
4. Tente fazer upload de uma imagem (logo ou background)
5. Se funcionar, você verá a imagem aparecer!

---

## ✅ Checklist Final

Marque conforme for completando:

- [ ] Bucket `site-assets` criado
- [ ] Bucket marcado como **Public** (✅)
- [ ] Policy de INSERT criada (authenticated users)
- [ ] Policy de SELECT criada (public)
- [ ] Policy de UPDATE criada (authenticated users)
- [ ] Policy de DELETE criada (authenticated users)
- [ ] Teste de upload funcionou
- [ ] Imagem aparece na aplicação

---

## 🚨 Erros Comuns

### ❌ "new row violates row-level security policy"
**Causa**: Policy de INSERT não foi criada  
**Solução**: Execute a policy de INSERT do PASSO 2

### ❌ "Bucket not found"
**Causa**: Bucket não foi criado  
**Solução**: Volte ao PASSO 1

### ❌ Imagem não aparece após upload
**Causa**: Bucket não está marcado como Public OU policy de SELECT não existe  
**Solução**: 
1. Verifique se bucket está Public (Storage > site-assets > Settings)
2. Execute a policy de SELECT do PASSO 2

### ❌ "Access denied"
**Causa**: Usuário não está autenticado OU policy de INSERT não existe  
**Solução**: 
1. Faça login novamente
2. Execute a policy de INSERT do PASSO 2

---

## 📝 Notas Importantes

1. **O código JÁ está configurado** para usar `site-assets` - não precisa alterar nada no código!
2. **Public bucket** é necessário para que as imagens sejam acessíveis publicamente
3. As policies garantem que:
   - Qualquer pessoa pode **ver** as imagens (SELECT public)
   - Apenas usuários autenticados podem **fazer upload** (INSERT authenticated)
   - Apenas usuários autenticados podem **atualizar/deletar** (UPDATE/DELETE authenticated)

---

## 🎉 Pronto!

Após seguir todos os passos, o sistema de upload de imagens estará funcionando perfeitamente!
