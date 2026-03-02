import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { CreditCard, Loader2, AlertCircle } from 'lucide-react';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { createOrderPayment } from '@/services/merchantPaymentService';
import { useMercadoPago } from '@/contexts/MercadoPagoContext';
import { useCart } from '@/contexts/CartContext';
import { useToast } from '@/hooks/use-toast';

interface OrderPaymentButtonProps {
  customerEmail: string;
  customerName: string;
  onSuccess?: (paymentId: string) => void;
}

/**
 * Botão de pagamento para PEDIDOS
 * Usa as credenciais do LOJISTA (dono do negócio)
 */
const OrderPaymentButton: React.FC<OrderPaymentButtonProps> = ({
  customerEmail,
  customerName,
  onSuccess
}) => {
  const { config, isConfigured } = useMercadoPago();
  const { items, total } = useCart();
  const { toast } = useToast();
  const [loading, setLoading] = useState(false);

  const handlePayment = async () => {
    if (!isConfigured || !config) {
      toast({
        title: 'Pagamento não configurado',
        description: 'O lojista ainda não configurou o Mercado Pago',
        variant: 'destructive'
      });
      return;
    }

    if (items.length === 0) {
      toast({
        title: 'Carrinho vazio',
        description: 'Adicione produtos ao carrinho antes de pagar',
        variant: 'destructive'
      });
      return;
    }

    setLoading(true);
    try {
      const payment = await createOrderPayment(
        {
          orderId: `ORD-${Date.now()}`,
          amount: total,
          items: items.map(item => ({
            id: item.product.id,
            title: item.product.name,
            quantity: item.quantity,
            unit_price: item.product.price
          })),
          customerEmail,
          customerName
        },
        config.accessToken
      );

      if (payment.paymentUrl) {
        // Redirecionar para página de pagamento do Mercado Pago
        window.location.href = payment.paymentUrl;
      } else if (payment.qrCode) {
        // Mostrar QR Code do PIX
        toast({
          title: 'Pagamento PIX gerado',
          description: 'Escaneie o QR Code para pagar'
        });
        onSuccess?.(payment.id);
      }
    } catch (error) {
      toast({
        title: 'Erro ao processar pagamento',
        description: 'Tente novamente mais tarde',
        variant: 'destructive'
      });
    } finally {
      setLoading(false);
    }
  };

  if (!isConfigured) {
    return (
      <Alert variant="destructive">
        <AlertCircle className="h-4 w-4" />
        <AlertDescription>
          O lojista ainda não configurou os pagamentos. Entre em contato para mais informações.
        </AlertDescription>
      </Alert>
    );
  }

  return (
    <Button
      onClick={handlePayment}
      disabled={loading || items.length === 0}
      size="lg"
      className="w-full"
    >
      {loading ? (
        <>
          <Loader2 className="h-5 w-5 mr-2 animate-spin" />
          Processando...
        </>
      ) : (
        <>
          <CreditCard className="h-5 w-5 mr-2" />
          Finalizar Pedido - R$ {total.toFixed(2)}
        </>
      )}
    </Button>
  );
};

export default OrderPaymentButton;
