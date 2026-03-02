# Configurar Bucket de Storage no Supabase

## Passo 1: Criar o Bucket

1. Acesse o **Supabase Dashboard**
2. Vá em **Storage** no menu lateral
3. Clique em **New Bucket**
4. Configure:
   - **Name**: `site-assets`
   - **Public bucket**: ✅ **MARCAR COMO PUBLIC**
   - **File size limit**: 50MB (ou conforme necessário)
   - **Allowed MIME types**: deixe vazio para aceitar todos os tipos

5. Clique em **Create Bucket**

## Passo 2: Criar Policies de Acesso

Após criar o bucket, você precisa criar as policies manualmente.

### Policy 1: Permitir Upload para Usuários Autenticados

1. No Supabase Dashboard, vá em **Storage** > **Policies**
2. Selecione o bucket `site-assets`
3. Clique em **New Policy**
4. Escolha **Custom Policy**
5. Configure:
   - **Policy name**: `Authenticated users can upload`
   - **Allowed operation**: `INSERT`
   - **Target roles**: `authenticated`
   - **Policy definition**:
   ```sql
   (bucket_id = 'site-assets'::text)
   ```
   - **WITH CHECK expression**:
   ```sql
   (bucket_id = 'site-assets'::text)
   ```

### Policy 2: Permitir Leitura Pública

1. Clique em **New Policy** novamente
2. Escolha **Custom Policy**
3. Configure:
   - **Policy name**: `Public read access`
   - **Allowed operation**: `SELECT`
   - **Target roles**: `public`, `authenticated`
   - **Policy definition**:
   ```sql
   (bucket_id = 'site-assets'::text)
   ```

### Policy 3: Permitir Update para Usuários Autenticados

1. Clique em **New Policy**
2. Configure:
   - **Policy name**: `Authenticated users can update`
   - **Allowed operation**: `UPDATE`
   - **Target roles**: `authenticated`
   - **Policy definition**:
   ```sql
   (bucket_id = 'site-assets'::text)
   ```

### Policy 4: Permitir Delete para Usuários Autenticados

1. Clique em **New Policy**
2. Configure:
   - **Policy name**: `Authenticated users can delete`
   - **Allowed operation**: `DELETE`
   - **Target roles**: `authenticated`
   - **Policy definition**:
   ```sql
   (bucket_id = 'site-assets'::text)
   ```

## Passo 3: Criar Policies via SQL (Alternativa)

Se preferir criar as policies via SQL, execute este script no **SQL Editor**:

```sql
-- Policy para permitir upload (INSERT)
CREATE POLICY "Authenticated users can upload"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'site-assets');

-- Policy para permitir leitura pública (SELECT)
CREATE POLICY "Public read access"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'site-assets');

-- Policy para permitir update
CREATE POLICY "Authenticated users can update"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'site-assets')
WITH CHECK (bucket_id = 'site-assets');

-- Policy para permitir delete
CREATE POLICY "Authenticated users can delete"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'site-assets');
```

## Passo 4: Verificar Configuração

Execute este SQL para verificar se o bucket e as policies foram criados:

```sql
-- Verificar se o bucket existe
SELECT * FROM storage.buckets WHERE name = 'site-assets';

-- Verificar policies do bucket
SELECT * FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage';
```

## Estrutura de Pastas Recomendada

Organize os arquivos no bucket da seguinte forma:

```
site-assets/
├── products/          # Imagens de produtos
├── stores/            # Logos e backgrounds de lojas
│   ├── logos/
│   └── backgrounds/
├── categories/        # Imagens de categorias
└── temp/             # Uploads temporários
```

## URLs Públicas

Após o upload, as imagens estarão disponíveis publicamente em:

```
https://[seu-projeto].supabase.co/storage/v1/object/public/site-assets/[caminho-do-arquivo]
```

Exemplo:
```
https://[seu-projeto].supabase.co/storage/v1/object/public/site-assets/products/pizza.jpg
```

## Próximos Passos

Após configurar o bucket, verifique se o código está usando o bucket correto executando a busca no código.
