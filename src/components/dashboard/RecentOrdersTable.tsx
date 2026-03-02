
import React from 'react';
import { format } from 'date-fns';
import { Order } from '@/types';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';

interface RecentOrdersTableProps {
  orders: Order[];
}

const statusColors = {
  pending: "bg-yellow-500/10 text-yellow-700 border-yellow-500/20 dark:text-yellow-400",
  preparing: "bg-blue-500/10 text-blue-700 border-blue-500/20 dark:text-blue-400",
  ready: "bg-green-500/10 text-green-700 border-green-500/20 dark:text-green-400",
  out_for_delivery: "bg-purple-500/10 text-purple-700 border-purple-500/20 dark:text-purple-400",
  delivered: "bg-indigo-500/10 text-indigo-700 border-indigo-500/20 dark:text-indigo-400",
  cancelled: "bg-red-500/10 text-red-700 border-red-500/20 dark:text-red-400"
};

const statusLabels = {
  pending: "Pendente",
  preparing: "Preparando", 
  ready: "Pronto",
  out_for_delivery: "🚚 Saiu para entrega",
  delivered: "Entregue",
  cancelled: "Cancelado"
};

const RecentOrdersTable = ({ orders }: RecentOrdersTableProps) => {
  return (
    <div className="overflow-x-auto rounded-xl">
      <div className="hidden md:block">
        <table className="w-full">
          <thead>
            <tr className="border-b border-border/50">
              <th className="pb-4 text-left font-semibold text-muted-foreground">Pedido</th>
              <th className="pb-4 text-left font-semibold text-muted-foreground">Cliente</th>
              <th className="pb-4 text-left font-semibold text-muted-foreground">Data</th>
              <th className="pb-4 text-right font-semibold text-muted-foreground">Total</th>
              <th className="pb-4 text-right font-semibold text-muted-foreground">Status</th>
            </tr>
          </thead>
          <tbody>
            {orders.map((order) => (
              <tr key={order.id} className="border-b border-border/30 hover:bg-muted/30 transition-colors duration-200">
                <td className="py-4">
                  <div className="font-medium">#{order.id.split('-').pop()}</div>
                  <div className="text-sm text-muted-foreground">{order.items.length} itens</div>
                </td>
                <td className="py-4">
                  <div className="font-medium">{order.customerName}</div>
                  {order.customerPhone && (
                    <div className="text-sm text-muted-foreground">{order.customerPhone}</div>
                  )}
                </td>
                <td className="py-4">
                  <div className="font-medium">
                    {format(new Date(order.createdAt), 'dd/MM/yyyy')}
                  </div>
                  <div className="text-sm text-muted-foreground">
                    {format(new Date(order.createdAt), 'HH:mm')}
                  </div>
                </td>
                <td className="py-4 text-right font-semibold">
                  R$ {order.total.toFixed(2).replace('.', ',')}
                </td>
                <td className="py-4 text-right">
                  <Badge variant="outline" className={cn("font-medium", statusColors[order.status])}>
                    {statusLabels[order.status] || order.status}
                  </Badge>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Mobile Card Layout */}
      <div className="md:hidden space-y-4">
        {orders.map((order) => (
          <div key={order.id} className="bg-card/50 rounded-lg border border-border/50 p-4 transition-all duration-200 hover:shadow-md">
            <div className="flex justify-between items-start mb-3">
              <div>
                <div className="font-semibold">#{order.id.split('-').pop()}</div>
                <div className="text-sm text-muted-foreground">{order.items.length} itens</div>
              </div>
              <Badge variant="outline" className={cn("text-xs", statusColors[order.status])}>
                {statusLabels[order.status] || order.status}
              </Badge>
            </div>
            
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Cliente:</span>
                <span className="text-sm font-medium">{order.customerName}</span>
              </div>
              
              <div className="flex justify-between">
                <span className="text-sm text-muted-foreground">Data:</span>
                <span className="text-sm font-medium">
                  {format(new Date(order.createdAt), 'dd/MM/yyyy HH:mm')}
                </span>
              </div>
              
              <div className="flex justify-between items-center pt-2 border-t border-border/30">
                <span className="text-sm text-muted-foreground">Total:</span>
                <span className="font-bold text-lg">
                  R$ {order.total.toFixed(2).replace('.', ',')}
                </span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default RecentOrdersTable;
