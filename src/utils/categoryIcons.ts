import * as LucideIcons from 'lucide-react';

// Mapeamento de palavras-chave para ícones
const iconMapping: Record<string, string> = {
  // Comidas
  'burger': 'Beef',
  'hamburguer': 'Beef',
  'sanduiche': 'Sandwich',
  'pizza': 'Pizza',
  'churrasco': 'Flame',
  'steak': 'Utensils',
  'carne': 'Beef',
  'frango': 'Drumstick',
  'peixe': 'Fish',
  'salada': 'Salad',
  'sopa': 'Soup',
  'massa': 'UtensilsCrossed',
  'macarrao': 'UtensilsCrossed',
  'prato': 'UtensilsCrossed',
  'lanche': 'Sandwich',
  'snack': 'Popcorn',
  
  // Bebidas
  'bebida': 'Wine',
  'drink': 'Wine',
  'suco': 'GlassWater',
  'refrigerante': 'GlassWater',
  'agua': 'Droplet',
  'cafe': 'Coffee',
  'cha': 'Coffee',
  'cerveja': 'Beer',
  'vinho': 'Wine',
  
  // Sobremesas
  'sobremesa': 'Cake',
  'dessert': 'Cake',
  'doce': 'CakeSlice',
  'sorvete': 'IceCream',
  'bolo': 'Cake',
  
  // Outros
  'combo': 'Package',
  'kit': 'Package',
  'promocao': 'Sparkles',
  'vegetariano': 'Leaf',
  'vegano': 'Sprout',
  'fitness': 'Dumbbell',
  'light': 'Salad',
};

// Função para sugerir ícone baseado no nome da categoria
export const suggestIcon = (categoryName: string): string => {
  const normalizedName = categoryName
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');

  // Procura por palavras-chave no nome
  for (const [keyword, icon] of Object.entries(iconMapping)) {
    if (normalizedName.includes(keyword)) {
      return icon;
    }
  }

  // Ícone padrão
  return 'Tag';
};

// Função para obter o componente de ícone
export const getIconComponent = (iconName: string) => {
  const Icon = (LucideIcons as any)[iconName] || LucideIcons.Tag;
  return Icon;
};

// Lista de ícones populares para seleção manual
export const popularIcons = [
  'Beef', 'Pizza', 'Sandwich', 'UtensilsCrossed', 'Utensils',
  'Wine', 'Coffee', 'Beer', 'GlassWater', 'IceCream',
  'Cake', 'CakeSlice', 'Popcorn', 'Flame', 'Drumstick',
  'Fish', 'Salad', 'Soup', 'Leaf', 'Sprout',
  'Package', 'Sparkles', 'Tag', 'Star', 'Heart'
];
