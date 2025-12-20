import 'package:flutter/material.dart';
import '../models/destination.dart';
import '../services/auth_service.dart';
import 'payment_page.dart';

class TicketPurchasePageWithXendit extends StatefulWidget {
  final Destination destination;
  final User currentUser;

  const TicketPurchasePageWithXendit({
    required this.destination,
    required this.currentUser,
    super.key,
  });

  @override
  State<TicketPurchasePageWithXendit> createState() =>
      _TicketPurchasePageWithXenditState();
}

class _TicketPurchasePageWithXenditState
    extends State<TicketPurchasePageWithXendit> {
  int _quantity = 1;
  String? _selectedTicketType; // 'regular', 'student', 'senior'

  // Harga tiket (dalam Rupiah)
  static const Map<String, int> ticketPrices = {
    'regular': 50000,
    'student': 30000,
    'senior': 25000,
  };

  static const Map<String, String> ticketLabels = {
    'regular': 'Tiket Reguler',
    'student': 'Tiket Pelajar',
    'senior': 'Tiket Senior',
  };

  int get _totalPrice {
    if (_selectedTicketType == null) return 0;
    return (ticketPrices[_selectedTicketType] ?? 0) * _quantity;
  }

  Future<void> _proceedToPayment() async {
    if (_selectedTicketType == null) {
      _showError('Silakan pilih jenis tiket');
      return;
    }

    if (_quantity <= 0) {
      _showError('Jumlah tiket minimal 1');
      return;
    }

    // Navigate ke Payment Page dengan Xendit
    if (mounted) {
      final success = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            amount: _totalPrice,
            ticketTitle: '${ticketLabels[_selectedTicketType]} x $_quantity',
            destinationName: widget.destination.name,
            userEmail: widget.currentUser.email,
            userName: widget.currentUser.name ?? 'Guest',
            onPaymentSuccess: _handlePaymentSuccess,
          ),
        ),
      );

      if (success == true) {
        _createTicket();
      }
    }
  }

  void _handlePaymentSuccess() {
    _showSuccess('Pembayaran berhasil! Tiket akan dikirim ke email Anda.');
  }

  Future<void> _createTicket() async {
    // TODO: Save ticket ke database setelah payment sukses
    // final ticket = Ticket(
    //   id: 'TICKET_${DateTime.now().millisecondsSinceEpoch}',
    //   destinationId: widget.destination.id!,
    //   userId: widget.currentUser.id,
    //   ticketType: _selectedTicketType!,
    //   quantity: _quantity,
    //   totalPrice: _totalPrice,
    //   purchaseDate: DateTime.now(),
    //   status: 'active',
    // );
    // await DatabaseHelper().insertTicket(ticket);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beli Tiket')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Destination Info
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.destination.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.destination.description,
                      style: TextStyle(color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Ticket Type Selection
              Text(
                'Jenis Tiket',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              ...ticketLabels.entries.map((entry) {
                final type = entry.key;
                final label = entry.value;
                final price = ticketPrices[type] ?? 0;
                final isSelected = _selectedTicketType == type;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedTicketType = type);
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00897B)
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? const Color(0xFF00897B).withValues(alpha: 0.05)
                            : Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? const Color(0xFF00897B)
                                      : Colors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00897B)
                                    : Colors.grey,
                              ),
                              color: isSelected
                                  ? const Color(0xFF00897B)
                                  : Colors.white,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              SizedBox(height: 32),

              // Quantity Selector
              Text(
                'Jumlah Tiket',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove),
                      color: const Color(0xFF00897B),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add),
                      color: const Color(0xFF00897B),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Total Price
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00897B).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Harga:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rp ${_totalPrice.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00897B),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Proceed to Payment Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _totalPrice > 0 ? _proceedToPayment : null,
                  icon: const Icon(Icons.payment),
                  label: const Text('Lanjut ke Pembayaran'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
