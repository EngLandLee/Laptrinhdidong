import { describe, it, expect, beforeEach } from 'vitest';
import { venueStore } from './venueStore';

describe('venueStore', () => {
  beforeEach(() => {
    venueStore.reset();
  });

  it('initializes with seed venues including Tao Đàn', () => {
    const venues = venueStore.getVenues();
    expect(venues.length).toBeGreaterThanOrEqual(4);
    const taoDan = venues.find(v => v.id === 'venue_01');
    expect(taoDan).toBeDefined();
    expect(taoDan?.name).toContain('Tao Đàn');
  });

  it('allows adding a new sports venue', () => {
    venueStore.addVenue({
      id: 'venue_custom',
      name: 'CLB Cầu Lông Thủ Đức Arena',
      address: '12 Võ Văn Ngân, TP. Thủ Đức',
      district: 'Thủ Đức',
      hotline: '0901 234 567',
      sports: ['badminton', 'pickleball'],
      openTime: '06:00',
      closeTime: '22:00',
      baseHourlyRate: 150000,
      imageUrl: 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
      isActive: true,
    });

    const venue = venueStore.getVenueById('venue_custom');
    expect(venue).toBeDefined();
    expect(venue?.name).toBe('CLB Cầu Lông Thủ Đức Arena');
  });

  it('allows adding a new court to Tao Đàn', () => {
    venueStore.addCourt('venue_01', {
      name: 'Sân Cầu Lông 09',
      sport: 'badminton',
      surfaceType: 'Thảm Yonex Tiêu Chuẩn',
      facilityType: 'indoor',
      regularPrice: 120000,
      peakPrice: 180000,
      isActive: true,
    });

    const courts = venueStore.getCourtsByVenue('venue_01');
    expect(courts.length).toBe(9);
    expect(courts.some(c => c.name === 'Sân Cầu Lông 09')).toBe(true);
  });

  it('allows reserving slot manually and checking in ticket', () => {
    // Reserve slot
    venueStore.reserveSlot('court_01_08_00', {
      customerName: 'Hoàng Long',
      customerPhone: '0912 345 678',
    });

    const slot = venueStore.getSlotById('court_01_08_00');
    expect(slot?.status).toBe('reservedManual');
    expect(slot?.customerName).toBe('Hoàng Long');

    // Check-in pre-seeded ticket SH-8291
    const checkInResult = venueStore.checkInTicket('SH-8291');
    expect(checkInResult).toBe(true);
    expect(venueStore.isCheckedIn('SH-8291')).toBe(true);
  });
});
