# 🎯 Guia: Sistema Multi-Tenant de Produtos

## ✅ O Que Foi Implementado

Agora cada loja tem seus **próprios produtos isolados**:

- ✅ **Loja A** adiciona produtos → Só aparecem na Loja A
- ✅ **Loja B** adiciona produtos → Só aparecem na Loja B
- ✅ **Produtos não são compartilhados** entre lojas
- ✅ **Cada loja é independente**

## 🔧 Correções Aplicadas

### 1. Filtro por `store_id`
```typescript
// Agora filtra produtos por loja
productsService.getAllForAdmin(currentStore.id)
```

### 2. Produtos sempre salvos com `store_id`
```typescript
// Ao criar produto, sempre adiciona store_id
const productWithStore = {
  ...product,
  store_id: currentStore.id  // ✅ Sempre vinculado à loja
};
```

### 3. Isolamento completo
- Cada loja vê apenas seus produtos
- Produtos sem `store_id` não aparecem
- Multi-tenancy funcionando

## 🧪 Como Testar o Isolamento

### Teste Completo:

#### Passo 1: Limpar Produtos de Exemplo
Execute no **SQL Editor do Supabase**:

```sql
-- Deletar produtos sem loja (de migrations antigas)
DELETE FROM products WHERE store_id IS NULL;

-- Verificar que não há mais produtos sem loja
SELECT COUNT(*) FROM products WHERE store_id IS NULL;
-- Resultado esperado: 0
```

#### Passo 2: Criar Produtos na Loja A

1. **Acesse** `/store-selector`
2. **Selecione** a primeira loja (ex: "brunonobru")
3. **Vá para** `/admin/products`
4. **Clique** em "Adicionar Produto"
5. **Crie** 2 produtos:
   - Produto A1: "Hambúrguer Especial" - R$ 25,00
   - Produto A2: "Batata Frita" - R$ 10,00
6. **Verifique** que os 2 produtos aparecem

#### Passo 3: Trocar para Loja B

1. **Acesse** `/store-selector` novamente
2. **Selecione** a segunda loja (ex: "vefff")
3. **Vá para** `/admin/products`
4. **Verifique**: Deve mostrar "Nenhum produto encontrado"
   - ✅ Produtos da Loja A **NÃO aparecem**!

#### Passo 4: Criar Produtos na Loja B

1. **Clique** em "Adicionar Produto"
2. **Crie** 2 produtos diferentes:
   - Produto B1: "Pizza Margherita" - R$ 35,00
   - Produto B2: "Refrigerante" - R$ 5,00
3. **Verifique** que os 2 produtos aparecem

#### Passo 5: Voltar para Loja A

1. **Acesse** `/store-selector`
2. **Selecione** a primeira loja novamente
3. **Vá para** `/admin/products`
4. **Verifique**: Deve mostrar apenas os 2 produtos da Loja A
   - ✅ Produtos da Loja B **NÃO aparecem**!

## 📊 Verificação no Banco de Dados

Execute no **SQL Editor**:

```sql
-- Ver produtos de cada loja
SELECT 
  s.name as loja,
  s.slug,
  p.name as produto,
  p.price as preco,
  p.store_id
FROM stores s
LEFT JOIN products p ON p.store_id = s.id
ORDER BY s.name, p.name;
```

**Resultado esperado:**
```
loja          | slug        | produto              | preco | store_id
--------------|-------------|----------------------|-------|----------
brunonobru    | brunonobru  | Batata Frita        | 10.00 | [id-A]
brunonobru    | brunonobru  | Hambúrguer Especial | 25.00 | [id-A]
vefff         | vefff       | Pizza Margherita    | 35.00 | [id-B]
vefff         | vefff       | Refrigerante        | 5.00  | [id-B]
```

## 🔒 Segurança (RLS)

As políticas RLS garantem que:

1. **Cada usuário** vê apenas produtos de suas lojas
2. **Não é possível** acessar produtos de outras lojas via API
3. **Isolamento no nível do banco** de dados

### Verificar Políticas:

```sql
-- Ver políticas de products
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'products';
```

### Atualizar Políticas (se necessário):

```sql
-- Remover políticas antigas
DROP POLICY IF EXISTS "Products are viewable by everyone" ON products;
DROP POLICY IF EXISTS "Only authenticated users can manage products" ON products;

-- Criar políticas multi-tenant
CREATE POLICY "Users can view own store products"
ON products FOR SELECT
USING (
  store_id IN (
    SELECT id FROM stores WHERE owner_id = auth.uid()
  )
);

CREATE POLICY "Users can manage own store products"
ON products FOR ALL
USING (
  store_id IN (
    SELECT id FROM stores WHERE owner_id = auth.uid()
  )
)
WITH CHECK (
  store_id IN (
    SELECT id FROM stores WHERE owner_id = auth.uid()
  )
);
```

## 🎯 Fluxo Completo

### Criar Produto:

```
1. Usuário seleciona Loja A
2. Clica em "Adicionar Produto"
3. Preenche formulário
4. Sistema adiciona automaticamente: store_id = Loja A
5. Produto salvo no banco com store_id
6. Produto aparece apenas na Loja A
```

### Visualizar Produtos:

```
1. Usuário acessa /admin/products
2. Sistema verifica currentStore
3. Busca produtos WHERE store_id = currentStore.id
4. Mostra apenas produtos da loja atual
5. Produtos de outras lojas NÃO aparecem
```

### Trocar de Loja:

```
1. Usuário acessa /store-selector
2. Seleciona outra loja
3. currentStore é atualizado
4. Produtos são recarregados
5. Mostra produtos da nova loja
```

## ✅ Checklist de Validação

Marque cada item após testar:

- [ ] Executei `DELETE FROM products WHERE store_id IS NULL`
- [ ] Criei produtos na Loja A
- [ ] Produtos da Loja A aparecem apenas na Loja A
- [ ] Troquei para Loja B
- [ ] Produtos da Loja A NÃO aparecem na Loja B
- [ ] Criei produtos na Loja B
- [ ] Produtos da Loja B aparecem apenas na Loja B
- [ ] Voltei para Loja A
- [ ] Produtos da Loja B NÃO aparecem na Loja A
- [ ] Verifiquei no banco que cada produto tem `store_id`
- [ ] Console mostra logs corretos

## 📱 Página Pública da Loja

Os clientes também veem apenas produtos da loja que acessam:

```
Cliente acessa: /s/brunonobru
→ Vê apenas produtos da loja "brunonobru"

Cliente acessa: /s/vefff
→ Vê apenas produtos da loja "vefff"
```

## 🚀 Resultado Final

### Antes (❌):
```
Loja A: Vê todos os produtos (A + B + exemplos)
Loja B: Vê todos os produtos (A + B + exemplos)
```

### Depois (✅):
```
Loja A: Vê apenas produtos da Loja A
Loja B: Vê apenas produtos da Loja B
```

## 🎉 Pronto!

Agora você tem um sistema **multi-tenant completo**:

- ✅ Cada loja é independente
- ✅ Produtos isolados por loja
- ✅ Segurança no banco de dados
- ✅ Interface limpa e organizada
- ✅ Fácil trocar entre lojas

**Execute o teste completo acima para validar!** 🚀
