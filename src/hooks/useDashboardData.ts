import { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { ordersService, productsService } from '@/services/supabaseService';
import { Order, Product } from '@/types';
import { useStore } from '@/contexts/StoreContext';

interface DashboardData {
  orders: Order[];
  products: Product[];
  totalOrders: number;
  totalRevenue: number;
  totalCustomers: number;
  totalProducts: number;
}

export const useDashboardData = () => {
  const { currentStore } = useStore();
  const [dashboardData, setDashboardData] = useState<DashboardData>({
    orders: [],
    products: [],
    totalOrders: 0,
    totalRevenue: 0,
    totalCustomers: 0,
    totalProducts: 0
  });

  // Buscar pedidos da loja atual (incluindo pendentes)
  const { data: orders = [], refetch: refetchOrders } = useQuery({
    queryKey: ['orders', currentStore?.id],
    queryFn: () => currentStore?.id ? ordersService.getAllIncludingPending(currentStore.id) : Promise.resolve([]),
    enabled: !!currentStore?.id,
    refetchInterval: 30000, // Refresh every 30 seconds as fallback
  });

  // Buscar produtos da loja atual
  const { data: products = [], refetch: refetchProducts } = useQuery({
    queryKey: ['products', currentStore?.id],
    queryFn: () => currentStore?.id ? productsService.getAllForAdmin(currentStore.id) : Promise.resolve([]),
    enabled: !!currentStore?.id,
    refetchInterval: 30000,
  });

  // Atualizar dados calculados quando orders ou products mudarem
  useEffect(() => {
    const totalOrders = orders.length;
    const totalRevenue = orders.reduce((sum, order) => sum + order.total, 0);
    const totalCustomers = new Set(orders.map(order => order.customerName)).size;
    const totalProducts = products.filter(p => p.available).length;

    setDashboardData({
      orders,
      products,
      totalOrders,
      totalRevenue,
      totalCustomers,
      totalProducts
    });
  }, [orders, products]);

  // Configurar real-time updates para pedidos
  useEffect(() => {
    const channel = supabase
      .channel('dashboard-orders')
      .on(
        'postgres_changes',
        {
          event: '*', // Listen to all events (INSERT, UPDATE, DELETE)
          schema: 'public',
          table: 'orders'
        },
        () => {
          // Refetch orders when any change occurs
          refetchOrders();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [refetchOrders]);

  // Configurar real-time updates para produtos
  useEffect(() => {
    const channel = supabase
      .channel('dashboard-products')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'products'
        },
        () => {
          refetchProducts();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [refetchProducts]);

  return dashboardData;
};

// Função para gerar dados do gráfico de pedidos
export const generateOrdersChartData = (orders: Order[]) => {
  const data = [];
  const now = new Date();
  
  for (let i = 6; i >= 0; i--) {
    const date = new Date(now);
    date.setDate(date.getDate() - i);
    
    const dayOrders = orders.filter(order => {
      const orderDate = new Date(order.createdAt);
      return orderDate.getDate() === date.getDate() && 
             orderDate.getMonth() === date.getMonth() && 
             orderDate.getFullYear() === date.getFullYear();
    });
    
    data.push({
      name: date.toLocaleDateString('pt-BR', { weekday: 'short' }),
      orders: dayOrders.length,
      revenue: dayOrders.reduce((sum, order) => sum + order.total, 0)
    });
  }
  
  return data;
};

// Função para gerar dados do gráfico de status dos pedidos
export const generateOrderStatusChartData = (orders: Order[]) => {
  const statusCounts = {
    pending: 0,
    preparing: 0,
    ready: 0,
    out_for_delivery: 0,
    delivered: 0,
    cancelled: 0
  };
  
  orders.forEach(order => {
    statusCounts[order.status]++;
  });
  
  return Object.keys(statusCounts).map(status => ({
    name: status.charAt(0).toUpperCase() + status.slice(1),
    value: statusCounts[status as keyof typeof statusCounts]
  }));
};