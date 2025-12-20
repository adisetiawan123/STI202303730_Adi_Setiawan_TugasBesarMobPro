import 'dart:io';
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/destination.dart';
import '../services/auth_service.dart';
import '../widgets/destination_card.dart';
import 'add_destination_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_tickets_page.dart';
import 'map_page.dart';
import 'profile_page.dart';
import 'my_tickets_page.dart';
import 'ticket_purchase_page.dart';
import 'payment_debug_page.dart';

class HomePage extends StatefulWidget {
  final User currentUser;
  final VoidCallback onLogout;

  const HomePage({
    required this.currentUser,
    required this.onLogout,
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _selectedCategory = 'Semua';
  List<Destination> _destinations = [];
  final db = DatabaseHelper();
  User? _currentUser;

  final List<String> categories = [
    'Semua',
    'Pantai',
    'Gunung',
    'Sejarah',
    'Taman',
    'Danau',
    'Kuliner',
    'Budaya',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _currentUser = widget.currentUser;
  }

  Future<void> _loadData() async {
    final list = await db.getAllDestinations();
    setState(() => _destinations = list);
  }

  void _editDestination(Destination dest) async {
    // Check if user is admin
    if (_currentUser == null) {
      _showAccessDenied('Silakan login terlebih dahulu');
      return;
    }

    if (_currentUser!.role != 'admin') {
      _showAccessDenied('Hanya admin yang dapat mengedit destinasi');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddDestinationPage(destination: dest)),
    );
    _loadData();
  }

  void _deleteDestination(int id) async {
    // Check if user is admin
    if (_currentUser == null) {
      _showAccessDenied('Silakan login terlebih dahulu');
      return;
    }

    if (_currentUser!.role != 'admin') {
      _showAccessDenied('Hanya admin yang dapat menghapus destinasi');
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus Destinasi'),
        content: Text('Apakah Anda yakin ingin menghapus destinasi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await db.deleteDestination(id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Destinasi dihapus'),
                  backgroundColor: Color(0xFF00897B),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _loadData();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showAccessDenied(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build pages list based on admin status
    final List<Widget> pages = [
      _buildListView(),
      MapPage(),
      _currentUser != null
          ? MyTicketsPage(currentUser: _currentUser!)
          : _buildLoginPrompt(),
      ProfilePage(onLogout: widget.onLogout),
    ];

    // If admin, build separate admin pages list with Dashboard and Admin Tickets
    final List<Widget> adminPages = [
      _buildListView(),
      AdminDashboardPage(),
      MapPage(),
      AdminTicketsPage(),
      ProfilePage(onLogout: widget.onLogout),
      const PaymentDebugPage(), // Debug page for payment testing
    ];

    final currentPages = _currentUser?.role == 'admin' ? adminPages : pages;
    final displayIndex = _currentIndex;

    return Scaffold(
      appBar: AppBar(
        leading: displayIndex != 0
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentIndex = 0),
                tooltip: 'Kembali ke Beranda',
              )
            : null,
        title: Text(
          _getTabTitle(displayIndex),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: displayIndex == 0
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeGreeting(),
                  _buildPopularDestinationsSection(),
                  _buildCategoryFilterSection(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Semua Destinasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ),
                  SizedBox(height: 400, child: _buildListView()),
                ],
              ),
            )
          : currentPages[displayIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: displayIndex,
        onTap: (i) async {
          setState(() => _currentIndex = i);
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          if (_currentUser?.role == 'admin')
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Kelola',
            ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Peta'),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Tiket',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          if (_currentUser?.role == 'admin')
            BottomNavigationBarItem(
              icon: Icon(Icons.bug_report),
              label: 'Debug',
            ),
        ],
      ),
      floatingActionButton: displayIndex == 0 && _currentUser?.role == 'admin'
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddDestinationPage()),
                );
                _loadData();
              },
              tooltip: 'Tambah Destinasi',
              child: Icon(Icons.add),
            )
          : null,
    );
  }

  String _getTabTitle(int index) {
    // Adjust title based on whether user is admin
    if (_currentUser?.role == 'admin') {
      switch (index) {
        case 0:
          return 'Travel Wisata Lokal';
        case 1:
          return 'Kelola Destinasi';
        case 2:
          return 'Peta Destinasi';
        case 3:
          return 'Tiket Saya';
        case 4:
          return 'Profil';
        default:
          return 'Travel Wisata Lokal';
      }
    } else {
      switch (index) {
        case 0:
          return 'Travel Wisata Lokal';
        case 1:
          return 'Peta Destinasi';
        case 2:
          return 'Tiket Saya';
        case 3:
          return 'Profil';
        default:
          return 'Travel Wisata Lokal';
      }
    }
  }

  Widget _buildLoginPrompt() {
    return Center(
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
            'Silakan Login Terlebih Dahulu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Untuk membeli dan melihat tiket Anda',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => setState(() => _currentIndex = 4),
            icon: Icon(Icons.login),
            label: Text('Masuk ke Profil'),
            style: FilledButton.styleFrom(backgroundColor: Color(0xFF00897B)),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeGreeting() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF004D40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang! 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Jelajahi destinasi wisata lokal terbaik di sekitar Anda',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  '${_destinations.length} Destinasi Tersedia',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularDestinationsSection() {
    List<Destination> popularDests = _destinations
        .where((d) => d.visitCount > 0)
        .toList();

    if (popularDests.isEmpty) {
      return SizedBox.shrink();
    }

    // Sort by visitCount descending
    popularDests.sort((a, b) => b.visitCount.compareTo(a.visitCount));

    // Take top 5
    popularDests = popularDests.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Text(
            '⭐ Destinasi Populer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: popularDests.map((dest) {
              return _buildPopularDestinationCard(dest);
            }).toList(),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPopularDestinationCard(Destination dest) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 26),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Increment visit count
          dest.visitCount++;
          db.updateDestination(dest);
          _loadData();
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                height: 100,
                color: Colors.grey[200],
                child: dest.imagePath != null
                    ? Image.file(
                        File(dest.imagePath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: Color(0xFFE0F2F1),
                        child: Icon(Icons.landscape, color: Color(0xFF00897B)),
                      ),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dest.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF212121),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  // Ticket info
                  if (dest.ticketInfo.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.confirmation_number,
                          size: 18,
                          color: Color(0xFF00897B),
                        ),
                        SizedBox(width: 8),
                        Expanded(child: Text(dest.ticketInfo)),
                      ],
                    ),
                  if (dest.ticketInfo.isNotEmpty) SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      dest.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF00897B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(Icons.favorite, size: 12, color: Colors.red),
                      SizedBox(width: 2),
                      Text(
                        '${dest.visitCount}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            'Filter Kategori',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = cat);
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: Color(0xFF00897B),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildListView() {
    List<Destination> filteredDestinations = _destinations;
    if (_selectedCategory != 'Semua') {
      filteredDestinations = _destinations
          .where((d) => d.category == _selectedCategory)
          .toList();
    }

    return filteredDestinations.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 64, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  _selectedCategory == 'Semua'
                      ? 'Belum ada destinasi'
                      : 'Tidak ada destinasi di kategori ini',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tekan tombol + untuk menambah destinasi baru',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: filteredDestinations.length,
            itemBuilder: (context, index) {
              final d = filteredDestinations[index];
              return DestinationCard(
                dest: d,
                isAdmin: _currentUser?.role == 'admin',
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text(d.name),
                      contentPadding: EdgeInsets.all(20),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (d.imagePath != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(d.imagePath!),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            if (d.imagePath != null) SizedBox(height: 16),
                            Text(d.description, style: TextStyle(fontSize: 14)),
                            SizedBox(height: 12),
                            Divider(),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: Color(0xFF00897B),
                                ),
                                SizedBox(width: 8),
                                Expanded(child: Text(d.address)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: Color(0xFF00897B),
                                ),
                                SizedBox(width: 8),
                                Text('${d.openTime} - ${d.closeTime}'),
                              ],
                            ),
                            SizedBox(height: 8),
                            // Ticket info
                            if (d.ticketInfo.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.confirmation_number,
                                    size: 18,
                                    color: Color(0xFF00897B),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(child: Text(d.ticketInfo)),
                                ],
                              ),
                            if (d.ticketInfo.isNotEmpty) SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.public,
                                  size: 18,
                                  color: Color(0xFF00897B),
                                ),
                                SizedBox(width: 8),
                                Text('${d.latitude}, ${d.longitude}'),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.category,
                                  size: 18,
                                  color: Color(0xFF00897B),
                                ),
                                SizedBox(width: 8),
                                Text(d.category),
                              ],
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: Text('Tutup'),
                        ),
                        if (_currentUser != null &&
                            d.ticketInfo.isNotEmpty &&
                            _currentUser!.role != 'admin')
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(c);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TicketPurchasePage(
                                    destination: d,
                                    currentUser: _currentUser!,
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.confirmation_number),
                            label: Text('Beli Tiket'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Color(0xFF00897B),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                onEdit: () => _editDestination(d),
                onDelete: () => _deleteDestination(d.id!),
              );
            },
          );
  }
}
