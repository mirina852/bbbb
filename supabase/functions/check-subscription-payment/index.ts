import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
    const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const PLATFORM_MP_TOKEN = Deno.env.get("PLATFORM_MERCADOPAGO_ACCESS_TOKEN") ?? "";

    console.log("=== check-subscription-payment iniciado ===");
    console.log("SUPABASE_URL:", SUPABASE_URL ? "configurado" : "NÃO CONFIGURADO");
    console.log("SERVICE_ROLE_KEY:", SERVICE_ROLE_KEY ? "configurado" : "NÃO CONFIGURADO");
    console.log("PLATFORM_MP_TOKEN:", PLATFORM_MP_TOKEN ? "configurado" : "NÃO CONFIGURADO");

    if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
      throw new Error("Variáveis de ambiente não configuradas");
    }

    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    // Autenticar usuário
    const authHeader = req.headers.get("Authorization");
    console.log("Auth header presente:", !!authHeader);
    
    if (!authHeader) {
      return new Response(JSON.stringify({ success: false, error: "Não autorizado" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401
      });
    }

    const token = authHeader.replace("Bearer ", "").trim();
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      console.error("Erro de autenticação:", authError);
      return new Response(JSON.stringify({ success: false, error: "Token inválido" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401
      });
    }

    console.log("Usuário autenticado:", user.id);

    const { paymentId } = await req.json();
    console.log("Verificando pagamento ID:", paymentId);

    if (!paymentId) {
      return new Response(JSON.stringify({ success: false, error: "paymentId é obrigatório" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400
      });
    }

    // Buscar pagamento no banco
    const { data: payment, error: paymentError } = await supabase
      .from("subscription_payments")
      .select("*, subscription_plans(*)")
      .eq("id", paymentId)
      .eq("user_id", user.id)
      .single();

    if (paymentError || !payment) {
      console.error("Pagamento não encontrado:", paymentError);
      return new Response(JSON.stringify({ success: false, error: "Pagamento não encontrado" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 404
      });
    }

    console.log("Pagamento encontrado:", {
      id: payment.id,
      status: payment.status,
      external_payment_id: payment.external_payment_id,
      subscription_plan_id: payment.subscription_plan_id
    });

    // Se já está aprovado, retornar
    if (payment.status === "approved") {
      console.log("Pagamento já está aprovado");
      return new Response(JSON.stringify({ success: true, status: "approved" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    // Verificar status no Mercado Pago
    const externalPaymentId = payment.external_payment_id || payment.payment_id;
    
    if (!externalPaymentId) {
      console.log("Sem external_payment_id, retornando status atual");
      return new Response(JSON.stringify({ success: true, status: payment.status }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    if (!PLATFORM_MP_TOKEN) {
      console.error("PLATFORM_MERCADOPAGO_ACCESS_TOKEN não configurado");
      return new Response(JSON.stringify({ success: true, status: payment.status }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    console.log("Consultando Mercado Pago, external_payment_id:", externalPaymentId);

    const mpResponse = await fetch(`https://api.mercadopago.com/v1/payments/${externalPaymentId}`, {
      headers: {
        "Authorization": `Bearer ${PLATFORM_MP_TOKEN}`
      }
    });

    console.log("Resposta MP status:", mpResponse.status);

    if (!mpResponse.ok) {
      console.error("Erro ao consultar MP:", mpResponse.status, await mpResponse.text());
      return new Response(JSON.stringify({ success: true, status: payment.status }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    const mpData = await mpResponse.json();
    console.log("Status no Mercado Pago:", mpData.status);

    // Se pagamento foi aprovado no MP mas não no banco
    if (mpData.status === "approved" && payment.status !== "approved") {
      console.log("🎉 Pagamento aprovado! Ativando assinatura...");

      // Atualizar status do pagamento
      const { error: updateError } = await supabase
        .from("subscription_payments")
        .update({ status: "approved", updated_at: new Date().toISOString() })
        .eq("id", payment.id);

      if (updateError) {
        console.error("Erro ao atualizar pagamento:", updateError);
      } else {
        console.log("✅ Status do pagamento atualizado para 'approved'");
      }

      // Calcular período da assinatura
      const durationDays = payment.subscription_plans?.duration_days || 30;
      const now = new Date();
      const periodEnd = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);

      console.log("Criando assinatura:", {
        user_id: user.id,
        subscription_plan_id: payment.subscription_plan_id,
        duration_days: durationDays,
        period_start: now.toISOString(),
        period_end: periodEnd.toISOString()
      });

      // Verificar se já existe assinatura ativa para este usuário
      const { data: existingSub, error: existingError } = await supabase
        .from("user_subscriptions")
        .select("id, current_period_end")
        .eq("user_id", user.id)
        .eq("status", "active")
        .gt("current_period_end", now.toISOString())
        .order("current_period_end", { ascending: false })
        .limit(1)
        .maybeSingle();

      if (existingError) {
        console.error("Erro ao verificar assinatura existente:", existingError);
      }

      if (existingSub) {
        // Estender assinatura existente
        console.log("Assinatura existente encontrada, estendendo...");
        const existingEnd = new Date(existingSub.current_period_end);
        const newEnd = new Date(existingEnd.getTime() + durationDays * 24 * 60 * 60 * 1000);

        const { error: extendError } = await supabase
          .from("user_subscriptions")
          .update({
            current_period_end: newEnd.toISOString(),
            subscription_plan_id: payment.subscription_plan_id,
            updated_at: new Date().toISOString()
          })
          .eq("id", existingSub.id);

        if (extendError) {
          console.error("Erro ao estender assinatura:", extendError);
          throw new Error("Erro ao estender assinatura");
        }

        console.log("✅ Assinatura estendida até:", newEnd.toISOString());
      } else {
        // Criar nova assinatura
        const { error: subError } = await supabase
          .from("user_subscriptions")
          .insert({
            user_id: user.id,
            subscription_plan_id: payment.subscription_plan_id,
            status: "active",
            current_period_start: now.toISOString(),
            current_period_end: periodEnd.toISOString()
          });

        if (subError) {
          console.error("Erro ao criar assinatura:", subError);
          throw new Error("Erro ao ativar assinatura: " + subError.message);
        }

        console.log("✅ Nova assinatura criada com sucesso!");
      }

      return new Response(JSON.stringify({ success: true, status: "approved" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }

    // Retornar status atual
    console.log("Retornando status:", mpData.status || payment.status);
    return new Response(JSON.stringify({ success: true, status: mpData.status || payment.status }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    });

  } catch (error: any) {
    console.error("❌ Erro na função:", error);
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500
    });
  }
});
