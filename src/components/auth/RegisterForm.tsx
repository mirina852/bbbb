
import React from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle, CardFooter, CardDescription } from '@/components/ui/card';
import { useAuth } from '@/contexts/AuthContext';
import { useStore } from '@/contexts/StoreContext';
import { toast } from "sonner";
import { Store, Mail, Lock, User, Loader2 } from 'lucide-react';
import { getStoreUrl } from '@/lib/utils/storeUrl';

interface RegisterFormProps {
  onSwitchToLogin: () => void;
}

const RegisterForm = ({ onSwitchToLogin }: RegisterFormProps) => {
  const [name, setName] = React.useState('');
  const [email, setEmail] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [confirmPassword, setConfirmPassword] = React.useState('');
  const [storeName, setStoreName] = React.useState('');
  const [isLoading, setIsLoading] = React.useState(false);
  const { register } = useAuth();
  const { createStore } = useStore();
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!name || !email || !password || !confirmPassword || !storeName) {
      toast.error("Por favor, preencha todos os campos");
      return;
    }
    
    if (password !== confirmPassword) {
      toast.error("As senhas não coincidem");
      return;
    }
    
    if (password.length < 6) {
      toast.error("A senha deve ter no mínimo 6 caracteres");
      return;
    }

    if (storeName.length > 30) {
      toast.error("O nome da loja deve ter no máximo 30 caracteres");
      return;
    }
    
    setIsLoading(true);
    try {
      // 1. Criar conta do usuário
      const { user } = await register(email, password);
      
      if (!user) {
        throw new Error('Erro ao criar usuário');
      }

      // 2. Verificar se precisa confirmar email
      // Se user.email_confirmed_at for null, significa que precisa confirmar
      const needsEmailConfirmation = !user.email_confirmed_at;

      if (needsEmailConfirmation) {
        // Mostrar mensagem sobre confirmação de email
        toast.info(
          <div>
            <p className="font-semibold">📧 Confirme seu email</p>
            <p className="text-sm mt-1">
              Enviamos um link de confirmação para <strong>{email}</strong>
            </p>
            <p className="text-xs mt-2 text-muted-foreground">
              Após confirmar, você poderá fazer login e sua loja será criada automaticamente.
            </p>
          </div>,
          { duration: 15000 }
        );
        
        // Aguardar um pouco e redirecionar para login
        setTimeout(() => {
          onSwitchToLogin();
        }, 2000);
        return;
      }

      // 3. Se não precisa confirmar email, criar loja automaticamente
      const store = await createStore({
        name: storeName,
        description: `Loja de ${name}`,
      });

      // 4. Mostrar sucesso com URL da loja
      const storeUrl = getStoreUrl(store.slug);
      toast.success(
        <div>
          <p className="font-semibold">Conta criada com sucesso! 🎉</p>
          <p className="text-sm mt-1">Sua loja está no ar:</p>
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
    } catch (error: any) {
      console.error("Erro no registro:", error);
      
      // Mensagens de erro mais específicas
      let errorMessage = "Erro ao criar conta. Tente novamente.";
      
      if (error.message) {
        if (error.message.includes('generate_unique_slug')) {
          errorMessage = "Erro ao gerar URL da loja. Execute o SQL de correção.";
        } else if (error.message.includes('stores')) {
          errorMessage = "Erro ao criar loja: " + error.message;
        } else if (error.message.includes('User already registered')) {
          errorMessage = "Este e-mail já está cadastrado.";
        } else {
          errorMessage = error.message;
        }
      }
      
      toast.error(errorMessage, { duration: 5000 });
    } finally {
      setIsLoading(false);
    }
  };
  
  return (
    <Card className="w-full max-w-md mx-auto">
      <CardHeader className="space-y-1">
        <div className="flex justify-center mb-2">
          <div className="bg-primary/10 p-3 rounded-full">
            <Store className="h-8 w-8 text-primary" />
          </div>
        </div>
        <CardTitle className="text-2xl font-bold text-center">Criar Conta e Loja</CardTitle>
        <CardDescription className="text-center">
          Cadastre-se e sua loja estará no ar em segundos!
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Nome da Loja */}
          <div className="space-y-2">
            <Label htmlFor="storeName" className="flex items-center gap-2">
              <Store className="h-4 w-4" />
              Nome da Loja *
            </Label>
            <Input
              id="storeName"
              value={storeName}
              onChange={(e) => setStoreName(e.target.value)}
              placeholder='Ex: "Mundo das Plantas"'
              required
              maxLength={30}
            />
            <p className="text-xs text-muted-foreground">
              Será usado para gerar sua URL (ex: mundo-das-plantas)
            </p>
          </div>

          {/* Nome do Proprietário */}
          <div className="space-y-2">
            <Label htmlFor="name" className="flex items-center gap-2">
              <User className="h-4 w-4" />
              Seu Nome *
            </Label>
            <Input
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Digite seu nome"
              required
            />
          </div>

          {/* Email */}
          <div className="space-y-2">
            <Label htmlFor="email" className="flex items-center gap-2">
              <Mail className="h-4 w-4" />
              E-mail *
            </Label>
            <Input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="seu@email.com"
              required
            />
          </div>

          {/* Senha */}
          <div className="space-y-2">
            <Label htmlFor="password" className="flex items-center gap-2">
              <Lock className="h-4 w-4" />
              Senha *
            </Label>
            <Input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Mínimo 6 caracteres"
              required
              minLength={6}
            />
          </div>

          {/* Confirmar Senha */}
          <div className="space-y-2">
            <Label htmlFor="confirmPassword" className="flex items-center gap-2">
              <Lock className="h-4 w-4" />
              Confirmar Senha *
            </Label>
            <Input
              id="confirmPassword"
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Digite a senha novamente"
              required
              minLength={6}
            />
          </div>
          <Button 
            type="submit" 
            className="w-full"
            disabled={isLoading}
          >
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Criando conta e loja...
              </>
            ) : (
              'Criar Conta e Loja'
            )}
          </Button>
        </form>
      </CardContent>
      <CardFooter className="flex justify-center">
        <Button variant="link" onClick={onSwitchToLogin}>
          Já tem uma conta? Fazer login
        </Button>
      </CardFooter>
    </Card>
  );
};

export default RegisterForm;
