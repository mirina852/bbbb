
import React, { useEffect, useState } from 'react';
import { CheckCircle, Search } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import BottomNavigation from '@/components/customer/BottomNavigation';

const OrderSuccess = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [storeUrl, setStoreUrl] = useState('/');

  useEffect(() => {
    // Tenta recuperar a URL da loja do estado de navegação ou localStorage
    const stateStoreUrl = location.state?.from;
    const savedStoreUrl = localStorage.getItem('currentStoreUrl');
    
    if (stateStoreUrl) {
      setStoreUrl(stateStoreUrl);
    } else if (savedStoreUrl) {
      setStoreUrl(savedStoreUrl);
    } else {
      // Se não houver URL salva, redireciona para a landing page
      setStoreUrl('/');
    }
  }, [location]);

  const handleBackToMenu = () => {
    // Limpa o localStorage após usar
    localStorage.removeItem('currentStoreUrl');
    navigate(storeUrl);
  };

  return (
    <>
      <div className="min-h-screen flex items-center justify-center bg-muted/20 px-4 pb-16">
        <div className="bg-white rounded-lg shadow-lg p-8 max-w-md w-full text-center">
          <div className="flex justify-center mb-4">
            <CheckCircle className="h-16 w-16 text-green-500" />
          </div>
          <h1 className="text-2xl font-bold mb-2">Pedido Realizado com Sucesso!</h1>
          <p className="text-muted-foreground mb-6">
            Obrigado pelo seu pedido. Estamos preparando sua comida e estará pronta em breve.
          </p>
          <div className="flex flex-col gap-3 sm:flex-row sm:justify-center">
            <Link to="/track-order">
              <Button variant="outline" className="w-full sm:w-auto flex items-center gap-2">
                <Search className="h-4 w-4" />
                Acompanhar Pedido
              </Button>
            </Link>
            <Button 
              onClick={handleBackToMenu}
              className="w-full sm:w-auto bg-food-primary hover:bg-food-dark"
            >
              Voltar ao Menu
            </Button>
          </div>
        </div>
      </div>
      
      <BottomNavigation 
        cartItemsCount={0}
        onCartClick={() => {}}
      />
    </>
  );
};

export default OrderSuccess;
