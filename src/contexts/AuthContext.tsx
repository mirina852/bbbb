
import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { User, Session } from '@supabase/supabase-js';
import { toast } from "sonner";

interface AuthContextType {
  user: User | null;
  session: Session | null;
  isLoading: boolean;
  loading: boolean; // Alias for isLoading for backwards compatibility
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string) => Promise<{ user: User | null }>;
  logout: () => Promise<void>;
  isAdmin: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Set up auth state listener
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event, session) => {
        setSession(session);
        setUser(session?.user ?? null);
        setIsLoading(false);
      }
    );

    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      setIsLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const login = async (email: string, password: string) => {
    try {
      setIsLoading(true);
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      
      if (error) throw error;
      toast.success("Login realizado com sucesso!");
    } catch (error: any) {
      toast.error(error.message || "Erro no login");
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const register = async (email: string, password: string) => {
    try {
      setIsLoading(true);
      
      // Check if registration is still allowed (no users exist)
      const { data: allowed, error: checkError } = await supabase.rpc('is_registration_allowed' as any);
      if (checkError) throw checkError;
      if (!allowed) {
        throw new Error('O registro não está mais disponível. Uma conta já foi criada.');
      }
      
      const redirectUrl = `${window.location.origin}/auth?confirmed=true`;
      
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          emailRedirectTo: redirectUrl
        }
      });
      
      if (error) throw error;
      
      // Verificar se o email precisa ser confirmado
      if (data.user && !data.session) {
        // Email de confirmação foi enviado
        toast.info(
          "Verifique seu email para confirmar sua conta. Após confirmar, você poderá fazer login.",
          { duration: 8000 }
        );
      } else if (data.session) {
        // Usuário já está autenticado (confirmação automática está habilitada)
        toast.success("Registro realizado com sucesso!");
      }
      
      return { user: data.user };
    } catch (error: any) {
      toast.error(error.message || "Erro no registro");
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = async () => {
    try {
      // Limpar estado local primeiro
      setUser(null);
      setSession(null);
      
      // Fazer logout no Supabase
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      
      // Limpar localStorage completamente
      localStorage.removeItem('supabase.auth.token');
      localStorage.clear();
      
      toast.info("Logout realizado com sucesso");
      
      // Redirecionar para página de autenticação após um pequeno delay
      setTimeout(() => {
        window.location.href = '/auth';
      }, 500);
    } catch (error: any) {
      console.error('Erro no logout:', error);
      toast.error(error.message || "Erro no logout");
      
      // Mesmo com erro, limpar tudo e redirecionar
      setUser(null);
      setSession(null);
      localStorage.clear();
      window.location.href = '/auth';
    }
  };

  // For now, consider all authenticated users as admin
  // In production, you'd check user roles from a database
  const isAdmin = !!user;

  return (
    <AuthContext.Provider value={{ 
      user, 
      session, 
      isLoading,
      loading: isLoading, // Alias for backwards compatibility
      login, 
      register, 
      logout, 
      isAdmin 
    }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
