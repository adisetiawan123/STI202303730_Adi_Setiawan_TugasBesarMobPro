import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:travel_wisata_lokal/services/real_payment_service.dart';

void main() {
  group('PaymentService Deep Link Tests', () {
    test('DANA deep link format should be correct', () {
      final deepLink = PaymentMethod.dana.getDeepLink(
        phoneNumber: '08123456789',
        amount: '50000',
        description: 'Test Payment',
      );
      debugPrint('✅ DANA Deep Link: $deepLink');
      expect(deepLink, contains('dana://'));
      expect(deepLink, contains('628123456789')); // normalized phone
      expect(deepLink, contains('50000'));
      expect(deepLink, contains('Travel%20Wisata'));
    });

    test('OVO deep link format should be correct', () {
      final deepLink = PaymentMethod.ovo.getDeepLink(
        phoneNumber: '08123456789',
        amount: '50000',
        description: 'Test Payment',
      );
      debugPrint('✅ OVO Deep Link: $deepLink');
      expect(deepLink, contains('ovo://'));
      expect(deepLink, contains('628123456789'));
      expect(deepLink, contains('50000'));
      expect(deepLink, contains('Travel%20Wisata'));
    });

    test('GoPay deep link format should be correct', () {
      final deepLink = PaymentMethod.gopay.getDeepLink(
        phoneNumber: '08123456789',
        amount: '50000',
        description: 'Test Payment',
      );
      debugPrint('✅ GoPay Deep Link: $deepLink');
      expect(deepLink, contains('https://pay.gojek.com'));
      expect(deepLink, contains('628123456789'));
      expect(deepLink, contains('50000'));
      expect(deepLink, contains('Travel%20Wisata'));
    });

    test('Link Aja deep link format should be correct', () {
      final deepLink = PaymentMethod.linkaja.getDeepLink(
        phoneNumber: '08123456789',
        amount: '50000',
        description: 'Test Payment',
      );
      debugPrint('✅ Link Aja Deep Link: $deepLink');
      expect(deepLink, contains('linkaja://'));
      expect(deepLink, contains('628123456789'));
      expect(deepLink, contains('50000'));
      expect(deepLink, contains('Travel%20Wisata'));
    });

    test('Bank Transfer should return placeholder URL', () {
      final deepLink = PaymentMethod.bankTransfer.getDeepLink(
        phoneNumber: '08123456789',
        amount: '50000',
        description: 'Test Payment',
      );
      debugPrint('✅ Bank Transfer URL: $deepLink');
      expect(deepLink, contains('example.com'));
    });

    test('Payment method display names should be correct', () {
      expect(PaymentMethod.dana.displayName, 'DANA');
      expect(PaymentMethod.ovo.displayName, 'OVO');
      expect(PaymentMethod.gopay.displayName, 'GoPay');
      expect(PaymentMethod.linkaja.displayName, 'Link Aja');
      expect(PaymentMethod.bankTransfer.displayName, 'Transfer Bank');
    });

    test('Payment method icons should be present', () {
      expect(PaymentMethod.dana.icon, isNotEmpty);
      expect(PaymentMethod.ovo.icon, isNotEmpty);
      expect(PaymentMethod.gopay.icon, isNotEmpty);
      expect(PaymentMethod.linkaja.icon, isNotEmpty);
      expect(PaymentMethod.bankTransfer.icon, isNotEmpty);
    });
  });
}
