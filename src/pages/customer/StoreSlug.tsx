import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, useSearchParams } from 'react-router-dom';
import { Product } from '@/types';
import { productsService, ordersService, categoriesService } from '@/services/supabaseService';
import ProductList from '@/components/customer/ProductList';
import Cart from '@/components/customer/Cart';
import CheckoutForm from '@/components/customer/CheckoutForm';
import BottomNavigation from '@/components/customer/BottomNavigation';
import { toast } from "sonner";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Badge } from '@/components/ui/badge';
import { Utensils, AlertCircle, LogIn } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useCart } from '@/contexts/CartContext';
import BackgroundCarousel from '@/components/customer/BackgroundCarousel';
import { getIconComponent } from '@/utils/categoryIcons';
import { useStore } from '@/contexts/StoreContext';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { useAuth } from '@/contexts/AuthContext';
import { useMercadoPago } from '@/contexts/MercadoPagoContext';

interface Category {
  id: string;
  name: string;
  slug: string;
  display_order: number;
  icon?: string;
}

const StoreSlug: React.FC = () => {
  const { slug } = useParams<{ slug: string }>();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { currentStore, loadStoreBySlug, loading: storeLoading } = useStore();
  const { cartItems, addToCart, removeFromCart, updateQuantity, clearCart } = useCart();
  const { user } = useAuth();
  const { loadConfig } = useMercadoPago();

  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [isCheckoutOpen, setIsCheckoutOpen] = useState(false);
  const [loading, setLoading] = useState(true);
  const [storeNotFound, setStoreNotFound] = useState(false);
  const [activeTab, setActiveTab] = useState<string>('');

  // Carregar loja pelo slug
  useEffect(() => {
    const loadStore = async () => {
      if (!slug) {
        setStoreNotFound(true);
        setLoading(false);
        return;
      }

      const store = await loadStoreBySlug(slug);
      
      // Salvar a loja atual no localStorage para o botão "Início"
      if (store) {
        localStorage.setItem('lastVisitedStore', `/${slug}`);
      }
      
      if (!store) {
        setStoreNotFound(true);
      }
      setLoading(false);
    };

    loadStore();
  }, [slug]);

  // Carregar produtos, categorias e credenciais do Mercado Pago quando a loja estiver carregada
  useEffect(() => {
    if (currentStore?.id) {
      loadProducts();
      loadCategories();
      // Carregar credenciais do Mercado Pago para esta loja
      loadMercadoPagoCredentials(currentStore.id);
    }
  }, [currentStore?.id]);

  // Carregar credenciais do Mercado Pago
  const loadMercadoPagoCredentials = async (storeId: string) => {
    try {
      console.log('🔑 Carregando credenciais do Mercado Pago para loja:', storeId);
      await loadConfig(storeId);
    } catch (error) {
      console.error('❌ Erro ao carregar credenciais do Mercado Pago:', error);
    }
  };

  // Definir categoria inicial baseada na URL ou primeira categoria disponível
  useEffect(() => {
    if (categories.length > 0 && !activeTab) {
      // Verificar se há categoria na URL (?category=hamburguer)
      const categoryParam = searchParams.get('category');
      
      if (categoryParam) {
        // Procurar categoria pelo slug ou nome
        const matchedCategory = categories.find(cat => 
          cat.slug === categoryParam || 
          cat.name.toLowerCase() === categoryParam.toLowerCase()
        );
        
        if (matchedCategory) {
          const slug = matchedCategory.slug || matchedCategory.name.toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .replace(/[^a-z0-9]+/g, '-')
            .replace(/^-+|-+$/g, '');
          setActiveTab(slug);
          console.log('📍 Categoria inicial definida pela URL:', slug);
          return;
        }
      }
      
      // Se não houver categoria na URL, usar a primeira
      const firstCategorySlug = categories[0].slug || categories[0].name.toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '');
      setActiveTab(firstCategorySlug);
      console.log('📍 Categoria inicial definida (primeira):', firstCategorySlug);
    }
  }, [categories, searchParams]);

  const loadProducts = async () => {
    if (!currentStore?.id) {
      console.log('❌ Nenhuma loja carregada para buscar produtos');
      return;
    }

    try {
      console.log('🔍 Buscando produtos para loja:', currentStore.id);
      const data = await productsService.getAllByStore(currentStore.id);
      console.log('✅ Produtos carregados:', data?.length || 0);
      
      // Debug: Ver TODOS os campos de cada produto
      data?.forEach((p: any) => {
        console.log('🔍 Produto:', p.name || p.nome, {
          id: p.id,
          category_id: p.category_id,
          categoria_id: p.categoria_id,
          name: p.name,
          nome: p.nome
        });
      });
      
      setProducts(data || []);
    } catch (error) {
      console.error('❌ Error loading products:', error);
      toast.error('Erro ao carregar produtos');
    }
  };

  const loadCategories = async () => {
    if (!currentStore?.id) {
      console.log('❌ Nenhuma loja carregada para buscar categorias');
      return;
    }

    try {
      console.log('🔍 Buscando categorias para loja:', currentStore.id);
      const data = await categoriesService.getAllByStore(currentStore.id);
      console.log('✅ Categorias carregadas:', data?.length || 0, data);
      setCategories(data || []);
    } catch (error) {
      console.error('❌ Error loading categories:', error);
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
    if (!currentStore?.id) return;

    try {
      const orderData = {
        store_id: currentStore.id,
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
        total: cartItems.reduce((sum, item) => sum + item.product.price * item.quantity, 0) + (currentStore.delivery_fee || 0),
        // Vincular pagamento PIX ao pedido
        external_payment_id: externalPaymentId,
        payment_status: externalPaymentId ? 'approved' : 'pending',
      };

      await ordersService.create(orderData);

      clearCart();
      setIsCheckoutOpen(false);

      // Salva a URL da loja atual para voltar depois
      const currentPath = `/${slug}`;
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
    
    const currentPath = `/${slug}`;
    localStorage.setItem('currentStoreUrl', currentPath);
    
    toast.success("Pagamento confirmado! Seu pedido foi enviado.");
    navigate('/order-success', { state: { from: currentPath } });
  };
  
  // Agrupa produtos por categoria
  const categorizedProducts: Record<string, Product[]> = {};
  products.forEach(product => {
    // Usar category_id (inglês) do banco, com fallback para categoria_id (português)
    const categoriaId = product.category_id || (product as any).categoria_id;
    
    // Encontrar a categoria pelo categoria_id
    const category = categories.find(cat => cat.id === categoriaId);
    
    // Gerar slug se não existir (normalizar nome para slug)
    let categorySlug = 'sem-categoria';
    if (category) {
      categorySlug = category.slug || category.name.toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '') // Remove acentos
        .replace(/[^a-z0-9]+/g, '-')      // Substitui espaços e caracteres especiais por -
        .replace(/^-+|-+$/g, '');         // Remove - do início e fim
    }
    
    console.log('📦 Produto:', product.name, '| categoria_id:', categoriaId, '| categoria encontrada:', category?.name, '| slug gerado:', categorySlug);
    
    if (!categorizedProducts[categorySlug]) categorizedProducts[categorySlug] = [];
    categorizedProducts[categorySlug].push(product);
  });

  console.log('📊 Produtos agrupados:', categorizedProducts);
  console.log('📋 Total de categorias:', categories.length);
  console.log('📋 Total de produtos:', products.length);

  // Filtra apenas categorias que têm produtos (usando slug gerado)
  const visibleCategories = categories.filter(cat => {
    const slug = cat.slug || cat.name.toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
    return categorizedProducts[slug]?.length > 0;
  });
  
  console.log('👁️ Categorias visíveis:', visibleCategories.length, visibleCategories);

  // Loading state
  if (loading || storeLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  // Store not found
  if (storeNotFound || !currentStore) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <div className="max-w-md w-full">
          <Alert variant="destructive">
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>
              <strong>Loja não encontrada</strong>
              <p className="mt-2">
                A loja "{slug}" não existe ou está inativa.
              </p>
            </AlertDescription>
          </Alert>
          <Button 
            onClick={() => navigate('/')} 
            className="w-full mt-4"
          >
            Voltar para página inicial
          </Button>
        </div>
      </div>
    );
  }

  // Store closed
  if (!currentStore.is_open) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <div className="max-w-md w-full">
          <Alert>
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>
              <strong>{currentStore.name}</strong>
              <p className="mt-2">
                Desculpe, estamos fechados no momento. Volte mais tarde!
              </p>
            </AlertDescription>
          </Alert>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white py-4 sticky top-0 z-10 shadow-sm">
        <div className="container mx-auto px-4 flex justify-between items-center">
          <div className="flex items-center gap-2">
            <Utensils className="h-6 w-6 text-[#FF7A30]" />
            <h1 className="text-xl font-bold">{currentStore.name}</h1>
          </div>
          <div className="flex items-center gap-3">
            {!user && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => navigate('/auth')}
                className="flex items-center gap-2"
              >
                <LogIn className="h-4 w-4" />
                <span className="hidden sm:inline">Entrar</span>
              </Button>
            )}
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
        <Tabs value={activeTab} onValueChange={setActiveTab}>
          <div className="sticky top-[73px] bg-white z-10 pb-2 mb-4 border-b">
            <TabsList className="w-full justify-start overflow-x-auto py-2">
              {visibleCategories.map(category => {
                const IconComponent = getIconComponent(category.icon || 'Tag');
                const slug = category.slug || category.name.toLowerCase()
                  .normalize('NFD')
                  .replace(/[\u0300-\u036f]/g, '')
                  .replace(/[^a-z0-9]+/g, '-')
                  .replace(/^-+|-+$/g, '');
                return (
                  <TabsTrigger key={category.id} value={slug} className="flex items-center px-5">
                    <IconComponent className="h-5 w-5 mr-2" />
                    {category.name}
                    <Badge variant="secondary" className="ml-2">
                      {categorizedProducts[slug]?.length || 0}
                    </Badge>
                  </TabsTrigger>
                );
              })}
            </TabsList>
          </div>

          {/* Logo e fundo aparecem em todas as categorias */}
          <BackgroundCarousel 
            images={currentStore.background_urls || []} 
            logoUrl={currentStore.logo_url}
            logoTop={105}
            logoLeft={20}
          />

          {visibleCategories.map((category) => {
            const slug = category.slug || category.name.toLowerCase()
              .normalize('NFD')
              .replace(/[\u0300-\u036f]/g, '')
              .replace(/[^a-z0-9]+/g, '-')
              .replace(/^-+|-+$/g, '');
            
            return (
              <TabsContent key={category.id} value={slug} className="py-2">
                <ProductList
                  products={categorizedProducts[slug] || []}
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
        storeId={currentStore?.id}
        storeSlug={slug}
      />

      <div className="pb-16" />

      <BottomNavigation
        cartItemsCount={cartItems.reduce((sum, item) => sum + item.quantity, 0)}
        onCartClick={() => document.getElementById('cart-trigger')?.click()}
      />
    </div>
  );
};

export default StoreSlug;
