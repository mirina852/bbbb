
import React, { useState, useEffect } from 'react';
import AdminLayout from '@/layouts/AdminLayout';
import PageHeader from '@/components/common/PageHeader';
import OrdersTable from '@/components/orders/OrdersTable';
import OrderDetailsDialog from '@/components/orders/OrderDetailsDialog';
import { ordersService } from '@/services/supabaseService';
import { Order, OrderStatus } from '@/types';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Input } from '@/components/ui/input';
import { toast } from "sonner";
import { useStore } from '@/contexts/StoreContext';

const Orders = () => {
  const { currentStore } = useStore();
  const [orders, setOrders] = useState<Order[]>([]);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [isDetailsOpen, setIsDetailsOpen] = useState(false);
  const [statusFilter, setStatusFilter] = useState<string>('confirmed_only');
  const [searchTerm, setSearchTerm] = useState('');
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    if (currentStore?.id) {
      loadOrders();
    }
  }, [currentStore?.id]);

  useEffect(() => {
    if (currentStore?.id) {
      loadOrders();
    }
  }, [statusFilter]);
  
  const loadOrders = async () => {
    if (!currentStore?.id) return;
    
    try {
      // Buscar apenas pedidos da loja atual
      // Se o filtro for 'confirmed_only', buscar apenas pedidos confirmados
      // Se for 'all', buscar todos os pedidos
      const data = statusFilter === 'confirmed_only' 
        ? await ordersService.getAll(currentStore.id)
        : await ordersService.getAllIncludingPending(currentStore.id);
      setOrders(data);
    } catch (error) {
      console.error('Error loading orders:', error);
      toast.error('Erro ao carregar pedidos');
    } finally {
      setLoading(false);
    }
  };
  
  const handleViewDetails = (order: Order) => {
    setSelectedOrder(order);
    setIsDetailsOpen(true);
  };
  
  const handleUpdateStatus = async (id: string, status: OrderStatus) => {
    try {
      await ordersService.updateStatus(id, status);
      setOrders(
        orders.map(order => 
          order.id === id 
            ? { ...order, status, updatedAt: new Date() }
            : order
        )
      );
      toast.success(`Status do pedido atualizado para ${status}`);
    } catch (error) {
      console.error('Error updating order status:', error);
      toast.error('Erro ao atualizar status do pedido');
    }
  };
  
  const filteredOrders = orders.filter(order => {
    const matchesStatus = statusFilter === 'confirmed_only' || statusFilter === 'all' || order.status === statusFilter;
    
    const matchesSearch = 
      order.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      order.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      order.items.some(item => item.productName.toLowerCase().includes(searchTerm.toLowerCase()));
    
    return matchesStatus && matchesSearch;
  });
  
  return (
    <AdminLayout>
      <PageHeader 
        title="Pedidos" 
        description="Gerencie os pedidos dos clientes"
      />
      
      <div className="flex flex-col sm:flex-row gap-4 mb-6">
        <Input
          placeholder="Buscar pedidos..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="flex-1 sm:max-w-xs h-12 text-base"
        />
        
        <Select
          value={statusFilter}
          onValueChange={setStatusFilter}
        >
          <SelectTrigger className="w-full sm:w-[180px] h-12 text-base">
            <SelectValue placeholder="Filtrar por status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="confirmed_only">✅ Apenas Confirmados</SelectItem>
            <SelectItem value="all">📋 Todos (incluindo pendentes)</SelectItem>
            <SelectItem value="pago">💰 Pago</SelectItem>
            <SelectItem value="pending">⏳ Pendente</SelectItem>
            <SelectItem value="preparing">👨‍🍳 Preparando</SelectItem>
            <SelectItem value="ready">🍽️ Pronto</SelectItem>
            <SelectItem value="out_for_delivery">🚚 Saiu para entrega</SelectItem>
            <SelectItem value="delivered">✅ Entregue</SelectItem>
            <SelectItem value="cancelled">❌ Cancelado</SelectItem>
          </SelectContent>
        </Select>
      </div>
      
      <OrdersTable 
        orders={filteredOrders} 
        onViewDetails={handleViewDetails} 
      />
      
      {filteredOrders.length === 0 && !loading && (
        <div className="text-center py-12 bg-muted/30 rounded-lg mt-6">
          <p className="text-muted-foreground text-lg">Nenhum pedido encontrado</p>
          <p className="text-muted-foreground/70 text-sm mt-2">
            Tente ajustar os filtros ou aguarde novos pedidos
          </p>
        </div>
      )}
      
      {loading && (
        <div className="text-center py-12 bg-muted/30 rounded-lg mt-6">
          <div className="animate-pulse text-center space-y-4">
            <div className="h-8 w-8 rounded-full bg-primary/20 mx-auto animate-spin border-2 border-primary border-t-transparent"></div>
            <p className="text-muted-foreground">Carregando pedidos...</p>
          </div>
        </div>
      )}
      
      <OrderDetailsDialog
        order={selectedOrder}
        isOpen={isDetailsOpen}
        onClose={() => setIsDetailsOpen(false)}
        onUpdateStatus={handleUpdateStatus}
      />
    </AdminLayout>
  );
};

export default Orders;
