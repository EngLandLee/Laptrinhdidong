import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats numbers with thousands dot separators and currency suffix', () {
      expect(CurrencyFormatter.format(0), '0 đ');
      expect(CurrencyFormatter.format(500), '500 đ');
      expect(CurrencyFormatter.format(1000), '1.000 đ');
      expect(CurrencyFormatter.format(25000), '25.000 đ');
      expect(CurrencyFormatter.format(120000), '120.000 đ');
      expect(CurrencyFormatter.format(587000), '587.000 đ');
      expect(CurrencyFormatter.format(707000), '707.000 đ');
      expect(CurrencyFormatter.format(1500000), '1.500.000 đ');
    });

    test('formats numbers with units correctly', () {
      expect(CurrencyFormatter.formatWithUnit(25000, 'cái'), '25.000 đ/cái');
      expect(CurrencyFormatter.formatWithUnit(15000, 'chai'), '15.000 đ/chai');
      expect(CurrencyFormatter.formatWithUnit(20000, 'lon'), '20.000 đ/lon');
      expect(CurrencyFormatter.formatWithUnit(150000, 'h'), '150.000 đ/h');
    });
  });
}
