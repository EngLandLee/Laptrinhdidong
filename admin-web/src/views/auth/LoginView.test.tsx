import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { LoginView } from './LoginView';
import { authStore } from '../../store/authStore';

describe('LoginView', () => {
  beforeEach(() => {
    authStore.reset();
    authStore.logout();
  });

  it('renders login form with inputs and quick login options', () => {
    render(
      <MemoryRouter>
        <LoginView />
      </MemoryRouter>
    );

    expect(screen.getAllByText(/SportHub/i).length).toBeGreaterThanOrEqual(1);
    expect(screen.getByText(/Portal/i)).toBeInTheDocument();
    expect(screen.getByText(/Đăng nhập Hệ thống Quản trị/i)).toBeInTheDocument();
    expect(screen.getByTestId('input-login-email')).toBeInTheDocument();
    expect(screen.getByTestId('input-login-password')).toBeInTheDocument();
    expect(screen.getByTestId('btn-submit-login')).toBeInTheDocument();
    expect(screen.getByTestId('btn-quick-admin')).toBeInTheDocument();
    expect(screen.getByTestId('btn-quick-partner')).toBeInTheDocument();
  });

  it('allows quick login as Super Admin', () => {
    render(
      <MemoryRouter>
        <LoginView />
      </MemoryRouter>
    );

    fireEvent.click(screen.getByTestId('btn-quick-admin'));
    expect(authStore.isAuthenticated()).toBe(true);
    expect(authStore.getRole()).toBe('superadmin');
  });

  it('allows quick login as Partner Club Owner', () => {
    render(
      <MemoryRouter>
        <LoginView />
      </MemoryRouter>
    );

    fireEvent.click(screen.getByTestId('btn-quick-partner'));
    expect(authStore.isAuthenticated()).toBe(true);
    expect(authStore.getRole()).toBe('partner');
  });

  it('allows manual credentials login', () => {
    render(
      <MemoryRouter>
        <LoginView />
      </MemoryRouter>
    );

    fireEvent.change(screen.getByTestId('input-login-email'), {
      target: { value: 'taodan@partner.sporthub.vn' },
    });
    fireEvent.change(screen.getByTestId('input-login-password'), {
      target: { value: 'password123' },
    });
    fireEvent.click(screen.getByTestId('btn-submit-login'));

    expect(authStore.isAuthenticated()).toBe(true);
    expect(authStore.getRole()).toBe('partner');
  });
});
