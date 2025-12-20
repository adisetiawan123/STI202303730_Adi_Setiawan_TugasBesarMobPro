import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/midtrans_service.dart';
import '../config/midtrans_config.dart';

class PaymentPage extends StatefulWidget {
  final int amount;
  final String ticketTitle;
  final String destinationName;
  final String userEmail;
  final String userName;
  final VoidCallback onPaymentSuccess;

  const PaymentPage({
    required this.amount,
    required this.ticketTitle,
    required this.destinationName,
    required this.userEmail,
    required this.userName,
    required this.onPaymentSuccess,
    super.key,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = false;
  bool _isCheckingStatus = false;
  String? _redirectUrl;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _createTransaction();
  }

  Future<void> _createTransaction() async {
    final backend = MidtransConfig.backendCreateTransactionUrl;
    if (backend.isEmpty) {
      _showError('Midtrans backend URL belum dikonfigurasi.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      _orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      final payload = {
        'order_id': _orderId,
        'gross_amount': widget.amount,
        'customer': {'email': widget.userEmail, 'first_name': widget.userName},
        'items': [
          {
            'id': 'ticket_1',
            'price': widget.amount,
            'quantity': 1,
            'name': widget.ticketTitle,
          },
        ],
      };

      final mid = MidtransService();
      final tokenOrUrl = await mid.fetchSnapTokenFromBackend(
        backendUrl: backend,
        body: payload,
      );

      if (mounted) {
        setState(() {
          _redirectUrl = tokenOrUrl;
          _isLoading = false;
        });
      }

      if (tokenOrUrl == null) {
        _showError('Gagal mendapat token/redirect dari backend Midtrans');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError('Error saat membuat transaksi: ${e.toString()}');
    }
  }

  Future<void> _openPaymentLink() async {
    if (_redirectUrl == null) {
      _showError('Link pembayaran belum tersedia');
      return;
    }

    final uri = Uri.parse(_redirectUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // After opening the payment link, wait a moment then prompt to check status
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _promptCheckPaymentStatus();
        }
      });
    } else {
      _showError('Tidak dapat membuka halaman pembayaran');
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_orderId == null) return;

    setState(() => _isCheckingStatus = true);
    try {
      final backend = MidtransConfig.backendCreateTransactionUrl;
      final statusUrl = backend.replaceAll(
        '/create-transaction',
        '/check-status/$_orderId',
      );

      final response = await http
          .get(Uri.parse(statusUrl))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => http.Response('Timeout', 408),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transactionStatus = data['transaction_status'] ?? '';

        if (transactionStatus == 'settlement' ||
            transactionStatus == 'capture') {
          setState(() {
            _isCheckingStatus = false;
          });
          _showSuccess('Pembayaran berhasil! Dana telah diterima.');
          Future.delayed(const Duration(seconds: 1), () {
            widget.onPaymentSuccess();
            if (mounted) Navigator.pop(context);
          });
        } else if (transactionStatus == 'pending') {
          setState(() => _isCheckingStatus = false);
          _showError('Pembayaran masih diproses. Mohon tunggu...');
        } else if (transactionStatus == 'deny' ||
            transactionStatus == 'cancel' ||
            transactionStatus == 'expire') {
          setState(() => _isCheckingStatus = false);
          _showError(
            'Pembayaran dibatalkan atau kadaluarsa. Silakan coba lagi.',
          );
        } else {
          setState(() => _isCheckingStatus = false);
          _showError(
            'Status pembayaran: $transactionStatus. Hubungi support jika ada masalah.',
          );
        }
      } else {
        setState(() => _isCheckingStatus = false);
        _showError(
          'Gagal memperiksa status. Cek koneksi internet atau coba lagi.',
        );
      }
    } catch (e) {
      setState(() => _isCheckingStatus = false);
      _showError('Error: ${e.toString()}');
    }
  }

  void _promptCheckPaymentStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verifikasi Pembayaran'),
        content: const Text(
          'Apakah pembayaran Anda sudah selesai? Kami akan memverifikasi status pembayaran Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Belum'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkPaymentStatus();
            },
            child: const Text('Ya, Sudah Selesai'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran Tiket')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ringkasan Pembayaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Destinasi:'),
                              Text(
                                widget.destinationName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tiket:'),
                              Text(
                                widget.ticketTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Email:'),
                              Text(
                                widget.userEmail,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rp ${widget.amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00897B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (_redirectUrl != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info,
                              color: Colors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Transaksi Midtrans siap',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Gunakan tombol di bawah untuk melanjutkan ke Midtrans.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _openPaymentLink,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Lanjutkan ke Midtrans'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00897B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _isCheckingStatus
                              ? null
                              : _checkPaymentStatus,
                          icon: const Icon(Icons.refresh),
                          label: _isCheckingStatus
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Periksa Status Pembayaran'),
                        ),
                      ),
                    ] else ...[
                      const SizedBox.shrink(),
                    ],

                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info, color: Colors.blue, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pembayaran diproses oleh Midtrans. Anda akan diarahkan ke halaman pembayaran yang aman.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
