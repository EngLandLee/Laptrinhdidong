import { useState, useEffect } from 'react';

export type ThemeMode = 'light' | 'dark';

class ThemeStore {
  private theme: ThemeMode = 'light';
  private listeners: Set<() => void> = new Set();

  constructor() {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('sporthub_theme');
      if (saved === 'dark' || saved === 'light') {
        this.theme = saved;
      }
      this.applyTheme();
    }
  }

  private applyTheme() {
    if (typeof document !== 'undefined') {
      if (this.theme === 'dark') {
        document.documentElement.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
      }
    }
  }

  getTheme(): ThemeMode {
    return this.theme;
  }

  isDark(): boolean {
    return this.theme === 'dark';
  }

  setTheme(theme: ThemeMode) {
    this.theme = theme;
    if (typeof window !== 'undefined') {
      localStorage.setItem('sporthub_theme', theme);
    }
    this.applyTheme();
    this.notify();
  }

  toggleTheme() {
    this.setTheme(this.theme === 'dark' ? 'light' : 'dark');
  }

  subscribe(listener: () => void) {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  private notify() {
    this.listeners.forEach((l) => l());
  }

  reset() {
    this.theme = 'light';
    if (typeof window !== 'undefined') {
      localStorage.setItem('sporthub_theme', 'light');
    }
    this.applyTheme();
    this.notify();
  }
}

export const themeStore = new ThemeStore();

export function useThemeStore() {
  const [theme, setTheme] = useState<ThemeMode>(() => themeStore.getTheme());

  useEffect(() => {
    return themeStore.subscribe(() => {
      setTheme(themeStore.getTheme());
    });
  }, []);

  return {
    theme,
    isDarkMode: theme === 'dark',
    toggleTheme: () => themeStore.toggleTheme(),
    setTheme: (t: ThemeMode) => themeStore.setTheme(t),
  };
}
