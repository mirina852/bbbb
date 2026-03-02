import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useStore } from '@/contexts/StoreContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { toast } from 'sonner';
import { Store, MapPin, Phone, Mail, Loader2 } from 'lucide-react';
import { getStoreUrl } from '@/lib/utils/storeUrl';

const StoreSetup: React.FC = () => {
  const navigate = useNavigate();
  const { createStore, loading } = useStore();

  const [formData, setFormData] = useState({
    name: '',
    description: '',
    phone: '',
    email: '',
    address: '',
    city: '',
    state: '',
    zip_code: '',
    delivery_fee: '5.00',
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!formData.name.trim()) {
      toast.error('Por favor, informe o nome da loja');
      return;
    }

    try {
      const store = await createStore({
        name: formData.name,
        description: formData.description,
        phone: formData.phone,
        email: formData.email,
        address: formData.address,
        city: formData.city,
        state: formData.state,
        zip_code: formData.zip_code,
        delivery_fee: parseFloat(formData.delivery_fee) || 0,
      });

      // Mostra a URL da loja
      const storeUrl = getStoreUrl(store.slug);
      toast.success(
        <div>
          <p className="font-semibold">Sua loja foi criada! 🎉</p>
          <p className="text-sm mt-1">Acesse:</p>
          <a 
            href={storeUrl} 
            target="_blank" 
            rel="noopener noreferrer"
            className="text-xs text-blue-600 hover:text-blue-800 mt-1 break-all underline"
          >
            {storeUrl}
          </a>
        </div>,
        { duration: 10000 }
      );

      // Redireciona para o admin
      navigate('/admin');
    } catch (error) {
      console.error('Erro ao criar loja:', error);
      toast.error('Erro ao criar loja. Tente novamente.');
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 to-orange-100 flex items-center justify-center p-4">
      <Card className="w-full max-w-2xl">
        <CardHeader className="text-center">
          <div className="flex justify-center mb-4">
            <div className="bg-primary/10 p-4 rounded-full">
              <Store className="h-12 w-12 text-primary" />
            </div>
          </div>
          <CardTitle className="text-2xl">Crie sua loja</CardTitle>
          <CardDescription className="text-base">
            Cadastre-se e escolha o nome da sua loja. O nome será usado na URL (ex: minhaloja.exemplo.com)
          </CardDescription>
        </CardHeader>

        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Informações Básicas */}
            <div className="space-y-4">
              <h3 className="font-semibold text-lg flex items-center gap-2">
                <Store className="h-5 w-5" />
                Informações Básicas
              </h3>

              <div className="space-y-2">
                <Label htmlFor="name">Nome da Loja *</Label>
                <Input
                  id="name"
                  name="name"
                  placeholder='Ex: "Mundo das Plantas"'
                  value={formData.name}
                  onChange={handleChange}
                  required
                  maxLength={30}
                />
                <p className="text-xs text-muted-foreground">
                  Apenas letras, números e traços. Sem espaços no slug. Máx. 30 caracteres.
                </p>
              </div>

              <div className="space-y-2">
                <Label htmlFor="description">Descrição</Label>
                <Textarea
                  id="description"
                  name="description"
                  placeholder="Descreva sua loja..."
                  value={formData.description}
                  onChange={handleChange}
                  rows={3}
                />
              </div>
            </div>

            {/* Contato */}
            <div className="space-y-4">
              <h3 className="font-semibold text-lg flex items-center gap-2">
                <Phone className="h-5 w-5" />
                Contato
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="phone">Telefone</Label>
                  <Input
                    id="phone"
                    name="phone"
                    type="tel"
                    placeholder="(11) 99999-9999"
                    value={formData.phone}
                    onChange={handleChange}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="email">E-mail</Label>
                  <Input
                    id="email"
                    name="email"
                    type="email"
                    placeholder="contato@minhaloja.com"
                    value={formData.email}
                    onChange={handleChange}
                  />
                </div>
              </div>
            </div>

            {/* Endereço */}
            <div className="space-y-4">
              <h3 className="font-semibold text-lg flex items-center gap-2">
                <MapPin className="h-5 w-5" />
                Endereço
              </h3>

              <div className="space-y-2">
                <Label htmlFor="address">Endereço Completo</Label>
                <Input
                  id="address"
                  name="address"
                  placeholder="Rua, número, complemento"
                  value={formData.address}
                  onChange={handleChange}
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="city">Cidade</Label>
                  <Input
                    id="city"
                    name="city"
                    placeholder="São Paulo"
                    value={formData.city}
                    onChange={handleChange}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="state">Estado</Label>
                  <Input
                    id="state"
                    name="state"
                    placeholder="SP"
                    value={formData.state}
                    onChange={handleChange}
                    maxLength={2}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="zip_code">CEP</Label>
                  <Input
                    id="zip_code"
                    name="zip_code"
                    placeholder="00000-000"
                    value={formData.zip_code}
                    onChange={handleChange}
                  />
                </div>
              </div>
            </div>

            {/* Taxa de Entrega */}
            <div className="space-y-4">
              <h3 className="font-semibold text-lg">Configurações</h3>

              <div className="space-y-2">
                <Label htmlFor="delivery_fee">Taxa de Entrega (R$)</Label>
                <Input
                  id="delivery_fee"
                  name="delivery_fee"
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="5.00"
                  value={formData.delivery_fee}
                  onChange={handleChange}
                />
              </div>
            </div>

            {/* Botões */}
            <div className="flex gap-3 pt-4">
              <Button
                type="submit"
                className="flex-1"
                disabled={loading}
              >
                {loading ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Criando...
                  </>
                ) : (
                  'Criar conta'
                )}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
};

export default StoreSetup;
