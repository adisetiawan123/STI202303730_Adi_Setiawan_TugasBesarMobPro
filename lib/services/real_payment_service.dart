import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

enum PaymentMethod { dana, ovo, gopay, linkaja, bankTransfer }

extension PaymentMethodExt on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.dana:
        return 'DANA';
      case PaymentMethod.ovo:
        return 'OVO';
      case PaymentMethod.gopay:
        return 'GoPay';
      case PaymentMethod.linkaja:
        return 'Link Aja';
      case PaymentMethod.bankTransfer:
        return 'Transfer Bank';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.dana:
        return '💜';
      case PaymentMethod.ovo:
        return '🔵';
      case PaymentMethod.gopay:
        return '🟢';
      case PaymentMethod.linkaja:
        return '🟠';
      case PaymentMethod.bankTransfer:
        return '🏦';
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.dana:
        return 'Dompet digital DANA';
      case PaymentMethod.ovo:
        return 'Pembayaran OVO digital wallet';
      case PaymentMethod.gopay:
        return 'Pembayaran GoPay dari Gojek';
      case PaymentMethod.linkaja:
        return 'Pembayaran Link Aja OJK';
      case PaymentMethod.bankTransfer:
        return 'Transfer antar bank';
    }
  }

  /// Deep link untuk membuka aplikasi pembayaran
  String getDeepLink({
    required String phoneNumber,
    required String amount,
    required String description,
  }) {
    // Hapus formatting dari nomor telepon
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final normalizedPhone = cleanPhone.startsWith('0')
        ? cleanPhone.replaceFirst('0', '62')
        : cleanPhone;

    switch (this) {
      case PaymentMethod.dana:
        // DANA deep link format - menggunakan transfer P2P
        return 'dana://transfer?phoneNumber=$normalizedPhone&amount=$amount&description=${Uri.encodeComponent(description)}';

      case PaymentMethod.ovo:
        // OVO deep link format - menggunakan transfer
        return 'ovo://transfer?phoneNumber=$normalizedPhone&amount=$amount&note=${Uri.encodeComponent(description)}';

      case PaymentMethod.gopay:
        // GoPay - menggunakan payment link web (lebih reliable)
        return 'https://pay.gojek.com/pay?amount=$amount&phone=$normalizedPhone&description=${Uri.encodeComponent(description)}';

      case PaymentMethod.linkaja:
        // Link Aja deep link - menggunakan transfer
        return 'linkaja://transfer?phone=$normalizedPhone&amount=$amount&description=${Uri.encodeComponent(description)}';

      case PaymentMethod.bankTransfer:
        // Bank transfer - tampilkan informasi manual
        return 'https://example.com/bank-transfer';
    }
  }
}

class RealPaymentService {
  static final RealPaymentService _instance = RealPaymentService._internal();

  factory RealPaymentService() {
    return _instance;
  }

  RealPaymentService._internal();

  /// Buka aplikasi pembayaran dengan deep link
  Future<bool> openPaymentApp({
    required PaymentMethod method,
    required String phoneNumber,
    required String amount,
    required String description,
  }) async {
    try {
      final deepLink = method.getDeepLink(
        phoneNumber: phoneNumber,
        amount: amount,
        description: description,
      );

      // Cek apakah aplikasi terpasang
      if (await canLaunchUrl(Uri.parse(deepLink))) {
        return await launchUrl(
          Uri.parse(deepLink),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Jika aplikasi tidak terpasang, buka app store
        return await _openAppStore(method);
      }
    } catch (e) {
      debugPrint('Error opening payment app: $e');
      return false;
    }
  }

  /// Buka App Store untuk download aplikasi pembayaran
  Future<bool> _openAppStore(PaymentMethod method) async {
    try {
      String storeUrl = '';

      // URL Play Store (Android) dan App Store (iOS)
      // Untuk production, gunakan platform-specific URLs
      switch (method) {
        case PaymentMethod.dana:
          // DANA di Play Store
          storeUrl =
              'https://play.google.com/store/apps/details?id=com.dana.id';
          break;
        case PaymentMethod.ovo:
          // OVO di Play Store
          storeUrl = 'https://play.google.com/store/apps/details?id=id.ovo.app';
          break;
        case PaymentMethod.gopay:
          // GoPay di Play Store
          storeUrl =
              'https://play.google.com/store/apps/details?id=com.gojek.app';
          break;
        case PaymentMethod.linkaja:
          // Link Aja di Play Store
          storeUrl =
              'https://play.google.com/store/apps/details?id=com.telkomsel.linkaja';
          break;
        case PaymentMethod.bankTransfer:
          return false;
      }

      if (await canLaunchUrl(Uri.parse(storeUrl))) {
        return await launchUrl(
          Uri.parse(storeUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      return false;
    } catch (e) {
      debugPrint('Error opening app store: $e');
      return false;
    }
  }

  /// Cek apakah aplikasi pembayaran sudah terpasang
  Future<bool> isPaymentAppInstalled(PaymentMethod method) async {
    try {
      final deepLink = method.getDeepLink(
        phoneNumber: '0',
        amount: '0',
        description: 'check',
      );
      return await canLaunchUrl(Uri.parse(deepLink));
    } catch (e) {
      return false;
    }
  }

  /// Get list metode pembayaran yang tersedia
  List<PaymentMethod> getAvailablePaymentMethods() {
    return PaymentMethod.values;
  }

  /// Validasi nomor telepon Indonesia
  bool validatePhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Harus dimulai dengan 0, 62, atau prefix mobile Indonesia (8x untuk 10 digit)
    if (!cleaned.startsWith('0') &&
        !cleaned.startsWith('62') &&
        !(cleaned.length == 10 && cleaned.startsWith('8'))) {
      return false;
    }

    // Validasi panjang berdasarkan format
    if (cleaned.startsWith('0')) {
      // Format lokal: 11-12 digit (0 + 10-11 digit)
      return cleaned.length >= 11 && cleaned.length <= 12;
    } else if (cleaned.startsWith('62')) {
      // Format internasional: 12-13 digit (62 + 10-11 digit)
      return cleaned.length >= 12 && cleaned.length <= 13;
    } else if (cleaned.startsWith('8')) {
      // Format tanpa 0: tepat 10 digit
      return cleaned.length == 10;
    }

    return false;
  }

  /// Validasi amount (harus numeric)
  bool validateAmount(String amount) {
    final cleaned = amount.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.isNotEmpty && int.tryParse(cleaned) != null;
  }

  /// Test deep link untuk debugging
  Future<Map<String, dynamic>> testDeepLink(PaymentMethod method) async {
    try {
      final testLink = method.getDeepLink(
        phoneNumber: '08123456789',
        amount: '10000',
        description: 'Test Payment',
      );

      final canLaunch = await canLaunchUrl(Uri.parse(testLink));

      return {
        'method': method.displayName,
        'deepLink': testLink,
        'canLaunch': canLaunch,
        'isInstalled': await isPaymentAppInstalled(method),
      };
    } catch (e) {
      return {
        'method': method.displayName,
        'error': e.toString(),
        'canLaunch': false,
        'isInstalled': false,
      };
    }
  }

  /// Get informasi troubleshooting untuk payment method
  Map<String, String> getTroubleshootingInfo(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.dana:
        return {
          'appName': 'DANA',
          'packageId': 'com.dana.id',
          'deepLinkFormat':
              'dana://transfer?phoneNumber={phone}&amount={amount}&description={desc}',
          'fallback':
              'Buka app DANA manual dan transfer ke nomor yang ditampilkan',
          'commonIssues':
              'Pastikan app DANA versi terbaru. Jika masih error, gunakan web DANA.',
        };

      case PaymentMethod.ovo:
        return {
          'appName': 'OVO',
          'packageId': 'id.ovo.app',
          'deepLinkFormat':
              'ovo://transfer?phoneNumber={phone}&amount={amount}&note={desc}',
          'fallback':
              'Buka app OVO manual dan transfer ke nomor yang ditampilkan',
          'commonIssues':
              'OVO deep link kadang tidak stabil. Gunakan scan QR jika tersedia.',
        };

      case PaymentMethod.gopay:
        return {
          'appName': 'GoPay (Gojek)',
          'packageId': 'com.gojek.app',
          'deepLinkFormat':
              'Web link: https://pay.gojek.com/pay?amount={amount}&phone={phone}',
          'fallback': 'Buka Gojek app dan pilih GoPay > Transfer > Ke Nomor HP',
          'commonIssues':
              'GoPay lebih reliable via web link daripada deep link app.',
        };

      case PaymentMethod.linkaja:
        return {
          'appName': 'Link Aja',
          'packageId': 'com.telkomsel.linkaja',
          'deepLinkFormat':
              'linkaja://transfer?phone={phone}&amount={amount}&description={desc}',
          'fallback':
              'Buka Link Aja app dan pilih Transfer > Ke Sesama Link Aja',
          'commonIssues': 'Pastikan nomor HP sudah terdaftar di Link Aja.',
        };

      case PaymentMethod.bankTransfer:
        return {
          'appName': 'Bank App',
          'packageId': 'N/A',
          'deepLinkFormat': 'Manual transfer',
          'fallback': 'Transfer manual ke rekening yang ditampilkan',
          'commonIssues': 'Tidak ada deep link, user harus transfer manual.',
        };
    }
  }
}
