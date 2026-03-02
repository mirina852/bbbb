
import React, { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import AdminLayout from '@/layouts/AdminLayout';
import PageHeader from '@/components/common/PageHeader';
import NotificationSettings from '@/components/settings/NotificationSettings';
import SiteCustomization from '@/components/settings/SiteCustomization';
import StoreUrlDisplay from '@/components/settings/StoreUrlDisplay';
import MercadoPagoConfig from '@/components/payment/MercadoPagoConfig';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Settings as SettingsIcon, Bell, Palette, CreditCard } from 'lucide-react';

const Settings = () => {
  const [searchParams] = useSearchParams();
  const [activeTab, setActiveTab] = useState('site');

  useEffect(() => {
    const tab = searchParams.get('tab');
    if (tab && ['site', 'notifications', 'payment'].includes(tab)) {
      setActiveTab(tab);
    }
  }, [searchParams]);

  return (
    <AdminLayout>
      <div className="space-y-6">
        <PageHeader 
          title="Configurações" 
          description="Gerencie as configurações do sistema" 
        />
        
        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="site" className="flex items-center gap-2">
              <Palette className="h-4 w-4" />
              Personalização
            </TabsTrigger>
            <TabsTrigger value="notifications" className="flex items-center gap-2">
              <Bell className="h-4 w-4" />
              Notificações
            </TabsTrigger>
            <TabsTrigger value="payment" className="flex items-center gap-2">
              <CreditCard className="h-4 w-4" />
              Pagamentos
            </TabsTrigger>
          </TabsList>
          
          <TabsContent value="site" className="space-y-6">
            <StoreUrlDisplay />
            <SiteCustomization />
          </TabsContent>
          
          <TabsContent value="notifications">
            <NotificationSettings />
          </TabsContent>
          
          <TabsContent value="payment">
            <MercadoPagoConfig />
          </TabsContent>
        </Tabs>
      </div>
    </AdminLayout>
  );
};

export default Settings;
