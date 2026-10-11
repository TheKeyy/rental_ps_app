import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      DatabaseHelper.instance.getRentalUnits(),
      DatabaseHelper.instance.getBookings(),
    ]);
    if (!mounted) return;
    setState(() {
      _units = values[0];
      _bookings = values[1];
      _loading = false;
    });
  }

  Future<void> _createBooking() async {
    if (_units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan unit PS terlebih dahulu di Manajemen Unit.')),
      );
      return;
    }
    final name = TextEditingController();
    final phone = TextEditingController();
    final note = TextEditingController();
    DateTime day = DateTime.now();
    TimeOfDay start = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
    int duration = 60;
    int unitId = _units.first['id'] as int;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Booking baru'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Nama pelanggan', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Nomor kontak (opsional)', prefixIcon: Icon(Icons.phone_outlined)),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      initialValue: unitId,
                      decoration: const InputDecoration(labelText: 'Pilih unit'),
                      items: _units.map((u) => DropdownMenuItem<int>(
                        value: u['id'] as int,
                        child: Text('${u['unit_code']} · ${u['display_name']}'),
                      )).toList(),
                      onChanged: (value) => setDialogState(() => unitId = value ?? unitId),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tanggal booking'),
                      subtitle: Text(DateFormat('EEEE, dd MMM yyyy').format(day)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: day,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setDialogState(() => day = picked);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Jam mulai'),
                      subtitle: Text(start.format(context)),
                      trailing: const Icon(Icons.schedule),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: start);
                        if (picked != null) setDialogState(() => start = picked);
                      },
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: duration,
                      decoration: const InputDecoration(labelText: 'Durasi booking'),
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30 menit')),
                        DropdownMenuItem(value: 60, child: Text('1 jam')),
                        DropdownMenuItem(value: 90, child: Text('1 jam 30 menit')),
                        DropdownMenuItem(value: 120, child: Text('2 jam')),
                        DropdownMenuItem(value: 180, child: Text('3 jam')),
                        DropdownMenuItem(value: 240, child: Text('4 jam')),
                      ],
                      onChanged: (value) => setDialogState(() => duration = value ?? 60),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: note,
                      decoration: const InputDecoration(labelText: 'Catatan (opsional)', prefixIcon: Icon(Icons.notes_outlined)),
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
                final begins = DateTime(day.year, day.month, day.day, start.hour, start.minute);
                final ends = begins.add(Duration(minutes: duration));
                final unit = _units.firstWhere((u) => u['id'] == unitId);
                final beginsText = begins.toIso8601String();
                final endsText = ends.toIso8601String();
                final conflict = await DatabaseHelper.instance.bookingBentrok(
                  unitId: unitId,
                  startAt: beginsText,
                  endAt: endsText,
                );
                if (conflict) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Jadwal unit ini bentrok dengan booking lain. Pilih jam atau unit lain.')),
                  );
                  return;
                }
                await DatabaseHelper.instance.saveBooking(
                  customerName: name.text,
                  customerPhone: phone.text,
                  unitId: unitId,
                  startAt: beginsText,
                  endAt: endsText,
                  status: 'Dikonfirmasi',
                  note: note.text,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                await _load();
              },
              child: const Text('Konfirmasi booking'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    phone.dispose();
    note.dispose();
  }

  Future<void> _changeStatus(Map<String, dynamic> booking, String status) async {
    await DatabaseHelper.instance.updateBookingStatus(booking['id'] as int, status);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Rental')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBooking,
        icon: const Icon(Icons.event_available),
        label: const Text('Booking baru'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const Center(child: Text('Belum ada booking. Tekan Booking baru untuk mencatat jadwal.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: _bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final b = _bookings[index];
                    final start = DateTime.tryParse(b['start_at'] as String? ?? '');
                    final end = DateTime.tryParse(b['end_at'] as String? ?? '');
                    final status = b['status']?.toString() ?? 'Menunggu';
                    final statusColor = status == 'Dikonfirmasi'
                        ? const Color(0xFF4F46E5)
                        : status == 'Selesai'
                            ? Colors.green
                            : status == 'Dibatalkan'
                                ? Colors.grey
                                : Colors.orange;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(b['customer_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                                PopupMenuButton<String>(
                                  tooltip: 'Ubah status',
                                  onSelected: (value) => _changeStatus(b, value),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'Dikonfirmasi', child: Text('Dikonfirmasi')),
                                    PopupMenuItem(value: 'Selesai', child: Text('Selesai')),
                                    PopupMenuItem(value: 'Dibatalkan', child: Text('Dibatalkan')),
                                  ],
                                ),
                              ],
                            ),
                            Text('${b['unit_code']} · ${b['display_name']}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('${start == null ? 'Tanggal?' : DateFormat('dd MMM yyyy, HH:mm').format(start)} – ${end == null ? 'Jam?' : DateFormat('HH:mm').format(end)}'),
                            if ((b['customer_phone'] as String? ?? '').isNotEmpty) Text('Kontak: ${b['customer_phone']}'),
                            if ((b['note'] as String? ?? '').isNotEmpty) Text('Catatan: ${b['note']}'),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Chip(
                                label: Text(status),
                                backgroundColor: statusColor.withValues(alpha: 0.12),
                                side: BorderSide(color: statusColor.withValues(alpha: 0.25)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
