import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';

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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Gagal memuat foto catatan.');
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
        imageQuality: 75,
        maxWidth: 1600,
        maxHeight: 2000,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      String extractedText = '';
      TextRecognizer? recognizer;
      try {
        recognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final result = await recognizer.processImage(
          InputImage.fromFilePath(picked.path),
        );
        extractedText = result.text.trim();
      } catch (_) {
        // Keep the photo usable even if on-device text recognition fails.
      } finally {
        await recognizer?.close();
      }

      if (!mounted) return;
      final textController = TextEditingController(text: extractedText);
      final shouldSave = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Periksa foto catatan'),
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
                      errorBuilder: (_, __, ___) => const SizedBox(
                        height: 120,
                        child: Center(child: Icon(Icons.broken_image_outlined, size: 40)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Teks hasil baca otomatis bisa keliru, terutama tulisan tangan. Cek dan koreksi sebelum menyimpan. Foto tetap disimpan sebagai referensi.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    minLines: 4,
                    maxLines: 9,
                    decoration: const InputDecoration(
                      labelText: 'Teks catatan (bisa diedit)',
                      hintText: 'Teks yang terbaca dari foto akan muncul di sini...',
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
              label: const Text('Simpan foto'),
            ),
          ],
        ),
      );

      final reviewedText = textController.text.trim();
      textController.dispose();
      if (shouldSave != true || !mounted) return;

      await DatabaseHelper.instance.insertNoteScan(
        tanggal: _dateKey,
        imageBytes: bytes,
        extractedText: reviewedText,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _loadPhotos();
      if (mounted) _showMessage('Foto catatan berhasil disimpan.');
    } catch (e) {
      if (mounted) _showMessage('Foto gagal diproses. Coba foto ulang dengan cahaya yang cukup.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deletePhoto(Map<String, dynamic> photo) async {
    final id = photo['id'] as int?;
    if (id == null) return;
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus foto catatan?'),
        content: const Text('Foto dan teks hasil bacanya akan dihapus dari aplikasi.'),
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  DateFormat('dd MMMM yyyy').format(DateTime.parse(photo['tanggal'] as String)),
                  style: const TextStyle(color: Colors.blueGrey),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: InteractiveViewer(
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 56),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Teks catatan', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(text.isEmpty ? 'Belum ada teks yang terbaca.' : text),
                  ),
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
            onPressed: _pickDate,
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
                  'Foto halaman buku, cek teks yang terbaca, lalu simpan foto sebagai arsip untuk membantu rekap.',
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
              onTap: _pickDate,
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
                  label: const Text('Galeri'),
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
                child: Text('${_photos.length} foto', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
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
                  Text('Belum ada foto untuk tanggal ini', style: TextStyle(fontWeight: FontWeight.bold)),
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
              final preview = text.isEmpty ? 'Belum ada teks yang terbaca.' : text;
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
                                DateFormat('HH:mm').format(DateTime.tryParse(photo['created_at'] as String? ?? '') ?? DateTime.now()),
                                style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                preview,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(height: 1.35),
                              ),
                              const SizedBox(height: 6),
                              const Text('Ketuk untuk melihat foto', style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5))),
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
            'Catatan: hasil baca otomatis hanya membantu membaca tulisan. Tulisan tangan, angka, dan nominal wajib diperiksa ulang sebelum dipakai sebagai data transaksi.',
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
