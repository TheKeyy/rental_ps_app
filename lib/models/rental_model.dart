class Rental {
  final int? id;
  final String nama;
  final int psNomor;
  final String waktuMulai;
  final String waktuSelesai;
  final int durasiMenit;
  final int saldo;
  final String metodeBayar;
  final String tanggal;

  Rental({
    this.id,
    required this.nama,
    required this.psNomor,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.durasiMenit,
    required this.saldo,
    required this.metodeBayar,
    required this.tanggal,
  });

  Rental copyWith({
    int? id,
    String? nama,
    int? psNomor,
    String? waktuMulai,
    String? waktuSelesai,
    int? durasiMenit,
    int? saldo,
    String? metodeBayar,
    String? tanggal,
  }) {
    return Rental(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      psNomor: psNomor ?? this.psNomor,
      waktuMulai: waktuMulai ?? this.waktuMulai,
      waktuSelesai: waktuSelesai ?? this.waktuSelesai,
      durasiMenit: durasiMenit ?? this.durasiMenit,
      saldo: saldo ?? this.saldo,
      metodeBayar: metodeBayar ?? this.metodeBayar,
      tanggal: tanggal ?? this.tanggal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'ps_nomor': psNomor,
      'waktu_mulai': waktuMulai,
      'waktu_selesai': waktuSelesai,
      'durasi_menit': durasiMenit,
      'saldo': saldo,
      'metode_bayar': metodeBayar,
      'tanggal': tanggal,
    };
  }

  factory Rental.fromMap(Map<String, dynamic> map) {
    return Rental(
      id: map['id'],
      nama: map['nama'],
      psNomor: map['ps_nomor'],
      waktuMulai: map['waktu_mulai'],
      waktuSelesai: map['waktu_selesai'],
      durasiMenit: map['durasi_menit'],
      saldo: map['saldo'],
      metodeBayar: map['metode_bayar'],
      tanggal: map['tanggal'],
    );
  }
}
