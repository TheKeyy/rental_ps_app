import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/rental_model.dart';
import '../models/expense_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('rental_ps.db');
    return _database!;
  }

  Future<void> closeDb() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS time_deposits (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nama TEXT NOT NULL UNIQUE,
              sisa_menit INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS expenses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              keterangan TEXT NOT NULL,
              nominal INTEGER NOT NULL,
              tanggal TEXT NOT NULL,
              waktu TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 6) {
          await _migrateV6(db);
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rentals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        ps_nomor INTEGER NOT NULL,
        waktu_mulai TEXT NOT NULL,
        waktu_selesai TEXT NOT NULL,
        durasi_menit INTEGER NOT NULL,
        saldo INTEGER NOT NULL,
        metode_bayar TEXT NOT NULL,
        tanggal TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE time_deposits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL UNIQUE,
        sisa_menit INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        keterangan TEXT NOT NULL,
        nominal INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        waktu TEXT NOT NULL,
        kategori TEXT NOT NULL DEFAULT 'Lainnya'
      )
    ''');
  }

  Future<void> _migrateV6(Database db) async {
    final cols = await db.rawQuery('PRAGMA table_info(expenses)');
    final names = cols.map((c) => c['name'] as String).toSet();
    if (!names.contains('kategori')) {
      await db.execute("ALTER TABLE expenses ADD COLUMN kategori TEXT NOT NULL DEFAULT 'Lainnya'");
    }
  }

  Future<int> insertRental(Rental rental) async {
    final db = await instance.database;
    return await db.insert('rentals', rental.toMap());
  }

  Future<int> updateRental(Rental rental) async {
    final db = await instance.database;
    return await db.update('rentals', rental.toMap(), where: 'id = ?', whereArgs: [rental.id]);
  }

  Future<int> deleteRental(int id) async {
    final db = await instance.database;
    return await db.delete('rentals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Rental>> getRentalsByDate(String tanggal) async {
    final db = await instance.database;
    final result = await db.query('rentals', where: 'tanggal = ?', whereArgs: [tanggal], orderBy: 'id DESC');
    return result.map((json) => Rental.fromMap(json)).toList();
  }

  Future<List<Rental>> getRentalsByDateRange(String startDate, String endDate) async {
    final db = await instance.database;
    final result = await db.query(
      'rentals',
      where: 'tanggal >= ? AND tanggal <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'tanggal DESC, id DESC',
    );
    return result.map((json) => Rental.fromMap(json)).toList();
  }

  Future<int> insertExpense(Expense exp) async {
    final db = await instance.database;
    return await db.insert('expenses', exp.toMap());
  }

  Future<int> updateExpense(Expense exp) async {
    final db = await instance.database;
    return await db.update('expenses', exp.toMap(), where: 'id = ?', whereArgs: [exp.id]);
  }

  Future<List<Expense>> getExpensesByDate(String tanggal) async {
    final db = await instance.database;
    final result = await db.query('expenses', where: 'tanggal = ?', whereArgs: [tanggal], orderBy: 'id DESC');
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<List<Expense>> getExpensesByDateRange(String startDate, String endDate) async {
    final db = await instance.database;
    final result = await db.query(
      'expenses',
      where: 'tanggal >= ? AND tanggal <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'tanggal DESC, id DESC',
    );
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getSisaMenit(String nama) async {
    final db = await instance.database;
    final result = await db.query('time_deposits', where: 'LOWER(nama) = ?', whereArgs: [nama.trim().toLowerCase()]);
    if (result.isNotEmpty) {
      return result.first['sisa_menit'] as int;
    }
    return 0;
  }

  Future<void> tambahSisaMenit(String nama, int menit) async {
    final db = await instance.database;
    final cleanName = nama.trim();
    final existing = await getSisaMenit(cleanName);

    if (existing > 0) {
      await db.update(
        'time_deposits',
        {'sisa_menit': existing + menit},
        where: 'LOWER(nama) = ?',
        whereArgs: [cleanName.toLowerCase()],
      );
    } else {
      await db.insert('time_deposits', {'nama': cleanName, 'sisa_menit': menit});
    }
  }

  Future<void> gunakanSisaMenit(String nama, int menitDipakai) async {
    final db = await instance.database;
    final cleanName = nama.trim();
    final current = await getSisaMenit(cleanName);
    final sisaBaru = current - menitDipakai;

    if (sisaBaru <= 0) {
      await db.delete('time_deposits', where: 'LOWER(nama) = ?', whereArgs: [cleanName.toLowerCase()]);
    } else {
      await db.update(
        'time_deposits',
        {'sisa_menit': sisaBaru},
        where: 'LOWER(nama) = ?',
        whereArgs: [cleanName.toLowerCase()],
      );
    }
  }

  Future<void> setSisaMenit(int id, int menit) async {
    final db = await instance.database;
    if (menit <= 0) {
      await db.delete('time_deposits', where: 'id = ?', whereArgs: [id]);
    } else {
      await db.update('time_deposits', {'sisa_menit': menit}, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> hapusDeposit(int id) async {
    final db = await instance.database;
    await db.delete('time_deposits', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllDeposits() async {
    final db = await instance.database;
    return await db.query('time_deposits', where: 'sisa_menit > 0', orderBy: 'nama ASC');
  }
}
