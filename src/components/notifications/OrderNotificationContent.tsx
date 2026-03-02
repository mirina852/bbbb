import React from 'react';
import { Order } from '@/types';

interface OrderNotificationContentProps {
  order: Order;
}

export const OrderNotificationTitle = () => {
  return (
    <div className="flex items-center gap-2">
      <span className="text-2xl">🔔</span>
      <div>
        <div className="font-bold text-lg">Novo Pedido Recebido!</div>
        <div className="text-xs text-muted-foreground mt-0.5">
          {new Date().toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}
        </div>
      </div>
    </div>
  );
};

export const OrderNotificationDescription = ({ order }: OrderNotificationContentProps) => {
  // Gerar ID curto e legível (primeiros 6 caracteres após remover hífens)
  const shortId = order.id.replace(/-/g, '').slice(0, 6).toUpperCase();
  
  // Contar itens corretamente
  const itemCount = Array.isArray(order.items) ? order.items.length : 0;
  
  return (
    <div className="space-y-2 mt-2">
      <div className="flex items-center justify-between bg-primary/10 rounded-lg p-3">
        <div className="flex items-center gap-2">
          <span className="text-xl">📋</span>
          <div>
            <div className="font-semibold text-sm">Pedido #{shortId}</div>
            <div className="text-xs text-muted-foreground">{order.customerName}</div>
          </div>
        </div>
        <div className="text-right">
          <div className="text-xs text-muted-foreground">Total</div>
          <div className="font-bold text-lg text-green-600">
            R$ {order.total.toFixed(2).replace('.', ',')}
          </div>
        </div>
      </div>
      
      {/* Lista de itens do pedido */}
      {itemCount > 0 && (
        <div className="bg-muted/30 rounded-lg p-2 space-y-1">
          <div className="text-xs font-semibold text-muted-foreground mb-1">Itens do Pedido:</div>
          {order.items.slice(0, 3).map((item, index) => (
            <div key={index} className="flex items-center justify-between text-xs">
              <span className="flex items-center gap-1">
                <span className="text-orange-500">•</span>
                <span>{item.quantity}x {item.productName}</span>
              </span>
              <span className="text-muted-foreground">
                R$ {(item.price * item.quantity).toFixed(2).replace('.', ',')}
              </span>
            </div>
          ))}
          {itemCount > 3 && (
            <div className="text-xs text-muted-foreground italic">
              + {itemCount - 3} {itemCount - 3 === 1 ? 'item' : 'itens'}
            </div>
          )}
        </div>
      )}
      
      <div className="flex items-center gap-2 text-xs text-muted-foreground">
        <span>🍽️</span>
        <span>{itemCount} {itemCount === 1 ? 'item' : 'itens'}</span>
        {order.deliveryAddress && (
          <>
            <span>•</span>
            <span>🚚 Entrega</span>
          </>
        )}
      </div>
    </div>
  );
};
