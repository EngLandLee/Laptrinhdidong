import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/court_sport_partition.dart';
import 'package:sporthub/core/utils/seed_data.dart';

void main() {
  group('CourtSportPartition Tests', () {
    test('Tan Binh Arena (10 courts, 3 sports) partitions correctly', () {
      final venue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_tb_05');

      // Courts 1-4: Badminton
      for (int c = 1; c <= 4; c++) {
        expect(CourtSportPartition.getSportForCourt(venue: venue, courtNumber: c), 'badminton');
      }

      // Courts 5-7: Pickleball
      for (int c = 5; c <= 7; c++) {
        expect(CourtSportPartition.getSportForCourt(venue: venue, courtNumber: c), 'pickleball');
      }

      // Courts 8-10: Football
      for (int c = 8; c <= 10; c++) {
        expect(CourtSportPartition.getSportForCourt(venue: venue, courtNumber: c), 'football');
      }

      // Get courts for specific sport
      expect(CourtSportPartition.getCourtsForSport(venue: venue, sportType: 'badminton'), [1, 2, 3, 4]);
      expect(CourtSportPartition.getCourtsForSport(venue: venue, sportType: 'pickleball'), [5, 6, 7]);
      expect(CourtSportPartition.getCourtsForSport(venue: venue, sportType: 'football'), [8, 9, 10]);
      expect(CourtSportPartition.getCourtsForSport(venue: venue, sportType: 'all'), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('Single-sport venue returns same sport for all courts', () {
      final venue = SeedData.sampleVenues.firstWhere((v) => v.id == 'venue_td_02');
      expect(CourtSportPartition.getSportForCourt(venue: venue, courtNumber: 1), 'pickleball');
      expect(CourtSportPartition.getSportForCourt(venue: venue, courtNumber: 8), 'pickleball');
      expect(CourtSportPartition.getCourtsForSport(venue: venue, sportType: 'all'), [1, 2, 3, 4, 5, 6, 7, 8]);
    });
  });
}
