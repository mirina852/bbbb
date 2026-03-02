
import React, { useState, useEffect } from 'react';
import { Plus, Truck, ChefHat, Tags } from 'lucide-react';
import AdminLayout from '@/layouts/AdminLayout';
import PageHeader from '@/components/common/PageHeader';
import ProductCard from '@/components/products/ProductCard';
import ProductForm from '@/components/products/ProductForm';
import DeliveryFeeSettings from '@/components/settings/DeliveryFeeSettings';
import CategoryManager from '@/components/products/CategoryManager';
import { productsService, categoriesService, Category } from '@/services/supabaseService';
import { Product } from '@/types';
import { useStore } from '@/contexts/StoreContext';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Button } from '@/components/ui/button';
import { toast } from "sonner";
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';

const Products = () => {
  const { currentStore, loadUserStores } = useStore();
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [deleteProductId, setDeleteProductId] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [loading, setLoading] = useState(true);
  const [isDeliveryFeeOpen, setIsDeliveryFeeOpen] = useState(false);
  const [isCategoryManagerOpen, setIsCategoryManagerOpen] = useState(false);
  const deliveryFee = currentStore?.delivery_fee ?? 0;
  
  useEffect(() => {
    if (currentStore?.id) {
      loadProducts();
      loadCategories();
    }
  }, [currentStore?.id]);
  
  const loadProducts = async () => {
    if (!currentStore?.id) {
      console.log('Nenhuma loja selecionada');
      setLoading(false);
      return;
    }

    try {
      console.log('Carregando produtos para loja:', currentStore.id);
      const data = await productsService.getAllForAdmin(currentStore.id);
      console.log('Produtos carregados:', data.length);
      setProducts(data);
    } catch (error) {
      console.error('Error loading products:', error);
      toast.error('Erro ao carregar produtos');
    } finally {
      setLoading(false);
    }
  };

  const loadCategories = async () => {
    if (!currentStore?.id) {
      console.log('Nenhuma loja selecionada');
      return;
    }

    try {
      const data = await categoriesService.getAllByStore(currentStore.id);
      console.log('Categorias carregadas:', data);
      setCategories(data);
    } catch (error) {
      console.error('Error loading categories:', error);
      toast.error('Erro ao carregar categorias');
    }
  };
  
  const handleAddEditProduct = async (product: Product) => {
    if (!currentStore?.id) {
      toast.error('Nenhuma loja selecionada');
      return;
    }

    try {
      console.log('Tentando salvar produto:', product);
      
      // Adicionar store_id ao produto
      const productWithStore = {
        ...product,
        store_id: currentStore.id
      };
      
      if (editingProduct) {
        // Update existing product
        console.log('Atualizando produto existente...');
        await productsService.update(productWithStore.id, productWithStore);
        setProducts(products.map(p => p.id === productWithStore.id ? productWithStore : p));
        toast.success("Produto atualizado com sucesso");
      } else {
        // Add new product
        console.log('Adicionando novo produto...');
        const newProduct = await productsService.create(productWithStore);
        console.log('Produto criado:', newProduct);
        setProducts([...products, newProduct]);
        toast.success("Produto adicionado com sucesso");
      }
      
      setIsFormOpen(false);
      setEditingProduct(null);
    } catch (error: any) {
      console.error('Erro detalhado ao salvar produto:', error);
      toast.error('Erro ao salvar produto: ' + (error.message || 'Erro desconhecido'));
    }
  };
  
  const handleEditProduct = (product: Product) => {
    setEditingProduct(product);
    setIsFormOpen(true);
  };
  
  const handleDeleteProduct = (id: string) => {
    setDeleteProductId(id);
  };
  
  const confirmDelete = async () => {
    if (deleteProductId) {
      try {
        await productsService.delete(deleteProductId);
        setProducts(products.filter(p => p.id !== deleteProductId));
        setDeleteProductId(null);
        toast.success("Produto deletado com sucesso");
      } catch (error) {
        console.error('Error deleting product:', error);
        toast.error('Erro ao deletar produto');
      }
    }
  };
  
  
  
  const filteredProducts = products.filter(product => {
    const matchesSearch = product.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          product.description.toLowerCase().includes(searchTerm.toLowerCase());
    
    // Comparar pelo category_id em vez de product.category (texto)
    const matchesCategory = categoryFilter === 'all' || product.category_id === categoryFilter;
    
    return matchesSearch && matchesCategory;
  });
  
  return (
    <AdminLayout>
      <div className="space-y-4 mb-4 sm:mb-6 px-2 sm:px-0">
        <PageHeader 
          title="Produtos" 
          description="Gerencie seu menu de comidas"
          action={{
            label: "Adicionar Produto",
            icon: <Plus className="h-4 w-4" />,
            onClick: () => {
              setEditingProduct(null);
              setIsFormOpen(true);
            }
          }}
        />
        
        <div className="flex flex-col sm:flex-row gap-2 w-full">
          <Button
            variant="outline"
            onClick={() => setIsCategoryManagerOpen(true)}
            className="w-full sm:w-auto justify-center"
          >
            <Tags className="h-4 w-4 mr-2" />
            <span className="text-sm">Gerenciar Categorias</span>
          </Button>
          <Button
            variant="outline"
            onClick={() => setIsDeliveryFeeOpen(true)}
            className="w-full sm:w-auto justify-center"
          >
            <Truck className="h-4 w-4 mr-2" />
            <span className="text-sm">Taxa de Entrega</span>
          </Button>
        </div>
      </div>
      
      <div className="w-full px-2 sm:px-4 lg:px-6">
        <div className="flex flex-col gap-3 mb-6 sm:mb-8 max-w-4xl mx-auto">
          <div className="w-full">
            <Input
              placeholder="Buscar produtos..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="h-10 sm:h-11 text-sm sm:text-base bg-background/50 backdrop-blur-sm border-border/50 focus:border-primary/50 w-full"
            />
          </div>
          
          <Select
            value={categoryFilter}
            onValueChange={setCategoryFilter}
          >
            <SelectTrigger className="w-full h-10 sm:h-11 bg-background/50 backdrop-blur-sm border-border/50 text-sm sm:text-base">
              <SelectValue placeholder="Todas as Categorias" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Todas as Categorias</SelectItem>
              {categories.map(category => (
                <SelectItem key={category.id} value={category.id}>
                  {category.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        {loading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-3 sm:gap-4 lg:gap-6 justify-items-center">
            {[...Array(8)].map((_, i) => (
              <div key={i} className="animate-pulse">
                <div className="bg-muted rounded-xl h-64 mb-4"></div>
                <div className="space-y-2">
                  <div className="bg-muted rounded h-4 w-3/4"></div>
                  <div className="bg-muted rounded h-3 w-1/2"></div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-3 sm:gap-4 lg:gap-6 justify-items-center">
              {filteredProducts.map(product => (
                <div key={product.id} className="animate-fade-in">
                  <ProductCard
                    product={product}
                    categories={categories}
                    onEdit={handleEditProduct}
                    onDelete={handleDeleteProduct}
                  />
                </div>
              ))}
            </div>
            
            {filteredProducts.length === 0 && !loading && (
              <div className="flex flex-col items-center justify-center py-16 px-4">
                <div className="w-24 h-24 bg-muted rounded-full flex items-center justify-center mb-4">
                  <ChefHat className="h-10 w-10 text-muted-foreground" />
                </div>
                <h3 className="text-lg font-semibold text-foreground mb-2">
                  Nenhum produto encontrado
                </h3>
                <p className="text-muted-foreground text-center max-w-md">
                  {searchTerm || categoryFilter !== 'all' 
                    ? 'Tente ajustar os filtros para encontrar produtos.'
                    : 'Você ainda não tem produtos cadastrados. Adicione seu primeiro produto!'
                  }
                </p>
              </div>
            )}
          </>
        )}
      </div>
      
      <ProductForm
        isOpen={isFormOpen}
        onClose={() => {
          setIsFormOpen(false);
          setEditingProduct(null);
        }}
        onSave={handleAddEditProduct}
        product={editingProduct}
        categories={categories}
      />

      <CategoryManager
        isOpen={isCategoryManagerOpen}
        onClose={() => setIsCategoryManagerOpen(false)}
        onCategoriesChange={loadCategories}
      />

      <DeliveryFeeSettings
        isOpen={isDeliveryFeeOpen}
        onClose={() => setIsDeliveryFeeOpen(false)}
        currentFee={deliveryFee}
        onUpdate={(newFee) => {
          // Recarregar a loja para obter o novo valor
          loadUserStores();
        }}
      />
      
      <AlertDialog open={!!deleteProductId} onOpenChange={() => setDeleteProductId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Tem certeza?</AlertDialogTitle>
            <AlertDialogDescription>
              Esta ação não pode ser desfeita. Isso excluirá permanentemente o produto.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} className="bg-red-500 hover:bg-red-600">
              Excluir
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AdminLayout>
  );
};

export default Products;
