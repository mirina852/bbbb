import { supabase } from '@/integrations/supabase/client';

export interface SubscriptionPlan {
  id: string;
  name: string;
  slug: string;
  price: number;
  duration_days: number;
  is_trial: boolean;
  features: string[];
  is_available?: boolean;  // Indica se o plano está disponível para o usuário
}

export interface UserSubscription {
  id: string;
  plan_name: string;
  plan_slug: string;
  status: 'active' | 'expired' | 'cancelled';
  expires_at: string;
  created_at: string;  // Data de início real da assinatura
  days_remaining: number;
}

export const subscriptionService = {
  // Buscar todos os planos disponíveis
  async getPlans(): Promise<SubscriptionPlan[]> {
    const { data, error } = await (supabase as any)
      .from('subscription_plans')
      .select('*')
      .order('price', { ascending: true });
    
    if (error) throw error;

    const normalizeFeatures = (f: any): string[] => {
      if (Array.isArray(f)) return f as string[];
      if (f && typeof f === 'object') return Object.values(f) as string[]; // caso jsonb como objeto
      return [];
    };

    return (data || []).map((p: any) => ({
      ...p,
      price: p?.price != null ? Number(p.price) : 0,
      duration_days: p?.duration_days != null ? Number(p.duration_days) : 30,
      is_trial: Boolean(p?.is_trial),
      features: normalizeFeatures(p.features),
    }));
  },

  // Buscar planos disponíveis para o usuário (considera se já usou trial)
  async getAvailablePlans(userId: string): Promise<SubscriptionPlan[]> {
    const { data, error } = await (supabase as any)
      .rpc('get_available_plans', { _user_id: userId });
    
    if (error) throw error;

    const normalizeFeatures = (f: any): string[] => {
      if (Array.isArray(f)) return f as string[];
      if (f && typeof f === 'object') return Object.values(f) as string[];
      return [];
    };

    return (data || []).map((p: any) => ({
      ...p,
      features: normalizeFeatures(p.features),
    }));
  },

  // Verificar se usuário já usou o teste gratuito
  async hasUsedTrial(userId: string): Promise<boolean> {
    const { data, error } = await (supabase as any)
      .rpc('has_used_trial', { _user_id: userId });
    
    if (error) throw error;
    return data || false;
  },

  // Buscar assinatura ativa do usuário (sem RPC)
  async getActiveSubscription(userId: string): Promise<UserSubscription | null> {
    const nowIso = new Date().toISOString();
    const { data: rows, error } = await (supabase as any)
      .from('user_subscriptions')
      .select('id, subscription_plan_id, status, current_period_start, current_period_end')
      .eq('user_id', userId)
      .eq('status', 'active')
      .gt('current_period_end', nowIso)
      .order('current_period_end', { ascending: false })
      .limit(1);
    if (error) throw error;
    const row = rows?.[0];
    if (!row) return null;

    const { data: plan, error: planError } = await (supabase as any)
      .from('subscription_plans')
      .select('name, slug')
      .eq('id', row.subscription_plan_id)
      .single();
    if (planError) throw planError;

    const end = new Date(row.current_period_end);
    const diffDays = Math.max(0, Math.ceil((end.getTime() - Date.now()) / 86400000));

    const result: UserSubscription = {
      id: row.id,
      plan_name: plan?.name || '',
      plan_slug: plan?.slug || '',
      status: row.status,
      created_at: row.current_period_start,
      expires_at: row.current_period_end,
      days_remaining: diffDays,
    };
    return result;
  },

  // Verificar se usuário tem assinatura ativa (sem RPC)
  async hasActiveSubscription(userId: string): Promise<boolean> {
    const active = await this.getActiveSubscription(userId);
    return !!active;
  },

  // Criar pagamento PIX para assinatura
  async createPayment(userId: string, planId: string): Promise<any> {
    console.log('subscriptionService.createPayment chamado:', { userId, planId });
    
    // Buscar informações do plano
    const { data: plan, error: planError } = await (supabase as any)
      .from('subscription_plans')
      .select('price, name')
      .eq('id', planId)
      .single();

    if (planError) {
      console.error('❌ Erro ao buscar plano:', planError);
      throw new Error(`Erro ao buscar plano: ${planError.message}. Verifique se a migration foi executada.`);
    }

    if (!plan) {
      console.error('❌ Plano não encontrado:', planId);
      throw new Error('Plano não encontrado. Execute a migration primeiro.');
    }

    console.log('✅ Plano encontrado:', plan);
    console.log('📤 Invocando create-pix-payment com:', {
      planId,
      amount: plan.price,
      description: `Assinatura ${plan.name}`
    });

    const { data, error } = await supabase.functions.invoke('create-pix-payment', {
      body: {
        planId,
        amount: plan.price,
        description: `Assinatura ${plan.name}`
      }
    });

    if (error) {
      console.error('Erro ao criar pagamento:', error);
      console.error('Detalhes do erro:', {
        message: error.message,
        context: error.context,
        status: error.status
      });
      throw error;
    }
    
    console.log('Resposta da função:', data);
    
    // A função retorna { success: true, data: {...} }
    if (data && data.success && data.data) {
      console.log('Pagamento criado:', data.data);
      return data.data;
    }
    
    // Se não tiver success, pode ser erro
    if (data && !data.success) {
      throw new Error(data.error || 'Erro ao criar pagamento');
    }
    
    console.log('Pagamento criado (formato antigo):', data);
    return data;
  },

  // Verificar status do pagamento de assinatura
  async checkPaymentStatus(paymentId: string): Promise<any> {
    console.log('subscriptionService.checkPaymentStatus chamado:', { paymentId });
    
    const { data, error } = await supabase.functions.invoke('check-subscription-payment', {
      body: { paymentId }
    });

    if (error) {
      console.error('Erro ao verificar status do pagamento:', error);
      throw error;
    }

    console.log('Status do pagamento:', data);
    
    // A função retorna { success: true, status: "approved" | "pending" | etc }
    if (data && data.success) {
      return { status: data.status };
    }
    
    return data;
  },

  // Criar nova assinatura (direto - usado apenas em testes)
  async createSubscription(userId: string, planId: string): Promise<void> {
    console.log('subscriptionService.createSubscription chamado:', { userId, planId });
    
    // Buscar informações do plano
    const { data: plan, error: planError } = await (supabase as any)
      .from('subscription_plans')
      .select('duration_days')
      .eq('id', planId)
      .single();
    
    if (planError) {
      console.error('Erro ao buscar plano:', planError);
      throw new Error(`Erro ao buscar plano: ${planError.message}`);
    }

    if (!plan) {
      throw new Error('Plano não encontrado');
    }

    console.log('Plano encontrado:', plan);

    // Verificar se usuário já tem assinatura ativa
    const currentSubscription = await this.getActiveSubscription(userId);
    
    // Calcular início e data de expiração do novo período
    let periodStart = new Date();
    
    if (currentSubscription && currentSubscription.status === 'active' && currentSubscription.days_remaining > 0) {
      // Se tem assinatura ativa, adicionar novo período ao final da assinatura atual
      periodStart = new Date(currentSubscription.expires_at);
      console.log('Assinatura ativa encontrada, adicionando ao final:', periodStart);
    }
    
    const periodEnd = new Date(periodStart);
    periodEnd.setDate(periodEnd.getDate() + plan.duration_days);

    console.log('Criando assinatura com período:', {
      start: periodStart.toISOString(),
      end: periodEnd.toISOString(),
    });

    // Criar assinatura usando current_period_start / current_period_end
    const { data, error } = await (supabase as any)
      .from('user_subscriptions')
      .insert({
        user_id: userId,
        subscription_plan_id: planId,
        status: 'active',
        current_period_start: periodStart.toISOString(),
        current_period_end: periodEnd.toISOString(),
      })
      .select()
      .single();
    
    if (error) {
      console.error('Erro ao inserir assinatura:', error);
      throw new Error(`Erro ao criar assinatura: ${error.message}`);
    }

    console.log('Assinatura criada com sucesso:', data);
  }
};
