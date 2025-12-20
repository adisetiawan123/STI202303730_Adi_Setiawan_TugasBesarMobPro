import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../db/database_helper.dart';
import '../services/auth_service.dart';
import '../services/real_payment_service.dart';

class MyTicketsPage extends StatefulWidget {
  final User currentUser;

  const MyTicketsPage({required this.currentUser, super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage>
    with WidgetsBindingObserver {
  final db = DatabaseHelper();
  final paymentService = RealPaymentService();
  List<Ticket> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTickets();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User kembali ke aplikasi, refresh data tiket
      _loadTickets();
    }
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final tickets = await db.getTicketsByEmail(widget.currentUser.email);
      setState(() => _tickets = tickets);
    } catch (e) {
      _showError('Gagal memuat tiket: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
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

  void _checkoutTicket(Ticket ticket) async {
    _showPaymentMethodDialog(ticket);
  }

  void _showPaymentMethodDialog(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final phoneCtrl = TextEditingController();

          return AlertDialog(
            title: Text('Pilih Metode Pembayaran'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ringkasan pembayaran
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan Pembayaran',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total:', style: TextStyle(fontSize: 12)),
                            Text(
                              ticket.totalPrice,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Phone number input
                  Text(
                    'Nomor Telepon',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 08123456789',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.phone),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16),

                  // Payment methods
                  Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  ...paymentService.getAvailablePaymentMethods().map((method) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Material(
                        child: InkWell(
                          onTap: () {
                            if (phoneCtrl.text.isEmpty) {
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
                            _processPaymentWithMethod(
                              ticket,
                              method,
                              phoneCtrl.text,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  method.icon,
                                  style: TextStyle(fontSize: 24),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batalkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _processPaymentWithMethod(
    Ticket ticket,
    PaymentMethod method,
    String phoneNumber,
  ) async {
    // Validasi input
    if (!paymentService.validatePhoneNumber(phoneNumber)) {
      _showError(
        'Nomor telepon tidak valid. Format: 08123456789 atau 628123456789',
      );
      return;
    }

    // Validasi amount
    final amountStr = ticket.totalPrice
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();

    if (!paymentService.validateAmount(amountStr)) {
      _showError('Jumlah pembayaran tidak valid');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF00897B)),
              ),
              SizedBox(height: 16),
              Text(
                'Membuka aplikasi ${method.displayName}...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'Jika aplikasi tidak terbuka, pastikan ${method.displayName} sudah terinstall',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Buka aplikasi pembayaran dengan deep link
      final success = await paymentService.openPaymentApp(
        method: method,
        phoneNumber: phoneNumber,
        amount: amountStr,
        description:
            'Travel Wisata - ${ticket.destinationName} - ${ticket.quantity} tiket - ${ticket.totalPrice}',
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      if (success) {
        // Tunggu user selesai pembayaran dan kembali ke aplikasi
        await Future.delayed(Duration(milliseconds: 500)); // Small delay

        if (!mounted) return;

        _showPaymentConfirmationDialog(ticket, method, phoneNumber);
      } else {
        // Aplikasi tidak terinstall atau deep link gagal
        _showPaymentAppNotInstalledDialog(method);
      }
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      debugPrint('Payment error: $e');
      _showError('Terjadi kesalahan: ${e.toString()}');
    }
  }

  void _showPaymentAppNotInstalledDialog(PaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aplikasi ${method.displayName} Belum Terinstall'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplikasi ${method.displayName} tidak ditemukan di perangkat Anda.',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'Silakan install aplikasi terlebih dahulu dari Play Store.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await paymentService.openPaymentApp(
                method: method,
                phoneNumber: '0',
                amount: '0',
                description: 'install',
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Color(0xFF00897B)),
            child: Text('Install dari Play Store'),
          ),
        ],
      ),
    );
  }

  void _showPaymentConfirmationDialog(
    Ticket ticket,
    PaymentMethod method,
    String phoneNumber,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Apakah Pembayaran Berhasil?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Silakan konfirmasi status pembayaran Anda di aplikasi ${method.displayName}',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Transaksi:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Metode: ${method.displayName}',
                    style: TextStyle(fontSize: 12),
                  ),
                  Text('Nomor: $phoneNumber', style: TextStyle(fontSize: 12)),
                  Text(
                    'Jumlah: ${ticket.totalPrice}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Pembayaran Gagal',
              style: TextStyle(color: Colors.red),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmPaymentSuccess(ticket, method, phoneNumber);
            },
            style: FilledButton.styleFrom(backgroundColor: Color(0xFF4CAF50)),
            child: Text('Pembayaran Berhasil'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPaymentSuccess(
    Ticket ticket,
    PaymentMethod method,
    String phoneNumber,
  ) async {
    try {
      // Generate transaction ID
      final transactionId =
          'TRX${DateTime.now().millisecondsSinceEpoch.toString().substring(4, 10)}';

      // Update ticket status to confirmed
      final updated = Ticket(
        id: ticket.id,
        destinationId: ticket.destinationId,
        destinationName: ticket.destinationName,
        userEmail: ticket.userEmail,
        quantity: ticket.quantity,
        ticketPrice: ticket.ticketPrice,
        totalPrice: ticket.totalPrice,
        purchaseDate: ticket.purchaseDate,
        status: 'confirmed',
        notes:
            '${ticket.notes}\n[${method.displayName}] $phoneNumber\nID: $transactionId\nWaktu: ${DateTime.now().toString()}',
      );

      await db.updateTicket(updated);

      // Refresh tickets list
      await _loadTickets();

      // Show success dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Pembayaran Berhasil'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tiket Anda telah dikonfirmasi!'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Transaksi:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Metode: ${method.displayName}',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text('Nomor: $phoneNumber', style: TextStyle(fontSize: 12)),
                    Text(
                      'ID: $transactionId',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Jumlah: ${ticket.totalPrice}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      'Waktu: ${DateTime.now().toLocal().toString().split('.')[0]}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: Color(0xFF4CAF50)),
              child: Text('Tutup'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Payment confirmation error: $e');
      _showError('Gagal menyimpan data pembayaran: ${e.toString()}');
    }
  }

  void _cancelTicket(Ticket ticket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batalkan Tiket'),
        content: Text(
          'Yakin ingin membatalkan tiket untuk ${ticket.destinationName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Ya', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final updated = Ticket(
          id: ticket.id,
          destinationId: ticket.destinationId,
          destinationName: ticket.destinationName,
          userEmail: ticket.userEmail,
          quantity: ticket.quantity,
          ticketPrice: ticket.ticketPrice,
          totalPrice: ticket.totalPrice,
          purchaseDate: ticket.purchaseDate,
          status: 'cancelled',
          notes: ticket.notes,
        );
        await db.updateTicket(updated);
        _loadTickets();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tiket berhasil dibatalkan'),
            backgroundColor: Color(0xFF00897B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        _showError('Gagal membatalkan tiket: ${e.toString()}');
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Color(0xFF4CAF50);
      case 'used':
        return Color(0xFF2196F3);
      case 'pending':
        return Color(0xFFFFC107);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Terkonfirmasi';
      case 'used':
        return 'Sudah Digunakan';
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tiket Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF00897B)),
              ),
            )
          : _tickets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada tiket',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mulai beli tiket untuk destinasi favorit Anda',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _tickets.length,
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ticket.destinationName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF212121),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'ID: #${ticket.id}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  ticket.status,
                                ).withValues(alpha: 26),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusLabel(ticket.status),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(ticket.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 16, color: Colors.grey[200]),

                        // Details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Jumlah Tiket',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${ticket.quantity} tiket',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00897B),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Harga per Tiket',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  ticket.ticketPrice,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00897B),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  ticket.totalPrice,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 12),

                        // Date
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tanggal: ${ticket.purchaseDate}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                        // Notes
                        if (ticket.notes.isNotEmpty) ...[
                          SizedBox(height: 12),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Catatan:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  ticket.notes,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Actions
                        SizedBox(height: 12),
                        if (ticket.status == 'pending')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _cancelTicket(ticket),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: Text(
                                  'Batalkan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: () => _checkoutTicket(ticket),
                                icon: Icon(Icons.payment, size: 16),
                                label: Text('Checkout'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Color(0xFF00897B),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  textStyle: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          )
                        else if (ticket.status == 'confirmed')
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _cancelTicket(ticket),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: Text(
                                'Batalkan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
