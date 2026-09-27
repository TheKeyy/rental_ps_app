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
    await DatabaseHelper.instance.closeDb();
    final path = await _dbFilePath();
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File database belum ada.');
    }
    await Share.shareXFiles(
      [XFile(path)],
      text: 'Cadangan data Rental PS',
    );
    await DatabaseHelper.instance.database;
  }

  static Future<bool> pulihkanDariFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return false;

    final sourcePath = result.files.single.path!;
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw Exception('File cadangan tidak ditemukan.');
    }

    await DatabaseHelper.instance.closeDb();
    final dest = File(await _dbFilePath());
    if (await dest.exists()) {
      await dest.delete();
    }
    await source.copy(dest.path);
    await DatabaseHelper.instance.database;
    return true;
  }
}
