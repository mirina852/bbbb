import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { CreditCard, Save, AlertCircle, CheckCircle, Lock } from 'lucide-react';
import { useMercadoPago } from '@/contexts/MercadoPagoContext';
import { useSubscription } from '@/contexts/SubscriptionContext';
import { useNavigate } from 'react-router-dom';

const MercadoPagoConfig = () => {
  const { config: savedConfig, saveConfig, isConfigured } = useMercadoPago();
  const { subscription, isSubscriptionActive } = useSubscription();
  const navigate = useNavigate();
  const [config, setConfig] = useState({
    publicKey: '',
    accessToken: '',
  });
  const [saved, setSaved] = useState(false);
  const [loading, setLoading] = useState(false);
  const [hasExistingToken, setHasExistingToken] = useState(false);

  useEffect(() => {
    if (savedConfig) {
      setConfig(savedConfig);
      // Se isConfigured é true, significa que há um access token salvo
      if (isConfigured) {
        setHasExistingToken(true);
      }
    }
  }, [savedConfig, isConfigured]);

  const handleSave = async () => {
    setLoading(true);
    try {
      await saveConfig(config);
      setSaved(true);
      setHasExistingToken(true);
      // Limpa o campo de access token após salvar
      setConfig(prev => ({ ...prev, accessToken: '' }));
      setTimeout(() => setSaved(false), 3000);
    } catch (error) {
      console.error('Erro ao salvar:', error);
    } finally {
      setLoading(false);
    }
  };

  // Verificar se usuário tem assinatura ativa
  if (!subscription || !isSubscriptionActive) {
    return (
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Lock className="h-5 w-5 text-muted-foreground" />
            <CardTitle>Configuração do Mercado Pago</CardTitle>
          </div>
          <CardDescription>
            Configure suas credenciais do Mercado Pago para receber pagamentos dos seus clientes
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <Alert variant="destructive">
            <Lock className="h-4 w-4" />
            <AlertDescription>
              <strong>Acesso bloqueado:</strong> Você precisa ter uma assinatura ativa para configurar o Mercado Pago.
            </AlertDescription>
          </Alert>

          <Alert>
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>
              <strong>Por que isso é necessário?</strong>
              <p className="mt-2">
                Primeiro você precisa escolher um plano e ativar sua assinatura. 
                Depois disso, você poderá configurar suas credenciais do Mercado Pago 
                para começar a receber pagamentos dos seus clientes.
              </p>
            </AlertDescription>
          </Alert>

          <Button 
            onClick={() => navigate('/planos')} 
            className="w-full"
            size="lg"
          >
            Ver Planos Disponíveis
          </Button>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center gap-2">
          <CreditCard className="h-5 w-5" />
          <CardTitle>Configuração do Mercado Pago</CardTitle>
        </div>
        <CardDescription>
          Configure suas credenciais do Mercado Pago para receber pagamentos dos seus clientes
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        {isConfigured && (
          <Alert className="bg-green-50 border-green-200">
            <CheckCircle className="h-4 w-4 text-green-600" />
            <AlertDescription className="text-green-800">
              Mercado Pago configurado! Seus clientes já podem fazer pagamentos.
            </AlertDescription>
          </Alert>
        )}
        
        {!isConfigured && (
          <Alert className="bg-blue-50 border-blue-200">
            <AlertCircle className="h-4 w-4 text-blue-600" />
            <AlertDescription className="text-blue-800">
              <strong>Configure suas credenciais:</strong> Adicione suas credenciais do Mercado Pago para começar a receber pagamentos dos seus clientes.
            </AlertDescription>
          </Alert>
        )}

        <Alert>
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>
            <strong>Importante:</strong> Estas são as credenciais da SUA conta Mercado Pago. 
            Os pagamentos dos seus clientes cairão diretamente na sua conta.
          </AlertDescription>
        </Alert>

        <Alert className="bg-blue-50 border-blue-200">
          <AlertCircle className="h-4 w-4 text-blue-600" />
          <AlertDescription className="text-blue-800">
            <strong>Como obter suas credenciais:</strong>
            <ol className="list-decimal ml-4 mt-2 space-y-1">
              <li>Acesse <a href="https://www.mercadopago.com.br/developers/panel" target="_blank" rel="noopener noreferrer" className="underline font-semibold">Mercado Pago Developers</a></li>
              <li>Faça login na sua conta</li>
              <li>Vá em "Suas integrações" → "Credenciais"</li>
              <li>Copie a Public Key e o Access Token</li>
            </ol>
          </AlertDescription>
        </Alert>

        <div className="space-y-2">
          <Label htmlFor="publicKey">Public Key</Label>
          <Input
            id="publicKey"
            type="text"
            placeholder="APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
            value={config.publicKey}
            onChange={(e) => setConfig({ ...config, publicKey: e.target.value })}
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="accessToken">Access Token</Label>
          <Input
            id="accessToken"
            type="password"
            placeholder={hasExistingToken && !config.accessToken ? "••••••••••••••••••••••••••••••••••••••••••••••••" : "APP_USR-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"}
            value={config.accessToken}
            onChange={(e) => setConfig({ ...config, accessToken: e.target.value })}
          />
          {hasExistingToken && !config.accessToken && (
            <p className="text-xs text-muted-foreground">
              Por questões de segurança, o Access Token salvo não é exibido. Deixe em branco para manter o atual ou insira um novo para atualizar.
            </p>
          )}
        </div>

        <Button onClick={handleSave} className="w-full" disabled={loading}>
          <Save className="h-4 w-4 mr-2" />
          {loading ? 'Salvando...' : 'Salvar Configurações'}
        </Button>

        {saved && (
          <Alert className="bg-green-50 border-green-200">
            <AlertDescription className="text-green-800">
              Configurações salvas com sucesso!
            </AlertDescription>
          </Alert>
        )}
      </CardContent>
    </Card>
  );
};

export default MercadoPagoConfig;
