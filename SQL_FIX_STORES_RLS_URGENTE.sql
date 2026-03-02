-- ============================================
-- 🚨 EXECUTAR AGORA NO SUPABASE SQL EDITOR
-- Fix RLS da tabela stores
-- ============================================

-- 🐛 PROBLEMA:
-- A política antiga usava "FOR ALL" com apenas USING,
-- mas INSERT precisa de WITH CHECK também.

-- ✅ SOLUÇÃO:
-- Criar políticas separadas para cada operação (SELECT, INSERT, UPDATE, DELETE)

-- 1️⃣ Remover políticas antigas
DROP POLICY IF EXISTS "Active stores are viewable by everyone" ON public.stores;
DROP POLICY IF EXISTS "Owners can manage their stores" ON public.stores;

-- 2️⃣ Criar política de leitura pública (para clientes verem lojas)
CREATE POLICY "Anyone can view active stores"
  ON public.stores
  FOR SELECT
  USING (is_active = true);

-- 3️⃣ Criar política de leitura para donos (ver suas próprias lojas, mesmo inativas)
CREATE POLICY "Owners can view their stores"
  ON public.stores
  FOR SELECT
  TO authenticated
  USING (auth.uid() = owner_id);

-- 4️⃣ Criar política de INSERT (usuários autenticados podem criar lojas)
CREATE POLICY "Authenticated users can create stores"
  ON public.stores
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);

-- 5️⃣ Criar política de UPDATE (donos podem atualizar suas lojas)
CREATE POLICY "Owners can update their stores"
  ON public.stores
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- 6️⃣ Criar política de DELETE (donos podem deletar suas lojas)
CREATE POLICY "Owners can delete their stores"
  ON public.stores
  FOR DELETE
  TO authenticated
  USING (auth.uid() = owner_id);

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
WHERE tablename = 'stores'
ORDER BY policyname;

-- Deve mostrar 5 políticas:
-- 1. Anyone can view active stores (SELECT)
-- 2. Authenticated users can create stores (INSERT)
-- 3. Owners can delete their stores (DELETE)
-- 4. Owners can update their stores (UPDATE)
-- 5. Owners can view their stores (SELECT)

-- ============================================
-- 🧪 TESTAR
-- ============================================

-- Após executar este SQL:
-- 1. Volte ao painel
-- 2. Tente criar uma nova loja
-- 3. Deve funcionar sem erro 403!
