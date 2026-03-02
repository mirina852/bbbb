
import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts';

interface OrderStatusData {
  name: string;
  value: number;
}

interface OrderStatusChartProps {
  data: OrderStatusData[];
}

const COLORS = [
  'hsl(59, 100%, 58%)',   // Pending - Yellow
  'hsl(142, 76%, 36%)',   // Preparing - Green
  'hsl(35, 100%, 50%)',   // Ready - Orange
  'hsl(260, 100%, 65%)',  // Out for delivery - Purple
  'hsl(218, 91%, 60%)',   // Delivered - Blue
  'hsl(0, 84%, 60%)'      // Cancelled - Red
];

const STATUS_LABELS = {
  'Pending': 'Pendente',
  'Preparing': 'Preparando',
  'Ready': 'Pronto',
  'Out_for_delivery': '🚚 Saiu para entrega',
  'Delivered': 'Entregue',
  'Cancelled': 'Cancelado'
};

const OrderStatusChart = ({ data }: OrderStatusChartProps) => {
  const totalOrders = data.reduce((sum, item) => sum + item.value, 0);

  return (
    <Card className="group relative overflow-hidden bg-gradient-to-br from-card to-card/80 border-border/50 backdrop-blur-sm transition-all duration-300 hover:shadow-xl h-full">
      <CardHeader className="pb-4">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-accent/10 text-accent">
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div>
            <CardTitle className="text-xl font-semibold">Status dos Pedidos</CardTitle>
            <p className="text-sm text-muted-foreground">Distribuição por status</p>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="h-[350px] flex flex-col">
          <div className="flex-1">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <defs>
                  {COLORS.map((color, index) => (
                    <linearGradient key={index} id={`gradient-${index}`} x1="0" y1="0" x2="1" y2="1">
                      <stop offset="0%" stopColor={color} stopOpacity={0.9}/>
                      <stop offset="100%" stopColor={color} stopOpacity={0.6}/>
                    </linearGradient>
                  ))}
                </defs>
                <Pie
                  data={data}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  outerRadius={90}
                  innerRadius={45}
                  fill="#8884d8"
                  dataKey="value"
                  strokeWidth={3}
                  stroke="hsl(var(--background))"
                >
                  {data.map((entry, index) => (
                    <Cell 
                      key={`cell-${index}`} 
                      fill={`url(#gradient-${index % COLORS.length})`}
                      className="transition-all duration-300 hover:opacity-80"
                    />
                  ))}
                </Pie>
                <Tooltip 
                  content={({ active, payload }) => {
                    if (active && payload && payload.length) {
                      const data = payload[0];
                      const percentage = ((data.value as number / totalOrders) * 100).toFixed(1);
                      return (
                        <div className="bg-background/95 backdrop-blur-sm border border-border rounded-lg p-3 shadow-lg">
                          <p className="font-medium">{STATUS_LABELS[data.name as keyof typeof STATUS_LABELS] || data.name}</p>
                          <p className="text-sm text-muted-foreground">
                            {data.value} pedidos ({percentage}%)
                          </p>
                        </div>
                      );
                    }
                    return null;
                  }}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>
          
          {/* Custom Legend */}
          <div className="grid grid-cols-2 gap-3 mt-4 pt-4 border-t border-border/50">
            {data.map((entry, index) => (
              <div key={entry.name} className="flex items-center gap-2">
                <div 
                  className="w-3 h-3 rounded-full border"
                  style={{ backgroundColor: COLORS[index % COLORS.length] }}
                />
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-medium truncate">
                    {STATUS_LABELS[entry.name as keyof typeof STATUS_LABELS] || entry.name}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {entry.value} ({((entry.value / totalOrders) * 100).toFixed(0)}%)
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default OrderStatusChart;
