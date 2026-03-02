# ⚡ Guia Rápido: URLs com Categorias

## 🎯 Como Funciona

Agora você pode criar links diretos para categorias específicas da sua loja!

---

## 📋 Formato da URL

```
https://seusite.com/[slug-da-loja]?category=[nome-da-categoria]
```

---

## 💡 Exemplos Práticos

### Loja: mercadinhomvp

**URL normal (abre primeira categoria):**
```
https://seusite.com/mercadinhomvp
```

**URL com categoria específica:**
```
# Abre direto em "hambúrguer"
https://seusite.com/mercadinhomvp?category=hamburguer

# Abre direto em "bebidas"
https://seusite.com/mercadinhomvp?category=bebidas
```

---

## 🔍 Como Descobrir o Nome da Categoria

### Opção 1: Pelo Painel Admin
1. Acesse **Produtos** → **Gerenciar Categorias**
2. Veja o nome de cada categoria
3. Use o nome em minúsculas, sem acentos

**Exemplo:**
- Categoria: "Hambúrguer" → Use: `hamburguer`
- Categoria: "Bebidas Geladas" → Use: `bebidas-geladas`

### Opção 2: Pelo Banco de Dados
```sql
SELECT name, slug FROM categories 
WHERE store_id = 'seu-store-id';
```

---

## 📱 Casos de Uso

### 1. Instagram Stories
```
📸 Foto de hambúrguer
📝 Texto: "Confira nossos hambúrgueres! 🍔"
🔗 Link: seusite.com/mercadinhomvp?category=hamburguer
```

### 2. WhatsApp Business
```
💬 Mensagem automática:
"Olá! Veja nosso cardápio de bebidas:"
🔗 seusite.com/mercadinhomvp?category=bebidas
```

### 3. QR Codes
Crie QR Codes diferentes para cada categoria:

```
QR Code na mesa 1 → Hambúrgueres
QR Code na mesa 2 → Bebidas
QR Code no balcão → Sobremesas
```

### 4. Google Ads / Facebook Ads
```
Campanha 1: Hambúrgueres
URL de destino: seusite.com/mercadinhomvp?category=hamburguer

Campanha 2: Bebidas
URL de destino: seusite.com/mercadinhomvp?category=bebidas
```

---

## ✅ Melhorias Visuais

### Logo e Fundo Sempre Visíveis
Agora o logo e as imagens de fundo aparecem em **todas as categorias**, não apenas na primeira!

**Antes:**
- Troca de categoria → logo e fundo desaparecem

**Depois:**
- Troca de categoria → logo e fundo continuam visíveis ✅

---

## 🧪 Testar Agora

### Teste 1: Acesso Normal
```
1. Acesse: /mercadinhomvp
2. Deve abrir na primeira categoria
3. Logo e fundo devem aparecer
```

### Teste 2: Acesso com Categoria
```
1. Acesse: /mercadinhomvp?category=hamburguer
2. Deve abrir direto na categoria "hambúrguer"
3. Logo e fundo devem aparecer
```

### Teste 3: Trocar de Categoria
```
1. Acesse qualquer categoria
2. Clique em outra categoria
3. Logo e fundo devem continuar visíveis
```

---

## 🎨 Personalizar Posição do Logo

Se quiser ajustar onde o logo aparece, edite o arquivo:
`src/pages/customer/StoreSlug.tsx`

```typescript
<BackgroundCarousel 
  images={currentStore.background_urls || []} 
  logoUrl={currentStore.logo_url}
  logoTop={105}    // ← Distância do topo (em pixels)
  logoLeft={20}    // ← Distância da esquerda (em pixels)
/>
```

---

## 📊 Monitorar Acessos

Para saber quais categorias são mais acessadas, você pode:

1. **Google Analytics:** Rastrear parâmetros da URL
2. **Facebook Pixel:** Eventos personalizados por categoria
3. **Logs do servidor:** Analisar URLs mais acessadas

---

## 🎉 Resultado Final

✅ **Logo e fundo sempre visíveis**  
✅ **Links diretos para categorias**  
✅ **Marketing mais eficiente**  
✅ **Melhor experiência do cliente**  

---

## 📚 Documentação Completa

Para mais detalhes técnicos, consulte:
- `MELHORIAS_PAGINA_LOJA.md` - Documentação técnica completa

---

**Aproveite as novas funcionalidades! 🚀**
