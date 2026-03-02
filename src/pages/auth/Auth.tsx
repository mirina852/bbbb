
import React, { useState } from 'react';
import { Navigate } from 'react-router-dom';
import LoginForm from '@/components/auth/LoginForm';
import RegisterForm from '@/components/auth/RegisterForm';
import { useAuth } from '@/contexts/AuthContext';
import { useRegistrationAllowed } from '@/hooks/useRegistrationAllowed';
import { Loader2 } from 'lucide-react';

const Auth = () => {
  const { user, isAdmin } = useAuth();
  const { isAllowed, isLoading } = useRegistrationAllowed();
  const [showRegister, setShowRegister] = useState(false);
  
  if (user && isAdmin) {
    return <Navigate to="/admin" replace />;
  }

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-muted/30">
        <Loader2 className="h-8 w-8 animate-spin" />
      </div>
    );
  }

  // If no users exist, show registration. Otherwise show login.
  const shouldShowRegister = isAllowed && (showRegister || true);
  
  return (
    <div className="min-h-screen flex items-center justify-center bg-muted/30 px-4">
      <div className="max-w-md w-full">
        {isAllowed ? (
          <RegisterForm onSwitchToLogin={() => setShowRegister(false)} />
        ) : (
          <LoginForm />
        )}
      </div>
    </div>
  );
};

export default Auth;
