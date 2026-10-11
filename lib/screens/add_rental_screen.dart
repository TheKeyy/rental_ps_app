import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';
import '../models/rental_model.dart';
import '../services/alert_service.dart';
import '../services/rental_time.dart';
import '../services/settings_service.dart';
import '../services/tariff.dart';

class AddRentalScreen extends StatefulWidget {
  final String? selectedDate;
  final Rental? existing;

  const AddRentalScreen({super.key, this.selectedDate, this.existing});

  @override
  State<AddRentalScreen> createState() => _AddRentalScreenState();
}

class _AddRentalScreenState extends State<AddRentalScreen> {
  final _namaController = TextEditingController();
  final _saldoController = TextEditingController();

  late DateTime _tanggalTransaksi;
  int _selectedPS = 1;
  int _durasiBaruMenit = 60;
  String _metodeBayar = 'Cash';
  TimeOfDay _waktuMulai = TimeOfDay.now();

  int _depositTersedia = 0;
  int _depositDipakai = 0;

  List<Rental> _sewaHariIni = [];
  bool _isLoadingStatus = true;

  bool get _editMode => widget.existing != null;

  List<int> get _pilihanDurasi {
    final list = List<int>.from(Tariff.durasiPilihan);
    if (!list.contains(10)) {
      list.insert(0, 10);
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _tanggalTransaksi = DateTime.parse(existing.tanggal);
      _namaController.text = existing.nama.split('(').first.trim();
      _selectedPS = existing.psNomor;
      _durasiBaruMenit = existing.durasiMenit;
      _metodeBayar = existing.metodeBayar;
      _saldoController.text = existing.saldo.toString();
      final parts = existing.waktuMulai.split(':');
      _waktuMulai = TimeOfDay(
        hour: (int.tryParse(parts[0]) ?? 0) % 24,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      );
    } else {
      _tanggalTransaksi = widget.selectedDate != null
          ? DateTime.parse(widget.selectedDate!)
          : DateTime.now();
      _updateTarifOtomatis();
    }
    _checkActiveUnits();
  }

  Future<void> _checkActiveUnits() async {
    final transStr = DateFormat('yyyy-MM-dd').format(_tanggalTransaksi);
    final selectedDay = DateTime.parse(transStr);
    final previousDay = DateFormat('yyyy-MM-dd').format(selectedDay.subtract(const Duration(days: 1)));
    final rentals = await DatabaseHelper.instance.getRentalsByDateRange(previousDay, transStr);
    if (!mounted) return;
    setState(() {
      _sewaHariIni = rentals;
      _isLoadingStatus = false;
      if (!_editMode) {
        final now = DateTime.now();
        final settings = SettingsService.instance;
        for (int ps = 1; ps <= settings.jumlahPs; ps++) {
          if (RentalTime.aktifUntukPs(rentals, ps, now) == null) {
            _selectedPS = ps;
            break;
          }
        }
      }
    });
  }

  void _checkDeposit(String nama) async {
    if (_editMode) return;
    if (nama.trim().isEmpty) {
      setState(() {
        _depositTersedia = 0;
        _depositDipakai = 0;
      });
      _updateTarifOtomatis();
      return;
    }
    final namaCek = nama.trim();
    final sisa = await DatabaseHelper.instance.getSisaMenit(namaCek);
    if (!mounted || _namaController.text.trim() != namaCek) return;
    setState(() {
      _depositTersedia = sisa;
      _depositDipakai = sisa;
    });
    _updateTarifOtomatis();
  }

  void _updateTarifOtomatis() {
    _saldoController.text = SettingsService.instance.tarifUntuk(_durasiBaruMenit).toString();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalTransaksi,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _tanggalTransaksi = picked);
      await _checkActiveUnits();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _waktuMulai);
    if (picked != null) {
      setState(() => _waktuMulai = picked);
    }
  }

  DateTime get _startTime => DateTime(
        _tanggalTransaksi.year,
        _tanggalTransaksi.month,
        _tanggalTransaksi.day,
        _waktuMulai.hour,
        _waktuMulai.minute,
      );

  int get _totalMenitMain => _editMode ? _durasiBaruMenit : (_durasiBaruMenit + _depositDipakai);

  Future<void> _simpanTransaksi() async {
    final nama = _namaController.text.trim();
    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama penyewa wajib diisi!')),
      );
      return;
    }

    final totalDurasiMain = _totalMenitMain;
    if (totalDurasiMain <= 0) return;
    final nominal = int.tryParse(_saldoController.text);
    if (nominal == null || nominal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarif tidak boleh kosong atau negatif.')),
      );
      return;
    }

    final startTime = _startTime;
    final endTime = startTime.add(Duration(minutes: totalDurasiMain));

    if (RentalTime.bentrok(
      existing: _sewaHariIni,
      psNomor: _selectedPS,
      mulai: startTime,
      selesai: endTime,
      kecualiId: widget.existing?.id,
    )) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Jadwal bentrok'),
          content: Text(
            'PS $_selectedPS sudah terisi di jam ${RentalTime.formatJam(startTime)}–${RentalTime.formatJam(endTime)}. Pilih jam lain atau unit lain.',
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti'))],
        ),
      );
      return;
    }

    final namaSimpan = (!_editMode && _depositDipakai > 0) ? '$nama (Sisa ${_depositDipakai}m)' : nama;

    final rental = Rental(
      id: widget.existing?.id,
      nama: namaSimpan,
      psNomor: _selectedPS,
      waktuMulai: RentalTime.formatJam(startTime),
      waktuSelesai: RentalTime.formatJam(endTime),
      durasiMenit: totalDurasiMain,
      saldo: nominal,
      metodeBayar: _metodeBayar,
      tanggal: DateFormat('yyyy-MM-dd').format(_tanggalTransaksi),
    );

    late final int rentalId;
    try {
      rentalId = await DatabaseHelper.instance.simpanRentalAtomik(
        rental,
        editMode: _editMode,
        namaDeposit: _editMode ? null : nama,
        menitDeposit: _editMode ? 0 : _depositDipakai,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi gagal disimpan: $e')),
      );
      return;
    }

    try {
      await AlertService.instance.jadwalkanHabis(
        rentalId: rentalId,
        psNomor: rental.psNomor,
        nama: rental.nama,
        selesai: endTime,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sewa tersimpan, tetapi notifikasi gagal dijadwalkan.')),
        );
      }
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _saldoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(_editMode ? 'Ubah sewa' : 'Catat sewa baru')),
      body: _isLoadingStatus
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.42),
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
                    title: const Text('Tanggal pembukuan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(_tanggalTransaksi),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                    trailing: Icon(Icons.edit_calendar, color: Theme.of(context).colorScheme.primary),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('Jam mulai', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(
                      _waktuMulai.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: _pickTime,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama penyewa',
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: 'Ketik nama untuk cek sisa waktu...',
                  ),
                  onChanged: _checkDeposit,
                ),
                if (!_editMode && _depositTersedia > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      border: Border.all(color: Colors.amber.shade400),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Punya sisa waktu: $_depositTersedia menit',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Pakai sisa waktu sekarang?', style: TextStyle(fontSize: 14)),
                          value: _depositDipakai > 0,
                          onChanged: (val) {
                            setState(() => _depositDipakai = val ? _depositTersedia : 0);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text('Unit dan durasi', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('Pilih unit PS:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int ps = 1; ps <= settings.jumlahPs; ps++)
                      Builder(
                        builder: (_) {
                          final aktif = RentalTime.aktifUntukPs(_sewaHariIni, ps, now);
                          final next = RentalTime.berikutnyaUntukPs(_sewaHariIni, ps, now);
                          final sibuk = aktif != null && !_editMode;
                          return ChoiceChip(
                            avatar: sibuk ? const Icon(Icons.lock_clock, size: 16, color: Colors.red) : null,
                            label: Text(
                              sibuk
                                  ? 'PS $ps (dipakai: ${aktif.nama})'
                                  : next != null
                                      ? 'PS $ps (antrian ${next.waktuMulai})'
                                      : 'PS $ps (tersedia)',
                            ),
                            selected: _selectedPS == ps,
                            onSelected: (_) => setState(() => _selectedPS = ps),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Durasi sewa (bayar baru):', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: _pilihanDurasi.map((durasi) {
                    return ChoiceChip(
                      label: Text(Tariff.labelDurasi(durasi)),
                      selected: _durasiBaruMenit == durasi,
                      onSelected: (_) {
                        setState(() {
                          _durasiBaruMenit = durasi;
                          _updateTarifOtomatis();
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Total main: $_totalMenitMain menit (${_totalMenitMain ~/ 60} jam ${_totalMenitMain % 60} mnt) '
                    'sampai ${RentalTime.formatJam(_startTime.add(Duration(minutes: _totalMenitMain)))}',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Pembayaran', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                TextField(
                  controller: _saldoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tarif yang wajib dibayar (Rp)',
                    prefixIcon: Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Cash'),
                      selected: _metodeBayar == 'Cash',
                      onSelected: (_) => setState(() => _metodeBayar = 'Cash'),
                    ),
                    ChoiceChip(
                      label: const Text('Transfer'),
                      selected: _metodeBayar == 'Transfer',
                      onSelected: (_) => setState(() => _metodeBayar = 'Transfer'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _simpanTransaksi,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  child: Text(_editMode ? 'Simpan perubahan' : 'Simpan transaksi'),
                ),
              ],
            ),
    );
  }
}
