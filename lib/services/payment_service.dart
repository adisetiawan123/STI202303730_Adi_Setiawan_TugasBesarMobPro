import 'dart:async';

enum PaymentMethod { dana, ovo, gopay, bankTransfer, creditCard }

extension PaymentMethodExt on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.dana:
        return 'DANA';
      case PaymentMethod.ovo:
        return 'OVO';
      case PaymentMethod.gopay:
        return 'GoPay';
      case PaymentMethod.bankTransfer:
        return 'Transfer Bank';
      case PaymentMethod.creditCard:
        return 'Kartu Kredit';
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
      case PaymentMethod.bankTransfer:
        return '🏦';
      case PaymentMethod.creditCard:
        return '💳';
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
      case PaymentMethod.bankTransfer:
        return 'Transfer antar bank';
      case PaymentMethod.creditCard:
        return 'Pembayaran kartu kredit';
    }
  }
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();

  factory PaymentService() {
    return _instance;
  }

  PaymentService._internal();

  // Simulate payment processing
  Future<PaymentResult> processPayment({
    required String ticketId,
    required String amount,
    required PaymentMethod method,
    required String userPhone,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(Duration(seconds: 2));

      // Validate payment method
      if (!_validatePaymentMethod(method, userPhone)) {
        return PaymentResult(
          success: false,
          message: 'Nomor telepon tidak valid untuk metode pembayaran ini',
          transactionId: null,
        );
      }

      // Simulate payment processing (90% success rate for demo)
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      if (random < 90) {
        final transactionId = _generateTransactionId();
        return PaymentResult(
          success: true,
          message: 'Pembayaran berhasil! ID Transaksi: $transactionId',
          transactionId: transactionId,
        );
      } else {
        return PaymentResult(
          success: false,
          message: 'Pembayaran gagal. Silahkan coba lagi.',
          transactionId: null,
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Error: ${e.toString()}',
        transactionId: null,
      );
    }
  }

  bool _validatePaymentMethod(PaymentMethod method, String phone) {
    // Phone should be 10-13 digits
    final phoneDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phoneDigits.length < 10 || phoneDigits.length > 13) {
      return false;
    }

    // Check if phone starts with 0 or 62
    if (!phoneDigits.startsWith('0') && !phoneDigits.startsWith('62')) {
      return false;
    }

    return true;
  }

  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (DateTime.now().microsecond % 10000).toString().padLeft(
      4,
      '0',
    );
    return 'TRX${timestamp.toString().substring(4, 10)}$random';
  }

  // Get available payment methods
  List<PaymentMethod> getAvailablePaymentMethods() {
    return PaymentMethod.values;
  }

  // Check if payment method is enabled
  bool isPaymentMethodEnabled(PaymentMethod method) {
    // In production, this would check backend configuration
    return true;
  }
}

class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;

  PaymentResult({
    required this.success,
    required this.message,
    required this.transactionId,
  });
}
