import React, { createContext, useContext, useState, useEffect } from 'react';
import { useAuth } from './AuthContext';
import { subscriptionService, UserSubscription } from '@/services/subscriptionService';

interface SubscriptionContextType {
  subscription: UserSubscription | null;
  isSubscriptionActive: boolean;
  isLoading: boolean;
  refreshSubscription: () => Promise<void>;
}

const SubscriptionContext = createContext<SubscriptionContextType | undefined>(undefined);

export const SubscriptionProvider = ({ children }: { children: React.ReactNode }) => {
  const { user } = useAuth();
  const [subscription, setSubscription] = useState<UserSubscription | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const loadSubscription = async () => {
    if (!user) {
      setSubscription(null);
      setIsLoading(false);
      return;
    }

    try {
      const data = await subscriptionService.getActiveSubscription(user.id);
      setSubscription(data);
    } catch (error) {
      console.error('Erro ao carregar assinatura:', error);
      setSubscription(null);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadSubscription();
  }, [user]);

  const refreshSubscription = async () => {
    setIsLoading(true);
    await loadSubscription();
  };

  const isSubscriptionActive = subscription !== null && subscription.status === 'active' && subscription.days_remaining > 0;

  return (
    <SubscriptionContext.Provider value={{
      subscription,
      isSubscriptionActive,
      isLoading,
      refreshSubscription
    }}>
      {children}
    </SubscriptionContext.Provider>
  );
};

export const useSubscription = () => {
  const context = useContext(SubscriptionContext);
  if (!context) {
    throw new Error('useSubscription must be used within SubscriptionProvider');
  }
  return context;
};
