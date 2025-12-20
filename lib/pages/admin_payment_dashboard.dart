import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

class AdminPaymentDashboard extends StatefulWidget {
  final User adminUser;
  final VoidCallback onLogout;

  const AdminPaymentDashboard({
    required this.adminUser,
    required this.onLogout,
    super.key,
  });

  @override
  State<AdminPaymentDashboard> createState() => _AdminPaymentDashboardState();
}

class _AdminPaymentDashboardState extends State<AdminPaymentDashboard> {
  // Mock data untuk demo - bisa diganti dengan real data dari backend
  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'TXID001',
      'userId': 'user_001',
      'userName': 'Budi Santoso',
      'destination': 'Pantai Bali',
      'amount': 100000,
      'status': 'success',
      'date': DateTime.now().subtract(Duration(days: 2)),
      'method': 'DANA',
    },
    {
      'id': 'TXID002',
      'userId': 'user_002',
      'userName': 'Siti Nurhaliza',
      'destination': 'Gunung Merapi',
      'amount': 75000,
      'status': 'success',
      'date': DateTime.now().subtract(Duration(days: 1)),
      'method': 'OVO',
    },
    {
      'id': 'TXID003',
      'userId': 'user_003',
      'userName': 'Ahmad Wijaya',
      'destination': 'Danau Toba',
      'amount': 150000,
      'status': 'pending',
      'date': DateTime.now(),
      'method': 'GOPAY',
    },
  ];

  int get _totalRevenue {
    return _transactions
        .where((t) => t['status'] == 'success')
        .fold(0, (sum, t) => sum + (t['amount'] as int));
  }

  int get _successTransactions {
    return _transactions.where((t) => t['status'] == 'success').length;
  }

  int get _pendingTransactions {
    return _transactions.where((t) => t['status'] == 'pending').length;
  }

  Future<void> _handleLogout() async {
    // Confirm sebelum logout
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
      // Prefer calling provided callback (usually wired to app-level logout)
      widget.onLogout();

      // As a fallback/robustness step ensure we clear session here too
      final session = SessionService();
      await session.logout();

      if (!mounted) return;

      // Pop to root so app-level navigation (if any) can show LoginPage
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
        title: const Text('Admin - Dashboard Pembayaran'),
        actions: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.adminUser.name ?? 'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '(Admin)',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Dashboard Pembayaran',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),

              // Stats Grid
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildStatCard(
                    title: 'Total Pendapatan',
                    value: 'Rp ${_formatCurrency(_totalRevenue)}',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                  _buildStatCard(
                    title: 'Transaksi Sukses',
                    value: '$_successTransactions',
                    icon: Icons.check_circle,
                    color: Colors.blue,
                  ),
                  _buildStatCard(
                    title: 'Menunggu Verifikasi',
                    value: '$_pendingTransactions',
                    icon: Icons.hourglass_empty,
                    color: Colors.orange,
                  ),
                ],
              ),
              SizedBox(height: 32),

              // Transaction History
              Text(
                'Riwayat Transaksi',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildTransactionTable(),
              SizedBox(height: 32),

              // Payment Methods Summary
              Text(
                'Ringkasan Metode Pembayaran',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              _buildPaymentMethodsSummary(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'ID Transaksi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Pengguna',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Nominal',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ..._transactions.map((tx) {
            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx['id'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          tx['destination'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx['userName'], style: TextStyle(fontSize: 12)),
                        Text(
                          tx['method'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Rp ${_formatCurrency(tx['amount'])}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tx['status'] == 'success'
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tx['status'] == 'success' ? '✓ Sukses' : '⏳ Pending',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: tx['status'] == 'success'
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSummary() {
    final methods = <String, int>{};
    for (var tx in _transactions.where((t) => t['status'] == 'success')) {
      final method = tx['method'] as String;
      methods[method] = (methods[method] ?? 0) + (tx['amount'] as int);
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...methods.entries.map((entry) {
            final total = _totalRevenue;
            final amount = entry.value;
            final percentage = total > 0
                ? (amount / total * 100).toStringAsFixed(1)
                : '0';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Rp ${_formatCurrency(amount)} ($percentage%)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: total > 0 ? amount / total : 0,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(Color(0xFF00897B)),
                    ),
                  ),
                ],
              ),
            );
          }),
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
}
