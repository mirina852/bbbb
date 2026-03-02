-- ============================================
-- DESABILITAR RLS PARA ORDERS E ORDER_ITEMS
-- ============================================

-- OBJETIVO: Permitir que qualquer pessoa crie pedidos sem login

-- ============================================
-- OPÇÃO 1: DESABILITAR RLS COMPLETAMENTE
-- ============================================

-- Desabilitar RLS (sem segurança)
ALTER TABLE public.orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items DISABLE ROW LEVEL SECURITY;

-- Verificar
SELECT 
  tablename,
  rowsecurity as rls_habilitado
FROM pg_tables
WHERE tablename IN ('orders', 'order_items');

-- Deve retornar: rls_habilitado = false

-- ============================================
-- RESULTADO
-- ============================================
-- ✅ Qualquer pessoa pode criar pedidos
-- ✅ Qualquer pessoa pode criar itens de pedido
-- ⚠️ Qualquer pessoa pode VER todos os pedidos
-- ⚠️ Qualquer pessoa pode EDITAR/DELETAR pedidos

-- ============================================
-- OPÇÃO 2: MANTER RLS MAS SIMPLIFICAR
-- ============================================

-- Se você quiser manter alguma segurança:

-- Habilitar RLS
-- ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Remover todas as políticas
-- DROP POLICY IF EXISTS "public_insert_orders" ON public.orders;
-- DROP POLICY IF EXISTS "authenticated_select_orders" ON public.orders;
-- DROP POLICY IF EXISTS "authenticated_update_orders" ON public.orders;
-- DROP POLICY IF EXISTS "authenticated_delete_orders" ON public.orders;

-- Criar política simples: TODOS podem fazer TUDO
-- CREATE POLICY "allow_all_orders"
-- ON public.orders FOR ALL TO public USING (true) WITH CHECK (true);

-- CREATE POLICY "allow_all_order_items"
-- ON public.order_items FOR ALL TO public USING (true) WITH CHECK (true);

-- ============================================
-- RECOMENDAÇÃO
-- ============================================

-- Para um sistema de pedidos público (sem login):
-- ✅ Use OPÇÃO 1 (desabilitar RLS)
-- ✅ Mais simples
-- ✅ Funciona imediatamente
-- ⚠️ Menos seguro (qualquer um pode ver/editar pedidos)

-- Para um sistema com admin:
-- ✅ Use OPÇÃO 2 (RLS com política permissiva)
-- ✅ Permite criar pedidos sem login
-- ✅ Admin pode gerenciar pedidos
-- ⚠️ Mais complexo

-- ============================================
-- APÓS EXECUTAR
-- ============================================
-- 1. Recarregue a página /s/[slug]
-- 2. Faça checkout
-- 3. ✅ Pedido deve ser criado com sucesso!
