import 'package:flutter/material.dart';
import '../services/digital_wallet_service.dart';
import '../services/auth_service.dart';

class DigitalWalletPaymentPage extends StatefulWidget {
  final int amount;
  final String ticketTitle;
  final String destinationName;
  final User currentUser;
  final VoidCallback onPaymentSuccess;

  const DigitalWalletPaymentPage({
    required this.amount,
    required this.ticketTitle,
    required this.destinationName,
    required this.currentUser,
    required this.onPaymentSuccess,
    super.key,
  });

  @override
  State<DigitalWalletPaymentPage> createState() =>
      _DigitalWalletPaymentPageState();
}

class _DigitalWalletPaymentPageState extends State<DigitalWalletPaymentPage> {
  final _walletService = DigitalWalletPaymentService();

  DigitalWalletMethod? _selectedMethod;
  bool _isProcessing = false;
  DigitalWalletPaymentResult? _paymentResult;

  Future<void> _processPayment() async {
    if (_selectedMethod == null) {
      _showSnackBar('Silakan pilih metode pembayaran', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Create invoice dengan Xendit
      final result = await _walletService.createDigitalWalletPayment(
        method: _selectedMethod!,
        amount: widget.amount,
        phoneNumber: widget.currentUser.email.replaceAll(
          '@',
          '',
        ), // placeholder
        email: widget.currentUser.email,
        description: '${widget.destinationName} - ${widget.ticketTitle}',
        externalId: 'TICKET_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() => _paymentResult = result);

      if (result.success) {
        // Buka aplikasi dompet digital
        final opened = await _walletService.openDigitalWalletApp(
          method: _selectedMethod!,
          amount: widget.amount,
          phoneNumber: widget.currentUser.email,
          description: '${widget.destinationName} - ${widget.ticketTitle}',
        );

        if (opened) {
          _showSnackBar(
            'Silakan selesaikan pembayaran di aplikasi ${_selectedMethod!.name}',
            isError: false,
          );

          // Tunggu beberapa saat untuk verifikasi
          await Future.delayed(Duration(seconds: 3));
          _checkPaymentStatus(result.transactionId);
        } else {
          _showSnackBar(
            'Aplikasi tidak terinstall. Silakan install aplikasi ${_selectedMethod!.name}',
            isError: true,
          );
        }
      } else {
        _showSnackBar(result.message, isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _checkPaymentStatus(String invoiceId) async {
    setState(() => _isProcessing = true);

    try {
      final status = await _walletService.checkPaymentStatus(
        invoiceId: invoiceId,
      );

      if (status != null && status.success) {
        _showSnackBar('Pembayaran berhasil!', isError: false);
        await Future.delayed(Duration(seconds: 1));
        widget.onPaymentSuccess();
        if (mounted) Navigator.pop(context);
      } else {
        _showSnackBar('Pembayaran masih diproses...', isError: false);
      }
    } catch (e) {
      _showSnackBar('Error checking status: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran Dompet Digital')),
      body: _isProcessing && _paymentResult == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary
                    _buildOrderSummary(),
                    SizedBox(height: 32),

                    // Payment Methods
                    Text(
                      'Pilih Metode Pembayaran',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildPaymentMethodsGrid(),
                    SizedBox(height: 32),

                    // Payment Result
                    if (_paymentResult != null) _buildPaymentResult(),
                    SizedBox(height: 32),

                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Pemesanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Destinasi:'),
              Text(
                widget.destinationName,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tiket:'),
              Text(
                widget.ticketTitle,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Email:'),
              Text(
                widget.currentUser.email,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
          Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Rp ${_formatCurrency(widget.amount)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00897B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsGrid() {
    final methods = _walletService.getAvailableMethods();

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: methods.length,
      itemBuilder: (context, index) {
        final method = methods[index];
        final isSelected = _selectedMethod == method;

        return GestureDetector(
          onTap: () => setState(() => _selectedMethod = method),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Color(0xFF00897B) : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? Color(0xFF00897B).withValues(alpha: 0.05)
                  : Colors.white,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(method.icon, style: TextStyle(fontSize: 32)),
                SizedBox(height: 8),
                Text(
                  method.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isSelected ? Color(0xFF00897B) : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    method.description,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentResult() {
    final result = _paymentResult!;
    final isSuccess = result.success;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? Colors.green[300]! : Colors.orange[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.info,
                color: isSuccess ? Colors.green : Colors.orange,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSuccess ? 'Invoice Berhasil Dibuat' : 'Sedang Diproses',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isSuccess
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      result.message,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Transaction ID: ${result.transactionId}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _isProcessing || _selectedMethod == null
                ? null
                : _processPayment,
            icon: Icon(Icons.payment),
            label: Text('Proses Pembayaran'),
            style: FilledButton.styleFrom(backgroundColor: Color(0xFF00897B)),
          ),
        ),
        SizedBox(height: 12),
        if (_paymentResult != null && _paymentResult!.success)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _checkPaymentStatus(_paymentResult!.transactionId),
              icon: Icon(Icons.refresh),
              label: Text('Cek Status Pembayaran'),
            ),
          ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
