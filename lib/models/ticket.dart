class Ticket {
  int? id;
  int destinationId; // FK to destination
  String destinationName;
  String userEmail;
  int quantity;
  String ticketPrice; // harga tiket (misal: Rp 10.000)
  String totalPrice; // total harga
  String purchaseDate; // tanggal pembelian
  String status; // 'pending', 'confirmed', 'used', 'cancelled'
  String notes;

  Ticket({
    this.id,
    required this.destinationId,
    required this.destinationName,
    required this.userEmail,
    required this.quantity,
    required this.ticketPrice,
    required this.totalPrice,
    required this.purchaseDate,
    this.status = 'pending',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destinationId': destinationId,
      'destinationName': destinationName,
      'userEmail': userEmail,
      'quantity': quantity,
      'ticketPrice': ticketPrice,
      'totalPrice': totalPrice,
      'purchaseDate': purchaseDate,
      'status': status,
      'notes': notes,
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'],
      destinationId: map['destinationId'],
      destinationName: map['destinationName'],
      userEmail: map['userEmail'],
      quantity: map['quantity'],
      ticketPrice: map['ticketPrice'],
      totalPrice: map['totalPrice'],
      purchaseDate: map['purchaseDate'],
      status: map['status'] ?? 'pending',
      notes: map['notes'] ?? '',
    );
  }
}
