# ✅ Solução: Erro user_id em site_settings

## Problema
```
null value in column "user_id" violates not-null constraint
```

A tabela `site_settings` no banco de dados requer o campo `user_id`, mas o código não estava enviando esse valor.

## ✅ Correções Implementadas

### 1. Código Atualizado
**Arquivo**: `src/services/siteSettingsService.ts`

#### O que foi corrigido:
- ✅ Interface `SiteSettings` atualizada para corresponder à estrutura real do banco
- ✅ Removido `background_url` (singular) - não existe no banco
- ✅ Mantido `background_urls` (plural) - campo correto
- ✅ Adicionado `user_id` obrigatório
- ✅ Adicionado `primary_color`
- ✅ Função `update()` agora busca o `user_id` do usuário autenticado antes de criar registros

#### Código adicionado:
```typescript
// Get current user ID
const { data: { user } } = await supabase.auth.getUser();

if (!user) {
  throw new Error('Usuário não autenticado');
}

// Insert com user_id
const { data, error } = await supabase
  .from('site_settings')
  .insert({
    user_id: user.id,  // ✅ Agora envia o user_id
    logo_url: settings.logo_url || null,
    background_urls: settings.background_urls || null,
    primary_color: settings.primary_color || null
  })
```

## 🔧 Próximos Passos no Banco de Dados

### Verificar estrutura da tabela

Execute no **SQL Editor do Supabase**:

```sql
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'site_settings'
ORDER BY ordinal_position;
```

### Verificar se há registros com user_id NULL

```sql
SELECT * FROM public.site_settings WHERE user_id IS NULL;
```

### Se houver registros com user_id NULL:

```sql
-- Preencher com o ID do primeiro usuário admin
UPDATE public.site_settings 
SET user_id = (SELECT id FROM auth.users LIMIT 1)
WHERE user_id IS NULL;
```

### Se a coluna user_id não existir:

```sql
-- Adicionar coluna user_id
ALTER TABLE public.site_settings 
ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Preencher registros existentes
UPDATE public.site_settings 
SET user_id = (SELECT id FROM auth.users LIMIT 1)
WHERE user_id IS NULL;

-- Tornar obrigatório
ALTER TABLE public.site_settings 
ALTER COLUMN user_id SET NOT NULL;
```

## 🧪 Testar

1. **Faça login** como admin
2. Vá em **Settings** > **Personalização**
3. Tente fazer upload de um logo ou background
4. **Deve funcionar** sem o erro de user_id

## 📋 Estrutura Final da Tabela

A tabela `site_settings` deve ter esta estrutura:

```sql
CREATE TABLE public.site_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  logo_url TEXT,
  background_urls TEXT[],
  primary_color TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

## ⚠️ Importante

- O usuário **DEVE estar autenticado** para criar/atualizar configurações
- O `user_id` é preenchido automaticamente com o ID do usuário logado
- Se o erro persistir, execute o script `CORRIGIR_SITE_SETTINGS.sql`

## 🔍 Debug

Se o erro continuar, verifique no console do navegador:

```javascript
// Verificar se o usuário está autenticado
const { data: { user } } = await supabase.auth.getUser();
console.log('User:', user);
```

Se `user` for `null`, o problema é de autenticação, não de banco de dados.
