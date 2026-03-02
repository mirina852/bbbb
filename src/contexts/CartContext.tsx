import React, { createContext, useContext, useState, ReactNode } from 'react';
import { Product } from '@/types';
import { toast } from "sonner";

interface CartItem {
  product: Product;
  quantity: number;
  removedIngredients?: string[];
  extraIngredients?: { name: string; price: number }[];
}

interface CartContextType {
  cartItems: CartItem[];
  items: CartItem[]; // Alias for cartItems
  total: number; // Total cart value
  addToCart: (product: Product, removedIngredients?: string[], extraIngredients?: { name: string; price: number }[]) => void;
  removeFromCart: (productId: string) => void;
  updateQuantity: (productId: string, quantity: number) => void;
  clearCart: () => void;
}

const CartContext = createContext<CartContextType | undefined>(undefined);

export const useCart = () => {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error('useCart must be used within a CartProvider');
  }
  return context;
};

interface CartProviderProps {
  children: ReactNode;
}

export const CartProvider = ({ children }: CartProviderProps) => {
  const [cartItems, setCartItems] = useState<CartItem[]>([]);

  // Calculate total
  const total = cartItems.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);

  const addToCart = (product: Product, removedIngredients: string[] = [], extraIngredients: { name: string; price: number }[] = []) => {
    // Calculate extra ingredients price
    const extraPrice = extraIngredients.reduce((total, extra) => total + extra.price, 0);
    const finalPrice = product.price + extraPrice;
    
    const existingItemIndex = cartItems.findIndex(
      item => 
        item.product.id === product.id && 
        JSON.stringify(item.removedIngredients || []) === JSON.stringify(removedIngredients) &&
        JSON.stringify(item.extraIngredients || []) === JSON.stringify(extraIngredients)
    );

    if (existingItemIndex >= 0) {
      setCartItems(prev =>
        prev.map((item, index) =>
          index === existingItemIndex
            ? { 
                ...item, 
                quantity: item.quantity + 1,
                product: { ...item.product, price: finalPrice }
              }
            : item
        )
      );
    } else {
      setCartItems(prev => [
        ...prev,
        {
          product: { ...product, price: finalPrice },
          quantity: 1,
          removedIngredients,
          extraIngredients,
        },
      ]);
    }

    const customizationText = [
      removedIngredients.length > 0 ? `sem ${removedIngredients.length} ingrediente${removedIngredients.length > 1 ? 's' : ''}` : '',
      extraIngredients.length > 0 ? `com ${extraIngredients.length} extra${extraIngredients.length > 1 ? 's' : ''}` : ''
    ].filter(Boolean).join(', ');

    const displayText = customizationText ? ` (${customizationText})` : '';
    toast.success(`${product.name}${displayText} adicionado ao carrinho`);
  };

  const removeFromCart = (productId: string) => {
    setCartItems(prev => prev.filter(item => item.product.id !== productId));
  };

  const updateQuantity = (productId: string, quantity: number) => {
    setCartItems(prev =>
      prev.map(item =>
        item.product.id === productId
          ? { ...item, quantity }
          : item
      )
    );
  };

  const clearCart = () => {
    setCartItems([]);
  };

  return (
    <CartContext.Provider value={{
      cartItems,
      items: cartItems, // Alias for backwards compatibility
      total,
      addToCart,
      removeFromCart,
      updateQuantity,
      clearCart
    }}>
      {children}
    </CartContext.Provider>
  );
};