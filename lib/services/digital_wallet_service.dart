import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Enum untuk metode pembayaran dompet digital
enum DigitalWalletMethod { dana, ovo, gopay, linkaja, shopeepay, qris }

/// Extension untuk tampilan user-friendly
extension DigitalWalletMethodExt on DigitalWalletMethod {
  String get name {
    switch (this) {
      case DigitalWalletMethod.dana:
        return 'DANA';
      case DigitalWalletMethod.ovo:
        return 'OVO';
      case DigitalWalletMethod.gopay:
        return 'GoPay';
      case DigitalWalletMethod.linkaja:
        return 'Link Aja';
      case DigitalWalletMethod.shopeepay:
        return 'ShopeePay';
      case DigitalWalletMethod.qris:
        return 'QRIS';
    }
  }

  String get icon {
    switch (this) {
      case DigitalWalletMethod.dana:
        return '💜';
      case DigitalWalletMethod.ovo:
        return '🔵';
      case DigitalWalletMethod.gopay:
        return '🟢';
      case DigitalWalletMethod.linkaja:
        return '🟠';
      case DigitalWalletMethod.shopeepay:
        return '🛒';
      case DigitalWalletMethod.qris:
        return '📱';
    }
  }

  String get description {
    switch (this) {
      case DigitalWalletMethod.dana:
        return 'Dompet Digital DANA - Transfer instan ke nomor HP';
      case DigitalWalletMethod.ovo:
        return 'Dompet Digital OVO - Bayar di mana saja dengan OVO';
      case DigitalWalletMethod.gopay:
        return 'GoPay - Pembayaran mudah dari Gojek';
      case DigitalWalletMethod.linkaja:
        return 'Link Aja - Platform pembayaran digital OJK';
      case DigitalWalletMethod.shopeepay:
        return 'ShopeePay - Bayar melalui aplikasi Shopee';
      case DigitalWalletMethod.qris:
        return 'QRIS - Scan kode untuk pembayaran';
    }
  }

  /// Generate deep link untuk membuka aplikasi dompet digital
  String generateDeepLink({
    required String amount,
    required String phoneNumber,
    required String description,
  }) {
    switch (this) {
      case DigitalWalletMethod.dana:
        // Deep link DANA
        return 'dana://transfer?phoneNumber=$phoneNumber&amount=$amount&note=${Uri.encodeComponent(description)}';

      case DigitalWalletMethod.ovo:
        // Deep link OVO
        return 'ovo://send?phoneNumber=$phoneNumber&amount=$amount&message=${Uri.encodeComponent(description)}';

      case DigitalWalletMethod.gopay:
        // Deep link GoPay (biasanya melalui web)
        return 'https://pay.gojek.com/pay?amount=$amount&description=${Uri.encodeComponent(description)}';

      case DigitalWalletMethod.linkaja:
        // Deep link Link Aja
        return 'linkaja://pay?amount=$amount&phone=$phoneNumber&note=${Uri.encodeComponent(description)}';

      case DigitalWalletMethod.shopeepay:
        // Deep link ShopeePay
        return 'shopeepay://pay?amount=$amount&phone=$phoneNumber';

      case DigitalWalletMethod.qris:
        // QRIS biasanya di-generate server-side
        return 'https://api.qris.id/generate?amount=$amount';
    }
  }
}

/// Class untuk response pembayaran dompet digital
class DigitalWalletPaymentResult {
  final bool success;
  final String transactionId;
  final String statusCode;
  final String message;
  final DateTime timestamp;
  final DigitalWalletMethod method;
  final int amount;

  DigitalWalletPaymentResult({
    required this.success,
    required this.transactionId,
    required this.statusCode,
    required this.message,
    required this.timestamp,
    required this.method,
    required this.amount,
  });

  factory DigitalWalletPaymentResult.fromJson(Map<String, dynamic> json) {
    return DigitalWalletPaymentResult(
      success: json['success'] ?? false,
      transactionId: json['transactionId'] ?? '',
      statusCode: json['statusCode'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      method: DigitalWalletMethod.values[json['method'] ?? 0],
      amount: json['amount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'transactionId': transactionId,
    'statusCode': statusCode,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'method': method.index,
    'amount': amount,
  };
}

/// Service untuk pembayaran dompet digital menggunakan Xendit
class DigitalWalletPaymentService {
  static final DigitalWalletPaymentService _instance =
      DigitalWalletPaymentService._internal();

  factory DigitalWalletPaymentService() => _instance;

  DigitalWalletPaymentService._internal();

  // Xendit configuration
  static const String xenditApiKey = 'xnd_live_YOUR_API_KEY_HERE';
  static const String xenditBaseUrl = 'https://api.xendit.co';
  static const String xenditPublicKey = 'xnd_public_YOUR_PUBLIC_KEY_HERE';

  /// Buat invoice pembayaran menggunakan dompet digital di Xendit
  Future<DigitalWalletPaymentResult> createDigitalWalletPayment({
    required DigitalWalletMethod method,
    required int amount,
    required String phoneNumber,
    required String email,
    required String description,
    required String externalId,
  }) async {
    try {
      // Map payment method ke Xendit's channel codes
      final channelCode = _getXenditChannelCode(method);
      if (channelCode == null) {
        return DigitalWalletPaymentResult(
          success: false,
          transactionId: '',
          statusCode: 'INVALID_METHOD',
          message: 'Metode pembayaran tidak didukung di Xendit',
          timestamp: DateTime.now(),
          method: method,
          amount: amount,
        );
      }

      // Create invoice via Xendit API
      final response = await http.post(
        Uri.parse('$xenditBaseUrl/invoices'),
        headers: {
          'Authorization': 'Basic ${_encodeBasicAuth(xenditApiKey)}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'external_id': externalId,
          'amount': amount,
          'description': description,
          'email_to': email,
          'payment_methods': [channelCode],
          'customer': {
            'given_names': 'Customer',
            'email': email,
            'mobile_number': phoneNumber,
          },
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return DigitalWalletPaymentResult(
          success: true,
          transactionId: responseData['id'] ?? '',
          statusCode: 'INVOICE_CREATED',
          message: 'Invoice berhasil dibuat. Silakan lanjutkan pembayaran.',
          timestamp: DateTime.now(),
          method: method,
          amount: amount,
        );
      } else {
        return DigitalWalletPaymentResult(
          success: false,
          transactionId: '',
          statusCode: 'API_ERROR',
          message: 'Gagal membuat invoice: ${response.statusCode}',
          timestamp: DateTime.now(),
          method: method,
          amount: amount,
        );
      }
    } catch (e) {
      return DigitalWalletPaymentResult(
        success: false,
        transactionId: '',
        statusCode: 'EXCEPTION',
        message: 'Error: ${e.toString()}',
        timestamp: DateTime.now(),
        method: method,
        amount: amount,
      );
    }
  }

  /// Buka aplikasi dompet digital untuk pembayaran
  Future<bool> openDigitalWalletApp({
    required DigitalWalletMethod method,
    required int amount,
    required String phoneNumber,
    required String description,
  }) async {
    try {
      final deepLink = method.generateDeepLink(
        amount: amount.toString(),
        phoneNumber: phoneNumber,
        description: description,
      );

      final uri = Uri.parse(deepLink);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // Jika app tidak terinstall, buka web version
        return await _openWebPayment(method, amount, phoneNumber);
      }
    } catch (e) {
      debugPrint('Error launching wallet app: $e');
      return false;
    }
  }

  /// Cek status pembayaran dari Xendit
  Future<DigitalWalletPaymentResult?> checkPaymentStatus({
    required String invoiceId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$xenditBaseUrl/invoices/$invoiceId'),
        headers: {'Authorization': 'Basic ${_encodeBasicAuth(xenditApiKey)}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isPaid = data['status'] == 'PAID';

        return DigitalWalletPaymentResult(
          success: isPaid,
          transactionId: data['id'] ?? '',
          statusCode: data['status'] ?? 'UNKNOWN',
          message: isPaid
              ? 'Pembayaran berhasil!'
              : 'Pembayaran sedang diproses...',
          timestamp: DateTime.now(),
          method: DigitalWalletMethod.values[0],
          amount: data['amount'] ?? 0,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      return null;
    }
  }

  /// Get list metode pembayaran yang tersedia
  List<DigitalWalletMethod> getAvailableMethods() {
    return DigitalWalletMethod.values;
  }

  /// Check apakah metode pembayaran didukung
  bool isMethodSupported(DigitalWalletMethod method) {
    return true; // Semua method didukung
  }

  // Private methods
  String? _getXenditChannelCode(DigitalWalletMethod method) {
    switch (method) {
      case DigitalWalletMethod.dana:
        return 'DANA';
      case DigitalWalletMethod.ovo:
        return 'OVO';
      case DigitalWalletMethod.gopay:
        return 'GOPAY';
      case DigitalWalletMethod.linkaja:
        return 'LINKAJA';
      case DigitalWalletMethod.shopeepay:
        return 'SHOPEEPAY';
      case DigitalWalletMethod.qris:
        return 'QRIS';
    }
  }

  String _encodeBasicAuth(String apiKey) {
    return base64Encode(utf8.encode('$apiKey:'));
  }

  Future<bool> _openWebPayment(
    DigitalWalletMethod method,
    int amount,
    String phoneNumber,
  ) async {
    try {
      late String url;
      switch (method) {
        case DigitalWalletMethod.dana:
          url = 'https://dana.id';
          break;
        case DigitalWalletMethod.ovo:
          url = 'https://ovo.id';
          break;
        case DigitalWalletMethod.gopay:
          url = 'https://gojek.com';
          break;
        case DigitalWalletMethod.linkaja:
          url = 'https://linkaja.id';
          break;
        case DigitalWalletMethod.shopeepay:
          url = 'https://shopee.co.id';
          break;
        case DigitalWalletMethod.qris:
          url = 'https://qris.kemenkeu.go.id';
          break;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error opening web payment: $e');
      return false;
    }
  }
}
