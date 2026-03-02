# 🚀 Como Fazer Deploy da Função Atualizada

## ⚠️ Problema Atual

A mensagem de erro **"Configure seu token do Mercado Pago"** aparece porque a **versão antiga** da função ainda está rodando no Supabase.

A versão nova (que não pede credenciais do usuário) está no seu código local, mas precisa ser enviada para o Supabase.

---

## ✅ Solução: Deploy Manual via Dashboard

### Passo 1: Acessar o Dashboard do Supabase

1. Acesse: https://supabase.com/dashboard
2. Faça login na sua conta
3. Selecione seu projeto

### Passo 2: Ir para Edge Functions

1. No menu lateral, clique em **"Edge Functions"**
2. Procure pela função **"create-pix-payment"**

### Passo 3: Atualizar o Código

**Opção A - Editar Diretamente:**

1. Clique na função "create-pix-payment"
2. Clique em "Edit" ou "Code"
3. Cole o código atualizado (veja abaixo)
4. Clique em "Deploy"

**Opção B - Deletar e Recriar:**

1. Delete a função "create-pix-payment"
2. Clique em "New Function"
3. Nome: `create-pix-payment`
4. Cole o código atualizado (veja abaixo)
5. Clique em "Deploy"

### Passo 4: Configurar Variáveis de Ambiente

Antes de fazer o deploy, configure as variáveis:

1. Vá em **"Edge Functions"** → **"Secrets"** (ou "Environment Variables")
2. Adicione:

```
MERCADOPAGO_ACCESS_TOKEN=seu_token_aqui
MERCADOPAGO_PUBLIC_KEY=sua_chave_aqui
```

3. Salve

---

## 📄 Código Atualizado da Função

Copie este código completo e cole no dashboard:

\`\`\`typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  }

  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
    const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    console.log("SUPABASE_URL:", SUPABASE_URL);
    console.log("SERVICE_ROLE_KEY definido:", !!SERVICE_ROLE_KEY);

    if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Faltando variáveis de ambiente SUPABASE_URL ou SERVICE_ROLE_KEY",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    const supabaseClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: "Token de autorização não fornecido" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: userData, error: userError } = await supabaseClient.auth.getUser(token);

    if (userError || !userData?.user) {
      console.error("Erro ao validar usuário:", userError);
      return new Response(
        JSON.stringify({ success: false, error: "Usuário não autenticado" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    const user = userData.user;
    console.log("Usuário autenticado:", user.id);

    const { planId, amount, description } = await req.json();
    console.log("Dados recebidos:", { planId, amount, description });

    if (!planId || !amount) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Parâmetros obrigatórios planId e amount não foram fornecidos",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    console.log("Criando pagamento para plano:", planId);

    // ✅ Para pagamentos de ASSINATURA, usar credenciais do SISTEMA (plataforma)
    // As credenciais do usuário são apenas para receber pagamentos dos CLIENTES dele
    const PLATFORM_MERCADOPAGO_TOKEN = Deno.env.get("MERCADOPAGO_ACCESS_TOKEN");
    const PLATFORM_MERCADOPAGO_PUBLIC_KEY = Deno.env.get("MERCADOPAGO_PUBLIC_KEY");

    console.log("PLATFORM_MERCADOPAGO_TOKEN definido:", !!PLATFORM_MERCADOPAGO_TOKEN);
    console.log("PLATFORM_MERCADOPAGO_PUBLIC_KEY definido:", !!PLATFORM_MERCADOPAGO_PUBLIC_KEY);

    if (!PLATFORM_MERCADOPAGO_TOKEN || !PLATFORM_MERCADOPAGO_PUBLIC_KEY) {
      console.error("Credenciais da plataforma não configuradas nas variáveis de ambiente");
      return new Response(
        JSON.stringify({
          success: false,
          error: "Erro de configuração do sistema. Entre em contato com o suporte.",
          errorCode: "PLATFORM_CONFIG_ERROR",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    const merchantToken = PLATFORM_MERCADOPAGO_TOKEN;
    console.log("Usando token da plataforma para pagamento de assinatura");

    const paymentId = crypto.randomUUID();
    const formattedAmount = Number(amount).toFixed(2).replace(".", "");

    // ⚠️ Aqui pode ir a integração real com API do Mercado Pago
    const qrCode = \`00020126580014br.gov.bcb.pix0136\${paymentId}520400005303986540\${formattedAmount}5802BR5913NOME_EMPRESA6009SAO_PAULO62070503***6304\`;

    const { data: payment, error: paymentError } = await supabaseClient
      .from("subscription_payments")
      .insert({
        user_id: user.id,
        plan_id: planId,
        amount: amount,
        status: "pending",
        qr_code: qrCode,
        qr_code_base64: qrCode,
        payment_id: paymentId,
      })
      .select()
      .single();

    if (paymentError) {
      console.error("Erro ao criar pagamento:", paymentError);
      return new Response(
        JSON.stringify({
          success: false,
          error: \`Erro ao criar pagamento: \${paymentError.message}\`,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    console.log("Pagamento criado com sucesso:", payment);

    return new Response(
      JSON.stringify({
        success: true,
        data: {
          id: payment.id,
          payment_id: paymentId,
          qr_code: qrCode,
          qr_code_base64: qrCode,
          amount: amount,
          status: "pending",
        },
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (error) {
    console.error("Erro geral:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Erro desconhecido",
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  }
});
\`\`\`

---

## 🧪 Testar Após Deploy

1. **Limpe o cache** do navegador (Ctrl + Shift + Delete)
2. **Recarregue** a página de planos
3. **Tente** escolher um plano novamente
4. **Verifique:**
   - ✅ Não deve mais pedir credenciais do usuário
   - ✅ QR Code deve aparecer
   - ✅ Erro diferente se houver (ex: variáveis não configuradas)

---

## 🔍 Verificar Logs

Para ver se está funcionando:

1. No dashboard do Supabase
2. Vá em **"Edge Functions"** → **"create-pix-payment"**
3. Clique em **"Logs"**
4. Tente criar um pagamento
5. Veja os logs em tempo real

Procure por:
- ✅ `"Usando token da plataforma para pagamento de assinatura"`
- ❌ `"Credenciais da plataforma não configuradas"` (se aparecer, configure as variáveis)

---

## 📝 Checklist

- [ ] Acessei o dashboard do Supabase
- [ ] Encontrei a função "create-pix-payment"
- [ ] Configurei as variáveis de ambiente (MERCADOPAGO_ACCESS_TOKEN e MERCADOPAGO_PUBLIC_KEY)
- [ ] Atualizei o código da função
- [ ] Fiz o deploy
- [ ] Limpei o cache do navegador
- [ ] Testei criar um pagamento
- [ ] Verifiquei os logs

---

## ❓ Ainda com Erro?

Se após o deploy ainda aparecer o erro:

1. **Verifique os logs** da função
2. **Confirme** que as variáveis de ambiente estão configuradas
3. **Teste** com o console do navegador aberto (F12) para ver os erros
4. **Compartilhe** os logs para análise
