import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/rental_model.dart';
import '../models/expense_model.dart';
import '../services/rental_time.dart';

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
      version: 13,
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
        if (oldVersion < 12) {
          await _migrateV12(db);
        }
        if (oldVersion < 13) {
          await _migrateV13(db);
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
    await _createNoteScanImportsTable(db);
    await _createRentalManagementTables(db);
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

  Future<void> _migrateV12(Database db) async {
    await _createRentalManagementTables(db);
  }

  Future<void> _migrateV13(Database db) async {
    await _createNoteScanImportsTable(db);
  }

  Future<void> _createNoteScanImportsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS note_scan_imports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note_scan_id INTEGER NOT NULL,
        row_fingerprint TEXT NOT NULL,
        rental_id INTEGER NOT NULL,
        imported_at TEXT NOT NULL,
        UNIQUE(note_scan_id, row_fingerprint)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_note_scan_imports_scan ON note_scan_imports(note_scan_id)',
    );
  }

  Future<void> _createRentalManagementTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rental_units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unit_code TEXT NOT NULL UNIQUE,
        console_type TEXT NOT NULL,
        display_name TEXT NOT NULL,
        unit_number INTEGER NOT NULL UNIQUE,
        hourly_rate INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT NOT NULL,
        customer_phone TEXT NOT NULL DEFAULT '',
        unit_id INTEGER NOT NULL,
        start_at TEXT NOT NULL,
        end_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'Menunggu',
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY(unit_id) REFERENCES rental_units(id)
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bookings_schedule ON bookings(unit_id, start_at, end_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status)');
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
  // DYNAMIC UNITS AND BOOKINGS
  // ==========================================

  Future<List<Map<String, dynamic>>> getRentalUnits({bool activeOnly = true}) async {
    final db = await instance.database;
    return db.query(
      'rental_units',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'console_type ASC, unit_code ASC',
    );
  }

  Future<int> saveRentalUnit({
    int? id,
    required String unitCode,
    required String consoleType,
    required String displayName,
    required int unitNumber,
    required int hourlyRate,
    bool active = true,
  }) async {
    final db = await instance.database;
    final values = <String, Object?>{
      'unit_code': unitCode.trim().toUpperCase(),
      'console_type': consoleType.trim().toUpperCase(),
      'display_name': displayName.trim(),
      'unit_number': unitNumber,
      'hourly_rate': hourlyRate,
      'is_active': active ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (id == null) return db.insert('rental_units', values);
    values.remove('created_at');
    return db.update('rental_units', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getBookings({String? status}) async {
    final db = await instance.database;
    final where = status == null ? null : 'b.status = ?';
    return db.rawQuery('''
      SELECT b.*, u.unit_code, u.console_type, u.display_name
      FROM bookings b JOIN rental_units u ON u.id = b.unit_id
      ${where == null ? '' : 'WHERE $where'}
      ORDER BY b.start_at ASC
    ''', status == null ? null : [status]);
  }

  Future<bool> bookingBentrok({
    required int unitId,
    required String startAt,
    required String endAt,
    int? excludeId,
  }) async {
    final db = await instance.database;
    final rows = await db.query(
      'bookings',
      where: "unit_id = ? AND status IN ('Menunggu', 'Dikonfirmasi') AND start_at < ? AND end_at > ?${excludeId == null ? '' : ' AND id != ?'}",
      whereArgs: [unitId, endAt, startAt, if (excludeId != null) excludeId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<int> saveBooking({
    int? id,
    required String customerName,
    required String customerPhone,
    required int unitId,
    required String startAt,
    required String endAt,
    required String status,
    String note = '',
  }) async {
    final db = await instance.database;
    final values = <String, Object?>{
      'customer_name': customerName.trim(),
      'customer_phone': customerPhone.trim(),
      'unit_id': unitId,
      'start_at': startAt,
      'end_at': endAt,
      'status': status,
      'note': note.trim(),
      'created_at': DateTime.now().toIso8601String(),
    };
    if (id == null) return db.insert('bookings', values);
    values.remove('created_at');
    return db.update('bookings', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateBookingStatus(int id, String status) async {
    final db = await instance.database;
    await db.update('bookings', {'status': status}, where: 'id = ?', whereArgs: [id]);
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

  Future<Set<String>> getImportedNoteFingerprints(int noteScanId) async {
    final db = await instance.database;
    final rows = await db.query(
      'note_scan_imports',
      columns: ['row_fingerprint'],
      where: 'note_scan_id = ?',
      whereArgs: [noteScanId],
    );
    return rows.map((row) => row['row_fingerprint'] as String).toSet();
  }

  /// Imports user-reviewed ledger rows into official rentals atomically per row.
  /// Rows that were already imported, duplicated, booked over, or overlap another
  /// rental are reported as skipped instead of silently changing the ledger.
  Future<Map<String, dynamic>> importNoteScanRows({
    required int noteScanId,
    required List<Map<String, dynamic>> rows,
  }) async {
    final db = await instance.database;
    final imported = <Map<String, dynamic>>[];
    final skipped = <Map<String, dynamic>>[];

    await db.transaction((txn) async {
      final photo = await txn.query(
        'note_scans',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [noteScanId],
        limit: 1,
      );
      if (photo.isEmpty) {
        throw StateError('Foto catatan tidak ditemukan. Muat ulang arsip lalu coba lagi.');
      }

      for (final row in rows) {
        final fingerprint = (row['row_fingerprint'] as String? ?? '').trim();
        final nama = (row['nama'] as String? ?? '').trim();
        final psNomor = row['ps_nomor'] as int?;
        final unitId = row['unit_id'] as int?;
        final tanggal = (row['tanggal'] as String? ?? '').trim();
        final waktuMulai = (row['waktu_mulai'] as String? ?? '').trim();
        final durasiMenit = row['durasi_menit'] as int?;
        final saldo = row['saldo'] as int?;
        final metodeBayar = (row['metode_bayar'] as String? ?? 'Cash').trim();

        String? reason;
        if (fingerprint.isEmpty || nama.isEmpty || psNomor == null || unitId == null ||
            tanggal.isEmpty || waktuMulai.isEmpty || durasiMenit == null ||
            durasiMenit <= 0 || saldo == null || saldo <= 0) {
          reason = 'Data wajib belum lengkap.';
        }
        if (reason != null) {
          skipped.add({'nama': nama.isEmpty ? 'Baris tanpa nama' : nama, 'reason': reason});
          continue;
        }

        final validPsNomor = psNomor!;
        final validUnitId = unitId!;
        final validDurasiMenit = durasiMenit!;
        final validSaldo = saldo!;

        final alreadyImported = await txn.query(
          'note_scan_imports',
          where: 'note_scan_id = ? AND row_fingerprint = ?',
          whereArgs: [noteScanId, fingerprint],
          limit: 1,
        );
        if (alreadyImported.isNotEmpty) {
          skipped.add({'nama': nama, 'reason': 'Baris dari foto ini sudah pernah diimpor.'});
          continue;
        }

        final unitRows = await txn.query(
          'rental_units',
          where: 'id = ? AND unit_number = ? AND is_active = 1',
          whereArgs: [validUnitId, validPsNomor],
          limit: 1,
        );
        if (unitRows.isEmpty) {
          skipped.add({'nama': nama, 'reason': 'Unit tidak aktif atau pilihan unit sudah berubah.'});
          continue;
        }

        final startAt = DateTime.tryParse('${tanggal}T$waktuMulai:00');
        if (startAt == null) {
          skipped.add({'nama': nama, 'reason': 'Tanggal atau jam mulai tidak valid.'});
          continue;
        }
        final endAt = startAt.add(Duration(minutes: validDurasiMenit));
        final rental = Rental(
          nama: nama,
          psNomor: validPsNomor,
          waktuMulai: RentalTime.formatJam(startAt),
          waktuSelesai: RentalTime.formatJam(endAt),
          durasiMenit: validDurasiMenit,
          saldo: validSaldo,
          metodeBayar: metodeBayar,
          tanggal: tanggal,
        );

        final duplicate = await txn.query(
          'rentals',
          where: 'tanggal = ? AND ps_nomor = ? AND LOWER(nama) = ? AND waktu_mulai = ? AND durasi_menit = ? AND saldo = ?',
          whereArgs: [tanggal, validPsNomor, nama.toLowerCase(), rental.waktuMulai, validDurasiMenit, validSaldo],
          limit: 1,
        );
        if (duplicate.isNotEmpty) {
          await txn.insert('note_scan_imports', {
            'note_scan_id': noteScanId,
            'row_fingerprint': fingerprint,
            'rental_id': duplicate.first['id'],
            'imported_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          skipped.add({'nama': nama, 'reason': 'Transaksi serupa sudah ada di catatan hari.'});
          continue;
        }

        final dayBefore = startAt.subtract(const Duration(days: 1));
        final dayAfter = endAt.add(const Duration(days: 1));
        String dateKey(DateTime date) =>
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        final existingRows = await txn.query(
          'rentals',
          where: 'ps_nomor = ? AND tanggal >= ? AND tanggal <= ?',
          whereArgs: [psNomor, dateKey(dayBefore), dateKey(dayAfter)],
        );
        var rentalConflict = false;
        for (final existingRow in existingRows) {
          final existing = Rental.fromMap(existingRow);
          final existingStart = RentalTime.startOf(existing);
          final existingEnd = RentalTime.endOf(existing);
          if (startAt.isBefore(existingEnd) && endAt.isAfter(existingStart)) {
            rentalConflict = true;
            break;
          }
        }
        if (rentalConflict) {
          skipped.add({'nama': nama, 'reason': 'Jadwal bentrok dengan transaksi rental yang sudah ada.'});
          continue;
        }

        final bookings = await txn.query(
          'bookings',
          where: "unit_id = ? AND status IN ('Menunggu', 'Dikonfirmasi')",
          whereArgs: [unitId],
        );
        var bookingConflict = false;
        for (final booking in bookings) {
          final bookingStart = DateTime.tryParse(booking['start_at'] as String? ?? '');
          final bookingEnd = DateTime.tryParse(booking['end_at'] as String? ?? '');
          if (bookingStart != null && bookingEnd != null &&
              startAt.isBefore(bookingEnd) && endAt.isAfter(bookingStart)) {
            bookingConflict = true;
            break;
          }
        }
        if (bookingConflict) {
          skipped.add({'nama': nama, 'reason': 'Jadwal bentrok dengan booking yang aktif.'});
          continue;
        }

        final rentalValues = rental.toMap()..remove('id');
        final rentalId = await txn.insert('rentals', rentalValues);
        await txn.insert('note_scan_imports', {
          'note_scan_id': noteScanId,
          'row_fingerprint': fingerprint,
          'rental_id': rentalId,
          'imported_at': DateTime.now().toIso8601String(),
        });
        imported.add({'nama': nama, 'rental_id': rentalId});
      }
    });

    return {'imported': imported, 'skipped': skipped};
  }

}
