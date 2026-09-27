import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'tariff.dart';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _kNama = 'nama_warung';
  static const _kWa = 'nomor_wa';
  static const _kPs = 'jumlah_ps';
  static const _kPin = 'pin_kasir';
  static const _kPinOn = 'pin_aktif';
  static const _kPaket = 'tarif_paket';
  static const _kPer10 = 'tarif_per_10';

  late SharedPreferences _prefs;
  bool _ready = false;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _ready = true;
  }

  void _ensure() {
    if (!_ready) {
      throw StateError('SettingsService belum di-load');
    }
  }

  String get namaWarung {
    _ensure();
    return _prefs.getString(_kNama) ?? 'Rental PS';
  }

  Future<void> setNamaWarung(String v) async {
    await _prefs.setString(_kNama, v.trim().isEmpty ? 'Rental PS' : v.trim());
  }

  String get nomorWa {
    _ensure();
    return _prefs.getString(_kWa) ?? '';
  }

  Future<void> setNomorWa(String v) async {
    await _prefs.setString(_kWa, v.trim());
  }

  int get jumlahPs {
    _ensure();
    final n = _prefs.getInt(_kPs) ?? 2;
    return n.clamp(1, 8);
  }

  Future<void> setJumlahPs(int n) async {
    await _prefs.setInt(_kPs, n.clamp(1, 8));
  }

  bool get pinAktif {
    _ensure();
    return _prefs.getBool(_kPinOn) ?? false;
  }

  String get pin {
    _ensure();
    return _prefs.getString(_kPin) ?? '';
  }

  Future<void> setPin({required bool aktif, required String pin}) async {
    await _prefs.setBool(_kPinOn, aktif && pin.trim().length >= 4);
    await _prefs.setString(_kPin, pin.trim());
  }

  bool pinCocok(String input) => input.trim() == pin;

  int get hargaPer10 {
    _ensure();
    return _prefs.getInt(_kPer10) ?? Tariff.hargaPer10Default;
  }

  Future<void> setHargaPer10(int v) async {
    await _prefs.setInt(_kPer10, v < 0 ? 0 : v);
  }

  Map<int, int> get paket {
    _ensure();
    final raw = _prefs.getString(_kPaket);
    if (raw == null || raw.isEmpty) return Map<int, int>.from(Tariff.paketDefault);
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
    } catch (_) {
      return Map<int, int>.from(Tariff.paketDefault);
    }
  }

  Future<void> setPaket(Map<int, int> data) async {
    final encoded = jsonEncode(data.map((k, v) => MapEntry(k.toString(), v)));
    await _prefs.setString(_kPaket, encoded);
  }

  int tarifUntuk(int menit) => Tariff.hitung(menit, paket: paket, hargaPer10: hargaPer10);
}
