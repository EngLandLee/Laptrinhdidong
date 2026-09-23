import 'package:flutter_test/flutter_test.dart';
import 'package:sporthub/core/utils/vietqr_generator.dart';

void main() {
  test('VietQRGenerator creates correct image URL with required query parameters', () {
    final url = VietQRGenerator.generateUrl(
      bankId: 'MB',
      accountNo: '0901234567',
      amount: 150000,
      memo: 'BK-001',
      accountName: 'NGUYEN VAN A',
    );

    expect(url.startsWith('https://img.vietqr.io/image/MB-0901234567-compact2.png'), true);
    expect(url.contains('amount=150000'), true);
    expect(url.contains('addInfo=BK-001'), true);
    expect(url.contains('accountName=NGUYEN%20VAN%20A'), true);
  });

  test('VietQRGenerator encodes special characters in memo and accountName correctly', () {
    final url = VietQRGenerator.generateUrl(
      bankId: 'VCB',
      accountNo: '1234567890',
      amount: 500000,
      memo: 'Thanh toan san & bong #1',
      accountName: 'LÊ VĂN B',
    );

    expect(url.contains('addInfo=${Uri.encodeComponent('Thanh toan san & bong #1')}'), true);
    expect(url.contains('accountName=${Uri.encodeComponent('LÊ VĂN B')}'), true);
  });
}
