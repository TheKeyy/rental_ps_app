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
import 'report_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedDate;
  List<Rental> _rentalList = [];
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
    final buf = StringBuffer();
    for (int ps = 1; ps <= SettingsService.instance.jumlahPs; ps++) {
      final r = RentalTime.aktifUntukPs(_rentalList, ps, now);
      buf.write('$ps:');
      if (r != null) buf.write(RentalTime.endOf(r).difference(now).inSeconds);
      buf.write('|');
    }
    return buf.toString();
  }

  Future<void> _loadAllData() async {
    final rentals = await DatabaseHelper.instance.getRentalsByDate(_selectedDate);
    final expenses = await DatabaseHelper.instance.getExpensesByDate(_selectedDate);
    if (!mounted) return;
    setState(() {
      _rentalList = rentals;
      _expenseList = expenses;
    });
    _syncNotifications();
  }

  Future<void> _syncNotifications() async {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    for (int ps = 1; ps <= SettingsService.instance.jumlahPs; ps++) {
      if (_selectedDate != todayStr) {
        await AlertService.instance.batalkanSemua(ps);
        continue;
      }
      final aktif = RentalTime.aktifUntukPs(_rentalList, ps, now);
      if (aktif == null) {
        await AlertService.instance.batalkanSemua(ps);
      } else {
        await AlertService.instance.jadwalkanHabis(
          psNomor: ps,
          nama: aktif.nama,
          selesai: RentalTime.endOf(aktif),
        );
      }
    }
  }

  Future<void> _playAlertSound(String message) async {
    await AlertService.instance.bunyiLokal();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 4)),
    );
  }

  void _checkTimersForAlert() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_selectedDate != todayStr) return;
    final now = DateTime.now();
    for (int ps = 1; ps <= SettingsService.instance.jumlahPs; ps++) {
      final rental = RentalTime.aktifUntukPs(_rentalList, ps, now);
      if (rental == null) continue;
      final diff = RentalTime.endOf(rental).difference(now);
      final key5Min = '${rental.id}_5min';
      final keyDone = '${rental.id}_done';
      if (diff.inSeconds <= 300 && diff.inSeconds > 240 && !_playedAlarms.contains(key5Min)) {
        _playedAlarms.add(key5Min);
        _playAlertSound('Waktu PS $ps (${rental.nama}) sisa 5 menit lagi!');
      }
      if (diff.inSeconds <= 0 && diff.inSeconds > -10 && !_playedAlarms.contains(keyDone)) {
        _playedAlarms.add(keyDone);
        _playAlertSound('WAKTU HABIS! PS $ps (${rental.nama}) sudah selesai!');
      }
    }
  }

  int get _totalSaldoRental => _rentalList.fold(0, (sum, item) => sum + item.saldo);
  int get _totalMenitRental => _rentalList.fold(0, (sum, item) => sum + item.durasiMenit);
  int get _totalPengeluaran => _expenseList.fold(0, (sum, item) => sum + item.nominal);
  int get _labaBersih => _totalSaldoRental - _totalPengeluaran;
  int get _cash => _rentalList.where((r) => r.metodeBayar.toLowerCase() == 'cash').fold(0, (s, r) => s + r.saldo);
  int get _transfer => _rentalList.where((r) => r.metodeBayar.toLowerCase() != 'cash').fold(0, (s, r) => s + r.saldo);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = DateFormat('yyyy-MM-dd').format(picked));
      await _loadAllData();
    }
  }

  Future<void> _exportToWhatsApp() async {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final dateStr = DateFormat('dd MMMM yyyy').format(DateTime.parse(_selectedDate));
    final nama = SettingsService.instance.namaWarung;
    final buffer = StringBuffer();
    buffer.writeln('🎮 *$nama*');
    buffer.writeln('📅 Tanggal: $dateStr');
    buffer.writeln('----------------------------------');
    buffer.writeln('⏱️ Total waktu sewa: ${_totalMenitRental ~/ 60} jam ${_totalMenitRental % 60} mnt');
    buffer.writeln('💰 Kas sewa: ${currency.format(_totalSaldoRental)}');
    buffer.writeln('💵 Cash: ${currency.format(_cash)} | 🏦 TF: ${currency.format(_transfer)}');
    buffer.writeln('💸 Pengeluaran: ${currency.format(_totalPengeluaran)}');
    buffer.writeln('✨ *LABA:* ${currency.format(_labaBersih)}');
    buffer.writeln('----------------------------------');
    buffer.writeln('📋 *Detail sewa:*');
    if (_rentalList.isEmpty) {
      buffer.writeln('- (Tidak ada sewa)');
    } else {
      for (final r in _rentalList) {
        buffer.writeln('• PS${r.psNomor} - ${r.nama} (${r.waktuMulai}-${r.waktuSelesai}): ${currency.format(r.saldo)} [${r.metodeBayar}]');
      }
    }
    buffer.writeln('----------------------------------');
    buffer.writeln('📝 *Pengeluaran:*');
    if (_expenseList.isEmpty) {
      buffer.writeln('- (Tidak ada)');
    } else {
      for (final e in _expenseList) {
        buffer.writeln('• [${e.kategori}] ${e.keterangan}: ${currency.format(e.nominal)}');
      }
    }

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

  void _confirmDelete({required String title, required String content, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _perpanjangSewa(Rental rental, int menitTambahan, int biayaTambahan) async {
    final now = DateTime.now();
    final currentEnd = RentalTime.endOf(rental);
    final baseTime = currentEnd.isBefore(now) ? now : currentEnd;
    final newEnd = baseTime.add(Duration(minutes: menitTambahan));
    final extraFromNow = currentEnd.isBefore(now);
    final durasiBaru = extraFromNow
        ? now.difference(RentalTime.startOf(rental)).inMinutes + menitTambahan
        : rental.durasiMenit + menitTambahan;

    final updated = rental.copyWith(
      waktuSelesai: RentalTime.formatJam(newEnd),
      durasiMenit: durasiBaru < 0 ? menitTambahan : durasiBaru,
      saldo: rental.saldo + biayaTambahan,
    );
    await DatabaseHelper.instance.updateRental(updated);
    await _loadAllData();
  }

  void _showExtendDialog(Rental rental) {
    final s = SettingsService.instance;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Perpanjang PS ${rental.psNomor}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [10, 20, 30, 60, 120].map((m) {
            final harga = m == 10 ? 1000 : s.tarifUntuk(m);
            return ListTile(
              title: Text(Tariff.labelDurasi(m)),
              trailing: Text('Rp ${NumberFormat('#,###', 'id').format(harga)}'),
              onTap: () {
                Navigator.pop(ctx);
                _perpanjangSewa(rental, m, harga);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showStopDialog(Rental rental) {
    final now = DateTime.now();
    final sisaMenit = RentalTime.endOf(rental).difference(now).inMinutes;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Stop main PS ${rental.psNomor}'),
        content: Text(
          sisaMenit > 0
              ? 'Waktu tersisa $sisaMenit menit.\nSimpan sisa ke saldo ${rental.nama.split('(').first.trim()}?'
              : 'Hentikan sesi sewa ini sekarang?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          if (sisaMenit > 0)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
              onPressed: () async {
                Navigator.pop(ctx);
                final cleanName = rental.nama.split('(').first.trim();
                await DatabaseHelper.instance.tambahSisaMenit(cleanName, sisaMenit);
                await _stopRentalRecord(rental, simpanSisa: true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Disimpan $sisaMenit menit untuk $cleanName')),
                  );
                }
              },
              child: const Text('Simpan sisa', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _stopRentalRecord(rental, simpanSisa: false);
            },
            child: const Text('Berhenti', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _stopRentalRecord(Rental rental, {required bool simpanSisa}) async {
    final now = DateTime.now();
    final start = RentalTime.startOf(rental);
    var elapsed = now.difference(start).inMinutes;
    if (elapsed < 0) elapsed = 0;
    if (elapsed > rental.durasiMenit) elapsed = rental.durasiMenit;
    final updated = rental.copyWith(
      waktuSelesai: RentalTime.formatJam(now),
      durasiMenit: elapsed,
    );
    await DatabaseHelper.instance.updateRental(updated);
    await AlertService.instance.batalkanSemua(rental.psNomor);
    await _loadAllData();
  }

  Future<void> _showAllDepositsDialog() async {
    final deposits = await DatabaseHelper.instance.getAllDeposits();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tabungan sisa waktu', style: TextStyle(fontSize: 16)),
        content: deposits.isEmpty
            ? const Text('Belum ada simpanan sisa waktu.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: deposits.length,
                  itemBuilder: (context, index) {
                    final item = deposits[index];
                    final menit = item['sisa_menit'] as int;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item['nama'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('$menit mnt (${menit ~/ 60}j ${menit % 60}m)'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _editDeposit(item);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () async {
                              await DatabaseHelper.instance.hapusDeposit(item['id'] as int);
                              Navigator.pop(ctx);
                              _showAllDepositsDialog();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
      ),
    );
  }

  Future<void> _editDeposit(Map<String, dynamic> item) async {
    final ctrl = TextEditingController(text: '${item['sisa_menit']}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ubah sisa ${item['nama']}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Sisa menit'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper.instance.setSisaMenit(item['id'] as int, int.tryParse(ctrl.text) ?? 0);
      if (mounted) _showAllDepositsDialog();
    }
  }

  Widget _buildPSCard(int psNomor) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = _selectedDate == todayStr;
    final now = DateTime.now();
    final rental = isToday ? RentalTime.aktifUntukPs(_rentalList, psNomor, now) : null;
    final next = isToday ? RentalTime.berikutnyaUntukPs(_rentalList, psNomor, now) : null;

    bool isPlaying = false;
    String statusText = 'KOSONG';
    String timerText = '--:--';
    Color cardColor = Colors.grey.shade100;
    Color statusColor = Colors.grey;

    if (!isToday) {
      statusText = 'REKAP';
      timerText = '00:00';
      cardColor = Colors.blueGrey.shade50;
      statusColor = Colors.blueGrey;
    } else if (rental != null) {
      final diff = RentalTime.endOf(rental).difference(now);
      if (diff.isNegative) {
        statusText = 'WAKTU HABIS';
        timerText = '00:00';
        cardColor = Colors.red.shade50;
        statusColor = Colors.red;
      } else {
        isPlaying = true;
        statusText = 'MAIN: ${rental.nama}';
        timerText = RentalTime.formatSisa(diff);
        cardColor = Colors.green.shade50;
        statusColor = Colors.green.shade800;
      }
    } else if (next != null) {
      statusText = 'ANTRI: ${next.nama} ${next.waktuMulai}';
      timerText = next.waktuMulai;
      cardColor = Colors.orange.shade50;
      statusColor = Colors.deepOrange;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PS $psNomor', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(
              statusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: statusColor),
            ),
            FittedBox(
              child: Text(
                timerText,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isPlaying ? Colors.black87 : Colors.grey),
              ),
            ),
            if (isToday && isPlaying && rental != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _showExtendDialog(rental),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(4)),
                        alignment: Alignment.center,
                        child: const Text('+Waktu', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: InkWell(
                      onTap: () => _showStopDialog(rental),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(4)),
                        alignment: Alignment.center,
                        child: const Text('Stop', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openRental({Rental? existing}) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRentalScreen(selectedDate: _selectedDate, existing: existing),
      ),
    );
    if (res == true) _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final settings = SettingsService.instance;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _pickDate,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${settings.namaWarung} · ${DateFormat('dd/MM/yy').format(DateTime.parse(_selectedDate))}'),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())),
          ),
          IconButton(icon: const Icon(Icons.savings_outlined), onPressed: _showAllDepositsDialog),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              if (res == true && mounted) setState(() {});
              _loadAllData();
            },
          ),
          IconButton(icon: const Icon(Icons.share, color: Colors.green), onPressed: _exportToWhatsApp),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.sports_esports), text: 'Sewa'),
            Tab(icon: Icon(Icons.money_off), text: 'Keluar'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sewa: ${currency.format(_totalSaldoRental)}  Cash ${currency.format(_cash)} / TF ${currency.format(_transfer)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      Text('Keluar: ${currency.format(_totalPengeluaran)}',
                          style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Laba', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(
                      currency.format(_labaBersih),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _labaBersih >= 0 ? Colors.green.shade800 : Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.35,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        children: [
                          for (int ps = 1; ps <= settings.jumlahPs; ps++) _buildPSCard(ps),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _rentalList.isEmpty
                          ? const Center(child: Text('Belum ada sewa di tanggal ini.'))
                          : ListView.builder(
                              itemCount: _rentalList.length,
                              itemBuilder: (context, index) {
                                final r = _rentalList[index];
                                return ListTile(
                                  leading: CircleAvatar(child: Text('PS${r.psNomor}')),
                                  title: Text('${r.nama} (${r.waktuMulai} - ${r.waktuSelesai})'),
                                  subtitle: Text('${r.durasiMenit} menit | ${r.metodeBayar}'),
                                  onTap: () => _openRental(existing: r),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(currency.format(r.saldo), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                        onPressed: () {
                                          _confirmDelete(
                                            title: 'Hapus catatan sewa',
                                            content: 'Hapus sewa PS${r.psNomor} atas nama ${r.nama}?',
                                            onConfirm: () async {
                                              await DatabaseHelper.instance.deleteRental(r.id!);
                                              _loadAllData();
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                _expenseList.isEmpty
                    ? const Center(child: Text('Tidak ada pengeluaran di tanggal ini.'))
                    : ListView.builder(
                        itemCount: _expenseList.length,
                        itemBuilder: (context, index) {
                          final e = _expenseList[index];
                          return ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.money_off, color: Colors.white)),
                            title: Text(e.keterangan),
                            subtitle: Text('${e.kategori} · ${e.waktu}'),
                            onTap: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddExpenseScreen(selectedDate: _selectedDate, existing: e),
                                ),
                              );
                              if (res == true) _loadAllData();
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('- ${currency.format(e.nominal)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                  onPressed: () {
                                    _confirmDelete(
                                      title: 'Hapus pengeluaran',
                                      content: "Hapus '${e.keterangan}'?",
                                      onConfirm: () async {
                                        await DatabaseHelper.instance.deleteExpense(e.id!);
                                        _loadAllData();
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_tabController.index == 0) {
            await _openRental();
          } else {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddExpenseScreen(selectedDate: _selectedDate)),
            );
            if (res == true) _loadAllData();
          }
        },
        label: Text(_tabController.index == 0 ? 'Catat sewa' : 'Catat keluar'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
