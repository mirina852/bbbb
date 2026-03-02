
import React from 'react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface PageHeaderProps {
  title: string;
  description?: string;
  action?: {
    label: string;
    icon?: React.ReactNode;
    onClick: () => void;
  };
  secondaryAction?: {
    label: string;
    onClick: () => void;
    icon?: React.ReactNode;
    variant?: "default" | "destructive" | "outline" | "secondary" | "ghost" | "link";
  };
  className?: string;
}

const PageHeader = ({ title, description, action, secondaryAction, className }: PageHeaderProps) => {
  return (
    <div className={cn("flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 sm:gap-4 mb-4 sm:mb-6 w-full", className)}>
      <div className="w-full sm:w-auto">
        <h1 className="text-lg sm:text-2xl font-bold text-left">{title}</h1>
        {description && <p className="text-muted-foreground mt-0.5 sm:mt-1 text-left text-xs sm:text-base">{description}</p>}
      </div>
      <div className="flex items-center justify-start sm:justify-end gap-2 sm:gap-3 w-full sm:w-auto">
        {secondaryAction && (
          <Button 
            onClick={secondaryAction.onClick}
            variant={secondaryAction.variant || "outline"}
            size="sm"
            className="text-xs sm:text-sm h-9 sm:h-10"
          >
            {secondaryAction.icon && <span className="mr-1 sm:mr-2">{secondaryAction.icon}</span>}
            <span className="hidden sm:inline">{secondaryAction.label}</span>
            <span className="sm:hidden">{secondaryAction.icon ? '' : secondaryAction.label}</span>
          </Button>
        )}
        {action && (
          <Button 
            onClick={action.onClick}
            className="bg-food-primary hover:bg-food-dark text-xs sm:text-sm h-9 sm:h-10 px-3 sm:px-4"
            size="sm"
          >
            {action.icon && <span className="mr-1.5 sm:mr-2">{action.icon}</span>}
            <span>{action.label}</span>
          </Button>
        )}
      </div>
    </div>
  );
};

export default PageHeader;
