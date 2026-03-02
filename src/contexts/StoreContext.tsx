import React, { createContext, useContext, useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Store } from '@/types';
import { useAuth } from './AuthContext';

interface StoreContextType {
  // Loja atual (para visualização pública ou admin)
  currentStore: Store | null;
  
  // Lojas do usuário autenticado (para admin)
  userStores: Store[];
  
  // Funções
  loadStoreBySlug: (slug: string) => Promise<Store | null>;
  loadUserStores: () => Promise<void>;
  createStore: (storeData: Partial<Store>) => Promise<Store>;
  updateStore: (storeId: string, storeData: Partial<Store>) => Promise<void>;
  setCurrentStore: (store: Store | null) => void;
  
  // Estado
  loading: boolean;
  storesLoaded: boolean;
}

const StoreContext = createContext<StoreContextType | undefined>(undefined);

export const StoreProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [currentStore, setCurrentStore] = useState<Store | null>(null);
  const [userStores, setUserStores] = useState<Store[]>([]);
  const [loading, setLoading] = useState(false);
  const [storesLoaded, setStoresLoaded] = useState(false);
  const { user } = useAuth();

  // Carregar loja por slug (para página pública)
  const loadStoreBySlug = async (slug: string): Promise<Store | null> => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('stores')
        .select('*')
        .eq('slug', slug)
        .eq('is_active', true)
        .single();

      if (error) {
        console.error('Erro ao carregar loja:', error);
        return null;
      }

      const store: Store = {
        ...data,
        delivery_fee: data.delivery_fee ?? 5.00,
        is_open: data.is_open ?? true,
        created_at: new Date(data.created_at),
        updated_at: new Date(data.updated_at),
      };

      setCurrentStore(store);
      return store;
    } catch (error) {
      console.error('Erro ao carregar loja:', error);
      return null;
    } finally {
      setLoading(false);
    }
  };

  // Carregar lojas do usuário autenticado
  const loadUserStores = async () => {
    if (!user?.id) {
      setUserStores([]);
      setStoresLoaded(true);
      return;
    }

    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('stores')
        .select('*')
        .eq('owner_id', user.id)
        .order('created_at', { ascending: false });

      if (error) throw error;

      const stores: Store[] = (data || []).map(store => ({
        ...store,
        delivery_fee: store.delivery_fee ?? 5.00,
        is_open: store.is_open ?? true,
        created_at: new Date(store.created_at),
        updated_at: new Date(store.updated_at),
      }));

      setUserStores(stores);
      setStoresLoaded(true);

      // Se houver apenas uma loja, define como atual
      if (stores.length === 1 && !currentStore) {
        setCurrentStore(stores[0]);
      }
    } catch (error) {
      console.error('Erro ao carregar lojas do usuário:', error);
      setStoresLoaded(true);
    } finally {
      setLoading(false);
    }
  };

  // Criar nova loja
  const createStore = async (storeData: Partial<Store>): Promise<Store> => {
    if (!user?.id) {
      throw new Error('Usuário não autenticado');
    }

    try {
      setLoading(true);

      // Gerar slug único
      const { data: slugData, error: slugError } = await supabase
        .rpc('generate_unique_slug', { base_name: storeData.name || 'Minha Loja' });

      if (slugError) throw slugError;

      const slug = slugData as string;

      const { data, error } = await supabase
        .from('stores')
        .insert({
          owner_id: user.id,
          name: storeData.name,
          slug,
          description: storeData.description || '',
          phone: storeData.phone || '',
          email: storeData.email || '',
          address: storeData.address || '',
          city: storeData.city || '',
          state: storeData.state || '',
          zip_code: storeData.zip_code || '',
          logo_url: storeData.logo_url || null,
          background_urls: storeData.background_urls || null,
          primary_color: storeData.primary_color || '#FF7A30',
          delivery_fee: storeData.delivery_fee || 5.00,
          is_active: true,
          is_open: true,
        })
        .select()
        .single();

      if (error) throw error;

      const newStore: Store = {
        ...data,
        delivery_fee: data.delivery_fee ?? 5.00,
        is_open: data.is_open ?? true,
        created_at: new Date(data.created_at),
        updated_at: new Date(data.updated_at),
      };

      setUserStores(prev => [newStore, ...prev]);
      setCurrentStore(newStore);

      return newStore;
    } catch (error) {
      console.error('Erro ao criar loja:', error);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  // Atualizar loja
  const updateStore = async (storeId: string, storeData: Partial<Store>) => {
    try {
      setLoading(true);

      // Remover campos de data do objeto de atualização
      const { created_at, updated_at, ...updateData } = storeData as any;

      const { error } = await supabase
        .from('stores')
        .update(updateData)
        .eq('id', storeId);

      if (error) throw error;

      // Atualizar estado local
      setUserStores(prev =>
        prev.map(store =>
          store.id === storeId ? { ...store, ...storeData } : store
        )
      );

      if (currentStore?.id === storeId) {
        setCurrentStore(prev => prev ? { ...prev, ...storeData } : null);
      }
    } catch (error) {
      console.error('Erro ao atualizar loja:', error);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  // Carregar lojas do usuário quando autenticar
  useEffect(() => {
    if (user?.id) {
      console.log('StoreContext - Carregando lojas para usuário:', user.id);
      setStoresLoaded(false);
      loadUserStores();
    } else {
      console.log('StoreContext - Sem usuário, limpando lojas');
      setUserStores([]);
      setStoresLoaded(false);
      setLoading(false); // Importante: setar loading como false quando não há usuário
      // Não limpa currentStore para permitir visualização pública
    }
  }, [user?.id]);

  return (
    <StoreContext.Provider
      value={{
        currentStore,
        userStores,
        loadStoreBySlug,
        loadUserStores,
        createStore,
        updateStore,
        setCurrentStore,
        loading,
        storesLoaded,
      }}
    >
      {children}
    </StoreContext.Provider>
  );
};

export const useStore = () => {
  const context = useContext(StoreContext);
  if (context === undefined) {
    throw new Error('useStore must be used within a StoreProvider');
  }
  return context;
};
