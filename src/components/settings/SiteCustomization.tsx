import React, { useState, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useToast } from '@/hooks/use-toast';
import { Upload, X, Image, Plus } from 'lucide-react';
import { siteSettingsService } from '@/services/siteSettingsService';
import { useStore } from '@/contexts/StoreContext';
import { Carousel, CarouselContent, CarouselItem, CarouselNext, CarouselPrevious } from '@/components/ui/carousel';

const SiteCustomization = () => {
  const { toast } = useToast();
  const { currentStore, userStores, updateStore, loadUserStores } = useStore();
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState({ logo: false, background: false });
  const [logoPreview, setLogoPreview] = useState<string | null>(null);
  const [backgroundPreview, setBackgroundPreview] = useState<string | null>(null);

  // Usar a loja atual ou a primeira loja do usuário
  const store = currentStore || userStores[0];

  useEffect(() => {
    if (!store) {
      loadUserStores();
    }
  }, [store, loadUserStores]);


  const handleFileSelect = (file: File, type: 'logo' | 'background') => {
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      toast({
        variant: "destructive",
        title: "Por favor, selecione apenas arquivos de imagem",
      });
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      toast({
        variant: "destructive",
        title: "O arquivo deve ter no máximo 5MB",
      });
      return;
    }

    // Gerar preview
    const reader = new FileReader();
    reader.onloadend = () => {
      if (type === 'logo') {
        setLogoPreview(reader.result as string);
      } else {
        setBackgroundPreview(reader.result as string);
      }
    };
    reader.readAsDataURL(file);

    // Fazer upload
    handleFileUpload(file, type);
  };

  const handleFileUpload = async (file: File, type: 'logo' | 'background') => {
    if (!file || !store) return;

    setUploading(prev => ({ ...prev, [type]: true }));

    try {
      const imageUrl = await siteSettingsService.uploadImage(file, type);

      if (type === 'background') {
        // Adiciona ao array de backgrounds da loja
        const currentUrls = store.background_urls || [];
        await updateStore(store.id, {
          background_urls: [...currentUrls, imageUrl]
        });
      } else {
        // Para logo, substitui a imagem atual
        if (store.logo_url) {
          await siteSettingsService.deleteImage(store.logo_url);
        }
        await updateStore(store.id, {
          logo_url: imageUrl
        });
      }

      toast({
        title: `${type === 'logo' ? 'Logo' : 'Imagem de fundo'} adicionada com sucesso!`,
      });
      
      // Limpar preview após upload bem-sucedido
      if (type === 'logo') {
        setLogoPreview(null);
      } else {
        setBackgroundPreview(null);
      }
    } catch (error) {
      console.error('Error uploading image:', error);
      toast({
        variant: "destructive",
        title: "Erro ao fazer upload da imagem"
      });
      // Limpar preview em caso de erro também
      if (type === 'logo') {
        setLogoPreview(null);
      } else {
        setBackgroundPreview(null);
      }
    } finally {
      setUploading(prev => ({ ...prev, [type]: false }));
    }
  };

  const handleRemoveImage = async (type: 'logo' | 'background', imageUrl?: string) => {
    if (!store) return;

    try {
      if (type === 'logo') {
        const oldUrl = store.logo_url;
        if (oldUrl) {
          await siteSettingsService.deleteImage(oldUrl);
        }
        await updateStore(store.id, {
          logo_url: null
        });
        toast({
          title: "Logo removido com sucesso!",
        });
      } else if (type === 'background' && imageUrl) {
        // Remove uma imagem específica do array
        await siteSettingsService.deleteImage(imageUrl);
        const currentUrls = store.background_urls || [];
        const updatedUrls = currentUrls.filter(url => url !== imageUrl);
        await updateStore(store.id, {
          background_urls: updatedUrls
        });
        toast({
          title: "Imagem de fundo removida com sucesso!",
        });
      }
    } catch (error) {
      console.error('Error removing image:', error);
      toast({
        variant: "destructive",
        title: "Erro ao remover imagem",
      });
    }
  };
  if (!store) {
    return (
      <Card>
        <CardContent className="p-6">
          <div className="text-center text-muted-foreground">
            Nenhuma loja encontrada. Crie uma loja primeiro.
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Personalização da Loja</CardTitle>
        <CardDescription>
          Edite o logo e imagens de fundo da loja: {store.name}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">

        {/* Logo Upload */}
        <div className="space-y-3">
          <Label htmlFor="logo-upload">Logo</Label>
          <div className="flex items-center gap-4">
            {logoPreview || store.logo_url ? (
              <div className="relative group">
                <img 
                  src={logoPreview || store.logo_url} 
                  alt={logoPreview ? "Preview do logo" : "Logo atual"} 
                  className="w-20 h-20 object-contain bg-gray-100 rounded-lg border-2 border-dashed border-gray-300"
                />
                {uploading.logo && (
                  <div className="absolute inset-0 bg-black/50 rounded-lg flex items-center justify-center">
                    <div className="animate-spin rounded-full h-6 w-6 border-2 border-white border-t-transparent"></div>
                  </div>
                )}
                {!uploading.logo && store.logo_url && !logoPreview && (
                  <Button
                    type="button"
                    variant="destructive"
                    size="sm"
                    className="absolute -top-2 -right-2 h-6 w-6 p-0 opacity-0 group-hover:opacity-100 transition-opacity"
                    onClick={() => handleRemoveImage('logo')}
                  >
                    <X className="h-3 w-3" />
                  </Button>
                )}
              </div>
            ) : (
              <div className="w-20 h-20 bg-gray-100 rounded-lg border-2 border-dashed border-gray-300 flex items-center justify-center">
                <Image className="h-8 w-8 text-gray-400" />
              </div>
            )}
            <div className="flex-1">
              <Input
                id="logo-upload"
                type="file"
                accept="image/*"
                onChange={(e) => {
                  const file = e.target.files?.[0];
                  if (file) handleFileSelect(file, 'logo');
                }}
                disabled={uploading.logo}
                className="hidden"
              />
              <Label htmlFor="logo-upload">
                <Button 
                  type="button" 
                  variant="outline" 
                  disabled={uploading.logo}
                  className="cursor-pointer"
                  asChild
                >
                  <div>
                    <Upload className="h-4 w-4 mr-2" />
                    {uploading.logo ? 'Enviando...' : 'Escolher Logo'}
                  </div>
                </Button>
              </Label>
              <p className="text-sm text-muted-foreground mt-1">
                PNG, JPG, GIF (máx. 5MB)
              </p>
            </div>
          </div>
        </div>

        {/* Background Upload - Carrossel */}
        <div className="space-y-3">
          <Label>Imagens de Fundo</Label>
          <div className="space-y-4">
            {(store.background_urls && store.background_urls.length > 0) || backgroundPreview ? (
              <div className="relative">
                <Carousel className="w-full">
                  <CarouselContent>
                    {/* Preview da imagem sendo enviada */}
                    {backgroundPreview && (
                      <CarouselItem className="md:basis-1/2 lg:basis-1/3">
                        <div className="relative">
                          <img 
                            src={backgroundPreview} 
                            alt="Preview" 
                            className="w-full h-32 object-cover bg-gray-100 rounded-lg border-2 border-dashed border-primary"
                          />
                          <div className="absolute inset-0 bg-black/50 rounded-lg flex flex-col items-center justify-center gap-2">
                            <div className="animate-spin rounded-full h-8 w-8 border-2 border-white border-t-transparent"></div>
                            <span className="text-white text-xs font-medium">Enviando...</span>
                          </div>
                        </div>
                      </CarouselItem>
                    )}
                    
                    {/* Imagens já salvas */}
                    {store.background_urls?.map((url, index) => (
                      <CarouselItem key={index} className="md:basis-1/2 lg:basis-1/3">
                        <div className="relative group">
                          <img 
                            src={url} 
                            alt={`Fundo ${index + 1}`} 
                            className="w-full h-32 object-cover bg-gray-100 rounded-lg border-2 border-dashed border-gray-300"
                          />
                          <Button
                            type="button"
                            variant="destructive"
                            size="sm"
                            className="absolute -top-2 -right-2 h-6 w-6 p-0 opacity-0 group-hover:opacity-100 transition-opacity"
                            onClick={() => handleRemoveImage('background', url)}
                          >
                            <X className="h-3 w-3" />
                          </Button>
                        </div>
                      </CarouselItem>
                    ))}
                    
                    {/* Botão para adicionar nova imagem */}
                    <CarouselItem className="md:basis-1/2 lg:basis-1/3">
                      <div className="w-full h-32 bg-gray-100 rounded-lg border-2 border-dashed border-gray-300 flex items-center justify-center hover:bg-gray-50 transition-colors">
                        <Label htmlFor="background-upload" className="cursor-pointer flex flex-col items-center gap-2">
                          <Plus className="h-8 w-8 text-gray-400" />
                          <span className="text-sm text-gray-500">Adicionar</span>
                        </Label>
                      </div>
                    </CarouselItem>
                  </CarouselContent>
                  {((store.background_urls?.length || 0) + (backgroundPreview ? 1 : 0)) > 2 && (
                    <>
                      <CarouselPrevious />
                      <CarouselNext />
                    </>
                  )}
                </Carousel>
              </div>
            ) : (
              <div className="w-full h-32 bg-gray-100 rounded-lg border-2 border-dashed border-gray-300 flex items-center justify-center hover:bg-gray-50 transition-colors">
                <Label htmlFor="background-upload" className="cursor-pointer flex flex-col items-center gap-2">
                  <Plus className="h-8 w-8 text-gray-400" />
                  <span className="text-sm text-gray-500">Adicionar primeira imagem</span>
                </Label>
              </div>
            )}
            
            <Input
              id="background-upload"
              type="file"
              accept="image/*"
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) handleFileSelect(file, 'background');
                // Limpar o input para permitir selecionar o mesmo arquivo novamente
                e.target.value = '';
              }}
              disabled={uploading.background}
              className="hidden"
            />
            
            <p className="text-sm text-muted-foreground">
              PNG, JPG, GIF (máx. 5MB). Adicione múltiplas imagens para criar um carrossel de fundo.
            </p>
          </div>
        </div>

      </CardContent>
    </Card>
  );
};

export default SiteCustomization;
