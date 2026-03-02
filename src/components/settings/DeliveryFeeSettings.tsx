import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Truck } from 'lucide-react';
import { toast } from 'sonner';
import { useStore } from '@/contexts/StoreContext';

interface DeliveryFeeSettingsProps {
  isOpen: boolean;
  onClose: () => void;
  currentFee: number;
  onUpdate: (newFee: number) => void;
}

const DeliveryFeeSettings = ({ isOpen, onClose, currentFee, onUpdate }: DeliveryFeeSettingsProps) => {
  const [deliveryFee, setDeliveryFee] = useState(currentFee.toString());
  const [loading, setLoading] = useState(false);
  const { currentStore, updateStore } = useStore();

  const handleSave = async () => {
    if (!currentStore) {
      toast.error('Nenhuma loja selecionada');
      return;
    }

    const feeValue = parseFloat(deliveryFee.replace(',', '.'));
    
    if (isNaN(feeValue) || feeValue < 0) {
      toast.error('Por favor, insira um valor válido');
      return;
    }

    setLoading(true);
    try {
      await updateStore(currentStore.id, { delivery_fee: feeValue });
      toast.success('Taxa de entrega atualizada com sucesso!');
      onUpdate(feeValue);
      onClose();
    } catch (error) {
      console.error('Erro ao salvar taxa de entrega:', error);
      toast.error('Erro ao salvar taxa de entrega');
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (value: string) => {
    // Remove caracteres não numéricos exceto vírgula e ponto
    const cleaned = value.replace(/[^\d,.]/g, '');
    // Substitui vírgula por ponto para cálculos
    return cleaned.replace(',', '.');
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Truck className="h-5 w-5 text-primary" />
            Taxa de Entrega
          </DialogTitle>
        </DialogHeader>

        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg">Configurar Taxa</CardTitle>
            <CardDescription>
              Defina o valor cobrado para entregas
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="delivery-fee">
                Valor da Taxa (R$)
              </Label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground">
                  R$
                </span>
                <Input
                  id="delivery-fee"
                  value={deliveryFee}
                  onChange={(e) => setDeliveryFee(formatCurrency(e.target.value))}
                  placeholder="5,00"
                  className="pl-12"
                />
              </div>
              <p className="text-sm text-muted-foreground">
                Taxa atual: R$ {currentFee.toFixed(2).replace('.', ',')}
              </p>
            </div>

            <div className="flex gap-3 pt-4">
              <Button 
                variant="outline" 
                onClick={onClose}
                className="flex-1"
                disabled={loading}
              >
                Cancelar
              </Button>
              <Button 
                onClick={handleSave}
                className="flex-1"
                disabled={loading}
              >
                {loading ? 'Salvando...' : 'Salvar'}
              </Button>
            </div>
          </CardContent>
        </Card>
      </DialogContent>
    </Dialog>
  );
};

export default DeliveryFeeSettings;