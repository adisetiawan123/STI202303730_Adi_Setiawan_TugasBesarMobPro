import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

class UserProfilePage extends StatefulWidget {
  final User currentUser;
  final VoidCallback onLogout;

  const UserProfilePage({
    required this.currentUser,
    required this.onLogout,
    super.key,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final SessionService _sessionService = SessionService();

  // Mock payment history - bisa diganti dengan real data dari backend
  final List<Map<String, dynamic>> _paymentHistory = [
    {
      'id': 'TXID001',
      'destination': 'Pantai Bali',
      'amount': 100000,
      'status': 'success',
      'date': DateTime.now().subtract(Duration(days: 2)),
      'method': 'DANA',
      'tickets': 2,
    },
    {
      'id': 'TXID002',
      'destination': 'Gunung Merapi',
      'amount': 75000,
      'status': 'success',
      'date': DateTime.now().subtract(Duration(days: 5)),
      'method': 'OVO',
      'tickets': 1,
    },
    {
      'id': 'TXID003',
      'destination': 'Danau Toba',
      'amount': 150000,
      'status': 'pending',
      'date': DateTime.now().subtract(Duration(hours: 2)),
      'method': 'GOPAY',
      'tickets': 3,
    },
  ];

  int get _totalSpent {
    return _paymentHistory
        .where((t) => t['status'] == 'success')
        .fold(0, (sum, t) => sum + (t['amount'] as int));
  }

  int get _totalTickets {
    return _paymentHistory
        .where((t) => t['status'] == 'success')
        .fold(0, (sum, t) => sum + (t['tickets'] as int));
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Call app-level logout and clear session
      widget.onLogout();
      await _sessionService.logout();

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout gagal: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _buildProfileHeader(),
            SizedBox(height: 32),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistik Pembelian',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildStatTile(
                        'Total Pembelian',
                        'Rp ${_formatCurrency(_totalSpent)}',
                        Icons.wallet,
                        Colors.green,
                      ),
                      _buildStatTile(
                        'Tiket Dibeli',
                        '$_totalTickets',
                        Icons.confirmation_number,
                        Colors.blue,
                      ),
                      _buildStatTile(
                        'Destinasi Dikunjungi',
                        '${_paymentHistory.where((t) => t['status'] == 'success').length}',
                        Icons.place,
                        Colors.orange,
                      ),
                      _buildStatTile(
                        'Member Sejak',
                        'Dec 2025',
                        Icons.calendar_today,
                        Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Payment History
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Riwayat Pembayaran',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            _buildPaymentHistory(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00897B), Color(0xFF004D40)],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: widget.currentUser.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      widget.currentUser.photoUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      (widget.currentUser.name ?? 'U')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00897B),
                      ),
                    ),
                  ),
          ),
          SizedBox(height: 16),
          Text(
            widget.currentUser.name ?? 'User',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.currentUser.email,
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Member Regular',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    if (_paymentHistory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 48, color: Colors.grey[300]),
              SizedBox(height: 12),
              Text(
                'Belum ada riwayat pembayaran',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24),
      itemCount: _paymentHistory.length,
      itemBuilder: (context, index) {
        final payment = _paymentHistory[index];
        return _buildPaymentItem(payment);
      },
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    final isSuccess = payment['status'] == 'success';
    final icon = isSuccess ? Icons.check_circle : Icons.schedule;
    final color = isSuccess ? Colors.green : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment['destination'],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'ID: ${payment['id']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        payment['method'],
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  _formatDate(payment['date']),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rp ${_formatCurrency(payment['amount'])}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${payment['tickets']} tiket',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hari ini';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
