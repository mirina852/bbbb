/**
 * Serviço de Pagamento do Lojista
 * 
 * Este serviço processa pagamentos de PEDIDOS usando as credenciais
 * do Mercado Pago do LOJISTA (dono do negócio).
 * 
 * O dinheiro dos pedidos cai na conta do LOJISTA.
 */

export interface OrderPaymentData {
  orderId: string;
  amount: number;
  items: Array<{
    id: string;
    title: string;
    quantity: number;
    unit_price: number;
  }>;
  customerEmail: string;
  customerName: string;
}

export interface PaymentResponse {
  id: string;
  status: string;
  detail: string;
  paymentUrl?: string;
  qrCode?: string;
  qrCodeBase64?: string;
}

/**
 * Cria um pagamento de pedido usando o Mercado Pago do lojista
 */
export const createOrderPayment = async (
  data: OrderPaymentData,
  merchantAccessToken: string
): Promise<PaymentResponse> => {
  try {
    // TODO: Implementar integração real com Mercado Pago
    // const response = await fetch('https://api.mercadopago.com/v1/payments', {
    //   method: 'POST',
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': `Bearer ${merchantAccessToken}`
    //   },
    //   body: JSON.stringify({
    //     transaction_amount: data.amount,
    //     description: `Pedido #${data.orderId}`,
    //     payment_method_id: 'pix',
    //     payer: {
    //       email: data.customerEmail,
    //       first_name: data.customerName
    //     },
    //     additional_info: {
    //       items: data.items
    //     }
    //   })
    // });

    // Por enquanto, simular resposta
    console.log('Criando pagamento de pedido (lojista):', data);
    
    return {
      id: `order_${Date.now()}`,
      status: 'pending',
      detail: 'Pagamento criado com sucesso',
      paymentUrl: 'https://mercadopago.com/checkout/...',
      qrCode: '00020126580014br.gov.bcb.pix...',
      qrCodeBase64: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
    };
  } catch (error) {
    console.error('Erro ao criar pagamento de pedido:', error);
    throw new Error('Falha ao processar pagamento do pedido');
  }
};

/**
 * Verifica o status de um pagamento de pedido
 */
export const checkOrderPaymentStatus = async (
  paymentId: string,
  merchantAccessToken: string
): Promise<PaymentResponse> => {
  try {
    // TODO: Implementar verificação real
    // const response = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
    //   headers: {
    //     'Authorization': `Bearer ${merchantAccessToken}`
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
 * Cria um link de pagamento para o cliente
 */
export const createPaymentLink = async (
  data: OrderPaymentData,
  merchantAccessToken: string
): Promise<string> => {
  try {
    // TODO: Implementar criação de link de pagamento
    // const response = await fetch('https://api.mercadopago.com/checkout/preferences', {
    //   method: 'POST',
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': `Bearer ${merchantAccessToken}`
    //   },
    //   body: JSON.stringify({
    //     items: data.items,
    //     payer: {
    //       email: data.customerEmail,
    //       name: data.customerName
    //     },
    //     back_urls: {
    //       success: `${window.location.origin}/order-success`,
    //       failure: `${window.location.origin}/order-failure`,
    //       pending: `${window.location.origin}/order-pending`
    //     },
    //     auto_return: 'approved'
    //   })
    // });

    console.log('Criando link de pagamento:', data);
    
    return 'https://mercadopago.com/checkout/v1/redirect?pref_id=123456789';
  } catch (error) {
    console.error('Erro ao criar link de pagamento:', error);
    throw new Error('Falha ao criar link de pagamento');
  }
};
