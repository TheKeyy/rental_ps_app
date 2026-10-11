import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  List<Map<String, dynamic>> _units = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await DatabaseHelper.instance.getRentalUnits(activeOnly: false);
    if (!mounted) return;
    setState(() {
      _units = rows;
      _loading = false;
    });
  }

  Future<void> _edit([Map<String, dynamic>? unit]) async {
    final code = TextEditingController(text: unit?['unit_code']?.toString() ?? '');
    final name = TextEditingController(text: unit?['display_name']?.toString() ?? '');
    final number = TextEditingController(text: unit?['unit_number']?.toString() ?? '');
    final rate = TextEditingController(text: unit?['hourly_rate']?.toString() ?? '0');
    String type = unit?['console_type']?.toString() ?? 'PS3';
    bool active = (unit?['is_active'] as int? ?? 1) == 1;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(unit == null ? 'Tambah unit' : 'Edit unit'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Jenis konsol'),
                      items: const [
                        DropdownMenuItem(value: 'PS3', child: Text('PlayStation 3')),
                        DropdownMenuItem(value: 'PS4', child: Text('PlayStation 4')),
                        DropdownMenuItem(value: 'PS5', child: Text('PlayStation 5')),
                        DropdownMenuItem(value: 'LAINNYA', child: Text('Lainnya')),
                      ],
                      onChanged: (value) => setDialogState(() => type = value ?? 'PS3'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: code,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Kode unit', hintText: 'Contoh: PS4-01'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Kode unit wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Nama tampilan', hintText: 'Contoh: PS4 Ruang 1'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: number,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Nomor internal unik', helperText: 'Nomor ini dipakai untuk menghubungkan transaksi lama. Jangan gunakan nomor unit lain.'),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) return 'Masukkan nomor positif';
                        if (_units.any((u) => u['unit_number'] == n && u['id'] != unit?['id'])) return 'Nomor internal sudah dipakai';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: rate,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tarif per jam (Rp)'),
                      validator: (v) => (int.tryParse(v ?? '') == null || int.parse(v!) < 0) ? 'Tarif tidak valid' : null,
                    ),
                    if (unit != null)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Unit aktif'),
                        subtitle: const Text('Nonaktifkan unit yang tidak lagi disewakan'),
                        value: active,
                        onChanged: (value) => setDialogState(() => active = value),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await DatabaseHelper.instance.saveRentalUnit(
                    id: unit?['id'] as int?,
                    unitCode: code.text,
                    consoleType: type,
                    displayName: name.text,
                    unitNumber: int.parse(number.text),
                    hourlyRate: int.parse(rate.text),
                    active: active,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  await _load();
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan unit. Pastikan kode dan nomor unik. ($e)')),
                  );
                }
              },
              child: const Text('Simpan unit'),
            ),
          ],
        ),
      ),
    );
    code.dispose();
    name.dispose();
    number.dispose();
    rate.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Unit')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah unit'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _units.isEmpty
              ? const Center(child: Text('Belum ada unit. Tambahkan PS3 atau PS4 pertama lo.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: _units.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final unit = _units[index];
                    final active = (unit['is_active'] as int? ?? 1) == 1;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.sports_esports_outlined, color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text('${unit['unit_code']} · ${unit['display_name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${unit['console_type']} · ${currency.format(unit['hourly_rate'])}/jam · Nomor internal ${unit['unit_number']}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(active ? Icons.check_circle : Icons.pause_circle, color: active ? Colors.green : Colors.grey),
                            Text(active ? 'Aktif' : 'Nonaktif', style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                        onTap: () => _edit(unit),
                      ),
                    );
                  },
                ),
    );
  }
}
