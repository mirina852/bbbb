
import React, { useState, useEffect } from 'react';
import { Product } from '@/types';
import { productsService, ordersService, categoriesService } from '@/services/supabaseService';
import ProductList from '@/components/customer/ProductList';
import Cart from '@/components/customer/Cart';
import CheckoutForm from '@/components/customer/CheckoutForm';
import BottomNavigation from '@/components/customer/BottomNavigation';
import { useNavigate } from 'react-router-dom';
import { toast } from "sonner";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from '@/components/ui/badge';
import { Utensils } from 'lucide-react';
import { useSiteSettings } from '@/hooks/useSiteSettings';
import { Button } from '@/components/ui/button';
import { useCart } from '@/contexts/CartContext';
import BackgroundCarousel from '@/components/customer/BackgroundCarousel';
import { getIconComponent } from '@/utils/categoryIcons';
import { useMercadoPago } from '@/contexts/MercadoPagoContext';
import { supabase } from '@/integrations/supabase/client';

interface Category {
  id: string;
  name: string;
  slug: string;
  display_order: number;
  icon?: string;
}

const StoreFront: React.FC = () => {
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [isCheckoutOpen, setIsCheckoutOpen] = useState(false);
  const [loading, setLoading] = useState(true);

  const navigate = useNavigate();
  const { cartItems, addToCart, removeFromCart, updateQuantity, clearCart } = useCart();
  const { loadConfig } = useMercadoPago();
  const [activeStoreId, setActiveStoreId] = useState<string | undefined>(undefined);

  // 🔹 Estado para armazenar dados da loja (logo, backgrounds, nome, taxa de entrega)
  const [storeData, setStoreData] = useState<{
    logo_url: string | null;
    background_urls: string[] | null;
    name: string;
    delivery_fee: number;
  } | null>(null);

  const logoTop = 105;
  const logoLeft = 20;

  useEffect(() => {
    loadProducts();
    loadCategories();
    loadMercadoPagoCredentials();
  }, []);

  // Carregar credenciais do Mercado Pago da primeira loja ativa
  const loadMercadoPagoCredentials = async () => {
    try {
      // Buscar a primeira loja ativa (incluindo logo, backgrounds, nome e taxa de entrega)
      const { data: stores } = await supabase
        .from('stores')
        .select('id, logo_url, background_urls, name, delivery_fee')
        .eq('is_active', true)
        .order('created_at', { ascending: true })
        .limit(1)
        .maybeSingle();

      if (stores?.id) {
        console.log('🔑 Carregando dados da loja:', stores.id);
        setActiveStoreId(stores.id);
        setStoreData({
          logo_url: stores.logo_url,
          background_urls: stores.background_urls,
          name: stores.name,
          delivery_fee: stores.delivery_fee ?? 0
        });
        await loadConfig(stores.id);
      } else {
        console.log('⚠️ Nenhuma loja ativa encontrada');
      }
    } catch (error) {
      console.error('❌ Erro ao carregar dados da loja:', error);
    }
  };

  const loadProducts = async () => {
    try {
      const data = await productsService.getAll();
      setProducts(data || []);
    } catch (error) {
      console.error('Error loading products:', error);
      toast.error('Erro ao carregar produtos');
    } finally {
      setLoading(false);
    }
  };

  const loadCategories = async () => {
    try {
      const data = await categoriesService.getAll();
      setCategories(data || []);
    } catch (error) {
      console.error('Error loading categories:', error);
    }
  };


  const handleCheckout = () => {
    if (cartItems.length === 0) {
      toast.error("Seu carrinho está vazio");
      return;
    }
    setIsCheckoutOpen(true);
  };

  const handleSubmitOrder = async (
    customerName: string,
    customerPhone: string,
    deliveryAddress: string,
    paymentMethod: string,
    externalPaymentId?: string
  ) => {
    try {
      const orderData = {
        store_id: activeStoreId!, // Add store_id
        customerName,
        customerPhone,
        deliveryAddress,
        paymentMethod,
        items: cartItems.map(({ product, quantity, removedIngredients, extraIngredients }) => ({
          id: `item-${Date.now()}-${product.id}`,
          productId: product.id,
          productName: product.name,
          quantity,
          price: product.price,
          removedIngredients: removedIngredients || [],
          extraIngredients: extraIngredients || [],
        })),
        total: cartItems.reduce((sum, item) => sum + item.product.price * item.quantity, 0) + (storeData?.delivery_fee ?? 0),
        // Vincular pagamento PIX ao pedido
        external_payment_id: externalPaymentId,
        payment_status: externalPaymentId ? 'approved' : 'pending',
      };

      await ordersService.create(orderData);

      clearCart();
      setIsCheckoutOpen(false);

      // Salva a URL da loja atual para voltar depois
      const currentPath = '/store';
      localStorage.setItem('currentStoreUrl', currentPath);

      toast.success("Seu pedido foi enviado!");
      navigate('/order-success', { state: { from: currentPath } });
    } catch (error) {
      console.error('Error creating order:', error);
      toast.error('Erro ao enviar pedido');
    }
  };
  
  const handlePixPaymentComplete = async (paymentId: string, customerName: string, customerPhone: string, deliveryAddress: string) => {
    // Pedido já foi criado no CheckoutForm antes de abrir o PIX
    // Apenas limpar carrinho e navegar para sucesso
    clearCart();
    setIsCheckoutOpen(false);
    
    const currentPath = '/store';
    localStorage.setItem('currentStoreUrl', currentPath);
    
    toast.success("Pagamento confirmado! Seu pedido foi enviado.");
    navigate('/order-success', { state: { from: currentPath } });
  };
  
  // Agrupa produtos por categoria
  const categorizedProducts: Record<string, Product[]> = {};
  products.forEach(product => {
    if (!categorizedProducts[product.category]) categorizedProducts[product.category] = [];
    categorizedProducts[product.category].push(product);
  });

  // Filtra apenas categorias que têm produtos
  const visibleCategories = categories.filter(cat => 
    categorizedProducts[cat.slug]?.length > 0
  );

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white py-4 sticky top-0 z-10 shadow-sm">
        <div className="container mx-auto px-4 flex justify-between items-center">
          <div className="flex items-center gap-2">
            <Utensils className="h-6 w-6 text-[#FF7A30]" />
            {/* 🔹 Nome vem da loja atual */}
            <h1 className="text-xl font-bold">{storeData?.name || ""}</h1>
          </div>
          <div className="flex items-center gap-3">
            <Button
              variant="outline"
              onClick={() => navigate('/admin')}
              className="text-sm"
            >
              Admin
            </Button>
            <Cart
              cartItems={cartItems}
              onRemoveFromCart={removeFromCart}
              onUpdateQuantity={updateQuantity}
              onCheckout={handleCheckout}
            />
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-4">
        <Tabs defaultValue={visibleCategories[0]?.slug || 'burger'}>
          <div className="sticky top-[73px] bg-white z-10 pb-2 mb-4 border-b">
            <TabsList className="w-full justify-start overflow-x-auto py-2">
              {visibleCategories.map(category => {
                const IconComponent = getIconComponent(category.icon || 'Tag');
                return (
                  <TabsTrigger key={category.id} value={category.slug} className="flex items-center px-5">
                    <IconComponent className="h-5 w-5 mr-2" />
                    {category.name}
                    <Badge variant="secondary" className="ml-2">
                      {categorizedProducts[category.slug]?.length || 0}
                    </Badge>
                  </TabsTrigger>
                );
              })}
            </TabsList>
          </div>

          {visibleCategories.map((category, index) => {
            // Mostra o carousel apenas na primeira categoria
            if (index === 0) {
              return (
                <TabsContent key={category.id} value={category.slug} className="py-2">
                  <BackgroundCarousel 
                    images={storeData?.background_urls || []} 
                    logoUrl={storeData?.logo_url || null}
                    logoTop={logoTop}
                    logoLeft={logoLeft}
                  />

                  <ProductList
                    products={categorizedProducts[category.slug] || []}
                  />
                </TabsContent>
              );
            }

            return (
              <TabsContent key={category.id} value={category.slug} className="py-2">
                <ProductList
                  products={categorizedProducts[category.slug] || []}
                />
              </TabsContent>
            );
          })}
        </Tabs>
      </main>

      <CheckoutForm
        cartItems={cartItems}
        isOpen={isCheckoutOpen}
        onClose={() => setIsCheckoutOpen(false)}
        onSubmitOrder={handleSubmitOrder}
        onPixPaymentComplete={handlePixPaymentComplete}
        storeId={activeStoreId}
      />

      <div className="pb-16" />

      <BottomNavigation
        cartItemsCount={cartItems.reduce((sum, item) => sum + item.quantity, 0)}
        onCartClick={() => document.getElementById('cart-trigger')?.click()}
      />
    </div>
  );
};

export default StoreFront;
