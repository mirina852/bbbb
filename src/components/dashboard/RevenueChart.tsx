import React, { useState, useMemo } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { TrendingUp, Calendar } from 'lucide-react';
import { Order } from '@/types';
import { format, startOfWeek, endOfWeek, startOfMonth, endOfMonth, addDays, addWeeks, addMonths, isSameDay, isSameWeek, isSameMonth } from 'date-fns';
import { ptBR } from 'date-fns/locale';

interface RevenueChartProps {
  orders: Order[];
}

interface ChartData {
  name: string;
  receita: number;
}

const RevenueChart = ({ orders }: RevenueChartProps) => {
  const [activeTab, setActiveTab] = useState<'day' | 'week' | 'month'>('day');

  const chartData = useMemo(() => {
    const now = new Date();
    const data: ChartData[] = [];

    if (activeTab === 'day') {
      // Últimos 7 dias
      for (let i = 6; i >= 0; i--) {
        const date = addDays(now, -i);
        const dayOrders = orders.filter(order => 
          isSameDay(new Date(order.createdAt), date) && order.status !== 'cancelled'
        );
        const revenue = dayOrders.reduce((sum, order) => sum + order.total, 0);
        
        data.push({
          name: format(date, 'dd/MM', { locale: ptBR }),
          receita: revenue
        });
      }
    } else if (activeTab === 'week') {
      // Últimas 4 semanas
      for (let i = 3; i >= 0; i--) {
        const weekStart = startOfWeek(addWeeks(now, -i), { weekStartsOn: 1 });
        const weekEnd = endOfWeek(weekStart, { weekStartsOn: 1 });
        
        const weekOrders = orders.filter(order => {
          const orderDate = new Date(order.createdAt);
          return orderDate >= weekStart && orderDate <= weekEnd && order.status !== 'cancelled';
        });
        const revenue = weekOrders.reduce((sum, order) => sum + order.total, 0);
        
        data.push({
          name: `${format(weekStart, 'dd/MM', { locale: ptBR })} - ${format(weekEnd, 'dd/MM', { locale: ptBR })}`,
          receita: revenue
        });
      }
    } else if (activeTab === 'month') {
      // Últimos 6 meses
      for (let i = 5; i >= 0; i--) {
        const monthStart = startOfMonth(addMonths(now, -i));
        const monthEnd = endOfMonth(monthStart);
        
        const monthOrders = orders.filter(order => {
          const orderDate = new Date(order.createdAt);
          return orderDate >= monthStart && orderDate <= monthEnd && order.status !== 'cancelled';
        });
        const revenue = monthOrders.reduce((sum, order) => sum + order.total, 0);
        
        data.push({
          name: format(monthStart, 'MMM/yy', { locale: ptBR }),
          receita: revenue
        });
      }
    }

    return data;
  }, [orders, activeTab]);

  const totalRevenue = chartData.reduce((sum, item) => sum + item.receita, 0);
  const averageRevenue = chartData.length > 0 ? totalRevenue / chartData.length : 0;

  const getPeriodLabel = () => {
    switch (activeTab) {
      case 'day': return 'nos últimos 7 dias';
      case 'week': return 'nas últimas 4 semanas';
      case 'month': return 'nos últimos 6 meses';
      default: return '';
    }
  };

  return (
    <Card className="bg-gradient-to-br from-card to-card/80 border border-border/50 shadow-lg backdrop-blur-sm">
      <CardHeader className="pb-4">
        <div className="flex items-center gap-3 mb-4">
          <div className="p-2 rounded-lg bg-green-500/10 text-green-500">
            <TrendingUp className="h-5 w-5" />
          </div>
          <div>
            <CardTitle className="text-xl font-semibold">Receita por Período</CardTitle>
            <CardDescription>
              Análise detalhada da receita {getPeriodLabel()}
            </CardDescription>
          </div>
        </div>

        <Tabs value={activeTab} onValueChange={(value) => setActiveTab(value as any)} className="w-full">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="day" className="flex items-center gap-2">
              <Calendar className="h-4 w-4" />
              Por Dia
            </TabsTrigger>
            <TabsTrigger value="week" className="flex items-center gap-2">
              <Calendar className="h-4 w-4" />
              Por Semana
            </TabsTrigger>
            <TabsTrigger value="month" className="flex items-center gap-2">
              <Calendar className="h-4 w-4" />
              Por Mês
            </TabsTrigger>
          </TabsList>
        </Tabs>
      </CardHeader>

      <CardContent>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
          <div className="bg-gradient-to-r from-green-500/10 to-emerald-500/10 rounded-lg p-4 border border-green-500/20">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Receita Total</p>
                <p className="text-2xl font-bold text-green-600">
                  R$ {totalRevenue.toFixed(2).replace('.', ',')}
                </p>
              </div>
              <TrendingUp className="h-8 w-8 text-green-500" />
            </div>
          </div>
          
          <div className="bg-gradient-to-r from-blue-500/10 to-indigo-500/10 rounded-lg p-4 border border-blue-500/20">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Receita Média</p>
                <p className="text-2xl font-bold text-blue-600">
                  R$ {averageRevenue.toFixed(2).replace('.', ',')}
                </p>
              </div>
              <Calendar className="h-8 w-8 text-blue-500" />
            </div>
          </div>
        </div>

        <div className="h-80">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" opacity={0.3} />
              <XAxis 
                dataKey="name" 
                stroke="hsl(var(--muted-foreground))"
                fontSize={12}
                tickLine={false}
                axisLine={false}
              />
              <YAxis 
                stroke="hsl(var(--muted-foreground))"
                fontSize={12}
                tickLine={false}
                axisLine={false}
                tickFormatter={(value) => `R$ ${value}`}
              />
              <Tooltip
                content={({ active, payload, label }) => {
                  if (active && payload && payload.length) {
                    return (
                      <div className="bg-background/95 backdrop-blur-sm border border-border rounded-lg shadow-lg p-3">
                        <p className="font-medium text-foreground">{label}</p>
                        <p className="text-green-600 font-semibold">
                          Receita: R$ {payload[0].value?.toLocaleString('pt-BR', { minimumFractionDigits: 2 })}
                        </p>
                      </div>
                    );
                  }
                  return null;
                }}
              />
              <Bar 
                dataKey="receita" 
                fill="url(#revenueGradient)"
                radius={[4, 4, 0, 0]}
                stroke="hsl(var(--border))"
                strokeWidth={1}
              />
              <defs>
                <linearGradient id="revenueGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="rgb(34, 197, 94)" stopOpacity={0.8} />
                  <stop offset="100%" stopColor="rgb(34, 197, 94)" stopOpacity={0.3} />
                </linearGradient>
              </defs>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
};

export default RevenueChart;