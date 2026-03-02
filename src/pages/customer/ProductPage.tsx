import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Product, Ingredient } from '@/types';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { ArrowLeft, Plus, Minus, ShoppingCart, Check } from 'lucide-react';
import * as supabaseService from '@/services/supabaseService';
import { useCart } from '@/contexts/CartContext';
const ProductPage = () => {
  const {
    id
  } = useParams<{
    id: string;
  }>();
  const navigate = useNavigate();
  const {
    addToCart
  } = useCart();
  const [product, setProduct] = useState<Product | null>(null);
  const [loading, setLoading] = useState(true);
  const [removedIngredients, setRemovedIngredients] = useState<string[]>([]);
  const [extraIngredients, setExtraIngredients] = useState<{
    name: string;
    price: number;
  }[]>([]);
  useEffect(() => {
    if (id) {
      loadProduct(id);
    }
  }, [id]);
  const loadProduct = async (productId: string) => {
    try {
      setLoading(true);
      const product = await supabaseService.productsService.getById(productId);
      setProduct(product);
    } catch (error) {
      console.error('Error loading product:', error);
    } finally {
      setLoading(false);
    }
  };
  const handleRemoveIngredient = (ingredientName: string) => {
    setRemovedIngredients(prev => [...prev, ingredientName]);
  };
  const handleAddIngredient = (ingredientName: string) => {
    setRemovedIngredients(prev => prev.filter(name => name !== ingredientName));
  };
  const handleAddExtraIngredient = (name: string, price: number) => {
    setExtraIngredients(prev => [...prev, {
      name,
      price
    }]);
  };
  const handleRemoveExtraIngredient = (name: string) => {
    setExtraIngredients(prev => prev.filter(extra => extra.name !== name));
  };
  const getTotalExtraPrice = () => {
    return extraIngredients.reduce((total, extra) => total + extra.price, 0);
  };
  const getFinalPrice = () => {
    return product ? product.price + getTotalExtraPrice() : 0;
  };
  const handleAddToCart = () => {
    if (product) {
      addToCart(product, removedIngredients, extraIngredients);
      navigate(-1);
    }
  };
  if (loading) {
    return <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center">
          <div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-muted-foreground">Carregando produto...</p>
        </div>
      </div>;
  }
  if (!product) {
    return <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="text-center">
          <p className="text-lg text-muted-foreground mb-4">Produto não encontrado</p>
          <Button onClick={() => navigate(-1)} variant="outline">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Voltar
          </Button>
        </div>
      </div>;
  }
  const includedIngredients = product.ingredients?.filter(ing => !ing.isExtra) ?? [];
  const extraIngredientsAvailable = product.ingredients?.filter(ing => ing.isExtra) ?? [];
  return <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="sticky top-0 z-50 bg-card/80 backdrop-blur-sm border-b border-border">
        <div className="flex items-center justify-between p-4">
          <Button variant="ghost" size="icon" onClick={() => navigate(-1)} className="h-10 w-10">
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <h1 className="font-semibold text-lg truncate flex-1 text-center mx-4">
            {product.name}
          </h1>
          <div className="w-10" /> {/* Spacer for centering */}
        </div>
      </div>

      {/* Product Image */}
      <div className="relative">
        <div className="aspect-[4/3] overflow-hidden">
          <img src={product.image} alt={product.name} className="w-full h-full object-cover" onError={e => {
          e.currentTarget.src = '/placeholder.svg';
        }} />
        </div>
        
        {/* Gradient overlay for better text readability */}
        <div className="absolute inset-0 bg-gradient-to-t from-black/20 via-transparent to-transparent" />
        
        {/* Price badge */}
        <div className="absolute top-4 right-4">
          <Badge className="bg-primary text-primary-foreground text-lg font-bold px-3 py-2 shadow-lg">
            R$ {getFinalPrice().toFixed(2)}
          </Badge>
        </div>
      </div>

      {/* Content */}
      <div className="px-4 py-6 space-y-6">
        {/* Product Info */}
        <div className="text-center space-y-2">
          
          {product.description && <p className="text-muted-foreground text-sm leading-relaxed">
              {product.description}
            </p>}
          <div className="text-lg font-semibold text-primary">
            Preço base: R$ {product.price.toFixed(2)}
          </div>
        </div>

        {/* Remove Ingredients Section */}
        {includedIngredients.length > 0 && <Card className="border-2 border-red-100 bg-red-50/30">
            <CardContent className="p-4 space-y-4">
              <div className="flex items-center gap-2 mb-3">
                <Minus className="h-5 w-5 text-red-600" />
                <h3 className="font-semibold text-red-700">Remover Ingredientes</h3>
              </div>
              <p className="text-sm text-muted-foreground mb-4">
                Toque para remover ingredientes (sem custo adicional)
              </p>
              
              <div className="space-y-3">
                {includedIngredients.map(ingredient => {
              const isRemoved = removedIngredients.includes(ingredient.name);
              return <div key={ingredient.id} className={`flex items-center justify-between p-3 rounded-lg border-2 transition-all cursor-pointer active:scale-98 ${isRemoved ? 'bg-red-100 border-red-200 opacity-70' : 'bg-green-50 border-green-200 active:border-green-300'}`} onClick={() => isRemoved ? handleAddIngredient(ingredient.name) : handleRemoveIngredient(ingredient.name)}>
                      <div className="flex items-center gap-3">
                        <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center transition-all ${isRemoved ? 'bg-red-100 border-red-300' : 'bg-green-500 border-green-500'}`}>
                          {!isRemoved && <Check className="h-4 w-4 text-white" />}
                        </div>
                        <span className={`font-medium transition-all ${isRemoved ? 'line-through text-red-600' : 'text-green-700'}`}>
                          {ingredient.name}
                        </span>
                      </div>
                      
                      <div className="text-xs text-muted-foreground font-medium">
                        {isRemoved ? 'Removido' : 'Incluído'}
                      </div>
                    </div>;
            })}
              </div>
            </CardContent>
          </Card>}

        {/* Extra Ingredients Section */}
        {extraIngredientsAvailable.length > 0 && <Card className="border-2 border-primary/20 bg-primary/5">
            <CardContent className="p-4 space-y-4">
              <div className="flex items-center gap-2 mb-3">
                <Plus className="h-5 w-5 text-primary" />
                <h3 className="font-semibold text-primary">Ingredientes Extras</h3>
              </div>
              <p className="text-sm text-muted-foreground mb-4">
                Adicione ingredientes extras ao seu pedido
              </p>
              
              <div className="space-y-3">
                {extraIngredientsAvailable.map(ingredient => {
              const isSelected = extraIngredients.some(extra => extra.name === ingredient.name);
              return <div key={ingredient.id} className="flex items-center justify-between p-4 rounded-lg border-2 bg-card transition-all">
                      <div className="flex items-center gap-3 flex-1">
                        <div className="flex-1">
                          <div className="font-medium text-foreground">{ingredient.name}</div>
                          <div className="text-sm font-bold text-primary">
                            + R$ {ingredient.price?.toFixed(2)}
                          </div>
                        </div>
                      </div>
                      
                      <Button size="sm" variant={isSelected ? "default" : "outline"} onClick={() => isSelected ? handleRemoveExtraIngredient(ingredient.name) : handleAddExtraIngredient(ingredient.name, ingredient.price || 0)} className="min-w-[80px]">
                        {isSelected ? <>
                            <Check className="w-4 h-4 mr-1" />
                            Adicionado
                          </> : <>
                            <Plus className="w-4 h-4 mr-1" />
                            Adicionar
                          </>}
                      </Button>
                    </div>;
            })}
              </div>
            </CardContent>
          </Card>}

        {/* Summary of modifications */}
        {(removedIngredients.length > 0 || extraIngredients.length > 0) && <Card className="border-2 border-amber-200 bg-amber-50">
            <CardContent className="p-4 space-y-3">
              <h4 className="font-semibold text-amber-800">Resumo da Personalização</h4>
              
              {removedIngredients.length > 0 && <div>
                  <p className="text-sm text-red-600 font-medium mb-2">Ingredientes removidos:</p>
                  <div className="flex flex-wrap gap-2">
                    {removedIngredients.map(ingredientName => <Badge key={ingredientName} variant="destructive" className="text-xs">
                        {ingredientName}
                      </Badge>)}
                  </div>
                </div>}
              
              {extraIngredients.length > 0 && <div>
                  <p className="text-sm text-primary font-medium mb-2">Ingredientes extras:</p>
                  <div className="space-y-1">
                    {extraIngredients.map((extra, index) => <div key={index} className="flex justify-between text-sm">
                        <span>{extra.name}</span>
                        <span className="font-semibold text-primary">+ R$ {extra.price.toFixed(2)}</span>
                      </div>)}
                  </div>
                </div>}
            </CardContent>
          </Card>}

        {/* Bottom spacing for fixed button */}
        <div className="h-20" />
      </div>

      {/* Fixed bottom button */}
      <div className="fixed bottom-0 left-0 right-0 p-4 bg-card/80 backdrop-blur-sm border-t border-border">
        <Button className="w-full h-14 text-lg font-semibold bg-primary hover:bg-primary/90 text-primary-foreground shadow-lg" onClick={handleAddToCart}>
          <ShoppingCart className="w-5 h-5 mr-2" />
          Adicionar ao Carrinho
          {getTotalExtraPrice() > 0 && <span className="ml-2 bg-white/20 px-2 py-1 rounded text-sm">
              R$ {getFinalPrice().toFixed(2)}
            </span>}
        </Button>
      </div>
    </div>;
};
export default ProductPage;