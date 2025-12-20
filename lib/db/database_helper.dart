import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/destination.dart';
import '../models/ticket.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'travel_wisata_lokal.db');

    return await openDatabase(
      path,
      version: 5, // bumped to include tickets table
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // 🔼 MIGRASI DATABASE
  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Tambah kolom category (jika belum ada)
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE destinations ADD COLUMN category TEXT DEFAULT "Lainnya"',
        );
      } catch (e) {
        // Jika sudah ada, lewati
      }
    }

    // Tambah kolom visitCount (jika belum ada)
    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE destinations ADD COLUMN visitCount INTEGER DEFAULT 0',
        );
      } catch (e) {
        // Jika sudah ada, lewati
      }
    }

    // Tambah kolom ticketInfo (jika belum ada)
    if (oldVersion < 4) {
      try {
        await db.execute(
          "ALTER TABLE destinations ADD COLUMN ticketInfo TEXT DEFAULT ''",
        );
      } catch (e) {
        // Jika sudah ada, lewati
      }
    }

    // Buat tabel tickets (jika belum ada)
    if (oldVersion < 5) {
      try {
        await db.execute('''
          CREATE TABLE tickets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            destinationId INTEGER,
            destinationName TEXT,
            userEmail TEXT,
            quantity INTEGER,
            ticketPrice TEXT,
            totalPrice TEXT,
            purchaseDate TEXT,
            status TEXT DEFAULT 'pending',
            notes TEXT DEFAULT ''
          )
        ''');
      } catch (e) {
        // Jika sudah ada, lewati
      }
    }
  }

  // 🆕 CREATE TABLE PENUH (UPDATED)
  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE destinations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        address TEXT,
        imagePath TEXT,
        latitude REAL,
        longitude REAL,
        openTime TEXT,
        closeTime TEXT,
        category TEXT DEFAULT "Lainnya",
        visitCount INTEGER DEFAULT 0,
        ticketInfo TEXT DEFAULT ''
      )
    ''');

    // Buat tabel tickets
    await db.execute('''
      CREATE TABLE tickets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        destinationId INTEGER,
        destinationName TEXT,
        userEmail TEXT,
        quantity INTEGER,
        ticketPrice TEXT,
        totalPrice TEXT,
        purchaseDate TEXT,
        status TEXT DEFAULT 'pending',
        notes TEXT DEFAULT ''
      )
    ''');
  }

  // ➕ INSERT DESTINATION
  Future<int> insertDestination(Destination dest) async {
    final db = await database;
    return await db.insert('destinations', dest.toMap());
  }

  // 📄 GET LIST DESTINATIONS
  Future<List<Destination>> getAllDestinations() async {
    final db = await database;
    final res = await db.query('destinations', orderBy: 'id DESC');
    return res.map((e) => Destination.fromMap(e)).toList();
  }

  // ✏ UPDATE DESTINATION
  Future<int> updateDestination(Destination dest) async {
    final db = await database;
    return await db.update(
      'destinations',
      dest.toMap(),
      where: 'id = ?',
      whereArgs: [dest.id],
    );
  }

  // ❌ DELETE DESTINATION
  Future<int> deleteDestination(int id) async {
    final db = await database;
    return await db.delete('destinations', where: 'id = ?', whereArgs: [id]);
  }

  // ========== TICKET OPERATIONS ==========

  // ➕ INSERT TICKET
  Future<int> insertTicket(Ticket ticket) async {
    final db = await database;
    return await db.insert('tickets', ticket.toMap());
  }

  // 📄 GET ALL TICKETS BY USER EMAIL
  Future<List<Ticket>> getTicketsByEmail(String userEmail) async {
    final db = await database;
    final res = await db.query(
      'tickets',
      where: 'userEmail = ?',
      whereArgs: [userEmail],
      orderBy: 'purchaseDate DESC',
    );
    return res.map((e) => Ticket.fromMap(e)).toList();
  }

  // 📄 GET ALL TICKETS
  Future<List<Ticket>> getAllTickets() async {
    final db = await database;
    final res = await db.query('tickets', orderBy: 'purchaseDate DESC');
    return res.map((e) => Ticket.fromMap(e)).toList();
  }

  // 📄 GET TICKETS BY DESTINATION
  Future<List<Ticket>> getTicketsByDestination(int destinationId) async {
    final db = await database;
    final res = await db.query(
      'tickets',
      where: 'destinationId = ?',
      whereArgs: [destinationId],
      orderBy: 'purchaseDate DESC',
    );
    return res.map((e) => Ticket.fromMap(e)).toList();
  }

  // ✏ UPDATE TICKET
  Future<int> updateTicket(Ticket ticket) async {
    final db = await database;
    return await db.update(
      'tickets',
      ticket.toMap(),
      where: 'id = ?',
      whereArgs: [ticket.id],
    );
  }

  // ❌ DELETE TICKET
  Future<int> deleteTicket(int id) async {
    final db = await database;
    return await db.delete('tickets', where: 'id = ?', whereArgs: [id]);
  }
}
