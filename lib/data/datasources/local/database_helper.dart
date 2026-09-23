import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/ticket_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sporthub_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tickets (
        id TEXT PRIMARY KEY,
        booking_id TEXT NOT NULL,
        venue_name TEXT NOT NULL,
        sport_type TEXT NOT NULL,
        court_number INTEGER NOT NULL,
        match_date TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        total_price REAL NOT NULL,
        qr_code_data TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertTicket(TicketModel ticket) async {
    final db = await instance.database;
    return await db.insert('tickets', ticket.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TicketModel>> getTickets() async {
    final db = await instance.database;
    final maps = await db.query('tickets', orderBy: 'created_at DESC');
    return maps.map((e) => TicketModel.fromMap(e)).toList();
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
