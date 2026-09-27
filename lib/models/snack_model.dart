class SnackOrder {
  final int? id;
  final String namaPembeli;
  final String detailItem;
  final int totalHarga;
  final String tanggal;
  final String waktu;

  SnackOrder({
    this.id,
    required this.namaPembeli,
    required this.detailItem,
    required this.totalHarga,
    required this.tanggal,
    required this.waktu,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_pembeli': namaPembeli,
      'detail_item': detailItem,
      'total_harga': totalHarga,
      'tanggal': tanggal,
      'waktu': waktu,
    };
  }

  factory SnackOrder.fromMap(Map<String, dynamic> map) {
    return SnackOrder(
      id: map['id'],
      namaPembeli: map['nama_pembeli'],
      detailItem: map['detail_item'],
      totalHarga: map['total_harga'],
      tanggal: map['tanggal'],
      waktu: map['waktu'],
    );
  }
}