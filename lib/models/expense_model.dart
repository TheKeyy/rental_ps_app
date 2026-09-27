class Expense {
  final int? id;
  final String keterangan;
  final int nominal;
  final String tanggal;
  final String waktu;
  final String kategori;

  Expense({
    this.id,
    required this.keterangan,
    required this.nominal,
    required this.tanggal,
    required this.waktu,
    this.kategori = 'Lainnya',
  });

  static const kategoriPilihan = [
    'Token Listrik',
    'Belanja Modal',
    'Peralatan',
    'Sewa Tempat',
    'Lainnya',
  ];

  Expense copyWith({
    int? id,
    String? keterangan,
    int? nominal,
    String? tanggal,
    String? waktu,
    String? kategori,
  }) {
    return Expense(
      id: id ?? this.id,
      keterangan: keterangan ?? this.keterangan,
      nominal: nominal ?? this.nominal,
      tanggal: tanggal ?? this.tanggal,
      waktu: waktu ?? this.waktu,
      kategori: kategori ?? this.kategori,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'keterangan': keterangan,
      'nominal': nominal,
      'tanggal': tanggal,
      'waktu': waktu,
      'kategori': kategori,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      keterangan: map['keterangan'],
      nominal: map['nominal'],
      tanggal: map['tanggal'],
      waktu: map['waktu'],
      kategori: (map['kategori'] as String?)?.isNotEmpty == true ? map['kategori'] as String : 'Lainnya',
    );
  }
}
