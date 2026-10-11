import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/db_helper.dart';
import '../models/expense_model.dart';
import '../models/rental_model.dart';
import '../services/alert_service.dart';
import '../services/rental_time.dart';
import '../services/settings_service.dart';
import '../services/tariff.dart';
import 'add_expense_screen.dart';
import 'add_rental_screen.dart';
import 'note_scan_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'bookings_screen.dart';
import 'units_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedDate;
  List<Rental> _rentalList = [];
  List<Rental> _todayRentalList = [];
  List<Expense> _expenseList = [];
  Timer? _timer;
  String _timerSignature = '';
  final Set<String> _playedAlarms = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadAllData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _checkTimersForAlert();
      final sig = _buildTimerSignature();
      if (sig != _timerSignature) {
        _timerSignature = sig;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _buildTimerSignature() {
    final now = DateTime.now();
    final buffer = StringBuffer();
    for (final r in _todayRentalList) {
      final start = RentalTime.startOf(r);
      final end = RentalTime.endOf(r);
      if (now.isAfter(start) && now.isBefore(end)) {
        buffer.write('${r.id}_${end.millisecondsSinceEpoch}_${end.difference(now).inSeconds}|');
      }
    }
    return buffer.toString();
  }

  void _checkTimersForAlert() {
    final now = DateTime.now();
    for (final r in _todayRentalList) {
      final end = RentalTime.endOf(r);
      final sisaDetik = end.difference(now).inSeconds;

      final key5 = '${r.id}_${end.millisecondsSinceEpoch}_5m';
      if (sisaDetik <= 300 && sisaDetik > 290 && !_playedAlarms.contains(key5)) {
        _playedAlarms.add(key5);
        AlertService.instance.bunyiLokal();
      }

      final key0 = '${r.id}_${end.millisecondsSinceEpoch}_0m';
      if (sisaDetik <= 0 && sisaDetik >= -5 && !_playedAlarms.contains(key0)) {
        _playedAlarms.add(key0);
        AlertService.instance.bunyiLokal();
      }
    }
  }

  Future<void> _loadAllData() async {
    final today = DateTime.now();
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(today.subtract(const Duration(days: 1)));

    final rentals = await DatabaseHelper.instance.getRentalsByDate(_selectedDate);
    final expenses = await DatabaseHelper.instance.getExpensesByDate(_selectedDate);
    // Live status/timers must not stop working just because an older date is selected.
    final liveRentals = await DatabaseHelper.instance.getRentalsByDateRange(yesterdayStr, DateFormat('yyyy-MM-dd').format(today.add(const Duration(days: 1))));

    if (!mounted) return;
    setState(() {
      _rentalList = rentals;
      _expenseList = expenses;
      _todayRentalList = liveRentals;
    });
  }

  int get _omzetSewa => _rentalList.fold(0, (sum, r) => sum + r.saldo);
  int get _totalPengeluaran => _expenseList.fold(0, (sum, e) => sum + e.nominal);
  int get _sisaOperasional => _omzetSewa - _totalPengeluaran;

  Future<void> _pickDate() async {
    final cur = DateTime.tryParse(_selectedDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: cur,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
      _loadAllData();
    }
  }

  Future<void> _exportWhatsApp() async {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final nama = SettingsService.instance.namaWarung;
    final tanggalFormat = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.parse(_selectedDate));

    final buffer = StringBuffer();
    buffer.writeln('🎮 *REKAP HARIAN $nama*');
    buffer.writeln('🗓️ Tanggal: $tanggalFormat');
    buffer.writeln('----------------------------------');
    buffer.writeln('🕹️ Omzet Sewa PS: ${currency.format(_omzetSewa)} (${_rentalList.length} sesi)');
    buffer.writeln('💸 Pengeluaran: ${currency.format(_totalPengeluaran)} (${_expenseList.length} pos)');
    buffer.writeln('📊 *SISA OPERASIONAL:* ${currency.format(_sisaOperasional)}');
    buffer.writeln('🔢 ${_rentalList.length} sesi sewa');
    buffer.writeln('----------------------------------');

    final message = Uri.encodeComponent(buffer.toString());
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

  void _simpanSisaWaktuModal(Rental rental) {
    final now = DateTime.now();
    final end = RentalTime.endOf(rental);
    final diff = end.difference(now);
    final sisaMenit = diff.inMinutes;

    if (sisaMenit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waktu rental ini sudah habis')),
      );
      return;
    }

    final namaClean = rental.nama.split('(').first.trim();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan sisa waktu?'),
        content: Text(
          'Simpan sisa $sisaMenit menit atas nama "$namaClean" ke deposit waktu?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.tambahSisaMenit(namaClean, sisaMenit);

              final durasiBaru = now.difference(RentalTime.startOf(rental)).inMinutes;
              final rBaru = rental.copyWith(
                durasiMenit: durasiBaru < 0 ? 0 : durasiBaru,
                waktuSelesai: RentalTime.formatJam(now),
              );
              await DatabaseHelper.instance.updateRental(rBaru);
              if (rental.id != null) await AlertService.instance.batalkanUntukSewa(rental.id!);
              _loadAllData();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sisa $sisaMenit menit disimpan untuk $namaClean')),
                );
              }
            },
            child: const Text('Simpan Deposit'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitPSCards() {
    final settings = SettingsService.instance;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: settings.jumlahPs,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final ps = index + 1;
          final aktif = RentalTime.aktifUntukPs(_todayRentalList, ps, now);
          final next = RentalTime.berikutnyaUntukPs(_todayRentalList, ps, now);

          Duration diff = Duration.zero;
          if (aktif != null) {
            diff = RentalTime.endOf(aktif).difference(now);
            if (diff.isNegative) diff = Duration.zero;
          }

          final isBusy = aktif != null;
          final isWarning = isBusy && diff.inMinutes <= 5;

          return SizedBox(
            width: 180,
            child: Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: !isBusy
                      ? const Color(0xFFB7E4C7)
                      : isWarning
                          ? const Color(0xFFF4D29B)
                          : const Color(0xFFC7D2FE),
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PS $ps',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: !isBusy
                                ? const Color(0xFF15803D)
                                : isWarning
                                    ? const Color(0xFFB45309)
                                    : const Color(0xFF4F46E5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            !isBusy ? 'KOSONG' : isWarning ? 'HAMPIR HABIS' : 'MAIN',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (isBusy) ...[
                      Text(
                        aktif.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        RentalTime.formatSisa(diff),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isWarning ? const Color(0xFFB45309) : const Color(0xFF3730A3),
                        ),
                      ),
                      InkWell(
                        onTap: () => _simpanSisaWaktuModal(aktif),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.save_as, size: 14, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                'Stop & simpan sisa',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      const Spacer(),
                      if (next != null)
                        Text(
                          'Antrean: ${next.nama} (${next.waktuMulai})',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        )
                      else
                        const Text(
                          'Siap digunakan',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                        ),
                      const Spacer(),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openNoteScans() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteScansScreen(
          initialDate: DateTime.tryParse(_selectedDate),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    Widget metric(String label, String value, {Alignment alignment = Alignment.centerLeft}) {
      return Expanded(
        child: Align(
          alignment: alignment,
          child: Column(
            crossAxisAlignment: alignment == Alignment.centerRight
                ? CrossAxisAlignment.end
                : alignment == Alignment.center
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              const SizedBox(height: 5),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3730A3), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Ringkasan harian',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              metric('Omzet sewa', currency.format(_omzetSewa)),
              const SizedBox(width: 8),
              metric('Sesi sewa', '${_rentalList.length}', alignment: Alignment.center),
              const SizedBox(width: 8),
              metric('Pengeluaran', currency.format(_totalPengeluaran), alignment: Alignment.centerRight),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Colors.white30),
          ),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sisa operasional', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(height: 3),
                    Text('Omzet sewa dikurangi pengeluaran', style: TextStyle(color: Colors.white60, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  currency.format(_sisaOperasional),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _sisaOperasional >= 0 ? Colors.white : const Color(0xFFFFD5D5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(SettingsService.instance.namaWarung),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Laporan',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.event_available_outlined),
            tooltip: 'Booking Rental',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsScreen()));
              _loadAllData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined),
            tooltip: 'Foto Catatan',
            onPressed: _openNoteScans,
          ),
          IconButton(
            icon: const Icon(Icons.sports_esports_outlined),
            tooltip: 'Manajemen Unit',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const UnitsScreen()));
              _loadAllData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan',
            onPressed: () async {
              final ok = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              if (ok == true) {
                setState(() {});
                _loadAllData();
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: [
              InkWell(
                onTap: _pickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy').format(DateTime.parse(_selectedDate)),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Sewa (${_rentalList.length})'),
                  Tab(text: 'Keluar (${_expenseList.length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _buildUnitPSCards(),
          _buildSummaryCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: RENTAL LIST
                _rentalList.isEmpty
                    ? const Center(child: Text('Belum ada transaksi sewa hari ini.'))
                    : ListView.builder(
                        itemCount: _rentalList.length,
                        itemBuilder: (context, index) {
                          final r = _rentalList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text('PS ${r.psNomor}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              title: Text(r.nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${r.waktuMulai} - ${r.waktuSelesai} (${r.durasiMenit}m) • ${r.metodeBayar}'),
                              trailing: Text(
                                currency.format(r.saldo),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                              ),
                              onTap: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddRentalScreen(selectedDate: _selectedDate, existing: r),
                                  ),
                                );
                                if (updated == true) _loadAllData();
                              },
                              onLongPress: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus transaksi?'),
                                    content: Text('Hapus sewa ${r.nama} di PS ${r.psNomor}?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          await DatabaseHelper.instance.deleteRental(r.id!);
                                          await AlertService.instance.batalkanUntukSewa(r.id!);
                                          _loadAllData();
                                        },
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                // TAB 2: EXPENSES LIST
                _expenseList.isEmpty
                    ? const Center(child: Text('Belum ada pengeluaran hari ini.'))
                    : ListView.builder(
                        itemCount: _expenseList.length,
                        itemBuilder: (context, index) {
                          final e = _expenseList[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.shade100,
                                child: const Icon(Icons.money_off, color: Colors.red, size: 20),
                              ),
                              title: Text(e.keterangan, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${e.kategori} • ${e.waktu}'),
                              trailing: Text(
                                currency.format(e.nominal),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                              onTap: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddExpenseScreen(selectedDate: _selectedDate, existing: e),
                                  ),
                                );
                                if (updated == true) _loadAllData();
                              },
                              onLongPress: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus pengeluaran?'),
                                    content: Text('Hapus "${e.keterangan}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          await DatabaseHelper.instance.deleteExpense(e.id!);
                                          _loadAllData();
                                        },
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                icon: const Icon(Icons.share),
                tooltip: 'Bagikan Rekap ke WA',
                onPressed: _exportWhatsApp,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: Icon(_tabController.index == 1 ? Icons.money_off : Icons.add),
                  label: Text(_tabController.index == 1 ? '+ Pengeluaran' : '+ Sewa Baru'),
                  onPressed: () async {
                    if (_tabController.index == 1) {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddExpenseScreen(selectedDate: _selectedDate)),
                      );
                      if (res == true) _loadAllData();
                    } else {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddRentalScreen(selectedDate: _selectedDate)),
                      );
                      if (res == true) _loadAllData();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
