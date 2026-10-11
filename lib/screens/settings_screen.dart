import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/backup_service.dart';
import '../services/settings_service.dart';
import '../services/tariff.dart';
import 'units_screen.dart';

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
    final hargaPer10 = int.tryParse(_per10Ctrl.text);
    if (hargaPer10 == null || hargaPer10 < 0 || _paket.values.any((harga) => harga < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarif harus berupa angka nol atau lebih.')),
      );
      return;
    }

    final s = SettingsService.instance;
    await s.setNamaWarung(_namaCtrl.text);
    await s.setNomorWa(_waCtrl.text);
    await s.setJumlahPs(_jumlahPs);
    await s.setPin(aktif: _pinOn, pin: _pinCtrl.text);
    await s.setHargaPer10(hargaPer10);
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

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 9),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _sectionTitle('Profil warung', Icons.storefront_outlined),

          TextField(
            controller: _namaCtrl,
            decoration: const InputDecoration(labelText: 'Nama warung', prefixIcon: Icon(Icons.storefront_outlined)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _waCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor WhatsApp (opsional, 62...)',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Unit dan keamanan', Icons.tune_outlined),
          Card(
            child: ListTile(
              leading: Icon(Icons.sports_esports_outlined, color: Theme.of(context).colorScheme.primary),
              title: const Text('Manajemen Unit PS'),
              subtitle: const Text('Tambah PS3, PS4, atau konsol lain tanpa mengubah kode aplikasi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const UnitsScreen()));
              },
            ),
          ),
          const SizedBox(height: 8),
          Text('Jumlah unit PS lama (kompatibilitas): $_jumlahPs', style: const TextStyle(fontWeight: FontWeight.bold)),

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
            decoration: const InputDecoration(labelText: 'PIN', prefixIcon: Icon(Icons.lock_outline)),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Pengaturan tarif', Icons.payments_outlined),
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
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Cadangan data', Icons.backup_outlined),
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
