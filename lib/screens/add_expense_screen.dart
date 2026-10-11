import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';
import '../models/expense_model.dart';

class AddExpenseScreen extends StatefulWidget {
  final String selectedDate;
  final Expense? existing;

  const AddExpenseScreen({super.key, required this.selectedDate, this.existing});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _ketController = TextEditingController();
  final _nominalController = TextEditingController();
  String _kategori = 'Lainnya';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _ketController.text = e.keterangan;
      _nominalController.text = e.nominal.toString();
      _kategori = e.kategori;
    }
  }

  Future<void> _simpan() async {
    final ket = _ketController.text.trim();
    final nominal = int.tryParse(_nominalController.text) ?? 0;
    if (ket.isEmpty || nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi keterangan dan nominal lebih dari Rp 0.')),
      );
      return;
    }

    final now = DateTime.now();
    final exp = Expense(
      id: widget.existing?.id,
      keterangan: ket,
      nominal: nominal,
      tanggal: widget.existing?.tanggal ?? widget.selectedDate,
      waktu: widget.existing?.waktu ?? DateFormat('HH:mm').format(now),
      kategori: _kategori,
    );

    if (widget.existing != null) {
      await DatabaseHelper.instance.updateExpense(exp);
    } else {
      await DatabaseHelper.instance.insertExpense(exp);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing != null ? 'Ubah pengeluaran' : 'Catat pengeluaran')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: Expense.kategoriPilihan.contains(_kategori) ? _kategori : 'Lainnya',
            decoration: const InputDecoration(labelText: 'Kategori', prefixIcon: Icon(Icons.category_outlined)),
            items: Expense.kategoriPilihan
                .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                .toList(),
            onChanged: (v) => setState(() => _kategori = v ?? 'Lainnya'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ketController,
            decoration: const InputDecoration(
              labelText: 'Keterangan',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nominalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nominal pengeluaran (Rp)',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _simpan,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Simpan pengeluaran'),
          ),
        ],
      ),
    );
  }
}
