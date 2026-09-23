import { useSyncExternalStore } from 'react';
import { UserRole, PartnerAccount } from '../types';
import { INITIAL_PARTNER_ACCOUNTS } from './seedData';

const AUTH_STORAGE_KEY = 'sporthub_auth_store_v1';

export interface AuthStoreState {
  isAuthenticated: boolean;
  role: UserRole;
  activeVenueId: string;
  partnerAccounts: PartnerAccount[];
  staffProfile: {
    name: string;
    title: string;
    avatarUrl?: string;
  };
}

function getInitialAuthState(): AuthStoreState {
  if (typeof window !== 'undefined' && window.localStorage) {
    try {
      const stored = window.localStorage.getItem(AUTH_STORAGE_KEY);
      if (stored) {
        const parsed = JSON.parse(stored);
        if (parsed && parsed.role) {
          return {
            ...parsed,
            isAuthenticated: parsed.isAuthenticated !== undefined ? parsed.isAuthenticated : true,
          };
        }
      }
    } catch {
      // Fall back to default
    }
  }

  return {
    isAuthenticated: true,
    role: 'superadmin',
    activeVenueId: 'venue_01',
    partnerAccounts: JSON.parse(JSON.stringify(INITIAL_PARTNER_ACCOUNTS)),
    staffProfile: {
      name: 'Trần Văn',
      title: 'Quản lý ca',
    },
  };
}

class AuthStoreEngine {
  private state: AuthStoreState = getInitialAuthState();
  private listeners: Set<() => void> = new Set();
  private cachedSnapshot: AuthStoreState = this.state;

  constructor() {
    if (typeof window !== 'undefined') {
      window.addEventListener('storage', (e) => {
        if (e.key === AUTH_STORAGE_KEY && e.newValue) {
          try {
            this.state = JSON.parse(e.newValue);
            this.notify();
          } catch {
            // Ignore parse errors
          }
        }
      });
    }
  }

  private save(): void {
    if (typeof window !== 'undefined' && window.localStorage) {
      try {
        window.localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(this.state));
      } catch (err) {
        console.warn('Failed to save authStore to localStorage', err);
      }
    }
  }

  private notify(): void {
    this.cachedSnapshot = {
      ...this.state,
      partnerAccounts: [...this.state.partnerAccounts],
    };

    if (typeof window !== 'undefined') {
      try {
        window.dispatchEvent(new Event('sporthub_store_change'));
        window.dispatchEvent(new Event('sporthub_auth_store_change'));
      } catch {
        // Ignore in simulated test environment
      }
    }

    this.listeners.forEach((listener) => listener());
  }

  public subscribe = (listener: () => void): (() => void) => {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  };

  public getSnapshot = (): AuthStoreState => {
    return this.cachedSnapshot;
  };

  public reset = (): void => {
    this.state = {
      isAuthenticated: true,
      role: 'superadmin',
      activeVenueId: 'venue_01',
      partnerAccounts: JSON.parse(JSON.stringify(INITIAL_PARTNER_ACCOUNTS)),
      staffProfile: {
        name: 'Trần Văn',
        title: 'Quản lý ca',
      },
    };
    this.save();
    this.notify();
  };

  public isAuthenticated = (): boolean => {
    return this.state.isAuthenticated;
  };

  public login = (email: string, role?: UserRole): boolean => {
    const determinedRole: UserRole =
      role || (email.toLowerCase().includes('partner') ? 'partner' : 'superadmin');
    const isPartner = determinedRole === 'partner';
    this.state.isAuthenticated = true;
    this.state.role = determinedRole;
    this.state.activeVenueId = 'venue_01';
    this.state.staffProfile = {
      name: isPartner ? 'Chủ Sân Tao Đàn' : 'Admin Hệ Thống',
      title: isPartner ? 'Đối tác Quản lý' : 'Super Admin',
    };
    this.save();
    this.notify();
    return true;
  };

  public logout = (): void => {
    this.state.isAuthenticated = false;
    this.save();
    this.notify();
  };

  public getRole = (): UserRole => {
    return this.state.role;
  };

  public setRole = (role: UserRole): void => {
    this.state.role = role;
    this.save();
    this.notify();
  };

  public getActiveVenueId = (): string => {
    return this.state.activeVenueId;
  };

  public setActiveVenueId = (venueId: string): void => {
    this.state.activeVenueId = venueId;
    this.save();
    this.notify();
  };

  public getPartnerAccounts = (): PartnerAccount[] => {
    return this.state.partnerAccounts;
  };

  public addPartnerAccount = (
    account: Omit<PartnerAccount, 'id' | 'createdAt'> & { id?: string }
  ): PartnerAccount => {
    const newAccount: PartnerAccount = {
      id: account.id || `acc_${Date.now()}`,
      fullName: account.fullName,
      email: account.email,
      phone: account.phone,
      venueId: account.venueId,
      venueName: account.venueName,
      role: account.role || 'partner',
      isActive: account.isActive !== undefined ? account.isActive : true,
      createdAt: new Date().toISOString(),
    };

    this.state.partnerAccounts.push(newAccount);
    this.save();
    this.notify();
    return newAccount;
  };

  public toggleAccountStatus = (id: string): boolean => {
    const account = this.state.partnerAccounts.find((a) => a.id === id);
    if (!account) return false;

    account.isActive = !account.isActive;
    this.save();
    this.notify();
    return true;
  };
}

export const authStore = new AuthStoreEngine();

export function useAuthStore() {
  const data = useSyncExternalStore(
    authStore.subscribe,
    authStore.getSnapshot,
    authStore.getSnapshot
  );

  return {
    ...data,
    isAuthenticated: authStore.isAuthenticated,
    login: authStore.login,
    logout: authStore.logout,
    getRole: authStore.getRole,
    setRole: authStore.setRole,
    getActiveVenueId: authStore.getActiveVenueId,
    setActiveVenueId: authStore.setActiveVenueId,
    getPartnerAccounts: authStore.getPartnerAccounts,
    addPartnerAccount: authStore.addPartnerAccount,
    toggleAccountStatus: authStore.toggleAccountStatus,
    reset: authStore.reset,
  };
}
