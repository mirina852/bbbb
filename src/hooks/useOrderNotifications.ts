import { useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import { useNotificationSettings } from '@/contexts/NotificationSettingsContext';
import { useStore } from '@/contexts/StoreContext';
import { notificationSounds } from '@/utils/notificationSounds';
import { Order } from '@/types';
import { OrderNotificationTitle, OrderNotificationDescription } from '@/components/notifications/OrderNotificationContent';

export const useOrderNotifications = () => {
  const { toast } = useToast();
  const { settings } = useNotificationSettings();
  const { currentStore, userStores } = useStore();

  useEffect(() => {
    // Não criar subscription se não houver loja
    if (!currentStore && userStores.length === 0) {
      console.log('Nenhuma loja disponível para receber notificações');
      return;
    }

    // Usar a loja atual ou a primeira loja do usuário
    const storeId = currentStore?.id || userStores[0]?.id;
    
    if (!storeId) {
      console.log('Store ID não disponível para notificações');
      return;
    }

    console.log('Iniciando subscription de notificações para loja:', storeId);

    // Create a channel to listen for new orders filtered by store_id
    const channel = supabase
      .channel(`new-orders-${storeId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'orders',
          filter: `store_id=eq.${storeId}`
        },
        (payload) => {
          console.log('Novo pedido recebido:', payload);
          const newOrder = payload.new as Order;
          
          // Só mostrar notificação se estiver habilitada
          if (!settings.enabled) {
            console.log('Notificações desabilitadas');
            return;
          }
          
          // Show notification toast com visual melhorado
          toast({
            title: OrderNotificationTitle() as any,
            description: OrderNotificationDescription({ order: newOrder }) as any,
            duration: settings.duration,
            className: "border-l-4 border-l-green-500 shadow-lg",
          });

          // Reproduzir som se habilitado
          if (settings.soundEnabled) {
            notificationSounds.playSound(settings.soundType, settings.volume, settings.repeatCount);
          }
        }
      )
      .subscribe((status) => {
        console.log('Status da subscription:', status);
      });

    // Cleanup subscription on unmount
    return () => {
      console.log('Removendo subscription de notificações');
      supabase.removeChannel(channel);
    };
  }, [toast, settings, currentStore, userStores]);
};