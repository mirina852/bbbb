import React, { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useStore } from '@/contexts/StoreContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Store, Plus, ExternalLink, MapPin, Phone, Loader2 } from 'lucide-react';

const StoreSelector: React.FC = () => {
  const navigate = useNavigate();
  const { userStores, setCurrentStore, loadUserStores, loading } = useStore();

  useEffect(() => {
    loadUserStores();
  }, []);

  const handleSelectStore = (store: any) => {
    setCurrentStore(store);
    navigate('/admin');
  };

  const handleCreateStore = () => {
    navigate('/store-setup');
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-orange-50 to-orange-100 flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="h-12 w-12 animate-spin text-primary mx-auto mb-4" />
          <p className="text-muted-foreground">Carregando suas lojas...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 to-orange-100 p-4">
      <div className="max-w-6xl mx-auto py-8">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold mb-2">Minhas Lojas</h1>
          <p className="text-muted-foreground">
            Selecione uma loja para gerenciar ou crie uma nova
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* Lojas Existentes */}
          {userStores.map((store) => (
            <Card
              key={store.id}
              className="hover:shadow-lg transition-shadow cursor-pointer group"
              onClick={() => handleSelectStore(store)}
            >
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className="bg-primary/10 p-2 rounded-lg">
                      <Store className="h-6 w-6 text-primary" />
                    </div>
                    <div>
                      <CardTitle className="text-lg group-hover:text-primary transition-colors">
                        {store.name}
                      </CardTitle>
                      <CardDescription className="text-xs mt-1">
                        /{store.slug}
                      </CardDescription>
                    </div>
                  </div>
                  <Badge variant={store.is_open ? 'default' : 'secondary'}>
                    {store.is_open ? 'Aberta' : 'Fechada'}
                  </Badge>
                </div>
              </CardHeader>

              <CardContent className="space-y-3">
                {store.description && (
                  <p className="text-sm text-muted-foreground line-clamp-2">
                    {store.description}
                  </p>
                )}

                <div className="space-y-2 text-sm">
                  {store.address && (
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <MapPin className="h-4 w-4" />
                      <span className="truncate">
                        {store.city && store.state ? `${store.city}, ${store.state}` : store.address}
                      </span>
                    </div>
                  )}

                  {store.phone && (
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <Phone className="h-4 w-4" />
                      <span>{store.phone}</span>
                    </div>
                  )}
                </div>

                <div className="flex gap-2 pt-2">
                  <Button
                    variant="default"
                    className="flex-1"
                    onClick={(e) => {
                      e.stopPropagation();
                      handleSelectStore(store);
                    }}
                  >
                    Gerenciar
                  </Button>
                  <Button
                    variant="outline"
                    size="icon"
                    onClick={(e) => {
                      e.stopPropagation();
                      window.open(`/${store.slug}`, '_blank');
                    }}
                  >
                    <ExternalLink className="h-4 w-4" />
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}

          {/* Card para Criar Nova Loja */}
          <Card
            className="border-dashed border-2 hover:border-primary hover:bg-primary/5 transition-all cursor-pointer flex items-center justify-center min-h-[280px]"
            onClick={handleCreateStore}
          >
            <CardContent className="text-center py-8">
              <div className="bg-primary/10 p-4 rounded-full w-fit mx-auto mb-4">
                <Plus className="h-8 w-8 text-primary" />
              </div>
              <h3 className="font-semibold text-lg mb-2">Criar Nova Loja</h3>
              <p className="text-sm text-muted-foreground">
                Adicione mais uma loja ao seu negócio
              </p>
            </CardContent>
          </Card>
        </div>

        {userStores.length === 0 && (
          <div className="text-center mt-12">
            <div className="bg-white rounded-lg p-8 max-w-md mx-auto">
              <Store className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
              <h2 className="text-xl font-semibold mb-2">Nenhuma loja encontrada</h2>
              <p className="text-muted-foreground mb-6">
                Comece criando sua primeira loja
              </p>
              <Button onClick={handleCreateStore} size="lg">
                <Plus className="mr-2 h-5 w-5" />
                Criar Primeira Loja
              </Button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default StoreSelector;
