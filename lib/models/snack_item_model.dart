class SnackItem {
  final int? id;
  final String nama;
  final int harga;
  final int stok;

  SnackItem({
    this.id,
    required this.nama,
    required this.harga,
    required this.stok,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'harga': harga,
      'stok': stok,
    };
  }

  factory SnackItem.fromMap(Map<String, dynamic> map) {
    return SnackItem(
      id: map['id'],
      nama: map['nama'],
      harga: map['harga'],
      stok: map['stok'],
    );
  }
}