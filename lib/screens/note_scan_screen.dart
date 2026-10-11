import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';
import '../services/rental_notebook_parser.dart';

class NoteScansScreen extends StatefulWidget {
  const NoteScansScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<NoteScansScreen> createState() => _NoteScansScreenState();
}

class _NoteScansScreenState extends State<NoteScansScreen> {
  final ImagePicker _picker = ImagePicker();
  late DateTime _selectedDate;
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    try {
      final photos = await DatabaseHelper.instance.getNoteScansByDate(_dateKey);
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Gagal memuat foto catatan.');
    }
  }

  List<Map<String, String>> _parseRows(String text) {
    return RentalNotebookParser.parseRows(text);
  }

  List<Map<String, String>> _decodeRows(Map<String, dynamic> photo) {
    try {
      final decoded = jsonDecode(photo['entries_json'] as String? ?? '[]');
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map((entry) {
        return <String, String>{
          'no': entry['no']?.toString() ?? '',
          'nama': entry['nama']?.toString() ?? '',
          'ps': entry['ps']?.toString() ?? '',
          'waktu': entry['waktu']?.toString() ?? '',
          'sewa': entry['sewa']?.toString() ?? '',
          'saldo': entry['saldo']?.toString() ?? '',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      helpText: 'Pilih tanggal catatan',
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedDate = selected);
    await _loadPhotos();
  }

  Future<void> _takePhoto(ImageSource source) async {
    if (_isProcessing) return;

    try {
      setState(() => _isProcessing = true);
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 78,
        maxWidth: 1800,
        maxHeight: 2400,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      var extractedText = '';
      try {
        final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
        try {
          final result = await recognizer.processImage(InputImage.fromFilePath(picked.path));
          extractedText = result.text.trim();
        } finally {
          await recognizer.close();
        }
      } catch (_) {
        // Saving the image remains useful even if OCR fails.
      }

      if (!mounted) return;
      final textController = TextEditingController(text: extractedText);
      var shouldSave = false;
      var reviewedText = '';
      try {
        shouldSave = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Periksa hasil baca foto'),
                content: SizedBox(
                  width: 480,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            bytes,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Format buku: No | Nama | PS | Waktu | Sewa | Saldo. Cocokkan hasil OCR dengan buku asli. Baris yang tidak terbaca bisa diisi manual pada langkah berikutnya.',
                          style: TextStyle(fontSize: 12, height: 1.45),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: textController,
                          minLines: 4,
                          maxLines: 9,
                          decoration: const InputDecoration(
                            labelText: 'Teks hasil baca (bisa dikoreksi)',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Batal'),
                  ),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Simpan foto & rekap'),
                  ),
                ],
              ),
            ) ??
            false;
        reviewedText = textController.text.trim();
      } finally {
        textController.dispose();
      }

      if (!shouldSave || !mounted) return;
      final insertedId = await DatabaseHelper.instance.insertNoteScan(
        tanggal: _dateKey,
        imageBytes: bytes,
        extractedText: reviewedText,
        entriesJson: jsonEncode(_parseRows(reviewedText)),
        createdAt: DateTime.now().toIso8601String(),
      );
      if (!mounted) return;
      await _loadPhotos();
      if (!mounted) return;
      final savedRows = await DatabaseHelper.instance.getNoteScansByDate(_dateKey);
      Map<String, dynamic>? savedPhoto;
      for (final row in savedRows) {
        if (row['id'] == insertedId) {
          savedPhoto = row;
          break;
        }
      }
      if (savedPhoto != null && mounted) {
        _showMessage('Foto tersimpan. Periksa enam kolom rekapnya.');
        await _editRows(savedPhoto);
      }
    } catch (_) {
      if (mounted) _showMessage('Foto gagal diproses. Coba foto ulang dengan cahaya yang cukup.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _editRows(Map<String, dynamic> photo) async {
    final id = photo['id'] as int?;
    if (id == null) return;

    final edited = await Navigator.push<List<Map<String, String>>>(
      context,
      MaterialPageRoute(
        builder: (_) => RentalNotebookRowsEditor(
          date: photo['tanggal'] as String? ?? _dateKey,
          initialRows: _decodeRows(photo),
        ),
      ),
    );
    if (edited == null || !mounted) return;

    await DatabaseHelper.instance.updateNoteScanReview(
      id: id,
      extractedText: photo['extracted_text'] as String? ?? '',
      entriesJson: jsonEncode(edited),
    );
    if (!mounted) return;
    await _loadPhotos();
    if (mounted) _showMessage('Rekap catatan berhasil disimpan.');
  }

  Future<void> _editExtractedText(Map<String, dynamic> photo) async {
    final id = photo['id'] as int?;
    if (id == null) return;
    final controller = TextEditingController(
      text: photo['extracted_text'] as String? ?? '',
    );
    try {
      final edited = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Koreksi teks catatan'),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: controller,
              minLines: 5,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Teks hasil baca',
                alignLabelWithHint: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Simpan koreksi'),
            ),
          ],
        ),
      );
      if (edited == null) return;
      final reviewedText = edited.trim();
      await DatabaseHelper.instance.updateNoteScanReview(
        id: id,
        extractedText: reviewedText,
        entriesJson: jsonEncode(_parseRows(reviewedText)),
      );
      if (!mounted) return;
      await _loadPhotos();
      if (mounted) _showMessage('Teks catatan diperbarui.');
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deletePhoto(Map<String, dynamic> photo) async {
    final id = photo['id'] as int?;
    if (id == null) return;
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus foto catatan?'),
        content: const Text('Foto dan rekap tersimpannya akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (remove != true) return;
    await DatabaseHelper.instance.deleteNoteScan(id);
    await _loadPhotos();
    if (mounted) _showMessage('Foto catatan dihapus.');
  }

  void _showPhoto(Map<String, dynamic> photo) {
    final bytes = photo['image_blob'] as Uint8List;
    final text = (photo['extracted_text'] as String? ?? '').trim();
    final rowCount = _decodeRows(photo).length;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 740),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Foto buku catatan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    DateFormat('dd MMMM yyyy').format(DateTime.parse(photo['tanggal'] as String)),
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 5,
                  child: InteractiveViewer(
                    child: Center(
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 56),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Teks hasil baca', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(text.isEmpty ? 'Belum ada teks yang terbaca.' : text),
                        const SizedBox(height: 8),
                        Text(
                          '$rowCount baris rekap tersimpan',
                          style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _editExtractedText(photo);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Koreksi OCR'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _editRows(photo);
                        },
                        icon: const Icon(Icons.table_chart_outlined),
                        label: const Text('Rekap 6 kolom'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto Catatan'),
        actions: [
          IconButton(
            tooltip: 'Pilih tanggal',
            onPressed: _isProcessing ? null : _pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7773F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.document_scanner_outlined, color: Colors.white, size: 30),
                SizedBox(height: 12),
                Text(
                  'Digitalisasi buku rental',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  'Foto halaman buku, lalu koreksi data dengan kolom No, Nama, PS, Waktu, Sewa, dan Saldo.',
                  style: TextStyle(color: Colors.white, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8E9FF),
                child: Icon(Icons.calendar_today_outlined, color: Color(0xFF4F46E5)),
              ),
              title: const Text('Tanggal catatan', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
              subtitle: Text(displayDate, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _isProcessing ? null : _pickDate,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : () => _takePhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Ambil foto'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : () => _takePhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Pilih galeri'),
                ),
              ),
            ],
          ),
          if (_isProcessing) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 6),
            const Text('Memproses foto dan membaca teks…', textAlign: TextAlign.center),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text('Arsip foto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E9FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_photos.length} foto',
                  style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_photos.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4E7F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.photo_camera_back_outlined, size: 42, color: Colors.blueGrey),
                  SizedBox(height: 10),
                  Text('Belum ada foto pada tanggal ini', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(
                    'Ambil foto atau pilih gambar buku catatan untuk mulai mengarsipkan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey, height: 1.4),
                  ),
                ],
              ),
            )
          else
            ..._photos.map((photo) {
              final bytes = photo['image_blob'] as Uint8List;
              final text = (photo['extracted_text'] as String? ?? '').trim();
              final rowCount = _decodeRows(photo).length;
              final preview = text.isEmpty ? 'Belum ada teks yang terbaca.' : text;
              final created = DateTime.tryParse(photo['created_at'] as String? ?? '');
              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => _showPhoto(photo),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 104,
                        height: 122,
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFE9EAF2),
                            child: Icon(Icons.broken_image_outlined, size: 34),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('HH:mm').format(created ?? DateTime.now()),
                                style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                preview,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(height: 1.35),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$rowCount baris rekap • ketuk untuk membuka',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF4F46E5)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hapus foto',
                        onPressed: () => _deletePhoto(photo),
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 12),
          const Text(
            'OCR tulisan tangan dan angka bisa salah. Rekap ini disimpan sebagai catatan terpisah dan tidak otomatis membuat transaksi rental resmi. Periksa semua kolom sebelum menggunakan data.',
            style: TextStyle(fontSize: 12, color: Colors.blueGrey, height: 1.4),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : () => _takePhoto(ImageSource.camera),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Foto buku'),
      ),
    );
  }
}

class RentalNotebookRowsEditor extends StatefulWidget {
  const RentalNotebookRowsEditor({
    super.key,
    required this.date,
    required this.initialRows,
  });

  final String date;
  final List<Map<String, String>> initialRows;

  @override
  State<RentalNotebookRowsEditor> createState() => _RentalNotebookRowsEditorState();
}

class _RentalNotebookRowsEditorState extends State<RentalNotebookRowsEditor> {
  static const List<(String, String)> _fields = [
    ('no', 'No'),
    ('nama', 'Nama'),
    ('ps', 'PS'),
    ('waktu', 'Waktu'),
    ('sewa', 'Sewa'),
    ('saldo', 'Saldo'),
  ];

  final List<Map<String, TextEditingController>> _rows = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialRows.isEmpty) {
      _addInitialRow();
    } else {
      for (final row in widget.initialRows) {
        _rows.add(_makeControllers(row));
      }
    }
  }

  Map<String, TextEditingController> _makeControllers([Map<String, String>? initial]) {
    return {
      for (final field in _fields)
        field.$1: TextEditingController(text: initial?[field.$1] ?? ''),
    };
  }

  void _addInitialRow() {
    _rows.add(_makeControllers({
      'no': '1',
      'nama': '',
      'ps': '',
      'waktu': '',
      'sewa': '',
      'saldo': '',
    }));
  }

  void _addRow() {
    var highestNumber = 0;
    for (final row in _rows) {
      final number = int.tryParse(row['no']!.text.trim()) ?? 0;
      if (number > highestNumber) highestNumber = number;
    }

    setState(() {
      _rows.add(_makeControllers({
        'no': '${highestNumber + 1}',
        'nama': '',
        'ps': '',
        'waktu': '',
        'sewa': '',
        'saldo': '',
      }));
    });
  }

  void _removeRow(int index) {
    final removed = _rows.removeAt(index);
    for (final controller in removed.values) {
      controller.dispose();
    }
    setState(() {});
  }

  List<Map<String, String>> _collectRows() {
    return _rows.map((row) {
      return <String, String>{
        for (final field in _fields)
          field.$1: row[field.$1]!.text.trim(),
      };
    }).where((row) => row.values.any((value) => value.isNotEmpty)).toList();
  }

  void _save() {
    final rows = _collectRows();
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi setidaknya satu baris rekap terlebih dahulu.')),
      );
      return;
    }
    Navigator.pop(context, rows);
  }

  @override
  void dispose() {
    for (final row in _rows) {
      for (final controller in row.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd MMMM yyyy').format(
      DateTime.tryParse(widget.date) ?? DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Buku Rental'),
        actions: [
          IconButton(
            tooltip: 'Tambah baris',
            onPressed: _addRow,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E9FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Periksa data per baris',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3730A3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(dateLabel, style: const TextStyle(color: Color(0xFF4F46E5))),
                  const SizedBox(height: 8),
                  const Text(
                    'Kolom: No • Nama • PS • Waktu • Sewa • Saldo. OCR hanya perkiraan, jadi cocokkan kembali dengan buku asli. Data ini belum masuk ke transaksi resmi.',
                    style: TextStyle(fontSize: 12, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Baris catatan',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${_collectRows().length} baris',
                  style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: _rows.length,
              itemBuilder: (context, index) {
                final row = _rows[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8E9FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Baris ${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Hapus baris',
                              onPressed: _rows.length == 1 ? null : () => _removeRow(index),
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final fieldWidth = (constraints.maxWidth - 10) / 2;
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final field in _fields)
                                  SizedBox(
                                    width: fieldWidth,
                                    child: TextField(
                                      controller: row[field.$1],
                                      keyboardType: field.$1 == 'no' || field.$1 == 'ps'
                                          ? TextInputType.number
                                          : TextInputType.text,
                                      decoration: InputDecoration(
                                        labelText: field.$2,
                                        hintText: field.$1 == 'waktu' ? 'Mis. 13:00' : null,
                                        isDense: true,
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Simpan rekap catatan'),
        ),
      ),
    );
  }
}
