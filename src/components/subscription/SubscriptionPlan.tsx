import React from 'react';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Check } from 'lucide-react';

interface SubscriptionPlanProps {
  name: string;
  price: number;
  duration: string;
  features: string[];
  onSelect: () => void;
  isPopular?: boolean;
  isTrial?: boolean;
  isAvailable?: boolean;  // Se false, o plano não pode ser selecionado
}

const SubscriptionPlan = ({ 
  name, 
  price, 
  duration, 
  features, 
  onSelect, 
  isPopular,
  isTrial,
  isAvailable = true  // Por padrão, o plano está disponível
}: SubscriptionPlanProps) => {
  return (
    <Card className={`relative ${isPopular ? 'border-primary shadow-lg' : ''} ${!isAvailable ? 'opacity-60' : ''}`}>
      {isPopular && (
        <Badge className="absolute -top-3 left-1/2 -translate-x-1/2 bg-primary">
          Mais Popular
        </Badge>
      )}
      {!isAvailable && isTrial && (
        <Badge className="absolute -top-3 left-1/2 -translate-x-1/2 bg-muted-foreground">
          Já Utilizado
        </Badge>
      )}
      
      <CardHeader>
        <CardTitle className="text-2xl">{name}</CardTitle>
        <CardDescription>
          <span className="text-3xl font-bold text-foreground">
            R$ {price.toFixed(2).replace('.', ',')}
          </span>
          <span className="text-muted-foreground">/{duration}</span>
        </CardDescription>
      </CardHeader>
      
      <CardContent>
        <ul className="space-y-2">
          {features.map((feature, index) => (
            <li key={index} className="flex items-start gap-2">
              <Check className="h-5 w-5 text-primary shrink-0 mt-0.5" />
              <span className="text-sm">{feature}</span>
            </li>
          ))}
        </ul>
      </CardContent>
      
      <CardFooter>
        <Button 
          onClick={onSelect} 
          className="w-full"
          variant={isPopular ? 'default' : 'outline'}
          disabled={!isAvailable}
        >
          {!isAvailable && isTrial ? 'Já Utilizado' : 
           isTrial ? 'Iniciar Teste Gratuito' : 'Selecionar Plano'}
        </Button>
      </CardFooter>
    </Card>
  );
};

export default SubscriptionPlan;
