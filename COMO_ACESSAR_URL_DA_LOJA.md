# 🎯 Como Acessar a URL da Sua Loja

## ✅ Problema Resolvido

Você já fez cadastro e login, mas não viu a URL da sua loja. Agora você tem **3 formas** de acessar!

## 📋 Opção 1: Ver na Página de Configurações (RECOMENDADO)

### Passo a Passo:

1. **Faça login** no sistema
2. Vá para **Configurações** (menu lateral)
3. Na aba **"Personalização"** (primeira aba)
4. **Veja o card "URL da Sua Loja"** no topo da página

### O que você verá:

```
┌─────────────────────────────────────────┐
│ 🔗 URL da Sua Loja                      │
├─────────────────────────────────────────┤
│ Compartilhe este link com seus clientes│
│                                         │
│ http://localhost:5173/s/sua-loja  [📋] │
│                                         │
│ [Copiar Link]  [Compartilhar]          │
│                                         │
│ Como usar:                              │
│ • Copie o link e envie para clientes   │
│ • Adicione em redes sociais            │
│ • Use em cartões de visita             │
└─────────────────────────────────────────┘
```

### Funcionalidades:

- ✅ **Copiar Link** - Copia para área de transferência
- ✅ **Compartilhar** - Abre menu de compartilhamento do navegador
- ✅ **Abrir Loja** - Abre sua loja em nova aba
- ✅ **Dicas de uso** - Como divulgar sua loja

## 📋 Opção 2: Criar Nova Loja (Se não tiver)

Se você ainda **não criou uma loja**, siga estes passos:

### 1. Acesse manualmente:
```
http://localhost:5173/store-setup
```

### 2. Preencha o formulário:
- **Nome da Loja**: "Minha Hamburgueria"
- **Descrição**: Breve descrição da sua loja
- **Telefone**: Seu telefone
- **E-mail**: Seu e-mail
- **Endereço**: Endereço completo

### 3. Clique em "Criar conta"

### 4. Veja a mensagem de sucesso:
```
✅ Sua loja foi criada! 🎉
Acesse: http://localhost:5173/s/minha-hamburgueria
```

## 📋 Opção 3: Verificar no Banco de Dados

Se você quer ver diretamente no banco:

### SQL para ver sua loja:

```sql
-- Ver todas as lojas
SELECT 
  id,
  name,
  slug,
  owner_id,
  is_active,
  created_at
FROM public.stores
WHERE is_active = true
ORDER BY created_at DESC;
```

### Construir a URL manualmente:

```
http://localhost:5173/s/[SEU-SLUG]
```

Exemplo:
- Slug: `minha-hamburgueria`
- URL: `http://localhost:5173/s/minha-hamburgueria`

## 🔄 Fluxo Completo

### Se você JÁ criou a loja:

```
Login
  ↓
/admin (Dashboard)
  ↓
Configurações (menu lateral)
  ↓
Aba "Personalização"
  ↓
Ver "URL da Sua Loja" ✅
```

### Se você NÃO criou a loja ainda:

```
Login
  ↓
Sistema detecta: sem loja
  ↓
Redireciona para /store-setup
  ↓
Preencher formulário
  ↓
Criar loja
  ↓
Ver URL no toast ✅
  ↓
/admin → Configurações → Ver URL novamente ✅
```

## 🎨 Formato da URL

### Desenvolvimento (localhost):
```
http://localhost:5173/s/[slug-da-loja]
```

### Produção (quando publicar):
```
https://seudominio.com/s/[slug-da-loja]
```

### Exemplos:
```
http://localhost:5173/s/hamburgueria-do-ze
http://localhost:5173/s/pizzaria-bella
http://localhost:5173/s/lanchonete-central
http://localhost:5173/s/mundo-das-plantas
```

## 📱 Como Compartilhar com Clientes

### 1. WhatsApp:
```
Olá! Confira nosso cardápio online:
http://localhost:5173/s/sua-loja

Faça seu pedido agora! 🍔
```

### 2. Instagram Bio:
```
🍕 Cardápio Online
👇 Peça agora
localhost:5173/s/sua-loja
```

### 3. Facebook:
```
🎉 Agora você pode fazer pedidos online!
Acesse: http://localhost:5173/s/sua-loja
```

### 4. Cartão de Visita:
```
┌─────────────────────────┐
│  Hamburgueria do Zé     │
│  (11) 99999-9999       │
│  📱 Peça Online:        │
│  localhost:5173/s/...   │
└─────────────────────────┘
```

## 🚀 Próximos Passos

### 1. **Personalize sua loja:**
- Adicione logo
- Escolha cores
- Configure taxa de entrega

### 2. **Adicione produtos:**
- Vá em "Produtos"
- Clique "Adicionar Produto"
- Preencha nome, preço, descrição

### 3. **Configure pagamentos:**
- Vá em "Configurações" → "Pagamentos"
- Adicione suas credenciais do Mercado Pago

### 4. **Compartilhe!**
- Copie a URL da loja
- Envie para seus clientes
- Adicione em redes sociais

## ✅ Checklist

- [ ] Fiz login no sistema
- [ ] Criei minha loja (ou já tinha)
- [ ] Acessei "Configurações"
- [ ] Vi a "URL da Sua Loja"
- [ ] Copiei o link
- [ ] Testei abrindo em nova aba
- [ ] Compartilhei com clientes

## 🎯 Resumo Rápido

### Para ver sua URL AGORA:

1. **Login** → `/admin`
2. **Menu lateral** → "Configurações"
3. **Primeira aba** → "Personalização"
4. **Card no topo** → "URL da Sua Loja"
5. **Copiar e compartilhar!** 🎉

## 📞 Suporte

Se ainda não conseguir ver a URL:

1. Verifique se criou a loja em `/store-setup`
2. Verifique no banco se a loja existe
3. Recarregue a página (Ctrl+F5)
4. Limpe o cache do navegador

## 🎉 Pronto!

Agora você tem acesso à URL da sua loja e pode compartilhar com seus clientes! 🚀
