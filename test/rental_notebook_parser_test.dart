import 'package:flutter_test/flutter_test.dart';
import 'package:rental_ps_app/services/rental_notebook_parser.dart';

void main() {
  group('RentalNotebookParser', () {
    test('skips the header and parses pipe-separated rows', () {
      final rows = RentalNotebookParser.parseRows(
        'No | Nama | PS | Waktu | Sewa | Saldo\n'
        '1 | Dika | 2 | 13:00 | 2 jam | Rp 10.000',
      );

      expect(rows, hasLength(1));
      expect(rows.single, {
        'no': '1',
        'nama': 'Dika',
        'ps': '2',
        'waktu': '13:00',
        'sewa': '2 jam',
        'saldo': 'Rp 10.000',
      });
    });

    test('parses tab-separated rows', () {
      final rows = RentalNotebookParser.parseRows(
        '2\tRani\t1\t19:30\t1 jam\tRp 5.000',
      );

      expect(rows, hasLength(1));
      expect(rows.single['nama'], 'Rani');
      expect(rows.single['ps'], '1');
      expect(rows.single['saldo'], 'Rp 5.000');
    });

    test('uses a conservative fallback for a recognizable single line', () {
      final rows = RentalNotebookParser.parseRows(
        '3 Budi PS 2 20:15 90 menit 15000',
      );

      expect(rows, hasLength(1));
      expect(rows.single['no'], '3');
      expect(rows.single['nama'], 'Budi');
      expect(rows.single['ps'], '2');
      expect(rows.single['waktu'], '20:15');
      expect(rows.single['sewa'], '90 menit');
      expect(rows.single['saldo'], '15000');
    });

    test('ignores ambiguous lines instead of guessing their columns', () {
      final rows = RentalNotebookParser.parseRows(
        'Tulisan tidak terbaca dengan jelas',
      );

      expect(rows, isEmpty);
    });
  });
}
