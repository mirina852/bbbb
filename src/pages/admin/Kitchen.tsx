import React, { useState, useEffect, useCallback, useMemo } from 'react';
import AdminLayout from '@/layouts/AdminLayout';
import { ordersService } from '@/services/supabaseService';
import { Order, OrderStatus } from '@/types';
import { useStore } from '@/contexts/StoreContext';
import { supabase } from '@/integrations/supabase/client';
import { toast } from 'sonner';
import KitchenColumn from '@/components/kitchen/KitchenColumn';
import { Clock, Flame, CheckCircle2, RefreshCw, ChefHat, Zap, Timer } from 'lucide-react';
import { Button } from '@/components/ui/button';

const KITCHEN_COLUMNS: {
  status: OrderStatus;
  title: string;
  icon: React.ReactNode;
  color: string;
  bgGradient: string;
  headerBg: string;
}[] = [
  {
    status: 'pago',
    title: 'Novos Pedidos',
    icon: <Clock className="h-5 w-5 text-white" />,
    color: 'text-amber-600',
    bgGradient: 'from-amber-50/80 to-orange-50/60 dark:from-amber-950/40 dark:to-orange-950/30',
    headerBg: 'bg-gradient-to-r from-amber-500 to-orange-500',
  },
  {
    status: 'preparing',
    title: 'Preparando',
    icon: <Flame className="h-5 w-5 text-white" />,
    color: 'text-blue-600',
    bgGradient: 'from-blue-50/80 to-cyan-50/60 dark:from-blue-950/40 dark:to-cyan-950/30',
    headerBg: 'bg-gradient-to-r from-blue-500 to-cyan-500',
  },
  {
    status: 'ready',
    title: 'Pronto',
    icon: <CheckCircle2 className="h-5 w-5 text-white" />,
    color: 'text-emerald-600',
    bgGradient: 'from-emerald-50/80 to-green-50/60 dark:from-emerald-950/40 dark:to-green-950/30',
    headerBg: 'bg-gradient-to-r from-emerald-500 to-green-500',
  },
];

const Kitchen = () => {
  const { currentStore } = useStore();
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadOrders = useCallback(async () => {
    if (!currentStore?.id) return;
    try {
      const data = await ordersService.getAll(currentStore.id);
      setOrders(data);
    } catch (error) {
      console.error('Erro ao carregar pedidos:', error);
      toast.error('Erro ao carregar pedidos');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [currentStore?.id]);

  useEffect(() => {
    loadOrders();
  }, [loadOrders]);

  // Real-time updates
  useEffect(() => {
    const channel = supabase
      .channel('kitchen-orders')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'orders' }, () => {
        loadOrders();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [loadOrders]);

  const handleRefresh = () => {
    setRefreshing(true);
    loadOrders();
  };

  const handleUpdateStatus = async (id: string, newStatus: OrderStatus) => {
    try {
      await ordersService.updateStatus(id, newStatus);
      setOrders(prev =>
        prev.map(o => (o.id === id ? { ...o, status: newStatus, updatedAt: new Date() } : o))
      );

      const labels: Record<OrderStatus, string> = {
        pending: 'Pendente',
        pago: 'Pago',
        preparing: 'Preparando',
        ready: 'Pronto',
        out_for_delivery: 'Saiu p/ Entrega',
        delivered: 'Entregue',
        cancelled: 'Cancelado',
      };
      toast.success(`Pedido → ${labels[newStatus]}`, {
        icon: '🍔',
      });
    } catch {
      toast.error('Erro ao atualizar status');
    }
  };

  const activeOrders = useMemo(
    () => orders.filter(o => !['delivered', 'cancelled'].includes(o.status)),
    [orders]
  );

  const stats = useMemo(() => {
    const pending = activeOrders.filter(o => o.status === 'pago').length;
    const preparing = activeOrders.filter(o => o.status === 'preparing').length;
    const ready = activeOrders.filter(o => o.status === 'ready').length;
    return { pending, preparing, ready, total: activeOrders.length };
  }, [activeOrders]);

  return (
    <AdminLayout>
      {/* Premium Header */}
      <div className="mb-6 space-y-5 animate-fade-in">
        {/* Title row */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-primary to-primary/70 flex items-center justify-center shadow-lg shadow-primary/30">
              <ChefHat className="h-7 w-7 text-primary-foreground" />
            </div>
            <div>
              <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-foreground">
                Painel da Cozinha
              </h1>
              <p className="text-sm text-muted-foreground mt-0.5 flex items-center gap-2">
                <span className="inline-flex items-center gap-1">
                  <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                  Tempo real
                </span>
                <span className="text-border">•</span>
                {stats.total} pedido{stats.total !== 1 ? 's' : ''} ativo{stats.total !== 1 ? 's' : ''}
              </p>
            </div>
          </div>
          <Button
            variant="outline"
            size="sm"
            onClick={handleRefresh}
            disabled={refreshing}
            className="gap-2 rounded-xl border-border/60 hover:bg-accent/50 transition-all duration-200 hover:scale-105"
          >
            <RefreshCw className={`h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
            Atualizar
          </Button>
        </div>

        {/* Stats cards */}
        <div className="grid grid-cols-3 gap-3">
          <div className="relative overflow-hidden rounded-2xl border border-amber-200/60 dark:border-amber-800/40 bg-gradient-to-br from-amber-50 to-orange-50/50 dark:from-amber-950/40 dark:to-orange-950/20 p-4 transition-all duration-200 hover:shadow-md">
            <div className="absolute -top-4 -right-4 w-16 h-16 rounded-full bg-amber-400/10 blur-xl" />
            <div className="relative">
              <div className="flex items-center gap-2 mb-2">
                <Timer className="h-4 w-4 text-amber-600 dark:text-amber-400" />
                <span className="text-[11px] font-bold text-amber-700 dark:text-amber-300 uppercase tracking-wider">Aguardando</span>
              </div>
              <p className="text-3xl font-black text-amber-600 dark:text-amber-400">{stats.pending}</p>
            </div>
          </div>
          <div className="relative overflow-hidden rounded-2xl border border-blue-200/60 dark:border-blue-800/40 bg-gradient-to-br from-blue-50 to-cyan-50/50 dark:from-blue-950/40 dark:to-cyan-950/20 p-4 transition-all duration-200 hover:shadow-md">
            <div className="absolute -top-4 -right-4 w-16 h-16 rounded-full bg-blue-400/10 blur-xl" />
            <div className="relative">
              <div className="flex items-center gap-2 mb-2">
                <Flame className="h-4 w-4 text-blue-600 dark:text-blue-400" />
                <span className="text-[11px] font-bold text-blue-700 dark:text-blue-300 uppercase tracking-wider">Preparando</span>
              </div>
              <p className="text-3xl font-black text-blue-600 dark:text-blue-400">{stats.preparing}</p>
            </div>
          </div>
          <div className="relative overflow-hidden rounded-2xl border border-emerald-200/60 dark:border-emerald-800/40 bg-gradient-to-br from-emerald-50 to-green-50/50 dark:from-emerald-950/40 dark:to-green-950/20 p-4 transition-all duration-200 hover:shadow-md">
            <div className="absolute -top-4 -right-4 w-16 h-16 rounded-full bg-emerald-400/10 blur-xl" />
            <div className="relative">
              <div className="flex items-center gap-2 mb-2">
                <Zap className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
                <span className="text-[11px] font-bold text-emerald-700 dark:text-emerald-300 uppercase tracking-wider">Prontos</span>
              </div>
              <p className="text-3xl font-black text-emerald-600 dark:text-emerald-400">{stats.ready}</p>
            </div>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-24">
          <div className="text-center space-y-5 animate-fade-in">
            <div className="relative">
              <div className="h-16 w-16 rounded-2xl bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center mx-auto">
                <div className="h-10 w-10 rounded-full border-4 border-primary border-t-transparent animate-spin" />
              </div>
            </div>
            <div>
              <p className="text-foreground font-bold text-lg">Carregando pedidos</p>
              <p className="text-muted-foreground text-sm mt-1">Conectando ao painel em tempo real…</p>
            </div>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 animate-fade-in">
          {KITCHEN_COLUMNS.map(col => {
            const columnOrders = activeOrders.filter(o => o.status === col.status);
            return (
              <KitchenColumn
                key={col.status}
                title={col.title}
                icon={col.icon}
                color={col.color}
                bgGradient={col.bgGradient}
                headerBg={col.headerBg}
                orders={columnOrders}
                onUpdateStatus={handleUpdateStatus}
              />
            );
          })}
        </div>
      )}
    </AdminLayout>
  );
};

export default Kitchen;
