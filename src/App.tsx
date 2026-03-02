
import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider } from "@/contexts/AuthContext";
import { StoreProvider } from "@/contexts/StoreContext";
import { SubscriptionProvider } from "@/contexts/SubscriptionContext";
import { NotificationSettingsProvider } from "@/contexts/NotificationSettingsContext";
import { CartProvider } from "@/contexts/CartContext";
import { MercadoPagoProvider } from "@/contexts/MercadoPagoContext";
import ProtectedRoute from "@/components/auth/ProtectedRoute";
import RedirectOldStoreUrl from "@/components/RedirectOldStoreUrl";
import React from "react";

// Admin Pages
import Dashboard from "./pages/admin/Dashboard";
import Products from "./pages/admin/Products";
import Orders from "./pages/admin/Orders";
import Settings from "./pages/admin/Settings";
import Subscription from "./pages/admin/Subscription";
import StoreSetup from "./pages/admin/StoreSetup";
import StoreSelector from "./pages/admin/StoreSelector";
import Auth from "./pages/auth/Auth";

// Customer Pages
import Landing from "./pages/customer/Landing";
import StoreFront from "./pages/customer/StoreFront";
import StoreSlug from "./pages/customer/StoreSlug";
import OrderSuccess from "./pages/customer/OrderSuccess";
import OrderTracking from "./pages/customer/OrderTracking";
import ProductPage from "./pages/customer/ProductPage";

// Subscription Pages
import SubscriptionPlans from "./pages/subscription/SubscriptionPlans";

// Create a new QueryClient instance inside the component
const App = () => {
  // Create a client inside the component function
  const queryClient = new QueryClient();
  
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <StoreProvider>
          <SubscriptionProvider>
            <NotificationSettingsProvider>
              <MercadoPagoProvider>
                <CartProvider>
                  <TooltipProvider>
          <Toaster />
          <Sonner />
          <BrowserRouter>
            <Routes>
              {/* Customer Routes */}
              <Route path="/" element={<Landing />} />
              <Route path="/store" element={<StoreFront />} />
              <Route path="/product/:id" element={<ProductPage />} />
              <Route path="/order-success" element={<OrderSuccess />} />
              <Route path="/track-order" element={<OrderTracking />} />
              
              {/* Redirect old /s/ URLs to new format (must be before /:slug) */}
              <Route path="/s/:slug" element={<RedirectOldStoreUrl />} />
              
              {/* Store slug route (must be last among customer routes) */}
              <Route path="/:slug" element={<StoreSlug />} />
              
              {/* Admin Routes */}
              <Route path="/auth" element={<Auth />} />
              <Route path="/planos" element={<SubscriptionPlans />} />
              <Route path="/store-selector" element={
                <ProtectedRoute requireAdmin>
                  <StoreSelector />
                </ProtectedRoute>
              } />
              <Route path="/store-setup" element={
                <ProtectedRoute requireAdmin>
                  <StoreSetup />
                </ProtectedRoute>
              } />
              <Route path="/admin" element={
                <ProtectedRoute requireAdmin>
                  <Dashboard />
                </ProtectedRoute>
              } />
              <Route path="/admin/products" element={
                <ProtectedRoute requireAdmin>
                  <Products />
                </ProtectedRoute>
              } />
              <Route path="/admin/orders" element={
                <ProtectedRoute requireAdmin>
                  <Orders />
                </ProtectedRoute>
              } />
              <Route path="/admin/settings" element={
                <ProtectedRoute requireAdmin>
                  <Settings />
                </ProtectedRoute>
              } />
              <Route path="/admin/subscription" element={
                <ProtectedRoute requireAdmin>
                  <Subscription />
                </ProtectedRoute>
              } />
              
              {/* Redirect to home page for any undefined routes */}
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </BrowserRouter>
                  </TooltipProvider>
                </CartProvider>
              </MercadoPagoProvider>
            </NotificationSettingsProvider>
          </SubscriptionProvider>
        </StoreProvider>
      </AuthProvider>
    </QueryClientProvider>
  );
};

export default App;
