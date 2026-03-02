import React, { useState, useEffect } from 'react';
import { Search, Package, Clock, CheckCircle, Truck, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { Order, OrderStatus } from '@/types';
import BottomNavigation from '@/components/customer/BottomNavigation';

const OrderTracking = () => {
  const [phone, setPhone] = useState('');
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();

  const getStatusIcon = (status: OrderStatus) => {
    switch (status) {
      case 'pending':
        return <Clock className="h-5 w-5" />;
      case 'preparing':
        return <Package className="h-5 w-5" />;
      case 'ready':
        return <CheckCircle className="h-5 w-5" />;
      case 'out_for_delivery':
        return <Truck className="h-5 w-5" />;
      case 'delivered':
        return <Truck className="h-5 w-5" />;
      case 'cancelled':
        return <X className="h-5 w-5" />;
      default:
        return <Clock className="h-5 w-5" />;
    }
  };

  const getStatusLabel = (status: OrderStatus) => {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'preparing':
        return 'Preparando';
      case 'ready':
        return 'Pronto';
      case 'out_for_delivery':
        return '🚚 Saiu para entrega';
      case 'delivered':
        return 'Entregue';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  };

  const getStatusColor = (status: OrderStatus) => {
    switch (status) {
      case 'pending':
        return 'bg-yellow-500';
      case 'preparing':
        return 'bg-blue-500';
      case 'ready':
        return 'bg-green-500';
      case 'out_for_delivery':
        return 'bg-purple-500';
      case 'delivered':
        return 'bg-emerald-500';
      case 'cancelled':
        return 'bg-red-500';
      default:
        return 'bg-gray-500';
    }
  };

  const searchOrder = async () => {
    if (!phone.trim()) {
      toast({
        title: "Erro",
        description: "Por favor, digite seu número de telefone",
        variant: "destructive",
      });
      return;
    }

    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('orders')
        .select(`
          *,
          order_items!inner(
            id,
            product_name,
            quantity,
            price,
            removed_ingredients
          )
        `)
        .eq('customer_phone', phone)
        .order('created_at', { ascending: false });

      if (error) throw error;

      if (data && data.length > 0) {
        const ordersData = data.map(orderData => ({
          id: orderData.id,
          status: orderData.status as OrderStatus,
          total: orderData.total,
          customerName: orderData.customer_name,
          customerPhone: orderData.customer_phone,
          deliveryAddress: orderData.delivery_address,
          paymentMethod: orderData.payment_method,
          items: orderData.order_items.map((item: any) => ({
            id: item.id,
            productId: item.product_id || '',
            productName: item.product_name,
            quantity: item.quantity,
            price: item.price,
            removedIngredients: item.removed_ingredients
          })),
          createdAt: new Date(orderData.created_at),
          updatedAt: new Date(orderData.updated_at)
        }));
        setOrders(ordersData);
      } else {
        setOrders([]);
        toast({
          title: "Pedido não encontrado",
          description: "Não foi encontrado nenhum pedido com este número de telefone",
          variant: "destructive",
        });
      }
    } catch (error) {
      console.error('Error searching order:', error);
      toast({
        title: "Erro",
        description: "Erro ao buscar pedido. Tente novamente.",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  // Real-time updates for order status
  useEffect(() => {
    if (orders.length === 0) return;

    const orderIds = orders.map(order => order.id);
    const channel = supabase
      .channel('order-tracking')
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'orders'
        },
        (payload) => {
          const updatedOrder = payload.new as any;
          
          // Check if this update is for one of our orders
          if (orderIds.includes(updatedOrder.id)) {
            setOrders(prev => prev.map(order => 
              order.id === updatedOrder.id 
                ? {
                    ...order,
                    status: updatedOrder.status as OrderStatus,
                    updatedAt: new Date(updatedOrder.updated_at)
                  }
                : order
            ));
            
            toast({
              title: "Status Atualizado! 📋",
              description: `Pedido #${updatedOrder.id.slice(0, 8)} agora está: ${getStatusLabel(updatedOrder.status)}`,
            });
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [orders, toast]);

  const getStatusSteps = (orderStatus: OrderStatus) => {
    const steps = [
      { status: 'pending', label: 'Pendente' },
      { status: 'preparing', label: 'Preparando' },
      { status: 'ready', label: 'Pronto' },
      { status: 'out_for_delivery', label: '🚚 Saiu para entrega' },
      { status: 'delivered', label: 'Entregue' }
    ];

    const currentIndex = steps.findIndex(step => step.status === orderStatus);
    
    return steps.map((step, index) => ({
      ...step,
      completed: index <= currentIndex,
      current: index === currentIndex
    }));
  };

  return (
    <>
      <div className="min-h-screen bg-muted/20 p-4 pb-16">
        <div className="max-w-2xl mx-auto">
          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold mb-2">Acompanhar Pedido</h1>
            <p className="text-muted-foreground">
              Digite seu telefone para acompanhar o status do seu pedido
            </p>
          </div>

        <Card className="mb-6">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Search className="h-5 w-5" />
              Buscar Pedido
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex gap-2">
              <Input
                type="tel"
                placeholder="Digite seu número de telefone"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && searchOrder()}
              />
              <Button onClick={searchOrder} disabled={loading}>
                {loading ? 'Buscando...' : 'Acompanhar Pedido'}
              </Button>
            </div>
          </CardContent>
        </Card>

        {orders.length > 0 && (
          <div className="space-y-6">
            <div className="text-center mb-4">
              <h2 className="text-xl font-semibold">
                {orders.length === 1 ? 'Pedido Encontrado' : `${orders.length} Pedidos Encontrados`}
              </h2>
            </div>
            
            {orders.map((order) => (
              <Card key={order.id} className="overflow-hidden">
                {/* Order Header */}
                <CardHeader className="bg-gradient-to-r from-primary/10 to-primary/5">
                  <div className="flex items-center justify-between">
                    <CardTitle className="flex items-center gap-2">
                      {getStatusIcon(order.status)}
                      Pedido #{order.id.slice(0, 8)}
                    </CardTitle>
                    <Badge className={`${getStatusColor(order.status)} text-white`}>
                      {getStatusLabel(order.status)}
                    </Badge>
                  </div>
                </CardHeader>

                <CardContent className="pt-6 space-y-6">
                  {/* Order Information */}
                  <div>
                    <h3 className="font-semibold text-lg mb-3 flex items-center gap-2">
                      <Package className="h-5 w-5" />
                      Informações do Pedido
                    </h3>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm bg-muted/30 p-4 rounded-lg">
                      <div className="space-y-2">
                        <p><strong>Cliente:</strong> {order.customerName}</p>
                        <p><strong>Telefone:</strong> {order.customerPhone}</p>
                        {order.deliveryAddress && (
                          <p><strong>Endereço:</strong> {order.deliveryAddress}</p>
                        )}
                      </div>
                      <div className="space-y-2">
                        <p><strong>Total:</strong> <span className="text-lg font-bold text-primary">R$ {order.total.toFixed(2)}</span></p>
                        <p><strong>Pedido em:</strong> {order.createdAt.toLocaleString('pt-BR')}</p>
                        <p><strong>Atualizado em:</strong> {order.updatedAt.toLocaleString('pt-BR')}</p>
                      </div>
                    </div>
                  </div>

                  {/* Status Progress */}
                  {order.status !== 'cancelled' && (
                    <div>
                      <h3 className="font-semibold text-lg mb-4 flex items-center gap-2">
                        <Clock className="h-5 w-5" />
                        Progresso do Pedido
                      </h3>
                      <div className="relative">
                        <div className="flex items-start justify-between">
                          {getStatusSteps(order.status).map((step, index) => (
                            <React.Fragment key={step.status}>
                              <div className="flex flex-col items-center flex-1 relative z-10">
                                <div className={`
                                  w-10 h-10 rounded-full flex items-center justify-center text-white text-sm font-medium shadow-md
                                  ${step.completed ? getStatusColor(step.status as OrderStatus) : 'bg-gray-300'}
                                  ${step.current ? 'ring-4 ring-primary/30 scale-110' : ''}
                                  transition-all duration-300
                                `}>
                                  {step.completed ? '✓' : index + 1}
                                </div>
                                <span className={`text-xs mt-2 text-center max-w-[80px] ${step.current ? 'font-bold text-primary' : 'text-muted-foreground'}`}>
                                  {step.label}
                                </span>
                              </div>
                              {index < getStatusSteps(order.status).length - 1 && (
                                <div className="flex-1 flex items-center" style={{ marginTop: '20px' }}>
                                  <div className={`h-1 w-full ${step.completed ? 'bg-green-500' : 'bg-gray-300'} transition-all duration-300`} />
                                </div>
                              )}
                            </React.Fragment>
                          ))}
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Order Items */}
                  <div>
                    <h3 className="font-semibold text-lg mb-4 flex items-center gap-2">
                      <Package className="h-5 w-5" />
                      Itens do Pedido
                    </h3>
                    <div className="space-y-3">
                      {order.items.map((item, index) => (
                        <div key={index} className="flex justify-between items-start p-4 bg-muted/20 rounded-lg hover:bg-muted/40 transition-colors">
                          <div className="flex-1">
                            <p className="font-medium text-base">{item.productName}</p>
                            <p className="text-sm text-muted-foreground mt-1">
                              Quantidade: {item.quantity}
                            </p>
                            {item.removedIngredients && item.removedIngredients.length > 0 && (
                              <p className="text-sm text-red-600 mt-1">
                                <strong>Sem:</strong> {item.removedIngredients.join(', ')}
                              </p>
                            )}
                          </div>
                          <div className="text-right ml-4">
                            <p className="font-bold text-lg">R$ {(item.price * item.quantity).toFixed(2)}</p>
                            <p className="text-xs text-muted-foreground">R$ {item.price.toFixed(2)} cada</p>
                          </div>
                        </div>
                      ))}
                      
                      {/* Total Summary */}
                      <div className="border-t-2 border-primary/20 pt-3 mt-4">
                        <div className="flex justify-between items-center p-4 bg-primary/10 rounded-lg">
                          <span className="font-bold text-lg">Total do Pedido</span>
                          <span className="font-bold text-2xl text-primary">R$ {order.total.toFixed(2)}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
        </div>
      </div>

      <BottomNavigation 
        cartItemsCount={0}
        onCartClick={() => {}}
      />
    </>
  );
};

export default OrderTracking;