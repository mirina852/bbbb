import React, { useEffect } from 'react';
import { useNavigate, Outlet } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useStoreRedirect } from '@/hooks/useStoreRedirect';
import { Loader2 } from 'lucide-react';

/**
 * Layout que protege rotas admin e garante que o usuário tem uma loja
 */
const AdminLayout: React.FC = () => {
  const navigate = useNavigate();
  const { user, loading: authLoading } = useAuth();
  const { hasStores, currentStore } = useStoreRedirect();

  useEffect(() => {
    // Redireciona para login se não estiver autenticado
    if (!authLoading && !user) {
      navigate('/login');
    }
  }, [user, authLoading, navigate]);

  // Loading state
  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <Loader2 className="h-12 w-12 animate-spin text-primary mx-auto mb-4" />
          <p className="text-muted-foreground">Carregando...</p>
        </div>
      </div>
    );
  }

  // Não autenticado
  if (!user) {
    return null;
  }

  // Renderiza o conteúdo admin
  return <Outlet />;
};

export default AdminLayout;
