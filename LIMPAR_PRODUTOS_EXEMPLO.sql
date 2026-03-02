-- ============================================
-- LIMPAR PRODUTOS DE EXEMPLO (SEM store_id)
-- ============================================
-- Este script remove produtos que foram inseridos pelas migrations antigas
-- e que não têm store_id (produtos de exemplo globais)

-- 1. Ver quantos produtos sem store_id existem
SELECT 
  COUNT(*) as total_produtos_sem_loja,
  STRING_AGG(name, ', ') as nomes_produtos
FROM public.products
WHERE store_id IS NULL;

-- 2. Ver detalhes dos produtos sem store_id
SELECT 
  id,
  name,
  description,
  price,
  category,
  store_id,
  created_at
FROM public.products
WHERE store_id IS NULL
ORDER BY created_at;

-- ============================================
-- DELETAR PRODUTOS SEM store_id
-- ============================================
-- ⚠️ CUIDADO: Isso vai deletar TODOS os produtos sem store_id!
-- Execute apenas se tiver certeza que quer remover os produtos de exemplo

-- Descomente a linha abaixo para executar a limpeza:
-- DELETE FROM public.products WHERE store_id IS NULL;

-- ============================================
-- VERIFICAR RESULTADO
-- ============================================
-- Após deletar, verificar se ainda há produtos sem store_id
SELECT 
  COUNT(*) as produtos_sem_loja_restantes
FROM public.products
WHERE store_id IS NULL;

-- Ver todos os produtos com suas lojas
SELECT 
  p.id,
  p.name,
  p.price,
  p.store_id,
  s.name as loja_nome,
  s.slug as loja_slug
FROM public.products p
LEFT JOIN public.stores s ON p.store_id = s.id
ORDER BY s.name, p.name;

-- ============================================
-- ALTERNATIVA: Atribuir produtos a uma loja específica
-- ============================================
-- Se você quiser MANTER os produtos mas atribuí-los a uma loja:

-- 1. Ver suas lojas
SELECT id, name, slug FROM public.stores;

-- 2. Atribuir produtos sem store_id a uma loja específica
-- Substitua '[ID-DA-SUA-LOJA]' pelo ID da loja que você quer
-- UPDATE public.products 
-- SET store_id = '[ID-DA-SUA-LOJA]'
-- WHERE store_id IS NULL;

-- ============================================
-- PREVENIR NOVOS PRODUTOS SEM store_id
-- ============================================
-- Tornar store_id obrigatório (opcional, mas recomendado)
-- ⚠️ Só execute isso DEPOIS de limpar ou atribuir os produtos existentes!

-- ALTER TABLE public.products 
-- ALTER COLUMN store_id SET NOT NULL;

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- Após executar a limpeza:
-- ✅ Nenhum produto sem store_id
-- ✅ Cada produto pertence a uma loja específica
-- ✅ Novas contas não verão produtos de outras lojas
