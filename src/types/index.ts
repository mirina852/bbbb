// Store (Loja)
export interface Store {
  id: string;
  owner_id: string;
  name: string;
  slug: string;
  description?: string;
  phone?: string;
  email?: string;
  address?: string;
  city?: string;
  state?: string;
  zip_code?: string;
  logo_url?: string;
  background_urls?: string[];
  primary_color?: string;
  delivery_fee: number;
  is_active: boolean;
  is_open: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface Ingredient {
  id: string;
  productId: string;
  name: string;
  isExtra?: boolean;
  price?: number;
}

export interface Product {
  id: string;
  store_id?: string;
  category_id?: string;
  name: string;
  description: string;
  price: number;
  image_url?: string;
  available: boolean;
  created_at?: Date | string; // Allow string for Supabase responses
  updated_at?: Date | string; // Allow string for Supabase responses
  ingredients?: Ingredient[];
  // Campos legados (manter para compatibilidade)
  image?: string;
  category?: string;
}

export type OrderStatus = 'pending' | 'pago' | 'preparing' | 'ready' | 'out_for_delivery' | 'delivered' | 'cancelled';

export interface OrderItem {
  id: string;
  productId: string;
  productName: string;
  quantity: number;
  price: number;
  removedIngredients?: string[];
  extraIngredients?: {name: string, price: number}[];
}

export interface Order {
  id: string;
  store_id?: string; // Optional for backwards compatibility
  items: OrderItem[];
  total: number;
  status: OrderStatus;
  customerName: string;
  customerPhone?: string;
  deliveryAddress?: string;
  paymentMethod?: string;
  createdAt: Date;
  updatedAt: Date;
}

// Site settings interface
export interface SiteSettings {
  id?: string;
  store_id?: string;
  logo_url?: string;
  background_urls?: string[];
  background_url?: string; // Legacy field
  primary_color?: string;
  site_title?: string;
  delivery_fee?: number;
}
