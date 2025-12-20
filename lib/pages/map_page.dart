import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../db/database_helper.dart';
import '../models/destination.dart';

class MapPage extends StatefulWidget {
  final bool pickLocation;

  const MapPage({this.pickLocation = false, super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  List<Destination> _allDestinations = [];
  List<Destination> _filteredDestinations = [];
  String _searchQuery = '';
  late TextEditingController _searchController;
  LatLng? _pickedLatLng;
  String? _pickedAddress;
  final db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadMarkers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkers() async {
    final list = await db.getAllDestinations();
    if (!mounted) return;
    setState(() {
      _allDestinations = list;
      _filteredDestinations = list;
    });
    _updateMarkers();
  }

  void _updateMarkers() {
    final filtered = _allDestinations
        .where(
          (d) =>
              d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.address.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    setState(() {
      _filteredDestinations = filtered;
    });

    final m = filtered.map(
      (d) => Marker(
        markerId: MarkerId(d.id.toString()),
        position: LatLng(d.latitude, d.longitude),
        infoWindow: InfoWindow(title: d.name, snippet: d.address),
      ),
    );
    final markerSet = m.toSet();
    // if a location was picked (picker mode), show that marker too
    if (_pickedLatLng != null) {
      markerSet.add(
        Marker(
          markerId: const MarkerId('picked_location'),
          position: _pickedLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(title: _pickedAddress ?? 'Lokasi terpilih'),
        ),
      );
    }
    setState(() => _markers = markerSet);
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _updateMarkers();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    _updateMarkers();
  }

  Future<void> _forwardGeocode(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final latlng = LatLng(loc.latitude, loc.longitude);
        _controller?.animateCamera(CameraUpdate.newLatLngZoom(latlng, 15));
        if (widget.pickLocation) {
          _pickedLatLng = latlng;
          final placemarks = await placemarkFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          if (!mounted) return;
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            _pickedAddress = '${p.street ?? ''} ${p.locality ?? ''}'.trim();
          } else {
            _pickedAddress = query;
          }
          _updateMarkers();
        } else {
          // temporarily show a marker for found location
          setState(() {
            _markers = _markers
                .where((m) => m.markerId.value != 'search_result')
                .toSet();
            _markers.add(
              Marker(
                markerId: const MarkerId('search_result'),
                position: latlng,
                infoWindow: InfoWindow(title: query),
              ),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencari alamat: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _pickedAddress =
            '${p.street ?? ''} ${p.locality ?? ''} ${p.subAdministrativeArea ?? ''}'
                .trim();
      } else {
        _pickedAddress =
            'Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}';
      }
    } catch (e) {
      if (!mounted) return;
      _pickedAddress =
          'Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        // Search Bar dengan Styling Premium
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Search TextField
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 51),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau alamat destinasi...',
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                      color: Colors.blue,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: _clearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              // Hasil Pencarian
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ditemukan ${_filteredDestinations.length} lokasi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Google Map
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-7.434, 109.228),
                  zoom: 12,
                ),
                onMapCreated: (c) => _controller = c,
                markers: _markers,
                onTap: (pos) async {
                  if (widget.pickLocation) {
                    _pickedLatLng = pos;
                    await _reverseGeocode(pos);
                    _updateMarkers();
                  }
                },
              ),
              // Search action button
              Positioned(
                top: 14,
                right: 16,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    elevation: 4,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.search),
                  label: const Text('Cari'),
                  onPressed: () => _forwardGeocode(_searchController.text),
                ),
              ),
              if (widget.pickLocation && _pickedLatLng != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pickedAddress ?? 'Lokasi terpilih',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lat: ${_pickedLatLng!.latitude.toStringAsFixed(6)}, Lng: ${_pickedLatLng!.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop({
                                'latitude': _pickedLatLng!.latitude,
                                'longitude': _pickedLatLng!.longitude,
                                'address': _pickedAddress ?? '',
                              });
                            },
                            child: const Text('Pilih lokasi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    // Wrap body in a Scaffold so SnackBars and Navigator work reliably
    // When in pickLocation mode, show an AppBar for better UX
    return Scaffold(
      appBar: widget.pickLocation
          ? AppBar(
              title: const Text('Pilih Lokasi'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: body,
    );
  }
}
