import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';

export const useRegistrationAllowed = () => {
  const [isAllowed, setIsAllowed] = useState<boolean | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const check = async () => {
      try {
        const { data, error } = await supabase.rpc('is_registration_allowed');
        if (error) throw error;
        setIsAllowed(data as boolean);
      } catch (err) {
        console.error('Error checking registration:', err);
        setIsAllowed(false);
      } finally {
        setIsLoading(false);
      }
    };
    check();
  }, []);

  return { isAllowed, isLoading };
};
