import { describe, it, expect, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { PartnerDashboardView } from './PartnerDashboardView';
import { CourtsManagementView } from './CourtsManagementView';
import { ScheduleMatrixView } from './ScheduleMatrixView';
import { venueStore } from '../../store/venueStore';

describe('Partner Schedule & Courts Views', () => {
  beforeEach(() => {
    venueStore.reset();
  });

  it('PartnerDashboardView renders venue KPIs and 8 courts status', () => {
    render(
      <MemoryRouter>
        <PartnerDashboardView />
      </MemoryRouter>
    );

    expect(screen.getByText('Doanh thu hôm nay')).toBeInTheDocument();
    expect(screen.getByText('Số ca đã đặt')).toBeInTheDocument();
    expect(screen.getByText('Tỷ lệ lấp đầy')).toBeInTheDocument();
    expect(screen.getByText('Khách đã check-in')).toBeInTheDocument();
    expect(screen.getByText('Sân Cầu Lông 01')).toBeInTheDocument();
    expect(screen.getByText('Sân Pickleball 05')).toBeInTheDocument();
  });

  it('CourtsManagementView displays 8 courts and allows adding a new court', () => {
    render(
      <MemoryRouter>
        <CourtsManagementView />
      </MemoryRouter>
    );

    expect(screen.getAllByText(/Sân Cầu Lông/i).length).toBeGreaterThanOrEqual(4);
    expect(screen.getAllByText(/Sân Pickleball/i).length).toBeGreaterThanOrEqual(4);

    // Open add court modal
    fireEvent.click(screen.getByTestId('btn-add-court'));
    expect(screen.getByText('Thêm Sân Thể Thao Mới')).toBeInTheDocument();

    fireEvent.change(screen.getByTestId('input-court-name'), {
      target: { value: 'Sân Cầu Lông VIP 05' },
    });
    fireEvent.click(screen.getByTestId('btn-submit-court'));

    expect(venueStore.getCourtsByVenue('venue_01').some(c => c.name === 'Sân Cầu Lông VIP 05')).toBe(true);
  });

  it('ScheduleMatrixView renders matrix cells and allows phone reservation in modal', () => {
    render(
      <MemoryRouter>
        <ScheduleMatrixView />
      </MemoryRouter>
    );

    expect(screen.getByText('Lịch Sân Master')).toBeInTheDocument();
    expect(screen.getByText('06:00')).toBeInTheDocument();
    expect(screen.getByText('21:00')).toBeInTheDocument();

    // Click available cell court 01 at 08:00
    const cell = screen.getByTestId('slot-cell-court_01_08_00');
    fireEvent.click(cell);

    expect(screen.getByText('Quản lý Ca Sân')).toBeInTheDocument();
    fireEvent.change(screen.getByTestId('input-customer-name'), {
      target: { value: 'Trịnh Thăng Bình' },
    });
    fireEvent.change(screen.getByTestId('input-customer-phone'), {
      target: { value: '0988 999 888' },
    });
    fireEvent.click(screen.getByTestId('btn-confirm-reserve'));

    const updated = venueStore.getSlotById('court_01_08_00');
    expect(updated?.status).toBe('reservedManual');
    expect(updated?.customerName).toBe('Trịnh Thăng Bình');
  });

  it('ScheduleMatrixView allows slot price adjustment and maintenance toggle in modal', () => {
    render(
      <MemoryRouter>
        <ScheduleMatrixView />
      </MemoryRouter>
    );

    // Click slot court_01_07_00
    const cell = screen.getByTestId('slot-cell-court_01_07_00');
    fireEvent.click(cell);

    // Switch to Price tab
    fireEvent.click(screen.getByTestId('tab-price'));
    expect(screen.getByText('Điều chỉnh giá ca')).toBeInTheDocument();
    // Select quick chip 150k
    fireEvent.click(screen.getByTestId('price-chip-150000'));
    fireEvent.click(screen.getByTestId('btn-save-price'));

    expect(venueStore.getSlotById('court_01_07_00')?.price).toBe(150000);

    // Click slot court_01_07_00 again to test maintenance tab
    fireEvent.click(screen.getByTestId('slot-cell-court_01_07_00'));
    fireEvent.click(screen.getByTestId('tab-maintenance'));
    fireEvent.change(screen.getByTestId('input-maintenance-reason'), {
      target: { value: 'Sửa bóng đèn' },
    });
    fireEvent.click(screen.getByTestId('btn-lock-maintenance'));

    expect(venueStore.getSlotById('court_01_07_00')?.status).toBe('maintenance');

    // Reopen and unlock
    fireEvent.click(screen.getByTestId('slot-cell-court_01_07_00'));
    fireEvent.click(screen.getByTestId('tab-maintenance'));
    fireEvent.click(screen.getByTestId('btn-unlock-slot'));
    expect(venueStore.getSlotById('court_01_07_00')?.status).toBe('available');
  });

  it('ScheduleMatrixView provides ARIA grid semantics and accessible slot labels', () => {
    render(
      <MemoryRouter>
        <ScheduleMatrixView />
      </MemoryRouter>
    );

    const grid = screen.getByRole('grid', { name: /ma trận lịch sân 16 khung giờ/i });
    expect(grid).toBeInTheDocument();

    const cell = screen.getByTestId('slot-cell-court_01_08_00');
    expect(cell).toHaveAttribute('aria-label');
    expect(cell.getAttribute('aria-label')).toMatch(/Sân Cầu Lông 01/i);
    expect(cell.getAttribute('aria-label')).toMatch(/08:00/);
  });
});
