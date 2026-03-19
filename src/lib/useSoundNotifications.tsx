import { useState, useEffect } from 'react';

export type SoundOption = 'A' | 'B' | 'C' | 'D';

interface SoundNotificationSettings {
  isEnabled: boolean;
  volume: number;
  soundOption: SoundOption;
}

const DEFAULT_SETTINGS: SoundNotificationSettings = {
  isEnabled: true,
  volume: 85,
  soundOption: 'D', // Default: Urgent Order Alarm (Loud)
};

const STORAGE_KEY = 'muj-foodie-sound-settings';

export const useSoundNotifications = () => {
  const [settings, setSettings] = useState<SoundNotificationSettings>(DEFAULT_SETTINGS);
  const [isLoaded, setIsLoaded] = useState(false);

  // Load settings from localStorage on mount
  useEffect(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        const parsed = JSON.parse(stored);
        setSettings({ ...DEFAULT_SETTINGS, ...parsed });
      }
    } catch (error) {
      console.error('Failed to load sound settings:', error);
    } finally {
      setIsLoaded(true);
    }
  }, []);

  // Save settings to localStorage whenever they change
  useEffect(() => {
    if (isLoaded) {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(settings));
      } catch (error) {
        console.error('Failed to save sound settings:', error);
      }
    }
  }, [settings, isLoaded]);

  const toggleSound = (enabled: boolean) => {
    setSettings(prev => ({ ...prev, isEnabled: enabled }));
  };

  const setVolume = (volume: number) => {
    setSettings(prev => ({ ...prev, volume }));
  };

  const setSoundOption = (option: SoundOption) => {
    setSettings(prev => ({ ...prev, soundOption: option }));
  };

  const resetSettings = () => {
    setSettings(DEFAULT_SETTINGS);
  };

  return {
    settings,
    isEnabled: settings.isEnabled,
    volume: settings.volume,
    soundOption: settings.soundOption,
    toggleSound,
    setVolume,
    setSoundOption,
    resetSettings,
    isLoaded,
  };
};
