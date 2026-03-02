
import React from 'react';
import { Product, Ingredient } from '@/types';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import IngredientManager from './IngredientManager';
import { Category } from '@/services/supabaseService';

interface ProductFormProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (product: Product) => void;
  product: Product | null;
  categories: Category[];
}

const ProductForm = ({ isOpen, onClose, onSave, product, categories }: ProductFormProps) => {
  const [formData, setFormData] = React.useState<Partial<Product>>({
    name: '',
    description: '',
    price: 0,
    image_url: '',
    category_id: '',
    available: true,
    ingredients: []
  });

  const [selectedFile, setSelectedFile] = React.useState<File | null>(null);

  React.useEffect(() => {
    if (product) {
      setFormData({ ...product });
    } else {
      setFormData({
        name: '',
        description: '',
        price: 0,
        image_url: '',
        category_id: '',
        available: true,
        ingredients: []
      });
    }
  }, [product]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleNumberChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: parseFloat(value) }));
  };

  const handleCategoryChange = (value: string) => {
    setFormData(prev => ({ ...prev, category_id: value }));
  };

  const handleAvailabilityChange = (checked: boolean) => {
    setFormData(prev => ({ ...prev, available: checked }));
  };

  const handleIngredientsChange = (ingredients: Ingredient[]) => {
    setFormData(prev => ({ ...prev, ingredients }));
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0] || null;
    setSelectedFile(file);

    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setFormData(prev => ({ ...prev, image_url: reader.result as string }));
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    console.log('FormData ao submeter:', formData);
    
    if (!formData.name || !formData.description || formData.price === undefined || formData.price === null) {
      console.error('Campos obrigatórios faltando:', {
        name: formData.name,
        description: formData.description,
        price: formData.price
      });
      return;
    }
    
    const productToSave: any = {
      name: formData.name,
      description: formData.description,
      price: Number(formData.price),
      // ✅ FIX: Preservar imagem existente ao editar se não houver nova imagem
      image_url: formData.image_url || (product?.image_url || product?.image) || '',
      category_id: formData.category_id || null,
      available: formData.available !== undefined ? formData.available : true,
      ingredients: formData.ingredients || []
    };
    
    // Preserva store_id se existir no formData ou no produto original
    if (formData.store_id) {
      productToSave.store_id = formData.store_id;
    } else if (product?.store_id) {
      productToSave.store_id = product.store_id;
    }
    
    // Só adiciona id se estiver editando
    if (product?.id) {
      productToSave.id = product.id;
    }
    
    console.log('Produto a ser salvo:', productToSave);
    onSave(productToSave as Product);
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="w-[95vw] max-w-md mx-auto max-h-[90vh] overflow-y-auto sm:w-full sm:max-w-md"
        aria-describedby="product-form-description"
      >
        <DialogHeader>
          <DialogTitle>{product ? 'Editar Produto' : 'Adicionar Novo Produto'}</DialogTitle>
          <p id="product-form-description" className="text-sm text-muted-foreground">
            {product ? 'Edite as informações do produto.' : 'Adicione um novo produto ao cardápio.'}
          </p>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="name">Nome do Produto</Label>
            <Input
              id="name"
              name="name"
              value={formData.name}
              onChange={handleChange}
              placeholder="Nome do produto"
              required
            />
          </div>
          
          <div className="space-y-2">
            <Label htmlFor="description">Descrição</Label>
            <Textarea
              id="description"
              name="description"
              value={formData.description}
              onChange={handleChange}
              placeholder="Descrição do produto"
              required
            />
          </div>
          
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="price">Preço</Label>
              <Input
                id="price"
                name="price"
                type="number"
                step="0.01"
                min="0"
                value={formData.price}
                onChange={handleNumberChange}
                placeholder="0.00"
                required
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="category">Categoria</Label>
              <Select 
                value={formData.category_id} 
                onValueChange={handleCategoryChange}
              >
                <SelectTrigger id="category">
                  <SelectValue placeholder="Selecionar categoria" />
                </SelectTrigger>
                <SelectContent>
                  {categories.map(category => (
                    <SelectItem key={category.id} value={category.id}>
                      {category.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          
          {/* Campo de URL */}
          <div className="space-y-2">
            <Label htmlFor="image_url">URL da Imagem</Label>
            <Input
              id="image_url"
              name="image_url"
              value={formData.image_url || ''}
              onChange={handleChange}
              placeholder="https://exemplo.com/imagem.jpg"
            />
          </div>

          {/* Botão de Upload */}
          <div className="space-y-2">
            <Label htmlFor="upload">Enviar Imagem</Label>
            <input
              id="upload"
              type="file"
              accept="image/*"
              onChange={handleFileChange}
              className="block w-full text-sm text-gray-600 file:mr-4 file:py-2 file:px-4 
                         file:rounded-full file:border-0 file:text-sm file:font-semibold 
                         file:bg-food-primary file:text-white hover:file:bg-food-dark"
            />
          </div>

          {/* Pré-visualização */}
          {formData.image_url && (
            <div>
              <Label>Pré-visualização:</Label>
              <img
                src={formData.image_url}
                alt="Preview"
                className="mt-2 w-32 h-32 object-cover rounded"
              />
            </div>
          )}
          
          <div className="flex items-center space-x-2">
            <Switch
              id="available"
              checked={formData.available}
              onCheckedChange={handleAvailabilityChange}
            />
            <Label htmlFor="available">Disponível para pedido</Label>
          </div>

          <IngredientManager
            ingredients={formData.ingredients || []}
            onIngredientsChange={handleIngredientsChange}
          />
          
          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit" className="bg-food-primary hover:bg-food-dark">
              {product ? 'Atualizar Produto' : 'Adicionar Produto'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default ProductForm;

