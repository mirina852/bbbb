import React from 'react';
import { AlertCircle } from 'lucide-react';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { useNavigate } from 'react-router-dom';
import { useSubscription } from '@/contexts/SubscriptionContext';

const SubscriptionWarning = () => {
  const { isSubscriptionActive, subscription } = useSubscription();
  const navigate = useNavigate();

  // Não mostra nada se a assinatura está ativa
  if (isSubscriptionActive) {
    return null;
  }

  // Verifica se é teste gratuito expirado
  const isTrialExpired = subscription?.plan_slug === 'trial' && subscription?.status === 'expired';

  return (
    <Alert variant="destructive" className="mb-6">
      <AlertCircle className="h-4 w-4" />
      <AlertTitle>
        {isTrialExpired ? 'Teste Gratuito Expirado' : 'Assinatura Necessária'}
      </AlertTitle>
      <AlertDescription className="flex items-center justify-between">
        <span>
          {isTrialExpired 
            ? 'Seu período de teste gratuito expirou. Escolha um plano para continuar usando todos os recursos.'
            : 'Você precisa de uma assinatura ativa para usar todos os recursos do sistema.'}
        </span>
        <Button 
          variant="outline" 
          size="sm" 
          onClick={() => navigate('/planos')}
          className="ml-4 bg-white hover:bg-gray-100 text-red-600"
        >
          Ver Planos
        </Button>
      </AlertDescription>
    </Alert>
  );
};

export default SubscriptionWarning;
