class Tariff {
  static const Map<int, int> paketDefault = {
    10: 1000,
    20: 2000,
    30: 3000,
    40: 4000,
    60: 5000,
    120: 10000,
    180: 15000,
  };

  static const int hargaPer10Default = 1000;

  static const List<int> durasiPilihan = [0, 10, 20, 30, 40, 60, 120, 180];

  static int hitung(
    int menit, {
    Map<int, int>? paket,
    int hargaPer10 = hargaPer10Default,
  }) {
    if (menit <= 0) return 0;
    final table = paket ?? paketDefault;
    final pas = table[menit];
    if (pas != null) return pas;
    final blok = (menit + 9) ~/ 10;
    return blok * hargaPer10;
  }

  static String labelDurasi(int menit) {
    if (menit == 0) return 'Cuma sisa waktu';
    if (menit < 60) return '$menit menit';
    final jam = menit ~/ 60;
    final sisa = menit % 60;
    if (sisa == 0) return '$jam jam';
    return '$jam jam $sisa menit';
  }
}
