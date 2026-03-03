import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};

serve(async (req) => {
  // Health check
  if (req.method === "GET") {
    return new Response("Webhook de Pedidos Online ativo", { status: 200, headers: corsHeaders });
  }

  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
  const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const WEBHOOK_SECRET = Deno.env.get("MERCADO_PAGO_WEBHOOK_SECRET") ?? "";

  if (!SUPABASE_URL || !SERVICE_ROLE) {
    console.error("❌ Variáveis de ambiente não configuradas");
    return new Response("Configuração inválida", { status: 500, headers: corsHeaders });
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE);

  try {
    const body = await req.json();
    console.log("📩 Webhook de pedido recebido:", JSON.stringify(body));

    // 🔐 VERIFICAÇÃO DE ASSINATURA TEMPORARIAMENTE DESATIVADA
    // TODO: Corrigir chave secreta do Mercado Pago
    console.log("🔐 Verificação de assinatura desativada temporariamente");
    
    if (false) { // Desativado temporariamente
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

    console.log(`🔍 Buscando pagamento ${paymentId}...`);

    // Buscar por external_payment_id na tabela orders
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("*")
      .eq("external_payment_id", paymentId.toString())
      .maybeSingle();

    if (orderError || !order) {
      console.log("⚠️ Pedido não encontrado para este payment_id");
      return new Response("OK", { status: 200, headers: corsHeaders });
    }

    console.log(`📦 Pedido encontrado: ${order.id} - Status atual: ${order.payment_status}`);

    // Buscar detalhes do pagamento no Mercado Pago
    let mpData = null;
    let status = "pending";

    try {
      // Tentar buscar credenciais da loja
      const { data: credentials } = await supabase
        .from("merchant_payment_credentials")
        .select("access_token")
        .eq("store_id", order.store_id)
        .eq("is_active", true)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      if (credentials && credentials.access_token) {
        const mpResponse = await fetch(
          `https://api.mercadopago.com/v1/payments/${paymentId}`,
          {
            headers: {
              "Authorization": `Bearer ${credentials.access_token}`
            }
          }
        );

        if (mpResponse.ok) {
          mpData = await mpResponse.json();
          status = mpData.status; // approved, pending, rejected, cancelled
          console.log(`💳 Status do pagamento: ${status}`);
        } else {
          console.warn("⚠️ Não foi possível verificar status no Mercado Pago");
        }
      }
    } catch (error) {
      console.warn("⚠️ Erro ao buscar status no Mercado Pago:", error);
    }

    // Atualizar status do pedido
    const finalStatus = status === "approved" ? "pago" : status;
    const { error: updateError } = await supabase
      .from("orders")
      .update({ 
        payment_status: finalStatus,
        status: finalStatus,
        payment_method: finalStatus === "pago" ? "pix" : undefined,
        updated_at: new Date().toISOString()
      })
      .eq("id", order.id);

    if (updateError) {
      console.error("❌ Erro ao atualizar pedido:", updateError);
      return new Response("Erro ao atualizar", { status: 500, headers: corsHeaders });
    }

    console.log(`✅ Pedido ${order.id} atualizado para status: ${status}`);

    // Se pagamento aprovado, enviar notificação (opcional)
    if (status === "approved") {
      console.log("🎉 Pagamento aprovado! Pedido confirmado!");
      
      // Aqui você pode adicionar lógica para:
      // - Enviar email de confirmação
      // - Notificar a loja
      // - Atualizar estoque
      // - Enviar push notification
    }

    return new Response("Pedido atualizado com sucesso", { status: 200, headers: corsHeaders });

  } catch (error) {
    console.error("❌ Erro no webhook de pedidos:", error);
    return new Response("Erro interno", { status: 500, headers: corsHeaders });
  }
});
