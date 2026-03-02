/**
 * Serviço de Pagamento da Plataforma
 * 
 * Este serviço processa pagamentos de ASSINATURAS usando as credenciais
 * do Mercado Pago da PLATAFORMA (você).
 * 
 * O dinheiro das assinaturas cai na SUA conta.
 */

// Credenciais da plataforma (devem estar em variáveis de ambiente)
const PLATFORM_PUBLIC_KEY = import.meta.env.VITE_MERCADOPAGO_PUBLIC_KEY || '';
const PLATFORM_ACCESS_TOKEN = import.meta.env.VITE_MERCADOPAGO_ACCESS_TOKEN || '';

export interface SubscriptionPaymentData {
  planId: string;
  planName: string;
  amount: number;
  userId: string;
  userEmail: string;
}

export interface PaymentResponse {
  id: string;
  status: string;
  detail: string;
  paymentUrl?: string;
}

/**
 * Cria um pagamento de assinatura usando o Mercado Pago da plataforma
 */
export const createSubscriptionPayment = async (
  data: SubscriptionPaymentData
): Promise<PaymentResponse> => {
  try {
    // TODO: Implementar integração real com Mercado Pago
    // const response = await fetch('https://api.mercadopago.com/v1/payments', {
    //   method: 'POST',
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': `Bearer ${PLATFORM_ACCESS_TOKEN}`
    //   },
    //   body: JSON.stringify({
    //     transaction_amount: data.amount,
    //     description: `Assinatura ${data.planName}`,
    //     payment_method_id: 'pix',
    //     payer: {
    //       email: data.userEmail
    //     }
    //   })
    // });

    // Por enquanto, simular resposta
    console.log('Criando pagamento de assinatura (plataforma):', data);
    
    return {
      id: `sub_${Date.now()}`,
      status: 'pending',
      detail: 'Pagamento criado com sucesso',
      paymentUrl: 'https://mercadopago.com/checkout/...'
    };
  } catch (error) {
    console.error('Erro ao criar pagamento de assinatura:', error);
    throw new Error('Falha ao processar pagamento da assinatura');
  }
};

/**
 * Verifica o status de um pagamento de assinatura
 */
export const checkSubscriptionPaymentStatus = async (
  paymentId: string
): Promise<PaymentResponse> => {
  try {
    // TODO: Implementar verificação real
    // const response = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
    //   headers: {
    //     'Authorization': `Bearer ${PLATFORM_ACCESS_TOKEN}`
    //   }
    // });

    console.log('Verificando status do pagamento:', paymentId);
    
    return {
      id: paymentId,
      status: 'approved',
      detail: 'Pagamento aprovado'
    };
  } catch (error) {
    console.error('Erro ao verificar pagamento:', error);
    throw new Error('Falha ao verificar status do pagamento');
  }
};

/**
 * Retorna a Public Key da plataforma para inicializar o SDK do Mercado Pago
 */
export const getPlatformPublicKey = (): string => {
  return PLATFORM_PUBLIC_KEY;
};
