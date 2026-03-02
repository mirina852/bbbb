import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Home, ShoppingBag, BarChart2, Settings, LogOut, Utensils, CreditCard, Lock } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useAuth } from '@/contexts/AuthContext';
import { useSubscription } from '@/contexts/SubscriptionContext';
import { toast } from 'sonner';
import {
  Sidebar as SidebarContainer,
  SidebarContent,
  SidebarHeader,
  SidebarFooter,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  useSidebar
} from '@/components/ui/sidebar';

type SidebarLinkProps = {
  to: string;
  icon: React.ElementType;
  label: string;
  locked?: boolean;
};

const SidebarLink = ({ to, icon: Icon, label, locked = false }: SidebarLinkProps) => {
  const location = useLocation();
  const { state } = useSidebar();
  const isActive = location.pathname === to;

  const handleLockedClick = (e: React.MouseEvent) => {
    if (locked) {
      e.preventDefault();
      toast.error('Recurso bloqueado! Atualize seu plano para ter acesso.', {
        description: 'Clique em "Assinatura" para ver os planos disponíveis.',
        duration: 4000,
      });
    }
  };

  if (locked) {
    return (
      <SidebarMenuItem>
        <SidebarMenuButton 
          onClick={handleLockedClick}
          className={cn(
            "transition-all duration-200 group relative overflow-hidden cursor-not-allowed",
            "text-sidebar-foreground/40 hover:bg-sidebar-accent/10"
          )}
        >
          <Icon className="h-5 w-5 text-sidebar-foreground/40" />
          <span className="flex items-center justify-between w-full">
            {label}
            <Lock className="h-4 w-4 text-sidebar-foreground/40" />
          </span>
        </SidebarMenuButton>
      </SidebarMenuItem>
    );
  }

  return (
    <SidebarMenuItem>
      <SidebarMenuButton asChild className={cn(
        "transition-all duration-200 group relative overflow-hidden",
        isActive 
          ? "bg-sidebar-accent text-sidebar-accent-foreground font-medium" 
          : "text-sidebar-foreground/80 hover:bg-sidebar-accent/30 hover:text-sidebar-foreground"
      )}>
        <Link to={to}>
          {isActive && state === "expanded" && (
            <span className="absolute inset-y-0 left-0 w-1 bg-food-primary rounded-r-full" />
          )}
          <Icon className={cn("h-5 w-5 transition-transform group-hover:scale-110", 
            isActive ? "text-food-primary" : "text-sidebar-foreground/70")} />
          <span>{label}</span>
        </Link>
      </SidebarMenuButton>
    </SidebarMenuItem>
  );
};

const Sidebar = () => {
  const { logout } = useAuth();
  const { isSubscriptionActive } = useSubscription();
  
  // Definir quais recursos estão bloqueados sem assinatura ativa
  const isLocked = !isSubscriptionActive;
  
  return (
    <SidebarContainer className="border-r border-sidebar-border">
      <SidebarHeader className="p-5 border-b border-sidebar-border">
        <div className="flex items-center gap-2">
          <Utensils className="h-7 w-7 text-food-primary" />
          <h1 className="text-sidebar-foreground text-xl font-bold">FoodSaaS</h1>
        </div>
      </SidebarHeader>
      
      <SidebarContent className="p-4">
        <SidebarMenu className="space-y-1">
          <SidebarLink to="/admin" icon={Home} label="Dashboard" locked={isLocked} />
          <SidebarLink to="/admin/products" icon={ShoppingBag} label="Produtos" locked={isLocked} />
          <SidebarLink to="/admin/orders" icon={BarChart2} label="Pedidos" locked={isLocked} />
          <SidebarLink to="/admin/subscription" icon={CreditCard} label="Assinatura" />
          <SidebarLink to="/admin/settings" icon={Settings} label="Configurações" locked={isLocked} />
        </SidebarMenu>
      </SidebarContent>

      <SidebarFooter className="p-4 border-t border-sidebar-border">
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton 
              onClick={logout} 
              className="transition-all duration-200 text-sidebar-foreground/80 hover:bg-sidebar-accent/30 hover:text-sidebar-foreground group"
            >
              <LogOut className="h-5 w-5 text-sidebar-foreground/70 transition-transform group-hover:scale-110 group-hover:text-red-400" />
              <span>Sair</span>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
    </SidebarContainer>
  );
};

export default Sidebar;