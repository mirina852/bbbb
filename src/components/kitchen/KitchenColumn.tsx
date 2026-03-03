import React from 'react';
import { Order, OrderStatus } from '@/types';
import KitchenOrderCard from './KitchenOrderCard';
import { cn } from '@/lib/utils';
import { ScrollArea } from '@/components/ui/scroll-area';
import { UtensilsCrossed } from 'lucide-react';

interface KitchenColumnProps {
  title: string;
  icon: React.ReactNode;
  color: string;
  bgGradient: string;
  headerBg: string;
  orders: Order[];
  onUpdateStatus: (id: string, status: OrderStatus) => void;
}

const KitchenColumn: React.FC<KitchenColumnProps> = ({
  title,
  icon,
  color,
  bgGradient,
  headerBg,
  orders,
  onUpdateStatus,
}) => {
  return (
    <div className={cn(
      'rounded-3xl border border-border/40 overflow-hidden flex flex-col',
      'bg-gradient-to-b shadow-lg backdrop-blur-sm',
      'transition-all duration-300 hover:shadow-xl hover:border-border/60',
      bgGradient
    )}>
      {/* Column header - premium glassmorphism */}
      <div className={cn(
        'px-5 py-4 flex items-center gap-3 relative overflow-hidden',
        headerBg
      )}>
        {/* Background glow effect */}
        <div className="absolute inset-0 bg-gradient-to-r from-white/10 via-transparent to-white/5" />
        <div className="absolute -top-10 -right-10 w-24 h-24 rounded-full bg-white/10 blur-2xl" />
        
        <div className="relative flex items-center gap-3 flex-1">
          <div className="w-9 h-9 rounded-xl bg-white/20 backdrop-blur-md flex items-center justify-center shadow-inner">
            {icon}
          </div>
          <div>
            <span className="font-black text-sm text-white uppercase tracking-wider">{title}</span>
          </div>
        </div>
        <div className={cn(
          'relative bg-white/25 backdrop-blur-md text-white text-sm font-black',
          'rounded-xl w-9 h-9 flex items-center justify-center shadow-lg',
          orders.length > 0 && 'animate-count-pop'
        )}>
          {orders.length}
        </div>
      </div>

      {/* Orders list */}
      <ScrollArea className="flex-1 max-h-[calc(100vh-260px)]">
        <div className="p-3 space-y-3">
          {orders.length === 0 ? (
            <div className="text-center py-16 px-4">
              <div className="w-16 h-16 rounded-2xl bg-muted/50 flex items-center justify-center mx-auto mb-4">
                <UtensilsCrossed className="h-7 w-7 text-muted-foreground/40" />
              </div>
              <p className="text-sm font-bold text-muted-foreground/50">Nenhum pedido</p>
              <p className="text-[11px] text-muted-foreground/30 mt-1">Os pedidos aparecerão aqui</p>
            </div>
          ) : (
            orders.map((order, i) => (
              <KitchenOrderCard
                key={order.id}
                order={order}
                onUpdateStatus={onUpdateStatus}
                index={i}
              />
            ))
          )}
        </div>
      </ScrollArea>

      {/* Bottom glow line */}
      {orders.length > 0 && (
        <div className={cn(
          'h-0.5 mx-4 mb-2 rounded-full opacity-30',
          headerBg
        )} />
      )}
    </div>
  );
};

export default KitchenColumn;
