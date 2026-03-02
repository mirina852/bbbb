import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { 
  Store, 
  ShoppingBag, 
  TrendingUp, 
  Smartphone, 
  Clock, 
  DollarSign,
  CheckCircle,
  Zap,
  Users,
  BarChart3,
  Settings,
  CreditCard,
  ArrowRight,
  Star
} from 'lucide-react';

const Landing = () => {
  const navigate = useNavigate();

  const features = [
    {
      icon: <Store className="h-8 w-8 text-primary" />,
      title: "Loja Online Completa",
      description: "Tenha seu cardápio digital profissional com fotos, descrições e preços atualizados em tempo real."
    },
    {
      icon: <ShoppingBag className="h-8 w-8 text-primary" />,
      title: "Gestão de Pedidos",
      description: "Receba e gerencie pedidos em tempo real com notificações instantâneas e controle de status."
    },
    {
      icon: <Smartphone className="h-8 w-8 text-primary" />,
      title: "100% Mobile",
      description: "Interface otimizada para celular. Seus clientes fazem pedidos de qualquer lugar, a qualquer hora."
    },
    {
      icon: <BarChart3 className="h-8 w-8 text-primary" />,
      title: "Dashboard Completo",
      description: "Acompanhe vendas, produtos mais vendidos e estatísticas do seu negócio em tempo real."
    },
    {
      icon: <Settings className="h-8 w-8 text-primary" />,
      title: "Personalização Total",
      description: "Configure cores, logo, informações de contato e personalize sua loja do seu jeito."
    },
    {
      icon: <Zap className="h-8 w-8 text-primary" />,
      title: "Rápido e Fácil",
      description: "Configure sua loja em minutos. Sem complicação, sem necessidade de conhecimento técnico."
    }
  ];

  const plans = [
    {
      name: "Teste Gratuito",
      price: "R$ 00,00",
      period: "/30 dias",
      description: "Experimente todos os recursos gratuitamente",
      features: [
        "Loja online completa",
        "Gestão de pedidos ilimitados",
        "Dashboard com estatísticas",
        "Suporte por email",
        "Sem necessidade de cartão"
      ],
      badge: "Grátis",
      badgeColor: "bg-green-500",
      highlighted: false
    },
    {
      name: "Plano Start",
      price: "R$ 29,90",
      period: "/mês",
      description: "Ideal para começar seu negócio online",
      features: [
        "Todos os recursos do teste",
        "Pedidos ilimitados",
        "Produtos ilimitados",
        "Suporte prioritário",
        "Atualizações gratuitas",
        "Sem taxa de setup"
      ],
      badge: "Popular",
      badgeColor: "bg-blue-500",
      highlighted: true
    },
    {
      name: "Plano Pro",
      price: "R$ 299,90",
      period: "/ano",
      description: "Economize 2 meses pagando anualmente",
      features: [
        "Todos os recursos do mensal",
        "2 meses grátis",
        "Suporte VIP prioritário",
        "Consultoria de setup",
        "Treinamento personalizado",
        "Recursos exclusivos"
      ],
      badge: "Melhor Valor",
      badgeColor: "bg-purple-500",
      highlighted: false
    }
  ];

  const testimonials = [
    {
      name: "João Silva",
      business: "Burger House",
      text: "Desde que comecei a usar, meus pedidos aumentaram 40%! A plataforma é muito fácil de usar.",
      rating: 5
    },
    {
      name: "Maria Santos",
      business: "Lanchonete da Maria",
      text: "Meus clientes adoram fazer pedidos pelo celular. Economizei tempo e aumentei as vendas!",
      rating: 5
    },
    {
      name: "Carlos Oliveira",
      business: "Hamburgueria Premium",
      text: "Profissional, rápido e eficiente. Recomendo para qualquer dono de lanchonete!",
      rating: 5
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-muted/20">
      {/* Header/Navbar */}
      <header className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Store className="h-8 w-8 text-primary" />
            <span className="text-2xl font-bold">Petisco</span>
          </div>
          <div className="flex items-center gap-4">
            <Button variant="ghost" onClick={() => navigate('/auth')}>
              Entrar
            </Button>
            <Button onClick={() => navigate('/planos')}>
              Começar Grátis
            </Button>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="container mx-auto px-4 py-20 text-center">
        <Badge className="mb-4 text-sm px-4 py-1">
          🚀 Transforme sua lanchonete em um negócio digital
        </Badge>
        <h1 className="text-5xl md:text-6xl font-bold mb-6 bg-gradient-to-r from-primary to-purple-600 bg-clip-text text-transparent">
          Venda Mais com Seu<br />Cardápio Digital
        </h1>
        <p className="text-xl text-muted-foreground mb-8 max-w-2xl mx-auto">
          A plataforma completa para lanchonetes e hamburguerias receberem pedidos online, 
          gerenciarem o negócio e aumentarem as vendas.
        </p>
        <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
          <Button size="lg" className="text-lg h-14 px-8" onClick={() => navigate('/planos')}>
            Começar Teste Grátis
            <ArrowRight className="ml-2 h-5 w-5" />
          </Button>
          <Button size="lg" variant="outline" className="text-lg h-14 px-8" onClick={() => {
            document.getElementById('features')?.scrollIntoView({ behavior: 'smooth' });
          }}>
            Ver Recursos
          </Button>
        </div>
        <p className="text-sm text-muted-foreground mt-4">
          ✓ Sem necessidade de cartão de crédito  ✓ Configure em minutos  ✓ Cancele quando quiser
        </p>
      </section>

      {/* Stats Section */}
      <section className="bg-primary text-primary-foreground py-12">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-center">
            <div>
              <div className="text-4xl font-bold mb-2">500+</div>
              <div className="text-sm opacity-90">Lanchonetes Ativas</div>
            </div>
            <div>
              <div className="text-4xl font-bold mb-2">10k+</div>
              <div className="text-sm opacity-90">Pedidos por Mês</div>
            </div>
            <div>
              <div className="text-4xl font-bold mb-2">4.9★</div>
              <div className="text-sm opacity-90">Avaliação Média</div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="container mx-auto px-4 py-20">
        <div className="text-center mb-12">
          <h2 className="text-4xl font-bold mb-4">Tudo que Você Precisa</h2>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Uma plataforma completa para gerenciar seu negócio e vender mais
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature, index) => (
            <Card key={index} className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <div className="mb-4">{feature.icon}</div>
                <CardTitle className="text-xl">{feature.title}</CardTitle>
              </CardHeader>
              <CardContent>
                <CardDescription className="text-base">{feature.description}</CardDescription>
              </CardContent>
            </Card>
          ))}
        </div>
      </section>

      {/* Pricing Section */}
      <section className="bg-muted/50 py-20">
        <div className="container mx-auto px-4">
          <div className="text-center mb-12">
            <h2 className="text-4xl font-bold mb-4">Planos Transparentes</h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              Escolha o plano ideal para o seu negócio. Sem taxas ocultas.
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-6xl mx-auto">
            {plans.map((plan, index) => (
              <Card 
                key={index} 
                className={`relative ${plan.highlighted ? 'border-2 border-primary shadow-xl scale-105' : ''}`}
              >
                {plan.badge && (
                  <Badge className={`absolute -top-3 left-1/2 -translate-x-1/2 ${plan.badgeColor} text-white`}>
                    {plan.badge}
                  </Badge>
                )}
                <CardHeader className="text-center pb-8">
                  <CardTitle className="text-2xl mb-2">{plan.name}</CardTitle>
                  <div className="mb-2">
                    <span className="text-4xl font-bold">{plan.price}</span>
                    <span className="text-muted-foreground">{plan.period}</span>
                  </div>
                  <CardDescription>{plan.description}</CardDescription>
                </CardHeader>
                <CardContent>
                  <ul className="space-y-3 mb-6">
                    {plan.features.map((feature, fIndex) => (
                      <li key={fIndex} className="flex items-start gap-2">
                        <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0 mt-0.5" />
                        <span className="text-sm">{feature}</span>
                      </li>
                    ))}
                  </ul>
                  <Button 
                    className="w-full" 
                    variant={plan.highlighted ? "default" : "outline"}
                    size="lg"
                    onClick={() => navigate('/planos')}
                  >
                    {index === 0 ? 'Começar Teste Grátis' : 'Assinar Agora'}
                  </Button>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="container mx-auto px-4 py-20">
        <div className="text-center mb-12">
          <h2 className="text-4xl font-bold mb-4">O Que Nossos Clientes Dizem</h2>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Veja como estamos ajudando lanchonetes a crescerem
          </p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-6xl mx-auto">
          {testimonials.map((testimonial, index) => (
            <Card key={index}>
              <CardHeader>
                <div className="flex items-center gap-1 mb-2">
                  {[...Array(testimonial.rating)].map((_, i) => (
                    <Star key={i} className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                  ))}
                </div>
                <CardTitle className="text-lg">{testimonial.name}</CardTitle>
                <CardDescription>{testimonial.business}</CardDescription>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-muted-foreground italic">"{testimonial.text}"</p>
              </CardContent>
            </Card>
          ))}
        </div>
      </section>

      {/* CTA Section */}
      <section className="bg-primary text-primary-foreground py-20">
        <div className="container mx-auto px-4 text-center">
          <h2 className="text-4xl font-bold mb-4">Pronto Para Começar?</h2>
          <p className="text-xl mb-8 opacity-90 max-w-2xl mx-auto">
            Junte-se a centenas de lanchonetes que já estão vendendo mais com nossa plataforma
          </p>
          <Button 
            size="lg" 
            variant="secondary" 
            className="text-lg h-14 px-8"
            onClick={() => navigate('/planos')}
          >
            Começar Teste Grátis de 7 Dias
            <ArrowRight className="ml-2 h-5 w-5" />
          </Button>
          <p className="text-sm mt-4 opacity-75">
            Sem compromisso. Cancele quando quiser.
          </p>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t bg-background py-8">
        <div className="container mx-auto px-4 text-center text-sm text-muted-foreground">
          <p>© 2025 Petisco. Todos os direitos reservados.</p>
          <div className="flex justify-center gap-6 mt-4">
            <a href="#" className="hover:text-foreground transition-colors">Termos de Uso</a>
            <a href="#" className="hover:text-foreground transition-colors">Política de Privacidade</a>
            <a href="#" className="hover:text-foreground transition-colors">Suporte</a>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Landing;
