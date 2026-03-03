import React, { useMemo } from 'react';
import { Order, OrderStatus } from '@/types';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  ArrowRight,
  Clock,
  User,
  XCircle,
  ChefHat,
  Flame,
  PackageCheck,
} from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { ptBR } from 'date-fns/locale';

interface Props {
  order: Order;
  onUpdateStatus: (id: string, status: OrderStatus) => void;
  index: number;
}

const NEXT_STATUS: Partial<Record<OrderStatus, { label: string; status: OrderStatus; icon: React.ReactNode }>> = {
  pago: { label: 'Preparar', status: 'preparing', icon: <ChefHat className="h-4 w-4" /> },
  preparing: { label: 'Pronto!', status: 'ready', icon: <PackageCheck className="h-4 w-4" /> },
};

const STATUS_ACCENT: Record<string, string> = {
  pago: 'from-amber-500/20 to-orange-500/10 border-amber-400/40',
  preparing: 'from-blue-500/20 to-cyan-500/10 border-blue-400/40',
  ready: 'from-emerald-500/20 to-green-500/10 border-emerald-400/40',
};

const NEXT_BTN_STYLE: Record<string, string> = {
  pago: 'bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-600 hover:to-orange-600 text-white shadow-lg shadow-amber-500/25',
  preparing: 'bg-gradient-to-r from-blue-500 to-cyan-500 hover:from-blue-600 hover:to-cyan-600 text-white shadow-lg shadow-blue-500/25',
  ready: 'bg-gradient-to-r from-emerald-500 to-green-500 hover:from-emerald-600 hover:to-green-600 text-white shadow-lg shadow-emerald-500/25',
};

const KitchenOrderCard: React.FC<Props> = ({ order, onUpdateStatus, index }) => {
  const next = NEXT_STATUS[order.status];
  const timeAgo = formatDistanceToNow(new Date(order.createdAt), {
    addSuffix: true,
    locale: ptBR,
  });

  const minutesSinceCreated = useMemo(
    () => (Date.now() - new Date(order.createdAt).getTime()) / 60000,
    [order.createdAt]
  );
  const isUrgent = order.status === 'pago' && minutesSinceCreated > 15;
  const isWarning = order.status === 'pago' && minutesSinceCreated > 8 && !isUrgent;

  const accentClass = STATUS_ACCENT[order.status] || '';
  const btnStyle = NEXT_BTN_STYLE[order.status] || '';

  return (
    <div
      className={cn(
        'group rounded-2xl border bg-gradient-to-br backdrop-blur-sm overflow-hidden transition-all duration-300',
        'hover:shadow-xl hover:-translate-y-0.5 hover:border-primary/30',
        'animate-slide-up',
        accentClass,
        isUrgent && 'animate-urgent-ring ring-2 ring-destructive/60 border-destructive/50',
        isWarning && 'animate-glow-pulse'
      )}
      style={{ animationDelay: `${index * 60}ms`, animationFillMode: 'backwards' }}
    >
      {/* Top accent bar */}
      <div className={cn(
        'h-1 w-full',
        order.status === 'pago' && 'bg-gradient-to-r from-amber-400 via-orange-400 to-amber-500',
        order.status === 'preparing' && 'bg-gradient-to-r from-blue-400 via-cyan-400 to-blue-500',
        order.status === 'ready' && 'bg-gradient-to-r from-emerald-400 via-green-400 to-emerald-500',
      )} />

      {/* Card header */}
      <div className="px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className={cn(
            'w-9 h-9 rounded-xl flex items-center justify-center text-white font-black text-xs shadow-md',
            order.status === 'pago' && 'bg-gradient-to-br from-amber-500 to-orange-600',
            order.status === 'preparing' && 'bg-gradient-to-br from-blue-500 to-cyan-600',
            order.status === 'ready' && 'bg-gradient-to-br from-emerald-500 to-green-600',
          )}>
            #{order.id.slice(-3).toUpperCase()}
          </div>
          <div>
            <p className="text-xs font-bold text-foreground tracking-tight">
              Pedido #{order.id.slice(-6).toUpperCase()}
            </p>
            <p className="text-[10px] text-muted-foreground flex items-center gap-1 mt-0.5">
              <Clock className="h-2.5 w-2.5" />
              {timeAgo}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-1.5">
          {isUrgent && (
            <Badge className="bg-destructive text-destructive-foreground text-[9px] px-2 py-0.5 font-black tracking-wider animate-pulse shadow-md shadow-destructive/30">
              🔥 URGENTE
            </Badge>
          )}
          {isWarning && (
            <Badge className="bg-amber-500 text-white text-[9px] px-2 py-0.5 font-bold shadow-sm">
              ⏰ ATENÇÃO
            </Badge>
          )}
        </div>
      </div>

      {/* Items list */}
      <div className="px-4 pb-2 space-y-2">
        {order.items.map((item, i) => (
          <div
            key={item.id}
            className={cn(
              'flex items-start gap-3 p-2.5 rounded-xl bg-card/60 border border-border/30',
              'transition-colors group-hover:bg-card/80'
            )}
          >
            <div className={cn(
              'w-8 h-8 rounded-lg flex items-center justify-center font-black text-sm shrink-0',
              'bg-primary/15 text-primary border border-primary/20'
            )}>
              {item.quantity}
            </div>
            <div className="flex-1 min-w-0 space-y-0.5">
              <p className="text-sm font-bold text-foreground leading-tight truncate">
                {item.productName}
              </p>
              {item.removedIngredients && item.removedIngredients.length > 0 && (
                <div className="flex items-center gap-1 flex-wrap">
                  <span className="text-[10px] font-black text-destructive bg-destructive/10 px-1.5 py-0.5 rounded-md">SEM</span>
                  <span className="text-[10px] text-destructive/80 font-medium">
                    {item.removedIngredients.join(', ')}
                  </span>
                </div>
              )}
              {item.extraIngredients && item.extraIngredients.length > 0 && (
                <div className="flex items-center gap-1 flex-wrap">
                  <span className="text-[10px] font-black text-emerald-600 dark:text-emerald-400 bg-emerald-500/10 px-1.5 py-0.5 rounded-md">EXTRA</span>
                  <span className="text-[10px] text-emerald-600/80 dark:text-emerald-400/80 font-medium">
                    {item.extraIngredients.map((e: any) => (typeof e === 'string' ? e : e.name)).join(', ')}
                  </span>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Customer info */}
      <div className="mx-4 mb-3 p-3 rounded-xl bg-card/40 border border-border/20 space-y-1.5">
        <div className="flex items-center gap-2">
          <div className="w-6 h-6 rounded-full bg-primary/10 flex items-center justify-center">
            <User className="h-3 w-3 text-primary" />
          </div>
          <span className="text-xs font-bold text-foreground truncate">{order.customerName}</span>
        </div>
        <div className="flex items-center justify-between pt-1 border-t border-border/20">
          <span className="text-base font-black text-foreground">
            R$ {order.total.toFixed(2).replace('.', ',')}
          </span>
          {order.paymentMethod && (
            <Badge variant="secondary" className="text-[10px] font-bold">
              {order.paymentMethod}
            </Badge>
          )}
        </div>
      </div>

      {/* Action buttons */}
      <div className="px-4 pb-4 flex gap-2">
        {next && (
          <Button
            size="sm"
            onClick={() => onUpdateStatus(order.id, next.status)}
            className={cn(
              'flex-1 gap-2 text-xs font-black h-10 rounded-xl border-0 transition-all duration-200',
              'hover:scale-[1.02] active:scale-[0.98]',
              btnStyle
            )}
          >
            {next.icon}
            {next.label}
          </Button>
        )}
        {order.status !== 'cancelled' && (
          <Button
            size="sm"
            variant="ghost"
            onClick={() => onUpdateStatus(order.id, 'cancelled')}
            className="text-xs text-destructive hover:text-destructive hover:bg-destructive/10 h-10 w-10 rounded-xl p-0 transition-all duration-200 hover:scale-105"
          >
            <XCircle className="h-4 w-4" />
          </Button>
        )}
      </div>
    </div>
  );
};

export default KitchenOrderCard;
