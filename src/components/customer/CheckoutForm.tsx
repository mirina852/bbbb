import React from 'react';
import { Product } from '@/types';
import { Button } from '@/components/ui/button';
import { 
  Dialog, 
  DialogContent, 
  DialogHeader, 
  DialogTitle 
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Card, CardContent } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { toast } from "sonner";
import { MapPin, CreditCard, Banknote, QrCode, User, Phone, ShoppingBag } from 'lucide-react';
import PixPayment from './PixPayment';
import { useMercadoPago } from '@/contexts/MercadoPagoContext';
import { useStore } from '@/contexts/StoreContext';
import { supabase } from '@/integrations/supabase/client';

interface CartItem {
  product: Product;
  quantity: number;
  removedIngredients?: string[];
  extraIngredients?: { name: string; price: number }[];
}

interface CheckoutFormProps {
  cartItems: CartItem[];
  isOpen: boolean;
  onClose: () => void;
  onSubmitOrder: (customerName: string, customerPhone: string, deliveryAddress: string, paymentMethod: string) => void;
  onPixPaymentComplete: (paymentId: string, customerName: string, customerPhone: string, deliveryAddress: string) => void;
  // Identificação da loja (necessária para pagamentos PIX multi-tenant)
  storeId?: string;
  storeSlug?: string;
}

const CheckoutForm = ({ cartItems, isOpen, onClose, onSubmitOrder, onPixPaymentComplete, storeId, storeSlug }: CheckoutFormProps) => {
  const [customerName, setCustomerName] = React.useState('');
  const [customerPhone, setCustomerPhone] = React.useState('');
  const [deliveryAddress, setDeliveryAddress] = React.useState('');
  const [paymentMethod, setPaymentMethod] = React.useState('cash');
  const [isPixPaymentOpen, setIsPixPaymentOpen] = React.useState(false);
  const [deliveryFee, setDeliveryFee] = React.useState(0);
  const [pendingOrderId, setPendingOrderId] = React.useState<string | null>(null);
  const [isCreatingOrder, setIsCreatingOrder] = React.useState(false);
  const { isConfigured: isPixConfigured, config } = useMercadoPago();
  const { currentStore } = useStore();
  
  // Carregar taxa de entrega da loja atual
  React.useEffect(() => {
    const loadDeliveryFee = async () => {
      if (currentStore?.delivery_fee !== undefined && currentStore?.delivery_fee !== null) {
        setDeliveryFee(currentStore.delivery_fee);
      } else if (storeId) {
        // Buscar da loja específica se não tiver currentStore
        const { data } = await supabase.from('stores').select('delivery_fee').eq('id', storeId).single();
        if (data?.delivery_fee !== undefined && data?.delivery_fee !== null) {
          setDeliveryFee(data.delivery_fee);
        }
      }
    };
    loadDeliveryFee();
  }, [currentStore, storeId]);
  
  // Debug: Log do estado do PIX
  React.useEffect(() => {
    console.log('🔍 CheckoutForm - PIX configurado?', isPixConfigured);
    console.log('🔍 CheckoutForm - Config:', config);
  }, [isPixConfigured, config]);
  
  const subtotal = cartItems.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
  const total = subtotal + deliveryFee;
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!customerName.trim()) {
      toast.error("Por favor, informe seu nome");
      return;
    }
    
    if (!deliveryAddress.trim()) {
      toast.error("Por favor, informe o endereço de entrega");
      return;
    }
    
    if (paymentMethod === 'pix') {
      // Para PIX, criar pedido PRIMEIRO para ter o orderId
      setIsCreatingOrder(true);
      try {
        const targetStoreId = storeId || currentStore?.id;
        if (!targetStoreId) {
          toast.error("Erro: loja não identificada");
          return;
        }
        
        // Criar pedido com status pending
        const { data: order, error } = await supabase
          .from('orders')
          .insert({
            store_id: targetStoreId,
            customer_name: customerName,
            customer_phone: customerPhone,
            delivery_address: deliveryAddress,
            payment_method: 'pix',
            total: total,
            status: 'pending',
            payment_status: 'pending'
          })
          .select()
          .single();
        
        if (error) throw error;
        
        // Criar itens do pedido
        const orderItems = cartItems.map(({ product, quantity, removedIngredients, extraIngredients }) => ({
          order_id: order.id,
          product_id: product.id,
          product_name: product.name,
          quantity,
          price: product.price,
          removed_ingredients: removedIngredients || [],
          extra_ingredients: extraIngredients || []
        }));
        
        await supabase.from('order_items').insert(orderItems);
        
        console.log('✅ Pedido criado para pagamento PIX:', order.id);
        setPendingOrderId(order.id);
        setIsPixPaymentOpen(true);
      } catch (error) {
        console.error('Erro ao criar pedido para PIX:', error);
        toast.error('Erro ao processar pedido');
      } finally {
        setIsCreatingOrder(false);
      }
      return;
    }
    
    onSubmitOrder(customerName, customerPhone, deliveryAddress, paymentMethod);
  };
  
  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent 
        className="bg-gradient-to-br from-background/95 to-secondary/10 backdrop-blur shadow-2xl 
                   overflow-y-auto 
                   w-full h-full max-w-full max-h-full m-0 p-4
                   sm:max-w-md sm:max-h-[90vh] sm:mx-auto sm:my-auto sm:border sm:rounded-xl 
                   border-0 rounded-none"
      >
        <DialogHeader className="text-center pb-2">
          <DialogTitle className="text-xl font-bold bg-gradient-to-r from-primary to-orange-500 bg-clip-text text-transparent">
            Finalizar Pedido
          </DialogTitle>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Dados Pessoais */}
          <Card className="sm:border border-0 sm:border-border/50 bg-card/50 backdrop-blur-sm">
            <CardContent className="p-4 space-y-4">
              <div className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                <User className="h-4 w-4" />
                <span>Dados Pessoais</span>
              </div>
              
              <div className="space-y-3">
                <div className="space-y-2">
                  <Label htmlFor="customerName" className="text-sm font-medium">
                    Seu Nome
                  </Label>
                  <Input
                    id="customerName"
                    value={customerName}
                    onChange={(e) => setCustomerName(e.target.value)}
                    placeholder="Informe seu nome completo"
                    className="bg-background/80 border-border/60 focus:border-primary transition-colors"
                    required
                  />
                </div>
                
                <div className="space-y-2">
                  <Label htmlFor="customerPhone" className="text-sm font-medium flex items-center gap-2">
                    <Phone className="h-3 w-3" />
                    Telefone
                  </Label>
                  <Input
                    id="customerPhone"
                    value={customerPhone}
                    onChange={(e) => setCustomerPhone(e.target.value)}
                    placeholder="(11) 99999-9999"
                    className="bg-background/80 border-border/60 focus:border-primary transition-colors"
                    required
                  />
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Endereço */}
          <Card className="sm:border border-0 sm:border-border/50 bg-card/50 backdrop-blur-sm">
            <CardContent className="p-4 space-y-3">
              <div className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                <MapPin className="h-4 w-4" />
                <span>Entrega</span>
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="deliveryAddress" className="text-sm font-medium">
                  Endereço Completo
                </Label>
                <Input
                  id="deliveryAddress"
                  value={deliveryAddress}
                  onChange={(e) => setDeliveryAddress(e.target.value)}
                  placeholder="Rua, número, bairro, complemento"
                  className="bg-background/80 border-border/60 focus:border-primary transition-colors"
                  required
                />
              </div>
            </CardContent>
          </Card>
          
          {/* Forma de pagamento */}
          <Card className="sm:border border-0 sm:border-border/50 bg-card/50 backdrop-blur-sm">
            <CardContent className="p-4 space-y-3">
              <div className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                <CreditCard className="h-4 w-4" />
                <span>Forma de Pagamento</span>
              </div>
              
              <RadioGroup value={paymentMethod} onValueChange={setPaymentMethod} className="space-y-2">
                <div className="flex items-center space-x-3 rounded-lg border border-border/60 p-3 bg-background/40 hover:bg-accent/20 transition-colors">
                  <RadioGroupItem value="cash" id="payment-cash" className="text-primary" />
                  <Label htmlFor="payment-cash" className="flex items-center gap-3 font-normal cursor-pointer flex-1">
                    <div className="flex items-center justify-center w-8 h-8 rounded-full bg-green-100 text-green-600">
                      <Banknote className="h-4 w-4" />
                    </div>
                    <span className="text-sm">Dinheiro</span>
                  </Label>
                </div>
                
                <div className={`flex items-center space-x-3 rounded-lg border border-border/60 p-3 bg-background/40 transition-colors ${!isPixConfigured ? 'opacity-50 cursor-not-allowed' : 'hover:bg-accent/20'}`}>
                  <RadioGroupItem value="pix" id="payment-pix" className="text-primary" disabled={!isPixConfigured} />
                  <Label htmlFor="payment-pix" className={`flex items-center gap-3 font-normal flex-1 ${!isPixConfigured ? 'cursor-not-allowed' : 'cursor-pointer'}`}>
                    <div className="flex items-center justify-center w-8 h-8 rounded-full bg-primary/10 text-primary">
                      <QrCode className="h-4 w-4" />
                    </div>
                    <div className="flex flex-col">
                      <span className="text-sm font-medium">PIX</span>
                      <span className="text-xs text-muted-foreground">
                        {isPixConfigured ? 'Pagamento imediato' : 'Indisponível no momento'}
                      </span>
                    </div>
                  </Label>
                </div>
                
                <div className="flex items-center space-x-3 rounded-lg border border-border/60 p-3 bg-background/40 hover:bg-accent/20 transition-colors">
                  <RadioGroupItem value="card" id="payment-card" className="text-primary" />
                  <Label htmlFor="payment-card" className="flex items-center gap-3 font-normal cursor-pointer flex-1">
                    <div className="flex items-center justify-center w-8 h-8 rounded-full bg-blue-100 text-blue-600">
                      <CreditCard className="h-4 w-4" />
                    </div>
                    <div className="flex flex-col">
                      <span className="text-sm font-medium">Cartão</span>
                      <span className="text-xs text-muted-foreground">Crédito/Débito na entrega</span>
                    </div>
                  </Label>
                </div>
              </RadioGroup>
            </CardContent>
          </Card>
          
          {/* Resumo do Pedido */}
          <Card className="sm:border border-0 sm:border-border/50 bg-gradient-to-br from-primary/5 to-orange-500/5 backdrop-blur-sm">
            <CardContent className="p-4 space-y-3">
              <div className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                <ShoppingBag className="h-4 w-4" />
                <span>Resumo do Pedido</span>
              </div>
              
              <div className="space-y-2">
                {cartItems.map(({ product, quantity, removedIngredients, extraIngredients }) => (
                  <div key={`${product.id}-${JSON.stringify(removedIngredients)}-${JSON.stringify(extraIngredients)}`} className="space-y-1">
                    <div className="flex justify-between items-center text-sm py-1">
                      <span className="text-muted-foreground">{quantity}x {product.name}</span>
                      <span className="font-medium">R$ {(product.price * quantity).toFixed(2).replace('.', ',')}</span>
                    </div>
                    {(removedIngredients && removedIngredients.length > 0) && (
                      <div className="text-xs text-red-500 ml-4">
                        Sem: {removedIngredients.join(', ')}
                      </div>
                    )}
                    {(extraIngredients && extraIngredients.length > 0) && (
                      <div className="text-xs text-green-600 ml-4">
                        Extras: {extraIngredients.map(extra => `${extra.name} (+R$ ${extra.price.toFixed(2).replace('.', ',')})`).join(', ')}
                      </div>
                    )}
                  </div>
                ))}
              </div>
              
              <Separator className="my-3" />
              
              <div className="space-y-1">
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Subtotal</span>
                  <span>R$ {subtotal.toFixed(2).replace('.', ',')}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Taxa de entrega</span>
                  <span>R$ {deliveryFee.toFixed(2).replace('.', ',')}</span>
                </div>
              </div>
              
              <Separator className="my-3" />
              
              <div className="flex justify-between items-center font-bold text-lg">
                <span>Total</span>
                <span className="text-primary">R$ {total.toFixed(2).replace('.', ',')}</span>
              </div>
            </CardContent>
          </Card>
          
          {/* Botões */}
          <div className="flex gap-3 pt-2">
            <Button 
              type="button" 
              variant="outline" 
              onClick={onClose}
              className="flex-1 h-12 border-border/60 hover:bg-accent/50"
            >
              Cancelar
            </Button>
            <Button 
              type="submit" 
              disabled={isCreatingOrder}
              className="flex-1 h-12 bg-gradient-to-r from-primary to-orange-500 hover:from-primary/90 hover:to-orange-500/90 text-white font-medium shadow-lg hover:shadow-xl transition-all duration-200"
            >
              {isCreatingOrder ? 'Processando...' : paymentMethod === 'pix' ? 'Pagar com PIX' : 'Confirmar Pedido'}
            </Button>
          </div>
        </form>
        
        <PixPayment
          isOpen={isPixPaymentOpen}
          onClose={() => {
            setIsPixPaymentOpen(false);
            setPendingOrderId(null);
          }}
          amount={total}
          customerName={customerName}
          customerPhone={customerPhone}
          description={`Pedido ${currentStore?.name || 'Loja'} - ${cartItems.length} item(s)`}
          storeId={storeId}
          storeSlug={storeSlug}
          orderId={pendingOrderId || undefined}
          onPaymentComplete={(paymentId) => {
            setIsPixPaymentOpen(false);
            // Pedido já foi criado, só precisa navegar
            onPixPaymentComplete(paymentId, customerName, customerPhone, deliveryAddress);
          }}
        />
      </DialogContent>
    </Dialog>
  );
};

export default CheckoutForm;
