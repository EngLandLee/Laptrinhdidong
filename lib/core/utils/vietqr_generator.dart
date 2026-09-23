class VietQRGenerator {
  static String generateUrl({
    required String bankId,
    required String accountNo,
    required int amount,
    required String memo,
    required String accountName,
  }) {
    final encodedMemo = Uri.encodeComponent(memo);
    final encodedName = Uri.encodeComponent(accountName);
    return 'https://img.vietqr.io/image/$bankId-$accountNo-compact2.png?amount=$amount&addInfo=$encodedMemo&accountName=$encodedName';
  }
}
