
import React from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Order, OrderStatus } from '@/types';
import { Calendar, MapPin, CreditCard, Package, X, Banknote, Printer } from 'lucide-react';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { cn } from '@/lib/utils';

interface OrderDetailsDialogProps {
  order: Order | null;
  isOpen: boolean;
  onClose: () => void;
  onUpdateStatus: (id: string, status: OrderStatus) => void;
}

const statusColors = {
  pending: "bg-yellow-100 text-yellow-800 border-yellow-200",
  preparing: "bg-blue-100 text-blue-800 border-blue-200",
  ready: "bg-green-100 text-green-800 border-green-200",
  out_for_delivery: "bg-purple-100 text-purple-800 border-purple-200",
  delivered: "bg-indigo-100 text-indigo-800 border-indigo-200",
  cancelled: "bg-red-100 text-red-800 border-red-200"
};

const OrderDetailsDialog = ({ order, isOpen, onClose, onUpdateStatus }: OrderDetailsDialogProps) => {
  const [status, setStatus] = React.useState<OrderStatus>('pending');

  // Calcular subtotal dos itens
  const itemsSubtotal = order?.items?.reduce((sum, item) => {
    return sum + (item.price * item.quantity);
  }, 0) || 0;

  // Taxa de entrega é a diferença entre o total e o subtotal dos itens
  const deliveryFee = (order?.total || 0) - itemsSubtotal;

  React.useEffect(() => {
    if (order) {
      setStatus(order.status);
    }
  }, [order]);

  if (!order) return null;

  const handleStatusChange = (value: string) => {
    setStatus(value as OrderStatus);
  };

  const handleUpdateStatus = () => {
    onUpdateStatus(order.id, status);
    onClose();
  };

  const handlePrintThermal = () => {
    // Criar conteúdo otimizado para impressora térmica 58mm
    const thermalContent = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="UTF-8">
          <title>Pedido #${order.id.split('-').pop()}</title>
          <style>
            * {
              margin: 0;
              padding: 0;
              box-sizing: border-box;
            }
            @page {
              size: 58mm auto;
              margin: 0;
            }
            body {
              width: 58mm;
              margin: 0;
              padding: 5mm;
              font-family: 'Courier New', monospace;
              font-size: 10pt;
              line-height: 1.3;
              background: white;
            }
            .center { text-align: center; }
            .bold { font-weight: bold; }
            .line { border-top: 1px dashed #000; margin: 3mm 0; }
            .item { display: flex; justify-content: space-between; }
            .total { font-size: 12pt; font-weight: bold; }
            h1 { font-size: 14pt; margin: 2mm 0; }
            h2 { font-size: 11pt; margin: 2mm 0; }
            p { margin: 1mm 0; }
          </style>
        </head>
        <body>
          <div class="center">
            <h1>FOODSAAS</h1>
            <p>Pedido #${order.id.split('-').pop()}</p>
          </div>
          
          <div class="line"></div>
          
          <p><span class="bold">Data:</span> ${format(new Date(order.createdAt), 'dd/MM/yyyy HH:mm')}</p>
          
          <div class="line"></div>
          
          <h2>CLIENTE</h2>
          <p>${order.customerName}</p>
          ${order.customerPhone ? `<p>Tel: ${order.customerPhone}</p>` : ''}
          
          ${order.deliveryAddress ? `
            <div class="line"></div>
            <h2>ENTREGA</h2>
            <p>${order.deliveryAddress}</p>
          ` : ''}
          
          <div class="line"></div>
          
          <h2>ITENS</h2>
          ${order.items.map(item => `
            <div class="item">
              <span>${item.quantity}x ${item.productName}</span>
              <span>R$ ${(item.price * item.quantity).toFixed(2).replace('.', ',')}</span>
            </div>
            ${item.removedIngredients && item.removedIngredients.length > 0 ? 
              `<p style="font-size: 9pt; margin-left: 5mm;">Sem: ${item.removedIngredients.join(', ')}</p>` : ''}
            ${item.extraIngredients && item.extraIngredients.length > 0 ? 
              `<p style="font-size: 9pt; margin-left: 5mm;">Extras: ${item.extraIngredients.map(e => e.name).join(', ')}</p>` : ''}
          `).join('')}
          
          <div class="line"></div>
          
          <div class="item">
            <span>Subtotal:</span>
            <span>R$ ${(order.total - deliveryFee).toFixed(2).replace('.', ',')}</span>
          </div>
          <div class="item">
            <span>Taxa entrega:</span>
            <span>R$ ${deliveryFee.toFixed(2).replace('.', ',')}</span>
          </div>
          
          <div class="line"></div>
          
          <div class="item total">
            <span>TOTAL:</span>
            <span>R$ ${order.total.toFixed(2).replace('.', ',')}</span>
          </div>
          
          <div class="line"></div>
          
          <p><span class="bold">Pagamento:</span> ${order.paymentMethod === 'card' ? 'Cartão' : 'Dinheiro'}</p>
          <p><span class="bold">Status:</span> ${
            order.status === 'pending' ? 'Pendente' : 
            order.status === 'preparing' ? 'Em Preparo' : 
            order.status === 'ready' ? 'Pronto' : 
            order.status === 'out_for_delivery' ? 'Saiu p/ entrega' :
            order.status === 'delivered' ? 'Entregue' : 'Cancelado'
          }</p>
          
          <div class="line"></div>
          
          <p class="center" style="font-size: 9pt;">Obrigado pela preferencia!</p>
        </body>
      </html>
    `;

    // Criar blob URL para isolar completamente o conteúdo
    const blob = new Blob([thermalContent], { type: 'text/html' });
    const blobUrl = URL.createObjectURL(blob);
    
    // Abrir nova janela com o blob URL
    const printWindow = window.open(blobUrl, '_blank', 'width=300,height=600');
    
    // Aguardar a janela carregar e então abrir impressão
    if (printWindow) {
      printWindow.onload = () => {
        setTimeout(() => {
          printWindow.print();
        }, 500);
      };
      
      // Limpar blob após 2 segundos
      setTimeout(() => {
        URL.revokeObjectURL(blobUrl);
      }, 2000);
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
        <DialogContent className="w-[95vw] max-w-lg mx-auto max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Pedido #{order.id.split('-').pop()}</DialogTitle>
        </DialogHeader>
        
        <div className="space-y-4">
          <div className="flex justify-between">
            <div>
              <h3 className="font-medium">Cliente</h3>
              <p>{order.customerName}</p>
              {order.customerPhone && <p className="text-sm text-muted-foreground">{order.customerPhone}</p>}
            </div>
            <div className="text-right">
              <h3 className="font-medium">Data do Pedido</h3>
              <p>{format(new Date(order.createdAt), 'dd/MM/yyyy')}</p>
              <p className="text-sm text-muted-foreground">{format(new Date(order.createdAt), 'HH:mm')}</p>
            </div>
          </div>
          
          {order.deliveryAddress && (
            <div>
              <h3 className="font-medium mb-1 flex items-center gap-1">
                <MapPin className="h-4 w-4" />
                Endereço de Entrega
              </h3>
              <p className="text-sm">{order.deliveryAddress}</p>
            </div>
          )}
          
          {order.paymentMethod && (
            <div>
              <h3 className="font-medium mb-1 flex items-center gap-1">
                {order.paymentMethod === 'card' ? (
                  <CreditCard className="h-4 w-4 text-blue-600" />
                ) : order.paymentMethod === 'pix' ? (
                  <Package className="h-4 w-4 text-purple-600" />
                ) : (
                  <Banknote className="h-4 w-4 text-green-600" />
                )}
                Forma de Pagamento
              </h3>
              <p className="text-sm">
                {order.paymentMethod === 'card' 
                  ? 'Cartão de Crédito/Débito (na entrega)' 
                  : order.paymentMethod === 'pix'
                  ? 'PIX'
                  : 'Dinheiro'}
              </p>
            </div>
          )}
          
          <div>
            <h3 className="font-medium mb-2">Itens do Pedido</h3>
            <div className="border rounded-md">
              <table className="w-full">
                <thead className="bg-muted/50">
                  <tr>
                    <th className="text-left p-2 text-sm font-medium">Item</th>
                    <th className="text-center p-2 text-sm font-medium">Qtd</th>
                    <th className="text-right p-2 text-sm font-medium">Preço</th>
                  </tr>
                </thead>
                <tbody>
                  {order.items.map((item) => (
                    <tr key={item.id} className="border-t">
                      <td className="p-2 text-sm">
                        <div>
                          {item.productName}
                          {item.removedIngredients && item.removedIngredients.length > 0 && (
                            <div className="text-xs text-red-600 mt-1">
                              Sem: {item.removedIngredients.join(', ')}
                            </div>
                          )}
                          {item.extraIngredients && item.extraIngredients.length > 0 && (
                            <div className="text-xs text-green-600 mt-1">
                              Extras: {item.extraIngredients.map(extra => `${extra.name} (+R$ ${extra.price.toFixed(2).replace('.', ',')})`).join(', ')}
                            </div>
                          )}
                        </div>
                      </td>
                      <td className="p-2 text-sm text-center">{item.quantity}</td>
                      <td className="p-2 text-sm text-right">R$ {(item.price * item.quantity).toFixed(2).replace('.', ',')}</td>
                    </tr>
                  ))}
                  <tr className="border-t">
                    <td colSpan={2} className="p-2 text-sm font-medium text-right">Subtotal:</td>
                    <td className="p-2 text-sm text-right">R$ {(order.total - deliveryFee).toFixed(2).replace('.', ',')}</td>
                  </tr>
                  <tr>
                    <td colSpan={2} className="p-2 text-sm font-medium text-right">Taxa de entrega:</td>
                    <td className="p-2 text-sm text-right">R$ {deliveryFee.toFixed(2).replace('.', ',')}</td>
                  </tr>
                  <tr className="border-t bg-muted/30">
                    <td colSpan={2} className="p-2 text-sm font-medium text-right">Total:</td>
                    <td className="p-2 text-sm font-bold text-right">R$ {order.total.toFixed(2).replace('.', ',')}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
          
          <div>
            <h3 className="font-medium mb-2">Status do Pedido</h3>
            <div className="flex items-center justify-between">
              <Badge variant="outline" className={cn("text-sm px-2 py-1", statusColors[order.status])}>
                {order.status === 'pending' ? 'Pendente' : 
                 order.status === 'preparing' ? 'Em Preparo' : 
                 order.status === 'ready' ? 'Pronto' : 
                 order.status === 'out_for_delivery' ? '🚚 Saiu para entrega' :
                 order.status === 'delivered' ? 'Entregue' : 'Cancelado'}
              </Badge>
              <Select value={status} onValueChange={handleStatusChange}>
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder="Atualizar status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="pending">Pendente</SelectItem>
                  <SelectItem value="preparing">Em Preparo</SelectItem>
                  <SelectItem value="ready">Pronto</SelectItem>
                  <SelectItem value="out_for_delivery">🚚 Saiu para entrega</SelectItem>
                  <SelectItem value="delivered">Entregue</SelectItem>
                  <SelectItem value="cancelled">Cancelado</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </div>
        
        <DialogFooter className="flex-col sm:flex-row gap-2">
          <Button variant="outline" onClick={onClose}>
            Fechar
          </Button>
          <Button 
            variant="outline"
            onClick={handlePrintThermal}
            className="gap-2 bg-orange-50 hover:bg-orange-100"
          >
            <Printer className="h-4 w-4" />
            Imprimir
          </Button>
          <Button 
            className="bg-food-primary hover:bg-food-dark"
            onClick={handleUpdateStatus}
            disabled={status === order.status}
          >
            Atualizar Status
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default OrderDetailsDialog;
