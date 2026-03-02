import { useState, useEffect } from 'react';
import { siteSettingsService, SiteSettings } from '@/services/siteSettingsService';

export const useSiteSettings = () => {
  const [settings, setSettings] = useState<SiteSettings | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadSettings = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await siteSettingsService.get();
      setSettings(data);
    } catch (err) {
      console.error('Error loading site settings:', err);
      setError('Erro ao carregar configurações do site');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSettings();
  }, []);

  const refreshSettings = () => {
    loadSettings();
  };

  // Retorna URL de fundo (com fallback)
  const getBackgroundUrl = () => {
    return settings?.background_url || '/lovable-uploads/81716899-6663-41f3-b527-70754a477467.png';
  };

  // Retorna URLs de fundo (com fallback)
  const getBackgroundUrls = () => {
    return settings?.background_urls && settings.background_urls.length > 0 
      ? settings.background_urls 
      : [getBackgroundUrl()];
  };

  // Retorna URL do logo (com fallback nulo)
  const getLogoUrl = () => {
    return settings?.logo_url || null;
  };

  // Retorna título do site (com fallback padrão)
  const getSiteTitle = () => {
    return settings?.site_title || 'Meu Site';
  };

  return {
    settings,
    loading,
    error,
    refreshSettings,
    getBackgroundUrl,
    getBackgroundUrls,
    getLogoUrl,
    getSiteTitle
  };
};
