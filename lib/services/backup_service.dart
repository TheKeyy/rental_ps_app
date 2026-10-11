import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../database/db_helper.dart';

class BackupService {
  static Future<String> _dbFilePath() async {
    final dir = await getDatabasesPath();
    return p.join(dir, 'rental_ps.db');
  }

  static Future<void> bagikanCadangan() async {
    final path = await _dbFilePath();
    await DatabaseHelper.instance.closeDb();
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('File database belum ada.');
      }
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Cadangan data Rental PS',
      );
    } finally {
      await DatabaseHelper.instance.database;
    }
  }

  static Future<bool> pulihkanDariFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return false;

    final source = File(result.files.single.path!);
    if (!await source.exists()) {
      throw Exception('File cadangan tidak ditemukan.');
    }

    final destinationPath = await _dbFilePath();
    final staged = File('$destinationPath.restore.tmp');
    final previous = File('$destinationPath.before-restore');

    // Validate a staged copy first so an arbitrary or corrupt file never replaces live data.
    if (await staged.exists()) await staged.delete();
    await source.copy(staged.path);

    Database? validationDb;
    try {
      validationDb = await openDatabase(
        staged.path,
        readOnly: true,
        singleInstance: false,
      );
      final integrity = await validationDb.rawQuery('PRAGMA integrity_check');
      final integrityResult = integrity.isEmpty ? null : integrity.first.values.first;
      if (integrityResult != 'ok') {
        throw Exception('File cadangan rusak atau bukan database SQLite yang valid.');
      }

      final tables = await validationDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = tables.map((row) => row['name'] as String?).whereType<String>().toSet();
      const requiredTables = {'rentals', 'expenses', 'time_deposits'};
      if (!names.containsAll(requiredTables)) {
        throw Exception('File bukan cadangan Rental PS yang dikenali.');
      }

      final rentalColumns = await validationDb.rawQuery('PRAGMA table_info(rentals)');
      final columnNames = rentalColumns.map((row) => row['name'] as String?).whereType<String>().toSet();
      const requiredColumns = {'id', 'nama', 'ps_nomor', 'waktu_mulai', 'durasi_menit', 'saldo', 'tanggal'};
      if (!columnNames.containsAll(requiredColumns)) {
        throw Exception('Struktur database cadangan tidak cocok dengan aplikasi ini.');
      }
      await validationDb.close();
      validationDb = null;
    } catch (_) {
      if (validationDb != null) await validationDb.close();
      if (await staged.exists()) await staged.delete();
      rethrow;
    }

    await DatabaseHelper.instance.closeDb();
    try {
      if (await previous.exists()) await previous.delete();
      final destination = File(destinationPath);
      if (await destination.exists()) await destination.copy(previous.path);
      if (await destination.exists()) await destination.delete();
      await staged.rename(destinationPath);

      // Opening the restored DB also applies any supported schema migrations.
      await DatabaseHelper.instance.database;
      if (await previous.exists()) await previous.delete();
      return true;
    } catch (e) {
      final destination = File(destinationPath);
      if (await destination.exists()) await destination.delete();
      if (await previous.exists()) await previous.rename(destinationPath);
      await DatabaseHelper.instance.database;
      rethrow;
    } finally {
      if (await staged.exists()) await staged.delete();
    }
  }
}
