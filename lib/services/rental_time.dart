import '../models/rental_model.dart';

class RentalTime {
  static DateTime parseClock(DateTime day, String hhmm) {
    final parts = hhmm.split(':');
    var hour = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    var extraDays = 0;
    if (hour >= 24) {
      extraDays = hour ~/ 24;
      hour = hour % 24;
    }
    return DateTime(day.year, day.month, day.day, hour, minute)
        .add(Duration(days: extraDays));
  }

  static DateTime startOf(Rental r) {
    return parseClock(DateTime.parse(r.tanggal), r.waktuMulai);
  }

  static DateTime endOf(Rental r) {
    return startOf(r).add(Duration(minutes: r.durasiMenit < 0 ? 0 : r.durasiMenit));
  }

  static bool isActive(Rental r, DateTime now) {
    final start = startOf(r);
    final end = endOf(r);
    return !now.isBefore(start) && now.isBefore(end);
  }

  static bool isUpcoming(Rental r, DateTime now) => startOf(r).isAfter(now);

  static bool sudahHabis(Rental r, DateTime now) => !now.isBefore(endOf(r));

  static Rental? aktifUntukPs(List<Rental> list, int psNomor, DateTime now) {
    final aktif = list.where((r) => r.psNomor == psNomor && isActive(r, now)).toList();
    if (aktif.isEmpty) return null;
    aktif.sort((a, b) => startOf(b).compareTo(startOf(a)));
    return aktif.first;
  }

  static Rental? berikutnyaUntukPs(List<Rental> list, int psNomor, DateTime now) {
    final next = list.where((r) => r.psNomor == psNomor && isUpcoming(r, now)).toList();
    if (next.isEmpty) return null;
    next.sort((a, b) => startOf(a).compareTo(startOf(b)));
    return next.first;
  }

  static bool bentrok({
    required List<Rental> existing,
    required int psNomor,
    required DateTime mulai,
    required DateTime selesai,
    int? kecualiId,
  }) {
    for (final r in existing) {
      if (r.psNomor != psNomor) continue;
      if (kecualiId != null && r.id == kecualiId) continue;
      final a = startOf(r);
      final b = endOf(r);
      if (mulai.isBefore(b) && selesai.isAfter(a)) return true;
    }
    return false;
  }

  static String formatJam(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String formatSisa(Duration diff) {
    if (diff.isNegative) return '00:00';
    final totalDetik = diff.inSeconds;
    final m = totalDetik ~/ 60;
    final s = totalDetik % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
