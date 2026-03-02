
import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Edit, Trash2, ChefHat } from 'lucide-react';
import { Product } from '@/types';
import { Button } from '@/components/ui/button';
import { Category } from '@/services/supabaseService';

interface ProductCardProps {
  product: Product;
  categories?: Category[];
  onEdit: (product: Product) => void;
  onDelete: (id: string) => void;
}

const ProductCard = ({ product, categories, onEdit, onDelete }: ProductCardProps) => {
  // Buscar nome da categoria pelo category_id
  const category = categories?.find(cat => cat.id === product.category_id);
  const categoryName = category?.name || product.category || 'Outros';
  
  return (
    <Card className="product-card group overflow-hidden hover:shadow-2xl transition-all duration-300 border-2 hover:border-primary/20">
      <div className="relative h-44 sm:h-52 overflow-hidden bg-gradient-to-br from-muted/30 to-muted/10">
        <img 
          src={product.image_url || product.image || 'https://via.placeholder.com/400x300?text=Sem+Imagem'} 
          alt={product.name} 
          className="w-full h-full object-cover transition-all duration-500 group-hover:scale-110 group-hover:brightness-110"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
        
        {!product.available && (
          <div className="absolute inset-0 bg-black/80 flex items-center justify-center backdrop-blur-md">
            <div className="text-center space-y-2">
              <Badge variant="destructive" className="text-base px-5 py-2 font-bold shadow-lg">
                Indisponível
              </Badge>
              <p className="text-white/80 text-xs">Produto temporariamente fora de estoque</p>
            </div>
          </div>
        )}
        
        <div className="absolute top-3 left-3">
          <Badge className="product-category-badge capitalize font-bold text-xs sm:text-sm px-3 py-1.5 shadow-lg backdrop-blur-sm bg-orange-500 hover:bg-orange-600 border-0 transition-all duration-300 hover:scale-105">
            {categoryName}
          </Badge>
        </div>
        
        <div className="absolute top-3 right-3">
          <div className="product-price bg-green-500 text-white backdrop-blur-sm px-3 py-2 sm:px-4 sm:py-2.5 rounded-full shadow-xl text-sm sm:text-base font-bold border-2 border-white/20 transition-all duration-300 hover:scale-110 hover:bg-green-600">
            R$ {product.price.toFixed(2).replace('.', ',')}
          </div>
        </div>
        
        {/* Badge de destaque se disponível */}
        {product.available && (
          <div className="absolute bottom-3 left-3 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
            <Badge className="bg-white/90 text-green-600 font-semibold text-xs px-2 py-1 shadow-md">
              ✓ Disponível
            </Badge>
          </div>
        )}
      </div>
      
      <CardContent className="p-3 sm:p-5 space-y-3 sm:space-y-4">
        <div className="space-y-1 sm:space-y-2">
          <h3 className="font-bold text-base sm:text-xl text-foreground leading-tight line-clamp-2">
            {product.name}
          </h3>
        </div>

        {product.ingredients && product.ingredients.length > 0 && (
          <div className="flex items-center gap-2 text-xs sm:text-sm font-bold text-orange-700 dark:text-orange-400">
            <ChefHat className="h-4 w-4 sm:h-5 sm:w-5" />
            <span>Ingredientes</span>
          </div>
        )}

        <div className="flex gap-2 pt-2">
          <Button 
            variant="outline" 
            size="sm" 
            className="admin-action-btn hover:bg-blue-50 hover:text-blue-600 hover:border-blue-300 dark:hover:bg-blue-950 dark:hover:text-blue-400 flex-1 sm:flex-none h-9 sm:h-10 text-xs sm:text-sm font-semibold transition-all duration-200 hover:shadow-md"
            onClick={() => onEdit(product)}
          >
            <Edit className="h-4 w-4 sm:h-4 sm:w-4" />
            <span className="ml-2">Editar</span>
          </Button>
          <Button 
            variant="destructive" 
            size="sm" 
            className="admin-action-btn hover:bg-red-600 flex-1 sm:flex-none h-9 sm:h-10 text-xs sm:text-sm font-semibold transition-all duration-200 hover:shadow-md"
            onClick={() => onDelete(product.id)}
          >
            <Trash2 className="h-4 w-4 sm:h-4 sm:w-4" />
            <span className="ml-2">Excluir</span>
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};

export default ProductCard;
