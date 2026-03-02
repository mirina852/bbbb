import React, { useState, useEffect } from 'react';
import { Plus, Edit2, Trash2, GripVertical, ArrowUp, ArrowDown } from 'lucide-react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
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
import { toast } from 'sonner';
import { supabase } from '@/integrations/supabase/client';
import { useStore } from '@/contexts/StoreContext';
import { suggestIcon, getIconComponent, popularIcons } from '@/utils/categoryIcons';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Badge } from '@/components/ui/badge';

interface Category {
  id: string;
  name: string;
  slug: string;
  display_order: number;
  icon?: string;
}

interface CategoryManagerProps {
  isOpen: boolean;
  onClose: () => void;
  onCategoriesChange: () => void;
}

const CategoryManager = ({ isOpen, onClose, onCategoriesChange }: CategoryManagerProps) => {
  const { currentStore } = useStore();
  const [categories, setCategories] = useState<Category[]>([]);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  const [deleteCategory, setDeleteCategory] = useState<Category | null>(null);
  const [formData, setFormData] = useState({ name: '', slug: '', icon: '' });
  const [loading, setLoading] = useState(false);
  const [showIconPicker, setShowIconPicker] = useState(false);

  useEffect(() => {
    if (isOpen) {
      loadCategories();
    }
  }, [isOpen]);

  const loadCategories = async () => {
    if (!currentStore?.id) {
      toast.error('Nenhuma loja selecionada');
      return;
    }

    try {
      const { data, error } = await supabase
        .from('categories' as any)
        .select('*')
        .eq('store_id', currentStore.id)
        .order('position', { ascending: true });

      if (error) throw error;
      setCategories((data || []).map((cat: any) => ({
        id: cat.id,
        name: cat.name,
        slug: cat.slug || cat.name.toLowerCase(),
        display_order: cat.position || 0,
        icon: cat.icon
      })));
    } catch (error) {
      console.error('Error loading categories:', error);
      toast.error('Erro ao carregar categorias');
    }
  };

  const handleAddEdit = () => {
    setEditingCategory(null);
    setFormData({ name: '', slug: '', icon: 'Tag' });
    setShowIconPicker(false);
    setIsFormOpen(true);
  };

  const handleEdit = (category: Category) => {
    setEditingCategory(category);
    setFormData({ name: category.name, slug: category.slug, icon: category.icon || 'Tag' });
    setShowIconPicker(false);
    setIsFormOpen(true);
  };

  const handleSave = async () => {
    if (!formData.name) {
      toast.error('Preencha o nome da categoria');
      return;
    }

    if (!currentStore?.id) {
      toast.error('Nenhuma loja selecionada');
      return;
    }

    setLoading(true);
    try {
      if (editingCategory) {
        // Update
        const { error } = await supabase
          .from('categories' as any)
          .update({ 
            name: formData.name,
            slug: formData.slug,
            icon: formData.icon
          })
          .eq('id', editingCategory.id);

        if (error) throw error;
        toast.success('Categoria atualizada com sucesso');
      } else {
        // Create
        const { error } = await supabase
          .from('categories' as any)
          .insert({ 
            store_id: currentStore.id,
            name: formData.name,
            slug: formData.slug,
            icon: formData.icon,
            position: categories.length
          } as any);

        if (error) throw error;
        toast.success('Categoria criada com sucesso');
      }

      setIsFormOpen(false);
      loadCategories();
      onCategoriesChange();
    } catch (error: any) {
      console.error('Error saving category:', error);
      if (error.code === '23505') {
        toast.error('Esta categoria já existe');
      } else {
        toast.error('Erro ao salvar categoria: ' + (error.message || 'Erro desconhecido'));
      }
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteCategory) return;

    setLoading(true);
    try {
      const { error } = await supabase
        .from('categories' as any)
        .delete()
        .eq('id', deleteCategory.id);

      if (error) throw error;
      
      toast.success('Categoria excluída com sucesso');
      setDeleteCategory(null);
      loadCategories();
      onCategoriesChange();
    } catch (error: any) {
      console.error('Error deleting category:', error);
      toast.error('Erro ao excluir categoria');
    } finally {
      setLoading(false);
    }
  };

  const generateSlug = (name: string) => {
    return name
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
  };

  const handleNameChange = (name: string) => {
    const newSlug = editingCategory ? formData.slug : generateSlug(name);
    const suggestedIcon = editingCategory ? formData.icon : suggestIcon(name);
    
    setFormData({ 
      name, 
      slug: newSlug,
      icon: suggestedIcon
    });
  };

  const handleMoveUp = async (category: Category, index: number) => {
    if (index === 0) return; // Já é o primeiro
    
    const updatedCategories = [...categories];
    const temp = updatedCategories[index - 1];
    updatedCategories[index - 1] = updatedCategories[index];
    updatedCategories[index] = temp;
    
    setCategories(updatedCategories);
    await updatePositions(updatedCategories);
  };

  const handleMoveDown = async (category: Category, index: number) => {
    if (index === categories.length - 1) return; // Já é o último
    
    const updatedCategories = [...categories];
    const temp = updatedCategories[index + 1];
    updatedCategories[index + 1] = updatedCategories[index];
    updatedCategories[index] = temp;
    
    setCategories(updatedCategories);
    await updatePositions(updatedCategories);
  };

  const updatePositions = async (updatedCategories: Category[]) => {
    try {
      // Atualizar posições no banco de dados
      const updates = updatedCategories.map((cat, idx) => 
        supabase
          .from('categories' as any)
          .update({ position: idx })
          .eq('id', cat.id)
      );
      
      await Promise.all(updates);
      toast.success('Ordem atualizada com sucesso');
      onCategoriesChange();
    } catch (error) {
      console.error('Error updating positions:', error);
      toast.error('Erro ao atualizar ordem');
      loadCategories(); // Recarregar em caso de erro
    }
  };

  return (
    <>
      <Dialog open={isOpen} onOpenChange={onClose}>
        <DialogContent className="max-w-2xl max-h-[85vh] sm:max-h-[80vh] overflow-y-auto p-4 sm:p-6">
          <DialogHeader className="pb-3 sm:pb-4">
            <DialogTitle className="text-lg sm:text-xl">Gerenciar Categorias</DialogTitle>
          </DialogHeader>

          <div className="space-y-3 sm:space-y-4">
            <Button 
              onClick={handleAddEdit}
              className="w-full h-10 sm:h-11 text-sm sm:text-base"
            >
              <Plus className="h-4 w-4 mr-2" />
              Adicionar Nova Categoria
            </Button>

            <div className="space-y-2">
              <p className="text-xs sm:text-sm text-muted-foreground mb-2 px-1">
                Use as setas para definir qual categoria aparece primeiro na loja
              </p>
              {categories.map((category, index) => {
                const IconComponent = getIconComponent(category.icon || 'Tag');
                return (
                  <div
                    key={category.id}
                    className="flex items-center gap-2 sm:gap-3 p-2 sm:p-3 rounded-lg border bg-card hover:bg-accent/50 transition-colors"
                  >
                    <Badge variant={index === 0 ? "default" : "secondary"} className="w-6 h-6 sm:w-8 sm:h-8 flex items-center justify-center rounded-full text-xs sm:text-sm flex-shrink-0">
                      {index + 1}
                    </Badge>
                    <IconComponent className="h-4 w-4 sm:h-5 sm:w-5 text-primary flex-shrink-0" />
                    <div className="flex-1 min-w-0">
                      <div className="font-medium flex items-center gap-1.5 sm:gap-2 text-sm sm:text-base">
                        <span className="truncate">{category.name}</span>
                        {index === 0 && (
                          <Badge variant="default" className="text-[10px] sm:text-xs px-1.5 py-0 flex-shrink-0">
                            Primeira
                          </Badge>
                        )}
                      </div>
                      <div className="text-xs sm:text-sm text-muted-foreground truncate">{category.slug}</div>
                    </div>
                    <div className="flex gap-0.5 sm:gap-1 flex-shrink-0">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleMoveUp(category, index)}
                        disabled={index === 0}
                        title="Mover para cima"
                        className="h-7 w-7 sm:h-8 sm:w-8 p-0"
                      >
                        <ArrowUp className="h-3 w-3 sm:h-4 sm:w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleMoveDown(category, index)}
                        disabled={index === categories.length - 1}
                        title="Mover para baixo"
                        className="h-7 w-7 sm:h-8 sm:w-8 p-0"
                      >
                        <ArrowDown className="h-3 w-3 sm:h-4 sm:w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleEdit(category)}
                        title="Editar"
                        className="h-7 w-7 sm:h-8 sm:w-8 p-0"
                      >
                        <Edit2 className="h-3 w-3 sm:h-4 sm:w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => setDeleteCategory(category)}
                        title="Excluir"
                        className="h-7 w-7 sm:h-8 sm:w-8 p-0"
                      >
                        <Trash2 className="h-3 w-3 sm:h-4 sm:w-4 text-destructive" />
                      </Button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Form Dialog */}
      <Dialog open={isFormOpen} onOpenChange={setIsFormOpen}>
        <DialogContent className="p-4 sm:p-6">
          <DialogHeader className="pb-3 sm:pb-4">
            <DialogTitle className="text-lg sm:text-xl">
              {editingCategory ? 'Editar Categoria' : 'Nova Categoria'}
            </DialogTitle>
          </DialogHeader>

          <div className="space-y-3 sm:space-y-4">
            <div className="space-y-1.5 sm:space-y-2">
              <Label htmlFor="name" className="text-sm sm:text-base">Nome da Categoria</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => handleNameChange(e.target.value)}
                placeholder="Ex: Sobremesas"
                className="h-10 sm:h-11 text-sm sm:text-base"
              />
            </div>

            <div className="space-y-1.5 sm:space-y-2">
              <Label className="text-sm sm:text-base">Ícone</Label>
              <div className="flex items-center gap-2">
                {(() => {
                  const IconComponent = getIconComponent(formData.icon);
                  return (
                    <div className="flex items-center gap-2 p-2 border rounded-md flex-1">
                      <IconComponent className="h-4 w-4 sm:h-5 sm:w-5 text-primary" />
                      <span className="text-xs sm:text-sm truncate">{formData.icon}</span>
                    </div>
                  );
                })()}
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => setShowIconPicker(!showIconPicker)}
                  className="h-9 sm:h-10 text-xs sm:text-sm px-3 sm:px-4"
                >
                  {showIconPicker ? 'Fechar' : 'Alterar'}
                </Button>
              </div>
              
              {showIconPicker && (
                <ScrollArea className="h-40 sm:h-48 border rounded-md p-2">
                  <div className="grid grid-cols-4 sm:grid-cols-5 gap-1.5 sm:gap-2">
                    {popularIcons.map((iconName) => {
                      const IconComponent = getIconComponent(iconName);
                      return (
                        <button
                          key={iconName}
                          type="button"
                          onClick={() => {
                            setFormData({ ...formData, icon: iconName });
                            setShowIconPicker(false);
                          }}
                          className={`p-1.5 sm:p-2 rounded-md hover:bg-accent transition-colors flex items-center justify-center ${
                            formData.icon === iconName ? 'bg-primary text-primary-foreground' : ''
                          }`}
                          title={iconName}
                        >
                          <IconComponent className="h-4 w-4 sm:h-5 sm:w-5" />
                        </button>
                      );
                    })}
                  </div>
                </ScrollArea>
              )}
              <p className="text-xs text-muted-foreground">
                Ícone sugerido automaticamente baseado no nome
              </p>
            </div>

            <div className="space-y-1.5 sm:space-y-2">
              <Label htmlFor="slug" className="text-sm sm:text-base">Slug (identificador único)</Label>
              <Input
                id="slug"
                value={formData.slug}
                onChange={(e) => setFormData({ ...formData, slug: e.target.value })}
                placeholder="Ex: sobremesas"
                className="h-10 sm:h-11 text-sm sm:text-base"
              />
              <p className="text-[10px] sm:text-xs text-muted-foreground">
                Usado internamente para identificar a categoria
              </p>
            </div>
          </div>

          <DialogFooter className="flex-col sm:flex-row gap-2 sm:gap-0">
            <Button 
              variant="outline" 
              onClick={() => setIsFormOpen(false)}
              className="w-full sm:w-auto h-10 sm:h-11 text-sm sm:text-base"
            >
              Cancelar
            </Button>
            <Button 
              onClick={handleSave} 
              disabled={loading}
              className="w-full sm:w-auto h-10 sm:h-11 text-sm sm:text-base"
            >
              {loading ? 'Salvando...' : 'Salvar'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Dialog */}
      <AlertDialog open={!!deleteCategory} onOpenChange={() => setDeleteCategory(null)}>
        <AlertDialogContent className="p-4 sm:p-6">
          <AlertDialogHeader className="pb-3 sm:pb-4">
            <AlertDialogTitle className="text-lg sm:text-xl">Tem certeza?</AlertDialogTitle>
            <AlertDialogDescription className="text-xs sm:text-sm">
              Esta ação excluirá a categoria "{deleteCategory?.name}". 
              Produtos com esta categoria precisarão ser atualizados.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter className="flex-col sm:flex-row gap-2 sm:gap-0">
            <AlertDialogCancel className="w-full sm:w-auto h-10 sm:h-11 text-sm sm:text-base m-0">Cancelar</AlertDialogCancel>
            <AlertDialogAction 
              onClick={handleDelete}
              className="bg-destructive hover:bg-destructive/90 w-full sm:w-auto h-10 sm:h-11 text-sm sm:text-base"
              disabled={loading}
            >
              {loading ? 'Excluindo...' : 'Excluir'}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
};

export default CategoryManager;
