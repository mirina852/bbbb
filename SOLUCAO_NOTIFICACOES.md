# Solução: Notificações de Pedidos Não Funcionam

## Problema Identificado

As notificações de novos pedidos não estavam sendo recebidas devido a dois problemas principais:

1. **Falta de filtro por `store_id`**: O hook `useOrderNotifications` estava tentando escutar TODOS os pedidos do banco de dados, sem filtrar pela loja do usuário atual.

2. **Possível problema com Realtime**: A subscription do Supabase Realtime pode estar falhando devido às políticas RLS (Row Level Security) ou configuração incorreta.

## Correções Implementadas

### 1. Atualização do Hook `useOrderNotifications`

O hook foi atualizado para:
- Filtrar pedidos pela `store_id` da loja atual do usuário
- Adicionar logs de debug para facilitar troubleshooting
- Validar se existe uma loja antes de criar a subscription
- Usar um canal único por loja (`new-orders-${storeId}`)

**Arquivo modificado**: `src/hooks/useOrderNotifications.ts`

### 2. Verificação da Configuração do Supabase

Execute o script `VERIFICAR_NOTIFICACOES.sql` no Supabase SQL Editor para verificar:
- Se a tabela `orders` tem `REPLICA IDENTITY FULL`
- Se a tabela está na publicação `supabase_realtime`
- As políticas RLS da tabela
- Se RLS está habilitado

## Como Testar

### 1. Verificar os Logs do Console

Abra o Console do navegador (F12) e procure por mensagens como:
```
Iniciando subscription de notificações para loja: [store-id]
Status da subscription: SUBSCRIBED
```

Se você ver erros ou status diferente de `SUBSCRIBED`, há um problema com a configuração.

### 2. Testar a Notificação

1. Acesse a página de configurações (Settings)
2. Vá para a aba "Notificações"
3. Certifique-se que "Notificações de Novos Pedidos" está ATIVADO (toggle verde)
4. Clique em "Testar Som" para verificar se o som está funcionando
5. Faça um pedido de teste pela página pública da loja
6. Você deve receber uma notificação visual e sonora

### 3. Verificar Configurações no Supabase

Execute o script SQL de verificação:

```sql
-- No Supabase SQL Editor, execute:
\i VERIFICAR_NOTIFICACOES.sql
```

## Possíveis Problemas e Soluções

### Problema 1: "Nenhuma loja disponível para receber notificações"

**Causa**: O usuário não tem nenhuma loja cadastrada ou a loja não foi carregada.

**Solução**:
1. Certifique-se de que o usuário tem uma loja cadastrada
2. Verifique se o `StoreContext` está carregando as lojas corretamente
3. Recarregue a página

### Problema 2: Status da subscription não é "SUBSCRIBED"

**Causa**: Problema com a configuração do Realtime no Supabase.

**Solução**:
1. Execute o script `VERIFICAR_NOTIFICACOES.sql`
2. Se necessário, execute os comandos de correção:

```sql
-- Habilitar REPLICA IDENTITY
ALTER TABLE public.orders REPLICA IDENTITY FULL;

-- Adicionar à publicação
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
```

### Problema 3: Notificações desabilitadas

**Causa**: O toggle de notificações está desligado nas configurações.

**Solução**:
1. Vá para Settings > Notificações
2. Ative o toggle "Notificações de Novos Pedidos"
3. As configurações são salvas automaticamente no localStorage

### Problema 4: Som não toca

**Causa**: O toggle de som está desabilitado ou o volume está em 0.

**Solução**:
1. Vá para Settings > Notificações
2. Ative o toggle "Som de Notificação"
3. Ajuste o volume (mínimo 10%)
4. Clique em "Testar Som" para verificar

### Problema 5: Políticas RLS bloqueando a subscription

**Causa**: As políticas RLS podem estar impedindo que o Realtime funcione corretamente.

**Solução**: Verifique se existe uma política que permite SELECT para usuários autenticados:

```sql
-- Verificar políticas
SELECT policyname, cmd, qual 
FROM pg_policies 
WHERE tablename = 'orders';

-- Se necessário, criar política para SELECT
CREATE POLICY "Authenticated users can view orders from their stores"
ON public.orders
FOR SELECT
USING (
  auth.uid() IN (
    SELECT owner_id FROM public.stores WHERE id = orders.store_id
  )
);
```

## Logs de Debug

O hook agora inclui logs de debug que aparecem no console:

- `Nenhuma loja disponível para receber notificações` - Usuário sem loja
- `Store ID não disponível para notificações` - Problema ao obter store_id
- `Iniciando subscription de notificações para loja: [id]` - Subscription iniciada
- `Status da subscription: [status]` - Status da conexão Realtime
- `Novo pedido recebido: [payload]` - Pedido recebido via Realtime
- `Notificações desabilitadas` - Toggle de notificações está OFF
- `Removendo subscription de notificações` - Cleanup ao desmontar

## Verificação Final

Após aplicar as correções:

1. ✅ Verifique que o console mostra "Status da subscription: SUBSCRIBED"
2. ✅ Faça um pedido de teste
3. ✅ Confirme que a notificação aparece na tela
4. ✅ Confirme que o som toca (se habilitado)
5. ✅ Verifique que a notificação mostra os dados corretos do pedido

## Suporte Adicional

Se o problema persistir:

1. Compartilhe os logs do console do navegador
2. Execute o script `VERIFICAR_NOTIFICACOES.sql` e compartilhe os resultados
3. Verifique se há erros na aba Network do DevTools
4. Confirme que o Supabase Realtime está habilitado no projeto
