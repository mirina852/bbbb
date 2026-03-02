import { useEffect } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useStore } from '@/contexts/StoreContext';

/**
 * Hook para gerenciar lojas do usuário autenticado
 * 
 * Lógica:
 * - Carrega as lojas do usuário
 * - Se tiver apenas 1 loja, define automaticamente como currentStore
 * - Retorna informações sobre as lojas
 * 
 * Nota: Este hook NÃO faz redirecionamentos automáticos
 */
export const useStoreRedirect = () => {
  const { user, isLoading: authLoading } = useAuth();
  const { userStores, currentStore, setCurrentStore, loadUserStores, loading: storeLoading } = useStore();

  useEffect(() => {
    // Aguarda carregamento
    if (authLoading || storeLoading) return;

    // Não redireciona se não estiver autenticado
    if (!user) return;

    // Carrega lojas do usuário e define a loja automaticamente se necessário
    const checkAndSetStore = async () => {
      await loadUserStores();

      // Se tem apenas 1 loja, define como atual automaticamente
      if (userStores.length === 1) {
        if (!currentStore || currentStore.id !== userStores[0].id) {
          console.log('Definindo loja única como atual:', userStores[0].name);
          setCurrentStore(userStores[0]);
        }
      }
    };

    checkAndSetStore();
  }, [user, authLoading, storeLoading]);

  return {
    hasStores: userStores.length > 0,
    hasMultipleStores: userStores.length > 1,
    currentStore,
    userStores,
  };
};
