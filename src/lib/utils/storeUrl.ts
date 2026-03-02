/**
 * Utilitário para gerar URLs de lojas
 */

/**
 * Retorna a URL base do site
 * Em produção: usa variável de ambiente
 * Em desenvolvimento: usa localhost
 */
export const getBaseUrl = (): string => {
  // Se estiver em produção e tiver variável de ambiente
  if (import.meta.env.VITE_APP_URL) {
    return import.meta.env.VITE_APP_URL;
  }

  // Se estiver rodando no Vercel
  if (typeof window !== 'undefined' && window.location.hostname.includes('vercel.app')) {
    return window.location.origin;
  }

  // Desenvolvimento local
  if (typeof window !== 'undefined') {
    return window.location.origin;
  }

  // Fallback
  return 'http://localhost:8080';
};

/**
 * Gera a URL completa da loja baseado no slug
 * @param slug - Slug único da loja
 * @returns URL completa da loja pública
 */
export const getStoreUrl = (slug: string): string => {
  const baseUrl = getBaseUrl();
  return `${baseUrl}/${slug}`;
};

/**
 * Gera a URL do admin
 * @returns URL do painel administrativo
 */
export const getAdminUrl = (): string => {
  const baseUrl = getBaseUrl();
  return `${baseUrl}/admin`;
};

/**
 * Gera a URL de um produto específico
 * @param productId - ID do produto
 * @returns URL do produto
 */
export const getProductUrl = (productId: string): string => {
  const baseUrl = getBaseUrl();
  return `${baseUrl}/product/${productId}`;
};
