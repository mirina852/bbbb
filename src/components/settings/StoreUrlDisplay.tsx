import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useStore } from '@/contexts/StoreContext';
import { toast } from 'sonner';
import { ExternalLink, Copy, Share2, Download, Printer, QrCode } from 'lucide-react';
import { getStoreUrl } from '@/lib/utils/storeUrl';
import * as QRCodeLib from 'qrcode';

const StoreUrlDisplay: React.FC = () => {
  const { currentStore, userStores, loading, loadUserStores } = useStore();

  // Forçar carregamento das lojas ao montar o componente
  React.useEffect(() => {
    if (!currentStore && userStores.length === 0 && !loading) {
      console.log('StoreUrlDisplay - Forçando carregamento de lojas');
      loadUserStores();
    }
  }, []);

  // Debug: mostrar informações
  React.useEffect(() => {
    console.log('StoreUrlDisplay - currentStore:', currentStore);
    console.log('StoreUrlDisplay - userStores:', userStores);
    console.log('StoreUrlDisplay - loading:', loading);
  }, [currentStore, userStores, loading]);

  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>URL da Loja</CardTitle>
          <CardDescription>Carregando...</CardDescription>
        </CardHeader>
      </Card>
    );
  }

  if (!currentStore) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>URL da Loja</CardTitle>
          <CardDescription>
            {userStores.length === 0 
              ? 'Você ainda não criou uma loja. Vá para /store-setup para criar.'
              : 'Nenhuma loja selecionada. Você tem ' + userStores.length + ' loja(s).'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Button onClick={loadUserStores} variant="outline">
            Recarregar Lojas
          </Button>
          {userStores.length > 0 && (
            <div className="mt-4">
              <p className="text-sm font-semibold mb-2">Suas lojas:</p>
              <ul className="text-sm space-y-1">
                {userStores.map(store => (
                  <li key={store.id}>
                    {store.name} ({store.slug})
                  </li>
                ))}
              </ul>
            </div>
          )}
        </CardContent>
      </Card>
    );
  }

  const storeUrl = getStoreUrl(currentStore.slug);
  const [qrCodeDataUrl, setQrCodeDataUrl] = useState<string>('');

  useEffect(() => {
    if (storeUrl) {
      QRCodeLib.toDataURL(storeUrl, {
        width: 200,
        margin: 2,
        color: { dark: '#000000', light: '#FFFFFF' }
      }).then(setQrCodeDataUrl).catch(console.error);
    }
  }, [storeUrl]);

  const handleCopy = () => {
    navigator.clipboard.writeText(storeUrl);
    toast.success('URL copiada para a área de transferência!');
  };

  const handleShare = async () => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: currentStore.name,
          text: `Confira ${currentStore.name}!`,
          url: storeUrl,
        });
        toast.success('Compartilhado com sucesso!');
      } catch (error) {
        console.log('Compartilhamento cancelado');
      }
    } else {
      handleCopy();
    }
  };

  const handleDownloadQR = () => {
    if (!qrCodeDataUrl) return;
    const link = document.createElement('a');
    link.download = `qrcode-${currentStore.slug}.png`;
    link.href = qrCodeDataUrl;
    link.click();
    toast.success('QR Code baixado!');
  };

  const handlePrintQR = () => {
    if (!qrCodeDataUrl) return;
    const printWindow = window.open('', '_blank');
    if (printWindow) {
      printWindow.document.write(`
        <html>
          <head><title>QR Code - ${currentStore.name}</title></head>
          <body style="display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:100vh;margin:0;font-family:sans-serif;">
            <h2>${currentStore.name}</h2>
            <img src="${qrCodeDataUrl}" style="width:300px;height:300px;" />
            <p style="margin-top:16px;color:#666;">${storeUrl}</p>
          </body>
        </html>
      `);
      printWindow.document.close();
      printWindow.print();
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Share2 className="h-5 w-5" />
          URL da Sua Loja
        </CardTitle>
        <CardDescription>
          Compartilhe este link com seus clientes para que eles possam acessar seu cardápio online
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex gap-2">
          <Input
            value={storeUrl}
            readOnly
            className="font-mono text-sm"
          />
          <Button
            variant="outline"
            size="icon"
            onClick={handleCopy}
            title="Copiar URL"
          >
            <Copy className="h-4 w-4" />
          </Button>
          <Button
            variant="outline"
            size="icon"
            onClick={() => window.open(storeUrl, '_blank')}
            title="Abrir loja"
          >
            <ExternalLink className="h-4 w-4" />
          </Button>
        </div>

        <div className="flex gap-2">
          <Button
            onClick={handleCopy}
            variant="secondary"
            className="flex-1"
          >
            <Copy className="mr-2 h-4 w-4" />
            Copiar Link
          </Button>
          <Button
            onClick={handleShare}
            className="flex-1"
          >
            <Share2 className="mr-2 h-4 w-4" />
            Compartilhar
          </Button>
        </div>

        {/* QR Code Section */}
        <div className="bg-muted p-4 rounded-lg space-y-4">
          <div className="flex items-center gap-2">
            <QrCode className="h-5 w-5" />
            <p className="text-sm font-semibold">QR Code da Loja</p>
          </div>
          
          {qrCodeDataUrl && (
            <div className="flex flex-col items-center space-y-4">
              <div className="bg-white p-3 rounded-lg shadow-sm">
                <img 
                  src={qrCodeDataUrl} 
                  alt="QR Code da loja" 
                  className="w-48 h-48"
                />
              </div>
              
              <div className="flex gap-2 w-full">
                <Button
                  onClick={handleDownloadQR}
                  variant="outline"
                  className="flex-1"
                >
                  <Download className="mr-2 h-4 w-4" />
                  Baixar PNG
                </Button>
                <Button
                  onClick={handlePrintQR}
                  variant="outline"
                  className="flex-1"
                >
                  <Printer className="mr-2 h-4 w-4" />
                  Imprimir
                </Button>
              </div>
            </div>
          )}
        </div>

        <div className="bg-muted p-4 rounded-lg space-y-2">
          <p className="text-sm font-semibold">Como usar:</p>
          <ul className="text-sm text-muted-foreground space-y-1 list-disc list-inside">
            <li>Copie o link e envie para seus clientes</li>
            <li>Adicione em suas redes sociais (Instagram, Facebook, WhatsApp)</li>
            <li>Coloque em cartões de visita ou cardápios físicos</li>
            <li>Use em anúncios e materiais de marketing</li>
          </ul>
        </div>

        <div className="bg-blue-50 dark:bg-blue-950 p-4 rounded-lg border border-blue-200 dark:border-blue-800">
          <p className="text-sm font-semibold text-blue-900 dark:text-blue-100 mb-2">
            💡 Dica: Use o QR Code
          </p>
          <p className="text-sm text-blue-800 dark:text-blue-200">
            Imprima o QR Code e coloque nas mesas do seu estabelecimento, cardápios físicos ou cartões de visita. 
            Seus clientes podem escanear e fazer pedidos diretamente pelo celular!
          </p>
        </div>
      </CardContent>
    </Card>
  );
};

export default StoreUrlDisplay;
