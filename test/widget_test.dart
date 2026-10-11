import 'package:flutter_test/flutter_test.dart';
import 'package:rental_ps_app/models/rental_model.dart';
import 'package:rental_ps_app/services/rental_time.dart';
import 'package:rental_ps_app/services/tariff.dart';

Rental rental({
  int id = 1,
  int psNomor = 1,
  String tanggal = '2026-10-10',
  String mulai = '10:00',
  int durasi = 60,
}) {
  return Rental(
    id: id,
    nama: 'Pelanggan $id',
    psNomor: psNomor,
    waktuMulai: mulai,
    waktuSelesai: mulai,
    durasiMenit: durasi,
    saldo: 5000,
    metodeBayar: 'Cash',
    tanggal: tanggal,
  );
}

void main() {
  group('Tariff', () {
    test('uses configured default package prices', () {
      expect(Tariff.hitung(10), 1000);
      expect(Tariff.hitung(60), 5000);
      expect(Tariff.hitung(120), 10000);
    });

    test('rounds non-package durations up to a 10-minute block', () {
      expect(Tariff.hitung(11), 2000);
      expect(Tariff.hitung(19), 2000);
      expect(Tariff.hitung(21), 3000);
    });

    test('does not charge for zero or negative duration', () {
      expect(Tariff.hitung(0), 0);
      expect(Tariff.hitung(-10), 0);
    });
  });

  group('RentalTime', () {
    test('calculates end time across midnight', () {
      final session = rental(tanggal: '2026-10-10', mulai: '23:30', durasi: 60);
      expect(RentalTime.endOf(session), DateTime(2026, 10, 11, 0, 30));
    });

    test('detects an overlapping session on the same PS', () {
      final existing = [rental(mulai: '10:00', durasi: 60)];
      expect(
        RentalTime.bentrok(
          existing: existing,
          psNomor: 1,
          mulai: DateTime(2026, 10, 10, 10, 30),
          selesai: DateTime(2026, 10, 10, 11, 30),
        ),
        isTrue,
      );
    });

    test('allows sessions that start exactly when the previous one ends', () {
      final existing = [rental(mulai: '10:00', durasi: 60)];
      expect(
        RentalTime.bentrok(
          existing: existing,
          psNomor: 1,
          mulai: DateTime(2026, 10, 10, 11, 0),
          selesai: DateTime(2026, 10, 10, 12, 0),
        ),
        isFalse,
      );
    });

    test('does not report a clash on another PS unit', () {
      final existing = [rental(psNomor: 1, mulai: '10:00', durasi: 60)];
      expect(
        RentalTime.bentrok(
          existing: existing,
          psNomor: 2,
          mulai: DateTime(2026, 10, 10, 10, 30),
          selesai: DateTime(2026, 10, 10, 11, 30),
        ),
        isFalse,
      );
    });
  });
}
