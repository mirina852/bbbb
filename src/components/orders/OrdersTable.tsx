
import React from 'react';
import { format } from 'date-fns';
import { Order } from '@/types';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Eye, Phone, MapPin } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useIsMobile } from '@/hooks/use-mobile';

interface OrdersTableProps {
  orders: Order[];
  onViewDetails: (order: Order) => void;
}

const statusColors = {
  pending: "bg-yellow-100 text-yellow-800 border-yellow-200 dark:bg-yellow-900/20 dark:text-yellow-400 dark:border-yellow-800",
  preparing: "bg-blue-100 text-blue-800 border-blue-200 dark:bg-blue-900/20 dark:text-blue-400 dark:border-blue-800",
  ready: "bg-green-100 text-green-800 border-green-200 dark:bg-green-900/20 dark:text-green-400 dark:border-green-800",
  out_for_delivery: "bg-purple-100 text-purple-800 border-purple-200 dark:bg-purple-900/20 dark:text-purple-400 dark:border-purple-800",
  delivered: "bg-indigo-100 text-indigo-800 border-indigo-200 dark:bg-indigo-900/20 dark:text-indigo-400 dark:border-indigo-800",
  cancelled: "bg-red-100 text-red-800 border-red-200 dark:bg-red-900/20 dark:text-red-400 dark:border-red-800"
};

const statusLabels = {
  pending: 'Pendente',
  preparing: 'Preparando',
  ready: 'Pronto',
  out_for_delivery: '🚚 Saiu para entrega',
  delivered: 'Entregue',
  cancelled: 'Cancelado'
};

const OrdersTable = ({ orders, onViewDetails }: OrdersTableProps) => {
  const isMobile = useIsMobile();

  // Mobile Card Layout
  if (isMobile) {
    return (
      <div className="space-y-4">
        {orders.map((order) => (
          <Card key={order.id} className="overflow-hidden hover:shadow-md transition-shadow">
            <CardContent className="p-4">
              <div className="flex items-center justify-between mb-3">
                <div>
                  <h3 className="font-semibold text-lg">#{order.id.split('-').pop()}</h3>
                  <p className="text-sm text-muted-foreground">
                    {format(new Date(order.createdAt), 'dd/MM/yyyy HH:mm')}
                  </p>
                </div>
                <Badge variant="outline" className={cn(statusColors[order.status])}>
                  {statusLabels[order.status]}
                </Badge>
              </div>
              
              <div className="space-y-3">
                <div className="flex items-start gap-2">
                  <div className="flex-1">
                    <p className="font-medium">{order.customerName}</p>
                    {order.customerPhone && (
                      <div className="flex items-center gap-1 text-sm text-muted-foreground mt-1">
                        <Phone className="h-3 w-3" />
                        {order.customerPhone}
                      </div>
                    )}
                    {order.deliveryAddress && (
                      <div className="flex items-center gap-1 text-sm text-muted-foreground mt-1">
                        <MapPin className="h-3 w-3" />
                        <span className="truncate">{order.deliveryAddress}</span>
                      </div>
                    )}
                  </div>
                </div>
                
                <div className="bg-muted/30 rounded-lg p-3">
                  <div className="flex justify-between items-center mb-2">
                    <span className="text-sm font-medium">{order.items.length} itens</span>
                    <span className="text-lg font-bold text-primary">R$ {order.total.toFixed(2)}</span>
                  </div>
                  <p className="text-xs text-muted-foreground truncate">
                    {order.items.map(item => item.productName).join(', ')}
                  </p>
                </div>
                
                <Button 
                  onClick={() => onViewDetails(order)}
                  className="w-full h-12 text-base font-medium"
                  size="lg"
                >
                  <Eye className="h-5 w-5 mr-2" />
                  Ver Detalhes
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  // Desktop Table Layout
  return (
    <div className="rounded-md border bg-card">
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="bg-muted/50 border-b">
              <th className="p-4 text-left font-medium">ID do Pedido</th>
              <th className="p-4 text-left font-medium">Cliente</th>
              <th className="p-4 text-left font-medium">Data</th>
              <th className="p-4 text-left font-medium">Itens</th>
              <th className="p-4 text-right font-medium">Total</th>
              <th className="p-4 text-center font-medium">Status</th>
              <th className="p-4 text-right font-medium">Ações</th>
            </tr>
          </thead>
          <tbody>
            {orders.map((order) => (
              <tr key={order.id} className="border-b hover:bg-muted/30 transition-colors">
                <td className="p-4">
                  <span className="font-medium">#{order.id.split('-').pop()}</span>
                </td>
                <td className="p-4">
                  <div className="space-y-1">
                    <div className="font-medium">{order.customerName}</div>
                    {order.customerPhone && (
                      <div className="text-xs text-muted-foreground flex items-center gap-1">
                        <Phone className="h-3 w-3" />
                        {order.customerPhone}
                      </div>
                    )}
                  </div>
                </td>
                <td className="p-4">
                  <div className="space-y-1">
                    <div className="text-sm">
                      {format(new Date(order.createdAt), 'dd/MM/yyyy')}
                    </div>
                    <div className="text-xs text-muted-foreground">
                      {format(new Date(order.createdAt), 'HH:mm')}
                    </div>
                  </div>
                </td>
                <td className="p-4">
                  <div className="space-y-1">
                    <span className="text-sm font-medium">{order.items.length} itens</span>
                    <div className="text-xs text-muted-foreground truncate max-w-[200px]">
                      {order.items.map(item => item.productName).join(', ')}
                    </div>
                  </div>
                </td>
                <td className="p-4 text-right">
                  <span className="font-semibold text-primary">R$ {order.total.toFixed(2)}</span>
                </td>
                <td className="p-4 text-center">
                  <Badge variant="outline" className={cn(statusColors[order.status])}>
                    {statusLabels[order.status]}
                  </Badge>
                </td>
                <td className="p-4 text-right">
                  <Button 
                    size="default" 
                    variant="outline" 
                    onClick={() => onViewDetails(order)}
                    className="h-9 px-4"
                  >
                    <Eye className="h-4 w-4 mr-2" />
                    Ver
                  </Button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default OrdersTable;
