import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { PosCheckinView } from './PosCheckinView';
import { RevenueAnalyticsView } from './RevenueAnalyticsView';
import { venueStore } from '../../store/venueStore';

describe('Partner POS & Revenue Views', () => {
  beforeEach(() => {
    venueStore.reset();
  });

  it('PosCheckinView allows rapid ticket check-in via input and Enter key', () => {
    render(
      <MemoryRouter>
        <PosCheckinView />
      </MemoryRouter>
    );

    expect(venueStore.isCheckedIn('SH-8291')).toBe(false);

    const input = screen.getByPlaceholderText(/Nhập mã vé hoặc quét QR/i);
    fireEvent.change(input, { target: { value: 'SH-8291' } });
    fireEvent.click(screen.getByTestId('btn-rapid-checkin'));

    expect(venueStore.isCheckedIn('SH-8291')).toBe(true);
    expect(screen.getByText(/Check-in thành công vé SH-8291/i)).toBeInTheDocument();
  });

  it('PosCheckinView allows check-in by pressing Enter key on input', () => {
    render(
      <MemoryRouter>
        <PosCheckinView />
      </MemoryRouter>
    );

    expect(venueStore.isCheckedIn('SH-8292')).toBe(false);

    const input = screen.getByPlaceholderText(/Nhập mã vé hoặc quét QR/i);
    fireEvent.change(input, { target: { value: 'SH-8292' } });
    fireEvent.keyDown(input, { key: 'Enter', code: 'Enter' });

    expect(venueStore.isCheckedIn('SH-8292')).toBe(true);
    expect(screen.getByText(/Check-in thành công vé SH-8292/i)).toBeInTheDocument();
  });

  it('PosCheckinView allows check-in of BK- mobile ticket format', () => {
    render(
      <MemoryRouter>
        <PosCheckinView />
      </MemoryRouter>
    );

    expect(venueStore.isCheckedIn('BK-20260907-312')).toBe(false);

    const input = screen.getByPlaceholderText(/Nhập mã vé hoặc quét QR/i);
    fireEvent.change(input, { target: { value: 'BK-20260907-312' } });
    fireEvent.click(screen.getByTestId('btn-rapid-checkin'));

    expect(venueStore.isCheckedIn('BK-20260907-312')).toBe(true);
    expect(screen.getByText(/Check-in thành công vé BK-20260907-312/i)).toBeInTheDocument();
  });

  it('PosCheckinView allows 1-click check-in from today arrivals list', () => {
    render(
      <MemoryRouter>
        <PosCheckinView />
      </MemoryRouter>
    );

    expect(venueStore.isCheckedIn('SH-7714')).toBe(false);

    const checkInBtn = screen.getByTestId('btn-checkin-SH-7714');
    fireEvent.click(checkInBtn);

    expect(venueStore.isCheckedIn('SH-7714')).toBe(true);
    expect(screen.getByText(/Check-in thành công vé SH-7714/i)).toBeInTheDocument();
  });

  it('PosCheckinView calculates add-on product totals and completes checkout', () => {
    render(
      <MemoryRouter>
        <PosCheckinView />
      </MemoryRouter>
    );

    // Initial bill
    expect(screen.getByTestId('pos-bill-total').textContent).toContain('0 đ');

    // Add Pocari (20k)
    fireEvent.click(screen.getByTestId('btn-inc-pocari'));
    expect(screen.getByTestId('pos-bill-total').textContent).toContain('20.000 đ');

    // Add Thuê vợt (50k)
    fireEvent.click(screen.getByTestId('btn-inc-racket'));
    expect(screen.getByTestId('pos-bill-total').textContent).toContain('70.000 đ');

    // Add Aquafina (10k)
    fireEvent.click(screen.getByTestId('btn-inc-water'));
    expect(screen.getByTestId('pos-bill-total').textContent).toContain('80.000 đ');

    // Decrement Aquafina (back to 70k)
    fireEvent.click(screen.getByTestId('btn-dec-water'));
    expect(screen.getByTestId('pos-bill-total').textContent).toContain('70.000 đ');

    // Checkout
    fireEvent.click(screen.getByTestId('btn-pos-checkout'));
    expect(screen.getByTestId('pos-bill-total').textContent).toContain('0 đ');
    expect(screen.getByText(/Thanh toán thành công/i)).toBeInTheDocument();
  });

  it('RevenueAnalyticsView displays 7-day revenue chart and breakdown metrics', () => {
    render(
      <MemoryRouter>
        <RevenueAnalyticsView />
      </MemoryRouter>
    );

    expect(screen.getByText('Doanh thu 7 ngày gần nhất')).toBeInTheDocument();
    expect(screen.getByText('Doanh thu tiền sân')).toBeInTheDocument();
    expect(screen.getByText('Dịch vụ phụ trợ')).toBeInTheDocument();
    expect(screen.getByText('Cầu lông')).toBeInTheDocument();
    expect(screen.getByText('Pickleball')).toBeInTheDocument();
    expect(screen.getByText('Lịch sử giao dịch gần nhất')).toBeInTheDocument();
  });

  it('RevenueAnalyticsView triggers CSV export successfully', () => {
    const urlMock = vi.fn().mockReturnValue('blob:http://localhost/test-export');
    const revokeMock = vi.fn();
    window.URL.createObjectURL = urlMock;
    window.URL.revokeObjectURL = revokeMock;
    const clickSpy = vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => {});

    render(
      <MemoryRouter>
        <RevenueAnalyticsView />
      </MemoryRouter>
    );

    const exportBtn = screen.getByTestId('btn-export-csv');
    fireEvent.click(exportBtn);

    expect(clickSpy).toHaveBeenCalled();
    expect(screen.getByText(/Đã xuất file CSV thành công/i)).toBeInTheDocument();
    clickSpy.mockRestore();
  });
});
