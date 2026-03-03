import React, { createContext, useContext, useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from './AuthContext';
import { useToast } from '@/hooks/use-toast';

interface MercadoPagoConfig {
  publicKey: string;
  accessToken: string;
}

// Buscar store_id do usuário ou por slug
const getCurrentStoreId = async (userId?: string): Promise<string | null> => {
  if (!userId) return null;
  
  const { data, error } = await supabase
    .from('stores' as any)
    .select('id')
    .eq('owner_id', userId)
    .eq('is_active', true)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();
  
  if (error || !data) return null;
  return (data as any).id || null;
};

// Buscar store_id por slug (para páginas públicas)
const getStoreIdBySlug = async (slug: string): Promise<string | null> => {
  const { data, error } = await supabase
    .from('stores' as any)
    .select('id')
    .eq('slug', slug)
    .eq('is_active', true)
    .maybeSingle();
  
  if (error || !data) return null;
  return (data as any).id || null;
};

interface MercadoPagoContextType {
  config: MercadoPagoConfig | null;
  isConfigured: boolean;
  saveConfig: (config: MercadoPagoConfig, storeId?: string) => Promise<void>;
  loadConfig: (storeId?: string) => Promise<void>;
  loadConfigBySlug: (slug: string) => Promise<void>;
}

const MercadoPagoContext = createContext<MercadoPagoContextType | undefined>(undefined);

export const MercadoPagoProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [config, setConfig] = useState<MercadoPagoConfig | null>(null);
  const [hasCredentials, setHasCredentials] = useState(false);
  const { user } = useAuth();
  const { toast } = useToast();

  // Limpar credenciais quando usuário fizer logout
  React.useEffect(() => {
    if (!user) {
      console.log('🔍 Usuário deslogado, limpando credenciais Mercado Pago...');
      setConfig(null);
      setHasCredentials(false);
    }
  }, [user]);

  // Carregar configuração do Supabase por store_id
  const loadConfig = async (storeId?: string) => {
    try {
      console.log('🔍 MercadoPagoContext.loadConfig - Iniciando...');
      console.log('🔍 storeId recebido:', storeId);
      console.log('🔍 Usuário autenticado?', !!user?.id);
      
      let targetStoreId = storeId;
      
      // Se não foi passado store_id, tenta buscar do usuário atual
      if (!targetStoreId && user?.id) {
        targetStoreId = await getCurrentStoreId(user.id);
        console.log('🔍 Store ID do usuário:', targetStoreId);
      }
      
      if (!targetStoreId) {
        console.log('❌ Nenhum store_id disponível para carregar credenciais');
        setHasCredentials(false);
        return;
      }
      
      console.log('🔍 Buscando credenciais para store_id:', targetStoreId);
      
      const { data, error } = await supabase
        .from('merchant_payment_credentials')
        .select('public_key, access_token, store_id')
        .eq('store_id', targetStoreId)
        .eq('is_active', true)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (error) {
        console.error('❌ Erro ao buscar credenciais:', error);
        if (error.code !== 'PGRST116') { // Ignora erro de "não encontrado"
          console.error('❌ Detalhes do erro:', {
            code: error.code,
            message: error.message,
            details: error.details,
            hint: error.hint
          });
        }
        setHasCredentials(false);
        return;
      }

      console.log('🔍 Dados retornados:', data ? 'SIM' : 'NÃO');
      
      if (data) {
        console.log('✅ Credenciais encontradas!');
        console.log('✅ Public Key:', data.public_key ? 'PRESENTE' : 'AUSENTE');
        console.log('✅ Access Token:', data.access_token ? 'PRESENTE' : 'AUSENTE');
        
        setConfig({
          publicKey: data.public_key,
          accessToken: data.access_token, // Retorna access token para funcionar
        });
        // Marca que há credenciais válidas no banco
        const hasValidCredentials = !!(data.public_key && data.access_token);
        console.log('✅ Credenciais válidas?', hasValidCredentials);
        setHasCredentials(hasValidCredentials);
      } else {
        console.log('❌ Nenhuma credencial encontrada no banco');
        setHasCredentials(false);
      }
    } catch (error) {
      console.error('❌ Exceção ao carregar configuração do Mercado Pago:', error);
      setHasCredentials(false);
    }
  };

  // Carregar configuração por slug da loja (para páginas públicas)
  const loadConfigBySlug = async (slug: string) => {
    try {
      const storeId = await getStoreIdBySlug(slug);
      if (storeId) {
        await loadConfig(storeId);
      } else {
        console.log('Loja não encontrada para slug:', slug);
        setHasCredentials(false);
      }
    } catch (error) {
      console.error('Erro ao carregar configuração por slug:', error);
      setHasCredentials(false);
    }
  };

  // Salvar configuração no Supabase
  const saveConfig = async (newConfig: MercadoPagoConfig, storeId?: string) => {
    try {
      if (!user?.id) {
        toast({
          title: 'Erro',
          description: 'Você precisa estar autenticado para salvar as configurações.',
          variant: 'destructive',
        });
        throw new Error('Usuário não autenticado');
      }

      // Buscar store_id do usuário se não foi passado
      let targetStoreId = storeId;
      if (!targetStoreId) {
        targetStoreId = await getCurrentStoreId(user.id);
      }
      
      if (!targetStoreId) {
        toast({
          title: 'Erro',
          description: 'Você precisa criar uma loja antes de configurar o Mercado Pago.',
          variant: 'destructive',
        });
        throw new Error('Loja não encontrada');
      }

      // Se o accessToken estiver vazio, buscar o token existente
      let accessTokenToSave = newConfig.accessToken;
      if (!accessTokenToSave) {
        const { data: existingData } = await supabase
          .from('merchant_payment_credentials')
          .select('access_token')
          .eq('store_id', targetStoreId)
          .eq('is_active', true)
          .order('created_at', { ascending: false })
          .limit(1)
          .maybeSingle();
        
        if (existingData) {
          accessTokenToSave = existingData.access_token;
        }
      }

      // Validar que temos um access token
      if (!accessTokenToSave) {
        toast({
          title: 'Erro',
          description: 'Access Token é obrigatório.',
          variant: 'destructive',
        });
        throw new Error('Access Token não fornecido');
      }

      // Desativar credenciais antigas desta loja
      await supabase
        .from('merchant_payment_credentials')
        .update({ is_active: false })
        .eq('store_id', targetStoreId);

      // Inserir nova credencial
      const { error } = await supabase
        .from('merchant_payment_credentials')
        .insert({
          user_id: user.id,
          store_id: targetStoreId,
          public_key: newConfig.publicKey,
          access_token: accessTokenToSave,
          is_active: true,
        });

      if (error) {
        console.error('Erro ao salvar credenciais:', error);
        console.error('Detalhes do erro:', {
          message: error.message,
          code: error.code,
          details: error.details,
          hint: error.hint
        });
        
        let errorMessage = 'Não foi possível salvar as credenciais. Tente novamente.';
        
        // Mensagens específicas por tipo de erro
        if (error.message?.includes('relation') && error.message?.includes('does not exist')) {
          errorMessage = 'Tabela não encontrada. Execute a migration primeiro.';
        } else if (error.message?.includes('violates row-level security policy')) {
          errorMessage = 'Você não tem permissão para salvar credenciais. Verifique se tem uma assinatura ativa.';
        } else if (error.message?.includes('function') && error.message?.includes('does not exist')) {
          errorMessage = 'Erro de configuração do banco. Entre em contato com o suporte.';
        } else if (error.message?.includes('column') && error.message?.includes('does not exist')) {
          errorMessage = 'Execute a migration para adicionar a coluna store_id.';
        }
        
        toast({
          title: 'Erro ao salvar',
          description: errorMessage,
          variant: 'destructive',
        });
        throw error;
      }

      // Atualiza o estado local, mas mantém o accessToken vazio por segurança
      setConfig({
        publicKey: newConfig.publicKey,
        accessToken: '',
      });
      
      // Marca que há credenciais válidas salvas
      setHasCredentials(true);
      
      toast({
        title: 'Sucesso!',
        description: 'Credenciais do Mercado Pago salvas com sucesso.',
      });
    } catch (error) {
      console.error('Erro ao salvar configuração do Mercado Pago:', error);
      throw error;
    }
  };

  useEffect(() => {
    // Carrega credenciais quando houver usuário autenticado
    // Não limpa as credenciais se o usuário não estiver autenticado
    // pois elas podem ter sido carregadas por loadConfig(storeId) em páginas públicas
    if (user?.id) {
      loadConfig();
    }
    // Se não há usuário, mantém o estado atual (não reseta)
  }, [user?.id]);

  // isConfigured agora verifica se há credenciais no banco, não no estado local
  const isConfigured = hasCredentials;

  return (
    <MercadoPagoContext.Provider value={{ config, isConfigured, saveConfig, loadConfig, loadConfigBySlug }}>
      {children}
    </MercadoPagoContext.Provider>
  );
};

export const useMercadoPago = () => {
  const context = useContext(MercadoPagoContext);
  if (context === undefined) {
    throw new Error('useMercadoPago must be used within a MercadoPagoProvider');
  }
  return context;
};
