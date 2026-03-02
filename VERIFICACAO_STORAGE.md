# ✅ Verificação do Storage - Bucket site-assets

## Status do Código

### ✅ Código já está configurado corretamente!

O código já está usando o bucket `site-assets` em todos os lugares:

**Arquivo**: `src/services/siteSettingsService.ts`

#### Upload de imagens (linha 77-79):
```typescript
const { error: uploadError } = await supabase.storage
  .from('site-assets')  // ✅ CORRETO
  .upload(filePath, file, { upsert: true, contentType: file.type, cacheControl: '3600' });
```

#### Obter URL pública (linha 91-93):
```typescript
const { data } = supabase.storage
  .from('site-assets')  // ✅ CORRETO
  .getPublicUrl(filePath);
```

#### Deletar imagens (linha 105-107):
```typescript
const { error } = await supabase.storage
  .from('site-assets')  // ✅ CORRETO
  .remove([fileName]);
```

## Checklist de Configuração

### No Supabase Dashboard:

- [ ] **1. Criar o bucket `site-assets`**
  - Ir em Storage > New Bucket
  - Nome: `site-assets`
  - ✅ Marcar como **Public**
  - Criar bucket

- [ ] **2. Criar policies de acesso**
  - Opção 1: Via Dashboard (Storage > Policies)
  - Opção 2: Via SQL (executar `CRIAR_STORAGE_POLICIES.sql`)

### Policies necessárias:

1. **✅ INSERT** - Authenticated users can upload
2. **✅ SELECT** - Public read access  
3. **✅ UPDATE** - Authenticated users can update
4. **✅ DELETE** - Authenticated users can delete

### Verificar se funcionou:

Execute no SQL Editor:
```sql
-- Verificar bucket
SELECT * FROM storage.buckets WHERE name = 'site-assets';

-- Verificar policies
SELECT policyname, cmd, roles
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND (qual LIKE '%site-assets%' OR with_check LIKE '%site-assets%');
```

## Estrutura de Arquivos

O código salva arquivos com este padrão:
```
site-assets/
├── logo-[timestamp].jpg       # Logos do site
├── logo-[timestamp].png
├── background-[timestamp].jpg # Backgrounds
└── background-[timestamp].png
```

## URLs Geradas

Após o upload, as URLs públicas terão este formato:
```
https://[seu-projeto-id].supabase.co/storage/v1/object/public/site-assets/logo-1234567890.jpg
```

## Teste de Upload

Para testar se está funcionando:

1. Faça login no admin
2. Vá em **Settings** > **Personalização**
3. Tente fazer upload de um logo ou background
4. Se aparecer erro, verifique:
   - Console do navegador (F12)
   - Se o bucket foi criado
   - Se as policies foram criadas
   - Se o bucket está marcado como Public

## Troubleshooting

### Erro: "new row violates row-level security policy"
**Solução**: Criar a policy de INSERT para authenticated users

### Erro: "Bucket not found"
**Solução**: Criar o bucket `site-assets` no Dashboard

### Erro: "Access denied"
**Solução**: 
1. Verificar se o bucket está marcado como Public
2. Criar a policy de SELECT para public

### Imagem não aparece após upload
**Solução**: Criar a policy de SELECT para permitir leitura pública

## Próximos Passos

1. ✅ Criar bucket `site-assets` (via Dashboard)
2. ✅ Executar `CRIAR_STORAGE_POLICIES.sql` (via SQL Editor)
3. ✅ Testar upload de imagem
4. ✅ Verificar se a URL pública funciona
