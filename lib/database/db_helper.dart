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
      version: 11,
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
        if (oldVersion < 8) {
          await _migrateV8(db);
        }
        if (oldVersion < 9) {
          await _migrateV9(db);
        }
        if (oldVersion < 10) {
          await _migrateV10(db);
        }
        if (oldVersion < 11) {
          await _migrateV11(db);
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

    await _createNoteScansTable(db);
    await _createIndexes(db);
  }

  Future<void> _createNoteScansTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS note_scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal TEXT NOT NULL,
        image_blob BLOB NOT NULL,
        extracted_text TEXT NOT NULL DEFAULT '',
        entries_json TEXT NOT NULL DEFAULT '[]',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_note_scans_tanggal ON note_scans(tanggal)',
    );
  }

  Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_rentals_tanggal ON rentals(tanggal)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_rentals_ps_nomor ON rentals(ps_nomor)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_tanggal ON expenses(tanggal)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_deposits_nama ON time_deposits(nama)');
  }

  Future<void> _migrateV6(Database db) async {
    final cols = await db.rawQuery('PRAGMA table_info(expenses)');
    final names = cols.map((c) => c['name'] as String).toSet();
    if (!names.contains('kategori')) {
      await db.execute("ALTER TABLE expenses ADD COLUMN kategori TEXT NOT NULL DEFAULT 'Lainnya'");
    }
  }

  Future<void> _migrateV8(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_rentals_tanggal ON rentals(tanggal)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_tanggal ON expenses(tanggal)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_deposits_nama ON time_deposits(nama)');
  }

  Future<void> _migrateV9(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_rentals_ps_nomor ON rentals(ps_nomor)');
  }

  Future<void> _migrateV10(Database db) async {
    await _createNoteScansTable(db);
  }

  Future<void> _migrateV11(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'note_scans'",
    );
    if (tables.isEmpty) {
      await _createNoteScansTable(db);
      return;
    }

    final columns = await db.rawQuery('PRAGMA table_info(note_scans)');
    final names = columns.map((column) => column['name'] as String).toSet();
    if (!names.contains('entries_json')) {
      await db.execute(
        "ALTER TABLE note_scans ADD COLUMN entries_json TEXT NOT NULL DEFAULT '[]'",
      );
    }
  }

  // ==========================================
  // RENTALS
  // ==========================================

  Future<int> insertRental(Rental rental) async {
    final db = await instance.database;
    return await db.insert('rentals', rental.toMap());
  }

  Future<int> updateRental(Rental rental) async {
    final db = await instance.database;
    return await db.update('rentals', rental.toMap(), where: 'id = ?', whereArgs: [rental.id]);
  }

  /// Saves a rental and consumes any time deposit in one SQLite transaction.
  /// If either operation fails, both changes are rolled back.
  Future<int> simpanRentalAtomik(
    Rental rental, {
    required bool editMode,
    String? namaDeposit,
    int menitDeposit = 0,
  }) async {
    final db = await instance.database;
    return db.transaction<int>((txn) async {
      if (!editMode && menitDeposit > 0) {
        final namaBersih = (namaDeposit ?? '').trim();
        if (namaBersih.isEmpty) {
          throw StateError('Nama pelanggan diperlukan untuk memakai deposit.');
        }

        final rows = await txn.query(
          'time_deposits',
          where: 'LOWER(nama) = ?',
          whereArgs: [namaBersih.toLowerCase()],
          limit: 1,
        );
        if (rows.isEmpty) {
          throw StateError('Deposit waktu tidak ditemukan. Periksa kembali nama pelanggan.');
        }

        final tersedia = rows.first['sisa_menit'] as int;
        if (tersedia < menitDeposit) {
          throw StateError('Sisa waktu berubah. Muat ulang nama pelanggan sebelum menyimpan.');
        }

        final sisaBaru = tersedia - menitDeposit;
        if (sisaBaru <= 0) {
          await txn.delete(
            'time_deposits',
            where: 'LOWER(nama) = ?',
            whereArgs: [namaBersih.toLowerCase()],
          );
        } else {
          await txn.update(
            'time_deposits',
            {'sisa_menit': sisaBaru},
            where: 'LOWER(nama) = ?',
            whereArgs: [namaBersih.toLowerCase()],
          );
        }
      }

      if (editMode) {
        final id = rental.id;
        if (id == null) throw StateError('ID sewa tidak ditemukan.');
        await txn.update('rentals', rental.toMap(), where: 'id = ?', whereArgs: [id]);
        return id;
      }

      final values = rental.toMap()..remove('id');
      return txn.insert('rentals', values);
    });
  }

  Future<int> deleteRental(int id) async {
    final db = await instance.database;
    return await db.delete('rentals', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Rental>> getRentalsByDate(String tanggal) async {
    final db = await instance.database;
    final result = await db.query(
      'rentals',
      where: 'tanggal = ?',
      whereArgs: [tanggal],
      orderBy: 'id DESC',
    );
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

  Future<List<Rental>> getRentalsFromDate(String startDate) async {
    final db = await instance.database;
    final result = await db.query(
      'rentals',
      where: 'tanggal >= ?',
      whereArgs: [startDate],
      orderBy: 'tanggal ASC, id ASC',
    );
    return result.map((json) => Rental.fromMap(json)).toList();
  }

  // ==========================================
  // EXPENSES
  // ==========================================

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
    final result = await db.query(
      'expenses',
      where: 'tanggal = ?',
      whereArgs: [tanggal],
      orderBy: 'id DESC',
    );
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

  // ==========================================
  // TIME DEPOSITS
  // ==========================================

  Future<int> getSisaMenit(String nama) async {
    final db = await instance.database;
    final result = await db.query(
      'time_deposits',
      where: 'LOWER(nama) = ?',
      whereArgs: [nama.trim().toLowerCase()],
    );
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


  // ==========================================
  // NOTEBOOK PHOTO ARCHIVE
  // ==========================================

  Future<int> insertNoteScan({
    required String tanggal,
    required List<int> imageBytes,
    required String extractedText,
    required String entriesJson,
    required String createdAt,
  }) async {
    final db = await instance.database;
    return db.insert('note_scans', {
      'tanggal': tanggal,
      'image_blob': imageBytes,
      'extracted_text': extractedText,
      'entries_json': entriesJson,
      'created_at': createdAt,
    });
  }

  Future<List<Map<String, dynamic>>> getNoteScansByDate(String tanggal) async {
    final db = await instance.database;
    return db.query(
      'note_scans',
      where: 'tanggal = ?',
      whereArgs: [tanggal],
      orderBy: 'id DESC',
    );
  }

  Future<int> updateNoteScanText({
    required int id,
    required String extractedText,
  }) async {
    final db = await instance.database;
    return db.update(
      'note_scans',
      {'extracted_text': extractedText},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateNoteScanReview({
    required int id,
    required String extractedText,
    required String entriesJson,
  }) async {
    final db = await instance.database;
    return db.update(
      'note_scans',
      {
        'extracted_text': extractedText,
        'entries_json': entriesJson,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNoteScan(int id) async {
    final db = await instance.database;
    return db.delete('note_scans', where: 'id = ?', whereArgs: [id]);
  }

}
