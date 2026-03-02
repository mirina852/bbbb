-- ============================================
-- 🚨 EXECUTAR AGORA NO SUPABASE SQL EDITOR
-- Fix RLS da tabela ingredients
-- ============================================

-- 1️⃣ Remover políticas antigas
DROP POLICY IF EXISTS "Ingredients are viewable by everyone" ON public.ingredients;
DROP POLICY IF EXISTS "Only authenticated users can manage ingredients" ON public.ingredients;

-- 2️⃣ Criar política de leitura pública (para clientes verem ingredientes)
CREATE POLICY "Anyone can view ingredients"
  ON public.ingredients
  FOR SELECT
  USING (true);

-- 3️⃣ Criar política de INSERT (donos de loja podem adicionar ingredientes aos seus produtos)
CREATE POLICY "Store owners can insert ingredients for their products"
  ON public.ingredients
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.products p
      JOIN public.stores s ON s.id = p.store_id
      WHERE p.id = product_id
      AND s.owner_id = auth.uid()
    )
  );

-- 4️⃣ Criar política de UPDATE (donos de loja podem atualizar ingredientes dos seus produtos)
CREATE POLICY "Store owners can update ingredients of their products"
  ON public.ingredients
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.products p
      JOIN public.stores s ON s.id = p.store_id
      WHERE p.id = product_id
      AND s.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.products p
      JOIN public.stores s ON s.id = p.store_id
      WHERE p.id = product_id
      AND s.owner_id = auth.uid()
    )
  );

-- 5️⃣ Criar política de DELETE (donos de loja podem deletar ingredientes dos seus produtos)
CREATE POLICY "Store owners can delete ingredients of their products"
  ON public.ingredients
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.products p
      JOIN public.stores s ON s.id = p.store_id
      WHERE p.id = product_id
      AND s.owner_id = auth.uid()
    )
  );

-- ============================================
-- ✅ VERIFICAR SE FUNCIONOU
-- ============================================

-- Verificar políticas criadas
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'ingredients'
ORDER BY policyname;

-- Deve mostrar 4 políticas:
-- 1. Anyone can view ingredients (SELECT)
-- 2. Store owners can insert ingredients for their products (INSERT)
-- 3. Store owners can update ingredients of their products (UPDATE)
-- 4. Store owners can delete ingredients of their products (DELETE)

-- ============================================
-- 🧪 TESTAR
-- ============================================

-- Após executar este SQL:
-- 1. Volte ao painel admin
-- 2. Tente adicionar/editar um produto com ingredientes
-- 3. Deve funcionar sem erro 403!
