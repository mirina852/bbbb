import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';

export interface NotificationSettings {
  enabled: boolean;
  duration: number; // em milissegundos
  soundEnabled: boolean;
  soundType: 'default' | 'bell' | 'chime' | 'ping';
  volume: number; // 0 a 1
  repeatCount: number; // quantas vezes repetir o som
}

interface NotificationSettingsContextType {
  settings: NotificationSettings;
  updateSettings: (newSettings: Partial<NotificationSettings>) => void;
  resetSettings: () => void;
}

const defaultSettings: NotificationSettings = {
  enabled: true,
  duration: 8000,
  soundEnabled: true,
  soundType: 'default',
  volume: 0.3,
  repeatCount: 3,
};

const NotificationSettingsContext = createContext<NotificationSettingsContextType | undefined>(undefined);

export const NotificationSettingsProvider = ({ children }: { children: ReactNode }) => {
  const [settings, setSettings] = useState<NotificationSettings>(defaultSettings);

  // Carregar configurações do localStorage quando o componente montar
  useEffect(() => {
    const savedSettings = localStorage.getItem('notificationSettings');
    if (savedSettings) {
      try {
        const parsed = JSON.parse(savedSettings);
        setSettings({ ...defaultSettings, ...parsed });
      } catch (error) {
        console.error('Erro ao carregar configurações de notificação:', error);
      }
    }
  }, []);

  // Salvar configurações no localStorage sempre que mudarem
  useEffect(() => {
    localStorage.setItem('notificationSettings', JSON.stringify(settings));
  }, [settings]);

  const updateSettings = (newSettings: Partial<NotificationSettings>) => {
    setSettings(prev => ({ ...prev, ...newSettings }));
  };

  const resetSettings = () => {
    setSettings(defaultSettings);
  };

  return (
    <NotificationSettingsContext.Provider value={{ settings, updateSettings, resetSettings }}>
      {children}
    </NotificationSettingsContext.Provider>
  );
};

export const useNotificationSettings = () => {
  const context = useContext(NotificationSettingsContext);
  if (context === undefined) {
    throw new Error('useNotificationSettings deve ser usado dentro de um NotificationSettingsProvider');
  }
  return context;
};