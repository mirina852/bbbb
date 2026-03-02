import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useSubscription } from '@/contexts/SubscriptionContext';
import { useStore } from '@/contexts/StoreContext';
import { Loader2 } from 'lucide-react';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requireAdmin?: boolean;
  requireSubscription?: boolean;
}

const ProtectedRoute = ({ 
  children, 
  requireAdmin = false,
  requireSubscription = false 
}: ProtectedRouteProps) => {
  const { user, isLoading: authLoading, isAdmin } = useAuth();
  const { isSubscriptionActive, isLoading: subLoading } = useSubscription();
  const { userStores, loading: storeLoading, storesLoaded } = useStore();
  const location = useLocation();

  // Aguardar carregamento inicial - só aguarda assinatura se for requerida
  const isLoading = authLoading || (user && !storesLoaded) || (requireSubscription && subLoading);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin" />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/auth" state={{ from: location }} replace />;
  }

  if (requireAdmin && !isAdmin) {
    return <Navigate to="/" replace />;
  }

  // Se o usuário está autenticado mas não tem loja, redireciona para criar uma
  // Exceto se já estiver na página de setup
  // IMPORTANTE: Só redireciona se as lojas já foram carregadas (storesLoaded === true)
  if (requireAdmin && storesLoaded && userStores.length === 0 && location.pathname !== '/store-setup') {
    console.log('ProtectedRoute: Redirecionando para store-setup - usuário sem lojas');
    return <Navigate to="/store-setup" replace />;
  }

  if (requireSubscription && !isSubscriptionActive) {
    // Redireciona para a página de assinatura para que o usuário possa ver o status e ativar um plano
    return <Navigate to="/admin/subscription" state={{ from: location }} replace />;
  }

  return <>{children}</>;
};

export default ProtectedRoute;