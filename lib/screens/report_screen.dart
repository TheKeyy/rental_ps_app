import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/db_helper.dart';
import '../models/expense_model.dart';
import '../models/rental_model.dart';
import '../services/settings_service.dart';
import 'note_scan_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedFilterIndex = 1;
  List<Rental> _rentals = [];
  List<Expense> _expenses = [];
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _applyFilter(1);
  }

  void _applyFilter(int index) {
    _selectedFilterIndex = index;
    final now = DateTime.now();
    if (index == 0) {
      _startDate = now.subtract(const Duration(days: 6));
      _endDate = now;
    } else if (index == 1) {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    } else {
      _startDate = DateTime(now.year, now.month - 1, 1);
      _endDate = DateTime(now.year, now.month, 0);
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final fStart = DateFormat('yyyy-MM-dd').format(_startDate);
    final fEnd = DateFormat('yyyy-MM-dd').format(_endDate);
    final rentals = await DatabaseHelper.instance.getRentalsByDateRange(fStart, fEnd);
    final expenses = await DatabaseHelper.instance.getExpensesByDateRange(fStart, fEnd);
    if (!mounted) return;
    setState(() {
      _rentals = rentals;
      _expenses = expenses;
    });
  }

  int get _totalSaldoRental => _rentals.fold(0, (sum, r) => sum + r.saldo);
  int get _totalMenitRental => _rentals.fold(0, (sum, r) => sum + r.durasiMenit);
  int get _totalPengeluaran => _expenses.fold(0, (sum, e) => sum + e.nominal);
  int get _sisaOperasional => _totalSaldoRental - _totalPengeluaran;
  int get _cash => _rentals.where((r) => r.metodeBayar.toLowerCase() == 'cash').fold(0, (s, r) => s + r.saldo);
  int get _transfer => _rentals.where((r) => r.metodeBayar.toLowerCase() != 'cash').fold(0, (s, r) => s + r.saldo);

  Map<String, int> get _omzetHarian {
    final map = <String, int>{};
    for (final r in _rentals) {
      map[r.tanggal] = (map[r.tanggal] ?? 0) + r.saldo;
    }
    return map;
  }

  Map<String, int> get _keluarPerKategori {
    final map = <String, int>{};
    for (final e in _expenses) {
      map[e.kategori] = (map[e.kategori] ?? 0) + e.nominal;
    }
    return map;
  }

  String get _periodLabel {
    final df = DateFormat('dd MMM yyyy');
    if (_selectedFilterIndex == 0) return '7 hari (${df.format(_startDate)} - ${df.format(_endDate)})';
    if (_selectedFilterIndex == 1) return 'Bulan ini (${DateFormat('MMMM yyyy').format(_startDate)})';
    return 'Bulan lalu (${DateFormat('MMMM yyyy').format(_startDate)})';
  }

  Future<void> _exportWhatsApp() async {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final nama = SettingsService.instance.namaWarung;
    final buffer = StringBuffer();
    buffer.writeln('📊 *REKAP $nama*');
    buffer.writeln('🗓️ Periode: $_periodLabel');
    buffer.writeln('----------------------------------');
    buffer.writeln('⏱️ Durasi sewa: ${_totalMenitRental ~/ 60} jam ${_totalMenitRental % 60} mnt');
    buffer.writeln('🎮 Omzet sewa: ${currency.format(_totalSaldoRental)}');
    buffer.writeln('💵 Cash: ${currency.format(_cash)} | 🏦 TF: ${currency.format(_transfer)}');
    buffer.writeln('💸 Pengeluaran: ${currency.format(_totalPengeluaran)}');
    buffer.writeln('📊 *SISA OPERASIONAL:* ${currency.format(_sisaOperasional)}');
    buffer.writeln('🔢 ${_rentals.length} sesi sewa, ${_expenses.length} pengeluaran');

    await _kirimWa(buffer.toString());
  }

  Future<void> _kirimWa(String text) async {
    final message = Uri.encodeComponent(text);
    final nomor = SettingsService.instance.nomorWa.replaceAll(RegExp(r'[^0-9]'), '');
    final nativeUrl = nomor.isEmpty
        ? Uri.parse('whatsapp://send?text=$message')
        : Uri.parse('whatsapp://send?phone=$nomor&text=$message');
    final webUrl = nomor.isEmpty
        ? Uri.parse('https://wa.me/?text=$message')
        : Uri.parse('https://wa.me/$nomor?text=$message');
    try {
      if (await canLaunchUrl(nativeUrl)) {
        await launchUrl(nativeUrl);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuka WhatsApp: $e')));
      }
    }
  }

  Widget _card(String title, String value, IconData icon) {
    final accent = Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: accent),
        ),
        title: Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF667085))),
        subtitle: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accent)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final harian = _omzetHarian.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          IconButton(
            tooltip: 'Foto catatan',
            icon: const Icon(Icons.document_scanner_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteScansScreen(
                  initialDate: _selectedFilterIndex == 1 ? DateTime.now() : _endDate,
                ),
              ),
            ),
          ),
          IconButton(tooltip: 'Kirim rekap WhatsApp', icon: const Icon(Icons.share_outlined), onPressed: _exportWhatsApp),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('7 Hari'), selected: _selectedFilterIndex == 0, onSelected: (_) => _applyFilter(0)),
              ChoiceChip(label: const Text('Bulan Ini'), selected: _selectedFilterIndex == 1, onSelected: (_) => _applyFilter(1)),
              ChoiceChip(label: const Text('Bulan Lalu'), selected: _selectedFilterIndex == 2, onSelected: (_) => _applyFilter(2)),
            ],
          ),
          const SizedBox(height: 8),
          Center(child: Text(_periodLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteScansScreen(
                  initialDate: _selectedFilterIndex == 1 ? DateTime.now() : _endDate,
                ),
              ),
            ),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Arsip foto buku catatan'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: _sisaOperasional >= 0 ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('SISA OPERASIONAL (omzet sewa − pengeluaran)'),
                  Text(
                    currency.format(_sisaOperasional),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _sisaOperasional >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _card('Durasi sewa', '${_totalMenitRental ~/ 60} jam ${_totalMenitRental % 60} menit (${_rentals.length} sesi)', Icons.timer_outlined),
          _card('Omzet sewa', currency.format(_totalSaldoRental), Icons.sports_esports),
          _card('Cash', currency.format(_cash), Icons.payments),
          _card('Transfer', currency.format(_transfer), Icons.account_balance),
          _card('Pengeluaran', currency.format(_totalPengeluaran), Icons.money_off),
          const SizedBox(height: 12),
          const Text('Pengeluaran per kategori', style: TextStyle(fontWeight: FontWeight.bold)),
          if (_keluarPerKategori.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Tidak ada'))
          else
            ..._keluarPerKategori.entries.map((e) => ListTile(
                  dense: true,
                  title: Text(e.key),
                  trailing: Text(currency.format(e.value)),
                )),
          const SizedBox(height: 8),
          const Text('Omzet harian', style: TextStyle(fontWeight: FontWeight.bold)),
          if (harian.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Tidak ada'))
          else
            ...harian.map((e) => ListTile(
                  dense: true,
                  title: Text(DateFormat('dd MMM yyyy').format(DateTime.parse(e.key))),
                  trailing: Text(currency.format(e.value), style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.share_outlined),
            label: const Text('Kirim rekap ke WhatsApp'),
            onPressed: _exportWhatsApp,
          ),
        ],
      ),
    );
  }
}
