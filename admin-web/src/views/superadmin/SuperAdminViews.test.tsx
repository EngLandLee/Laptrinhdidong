import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { SuperAdminDashboardView } from './SuperAdminDashboardView';
import { VenuesManagementView } from './VenuesManagementView';
import { PartnerAccountsView } from './PartnerAccountsView';
import { venueStore } from '../../store/venueStore';
import { authStore } from '../../store/authStore';

describe('SuperAdmin Views', () => {
  beforeEach(() => {
    venueStore.reset();
    authStore.reset();
  });

  it('SuperAdminDashboardView renders system KPIs and venue counts', () => {
    render(
      <MemoryRouter>
        <SuperAdminDashboardView />
      </MemoryRouter>
    );

    expect(screen.getByText('Tổng Cụm Sân Hoạt Động')).toBeInTheDocument();
    expect(screen.getByText('Tổng Sân Thể Thao')).toBeInTheDocument();
    expect(screen.getByText('Lượt Đặt Sân Hôm Nay')).toBeInTheDocument();
    expect(screen.getByText('Doanh Thu Toàn Sàn')).toBeInTheDocument();
  });

  it('SuperAdminDashboardView displays venue distribution and activity stream', () => {
    render(
      <MemoryRouter>
        <SuperAdminDashboardView />
      </MemoryRouter>
    );

    // Distribution should include venues
    expect(screen.getAllByText(/Tao Đàn/i).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/Bình Thạnh/i).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/Thảo Điền/i).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/Nam Sài Gòn/i).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/Tân Bình/i).length).toBeGreaterThan(0);

    // Activity stream should show recent bookings
    expect(screen.getByText(/SH-8291/i)).toBeInTheDocument();
    expect(screen.getByText(/Nguyễn Văn An/i)).toBeInTheDocument();
  });

  it('VenuesManagementView lists existing venues and allows searching', () => {
    render(
      <MemoryRouter>
        <VenuesManagementView />
      </MemoryRouter>
    );

    expect(screen.getByText(/Tao Đàn/i)).toBeInTheDocument();
    expect(screen.getByText(/Nam Sài Gòn/i)).toBeInTheDocument();

    // Search
    const searchInput = screen.getByPlaceholderText(/Tìm kiếm cụm sân/i);
    fireEvent.change(searchInput, { target: { value: 'Nam Sài Gòn' } });

    expect(screen.getByText(/Nam Sài Gòn/i)).toBeInTheDocument();
    expect(screen.queryByText(/Tao Đàn/i)).not.toBeInTheDocument();
  });

  it('VenuesManagementView allows filtering by football sport', () => {
    render(
      <MemoryRouter>
        <VenuesManagementView />
      </MemoryRouter>
    );

    const footballBtn = screen.getByTestId('filter-sport-football');
    fireEvent.click(footballBtn);

    // Nam Sài Gòn and Tân Bình Arena feature football
    expect(screen.getByText(/Nam Sài Gòn/i)).toBeInTheDocument();
    expect(screen.getByText(/Tân Bình Arena/i)).toBeInTheDocument();
    // Thảo Điền is pickleball only
    expect(screen.queryByText(/Thảo Điền/i)).not.toBeInTheDocument();
  });

  it('VenuesManagementView allows opening Add Venue modal and creating a venue', () => {
    render(
      <MemoryRouter>
        <VenuesManagementView />
      </MemoryRouter>
    );

    const addBtn = screen.getByTestId('btn-add-venue');
    fireEvent.click(addBtn);

    expect(screen.getByText('Thêm Cụm Sân Mới')).toBeInTheDocument();
    fireEvent.change(screen.getByTestId('input-venue-name'), {
      target: { value: 'CLB Cầu Lông Quận 7 VIP' },
    });
    fireEvent.change(screen.getByTestId('input-venue-address'), {
      target: { value: '100 Nguyễn Thị Thập, Q7' },
    });
    fireEvent.change(screen.getByTestId('input-venue-district'), {
      target: { value: 'Quận 7' },
    });
    fireEvent.click(screen.getByTestId('btn-submit-venue'));

    expect(venueStore.getVenues().some((v) => v.name === 'CLB Cầu Lông Quận 7 VIP')).toBe(true);
  });

  it('VenuesManagementView allows toggling venue active status and deleting a venue', () => {
    render(
      <MemoryRouter>
        <VenuesManagementView />
      </MemoryRouter>
    );

    const toggleBtn = screen.getByTestId('toggle-status-venue_01');
    expect(toggleBtn).toBeInTheDocument();
    fireEvent.click(toggleBtn);

    const updated = venueStore.getVenueById('venue_01');
    expect(updated?.isActive).toBe(false);

    // Delete venue
    const deleteBtn = screen.getByTestId('btn-delete-venue_bt_01');
    expect(deleteBtn).toBeInTheDocument();
    fireEvent.click(deleteBtn);

    expect(venueStore.getVenueById('venue_bt_01')).toBeUndefined();
  });

  it('PartnerAccountsView lists partner accounts and handles status toggling', () => {
    render(
      <MemoryRouter>
        <PartnerAccountsView />
      </MemoryRouter>
    );

    expect(screen.getByText('Trần Văn Hùng')).toBeInTheDocument();
    expect(screen.getByText('hung.tran@taodanclub.vn')).toBeInTheDocument();
    expect(screen.getByText('Võ Quốc Anh')).toBeInTheDocument();

    // Toggle status of acc_01
    const toggleBtn = screen.getByTestId('toggle-account-acc_01');
    fireEvent.click(toggleBtn);

    const acc = authStore.getPartnerAccounts().find((a) => a.id === 'acc_01');
    expect(acc?.isActive).toBe(false);
  });

  it('PartnerAccountsView allows creating a new partner account', () => {
    render(
      <MemoryRouter>
        <PartnerAccountsView />
      </MemoryRouter>
    );

    const addAccountBtn = screen.getByTestId('btn-add-account');
    fireEvent.click(addAccountBtn);

    expect(screen.getByText('Cấp tài khoản Chủ Sân mới')).toBeInTheDocument();

    fireEvent.change(screen.getByTestId('input-account-name'), {
      target: { value: 'Hoàng Văn Thao' },
    });
    fireEvent.change(screen.getByTestId('input-account-email'), {
      target: { value: 'thao.hoang@example.com' },
    });
    fireEvent.change(screen.getByTestId('input-account-phone'), {
      target: { value: '0912 345 678' },
    });
    fireEvent.change(screen.getByTestId('select-account-venue'), {
      target: { value: 'venue_01' },
    });

    fireEvent.click(screen.getByTestId('btn-submit-account'));

    expect(
      authStore.getPartnerAccounts().some((a) => a.email === 'thao.hoang@example.com')
    ).toBe(true);
  });
});
