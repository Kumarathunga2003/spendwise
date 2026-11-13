import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SpendWise brand assets are present and nonempty', () {
    const assets = [
      'assets/branding/spendwise_launcher.png',
      'assets/branding/spendwise_adaptive_foreground.png',
      'assets/branding/spendwise_splash.png',
      'assets/branding/spendwise_splash_android12.png',
      'assets/branding/spendwise_wordmark.png',
      'assets/branding/spendwise_wordmark_light.png',
      'assets/branding/spendwise_wordmark_tagline.png',
      'assets/branding/spendwise_wordmark_tagline_light.png',
    ];
    for (final file in assets) {
      final asset = File(file);
      expect(asset.existsSync(), isTrue, reason: 'Missing $file');
      expect(asset.lengthSync(), greaterThan(1000), reason: 'Empty $file');
    }
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/branding/'));
    expect(pubspec, contains('version: 1.0.0+1'));
  });
}
