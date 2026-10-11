import 'package:flutter_test/flutter_test.dart';
import 'package:rental_ps_app/services/rental_notebook_importer.dart';

void main() {
  group('RentalNotebookImporter', () {
    test('reads a start time from a range and notebook-style spaced digits', () {
      expect(RentalNotebookImporter.parseStartTime('09:20 - 09:50'), '09:20');
      expect(RentalNotebookImporter.parseStartTime('9.20–9.50'), '09:20');
      expect(RentalNotebookImporter.parseStartTime('9 20 - 9 50'), '09:20');
    });

    test('parses ledger durations without guessing invalid values', () {
      expect(RentalNotebookImporter.parseDurationMinutes('20 m'), 20);
      expect(RentalNotebookImporter.parseDurationMinutes('1 jam'), 60);
      expect(RentalNotebookImporter.parseDurationMinutes('1 jam 20 menit'), 80);
      expect(RentalNotebookImporter.parseDurationMinutes('1.20 m'), 80);
      expect(RentalNotebookImporter.parseDurationMinutes('2 jam'), 120);
      expect(RentalNotebookImporter.parseDurationMinutes(''), isNull);
      expect(RentalNotebookImporter.parseDurationMinutes('1 jam 70 menit'), isNull);
    });

    test('normalizes rupiah amounts with thousands separators and handwriting marks', () {
      expect(RentalNotebookImporter.parseAmount('Rp 10.000'), 10000);
      expect(RentalNotebookImporter.parseAmount('2.000 L'), 2000);
      expect(RentalNotebookImporter.parseAmount('5,000'), 5000);
      expect(RentalNotebookImporter.parseAmount('tidak terbaca'), isNull);
    });

    test('creates a stable, whitespace-insensitive row fingerprint', () {
      final first = <String, String>{
        'no': '1',
        'nama': 'Dika Putra',
        'ps': '1',
        'waktu': '09:20',
        'sewa': '20 m',
        'saldo': '2.000',
      };
      final second = <String, String>{
        'no': ' 1 ',
        'nama': 'DIKA   PUTRA',
        'ps': '1',
        'waktu': '09:20',
        'sewa': '20 M',
        'saldo': '2.000',
      };
      expect(
        RentalNotebookImporter.fingerprint(first),
        RentalNotebookImporter.fingerprint(second),
      );
    });

    test('keeps different notebook row numbers distinct', () {
      const first = <String, String>{
        'no': '1', 'nama': 'Dika', 'ps': '1', 'waktu': '09:20', 'sewa': '20 m', 'saldo': '2000',
      };
      const second = <String, String>{
        'no': '2', 'nama': 'Dika', 'ps': '1', 'waktu': '09:20', 'sewa': '20 m', 'saldo': '2000',
      };
      expect(
        RentalNotebookImporter.fingerprint(first),
        isNot(RentalNotebookImporter.fingerprint(second)),
      );
    });
  });
}
