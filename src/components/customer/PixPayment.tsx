import React, { useState, useEffect } from 'react'; 
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";
import { Copy, QrCode, Timer, Check } from "lucide-react";
import { toast } from "sonner";
import * as QRCode from 'qrcode';

interface PixPaymentProps {
  isOpen: boolean;
  onClose: () => void;
  amount: number;
  customerName: string;
  customerPhone?: string;
  description: string;
  onPaymentComplete: (paymentId: string) => void;
  paymentId?: string;
  existingPaymentData?: PixPaymentData;
  // Identificação da loja para credenciais do Mercado Pago
  storeId?: string;
  storeSlug?: string;
  // ID do pedido já criado (para vincular pagamento ao pedido)
  orderId?: string;
}

interface PixPaymentData {
  id: string;
  status: string;
  qr_code: string;
  qr_code_base64?: string;
  ticket_url?: string;
}

const PixPayment: React.FC<PixPaymentProps> = ({
  isOpen,
  onClose,
  amount,
  customerName,
  customerPhone,
  description,
  onPaymentComplete,
  paymentId,
  existingPaymentData,
  storeId,
  storeSlug,
  orderId
}) => {
  const [paymentData, setPaymentData] = useState<PixPaymentData | null>(null);
  const [qrCodeDataUrl, setQrCodeDataUrl] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState<'pending' | 'approved' | 'expired'>('pending');
  const [timeLeft, setTimeLeft] = useState<number>(900); // 15 minutos para PIX

  useEffect(() => {
    if (isOpen && existingPaymentData) {
      // Usar dados de pagamento já criados
      console.log('Using existing payment data:', existingPaymentData);
      setPaymentData(existingPaymentData);
      setStatus('pending');
      setTimeLeft(900); // 15 minutos
      
      if (existingPaymentData.qr_code) {
        QRCode.toDataURL(existingPaymentData.qr_code, {
          width: 256,
          margin: 2,
          color: { dark: '#000000', light: '#FFFFFF' }
        }).then(setQrCodeDataUrl);
      }
    } else if (isOpen && !existingPaymentData) {
      // Criar novo pagamento (fluxo original)
      createPixPayment();
    }
  }, [isOpen, existingPaymentData]);

  // Timer de expiração visual (15 minutos para PIX)
  useEffect(() => {
    if (timeLeft > 0 && status === 'pending') {
      const timer = setTimeout(() => setTimeLeft(timeLeft - 1), 1000);
      return () => clearTimeout(timer);
    } else if (timeLeft === 0 && status === 'pending') {
      setStatus('expired');
    }
  }, [timeLeft, status]);

  // Função para verificar status manualmente
  const checkPaymentStatus = async () => {
    if (!paymentData?.id) return;
    
    try {
      const { supabase } = await import('@/integrations/supabase/client');
      
      // Verificar se é pedido ou assinatura
      const functionName = orderId ? 'check-payment-status' : 'check-subscription-payment';
      
      const { data, error } = await supabase.functions.invoke(functionName, {
        body: { paymentId: paymentData.id }
      });

      console.log('Manual status check:', data);

      if (data?.status === 'approved') {
        setStatus('approved');
        toast.success('Pagamento confirmado!');
      } else if (data?.status) {
        toast.info(`Status atual: ${data.status}`);
      }
    } catch (err) {
      console.error('Erro na verificação manual:', err);
      toast.error('Erro ao verificar status');
    }
  };

  // Timer para mostrar opção de continuar após 2 minutos
  const [showContinueOption, setShowContinueOption] = useState(false);

  useEffect(() => {
    if (!isOpen || status !== 'pending') return;

    // Mostrar opção de continuar após 2 minutos
    const timer = setTimeout(() => {
      setShowContinueOption(true);
    }, 2 * 60 * 1000); // 2 minutos

    return () => clearTimeout(timer);
  }, [isOpen, status]);

  const createPixPayment = async () => {
    setLoading(true);
    try {
      console.log('Creating PIX payment with data:', { amount, customerName, customerPhone, description, storeId, storeSlug, orderId });
      
      const { supabase } = await import('@/integrations/supabase/client');
      
      const { data, error } = await supabase.functions.invoke('create-pix-payment', {
        body: {
          amount,
          customerName,
          customerPhone,
          description,
          // Enviar identificação da loja para o backend resolver credenciais
          storeId,
          storeSlug,
          // Enviar orderId para vincular pagamento ao pedido
          orderId
        }
      });

      if (error) throw new Error(error.message || 'Erro ao criar pagamento PIX');
      if (!data) throw new Error('Nenhum dado retornado da função');

      console.log('Resposta da função:', data);

      // A função retorna { success: true, data: {...} }
      const paymentInfo = data.success ? data.data : data;
      
      if (!paymentInfo || !paymentInfo.qr_code) {
        console.error('QR Code não encontrado na resposta:', paymentInfo);
        throw new Error('QR Code não foi gerado');
      }

      setPaymentData(paymentInfo);
      setStatus('pending');
      setTimeLeft(900); // 15 minutos

      console.log('Gerando QR Code visual para:', paymentInfo.qr_code);
      const qrDataUrl = await QRCode.toDataURL(paymentInfo.qr_code, {
        width: 256,
        margin: 2,
        color: { dark: '#000000', light: '#FFFFFF' }
      });
      setQrCodeDataUrl(qrDataUrl);
      console.log('QR Code visual gerado com sucesso');

    } catch (error: any) {
      console.error('Error creating PIX payment:', error);
      
      // Verificar se é erro de credenciais não configuradas
      if (error.message?.includes('Configure suas credenciais') || 
          error.message?.includes('MERCHANT_CREDENTIALS_NOT_FOUND')) {
        toast.error('Pagamento PIX não disponível. O estabelecimento precisa configurar suas credenciais do Mercado Pago.');
      } else {
        toast.error('Erro ao gerar pagamento PIX');
      }
    } finally {
      setLoading(false);
    }
  };

  const copyPixCode = () => {
    if (paymentData?.qr_code) {
      navigator.clipboard.writeText(paymentData.qr_code);
      toast.success('Código PIX copiado!');
    }
  };

  const formatTime = (seconds: number) => {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
  };

  const handleClose = () => {
    setPaymentData(null);
    setQrCodeDataUrl('');
    setStatus('pending');
    setTimeLeft(900); // Reset para 15 minutos
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="max-w-md mx-auto max-h-[90vh] overflow-y-auto rounded-xl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <QrCode className="h-5 w-5 text-primary" />
            Pagamento PIX
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          {loading ? (
            <div className="flex items-center justify-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
          ) : paymentData ? (
            <>
              <Card>
                <CardHeader className="pb-3">
                  <CardTitle className="text-lg">
                    R$ {amount.toFixed(2).replace('.', ',')}
                  </CardTitle>
                  <div className="flex items-center gap-2">
                    <Badge variant={status === 'pending' ? 'default' : status === 'approved' ? 'secondary' : 'destructive'}>
                      {status === 'pending' ? 'Aguardando pagamento' : status === 'approved' ? 'Pago' : 'Expirado'}
                    </Badge>
                    {status === 'pending' && (
                      <div className="flex items-center gap-1 text-sm text-muted-foreground">
                        <Timer className="h-4 w-4" />
                        {formatTime(timeLeft)}
                      </div>
                    )}
                  </div>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-muted-foreground">{description}</p>
                </CardContent>
              </Card>

              {status === 'pending' && (
                <>
                  <div className="text-center mb-4">
                    <div className="flex items-center justify-center gap-2 text-orange-600 mb-2">
                      <Timer className="h-5 w-5" />
                      <span className="font-medium">Aguardando pagamento...</span>
                    </div>
                    <p className="text-sm text-muted-foreground mb-3">
                      Pague o QR Code acima. O Mercado Pago irá notificar automaticamente.
                    </p>
                    <Button 
                      variant="outline" 
                      size="sm" 
                      onClick={checkPaymentStatus}
                      className="mb-2"
                    >
                      🔍 Verificar status
                    </Button>
                    <p className="text-xs text-muted-foreground">
                      A confirmação pode levar até 2 minutos após o pagamento.
                    </p>
                  </div>
                  
                  <div className="space-y-4">
                    {qrCodeDataUrl ? (
                      <div className="flex justify-center">
                        <div className="border-2 border-gray-200 rounded-lg p-2 bg-white">
                          <img src={qrCodeDataUrl} alt="QR Code PIX" className="w-64 h-64" />
                        </div>
                      </div>
                    ) : (
                      <div className="flex justify-center">
                        <div className="animate-pulse text-center space-y-4">
                          <div className="h-8 w-8 rounded-full bg-primary/20 mx-auto animate-spin border-2 border-primary border-t-transparent"></div>
                          <p className="text-muted-foreground">Gerando QR Code...</p>
                        </div>
                      </div>
                    )}
                    
                    {paymentData?.qr_code && (
                      <div className="text-center">
                        <p className="text-sm font-medium mb-2">Código PIX (copie e cole no app do banco):</p>
                        <p className="text-xs font-mono break-all mb-2">{paymentData.qr_code}</p>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={copyPixCode}
                          className="w-full"
                        >
                          <Copy className="h-4 w-4 mr-2" />
                          Copiar código PIX
                        </Button>
                      </div>
                    )}
                  </div>
                  
                  <div className="mt-4 pt-4 border-t">
                    <div className="text-center">
                      <p className="text-sm font-medium text-blue-600 mb-2">
                        ℹ️ Aguarde a notificação
                      </p>
                      <p className="text-xs text-muted-foreground">
                        O Mercado Pago irá notificar nosso sistema automaticamente após seu pagamento.
                        Esta página será atualizada assim que recebermos a confirmação.
                      </p>
                    </div>
                  </div>
                  
                  {showContinueOption && (
                    <div className="mt-4 pt-4 border-t bg-yellow-50 p-3 rounded-lg">
                      <div className="text-center mb-2">
                        <p className="text-sm font-medium text-yellow-800 mb-1">
                          ⏱️ Já se passaram 2 minutos?
                        </p>
                        <p className="text-xs text-yellow-600 mb-3">
                          Se você já pagou e o sistema ainda não detectou, pode continuar.
                          Verificaremos o pagamento posteriormente.
                        </p>
                      </div>
                      <Button 
                        variant="default" 
                        onClick={() => {
                          setStatus('approved');
                          onPaymentComplete(paymentData.id);
                        }}
                        className="w-full bg-yellow-600 hover:bg-yellow-700"
                      >
                        ⏭️ Continuar mesmo assim
                      </Button>
                      <p className="text-xs text-muted-foreground mt-2 text-center">
                        Seu pedido será processado. O pagamento será verificado depois.
                      </p>
                    </div>
                  )}
                </>
              )}

              {status === 'expired' && (
                <div className="text-center py-4">
                  <p className="text-sm text-muted-foreground mb-3">
                    O pagamento expirou.
                  </p>
                </div>
              )}

              {status === 'approved' && (
                <div className="text-center py-4">
                  <div className="flex items-center justify-center gap-2 text-green-600 mb-3">
                    <Check className="h-5 w-5" />
                    <span className="font-medium">Pagamento confirmado!</span>
                  </div>
                  <Button onClick={() => onPaymentComplete(paymentData.id)}>
                    Continuar
                  </Button>
                </div>
              )}
            </>
          ) : (
            <div className="text-center py-4">
              <p className="text-sm text-muted-foreground">Erro ao gerar pagamento PIX</p>
              <Button onClick={createPixPayment} className="mt-3">
                Tentar novamente
              </Button>
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default PixPayment;
