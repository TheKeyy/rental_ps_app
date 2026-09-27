import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/snack_item_model.dart';

class SnackInventoryScreen extends StatefulWidget {
  const SnackInventoryScreen({super.key});

  @override
  State<SnackInventoryScreen> createState() => _SnackInventoryScreenState();
}

class _SnackInventoryScreenState extends State<SnackInventoryScreen> {
  List<SnackItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final data = await DatabaseHelper.instance.getAllSnackItems();
    setState(() => _items = data);
  }

  void _showFormDialog({SnackItem? item}) {
    final namaCtrl = TextEditingController(text: item?.nama ?? "");
    final hargaCtrl = TextEditingController(text: item != null ? item.harga.toString() : "");
    final stokCtrl = TextEditingController(text: item != null ? item.stok.toString() : "10");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? "Tambah Item Jajan" : "Edit Item Jajan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: "Nama Barang")),
            TextField(controller: hargaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Harga (Rp)")),
            TextField(controller: stokCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Jumlah Stok")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              final nama = namaCtrl.text.trim();
              final harga = int.tryParse(hargaCtrl.text) ?? 0;
              final stok = int.tryParse(stokCtrl.text) ?? 0;
              if (nama.isEmpty || harga <= 0) return;

              if (item == null) {
                await DatabaseHelper.instance.insertSnackItem(SnackItem(nama: nama, harga: harga, stok: stok));
              } else {
                await DatabaseHelper.instance.updateSnackItem(SnackItem(id: item.id, nama: nama, harga: harga, stok: stok));
              }
              if (mounted) Navigator.pop(ctx);
              _loadItems();
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text("Katalog & Stok Warung")),
      body: _items.isEmpty
          ? const Center(child: Text("Belum ada daftar item jajan."))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final it = _items[index];
                final isLowStock = it.stok <= 3;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isLowStock ? Colors.red.shade100 : Colors.green.shade100,
                      child: Icon(Icons.inventory_2, color: isLowStock ? Colors.red : Colors.green),
                    ),
                    title: Text(it.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${currency.format(it.harga)}  •  Stok: ${it.stok} pcs"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showFormDialog(item: it)),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await DatabaseHelper.instance.deleteSnackItem(it.id!);
                            _loadItems();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}