import { describe, it, expect, beforeEach } from 'vitest';
import { themeStore } from './themeStore';

describe('themeStore', () => {
  beforeEach(() => {
    localStorage.clear();
    document.documentElement.className = '';
    themeStore.reset();
  });

  it('initializes with light mode by default', () => {
    expect(themeStore.getTheme()).toBe('light');
    expect(themeStore.isDark()).toBe(false);
    expect(document.documentElement.classList.contains('dark')).toBe(false);
  });

  it('toggles from light to dark and applies dark class to documentElement', () => {
    themeStore.toggleTheme();
    expect(themeStore.getTheme()).toBe('dark');
    expect(themeStore.isDark()).toBe(true);
    expect(document.documentElement.classList.contains('dark')).toBe(true);
    expect(localStorage.getItem('sporthub_theme')).toBe('dark');
  });

  it('toggles back from dark to light and removes dark class', () => {
    themeStore.setTheme('dark');
    expect(themeStore.isDark()).toBe(true);
    expect(document.documentElement.classList.contains('dark')).toBe(true);

    themeStore.toggleTheme();
    expect(themeStore.getTheme()).toBe('light');
    expect(themeStore.isDark()).toBe(false);
    expect(document.documentElement.classList.contains('dark')).toBe(false);
    expect(localStorage.getItem('sporthub_theme')).toBe('light');
  });

  it('notifies subscribers on change', () => {
    let callCount = 0;
    const unsubscribe = themeStore.subscribe(() => {
      callCount++;
    });

    themeStore.toggleTheme();
    expect(callCount).toBe(1);

    themeStore.toggleTheme();
    expect(callCount).toBe(2);

    unsubscribe();
    themeStore.toggleTheme();
    expect(callCount).toBe(2);
  });
});
