import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/destination.dart';
import 'map_page.dart';
import '../db/database_helper.dart';

class AddDestinationPage extends StatefulWidget {
  final Destination? destination;

  const AddDestinationPage({this.destination, super.key});

  @override
  State<AddDestinationPage> createState() => _AddDestinationPageState();
}

class _AddDestinationPageState extends State<AddDestinationPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _ticketCtrl = TextEditingController();

  String _open = '08:00';
  String _close = '17:00';
  String _category = 'Pantai';
  String? _imagePath;
  bool _isLoading = false;

  final db = DatabaseHelper();

  final List<String> categories = [
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
    if (widget.destination != null) {
      final d = widget.destination!;
      _nameCtrl.text = d.name;
      _descCtrl.text = d.description;
      _addrCtrl.text = d.address;
      _latCtrl.text = d.latitude.toString();
      _lngCtrl.text = d.longitude.toString();
      _ticketCtrl.text = d.ticketInfo;
      _open = d.openTime;
      _close = d.closeTime;
      _imagePath = d.imagePath;
      _category = d.category;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addrCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _ticketCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _pickFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPage(pickLocation: true)),
    );
    if (result != null && result is Map) {
      final lat = result['latitude'];
      final lng = result['longitude'];
      final addr = result['address'];
      if (lat != null && lng != null) {
        setState(() {
          _latCtrl.text = lat.toString();
          _lngCtrl.text = lng.toString();
          if (addr != null && (addr as String).isNotEmpty) {
            _addrCtrl.text = addr;
          }
        });
      }
    }
  }

  Future<void> _pickTime(bool isOpen) async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (t != null) {
      final s =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isOpen) {
          _open = s;
        } else {
          _close = s;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = Destination(
        id: widget.destination?.id,
        name: _nameCtrl.text,
        description: _descCtrl.text,
        address: _addrCtrl.text,
        latitude: double.tryParse(_latCtrl.text) ?? 0,
        longitude: double.tryParse(_lngCtrl.text) ?? 0,
        imagePath: _imagePath,
        openTime: _open,
        closeTime: _close,
        category: _category,
        ticketInfo: _ticketCtrl.text,
      );

      if (widget.destination == null) {
        await db.insertDestination(data);
      } else {
        await db.updateDestination(data);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Kembali',
        ),
        title: Text(
          widget.destination == null ? "Tambah Destinasi" : "Edit Destinasi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                _buildImageSection(),
                const SizedBox(height: 24),

                // Form Fields
                Text(
                  'Informasi Destinasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 16),

                // Name Field
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Nama Destinasi",
                    hintText: "Contoh: Taman Nasional Komodo",
                    prefixIcon: Icon(Icons.place, color: Color(0xFF00897B)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? "Nama destinasi wajib diisi" : null,
                ),
                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Deskripsi",
                    hintText: "Jelaskan keunikan dan atraksi destinasi ini...",
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Icon(Icons.description, color: Color(0xFF00897B)),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Address Field
                TextFormField(
                  controller: _addrCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Alamat Lengkap",
                    hintText: "Jl. Raya No. 123, Kota, Provinsi",
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(Icons.location_on, color: Color(0xFF00897B)),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Field
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: "Kategori Wisata",
                    prefixIcon: Icon(Icons.category, color: Color(0xFF00897B)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _category = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Ticket Info Field
                TextFormField(
                  controller: _ticketCtrl,
                  decoration: InputDecoration(
                    labelText: "Informasi Tiket Masuk",
                    hintText: "Contoh: Gratis / Rp 10.000",
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(
                        Icons.confirmation_number,
                        color: Color(0xFF00897B),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Coordinates Section
                Text(
                  'Koordinat Lokasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Latitude",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Longitude",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _pickFromMap,
                    icon: Icon(Icons.map_outlined),
                    label: Text('Pilih dari Peta'),
                  ),
                ),
                const SizedBox(height: 24),

                // Operating Hours Section
                Text(
                  'Jam Operasional',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 16),

                // Opening Time
                _buildTimeCard(
                  'Jam Buka',
                  _open,
                  Icons.schedule,
                  () => _pickTime(true),
                ),
                const SizedBox(height: 12),

                // Closing Time
                _buildTimeCard(
                  'Jam Tutup',
                  _close,
                  Icons.schedule,
                  () => _pickTime(false),
                ),
                const SizedBox(height: 28),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _save,
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
                            widget.destination == null
                                ? 'Tambah Destinasi'
                                : 'Simpan Perubahan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF00897B).withValues(alpha: 77)),
      ),
      child: Column(
        children: [
          if (_imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_imagePath!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.image,
                size: 80,
                color: Color(0xFF00897B).withValues(alpha: 77),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.photo_library, color: Color(0xFF00897B)),
              label: Text(
                _imagePath == null ? 'Pilih Foto' : 'Ganti Foto',
                style: TextStyle(color: Color(0xFF00897B)),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Color(0xFF00897B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(
    String label,
    String time,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF00897B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Color(0xFF00897B)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text('Ubah', style: TextStyle(color: Color(0xFF00897B))),
          ),
        ],
      ),
    );
  }
}
