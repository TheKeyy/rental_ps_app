import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/backup_service.dart';
import '../services/settings_service.dart';
import '../services/tariff.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _namaCtrl;
  late final TextEditingController _waCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _per10Ctrl;
  late int _jumlahPs;
  late bool _pinOn;
  late Map<int, int> _paket;

  @override
  void initState() {
    super.initState();
    final s = SettingsService.instance;
    _namaCtrl = TextEditingController(text: s.namaWarung);
    _waCtrl = TextEditingController(text: s.nomorWa);
    _pinCtrl = TextEditingController(text: s.pin);
    _per10Ctrl = TextEditingController(text: s.hargaPer10.toString());
    _jumlahPs = s.jumlahPs;
    _pinOn = s.pinAktif;
    _paket = Map<int, int>.from(s.paket);
  }

  Future<void> _simpan() async {
    final s = SettingsService.instance;
    await s.setNamaWarung(_namaCtrl.text);
    await s.setNomorWa(_waCtrl.text);
    await s.setJumlahPs(_jumlahPs);
    await s.setPin(aktif: _pinOn, pin: _pinCtrl.text);
    await s.setHargaPer10(int.tryParse(_per10Ctrl.text) ?? Tariff.hargaPer10Default);
    await s.setPaket(_paket);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan disimpan')));
      Navigator.pop(context, true);
    }
  }

  Future<void> _backup() async {
    try {
      await BackupService.bagikanCadangan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal cadangan: $e')));
      }
    }
  }

  Future<void> _restore() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pulihkan data?'),
        content: const Text('Data sekarang akan diganti file cadangan. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Pulihkan')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final restored = await BackupService.pulihkanDariFile();
      if (restored && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data dipulihkan')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal pulihkan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _namaCtrl,
            decoration: const InputDecoration(labelText: 'Nama warung', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _waCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor WhatsApp (opsional, 62...)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Jumlah unit PS: $_jumlahPs', style: const TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _jumlahPs.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            label: '$_jumlahPs',
            onChanged: (v) => setState(() => _jumlahPs = v.round()),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Kunci PIN kasir'),
            subtitle: const Text('Minimal 4 digit saat aplikasi dibuka'),
            value: _pinOn,
            onChanged: (v) => setState(() => _pinOn = v),
          ),
          TextField(
            controller: _pinCtrl,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'PIN', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text('Tarif paket', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...Tariff.paketDefault.keys.map((menit) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextFormField(
                initialValue: (_paket[menit] ?? Tariff.paketDefault[menit]!).toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: Tariff.labelDurasi(menit),
                  prefixText: 'Rp ',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) {
                  _paket[menit] = int.tryParse(v) ?? 0;
                },
              ),
            );
          }),
          TextField(
            controller: _per10Ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Harga per 10 menit (durasi di luar paket)',
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Cadangan data', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _backup,
            icon: const Icon(Icons.share),
            label: const Text('Bagikan file cadangan'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _restore,
            icon: const Icon(Icons.restore),
            label: const Text('Pulihkan dari file'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _simpan,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Simpan pengaturan'),
          ),
        ],
      ),
    );
  }
}
