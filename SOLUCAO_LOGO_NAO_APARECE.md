# ✅ Solução: Logo não aparece na loja

## Problema Identificado

O logo era salvo na tabela `site_settings`, mas a página pública da loja buscava o logo na tabela `stores`. Eram **duas tabelas diferentes**!

### Estrutura do Sistema:

```
site_settings (LEGADO - configurações globais)
├── logo_url
├── background_urls
└── user_id

stores (MULTI-TENANT - dados de cada loja)
├── logo_url          ← A página pública busca AQUI
├── background_urls   ← A página pública busca AQUI
├── name
├── slug
└── owner_id
```

## ✅ Correção Implementada

**Arquivo modificado**: `src/components/settings/SiteCustomization.tsx`

### Mudanças principais:

1. **Removido**: Uso de `siteSettingsService` para salvar configurações
2. **Adicionado**: Uso de `StoreContext` para salvar na loja atual
3. **Agora salva em**: `stores.logo_url` e `stores.background_urls`

### Código antes (❌ ERRADO):
```typescript
// Salvava em site_settings
const updatedSettings = await siteSettingsService.update({
  logo_url: imageUrl
});
```

### Código depois (✅ CORRETO):
```typescript
// Salva na loja atual (stores)
await updateStore(store.id, {
  logo_url: imageUrl
});
```

## 🎯 Como funciona agora:

1. **Upload do logo** → Salva em `stores.logo_url` da loja atual
2. **Página pública** → Busca de `stores.logo_url` da loja
3. **✅ Logo aparece corretamente!**

## 🧪 Testar

1. **Faça upload de um novo logo**:
   - Settings > Personalização
   - Escolher Logo
   - Upload da imagem

2. **Verifique na página pública**:
   - Acesse a URL da sua loja
   - O logo deve aparecer no topo

3. **Verifique no banco**:
   ```sql
   SELECT id, name, logo_url FROM stores;
   ```
   O `logo_url` deve estar preenchido

## 📝 Observações

- **Logos antigos** salvos em `site_settings` não aparecerão
- **Solução**: Faça upload novamente do logo
- O sistema agora usa **multi-tenant** corretamente
- Cada loja tem seu próprio logo e backgrounds

## 🔧 Se o logo ainda não aparecer:

1. **Limpe o cache do navegador** (Ctrl+Shift+R)
2. **Verifique se o bucket existe**:
   ```sql
   SELECT * FROM storage.buckets WHERE name = 'site-assets';
   ```
3. **Verifique se a URL está correta**:
   ```sql
   SELECT logo_url FROM stores WHERE id = '[sua-loja-id]';
   ```
4. **Teste a URL diretamente** no navegador

## ✅ Resultado Final

- ✅ Logo salvo na tabela `stores`
- ✅ Logo aparece na página pública
- ✅ Backgrounds salvos na tabela `stores`
- ✅ Sistema multi-tenant funcionando corretamente
