
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Product } from '@/types';
import { Card, CardContent } from '@/components/ui/card';
import { ShoppingCart, Plus, Minus } from 'lucide-react';
import { Button } from '@/components/ui/button';
import ProductCustomization from './ProductCustomization';
import { useCart } from '@/contexts/CartContext';

interface ProductListProps {
  products: Product[];
}

const ProductList = ({ products }: ProductListProps) => {
  const navigate = useNavigate();
  const { cartItems, addToCart, removeFromCart, updateQuantity } = useCart();
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [isCustomizationOpen, setIsCustomizationOpen] = useState(false);
  
  const getCartQuantity = (productId: string) => {
    const item = cartItems.find(item => item.product.id === productId);
    return item ? item.quantity : 0;
  };

  const handleAddClick = (product: Product) => {
    // If product has ingredients, navigate to product page
    const hasIngredients = product.ingredients && product.ingredients.length > 0;
    if (hasIngredients) {
      navigate(`/product/${product.id}`);
    } else {
      // Add directly to cart if no ingredients
      addToCart(product, [], []);
    }
  };

  const handleCustomizationAddToCart = (product: Product, removedIngredients: string[], extraIngredients: {name: string, price: number}[]) => {
    addToCart(product, removedIngredients, extraIngredients);
  };

  const handleCardClick = (product: Product) => {
    navigate(`/product/${product.id}`);
  };
  
  return (
    <>
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
        {products.filter(p => p.available).map((product) => {
          const quantity = getCartQuantity(product.id);
          
          return (
            <Card key={product.id} className="overflow-hidden border border-gray-200 rounded-lg hover:shadow-lg transition-shadow cursor-pointer" onClick={() => handleCardClick(product)}>
              <div className="h-40 overflow-hidden">
                <img 
                  src={product.image_url || product.image || 'https://via.placeholder.com/400x300?text=Sem+Imagem'} 
                  alt={product.name} 
                  className="w-full h-full object-cover"
                />
              </div>
              <CardContent className="p-3 flex flex-col items-center text-center">
                <h3 className="font-semibold text-base mb-2 line-clamp-2 w-full">{product.name}</h3>
                <p className="text-[#FF7A30] font-bold text-xl mb-3">R$ {product.price.toFixed(2).replace('.', ',')}</p>
                
                {quantity === 0 ? (
                  <Button 
                    className="w-full bg-[#FF7A30] hover:bg-[#E66A20] text-white"
                    onClick={(e) => {
                      e.stopPropagation();
                      handleAddClick(product);
                    }}
                  >
                    <ShoppingCart className="mr-2 h-4 w-4" />
                    Adicionar
                  </Button>
                ) : (
                  <div className="flex items-center justify-between bg-muted rounded-md p-1" onClick={(e) => e.stopPropagation()}>
                    <Button 
                      size="icon" 
                      variant="ghost" 
                      className="h-8 w-8"
                      onClick={(e) => {
                        e.stopPropagation();
                        if (quantity === 1) {
                          removeFromCart(product.id);
                        } else {
                          updateQuantity(product.id, quantity - 1);
                        }
                      }}
                    >
                      <Minus className="h-4 w-4" />
                    </Button>
                    <span className="font-medium">{quantity}</span>
                    <Button 
                      size="icon" 
                      variant="ghost" 
                      className="h-8 w-8"
                      onClick={(e) => {
                        e.stopPropagation();
                        updateQuantity(product.id, quantity + 1);
                      }}
                    >
                      <Plus className="h-4 w-4" />
                    </Button>
                  </div>
                )}
              </CardContent>
            </Card>
          );
        })}
      </div>
      
      <ProductCustomization
        product={selectedProduct}
        isOpen={isCustomizationOpen}
        onClose={() => setIsCustomizationOpen(false)}
        onAddToCart={handleCustomizationAddToCart}
      />
    </>
  );
};

export default ProductList;
