import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';
import '../services/rental_notebook_importer.dart';

class NoteScanImportScreen extends StatefulWidget {
  const NoteScanImportScreen({
    super.key,
    required this.noteScanId,
    required this.date,
    required this.rows,
  });

  final int noteScanId;
  final String date;
  final List<Map<String, String>> rows;

  @override
  State<NoteScanImportScreen> createState() => _NoteScanImportScreenState();
}

class _NoteScanImportScreenState extends State<NoteScanImportScreen> {
  late final List<_ImportRowDraft> _drafts;
  List<Map<String, dynamic>> _units = [];
  Set<String> _alreadyImported = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _drafts = widget.rows.map(_ImportRowDraft.fromSource).toList();
    _loadUnitsAndImports();
  }

  Future<void> _loadUnitsAndImports() async {
    final results = await Future.wait([
      DatabaseHelper.instance.getRentalUnits(),
      DatabaseHelper.instance.getImportedNoteFingerprints(widget.noteScanId),
    ]);
    if (!mounted) return;
    final units = results[0] as List<Map<String, dynamic>>;
    final imported = results[1] as Set<String>;
    setState(() {
      _units = units;
      _alreadyImported = imported;
      for (final row in _drafts) {
        row.unitId = _matchUnit(row.source['ps'] ?? '');
        row.alreadyImported = imported.contains(row.fingerprint);
        row.selected = row.isReady && row.unitId != null && !row.alreadyImported;
      }
      _loading = false;
    });
  }

  int? _matchUnit(String sourcePs) {
    final raw = sourcePs.trim().toUpperCase().replaceAll(' ', '');
    if (raw.isEmpty) return null;

    for (final unit in _units) {
      if ((unit['unit_code'] as String? ?? '').toUpperCase().replaceAll(' ', '') == raw) {
        return unit['id'] as int;
      }
    }

    final numeric = RegExp(r'^(?:PS)?(\d+)$').firstMatch(raw);
    if (numeric != null) {
      final number = int.tryParse(numeric.group(1) ?? '');
      for (final unit in _units) {
        if (unit['unit_number'] == number) return unit['id'] as int;
      }
    }

    final sameType = _units.where(
      (unit) => (unit['console_type'] as String? ?? '').toUpperCase() == raw,
    ).toList();
    if (sameType.length == 1) return sameType.single['id'] as int;
    return null;
  }

  int? _unitNumber(int? id) {
    if (id == null) return null;
    for (final unit in _units) {
      if (unit['id'] == id) return unit['unit_number'] as int?;
    }
    return null;
  }

  String _unitLabel(Map<String, dynamic> unit) {
    return '${unit['unit_code']} · ${unit['display_name']}';
  }

  Future<void> _confirmImport() async {
    final selected = _drafts.where((row) => row.selected).toList();
    if (selected.isEmpty) {
      _message('Pilih setidaknya satu baris yang siap diimpor.');
      return;
    }

    final invalid = selected.where((row) => !row.isReady || row.unitId == null).toList();
    if (invalid.isNotEmpty) {
      _message('Lengkapi nama, unit, jam mulai, durasi, dan saldo pada setiap baris yang dipilih.');
      return;
    }

    final duplicateFingerprints = <String>{};
    for (final row in selected) {
      if (!duplicateFingerprints.add(row.fingerprint)) {
        _message('Ada baris sumber yang sama dipilih lebih dari sekali. Periksa kolom No.');
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi impor transaksi'),
        content: Text(
          '${selected.length} baris akan diperiksa terhadap transaksi dan booking yang sudah ada pada ${DateFormat('dd MMM yyyy').format(DateTime.parse(widget.date))}. '
          'Baris yang bentrok atau sudah pernah diimpor akan dilewati, bukan digandakan. Lanjutkan?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Periksa lagi')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Impor transaksi')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final result = await DatabaseHelper.instance.importNoteScanRows(
        noteScanId: widget.noteScanId,
        rows: [
          for (final row in selected)
            {
              'row_fingerprint': row.fingerprint,
              'nama': row.nama.text.trim(),
              'unit_id': row.unitId,
              'ps_nomor': _unitNumber(row.unitId),
              'tanggal': widget.date,
              'waktu_mulai': RentalNotebookImporter.parseStartTime(row.waktu.text)!,
              'durasi_menit': int.parse(row.durasi.text),
              'saldo': RentalNotebookImporter.parseAmount(row.saldo.text),
              'metode_bayar': row.metodeBayar,
            },
        ],
      );
      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (error) {
      if (!mounted) return;
      _message('Impor gagal dan tidak ada perubahan yang disimpan: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    for (final row in _drafts) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = DateTime.tryParse(widget.date) ?? DateTime.now();
    final readyCount = _drafts.where((row) => row.isReady && row.unitId != null && !row.alreadyImported).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Impor ke Catatan Hari')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _units.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Belum ada unit aktif. Tambahkan unit PS lewat Pengaturan → Manajemen Unit, lalu buka impor ini lagi.', textAlign: TextAlign.center),
                  ),
                )
              : _drafts.isEmpty
                  ? const Center(child: Text('Belum ada baris rekap. Koreksi atau isi tabel 6 kolom terlebih dahulu.'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Periksa sebelum masuk transaksi', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              Text(DateFormat('EEEE, dd MMMM yyyy').format(day)),
                              const SizedBox(height: 8),
                              const Text(
                                'Pilih baris yang benar. Waktu diambil dari jam mulai pada kolom Waktu; Sewa menjadi durasi bermain; Saldo menjadi nominal transaksi. Metode bayar tidak tertulis di buku, jadi periksa Cash/Transfer pada tiap baris.',
                                style: TextStyle(height: 1.4),
                              ),
                              const SizedBox(height: 6),
                              Text('$readyCount baris siap diimpor · ${_drafts.where((r) => r.alreadyImported).length} sudah pernah diimpor'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (var i = 0; i < _drafts.length; i++) _buildRowCard(i, _drafts[i]),
                      ],
                    ),
      bottomNavigationBar: _loading || _units.isEmpty || _drafts.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: _saving ? null : _confirmImport,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.playlist_add_check_circle_outlined),
                label: Text(_saving ? 'Mengimpor…' : 'Konfirmasi & Masukkan ke Catatan Hari'),
              ),
            ),
    );
  }

  Widget _buildRowCard(int index, _ImportRowDraft row) {
    final ready = row.isReady && row.unitId != null;
    final disabled = row.alreadyImported;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: row.selected,
                  onChanged: disabled || _saving ? null : (value) => setState(() => row.selected = value ?? false),
                ),
                Expanded(
                  child: Text(
                    'Baris ${row.source['no']?.isNotEmpty == true ? row.source['no'] : index + 1} · ${row.nama.text.isEmpty ? 'Nama belum diisi' : row.nama.text}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (disabled)
                  const Chip(label: Text('Sudah diimpor'))
                else if (ready)
                  const Icon(Icons.check_circle_outline, color: Color(0xFF15803D))
                else
                  const Tooltip(message: 'Periksa data yang belum terbaca', child: Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309))),
              ],
            ),
            if (disabled)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Baris ini sudah pernah dimasukkan dari foto ini dan tidak bisa dipilih lagi.', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
              ),
            TextField(
              controller: row.nama,
              enabled: !disabled && !_saving,
              decoration: const InputDecoration(labelText: 'Nama penyewa', prefixIcon: Icon(Icons.person_outline), isDense: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: row.unitId,
              decoration: const InputDecoration(labelText: 'Unit PS', prefixIcon: Icon(Icons.sports_esports_outlined), isDense: true),
              items: _units.map((unit) => DropdownMenuItem<int>(value: unit['id'] as int, child: Text(_unitLabel(unit)))).toList(),
              onChanged: disabled || _saving ? null : (value) => setState(() => row.unitId = value),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.waktu,
                    enabled: !disabled && !_saving,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(labelText: 'Jam mulai', hintText: '13:00', isDense: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: row.durasi,
                    enabled: !disabled && !_saving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Durasi (menit)', hintText: '60', isDense: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: row.saldo,
                    enabled: !disabled && !_saving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Saldo / nominal (Rp)', isDense: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: row.metodeBayar,
                    decoration: const InputDecoration(labelText: 'Bayar', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                    ],
                    onChanged: disabled || _saving ? null : (value) => setState(() => row.metodeBayar = value ?? 'Cash'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              disabled ? 'Tidak akan dibuat ulang.' : ready ? 'Data wajib terbaca. Tetap cocokkan dengan foto asli.' : 'Ada data belum jelas. Lengkapi atau perbaiki sebelum memilih baris ini.',
              style: TextStyle(fontSize: 12, color: disabled ? Colors.blueGrey : ready ? const Color(0xFF15803D) : const Color(0xFFB45309)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportRowDraft {
  _ImportRowDraft({
    required this.source,
    required this.nama,
    required this.waktu,
    required this.durasi,
    required this.saldo,
    required this.fingerprint,
    required this.metodeBayar,
  });

  final Map<String, String> source;
  final TextEditingController nama;
  final TextEditingController waktu;
  final TextEditingController durasi;
  final TextEditingController saldo;
  final String fingerprint;
  String metodeBayar;
  int? unitId;
  bool selected = false;
  bool alreadyImported = false;

  bool get isReady {
    return nama.text.trim().isNotEmpty &&
        RentalNotebookImporter.parseStartTime(waktu.text) != null &&
        (int.tryParse(durasi.text.trim()) ?? 0) > 0 &&
        (RentalNotebookImporter.parseAmount(saldo.text) ?? 0) > 0;
  }

  factory _ImportRowDraft.fromSource(Map<String, String> source) {
    final duration = RentalNotebookImporter.parseDurationMinutes(source['sewa'] ?? '');
    final start = RentalNotebookImporter.parseStartTime(source['waktu'] ?? '');
    final amount = RentalNotebookImporter.parseAmount(source['saldo'] ?? '');
    return _ImportRowDraft(
      source: Map<String, String>.from(source),
      nama: TextEditingController(text: source['nama'] ?? ''),
      waktu: TextEditingController(text: start ?? source['waktu'] ?? ''),
      durasi: TextEditingController(text: duration?.toString() ?? ''),
      saldo: TextEditingController(text: amount?.toString() ?? ''),
      fingerprint: RentalNotebookImporter.fingerprint(source),
      metodeBayar: 'Cash',
    );
  }

  void dispose() {
    nama.dispose();
    waktu.dispose();
    durasi.dispose();
    saldo.dispose();
  }
}
