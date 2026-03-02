import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { CreditCard, Loader2 } from 'lucide-react';
import { createSubscriptionPayment } from '@/services/platformPaymentService';
import { useAuth } from '@/contexts/AuthContext';
import { useToast } from '@/hooks/use-toast';

interface SubscriptionPaymentButtonProps {
  planId: string;
  planName: string;
  amount: number;
  onSuccess?: () => void;
}

/**
 * Botão de pagamento para ASSINATURAS
 * Usa as credenciais da PLATAFORMA (você)
 */
const SubscriptionPaymentButton: React.FC<SubscriptionPaymentButtonProps> = ({
  planId,
  planName,
  amount,
  onSuccess
}) => {
  const { user } = useAuth();
  const { toast } = useToast();
  const [loading, setLoading] = useState(false);

  const handlePayment = async () => {
    if (!user) {
      toast({
        title: 'Erro',
        description: 'Você precisa estar logado para assinar',
        variant: 'destructive'
      });
      return;
    }

    setLoading(true);
    try {
      const payment = await createSubscriptionPayment({
        planId,
        planName,
        amount,
        userId: user.id,
        userEmail: user.email
      });

      if (payment.paymentUrl) {
        // Redirecionar para página de pagamento do Mercado Pago
        window.location.href = payment.paymentUrl;
      } else {
        toast({
          title: 'Pagamento criado',
          description: 'Redirecionando para o pagamento...'
        });
        onSuccess?.();
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

  return (
    <Button
      onClick={handlePayment}
      disabled={loading}
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
          Assinar por R$ {amount.toFixed(2)}
        </>
      )}
    </Button>
  );
};

export default SubscriptionPaymentButton;
