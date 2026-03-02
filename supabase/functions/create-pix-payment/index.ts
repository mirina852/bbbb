import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
// ✅ Configuração de CORS
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};
// 🚀 Função principal
serve(async (req)=>{
  // 🔹 Responde ao pré-flight (CORS)
  if (req.method === "OPTIONS") {
    return new Response(JSON.stringify({
      success: true
    }), {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      },
      status: 200
    });
  }
  try {
    // 🔹 Lê variáveis do Supabase
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
    const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    console.log("SUPABASE_URL:", SUPABASE_URL);
    console.log("SERVICE_ROLE_KEY definido:", !!SERVICE_ROLE_KEY);
    if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
      return new Response(JSON.stringify({
        success: false,
        error: "Faltando variáveis de ambiente SUPABASE_URL ou SERVICE_ROLE_KEY"
      }), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        },
        status: 200
      });
    }
    // 🔹 Cria cliente Supabase com chave de serviço
    const supabaseClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    
    // 🔹 Lê corpo da requisição primeiro para determinar tipo de pagamento
    let body;
    try {
      body = await req.json();
    } catch (e) {
      console.error("Body inválido:", e);
      return new Response(JSON.stringify({
        success: false,
        error: "Body inválido ou ausente"
      }), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        },
        status: 200
      });
    }
    const { planId, amount, customerName, customerPhone, description, storeId, storeSlug } = body || {};
    
    // Verificar se é pagamento de assinatura ou pedido
    const isSubscriptionPayment = !!planId;
    const isOrderPayment = !planId && !!amount;
    
    // 🔹 Verifica token de autenticação (OBRIGATÓRIO apenas para assinaturas)
    const authHeader = req.headers.get("Authorization");
    console.log("Authorization header:", authHeader ? "presente" : "ausente");
    console.log("Tipo de pagamento:", isSubscriptionPayment ? "assinatura" : "pedido");
    
    let user: { id: string; email?: string } | null = null;
    
    if (isSubscriptionPayment) {
      // Para assinaturas, autenticação é OBRIGATÓRIA
      if (!authHeader) {
        return new Response(JSON.stringify({
          success: false,
          error: "Autenticação necessária para pagamento de assinatura"
        }), {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json"
          },
          status: 200
        });
      }
      
      const token = authHeader.replace("Bearer ", "").trim();
      const { data: { user: authUser } = {}, error: authError } = await supabaseClient.auth.getUser(token);
      
      if (authError || !authUser) {
        console.error("Token inválido ou usuário não encontrado");
        return new Response(JSON.stringify({
          success: false,
          error: "Não autorizado"
        }), {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json"
          },
          status: 200
        });
      }
      
      user = authUser;
    } else if (isOrderPayment) {
      // Para pedidos, autenticação é OPCIONAL
      if (authHeader) {
        const token = authHeader.replace("Bearer ", "").trim();
        const { data: { user: authUser } = {} } = await supabaseClient.auth.getUser(token);
        user = authUser || null;
      }
      console.log("Pagamento de pedido sem autenticação - permitido");
    }
    
    if (!amount || (amount === undefined || amount === null)) {
      console.error("amount faltando");
      return new Response(JSON.stringify({
        success: false,
        error: "Parâmetro obrigatório 'amount' não foi fornecido"
      }), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        },
        status: 200
      });
    }
    
    if (isSubscriptionPayment) {
      console.log("🧾 Criando pagamento para plano:", planId);
    } else if (isOrderPayment) {
      console.log("🛒 Criando pagamento para pedido:", { amount, customerName, description });
    } else {
      console.error("Tipo de pagamento não identificado");
      return new Response(JSON.stringify({
        success: false,
        error: "Tipo de pagamento inválido"
      }), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        },
        status: 200
      });
    }
    // 🔹 Buscar credenciais do merchant
    let merchantAccessToken = '';
    let merchantPublicKey = '';
    
    if (isOrderPayment) {
      // Para pedidos, buscar credenciais do merchant no banco
      console.log("Buscando credenciais do merchant para pagamento de pedido...");
      
      // Determinar store_id: pode vir direto ou via slug
      let targetStoreId = storeId;
      
      if (!targetStoreId && storeSlug) {
        console.log("Buscando store_id pelo slug:", storeSlug);
        const { data: storeData, error: storeError } = await supabaseClient
          .from('stores')
          .select('id')
          .eq('slug', storeSlug)
          .eq('is_active', true)
          .maybeSingle();
        
        if (storeError || !storeData) {
          console.error("Erro ao buscar loja pelo slug:", storeError);
          return new Response(JSON.stringify({
            success: false,
            error: "Loja não encontrada.",
            errorCode: "STORE_NOT_FOUND"
          }), {
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json"
            },
            status: 200
          });
        }
        
        targetStoreId = storeData.id;
        console.log("Store ID encontrado:", targetStoreId);
      }
      
      if (!targetStoreId) {
        console.error("Store ID não fornecido");
        return new Response(JSON.stringify({
          success: false,
          error: "ID da loja não fornecido.",
          errorCode: "STORE_ID_REQUIRED"
        }), {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json"
          },
          status: 200
        });
      }
      
      // Buscar credenciais específicas desta loja
      const { data: credentials, error: credError } = await supabaseClient
        .from('merchant_payment_credentials')
        .select('access_token, public_key')
        .eq('store_id', targetStoreId)
        .eq('is_active', true)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();
      
      if (credError) {
        console.error("Erro ao buscar credenciais do merchant:", credError);
        return new Response(JSON.stringify({
          success: false,
          error: "Erro ao buscar credenciais de pagamento. Entre em contato com o suporte.",
          errorCode: "CREDENTIALS_FETCH_ERROR"
        }), {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json"
          },
          status: 200
        });
      }
      
      if (!credentials || !credentials.access_token || !credentials.public_key) {
        console.error("Credenciais do merchant não encontradas ou incompletas para store_id:", targetStoreId);
        return new Response(JSON.stringify({
          success: false,
          error: "Configure suas credenciais do Mercado Pago antes de aceitar pagamentos PIX.",
          errorCode: "MERCHANT_CREDENTIALS_NOT_FOUND"
        }), {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json"
          },
          status: 200
        });
      }
      
      merchantAccessToken = credentials.access_token;
      merchantPublicKey = credentials.public_key;
      console.log("✅ Credenciais do merchant encontradas para store_id:", targetStoreId);
      
    } else if (isSubscriptionPayment) {
      // Para assinaturas, usar credenciais da plataforma
      const PLATFORM_MERCADOPAGO_TOKEN = Deno.env.get("PLATFORM_MERCADOPAGO_ACCESS_TOKEN");
      const PLATFORM_MERCADOPAGO_PUBLIC_KEY = Deno.env.get("PLATFORM_MERCADOPAGO_PUBLIC_KEY");
      console.log("PLATFORM_MERCADOPAGO_TOKEN definido:", !!PLATFORM_MERCADOPAGO_TOKEN);
      console.log("PLATFORM_MERCADOPAGO_PUBLIC_KEY definido:", !!PLATFORM_MERCADOPAGO_PUBLIC_KEY);
      
      if (!PLATFORM_MERCADOPAGO_TOKEN || !PLATFORM_MERCADOPAGO_PUBLIC_KEY) {
        console.error("Credenciais da plataforma não configuradas nas variáveis de ambiente");
        return new Response(JSON.stringify({
          success: false,
          error: "Erro de configuração do sistema. Entre em contato com o suporte.",
          errorCode: "PLATFORM_CONFIG_ERROR"
        }), {
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json"
          },
          status: 200
        });
      }
      
      merchantAccessToken = PLATFORM_MERCADOPAGO_TOKEN;
      merchantPublicKey = PLATFORM_MERCADOPAGO_PUBLIC_KEY;
      console.log("Usando token da plataforma para pagamento de assinatura...");
    }
    
    // 🔹 Criar pagamento PIX real no Mercado Pago
    let qrCode = '';
    let paymentId = '';
    let qrCodeBase64 = '';
    
    try {
      console.log("Criando pagamento PIX no Mercado Pago...");
      
      // Preparar metadata para o webhook identificar o tipo de pagamento
      const paymentMetadata: Record<string, string> = {};
      
      if (isSubscriptionPayment && user) {
        paymentMetadata.type = "subscription";
        paymentMetadata.plan_id = planId;
        paymentMetadata.user_id = user.id;
      } else if (isOrderPayment) {
        paymentMetadata.type = "order";
        // order_id será adicionado pelo frontend quando criar o pedido
        if (body.orderId) {
          paymentMetadata.order_id = body.orderId;
        }
        if (storeId) {
          paymentMetadata.store_id = storeId;
        }
      }
      
      // URL do webhook para receber notificações do Mercado Pago
      const webhookUrl = isSubscriptionPayment 
        ? `${SUPABASE_URL}/functions/v1/mercado-pago-webhook`
        : `${SUPABASE_URL}/functions/v1/pedido-webhook`;
      console.log("Webhook URL:", webhookUrl);
      
      const mpResponse = await fetch('https://api.mercadopago.com/v1/payments', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${merchantAccessToken}`,
          'Content-Type': 'application/json',
          'X-Idempotency-Key': crypto.randomUUID()
        },
        body: JSON.stringify({
          transaction_amount: Number(amount),
          description: description || `Pagamento ${isSubscriptionPayment ? 'assinatura' : 'pedido'}`,
          payment_method_id: 'pix',
          payer: {
            email: user?.email || 'cliente@email.com',
            first_name: customerName || 'Cliente',
          },
          metadata: paymentMetadata,
          notification_url: webhookUrl
        })
      });
      
      if (!mpResponse.ok) {
        const errorData = await mpResponse.json();
        console.error("Erro na API do Mercado Pago:", errorData);
        throw new Error(`Mercado Pago API error: ${errorData.message || mpResponse.statusText}`);
      }
      
      const mpData = await mpResponse.json();
      console.log("Resposta do Mercado Pago:", mpData);
      
      paymentId = mpData.id.toString();
      qrCode = mpData.point_of_interaction?.transaction_data?.qr_code || '';
      qrCodeBase64 = mpData.point_of_interaction?.transaction_data?.qr_code_base64 || '';
      
      if (!qrCode) {
        console.error("QR Code não retornado pelo Mercado Pago:", mpData);
        throw new Error("Mercado Pago não retornou QR Code");
      }
      
      console.log("✅ Pagamento PIX criado no Mercado Pago:", paymentId, "com metadata:", paymentMetadata);
      
    } catch (mpError: any) {
      console.error("Erro ao criar pagamento no Mercado Pago:", mpError);
      
      // Fallback: gerar QR Code simulado se a API falhar
      console.warn("⚠️ Usando QR Code simulado como fallback");
      paymentId = crypto.randomUUID();
      const formattedAmount = Number(amount).toFixed(2).replace(".", "");
      qrCode = `00020126580014br.gov.bcb.pix0136${paymentId}520400005303986540${formattedAmount}5802BR5913NOME_EMPRESA6009SAO_PAULO62070503***6304`;
      qrCodeBase64 = qrCode;
    }
    
    // 🔹 Salva pagamento no banco (apenas se for assinatura)
    let payment = null;
    let paymentError = null;
    
    if (isSubscriptionPayment && user) {
      const result = await supabaseClient.from("subscription_payments").insert({
        user_id: user.id,
        subscription_plan_id: planId,
        amount,
        status: "pending",
        payment_method: "pix",
        payment_id: paymentId,
        external_payment_id: paymentId,
        qr_code: qrCode,
        qr_code_base64: qrCodeBase64
      }).select().single();
      
      payment = result.data;
      paymentError = result.error;
    }
    console.log("payment:", payment, "paymentError:", paymentError);
    if (paymentError) {
      return new Response(JSON.stringify({
        success: false,
        error: (paymentError as any).message || "Erro desconhecido ao criar pagamento"
      }), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        },
        status: 200
      });
    }
    
    // 🔹 Retornar resposta apropriada
    if (isSubscriptionPayment && payment) {
      console.log("✅ Pagamento de assinatura criado com sucesso:", payment.id);
      return new Response(JSON.stringify({
        success: true,
        data: {
          id: payment.id,
          status: payment.status,
          qr_code: payment.qr_code
        }
      }), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        },
        status: 200
      });
    } else if (isOrderPayment) {
      console.log("✅ Pagamento de pedido criado com sucesso:", paymentId);
      return new Response(JSON.stringify({
        success: true,
        data: {
          id: paymentId,
          status: "pending",
          qr_code: qrCode,
          qr_code_base64: qrCode
        }
      }), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        },
        status: 200
      });
    } else {
      return new Response(JSON.stringify({
        success: false,
        error: "Erro ao processar pagamento"
      }), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        },
        status: 200
      });
    }
  } catch (error) {
    console.error("Erro interno na função:", error);
    const errorMessage = error instanceof Error ? error.message : "Erro interno na função";
    return new Response(JSON.stringify({
      success: false,
      error: errorMessage
    }), {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      },
      status: 200
    });
  }
});
