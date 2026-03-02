import React from 'react';
import { Home, Search, ShoppingCart } from 'lucide-react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';

interface BottomNavigationProps {
  cartItemsCount?: number;
  onCartClick: () => void;
}

const BottomNavigation = ({ cartItemsCount = 0, onCartClick }: BottomNavigationProps) => {
  const location = useLocation();
  const navigate = useNavigate();

  const handleHomeClick = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    
    // Se estiver em uma página de loja, rola para o topo
    // Verifica se não é uma rota especial (admin, auth, store, product, etc.)
    const isStorePage = !location.pathname.startsWith('/admin') && 
                        !location.pathname.startsWith('/auth') && 
                        !location.pathname.startsWith('/store') && 
                        !location.pathname.startsWith('/product') && 
                        !location.pathname.startsWith('/order') && 
                        !location.pathname.startsWith('/track') && 
                        !location.pathname.startsWith('/planos') && 
                        location.pathname !== '/';
    
    if (isStorePage) {
      console.log('Na página da loja - rolando para o topo');
      window.scrollTo({ 
        top: 0, 
        behavior: 'smooth' 
      });
    } else {
      // Se estiver em outra página, volta para a última loja visitada
      console.log('Fora da loja - voltando para a loja');
      
      // Tentar pegar a última loja visitada do localStorage
      const lastStore = localStorage.getItem('lastVisitedStore');
      
      if (lastStore) {
        navigate(lastStore);
      } else {
        // Se não houver loja salva, volta para a home
        navigate('/');
      }
    }
  };

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-background border-t border-border z-50">
      <div className="flex items-center justify-around py-2 px-4 max-w-md mx-auto">
        <Button 
          variant="ghost" 
          size="sm" 
          className="flex flex-col h-auto py-2 px-3"
          onClick={handleHomeClick}
        >
          <Home className="h-5 w-5" />
          <span className="text-xs">Início</span>
        </Button>
        
        <Link to="/track-order" className="flex flex-col items-center gap-1">
          <Button variant="ghost" size="sm" className="flex flex-col h-auto py-2 px-3">
            <Search className="h-5 w-5" />
            <span className="text-xs">Pedido</span>
          </Button>
        </Link>
        
        <Button 
          variant="ghost" 
          size="sm" 
          className="flex flex-col h-auto py-2 px-3 relative"
          onClick={onCartClick}
        >
          <ShoppingCart className="h-5 w-5" />
          <span className="text-xs">Carrinho</span>
          {cartItemsCount > 0 && (
            <Badge className="absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center p-0 bg-[#FF7A30] text-white text-xs">
              {cartItemsCount}
            </Badge>
          )}
        </Button>
      </div>
    </div>
  );
};

export default BottomNavigation;