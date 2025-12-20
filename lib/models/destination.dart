class Destination {
  int? id;
  String name;
  String description;
  String address;
  String? imagePath; // local file path
  double latitude;
  double longitude;
  String openTime; // e.g. 08:00
  String closeTime; // e.g. 17:00
  String category; // kategori wisata
  int visitCount; // jumlah kunjungan
  String ticketInfo; // informasi tiket masuk (mis. Gratis, Rp 10.000)

  Destination({
    this.id,
    required this.name,
    required this.description,
    required this.address,
    this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.openTime,
    required this.closeTime,
    required this.category,
    this.visitCount = 0,
    this.ticketInfo = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'imagePath': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'openTime': openTime,
      'closeTime': closeTime,
      'category': category,
      'visitCount': visitCount,
      'ticketInfo': ticketInfo,
    };
  }

  factory Destination.fromMap(Map<String, dynamic> map) {
    return Destination(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      address: map['address'],
      imagePath: map['imagePath'],
      latitude: map['latitude'] is int
          ? (map['latitude'] as int).toDouble()
          : map['latitude'],
      longitude: map['longitude'] is int
          ? (map['longitude'] as int).toDouble()
          : map['longitude'],
      openTime: map['openTime'],
      closeTime: map['closeTime'],
      category: map['category'] ?? 'Lainnya',
      visitCount: map['visitCount'] ?? 0,
      ticketInfo: map['ticketInfo'] ?? '',
    );
  }
}
