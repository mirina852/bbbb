import React from 'react';
import { ShoppingBag, DollarSign, Users, ClipboardList, TrendingUp, Activity } from 'lucide-react';
import AdminLayout from '@/layouts/AdminLayout';
import PageHeader from '@/components/common/PageHeader';
import DashboardCard from '@/components/dashboard/DashboardCard';
import OrdersChart from '@/components/dashboard/OrdersChart';
import OrderStatusChart from '@/components/dashboard/OrderStatusChart';
import RevenueChart from '@/components/dashboard/RevenueChart';
import RecentOrdersTable from '@/components/dashboard/RecentOrdersTable';
import { useDashboardData, generateOrdersChartData, generateOrderStatusChartData } from '@/hooks/useDashboardData';
const Dashboard = () => {
  // Usar hook para dados em tempo real
  const {
    orders,
    totalOrders,
    totalRevenue,
    totalCustomers,
    totalProducts
  } = useDashboardData();
  const recentOrders = orders.slice(0, 5);

  // Chart data
  const ordersChartData = generateOrdersChartData(orders);
  const orderStatusChartData = generateOrderStatusChartData(orders);
  return <AdminLayout>
      <div className="space-y-8">
        {/* Header Section */}
        <div className="text-center space-y-4 mb-12">
          
          
        </div>

        {/* Statistics Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-6 mb-12">
          <DashboardCard title="Total de Pedidos" value={totalOrders} icon={<ClipboardList className="h-6 w-6" />} description="Todos os pedidos" trend={"+12% este mês"} variant="primary" />
          <DashboardCard title="Receita Total" value={`R$ ${totalRevenue.toFixed(2).replace('.', ',')}`} icon={<DollarSign className="h-6 w-6" />} description="Receita acumulada" trend={"+8% este mês"} variant="success" />
          <DashboardCard title="Total de Clientes" value={totalCustomers} icon={<Users className="h-6 w-6" />} description="Clientes únicos" trend={"+5% este mês"} variant="info" />
          <DashboardCard title="Produtos Disponíveis" value={totalProducts} icon={<ShoppingBag className="h-6 w-6" />} description="Produtos ativos" trend="2 novos produtos" variant="warning" />
        </div>

        {/* Revenue Chart */}
        <div className="mb-12">
          <RevenueChart orders={orders} />
        </div>

        {/* Charts Section */}
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-8 mb-12">
          <div className="group">
            <OrdersChart data={ordersChartData} />
          </div>
          <div className="group">
            <OrderStatusChart data={orderStatusChartData} />
          </div>
        </div>

        {/* Recent Orders Table */}
        <div className="bg-gradient-to-br from-card to-card/80 rounded-2xl shadow-lg border border-border/50 backdrop-blur-sm">
          <div className="p-6 border-b border-border/50">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-food-primary/10 text-food-primary">
                <Activity className="h-5 w-5" />
              </div>
              <div>
                <h3 className="text-xl font-semibold">Pedidos Recentes</h3>
                <p className="text-sm text-muted-foreground">Últimos pedidos do sistema</p>
              </div>
            </div>
          </div>
          <div className="p-1">
            <RecentOrdersTable orders={recentOrders} />
          </div>
        </div>
      </div>
    </AdminLayout>;
};
export default Dashboard;