import { describe, it, expect, beforeEach } from 'vitest';
import { authStore } from './authStore';

describe('authStore', () => {
  beforeEach(() => {
    authStore.reset();
  });

  it('initializes with superadmin role and Tao Đàn as active venue', () => {
    expect(authStore.getRole()).toBe('superadmin');
    expect(authStore.getActiveVenueId()).toBe('venue_01');
    expect(authStore.getPartnerAccounts().length).toBeGreaterThanOrEqual(4);
  });

  it('allows switching between superadmin and partner roles', () => {
    authStore.setRole('partner');
    expect(authStore.getRole()).toBe('partner');

    authStore.setRole('superadmin');
    expect(authStore.getRole()).toBe('superadmin');
  });

  it('allows adding a new partner account and toggling status', () => {
    const newAcc = authStore.addPartnerAccount({
      fullName: 'Võ Minh Quân',
      email: 'quan.vo@example.com',
      phone: '0909 888 777',
      venueId: 'venue_01',
      venueName: 'CLB Cầu Lông Tao Đàn',
      role: 'partner',
      isActive: true,
    });

    expect(newAcc.id).toBeDefined();
    expect(authStore.getPartnerAccounts().some((a) => a.id === newAcc.id)).toBe(true);

    const toggleResult = authStore.toggleAccountStatus(newAcc.id);
    expect(toggleResult).toBe(true);
    const updated = authStore.getPartnerAccounts().find((a) => a.id === newAcc.id);
    expect(updated?.isActive).toBe(false);
  });

  it('allows logging out and logging in with role assignment', () => {
    expect(authStore.isAuthenticated()).toBe(true);

    authStore.logout();
    expect(authStore.isAuthenticated()).toBe(false);

    const loginSuccess = authStore.login('partner@taodan.vn', 'partner');
    expect(loginSuccess).toBe(true);
    expect(authStore.isAuthenticated()).toBe(true);
    expect(authStore.getRole()).toBe('partner');
  });
});
