import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../models/ticket.dart';
import '../db/database_helper.dart';
import '../services/auth_service.dart';
import '../services/real_payment_service.dart';

class TicketPurchasePage extends StatefulWidget {
  final Destination destination;
  final User currentUser;

  const TicketPurchasePage({
    required this.destination,
    required this.currentUser,
    super.key,
  });

  @override
  State<TicketPurchasePage> createState() => _TicketPurchasePageState();
}

class _TicketPurchasePageState extends State<TicketPurchasePage> {
  final _quantityCtrl = TextEditingController(text: '1');
  final _notesCtrl = TextEditingController();
  final db = DatabaseHelper();
  bool _isLoading = false;

  String get _ticketPrice {
    return widget.destination.ticketInfo.isNotEmpty
        ? widget.destination.ticketInfo
        : 'Gratis';
  }

  String _parsePrice(String priceStr) {
    // Parse "Rp 10.000" or "Gratis" to numeric value
    if (priceStr.toLowerCase().contains('gratis')) return '0';

    // Extract numbers from price string
    final numericStr = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return numericStr.isEmpty ? '0' : numericStr;
  }

  String _calculateTotal(int quantity) {
    final price = int.tryParse(_parsePrice(_ticketPrice)) ?? 0;
    final total = price * quantity;

    if (total == 0) return 'Gratis';
    return _formatCurrency(total);
  }

  String _formatCurrency(int amount) {
    if (amount == 0) return 'Gratis';
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)}.',
    );
    return 'Rp $formatted';
  }

  Future<void> _purchaseTicket() async {
    final quantity = int.tryParse(_quantityCtrl.text) ?? 1;

    if (quantity <= 0) {
      _showError('Jumlah tiket minimal 1');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final ticket = Ticket(
        destinationId: widget.destination.id ?? 0,
        destinationName: widget.destination.name,
        userEmail: widget.currentUser.email,
        quantity: quantity,
        ticketPrice: _ticketPrice,
        totalPrice: _calculateTotal(quantity),
        purchaseDate:
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        status: 'pending',
        notes: _notesCtrl.text,
      );

      await db.insertTicket(ticket);

      if (!mounted) return;

      // Langsung tampilkan dialog pemilihan metode pembayaran
      _showPaymentMethodSelection(ticket);
    } catch (e) {
      _showError('Gagal membeli tiket: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPaymentMethodSelection(Ticket ticket) {
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Pilih Metode Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Masukkan nomor telepon Anda untuk menerima pembayaran:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '08123456789',
                labelText: 'Nomor Telepon',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Pilih metode pembayaran:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            ...PaymentMethod.values
                .where((method) => method != PaymentMethod.bankTransfer)
                .map(
                  (method) => InkWell(
                    onTap: () {
                      final phone = phoneController.text.trim();
                      if (phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Masukkan nomor telepon terlebih dahulu',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      _processPaymentWithMethod(ticket, method, phone);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(method.icon, style: TextStyle(fontSize: 20)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method.displayName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  method.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batalkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPaymentWithMethod(
    Ticket ticket,
    PaymentMethod method,
    String phoneNumber,
  ) async {
    Navigator.pop(context); // Close payment method dialog

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Membuka aplikasi ${method.displayName}...'),
            SizedBox(height: 8),
            Text(
              'Jika aplikasi tidak terbuka, pastikan ${method.displayName} sudah terinstall',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );

    try {
      // Try to open payment app with deep link
      final success = await RealPaymentService().openPaymentApp(
        method: method,
        phoneNumber: phoneNumber,
        amount: ticket.totalPrice.replaceAll(
          RegExp(r'[^0-9]'),
          '',
        ), // Extract numeric value
        description:
            'Travel Wisata - ${ticket.destinationName} - ${ticket.quantity} tiket',
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      if (success) {
        // Show success message and navigate to tickets page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aplikasi ${method.displayName} berhasil dibuka!'),
            backgroundColor: Color(0xFF00897B),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate back to home and switch to tickets tab
        Navigator.of(context).popUntil((route) => route.isFirst);
        // Note: Tab switching will be handled by the parent HomePage
      } else {
        // Show error and navigate to tickets page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka aplikasi ${method.displayName}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
        // Note: Tab switching will be handled by the parent HomePage
      }
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      _showError('Error: ${e.toString()}');
      Navigator.of(context).pushReplacementNamed('/tickets');
    }
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Prevent admin from accessing ticket purchase
    if (widget.currentUser.role == 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admin tidak dapat membeli tiket'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      });
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final quantity = int.tryParse(_quantityCtrl.text) ?? 1;
    final total = _calculateTotal(quantity);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Beli Tiket',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Destination Info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Destinasi',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.destination.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00897B),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF00897B),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.destination.address,
                          style: TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Harga Tiket
            Text(
              'Harga Tiket',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Harga per tiket:', style: TextStyle(fontSize: 14)),
                  Text(
                    _ticketPrice,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00897B),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Jumlah Tiket
            Text(
              'Jumlah Tiket',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, color: Color(0xFF00897B)),
                    onPressed: () {
                      final current = int.tryParse(_quantityCtrl.text) ?? 1;
                      if (current > 1) {
                        setState(
                          () => _quantityCtrl.text = (current - 1).toString(),
                        );
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _quantityCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '1',
                      ),
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: Color(0xFF00897B)),
                    onPressed: () {
                      final current = int.tryParse(_quantityCtrl.text) ?? 1;
                      setState(
                        () => _quantityCtrl.text = (current + 1).toString(),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Catatan Tambahan
            Text(
              'Catatan (Opsional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan atau permintaan khusus...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            SizedBox(height: 24),

            // Total Harga
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFFF9C4),
                border: Border.all(color: Color(0xFFFFEB3B)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Harga',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        total,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${quantity}x tiket',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Tombol Beli
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _purchaseTicket,
                style: FilledButton.styleFrom(
                  backgroundColor: Color(0xFF00897B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'Lanjutkan Pembelian',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 16),

            // Info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tiket akan dikirim ke email Anda. Status awal: Pending sampai dikonfirmasi pihak destinasi wisata.',
                      style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
