import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};

serve(async (req) => {
  // Health check
  if (req.method === "GET") {
    return new Response("Webhook ativo", { status: 200, headers: corsHeaders });
  }

  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
  const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const MP_ACCESS_TOKEN = Deno.env.get("PLATFORM_MERCADOPAGO_ACCESS_TOKEN") ?? "";
  const WEBHOOK_SECRET = Deno.env.get("MERCADO_PAGO_WEBHOOK_SECRET") ?? "";

  if (!SUPABASE_URL || !SERVICE_ROLE) {
    console.error("❌ Variáveis de ambiente não configuradas");
    return new Response("Configuração inválida", { status: 500, headers: corsHeaders });
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);

  try {
    const body = await req.json();
    console.log("📩 Webhook recebido:", JSON.stringify(body));

    // Verificar assinatura do webhook se a secret estiver configurada
    const signature = req.headers.get("x-signature");
    const requestId = req.headers.get("x-request-id");
    
    if (WEBHOOK_SECRET && signature && requestId) {
      console.log("🔐 Verificando assinatura do webhook...");
      
      // Calcular assinatura esperada
      const key = await crypto.subtle.importKey(
        "raw",
        new TextEncoder().encode(WEBHOOK_SECRET),
        { name: "HMAC", hash: "SHA-256" },
        false,
        ["sign"]
      );
      
      const message = requestId + JSON.stringify(body);
      const signatureBuffer = await crypto.subtle.sign(
        "HMAC",
        key,
        new TextEncoder().encode(message)
      );
      
      const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
        .map(b => b.toString(16).padStart(2, '0'))
        .join('');
      
      if (signature !== expectedSignature) {
        console.error("❌ Assinatura do webhook inválida");
        return new Response("Assinatura inválida", { 
          status: 401, 
          headers: corsHeaders 
        });
      }
      
      console.log("✅ Assinatura do webhook verificada com sucesso");
    } else if (WEBHOOK_SECRET) {
      console.warn("⚠️ Assinatura configurada mas headers não encontrados");
    }

    // Mercado Pago envia { action: "payment.created", data: { id: "123" } }
    const paymentId = body?.data?.id;
    const action = body?.action || body?.type;

    if (!paymentId) {
      console.log("⚠️ Sem payment_id no webhook");
      return new Response("OK", { status: 200, headers: corsHeaders });
    }

    console.log(`🔍 Buscando pagamento ${paymentId} no Mercado Pago...`);

    // Buscar detalhes do pagamento no Mercado Pago
    const mpResponse = await fetch(
      `https://api.mercadopago.com/v1/payments/${paymentId}`,
      {
        headers: {
          "Authorization": `Bearer ${MP_ACCESS_TOKEN}`
        }
      }
    );

    if (!mpResponse.ok) {
      console.error("❌ Erro ao buscar pagamento no MP:", mpResponse.status);
      return new Response("Erro MP", { status: 200, headers: corsHeaders });
    }

    const mpData = await mpResponse.json();
    console.log("📦 Dados do pagamento:", JSON.stringify({
      id: mpData.id,
      status: mpData.status,
      metadata: mpData.metadata
    }));

    const status = mpData.status; // approved, pending, rejected, cancelled
    const metadata = mpData.metadata || {};
    const paymentType = metadata.type;

    // -----------------------------
    //  PAGAMENTO DE PEDIDO (ORDER)
    // -----------------------------
    if (paymentType === "order" && metadata.order_id) {
      console.log(`🛒 Atualizando pedido ${metadata.order_id} para status: ${status}`);

      const { error: orderError } = await supabase
        .from("orders")
        .update({ 
          payment_status: status,
          external_payment_id: paymentId.toString(),
          updated_at: new Date().toISOString()
        })
        .eq("id", metadata.order_id);

      if (orderError) {
        console.error("❌ Erro ao atualizar pedido:", orderError);
      } else {
        console.log(`✅ Pedido ${metadata.order_id} atualizado para ${status}`);
      }

      return new Response("Pedido atualizado", { status: 200, headers: corsHeaders });
    }

    // -----------------------------
    //  PAGAMENTO DE ASSINATURA
    // -----------------------------
    if (paymentType === "subscription" && metadata.user_id) {
      console.log(`💳 Atualizando assinatura do usuário ${metadata.user_id}`);

      // Atualizar status do pagamento na tabela subscription_payments
      const { error: paymentError } = await supabase
        .from("subscription_payments")
        .update({ 
          status,
          updated_at: new Date().toISOString()
        })
        .eq("external_payment_id", paymentId.toString());

      if (paymentError) {
        console.error("❌ Erro ao atualizar pagamento:", paymentError);
      }

      // Se aprovado → ativar/criar assinatura
      if (status === "approved") {
        console.log("🎉 Pagamento aprovado! Ativando assinatura...");

        // Buscar o plano para pegar duration_days
        const { data: plan } = await supabase
          .from("subscription_plans")
          .select("duration_days")
          .eq("id", metadata.plan_id)
          .single();

        const durationDays = plan?.duration_days || 30;
        const now = new Date();
        const periodEnd = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);

        // Verificar se já existe assinatura ativa
        const { data: existingSub } = await supabase
          .from("user_subscriptions")
          .select("id, current_period_end")
          .eq("user_id", metadata.user_id)
          .eq("status", "active")
          .gt("current_period_end", now.toISOString())
          .order("current_period_end", { ascending: false })
          .limit(1)
          .maybeSingle();

        if (existingSub) {
          // Estender assinatura existente
          const existingEnd = new Date(existingSub.current_period_end);
          const newEnd = new Date(existingEnd.getTime() + durationDays * 24 * 60 * 60 * 1000);

          const { error: extendError } = await supabase
            .from("user_subscriptions")
            .update({
              current_period_end: newEnd.toISOString(),
              subscription_plan_id: metadata.plan_id,
              updated_at: new Date().toISOString()
            })
            .eq("id", existingSub.id);

          if (extendError) {
            console.error("❌ Erro ao estender assinatura:", extendError);
          } else {
            console.log(`✅ Assinatura estendida até ${newEnd.toISOString()}`);
          }
        } else {
          // Criar nova assinatura
          const { error: subError } = await supabase
            .from("user_subscriptions")
            .insert({
              user_id: metadata.user_id,
              subscription_plan_id: metadata.plan_id,
              status: "active",
              current_period_start: now.toISOString(),
              current_period_end: periodEnd.toISOString()
            });

          if (subError) {
            console.error("❌ Erro ao criar assinatura:", subError);
          } else {
            console.log(`✅ Nova assinatura criada até ${periodEnd.toISOString()}`);
          }
        }
      }

      return new Response("Assinatura processada", { status: 200, headers: corsHeaders });
    }

    // -----------------------------
    //  FALLBACK: Buscar por external_payment_id
    // -----------------------------
    console.log("🔎 Buscando pagamento por external_payment_id...");

    // Tentar encontrar em subscription_payments
    const { data: subPayment } = await supabase
      .from("subscription_payments")
      .select("*, subscription_plans(*)")
      .eq("external_payment_id", paymentId.toString())
      .maybeSingle();

    if (subPayment) {
      console.log(`📋 Encontrado pagamento de assinatura: ${subPayment.id}`);

      await supabase
        .from("subscription_payments")
        .update({ status, updated_at: new Date().toISOString() })
        .eq("id", subPayment.id);

      if (status === "approved" && subPayment.status !== "approved") {
        const durationDays = subPayment.subscription_plans?.duration_days || 30;
        const now = new Date();
        const periodEnd = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);

        // Verificar assinatura existente
        const { data: existingSub } = await supabase
          .from("user_subscriptions")
          .select("id, current_period_end")
          .eq("user_id", subPayment.user_id)
          .eq("status", "active")
          .gt("current_period_end", now.toISOString())
          .maybeSingle();

        if (existingSub) {
          const existingEnd = new Date(existingSub.current_period_end);
          const newEnd = new Date(existingEnd.getTime() + durationDays * 24 * 60 * 60 * 1000);

          await supabase
            .from("user_subscriptions")
            .update({
              current_period_end: newEnd.toISOString(),
              subscription_plan_id: subPayment.subscription_plan_id,
              updated_at: new Date().toISOString()
            })
            .eq("id", existingSub.id);

          console.log(`✅ Assinatura estendida via fallback até ${newEnd.toISOString()}`);
        } else {
          await supabase
            .from("user_subscriptions")
            .insert({
              user_id: subPayment.user_id,
              subscription_plan_id: subPayment.subscription_plan_id,
              status: "active",
              current_period_start: now.toISOString(),
              current_period_end: periodEnd.toISOString()
            });

          console.log(`✅ Nova assinatura criada via fallback até ${periodEnd.toISOString()}`);
        }
      }

      return new Response("OK", { status: 200, headers: corsHeaders });
    }

    // Tentar encontrar em orders
    const { data: order } = await supabase
      .from("orders")
      .select("id")
      .eq("external_payment_id", paymentId.toString())
      .maybeSingle();

    if (order) {
      console.log(`📋 Encontrado pedido: ${order.id}`);

      await supabase
        .from("orders")
        .update({ payment_status: status, updated_at: new Date().toISOString() })
        .eq("id", order.id);

      console.log(`✅ Pedido ${order.id} atualizado para ${status}`);
      return new Response("OK", { status: 200, headers: corsHeaders });
    }

    console.log("⚠️ Pagamento não encontrado no sistema (pode ser de outro contexto)");
    return new Response("OK", { status: 200, headers: corsHeaders });

  } catch (error) {
    console.error("❌ Erro no webhook:", error);
    return new Response("Erro interno", { status: 500, headers: corsHeaders });
  }
});
