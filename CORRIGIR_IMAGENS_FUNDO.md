# 🖼️ Corrigir Imagens de Fundo Não Aparecem

## ⚠️ Problema

As imagens de fundo não aparecem na página de Personalização do Site porque a coluna `background_urls` não existe na tabela `site_settings`.

---

## ✅ Solução Rápida

### Opção 1: Executar SQL Completo (Recomendado)

1. **Abra** o SQL Editor do Supabase
2. **Cole** todo o conteúdo do arquivo `SQL_COMPLETO_EXECUTAR.sql`
3. **Execute** (Ctrl+Enter ou botão Run)
4. **Verifique** o resultado da última query - todas devem mostrar "existe = 1"

---

### Opção 2: Executar Apenas a Migration de Imagens

Se você já executou as outras migrations, execute apenas este SQL:

```sql
-- Adicionar coluna background_urls para múltiplas imagens
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS background_urls TEXT[] DEFAULT '{}';

-- Adicionar coluna site_title
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS site_title TEXT;

-- Adicionar coluna delivery_fee
ALTER TABLE public.site_settings 
ADD COLUMN IF NOT EXISTS delivery_fee DECIMAL(10,2) DEFAULT 5.00;

-- Migrar background_url existente para background_urls (se houver)
UPDATE public.site_settings 
SET background_urls = ARRAY[background_url]::TEXT[]
WHERE background_url IS NOT NULL 
AND (background_urls IS NULL OR background_urls = '{}');
```

---

## 🧪 Verificar se Funcionou

Execute este SQL para confirmar:

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'site_settings'
ORDER BY ordinal_position;
```

**Colunas esperadas:**
- ✅ `id` (uuid)
- ✅ `logo_url` (text)
- ✅ `background_url` (text)
- ✅ `background_urls` (ARRAY) ← **Nova coluna**
- ✅ `site_title` (text) ← **Nova coluna**
- ✅ `delivery_fee` (numeric) ← **Nova coluna**
- ✅ `created_at` (timestamp)
- ✅ `updated_at` (timestamp)

---

## 🎯 Testar Novamente

Após executar a migration:

1. **Recarregue** a página de Personalização do Site
2. **Clique** em "Adicionar primeira imagem"
3. **Selecione** uma imagem
4. **Observe:**
   - ✅ Preview aparece instantaneamente
   - ✅ Spinner mostra "Enviando..."
   - ✅ Após upload, imagem aparece no carrossel
   - ✅ Pode adicionar mais imagens
   - ✅ Setas de navegação aparecem (se tiver mais de 2)

---

## 📋 O Que Foi Adicionado

### 1. Coluna `background_urls` (ARRAY)
- Armazena **múltiplas URLs** de imagens
- Permite criar **carrossel** de imagens de fundo
- Tipo: `TEXT[]` (array de textos)

### 2. Coluna `site_title`
- Armazena o **título do site**
- Exibido no header/cabeçalho
- Tipo: `TEXT`

### 3. Coluna `delivery_fee`
- Armazena a **taxa de entrega padrão**
- Valor em reais (BRL)
- Padrão: R$ 5,00
- Tipo: `DECIMAL(10,2)`

### 4. Migração Automática
- Se você já tinha uma imagem em `background_url`
- Ela é **automaticamente copiada** para `background_urls`
- Não perde dados existentes

---

## ❓ Troubleshooting

### Erro: "column background_urls already exists"

**Causa:** Coluna já foi criada antes

**Solução:** Tudo certo! Apenas recarregue a página

---

### Imagens ainda não aparecem

**Verifique:**

1. **Coluna foi criada?**
   ```sql
   SELECT column_name FROM information_schema.columns 
   WHERE table_name = 'site_settings' AND column_name = 'background_urls';
   ```
   Deve retornar 1 linha

2. **Dados existem?**
   ```sql
   SELECT background_urls FROM public.site_settings;
   ```
   Deve mostrar um array (pode estar vazio: `{}`)

3. **Console do navegador (F12):**
   - Veja se há erros
   - Procure por "Error fetching site settings"

---

## 🎉 Resultado Final

Quando tudo estiver correto:

**Sem imagens:**
```
[+ Adicionar primeira imagem]
```

**Com 1 imagem:**
```
[Imagem 1] [+ Adicionar]
```

**Com múltiplas imagens:**
```
[Imagem 1] [Imagem 2] [Imagem 3] [+ Adicionar]
← → (setas de navegação)
```

**Durante upload:**
```
[Preview com spinner] [Imagem 1] [Imagem 2] [+ Adicionar]
```

---

## 📝 Checklist

- [ ] Executei a migration SQL
- [ ] Verifiquei que a coluna `background_urls` existe
- [ ] Recarreguei a página de Personalização
- [ ] Adicionei uma imagem de teste
- [ ] Imagem aparece no carrossel
- [ ] Posso adicionar mais imagens
- [ ] Posso remover imagens (botão X ao passar o mouse)

---

## 💡 Dica

Se você já tinha uma imagem em `background_url`, ela foi automaticamente migrada para `background_urls`. Você pode adicionar mais imagens e criar um carrossel!

**Agora as imagens de fundo devem aparecer corretamente!** 🎨
