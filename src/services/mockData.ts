import { Product, Order, OrderStatus } from '@/types';

// Mock products data
export const products: Product[] = [
  {
    id: '1',
    name: 'X-Frango',
    description: 'Delicioso hambúrguer de frango com alface e molho especial',
    price: 15.00,
    image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    category: 'burger',
    available: true
  },
  {
    id: '2',
    name: 'X-Tudo',
    description: 'Hambúrguer completo com queijo, bacon, ovo e salada',
    price: 20.00,
    image: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    category: 'burger',
    available: true
  },
  {
    id: '3',
    name: 'X-FILE',
    description: 'Triplo hambúrguer com muito queijo cheddar',
    price: 10.00,
    image: 'https://images.unsplash.com/photo-1564355808539-22fda35bed7e?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    category: 'burger',
    available: true
  },
  {
    id: '4',
    name: 'X-Burger',
    description: 'Clássico hambúrguer com queijo, alface e tomate',
    price: 18.90,
    image: 'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    category: 'burger',
    available: true
  },
  {
    id: '5',
    name: 'French Fries',
    description: 'Batatas fritas crocantes com sal marinho',
    price: 3.99,
    image: 'https://images.unsplash.com/photo-1576107232684-1279f390859f?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    category: 'snack',
    available: true
  },
  {
    id: '6',
    name: 'Combo Família',
    description: 'Hambúrguer, batatas fritas e bebida para 4 pessoas',
    price: 39.99,
    image: 'https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    category: 'combo',
    available: true
  }
];

// Helper to generate random dates within the last 30 days
const getRandomDate = () => {
  const now = new Date();
  const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  const randomTime = thirtyDaysAgo.getTime() + Math.random() * (now.getTime() - thirtyDaysAgo.getTime());
  return new Date(randomTime);
};

// Helper to generate random order status
const getRandomStatus = (): OrderStatus => {
  const statuses: OrderStatus[] = ['pending', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'cancelled'];
  const randomIndex = Math.floor(Math.random() * statuses.length);
  return statuses[randomIndex];
};

// Helper to generate random phone number
const getRandomPhone = () => {
  return `(${Math.floor(Math.random() * 900) + 100}) ${Math.floor(Math.random() * 900) + 100}-${Math.floor(Math.random() * 9000) + 1000}`;
};

// Generate random order items
const generateOrderItems = () => {
  const numberOfItems = Math.floor(Math.random() * 4) + 1;
  const items = [];
  
  for (let i = 0; i < numberOfItems; i++) {
    const randomProduct = products[Math.floor(Math.random() * products.length)];
    const quantity = Math.floor(Math.random() * 3) + 1;
    
    items.push({
      id: `item-${Date.now()}-${i}`,
      productId: randomProduct.id,
      productName: randomProduct.name,
      quantity,
      price: randomProduct.price
    });
  }
  
  return items;
};

// Generate random customer names
const customerNames = [
  'João Silva', 
  'Maria Oliveira', 
  'Pedro Santos', 
  'Ana Costa', 
  'Carlos Pereira', 
  'Fernanda Lima', 
  'Rafael Souza', 
  'Juliana Almeida', 
  'Gustavo Rodrigues', 
  'Carla Martins'
];

// Generate mock orders
export const generateMockOrders = (count: number = 20): Order[] => {
  const orders: Order[] = [];
  
  for (let i = 0; i < count; i++) {
    const items = generateOrderItems();
    const total = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    const createdAt = getRandomDate();
    const updatedAt = new Date(createdAt.getTime() + Math.random() * 3600000); // Add up to 1 hour
    
    orders.push({
      id: `order-${Date.now()}-${i}`,
      items,
      total,
      status: getRandomStatus(),
      customerName: customerNames[Math.floor(Math.random() * customerNames.length)],
      customerPhone: getRandomPhone(),
      createdAt,
      updatedAt
    });
  }
  
  // Sort by date, newest first
  return orders.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
};

// Initial mock orders
export const orders: Order[] = generateMockOrders();

// Generate data for chart (orders per day for the last 7 days)
export const generateOrdersChartData = () => {
  const data = [];
  const now = new Date();
  
  for (let i = 6; i >= 0; i--) {
    const date = new Date(now);
    date.setDate(date.getDate() - i);
    
    const dayOrders = orders.filter(order => {
      const orderDate = new Date(order.createdAt);
      return orderDate.getDate() === date.getDate() && 
             orderDate.getMonth() === date.getMonth() && 
             orderDate.getFullYear() === date.getFullYear();
    });
    
    data.push({
      name: date.toLocaleDateString('pt-BR', { weekday: 'short' }),
      orders: dayOrders.length,
      revenue: dayOrders.reduce((sum, order) => sum + order.total, 0)
    });
  }
  
  return data;
};

// Generate data for order status chart
export const generateOrderStatusChartData = () => {
  const statusCounts = {
    pending: 0,
    preparing: 0,
    ready: 0,
    out_for_delivery: 0,
    delivered: 0,
    cancelled: 0
  };
  
  orders.forEach(order => {
    statusCounts[order.status]++;
  });
  
  return Object.keys(statusCounts).map(status => ({
    name: status.charAt(0).toUpperCase() + status.slice(1),
    value: statusCounts[status as OrderStatus]
  }));
};
