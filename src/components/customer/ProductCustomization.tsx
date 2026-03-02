import React, { useState, useEffect } from 'react';
import { Product, Ingredient } from '@/types';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Separator } from '@/components/ui/separator';
import { X, ShoppingCart, Minus, Plus, Check } from 'lucide-react';

interface ProductCustomizationProps {
  product: Product | null;
  isOpen: boolean;
  onClose: () => void;
  onAddToCart: (product: Product, removedIngredients: string[], extraIngredients: {name: string, price: number}[]) => void;
}

const ProductCustomization = ({
  product,
  isOpen,
  onClose,
  onAddToCart,
}: ProductCustomizationProps) => {
  const [removedIngredients, setRemovedIngredients] = useState<string[]>([]);
  const [extraIngredients, setExtraIngredients] = useState<{name: string, price: number}[]>([]);

  // Se não tiver ingredientes, adiciona direto ao carrinho
  useEffect(() => {
    if (product && isOpen && (!product.ingredients || product.ingredients.length === 0)) {
      onAddToCart(product, [], []);
      onClose();
    }
  }, [product, isOpen, onAddToCart, onClose]);

  const handleRemoveIngredient = (ingredientName: string) => {
    setRemovedIngredients(prev => [...prev, ingredientName]);
  };

  const handleAddIngredient = (ingredientName: string) => {
    setRemovedIngredients(prev => prev.filter(name => name !== ingredientName));
  };

  const handleAddExtraIngredient = (name: string, price: number) => {
    setExtraIngredients(prev => [...prev, { name, price }]);
  };

  const handleRemoveExtraIngredient = (name: string) => {
    setExtraIngredients(prev => prev.filter(extra => extra.name !== name));
  };

  const handleAddToCart = () => {
    if (product) {
      onAddToCart(product, removedIngredients, extraIngredients);
      setRemovedIngredients([]);
      setExtraIngredients([]);
      onClose();
    }
  };

  const handleClose = () => {
    setRemovedIngredients([]);
    setExtraIngredients([]);
    onClose();
  };

  const getTotalExtraPrice = () => {
    return extraIngredients.reduce((total, extra) => total + extra.price, 0);
  };

  if (!product) return null;

  const includedIngredients = product.ingredients?.filter(ing => !ing.isExtra) ?? [];
  const extraIngredientsAvailable = product.ingredients?.filter(ing => ing.isExtra) ?? [];
  
  const hasAnyIngredients = includedIngredients.length > 0 || extraIngredientsAvailable.length > 0;
  
  if (!hasAnyIngredients) return null;

  return (
    <Dialog open={isOpen} onOpenChange={handleClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader className="pb-4">
          <DialogTitle className="text-2xl font-bold text-center">{product.name}</DialogTitle>
          <div className="text-center">
            <span className="text-lg font-semibold text-primary">
              R$ {product.price.toFixed(2)}
            </span>
          </div>
        </DialogHeader>

        <div className="space-y-6">
          {/* Product Image */}
          <div className="h-40 overflow-hidden rounded-xl border-2 border-muted">
            <img
              src={product.image}
              alt={product.name}
              className="w-full h-full object-cover"
            />
          </div>

          <div className="grid gap-6 md:grid-cols-2">
            {/* Remover Ingredientes */}
            {includedIngredients.length > 0 && (
              <Card className="border-2 border-red-100">
                <CardHeader className="pb-3">
                  <CardTitle className="flex items-center gap-2 text-red-700">
                    <Minus className="h-5 w-5" />
                    Remover Ingredientes
                  </CardTitle>
                  <p className="text-sm text-muted-foreground">
                    Desmarque os ingredientes que não deseja (sem custo)
                  </p>
                </CardHeader>
                <CardContent className="space-y-3">
                  {includedIngredients.map((ingredient) => {
                    const isRemoved = removedIngredients.includes(ingredient.name);

                    return (
                      <div
                        key={ingredient.id}
                        className={`group flex items-center justify-between p-3 rounded-lg border-2 transition-all cursor-pointer hover:shadow-md ${
                          isRemoved
                            ? 'bg-red-50 border-red-200 opacity-70'
                            : 'bg-green-50 border-green-200 hover:border-green-300'
                        }`}
                        onClick={() => 
                          isRemoved 
                            ? handleAddIngredient(ingredient.name)
                            : handleRemoveIngredient(ingredient.name)
                        }
                      >
                        <div className="flex items-center gap-3">
                          <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center transition-all ${
                            isRemoved 
                              ? 'bg-red-100 border-red-300' 
                              : 'bg-green-500 border-green-500'
                          }`}>
                            {!isRemoved && <Check className="h-3 w-3 text-white" />}
                          </div>
                          <span className={`font-medium transition-all ${
                            isRemoved ? 'line-through text-red-600' : 'text-green-700'
                          }`}>
                            {ingredient.name}
                          </span>
                        </div>
                        
                        <div className="text-xs text-muted-foreground">
                          {isRemoved ? 'Removido' : 'Incluído'}
                        </div>
                      </div>
                    );
                  })}
                </CardContent>
              </Card>
            )}

            {/* Adicionar Ingredientes Extras */}
            {extraIngredientsAvailable.length > 0 && (
              <Card className="border-2 border-primary/20">
                <CardHeader className="pb-3">
                  <CardTitle className="flex items-center gap-2 text-primary">
                    <Plus className="h-5 w-5" />
                    Ingredientes Extras
                  </CardTitle>
                  <p className="text-sm text-muted-foreground">
                    Adicione ingredientes extras ao seu pedido
                  </p>
                </CardHeader>
                <CardContent className="space-y-3">
                  {extraIngredientsAvailable.map((ingredient) => {
                    const isSelected = extraIngredients.some(extra => extra.name === ingredient.name);

                    return (
                      <div
                        key={ingredient.id}
                        className={`group flex items-center justify-between p-3 rounded-lg border-2 transition-all cursor-pointer hover:shadow-md ${
                          isSelected
                            ? 'bg-primary/10 border-primary/30 hover:border-primary/40'
                            : 'bg-muted/30 border-muted hover:border-primary/20'
                        }`}
                        onClick={() => 
                          isSelected 
                            ? handleRemoveExtraIngredient(ingredient.name)
                            : handleAddExtraIngredient(ingredient.name, ingredient.price || 0)
                        }
                      >
                        <div className="flex items-center gap-3 flex-1">
                          <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center transition-all ${
                            isSelected 
                              ? 'bg-primary border-primary' 
                              : 'bg-white border-muted-foreground/30'
                          }`}>
                            {isSelected && <Check className="h-3 w-3 text-white" />}
                          </div>
                          <div className="flex-1">
                            <span className="font-medium">{ingredient.name}</span>
                            <div className="text-sm font-bold text-primary">
                              + R$ {ingredient.price?.toFixed(2)}
                            </div>
                          </div>
                        </div>
                        
                        <div className="text-xs text-muted-foreground">
                          {isSelected ? 'Adicionado' : 'Adicionar'}
                        </div>
                      </div>
                    );
                  })}
                </CardContent>
              </Card>
            )}
          </div>

          {/* Resumo das modificações - Apenas se houver alguma modificação */}
          {(removedIngredients.length > 0 || extraIngredients.length > 0) && (
            <Card className="border-2 border-amber-200 bg-amber-50">
              <CardHeader className="pb-3">
                <CardTitle className="text-amber-800 text-lg">Resumo da Personalização</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {removedIngredients.length > 0 && (
                  <div>
                    <h4 className="font-medium text-red-700 mb-2 flex items-center gap-2">
                      <Minus className="h-4 w-4" />
                      Ingredientes removidos:
                    </h4>
                    <div className="flex flex-wrap gap-2">
                      {removedIngredients.map((ingredientName) => (
                        <Badge key={ingredientName} variant="destructive" className="text-xs">
                          {ingredientName}
                        </Badge>
                      ))}
                    </div>
                  </div>
                )}
                
                {extraIngredients.length > 0 && (
                  <div>
                    <h4 className="font-medium text-primary mb-2 flex items-center gap-2">
                      <Plus className="h-4 w-4" />
                      Ingredientes extras:
                    </h4>
                    <div className="space-y-2">
                      {extraIngredients.map((extra, index) => (
                        <div key={index} className="flex justify-between items-center bg-white/60 rounded px-3 py-2">
                          <span className="text-sm">{extra.name}</span>
                          <span className="font-semibold text-primary">+ R$ {extra.price.toFixed(2)}</span>
                        </div>
                      ))}
                    </div>
                    
                    <Separator className="my-3" />
                    
                    <div className="flex justify-between items-center bg-primary/10 rounded-lg px-4 py-3">
                      <span className="font-semibold">Valor dos extras:</span>
                      <span className="text-lg font-bold text-primary">+ R$ {getTotalExtraPrice().toFixed(2)}</span>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* Botões de ação */}
          <div className="flex gap-3 pt-4 border-t">
            <Button 
              variant="outline" 
              className="flex-1 h-12" 
              onClick={handleClose}
            >
              Cancelar
            </Button>
            <Button
              className="flex-1 h-12 bg-primary hover:bg-primary/90 text-white font-semibold text-lg"
              onClick={handleAddToCart}
            >
              <ShoppingCart className="mr-2 h-5 w-5" />
              {getTotalExtraPrice() > 0 ? (
                <>
                  Adicionar 
                  <span className="ml-2 bg-white/20 px-2 py-1 rounded text-sm">
                    + R$ {getTotalExtraPrice().toFixed(2)}
                  </span>
                </>
              ) : (
                'Adicionar ao Carrinho'
              )}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default ProductCustomization;
