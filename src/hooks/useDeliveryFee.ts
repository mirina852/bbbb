import { useState, useEffect } from 'react';
import { siteSettingsService } from '@/services/siteSettingsService';

const LS_KEY = 'delivery_fee';

export const useDeliveryFee = () => {
  const [deliveryFee, setDeliveryFee] = useState<number>(5); // Default value
  const [loading, setLoading] = useState(true);

  const loadDeliveryFee = async () => {
    try {
      setLoading(true);

      // 1) Local storage first (instant UI)
      const fromLocal = localStorage.getItem(LS_KEY);
      if (fromLocal !== null) {
        const parsed = parseFloat(fromLocal);
        if (!isNaN(parsed)) setDeliveryFee(parsed);
      }

      // 2) Try DB (if column exists)
      const settings = await siteSettingsService.get();
      if (settings && typeof settings.delivery_fee === 'number') {
        setDeliveryFee(settings.delivery_fee);
        localStorage.setItem(LS_KEY, String(settings.delivery_fee));
      }
    } catch (error) {
      // keep local value
      console.warn('Fallback to local delivery fee due to error:', error);
    } finally {
      setLoading(false);
    }
  };

  const updateDeliveryFee = (newFee: number) => {
    setDeliveryFee(newFee);
    localStorage.setItem(LS_KEY, String(newFee));
  };

  useEffect(() => {
    loadDeliveryFee();
  }, []);

  return {
    deliveryFee,
    loading,
    updateDeliveryFee,
    refreshDeliveryFee: loadDeliveryFee,
  };
};