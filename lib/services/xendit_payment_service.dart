import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class XenditPaymentService {
  static final XenditPaymentService _instance =
      XenditPaymentService._internal();

  factory XenditPaymentService() => _instance;

  XenditPaymentService._internal();

  // TODO: replace with your real Xendit keys
  static const String xenditApiKey = 'xnd_development_YOUR_API_KEY_HERE';
  static const String xenditBaseUrl = 'https://api.xendit.co';

  Future<XenditInvoice?> createInvoice({
    required String externalId,
    required int amount,
    required String description,
    required String payerEmail,
    required String payerName,
    int? expiryDuration,
    List<String>? paymentMethods,
  }) async {
    try {
      final body = {
        'external_id': externalId,
        'amount': amount,
        'payer_email': payerEmail,
        'description': description,
        'customer': {'given_names': payerName, 'email': payerEmail},
        'items': [
          {'name': description, 'quantity': 1, 'price': amount},
        ],
        if (expiryDuration != null)
          'due_date': DateTime.now()
              .add(Duration(minutes: expiryDuration))
              .toIso8601String(),
        if (paymentMethods != null) 'payment_methods': paymentMethods,
      };

      final response = await http
          .post(
            Uri.parse('$xenditBaseUrl/v2/invoices'),
            headers: {
              'Authorization':
                  'Basic ${base64Encode(utf8.encode('$xenditApiKey:'))}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return XenditInvoice.fromJson(jsonResponse);
      }

      debugPrint('Xendit Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Create Invoice Error: $e');
      return null;
    }
  }

  Future<XenditInvoice?> getInvoice(String invoiceId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$xenditBaseUrl/v2/invoices/$invoiceId'),
            headers: {
              'Authorization':
                  'Basic ${base64Encode(utf8.encode('$xenditApiKey:'))}',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return XenditInvoice.fromJson(jsonResponse);
      }

      debugPrint('Get Invoice Error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Get Invoice Error: $e');
      return null;
    }
  }

  Future<XenditQRCode?> createQRCode({
    required String referenceId,
    required int amount,
    required String currency,
    String? channelCode,
  }) async {
    try {
      final body = {
        'reference_id': referenceId,
        'amount': amount,
        'currency': currency,
        if (channelCode != null) 'channel_code': channelCode,
      };

      final response = await http
          .post(
            Uri.parse('$xenditBaseUrl/qr_codes'),
            headers: {
              'Authorization':
                  'Basic ${base64Encode(utf8.encode('$xenditApiKey:'))}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return XenditQRCode.fromJson(jsonResponse);
      }

      debugPrint('QR Code Error: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Create QR Code Error: $e');
      return null;
    }
  }

  bool verifyXenditWebhook({
    required String xWebhookToken,
    required String expectedToken,
  }) {
    return xWebhookToken == expectedToken;
  }
}

class XenditInvoice {
  final String id;
  final String externalId;
  final String invoiceUrl;
  final int amount;
  final String status;
  final String description;
  final String payerEmail;
  final DateTime createdAt;
  final DateTime? expiryDate;

  XenditInvoice({
    required this.id,
    required this.externalId,
    required this.invoiceUrl,
    required this.amount,
    required this.status,
    required this.description,
    required this.payerEmail,
    required this.createdAt,
    this.expiryDate,
  });

  factory XenditInvoice.fromJson(Map<String, dynamic> json) {
    return XenditInvoice(
      id: json['id'] as String,
      externalId: json['external_id'] as String,
      invoiceUrl: json['invoice_url'] as String,
      amount: json['amount'] as int,
      status: json['status'] as String,
      description: json['description'] as String? ?? '',
      payerEmail: json['payer_email'] as String? ?? '',
      createdAt: DateTime.parse(
        json['created'] as String? ?? DateTime.now().toIso8601String(),
      ),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
    );
  }

  bool get isPaid => status == 'PAID' || status == 'SETTLED';
  bool get isPending => status == 'PENDING';
  bool get isExpired => status == 'EXPIRED';
}

class XenditQRCode {
  final String id;
  final String referenceId;
  final String qrString;
  final int amount;
  final String status;
  final String currency;

  XenditQRCode({
    required this.id,
    required this.referenceId,
    required this.qrString,
    required this.amount,
    required this.status,
    required this.currency,
  });

  factory XenditQRCode.fromJson(Map<String, dynamic> json) {
    return XenditQRCode(
      id: json['id'] as String,
      referenceId: json['reference_id'] as String,
      qrString: json['qr_string'] as String,
      amount: json['amount'] as int? ?? 0,
      status: json['status'] as String,
      currency: json['currency'] as String? ?? 'IDR',
    );
  }
}

class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;
  final String? invoiceUrl;
  final Map<String, dynamic>? metadata;

  PaymentResult({
    required this.success,
    required this.message,
    this.transactionId,
    this.invoiceUrl,
    this.metadata,
  });
}
