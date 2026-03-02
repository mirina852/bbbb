import { supabase } from '@/integrations/supabase/client';
import { Product, Order, OrderItem, OrderStatus, Ingredient } from '@/types';

export interface Category {
  id: string;
  name: string;
  slug: string;
  display_order: number;
}

// Products Service
export const productsService = {
  async getAll(): Promise<Product[]> {
    const { data, error } = await supabase
      .from('produtos' as any)
      .select('*')
      .eq('available', true)
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    
    // Get ingredients for all products
    const products = (data || []) as any[];
    const productsWithIngredients = await Promise.all(
      products.map(async (product: any) => {
        const ingredients = await ingredientsService.getByProductId(product.id);
        return { ...product, ingredients } as Product;
      })
    );
    
    return productsWithIngredients;
  },

  async getAllByStore(storeId: string): Promise<Product[]> {
    console.log('🔍 getAllByStore - Buscando produtos para loja:', storeId);
    
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('store_id', storeId)
      .eq('available', true)
      .order('created_at', { ascending: false });
    
    if (error) {
      console.error('❌ Erro ao buscar produtos:', error);
      throw error;
    }
    
    console.log('✅ Produtos encontrados:', data?.length || 0);
    
    // Get ingredients for all products
    const products = (data || []) as any[];
    const productsWithIngredients = await Promise.all(
      products.map(async (product: any) => {
        const ingredients = await ingredientsService.getByProductId(product.id);
        return { ...product, ingredients } as Product;
      })
    );
    
    return productsWithIngredients;
  },

  async getAllForAdmin(storeId?: string): Promise<Product[]> {
    let query = supabase
      .from('products')
      .select('*');
    
    // Filtrar por store_id se fornecido
    if (storeId) {
      query = query.eq('store_id', storeId);
    }
    
    const { data, error } = await query.order('created_at', { ascending: false });
    
    if (error) throw error;
    
    // Get ingredients for all products
    const products = (data || []) as any[];
    const productsWithIngredients = await Promise.all(
      products.map(async (product: any) => {
        const ingredients = await ingredientsService.getByProductId(product.id);
        return { ...product, ingredients } as Product;
      })
    );
    
    return productsWithIngredients;
  },

  async getById(id: string): Promise<Product | null> {
    const { data, error } = await supabase
      .from('products')
      .select('*')
      .eq('id', id)
      .maybeSingle();
    
    if (error) throw error;
    if (!data) return null;
    
    // Get ingredients for this product
    const ingredients = await ingredientsService.getByProductId(id);
    return { ...data, ingredients } as Product;
  },

  async create(product: Omit<Product, 'id'>): Promise<Product> {
    try {
      console.log('Criando produto no Supabase:', product);
      const { ingredients, id, created_at, updated_at, ...productData } = product as any;
      
      // Validar campos obrigatórios
      if (!productData.store_id) {
        throw new Error('store_id é obrigatório');
      }
      if (!productData.name) {
        throw new Error('name é obrigatório');
      }
      if (productData.price === undefined || productData.price === null) {
        throw new Error('price é obrigatório');
      }
      
      // Estrutura da tabela products (em inglês)
      const cleanProductData = {
        store_id: productData.store_id,
        name: productData.name,
        description: productData.description || '',
        price: Number(productData.price),
        image: productData.image || productData.image_url || '',
        category: productData.category || 'outros',
        category_id: productData.category_id || productData.categoria_id || null,
        available: productData.available !== undefined ? productData.available : true
      };
      
      console.log('Dados do produto limpos:', cleanProductData);
      
      // Insert na tabela products (nome correto)
      const { data, error } = await supabase
        .from('products')
        .insert(cleanProductData)
        .select()
        .single();
      
      if (error) {
        console.error('Erro do Supabase ao inserir produto:', error);
        throw error;
      }
      
      console.log('Produto criado com sucesso:', data);
      
      // Save ingredients if any
      if (ingredients && ingredients.length > 0) {
        await ingredientsService.createMany(data.id, ingredients);
      }
      
      // Get the complete product with ingredients
      const savedIngredients = await ingredientsService.getByProductId(data.id);
      return { ...data, ingredients: savedIngredients } as Product;
    } catch (error) {
      console.error('Erro na função create do productsService:', error);
      throw error;
    }
  },

  async update(id: string, product: Partial<Product>): Promise<Product> {
    const { ingredients, id: _id, created_at, updated_at, ...productData } = product as any;
    
    // Mapear campos para estrutura do banco
    const cleanProductData: any = {
      ...productData,
      image: productData.image || productData.image_url || '',
      category_id: productData.category_id || productData.categoria_id || null
    };
    
    // Remover campos que não existem no banco
    delete cleanProductData.image_url;
    delete cleanProductData.categoria_id;
    
    const { data, error } = await supabase
      .from('products')
      .update(cleanProductData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    
    // Update ingredients if provided
    if (ingredients !== undefined) {
      // Delete existing ingredients
      await ingredientsService.deleteByProductId(id);
      
      // Create new ingredients
      if (ingredients.length > 0) {
        await ingredientsService.createMany(id, ingredients);
      }
    }
    
    // Get the complete product with ingredients
    const savedIngredients = await ingredientsService.getByProductId(id);
    return { ...data, ingredients: savedIngredients } as Product;
  },

  async delete(id: string): Promise<void> {
    // Delete ingredients first
    await ingredientsService.deleteByProductId(id);
    
    const { error } = await supabase
      .from('products')
      .delete()
      .eq('id', id);
    
    if (error) throw error;
  }
};

// Ingredients Service
export const ingredientsService = {
  async getByProductId(productId: string): Promise<Ingredient[]> {
    const { data, error } = await supabase
      .from('ingredients')
      .select('*')
      .eq('product_id', productId);
    
    if (error) throw error;
    
    return (data || []).map(item => ({
      id: item.id,
      productId: item.product_id,
      name: item.name,
      isExtra: (item as any).is_extra || false,
      price: (item as any).price || undefined
    }));
  },

  async createMany(productId: string, ingredients: Ingredient[]): Promise<void> {
    if (ingredients.length === 0) return;
    
    const ingredientData = ingredients.map(ingredient => ({
      product_id: productId,
      name: ingredient.name,
      is_extra: ingredient.isExtra || false,
      price: ingredient.price || null
    }));
    
    const { error } = await supabase
      .from('ingredients')
      .insert(ingredientData);
    
    if (error) throw error;
  },

  async deleteByProductId(productId: string): Promise<void> {
    const { error } = await supabase
      .from('ingredients')
      .delete()
      .eq('product_id', productId);
    
    if (error) throw error;
  }
};

// Categories Service
export const categoriesService = {
  async getAll(): Promise<Category[]> {
    const { data, error } = await supabase
      .from('categories' as any)
      .select('*')
      .order('position', { ascending: true });

    if (error) throw error;
    return (data || []) as unknown as Category[];
  },

  async getAllByStore(storeId: string): Promise<Category[]> {
    const { data, error } = await supabase
      .from('categories' as any)
      .select('*')
      .eq('store_id', storeId)
      .order('position', { ascending: true });

    if (error) throw error;
    return (data || []) as unknown as Category[];
  },

  async create(category: Omit<Category, 'id'>): Promise<Category> {
    const { data, error } = await supabase
      .from('categories' as any)
      .insert(category as any)
      .select()
      .single();

    if (error) throw error;
    return data as unknown as Category;
  },

  async update(id: string, category: Partial<Category>): Promise<void> {
    const { error } = await supabase
      .from('categories' as any)
      .update(category as any)
      .eq('id', id);

    if (error) throw error;
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('categories' as any)
      .delete()
      .eq('id', id);

    if (error) throw error;
  }
};

// Orders Service
export const ordersService = {
  async getAll(storeId?: string): Promise<Order[]> {
    console.log('🔍 ordersService.getAll - Iniciando busca de pedidos', { storeId });
    
    try {
      let query = supabase
        .from('orders')
        .select(`
          *,
          order_items (*)
        `);
      
      // Filtrar por store_id se fornecido
      if (storeId) {
        query = query.eq('store_id', storeId);
        console.log('🔍 Aplicando filtro store_id:', storeId);
      }
      
      // Filtrar apenas pedidos confirmados (não pendentes)
      // Mostrar apenas pedidos com pagamento aprovado ou status diferente de 'pending'
      // Incluir status "pago" como confirmado
      query = query.in('status', ['pago', 'preparing', 'ready', 'out_for_delivery', 'delivered']);
      console.log('🔍 Filtrando apenas pedidos confirmados (incluindo pago, preparando, pronto, etc.)');
      
      const { data: orders, error, status } = await query.order('created_at', { ascending: false });
      
      if (error) {
        console.error('❌ Erro na query de pedidos:', { error, status, details: error.details });
        throw error;
      }
      
      console.log('✅ Pedidos encontrados:', orders?.length || 0);
      
      return orders?.map(order => ({
        id: order.id,
        customerName: order.customer_name,
        customerPhone: order.customer_phone,
        deliveryAddress: order.delivery_address,
        paymentMethod: order.payment_method,
        total: order.total,
        status: order.status as OrderStatus,
        items: order.order_items?.map((item: any) => ({
          id: item.id,
          productId: item.product_id,
          productName: item.product_name,
          quantity: item.quantity,
          price: item.price,
          removedIngredients: item.removed_ingredients || [],
          extraIngredients: item.extra_ingredients || []
        })) || [],
        createdAt: new Date(order.created_at),
        updatedAt: new Date(order.updated_at)
      })) || [];
    } catch (error) {
      console.error('❌ Erro ao buscar pedidos:', error);
      throw error;
    }
  },

  async getAllIncludingPending(storeId?: string): Promise<Order[]> {
    console.log('🔍 ordersService.getAllIncludingPending - Buscando TODOS os pedidos', { storeId });
    
    try {
      let query = supabase
        .from('orders')
        .select(`
          *,
          order_items (*)
        `);
      
      // Filtrar por store_id se fornecido
      if (storeId) {
        query = query.eq('store_id', storeId);
        console.log('🔍 Aplicando filtro store_id:', storeId);
      }
      
      // NÃO filtrar por status - buscar TODOS os pedidos
      console.log('🔍 Buscando todos os pedidos (incluindo pendentes)');
      
      const { data: orders, error, status } = await query.order('created_at', { ascending: false });
      
      if (error) {
        console.error('❌ Erro na query de pedidos:', { error, status, details: error.details });
        throw error;
      }
      
      console.log('✅ Pedidos encontrados:', orders?.length || 0);
      
      return orders?.map(order => ({
        id: order.id,
        customerName: order.customer_name,
        customerPhone: order.customer_phone,
        deliveryAddress: order.delivery_address,
        paymentMethod: order.payment_method,
        total: order.total,
        status: order.status as OrderStatus,
        items: order.order_items?.map((item: any) => ({
          id: item.id,
          productId: item.product_id,
          productName: item.product_name,
          quantity: item.quantity,
          price: item.price,
          removedIngredients: item.removed_ingredients || [],
          extraIngredients: item.extra_ingredients || []
        })) || [],
        createdAt: new Date(order.created_at),
        updatedAt: new Date(order.updated_at)
      })) || [];
    } catch (error) {
      console.error('❌ Erro ao buscar pedidos:', error);
      throw error;
    }
  },

  async getById(id: string): Promise<Order | null> {
    const { data: order, error } = await supabase
      .from('orders')
      .select(`
        *,
        order_items (*)
      `)
      .eq('id', id)
      .single();
    
    if (error) throw error;
    
    if (!order) return null;
    
    return {
      id: order.id,
      customerName: order.customer_name,
      customerPhone: order.customer_phone,
      deliveryAddress: order.delivery_address,
      paymentMethod: order.payment_method,
      total: order.total,
      status: order.status as OrderStatus,
      items: order.order_items?.map((item: any) => ({
        id: item.id,
        productId: item.product_id,
        productName: item.product_name,
        quantity: item.quantity,
        price: item.price,
        removedIngredients: item.removed_ingredients || [],
        extraIngredients: item.extra_ingredients || []
      })) || [],
      createdAt: new Date(order.created_at),
      updatedAt: new Date(order.updated_at)
    };
  },

  async create(orderData: {
    store_id: string;
    customerName: string;
    customerPhone?: string;
    deliveryAddress?: string;
    paymentMethod?: string;
    items: OrderItem[];
    total: number;
    external_payment_id?: string;
    payment_status?: string;
  }): Promise<Order> {
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert([{
        store_id: orderData.store_id,
        customer_name: orderData.customerName,
        customer_phone: orderData.customerPhone,
        delivery_address: orderData.deliveryAddress,
        payment_method: orderData.paymentMethod,
        total: orderData.total,
        status: 'pending',
        external_payment_id: orderData.external_payment_id || null,
        payment_status: orderData.payment_status || 'pending'
      }])
      .select()
      .single();
    
    if (orderError) throw orderError;
    
    const { error: itemsError } = await supabase
      .from('order_items')
      .insert(orderData.items.map(item => ({
        order_id: order.id,
        product_id: item.productId,
        product_name: item.productName,
        quantity: item.quantity,
        price: item.price,
        removed_ingredients: item.removedIngredients || [],
        extra_ingredients: item.extraIngredients || []
      })));
    
    if (itemsError) throw itemsError;
    
    // Return the complete order with items
    return this.getById(order.id) as Promise<Order>;
  },

  async updateStatus(id: string, status: Order['status']): Promise<Order> {
    const { data, error } = await supabase
      .from('orders')
      .update({ status })
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    
    return this.getById(id) as Promise<Order>;
  }
};