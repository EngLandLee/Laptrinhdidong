import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { AppRoutes } from './App';
import { authStore } from './store/authStore';

describe('App Routing', () => {
  beforeEach(() => {
    authStore.reset();
  });

  it('renders Super Admin dashboard placeholder at /admin', () => {
    authStore.setRole('superadmin');
    render(
      <MemoryRouter initialEntries={['/admin']}>
        <AppRoutes />
      </MemoryRouter>
    );

    expect(screen.getByRole('heading', { name: 'Tổng quan Sàn' })).toBeInTheDocument();
  });

  it('renders Venues management placeholder at /admin/venues', () => {
    authStore.setRole('superadmin');
    render(
      <MemoryRouter initialEntries={['/admin/venues']}>
        <AppRoutes />
      </MemoryRouter>
    );

    expect(screen.getByRole('heading', { name: 'Quản lý Cụm Sân' })).toBeInTheDocument();
  });

  it('renders Accounts management placeholder at /admin/accounts', () => {
    authStore.setRole('superadmin');
    render(
      <MemoryRouter initialEntries={['/admin/accounts']}>
        <AppRoutes />
      </MemoryRouter>
    );

    expect(screen.getByRole('heading', { name: 'Tài khoản Chủ Sân' })).toBeInTheDocument();
  });

  it('renders Partner dashboard placeholder at /partner', () => {
    authStore.setRole('partner');
    render(
      <MemoryRouter initialEntries={['/partner']}>
        <AppRoutes />
      </MemoryRouter>
    );

    expect(screen.getByRole('heading', { name: 'Tổng quan Cụm Sân' })).toBeInTheDocument();
  });

  it('renders Courts management placeholder at /partner/courts', () => {
    authStore.setRole('partner');
    render(
      <MemoryRouter initialEntries={['/partner/courts']}>
        <AppRoutes />
      </MemoryRouter>
    );

    expect(screen.getByRole('heading', { name: 'Quản lý Sân' })).toBeInTheDocument();
  });

  it('renders Schedule master placeholder at /partner/schedule', () => {
    authStore.setRole('partner');
    render(
      <MemoryRouter initialEntries={['/partner/schedule']}>
        <AppRoutes />
      </MemoryRouter>
    );

    expect(screen.getByRole('heading', { name: 'Lịch Sân Master' })).toBeInTheDocument();
  });

  it('renders POS reception placeholder at /partner/pos', () => {
    authStore.setRole('partner');
    render(
      <MemoryRouter initialEntries={['/partner/pos']}>
        <AppRoutes />
      </MemoryRouter>
    );

    expect(screen.getByRole('heading', { name: 'Quầy Lễ Tân & Soát Vé' })).toBeInTheDocument();
  });

  it('renders Revenue report placeholder at /partner/revenue', () => {
    authStore.setRole('partner');
    render(
      <MemoryRouter initialEntries={['/partner/revenue']}>
        <AppRoutes />
      </MemoryRouter>
    );

    expect(screen.getByRole('heading', { name: 'Báo cáo Doanh thu' })).toBeInTheDocument();
  });
});
