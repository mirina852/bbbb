
import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { TrendingUp, TrendingDown } from 'lucide-react';
import { cn } from '@/lib/utils';

interface DashboardCardProps {
  title: string;
  value: string | number;
  icon: React.ReactNode;
  description?: string;
  trend?: string;
  variant?: 'primary' | 'success' | 'info' | 'warning' | 'danger';
  className?: string;
}

const DashboardCard = ({ title, value, icon, description, trend, variant = 'primary', className }: DashboardCardProps) => {
  const getVariantStyles = () => {
    switch (variant) {
      case 'success':
        return {
          gradient: 'from-emerald-500/10 to-green-500/5',
          border: 'border-emerald-500/20',
          iconBg: 'bg-emerald-500/10',
          iconColor: 'text-emerald-600',
          accent: 'border-l-emerald-500'
        };
      case 'info':
        return {
          gradient: 'from-blue-500/10 to-cyan-500/5',
          border: 'border-blue-500/20',
          iconBg: 'bg-blue-500/10',
          iconColor: 'text-blue-600',
          accent: 'border-l-blue-500'
        };
      case 'warning':
        return {
          gradient: 'from-amber-500/10 to-orange-500/5',
          border: 'border-amber-500/20',
          iconBg: 'bg-amber-500/10',
          iconColor: 'text-amber-600',
          accent: 'border-l-amber-500'
        };
      case 'danger':
        return {
          gradient: 'from-red-500/10 to-rose-500/5',
          border: 'border-red-500/20',
          iconBg: 'bg-red-500/10',
          iconColor: 'text-red-600',
          accent: 'border-l-red-500'
        };
      default:
        return {
          gradient: 'from-food-primary/10 to-accent/5',
          border: 'border-food-primary/20',
          iconBg: 'bg-food-primary/10',
          iconColor: 'text-food-primary',
          accent: 'border-l-food-primary'
        };
    }
  };

  const styles = getVariantStyles();

  return (
    <Card className={cn(
      "group relative overflow-hidden transition-all duration-300 hover:shadow-xl hover:scale-[1.02] border-l-4 backdrop-blur-sm",
      `bg-gradient-to-br ${styles.gradient}`,
      styles.border,
      styles.accent,
      className
    )}>
      <CardHeader className="flex flex-row items-center justify-between pb-3 space-y-0">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
        <div className={cn(
          "w-12 h-12 p-3 rounded-xl transition-all duration-300 group-hover:scale-110",
          styles.iconBg,
          styles.iconColor
        )}>
          {icon}
        </div>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="text-3xl font-bold tracking-tight">{value}</div>
        <div className="flex items-center justify-between">
          {description && (
            <p className="text-sm text-muted-foreground">{description}</p>
          )}
          {trend && (
            <div className="flex items-center gap-1 text-xs font-medium text-emerald-600">
              <TrendingUp className="h-3 w-3" />
              {trend}
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
};

export default DashboardCard;
