import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { paymentId, status } = await req.json();

    console.log('Webhook received:', { paymentId, status });

    // Buscar pagamento
    const { data: payment, error: paymentError } = await supabaseClient
      .from('subscription_payments')
      .select('*, subscription_plans(*)')
      .eq('external_payment_id', paymentId)
      .single();

    if (paymentError || !payment) {
      console.error('Payment not found:', paymentError);
      throw new Error('Pagamento não encontrado');
    }

    console.log('Payment found:', payment.id);

    // Se pagamento foi aprovado e ainda está pendente
    if (status === 'approved' && payment.status === 'pending') {
      console.log('Approving payment and creating subscription...');
      
      // 1. Atualizar status do pagamento
      const { error: updateError } = await supabaseClient
        .from('subscription_payments')
        .update({
          status: 'approved',
          paid_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .eq('id', payment.id);

      if (updateError) {
        console.error('Error updating payment:', updateError);
        throw updateError;
      }

      // 2. Calcular data de expiração da assinatura
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + payment.subscription_plans.duration_days);

      // 3. Criar/ativar assinatura
      const { error: subError } = await supabaseClient
        .from('user_subscriptions')
        .insert({
          user_id: payment.user_id,
          plan_id: payment.plan_id,
          status: 'active',
          expires_at: expiresAt.toISOString()
        });

      if (subError) {
        console.error('Error creating subscription:', subError);
        throw subError;
      }

      console.log('Subscription activated successfully');
    }

    return new Response(
      JSON.stringify({ success: true }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    );

  } catch (error: any) {
    console.error('Error in payment-webhook:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400 
      }
    );
  }
});
