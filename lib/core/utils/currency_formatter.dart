class CurrencyFormatter {
  /// Formats a number with Vietnamese thousands dot separator and currency suffix 'đ'.
  /// Examples:
  ///   `format(25000)` -> `'25.000 đ'`
  ///   `format(587000)` -> `'587.000 đ'`
  ///   `format(707000)` -> `'707.000 đ'`
  static String format(num amount) {
    final str = amount.toInt().toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$formatted đ';
  }

  /// Formats a number with Vietnamese thousands dot separator, currency suffix 'đ', and unit.
  /// Examples:
  ///   `formatWithUnit(25000, 'cái')` -> `'25.000 đ/cái'`
  ///   `formatWithUnit(15000, 'chai')` -> `'15.000 đ/chai'`
  ///   `formatWithUnit(150000, 'h')` -> `'150.000 đ/h'`
  static String formatWithUnit(num amount, String unit) {
    return '${format(amount)}/$unit';
  }
}
