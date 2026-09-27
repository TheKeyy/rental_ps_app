import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/rental_model.dart';
import '../models/expense_model.dart';
import '../models/snack_item_model.dart';
import '../models/snack_model.dart';

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
      version: 9,
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
        if (oldVersion < 7) {
          await _migrateV7(db);
        }
        if (oldVersion < 8) {
          await _migrateV8(db);
        }
        if (oldVersion < 9) {
          await _migrateV9(db);
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

    await db.execute('''
      CREATE TABLE snack_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        harga INTEGER NOT NULL,
        stok INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE snack_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_pembeli TEXT NOT NULL,
        detail_item TEXT NOT NULL,
        total_harga INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        waktu TEXT NOT NULL
      )
    ''');

    await _createIndexes(db);
  }

  Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_rentals_tanggal ON rentals(tanggal)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_rentals_ps_nomor ON rentals(ps_nomor)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_tanggal ON expenses(tanggal)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_snack_orders_tanggal ON snack_orders(tanggal)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_deposits_nama ON time_deposits(nama)');
  }

  Future<void> _migrateV6(Database db) async {
    final cols = await db.rawQuery('PRAGMA table_info(expenses)');
    final names = cols.map((c) => c['name'] as String).toSet();
    if (!names.contains('kategori')) {
      await db.execute("ALTER TABLE expenses ADD COLUMN kategori TEXT NOT NULL DEFAULT 'Lainnya'");
    }
  }

  Future<void> _migrateV7(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS snack_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        harga INTEGER NOT NULL,
        stok INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS snack_orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_pembeli TEXT NOT NULL,
        detail_item TEXT NOT NULL,
        total_harga INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        waktu TEXT NOT NULL
      )
    ''');
  }

  Future<void> _migrateV8(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_rentals_tanggal ON rentals(tanggal)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_tanggal ON expenses(tanggal)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_snack_orders_tanggal ON snack_orders(tanggal)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_deposits_nama ON time_deposits(nama)');
  }

  Future<void> _migrateV9(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_rentals_ps_nomor ON rentals(ps_nomor)');
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

  Future<void> gunakanSisaMenit(String nama, int menitDipakai) async {
    final db = await instance.database;
    final cleanName = nama.trim();
    final current = await getSisaMenit(cleanName);
    final sisaBaru = current - menitDipakai;

    if (sisaBaru <= 0) {
      await db.delete(
        'time_deposits',
        where: 'LOWER(nama) = ?',
        whereArgs: [cleanName.toLowerCase()],
      );
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

  // ==========================================
  // SNACK ITEMS & ORDERS
  // ==========================================

  Future<List<SnackItem>> getAllSnackItems() async {
    final db = await instance.database;
    final result = await db.query('snack_items', orderBy: 'nama ASC');
    return result.map((json) => SnackItem.fromMap(json)).toList();
  }

  Future<int> insertSnackItem(SnackItem item) async {
    final db = await instance.database;
    return await db.insert('snack_items', item.toMap());
  }

  Future<int> updateSnackItem(SnackItem item) async {
    final db = await instance.database;
    return await db.update('snack_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteSnackItem(int id) async {
    final db = await instance.database;
    return await db.delete('snack_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reduceStock(int id, int qty) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      final items = await txn.query('snack_items', where: 'id = ?', whereArgs: [id]);
      if (items.isNotEmpty) {
        final curStock = items.first['stok'] as int;
        final newStock = (curStock - qty) < 0 ? 0 : (curStock - qty);
        await txn.update(
          'snack_items',
          {'stok': newStock},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  Future<int> insertSnackOrder(SnackOrder order) async {
    final db = await instance.database;
    return await db.insert('snack_orders', order.toMap());
  }

  Future<List<SnackOrder>> getSnackOrdersByDate(String tanggal) async {
    final db = await instance.database;
    final result = await db.query(
      'snack_orders',
      where: 'tanggal = ?',
      whereArgs: [tanggal],
      orderBy: 'id DESC',
    );
    return result.map((json) => SnackOrder.fromMap(json)).toList();
  }

  Future<List<SnackOrder>> getSnackOrdersByDateRange(String startDate, String endDate) async {
    final db = await instance.database;
    final result = await db.query(
      'snack_orders',
      where: 'tanggal >= ? AND tanggal <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'tanggal DESC, id DESC',
    );
    return result.map((json) => SnackOrder.fromMap(json)).toList();
  }

  Future<int> deleteSnackOrder(int id) async {
    final db = await instance.database;
    return await db.delete('snack_orders', where: 'id = ?', whereArgs: [id]);
  }
}
