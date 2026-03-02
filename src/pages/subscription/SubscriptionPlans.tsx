import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useSubscription } from '@/contexts/SubscriptionContext';
import { subscriptionService, SubscriptionPlan as PlanType } from '@/services/subscriptionService';
import SubscriptionPlan from '@/components/subscription/SubscriptionPlan';
import PageHeader from '@/components/common/PageHeader';
import PixPayment from '@/components/customer/PixPayment';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { AlertCircle, Loader2 } from 'lucide-react';
import { toast } from 'sonner';

const SubscriptionPlans = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { subscription, refreshSubscription, isSubscriptionActive } = useSubscription();
  const [plans, setPlans] = useState<PlanType[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSelecting, setIsSelecting] = useState(false);
  const [showPixPayment, setShowPixPayment] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState<PlanType | null>(null);
  const [paymentData, setPaymentData] = useState<any>(null);
  const [checkingPayment, setCheckingPayment] = useState(false);

  useEffect(() => {
    loadPlans();
  }, []);

  // REMOVIDO: Permitir renovação antecipada
  // Usuários com assinatura ativa podem acessar /planos para renovar antecipadamente

  const loadPlans = async () => {
    try {
      let data;
      
      // Tentar buscar planos com disponibilidade (requer migration)
      if (user) {
        try {
          data = await subscriptionService.getAvailablePlans(user.id);
        } catch (rpcError) {
          // Se a função RPC não existir ainda, usar método padrão
          console.warn('Função get_available_plans não encontrada, usando getPlans()');
          data = await subscriptionService.getPlans();
        }
      } else {
        data = await subscriptionService.getPlans();
      }
      
      setPlans(data);
    } catch (error) {
      console.error('Erro ao carregar planos:', error);
      toast.error('Não foi possível carregar os planos');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSelectPlan = async (planId: string) => {
    if (!user) {
      navigate('/auth');
      return;
    }

    const plan = plans.find(p => p.id === planId);
    if (!plan) return;

    // ✅ Verificar se o plano está disponível (se a propriedade existir)
    if (plan.is_available === false) {
      toast.error('Você já utilizou o teste gratuito. Cada conta pode usar o teste apenas uma vez.');
      return;
    }

    setIsSelecting(true);
    try {
      // ✅ Se for plano GRATUITO (trial ou preço 0), verificar se já usou
      if (plan.is_trial || plan.price === 0) {
        // Verificação extra: se a migration foi executada, has_used_trial estará disponível
        try {
          const hasUsed = await subscriptionService.hasUsedTrial(user.id);
          if (hasUsed) {
            toast.error('Você já utilizou o teste gratuito. Cada conta pode usar o teste apenas uma vez.');
            setIsSelecting(false);
            return;
          }
        } catch (rpcError) {
          // Se a função RPC não existir, continuar (migration não executada)
          console.warn('Função has_used_trial não encontrada, pulando verificação');
        }
        
        console.log('Plano gratuito detectado, ativando direto:', planId);
        
        await subscriptionService.createSubscription(user.id, planId);
        await refreshSubscription();
        
        toast.success('Plano ativado com sucesso! Bem-vindo!');
        
        // Redirecionar para admin
        setTimeout(() => navigate('/admin'), 1000);
        return;
      }

      console.log('Criando pagamento para plano:', planId);
      
      // Criar pagamento PIX para planos pagos
      const payment = await subscriptionService.createPayment(user.id, planId);
      
      setPaymentData(payment);
      setSelectedPlan(plan);
      setShowPixPayment(true);
      
      console.log('Pagamento criado, abrindo modal PIX');
    } catch (error: any) {
      console.error('Erro ao criar pagamento:', error);
      
      const errorMessage = error.message || 'Não foi possível processar o pagamento';
      toast.error(errorMessage);
    } finally {
      setIsSelecting(false);
    }
  };

  const handlePaymentComplete = async (paymentId: string) => {
    console.log('Pagamento completo, verificando status...');
    setCheckingPayment(true);
    
    // Função de polling para verificar status
    const checkStatus = async () => {
      try {
        const status = await subscriptionService.checkPaymentStatus(paymentId);
        
        console.log('Status verificado:', status);
        
        if (status.status === 'approved') {
          // Pagamento aprovado - atualizar contexto
          await refreshSubscription();
          
          setShowPixPayment(false);
          setCheckingPayment(false);
          
          toast.success('Pagamento confirmado! Plano ativado com sucesso.');
          
          // Redirecionar para admin
          setTimeout(() => navigate('/admin'), 1000);
        } else if (status.status === 'expired' || status.status === 'cancelled') {
          setShowPixPayment(false);
          setCheckingPayment(false);
          toast.error('Pagamento expirado ou cancelado');
        } else {
          // Ainda pendente - verificar novamente em 3s
          setTimeout(checkStatus, 3000);
        }
      } catch (error) {
        console.error('Erro ao verificar status:', error);
        setCheckingPayment(false);
      }
    };
    
    checkStatus();
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-muted/30 to-background p-6">
      <div className="max-w-6xl mx-auto space-y-8">
        <PageHeader 
          title="Escolha seu Plano"
          description="Selecione o plano ideal para o seu negócio"
        />

        {subscription && subscription.status === 'expired' && (
          <Alert variant="destructive">
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>
              Seu plano <strong>{subscription.plan_name}</strong> expirou.
              Escolha um novo plano para continuar usando o sistema.
            </AlertDescription>
          </Alert>
        )}

        {isSubscriptionActive && (
          <Alert>
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>
              Você já possui uma assinatura ativa (<strong>{subscription?.plan_name}</strong> - {subscription?.days_remaining} dias restantes).
              Ao renovar agora, o novo período será adicionado ao final da sua assinatura atual.
            </AlertDescription>
          </Alert>
        )}

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {plans.map((plan, index) => (
            <SubscriptionPlan
              key={plan.id}
              name={plan.name}
              price={plan.price}
              duration={plan.duration_days === 365 ? 'ano' : 'mês'}
              features={plan.features}
              onSelect={() => handleSelectPlan(plan.id)}
              isPopular={index === 1}
              isTrial={plan.is_trial}
              isAvailable={plan.is_available !== false}
            />
          ))}
        </div>

        {(isSelecting || checkingPayment) && (
          <div className="fixed inset-0 bg-background/80 backdrop-blur-sm z-50 flex items-center justify-center">
            <div className="text-center">
              <Loader2 className="h-8 w-8 animate-spin mx-auto mb-2" />
              <p className="text-sm text-muted-foreground">
                {checkingPayment ? 'Verificando pagamento...' : 'Processando...'}
              </p>
            </div>
          </div>
        )}

        {showPixPayment && paymentData && selectedPlan && (
          <PixPayment
            isOpen={showPixPayment}
            onClose={() => setShowPixPayment(false)}
            amount={selectedPlan.price}
            customerName={user?.email || ''}
            description={`Assinatura ${selectedPlan.name}`}
            onPaymentComplete={handlePaymentComplete}
            paymentId={paymentData.id}
            existingPaymentData={paymentData}
          />
        )}
      </div>
    </div>
  );
};

export default SubscriptionPlans;
