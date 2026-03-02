import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { Plus, X } from 'lucide-react';
import { Ingredient } from '@/types';

interface IngredientManagerProps {
  ingredients: Ingredient[];
  onIngredientsChange: (ingredients: Ingredient[]) => void;
}

const IngredientManager = ({ ingredients, onIngredientsChange }: IngredientManagerProps) => {
  const [newIngredientName, setNewIngredientName] = useState('');
  const [newIngredientPrice, setNewIngredientPrice] = useState('');
  const [isExtra, setIsExtra] = useState(false);

  const addIngredient = () => {
    if (newIngredientName.trim()) {
      const newIngredient: Ingredient = {
        id: `temp-${Date.now()}`,
        productId: '',
        name: newIngredientName.trim(),
        isExtra,
        price: isExtra ? parseFloat(newIngredientPrice) || 0 : undefined
      };
      onIngredientsChange([...ingredients, newIngredient]);
      setNewIngredientName('');
      setNewIngredientPrice('');
      setIsExtra(false);
    }
  };

  const removeIngredient = (id: string) => {
    onIngredientsChange(ingredients.filter(ingredient => ingredient.id !== id));
  };

  const updateIngredient = (id: string, updates: Partial<Ingredient>) => {
    onIngredientsChange(
      ingredients.map(ingredient => 
        ingredient.id === id ? { ...ingredient, ...updates } : ingredient
      )
    );
  };

  return (
    <div className="space-y-4">
      <Label>Ingredientes</Label>
      
      {/* Add new ingredient */}
      <Card className="p-4">
        <div className="space-y-3">
          <div className="flex items-center space-x-2">
            <Switch
              id="ingredient-extra"
              checked={isExtra}
              onCheckedChange={setIsExtra}
            />
            <Label htmlFor="ingredient-extra">Ingrediente extra (pago)</Label>
          </div>
          
          <div className="flex gap-2">
            <Input
              placeholder="Nome do ingrediente"
              value={newIngredientName}
              onChange={(e) => setNewIngredientName(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && addIngredient()}
              className="flex-1"
            />
            {isExtra && (
              <Input
                type="number"
                placeholder="Preço (R$)"
                value={newIngredientPrice}
                onChange={(e) => setNewIngredientPrice(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && addIngredient()}
                className="w-32"
                step="0.01"
                min="0"
              />
            )}
            <Button 
              type="button" 
              onClick={addIngredient}
              size="sm"
              className="whitespace-nowrap"
            >
              <Plus className="h-4 w-4 mr-1" />
              Adicionar
            </Button>
          </div>
        </div>
      </Card>

      {/* Ingredients list */}
      <div className="space-y-2 max-h-64 overflow-y-auto">
        {ingredients.map((ingredient) => (
          <Card key={ingredient.id} className="relative">
            <CardContent className="p-3">
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <Input
                    value={ingredient.name}
                    onChange={(e) => updateIngredient(ingredient.id, { name: e.target.value })}
                    placeholder="Nome do ingrediente"
                    className="flex-1"
                  />
                  {ingredient.isExtra && (
                    <Input
                      type="number"
                      value={ingredient.price || 0}
                      onChange={(e) => updateIngredient(ingredient.id, { price: parseFloat(e.target.value) || 0 })}
                      placeholder="Preço"
                      className="w-24"
                      step="0.01"
                      min="0"
                    />
                  )}
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={() => removeIngredient(ingredient.id)}
                    className="text-red-600 hover:text-red-700 hover:bg-red-50"
                  >
                    <X className="h-4 w-4" />
                  </Button>
                </div>
                
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <Switch
                      checked={ingredient.isExtra || false}
                      onCheckedChange={(checked) => updateIngredient(ingredient.id, { 
                        isExtra: checked,
                        price: checked ? (ingredient.price || 0) : undefined 
                      })}
                    />
                    <Label className="text-sm">
                      {ingredient.isExtra ? 'Extra pago' : 'Incluído'}
                    </Label>
                  </div>
                  {ingredient.isExtra && ingredient.price && (
                    <span className="text-sm font-medium text-primary">
                      + R$ {ingredient.price.toFixed(2)}
                    </span>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {ingredients.length === 0 && (
        <p className="text-sm text-muted-foreground text-center py-4">
          Nenhum ingrediente adicionado ainda
        </p>
      )}
    </div>
  );
};

export default IngredientManager;