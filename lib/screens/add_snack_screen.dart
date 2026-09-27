import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/snack_model.dart';
import '../models/snack_item_model.dart';

class AddSnackScreen extends StatefulWidget {
  final String? selectedDate;
  const AddSnackScreen({super.key, this.selectedDate});

  @override
  State<AddSnackScreen> createState() => _AddSnackScreenState();
}

class _AddSnackScreenState extends State<AddSnackScreen> {
  final _namaController = TextEditingController();
  List<SnackItem> _items = [];
  final Map<int, int> _orderQtys = {};

  late DateTime _tanggalTransaksi;
  bool _potongStok = true;

  @override
  void initState() {
    super.initState();
    _tanggalTransaksi = widget.selectedDate != null
        ? DateTime.parse(widget.selectedDate!)
        : DateTime.now();

    // Jika input tanggal lampau, default jangan potong stok fisik sekarang
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final transStr = DateFormat('yyyy-MM-dd').format(_tanggalTransaksi);
    _potongStok = (todayStr == transStr);

    _loadItems();
  }

  void _loadItems() async {
    final data = await DatabaseHelper.instance.getAllSnackItems();
    setState(() {
      _items = data;
      for (var it in data) {
        _orderQtys[it.id!] = 0;
      }
    });
  }

  int get _totalHarga {
    int total = 0;
    for (var it in _items) {
      final qty = _orderQtys[it.id!] ?? 0;
      total += qty * it.harga;
    }
    return total;
  }

  String _generateDetailItem() {
    List<String> list = [];
    for (var it in _items) {
      final qty = _orderQtys[it.id!] ?? 0;
      if (qty > 0) {
        list.add("${it.nama} x$qty");
      }
    }
    return list.join(", ");
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalTransaksi,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _tanggalTransaksi = picked;
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final transStr = DateFormat('yyyy-MM-dd').format(_tanggalTransaksi);
        _potongStok = (todayStr == transStr);
      });
    }
  }

  void _simpanTransaksi() async {
    if (_totalHarga == 0) return;

    final now = DateTime.now();
    final order = SnackOrder(
      namaPembeli: _namaController.text.trim().isEmpty ? "Pelanggan" : _namaController.text.trim(),
      detailItem: _generateDetailItem(),
      totalHarga: _totalHarga,
      tanggal: DateFormat('yyyy-MM-dd').format(_tanggalTransaksi),
      waktu: DateFormat('HH:mm').format(now),
    );

    await DatabaseHelper.instance.insertSnackOrder(order);

    // Hanya potong stok jika diizinkan (bukan rekap data lampau)
    if (_potongStok) {
      for (var it in _items) {
        final qty = _orderQtys[it.id!] ?? 0;
        if (qty > 0) {
          await DatabaseHelper.instance.reduceStock(it.id!, qty);
        }
      }
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text("Kasir Jajan & Minuman")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pemilih Tanggal Transaksi
          Card(
            color: Colors.orange.shade50,
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.deepOrange),
              title: const Text("Tanggal Pembukuan", style: TextStyle(fontSize: 12, color: Colors.grey)),
              subtitle: Text(
                DateFormat('EEEE, dd MMMM yyyy').format(_tanggalTransaksi),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              ),
              trailing: const Icon(Icons.edit_calendar, color: Colors.deepOrange),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 8),

          // Switch Potong Stok
          SwitchListTile(
            dense: true,
            title: const Text("Potong Stok Inventaris Fisik?", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text(
              _potongStok ? "Stok barang saat ini akan berkurang" : "Hanya catat uang kas masuk (stok fisik tidak diubah)",
              style: const TextStyle(fontSize: 11),
            ),
            value: _potongStok,
            onChanged: (val) => setState(() => _potongStok = val),
          ),
          const Divider(),

          TextField(
            controller: _namaController,
            decoration: const InputDecoration(
              labelText: "Nama Pembeli (Opsional / No. PS)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ..._items.map((it) {
            final qty = _orderQtys[it.id!] ?? 0;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            "${currency.format(it.harga)} • Sisa Stok: ${it.stok}",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: qty > 0 ? () => setState(() => _orderQtys[it.id!] = qty - 1) : null,
                          icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 28),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _orderQtys[it.id!] = qty + 1),
                          icon: const Icon(Icons.add_circle, color: Colors.green, size: 28),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Tagihan:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  currency.format(_totalHarga),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.deepOrange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _totalHarga > 0 ? _simpanTransaksi : null,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text("Simpan Transaksi Jajan"),
          )
        ],
      ),
    );
  }
}