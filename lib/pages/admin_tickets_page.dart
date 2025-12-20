import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/ticket.dart';

class AdminTicketsPage extends StatefulWidget {
  const AdminTicketsPage({super.key});

  @override
  State<AdminTicketsPage> createState() => _AdminTicketsPageState();
}

class _AdminTicketsPageState extends State<AdminTicketsPage> {
  final db = DatabaseHelper();
  List<Ticket> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final t = await db.getAllTickets();
      setState(() => _tickets = t);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(Ticket ticket, String status) async {
    final newTicket = Ticket(
      id: ticket.id,
      destinationId: ticket.destinationId,
      destinationName: ticket.destinationName,
      userEmail: ticket.userEmail,
      quantity: ticket.quantity,
      ticketPrice: ticket.ticketPrice,
      totalPrice: ticket.totalPrice,
      purchaseDate: ticket.purchaseDate,
      status: status,
      notes: ticket.notes,
    );
    await db.updateTicket(newTicket);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Status diperbarui: $status')));
    _loadTickets();
  }

  Future<void> _deleteTicket(int id) async {
    await db.deleteTicket(id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Tiket dihapus')));
    _loadTickets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTickets,
              child: _tickets.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.confirmation_number_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Belum ada pembelian tiket',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(12),
                      itemCount: _tickets.length,
                      separatorBuilder: (_, __) => Divider(),
                      itemBuilder: (context, index) {
                        final t = _tickets[index];
                        return Card(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        t.destinationName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      t.purchaseDate,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text('Pembeli: ${t.userEmail}'),
                                SizedBox(height: 4),
                                Text(
                                  'Kuantitas: ${t.quantity} • Harga: ${t.ticketPrice} • Total: ${t.totalPrice}',
                                ),
                                if (t.notes.isNotEmpty) ...[
                                  SizedBox(height: 6),
                                  Text(
                                    'Catatan: ${t.notes}',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (t.status != 'confirmed')
                                      ElevatedButton(
                                        onPressed: () =>
                                            _updateStatus(t, 'confirmed'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        child: Text('Konfirmasi'),
                                      ),
                                    SizedBox(width: 8),
                                    if (t.status != 'cancelled')
                                      ElevatedButton(
                                        onPressed: () =>
                                            _updateStatus(t, 'cancelled'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                        ),
                                        child: Text('Batalkan'),
                                      ),
                                    Spacer(),
                                    IconButton(
                                      onPressed: () => _deleteTicket(t.id!),
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Chip(label: Text(t.status)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
