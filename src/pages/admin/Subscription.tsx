import React from 'react';
import AdminLayout from '@/layouts/AdminLayout';
import PageHeader from '@/components/common/PageHeader';
import { useSubscription } from '@/contexts/SubscriptionContext';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Calendar, Clock, CreditCard, CheckCircle, AlertCircle } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { Progress } from '@/components/ui/progress';

const Subscription = () => {
  const { subscription, isSubscriptionActive } = useSubscription();
  const navigate = useNavigate();

  if (!subscription) {
    return (
      <AdminLayout>
        <div className="space-y-6">
          <PageHeader 
            title="Status da Assinatura"
            description="Gerencie sua assinatura e veja os detalhes do seu plano"
          />

          <Card className="border-2 border-orange-500 shadow-lg">
            <CardHeader className="bg-orange-50 dark:bg-orange-950/20">
              <CardTitle className="flex items-center gap-2 text-orange-900 dark:text-orange-100 text-2xl">
                <AlertCircle className="h-8 w-8" />
                Assinatura Necessária
              </CardTitle>
              <CardDescription className="text-base">
                Você precisa ativar um plano para acessar o sistema.
              </CardDescription>
            </CardHeader>
            <CardContent className="pt-6">
              <div className="bg-orange-100 dark:bg-orange-950/30 border border-orange-200 dark:border-orange-800 rounded-lg p-4 mb-6">
                <p className="text-sm font-medium text-orange-900 dark:text-orange-100 mb-2">
                  ⚠️ Acesso Bloqueado
                </p>
                <p className="text-sm text-orange-800 dark:text-orange-200">
                  Para acessar o Dashboard, Produtos, Pedidos e Configurações, você precisa escolher e ativar um plano de assinatura.
                </p>
              </div>
              
              <div className="space-y-3 mb-6">
                <p className="text-sm font-medium">O que você pode fazer com uma assinatura:</p>
                <ul className="space-y-2 text-sm text-muted-foreground">
                  <li className="flex items-center gap-2">
                    <CheckCircle className="h-4 w-4 text-green-600" />
                    Gerenciar produtos e categorias
                  </li>
                  <li className="flex items-center gap-2">
                    <CheckCircle className="h-4 w-4 text-green-600" />
                    Receber e processar pedidos
                  </li>
                  <li className="flex items-center gap-2">
                    <CheckCircle className="h-4 w-4 text-green-600" />
                    Visualizar estatísticas e dashboard
                  </li>
                  <li className="flex items-center gap-2">
                    <CheckCircle className="h-4 w-4 text-green-600" />
                    Configurar sua loja online
                  </li>
                </ul>
              </div>
              
              <Button 
                onClick={() => navigate('/planos')}
                size="lg"
                className="w-full text-lg h-14 bg-orange-600 hover:bg-orange-700"
              >
                🚀 Ver Planos e Ativar Agora
              </Button>
            </CardContent>
          </Card>
        </div>
      </AdminLayout>
    );
  }

  const daysRemaining = subscription.days_remaining;
  const isExpiringSoon = daysRemaining <= 7;
  const isExpired = subscription.status === 'expired';

  // Calcular porcentagem (assumindo 30 dias para teste gratuito/mensal, 365 para anual)
  const totalDays = subscription.plan_slug === 'yearly' ? 365 : 30;
  const percentageRemaining = Math.max(0, Math.min(100, (daysRemaining / totalDays) * 100));

  // Definir cor e variante do badge
  let badgeVariant: 'default' | 'secondary' | 'destructive' | 'outline' = 'default';
  let statusText = 'Ativa';
  let statusIcon = <CheckCircle className="h-5 w-5 text-green-600" />;

  if (isExpired) {
    badgeVariant = 'destructive';
    statusText = 'Expirada';
    statusIcon = <AlertCircle className="h-5 w-5 text-red-600" />;
  } else if (isExpiringSoon) {
    badgeVariant = 'outline';
    statusText = 'Expirando em Breve';
    statusIcon = <Clock className="h-5 w-5 text-orange-600" />;
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <PageHeader 
            title="Status da Assinatura"
            description="Gerencie sua assinatura e veja os detalhes do seu plano"
          />
          {subscription.plan_slug === 'trial' && !isExpired && (
            <Badge variant="secondary" className="text-sm px-4 py-2">
              Teste Gratuito
            </Badge>
          )}
        </div>

        {/* Card Principal de Status */}
        <Card className={isExpired ? 'border-red-500' : isExpiringSoon ? 'border-orange-500' : 'border-green-500'}>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                {statusIcon}
                <div>
                  <CardTitle className="text-2xl">{subscription.plan_name}</CardTitle>
                  <div className="flex items-center gap-2 mt-1">
                    <CardDescription className="text-base m-0">
                      Status:
                    </CardDescription>
                    <Badge variant={badgeVariant}>{statusText}</Badge>
                  </div>
                </div>
              </div>
            </div>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Dias Restantes */}
            <div className="flex items-center justify-between p-4 bg-muted/50 rounded-lg">
              <div className="flex items-center gap-3">
                <Clock className={`h-8 w-8 ${isExpired ? 'text-red-600' : isExpiringSoon ? 'text-orange-600' : 'text-green-600'}`} />
                <div>
                  <p className="text-sm text-muted-foreground">Dias Restantes</p>
                  <p className={`text-3xl font-bold ${isExpired ? 'text-red-600' : isExpiringSoon ? 'text-orange-600' : 'text-green-600'}`}>
                    {isExpired ? '0' : daysRemaining}
                  </p>
                </div>
              </div>
            </div>

            {/* Barra de Progresso */}
            {!isExpired && (
              <div className="space-y-3">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Progresso do Período</span>
                  <span className="font-semibold">{percentageRemaining.toFixed(0)}%</span>
                </div>
                <Progress 
                  value={percentageRemaining} 
                  className={`h-3 ${isExpiringSoon ? '[&>div]:bg-orange-500' : '[&>div]:bg-green-500'}`}
                />
              </div>
            )}

            {/* Informações Detalhadas */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-4 border-t">
              <div className="flex items-start gap-3">
                <Calendar className="h-5 w-5 text-muted-foreground mt-0.5" />
                <div>
                  <p className="text-sm font-medium">Data de Início</p>
                  <p className="text-sm text-muted-foreground">
                    {subscription.created_at
                      ? new Date(subscription.created_at).toLocaleDateString('pt-BR', {
                          day: '2-digit',
                          month: 'long',
                          year: 'numeric'
                        })
                      : 'N/A'}
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <Calendar className="h-5 w-5 text-muted-foreground mt-0.5" />
                <div>
                  <p className="text-sm font-medium">
                    {isExpired ? 'Expirou em' : 'Expira em'}
                  </p>
                  <p className={`text-sm ${isExpired ? 'text-red-600 font-semibold' : 'text-muted-foreground'}`}>
                    {new Date(subscription.expires_at).toLocaleDateString('pt-BR', {
                      day: '2-digit',
                      month: 'long',
                      year: 'numeric'
                    })}
                  </p>
                </div>
              </div>
            </div>

            {/* Botões de Ação */}
            {(isExpiringSoon || isExpired) && (
              <div className="pt-4 border-t">
                <Button 
                  onClick={() => navigate('/planos')}
                  variant={isExpired ? 'destructive' : 'default'}
                  size="lg"
                  className="w-full"
                >
                  {isExpired ? 'Renovar Assinatura Agora' : 'Renovar Assinatura'}
                </Button>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Card de Recursos do Plano */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <CreditCard className="h-5 w-5" />
              Recursos do Plano
            </CardTitle>
            <CardDescription>
              Veja o que está incluído no seu plano atual
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              <div className="flex items-center gap-2 text-sm">
                <CheckCircle className="h-4 w-4 text-green-600" />
                <span>Acesso completo ao sistema</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <CheckCircle className="h-4 w-4 text-green-600" />
                <span>Gestão de produtos e pedidos</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <CheckCircle className="h-4 w-4 text-green-600" />
                <span>Dashboard com estatísticas</span>
              </div>
              {subscription.plan_slug !== 'trial' && (
                <>
                  <div className="flex items-center gap-2 text-sm">
                    <CheckCircle className="h-4 w-4 text-green-600" />
                    <span>Suporte prioritário</span>
                  </div>
                  {subscription.plan_slug === 'yearly' && (
                    <div className="flex items-center gap-2 text-sm">
                      <CheckCircle className="h-4 w-4 text-green-600" />
                      <span>Suporte VIP exclusivo</span>
                    </div>
                  )}
                </>
              )}
            </div>
          </CardContent>
        </Card>
      </div>
    </AdminLayout>
  );
};

export default Subscription;
