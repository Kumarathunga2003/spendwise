import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('In-app SpendWise logo uses RGBA artwork, not opaque launcher icon', () {
    final source =
        File('lib/widgets/spendwise_brand_logo.dart').readAsStringSync();
    expect(
        source, contains("'assets/branding/spendwise_wallet_transparent.png'"));
    final file = File('assets/branding/spendwise_wallet_transparent.png');
    expect(file.existsSync(), isTrue);
    final bytes = file.readAsBytesSync();
    expect(bytes.length, greaterThan(26));
    expect(bytes.sublist(0, 8), equals([137, 80, 78, 71, 13, 10, 26, 10]));
    expect(bytes[25], 6,
        reason: 'In-app brand image must use RGBA transparency');
    expect(
        File('pubspec.yaml').readAsStringSync(), contains('version: 1.0.0+1'));
  });
}
