-- ============================================
-- LIMPAR E RECRIAR CATEGORIAS
-- ============================================

-- 1. Ver categorias atuais
SELECT id, store_id, name, slug, position 
FROM public.categories
ORDER BY store_id, position;

-- 2. Deletar todas as categorias (CUIDADO!)
-- DELETE FROM public.categories;

-- 3. Recriar categorias padrão para cada loja
INSERT INTO public.categories (store_id, name, icon, position)
SELECT 
  s.id AS store_id,
  'Lanches' AS name,
  'Sandwich' AS icon,
  0 AS position
FROM public.stores s
ON CONFLICT DO NOTHING;

INSERT INTO public.categories (store_id, name, icon, position)
SELECT 
  s.id AS store_id,
  'Bebidas' AS name,
  'Coffee' AS icon,
  1 AS position
FROM public.stores s
ON CONFLICT DO NOTHING;

INSERT INTO public.categories (store_id, name, icon, position)
SELECT 
  s.id AS store_id,
  'Sobremesas' AS name,
  'IceCream' AS icon,
  2 AS position
FROM public.stores s
ON CONFLICT DO NOTHING;

-- 4. Ver categorias criadas
SELECT id, store_id, name, slug, icon, position 
FROM public.categories
ORDER BY store_id, position;
