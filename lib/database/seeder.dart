import 'db_helper.dart';
import '../models/rental_model.dart';
import '../models/expense_model.dart';
import '../models/snack_model.dart';

class DatabaseSeeder {
  static Future<void> seedHistoryData() async {
    final db = DatabaseHelper.instance;
    final database = await db.database;

    // Bersihkan tabel agar re-seed bersih total dan tidak ada duplikat
    await database.delete('rentals');
    await database.delete('expenses');
    await database.delete('snack_orders');

    final List<Rental> rentals = [
      // ==========================================
      // MINGGU 1: 16 - 23 AGUSTUS 2026
      // ==========================================
      // --- 16 Ags 2026 (Minggu) - Rp 64.000 ---
      Rental(nama: 'Zain', psNomor: 1, waktuMulai: '09:00', waktuSelesai: '09:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-16'),
      Rental(nama: 'Adnan', psNomor: 2, waktuMulai: '09:00', waktuSelesai: '09:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-16'),
      Rental(nama: 'Faqih', psNomor: 2, waktuMulai: '12:30', waktuSelesai: '13:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-16'),
      Rental(nama: 'Akbar', psNomor: 1, waktuMulai: '12:30', waktuSelesai: '13:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-16'),
      Rental(nama: 'Zain', psNomor: 1, waktuMulai: '13:30', waktuSelesai: '14:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-16'),
      Rental(nama: 'Adnan', psNomor: 2, waktuMulai: '14:00', waktuSelesai: '14:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-16'),
      Rental(nama: 'Faqih', psNomor: 1, waktuMulai: '15:00', waktuSelesai: '16:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-16'),
      Rental(nama: 'Akbar dan Teman', psNomor: 2, waktuMulai: '16:00', waktuSelesai: '17:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-16'),
      Rental(nama: 'Faqih', psNomor: 1, waktuMulai: '18:00', waktuSelesai: '19:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-16'),
      Rental(nama: 'Adnan', psNomor: 1, waktuMulai: '20:00', waktuSelesai: '21:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-16'),
      Rental(nama: 'Faqih', psNomor: 2, waktuMulai: '20:25', waktuSelesai: '22:25', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-08-16'),
      Rental(nama: 'Akbar', psNomor: 1, waktuMulai: '22:00', waktuSelesai: '23:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-16'),
      Rental(nama: 'Palik', psNomor: 1, waktuMulai: '23:00', waktuSelesai: '24:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-16'),

      // --- 18 Ags 2026 (Selasa) - Rp 66.000 ---
      Rental(nama: 'Malik', psNomor: 2, waktuMulai: '09:45', waktuSelesai: '10:45', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-18'),
      Rental(nama: 'Aldi', psNomor: 2, waktuMulai: '11:30', waktuSelesai: '12:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-18'),
      Rental(nama: 'Faizi', psNomor: 1, waktuMulai: '11:30', waktuSelesai: '12:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-18'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '13:00', waktuSelesai: '14:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-18'),
      Rental(nama: 'Adnan', psNomor: 1, waktuMulai: '13:00', waktuSelesai: '14:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-18'),
      Rental(nama: 'Fakih', psNomor: 2, waktuMulai: '15:00', waktuSelesai: '16:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-18'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '15:00', waktuSelesai: '16:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-18'),
      Rental(nama: 'Habibi', psNomor: 1, waktuMulai: '14:00', waktuSelesai: '16:00', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-08-18'),
      Rental(nama: 'Azril', psNomor: 2, waktuMulai: '16:00', waktuSelesai: '17:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-18'),
      Rental(nama: 'Malik', psNomor: 1, waktuMulai: '16:00', waktuSelesai: '17:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-18'),
      Rental(nama: 'Ovan', psNomor: 1, waktuMulai: '17:00', waktuSelesai: '17:40', durasiMenit: 40, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-18'),
      Rental(nama: 'Afnan', psNomor: 1, waktuMulai: '18:00', waktuSelesai: '18:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-18'),
      Rental(nama: 'Zain', psNomor: 2, waktuMulai: '18:00', waktuSelesai: '18:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-18'),

      // --- 19 Ags 2026 (Rabu) - Rp 48.500 ---
      Rental(nama: 'Faizi', psNomor: 2, waktuMulai: '13:00', waktuSelesai: '14:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-19'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '13:00', waktuSelesai: '13:20', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-08-19'),
      Rental(nama: 'Faqih', psNomor: 2, waktuMulai: '14:00', waktuSelesai: '15:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-19'),
      Rental(nama: 'Akbar', psNomor: 1, waktuMulai: '14:00', waktuSelesai: '15:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-19'),
      Rental(nama: 'Manes', psNomor: 2, waktuMulai: '15:00', waktuSelesai: '16:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-19'),
      Rental(nama: 'Aldi', psNomor: 1, waktuMulai: '15:00', waktuSelesai: '16:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-19'),
      Rental(nama: 'Tito', psNomor: 2, waktuMulai: '16:00', waktuSelesai: '17:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-19'),
      Rental(nama: 'Aldi', psNomor: 1, waktuMulai: '16:00', waktuSelesai: '16:20', durasiMenit: 20, saldo: 2500, metodeBayar: 'Cash', tanggal: '2026-08-19'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '16:30', waktuSelesai: '17:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-19'),
      Rental(nama: 'Baim', psNomor: 2, waktuMulai: '17:00', waktuSelesai: '18:00', durasiMenit: 60, saldo: 6000, metodeBayar: 'Cash', tanggal: '2026-08-19'),
      Rental(nama: 'Abnan', psNomor: 2, waktuMulai: '18:00', waktuSelesai: '18:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-19'),

      // --- 20 Ags 2026 (Kamis) - Rp 58.000 ---
      Rental(nama: 'Baim', psNomor: 2, waktuMulai: '10:00', waktuSelesai: '10:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-20'),
      Rental(nama: 'Malik New', psNomor: 1, waktuMulai: '10:00', waktuSelesai: '11:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-20'),
      Rental(nama: 'Akbar dan Teman', psNomor: 2, waktuMulai: '11:00', waktuSelesai: '12:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-20'),
      Rental(nama: 'Aldi', psNomor: 1, waktuMulai: '11:00', waktuSelesai: '12:00', durasiMenit: 60, saldo: 4000, metodeBayar: 'Cash', tanggal: '2026-08-20'),
      Rental(nama: 'Aurora', psNomor: 1, waktuMulai: '12:00', waktuSelesai: '13:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-20'),
      Rental(nama: 'Akbar/Rifa', psNomor: 2, waktuMulai: '12:00', waktuSelesai: '13:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-20'),
      Rental(nama: 'Ali', psNomor: 1, waktuMulai: '13:00', waktuSelesai: '14:00', durasiMenit: 60, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-20'),
      Rental(nama: 'Fathir', psNomor: 2, waktuMulai: '13:00', waktuSelesai: '14:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-20'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '14:00', waktuSelesai: '15:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-20'),
      Rental(nama: 'Afnan', psNomor: 2, waktuMulai: '14:00', waktuSelesai: '14:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-20'),
      Rental(nama: 'Zian', psNomor: 1, waktuMulai: '15:00', waktuSelesai: '16:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-20'),
      Rental(nama: 'Ari', psNomor: 2, waktuMulai: '15:00', waktuSelesai: '16:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-20'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '16:00', waktuSelesai: '16:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-20'),
      Rental(nama: 'Penyewa 14', psNomor: 1, waktuMulai: '16:30', waktuSelesai: '17:00', durasiMenit: 30, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-08-20'),

      // --- 21 Ags 2026 (Jumat) - Rp 113.000 ---
      Rental(nama: 'Baim', psNomor: 1, waktuMulai: '09:00', waktuSelesai: '10:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Teman Baim', psNomor: 2, waktuMulai: '09:00', waktuSelesai: '10:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Giant', psNomor: 2, waktuMulai: '10:00', waktuSelesai: '11:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Rifa', psNomor: 1, waktuMulai: '10:00', waktuSelesai: '13:00', durasiMenit: 180, saldo: 15000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '11:00', waktuSelesai: '12:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Kocan / Fat', psNomor: 1, waktuMulai: '13:00', waktuSelesai: '15:00', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Aldi', psNomor: 2, waktuMulai: '13:00', waktuSelesai: '16:00', durasiMenit: 180, saldo: 15000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Kocan Seragam Pib', psNomor: 1, waktuMulai: '15:00', waktuSelesai: '16:20', durasiMenit: 80, saldo: 7000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Faqih', psNomor: 1, waktuMulai: '16:30', waktuSelesai: '17:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Irfan', psNomor: 2, waktuMulai: '16:30', waktuSelesai: '17:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '17:30', waktuSelesai: '18:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Dofa', psNomor: 2, waktuMulai: '17:30', waktuSelesai: '18:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Fatih', psNomor: 1, waktuMulai: '18:30', waktuSelesai: '19:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Zain', psNomor: 1, waktuMulai: '19:30', waktuSelesai: '20:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Malik', psNomor: 2, waktuMulai: '19:30', waktuSelesai: '20:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '20:30', waktuSelesai: '21:00', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Afnan', psNomor: 1, waktuMulai: '21:00', waktuSelesai: '21:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Idam', psNomor: 1, waktuMulai: '21:30', waktuSelesai: '22:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Ari', psNomor: 1, waktuMulai: '22:30', waktuSelesai: '23:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-21'),
      Rental(nama: 'Ari', psNomor: 1, waktuMulai: '23:30', waktuSelesai: '23:50', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-08-21'),

      // --- 22 Ags 2026 (Sabtu) - Rp 126.000 ---
      Rental(nama: 'Malik', psNomor: 2, waktuMulai: '08:00', waktuSelesai: '09:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Farid', psNomor: 1, waktuMulai: '09:00', waktuSelesai: '09:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Adnan', psNomor: 2, waktuMulai: '09:15', waktuSelesai: '10:45', durasiMenit: 90, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '09:30', waktuSelesai: '10:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Baim', psNomor: 2, waktuMulai: '10:45', waktuSelesai: '11:45', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Aldi', psNomor: 2, waktuMulai: '11:00', waktuSelesai: '12:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Alpat / Zang', psNomor: 2, waktuMulai: '11:30', waktuSelesai: '13:30', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Manes', psNomor: 1, waktuMulai: '13:00', waktuSelesai: '15:00', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Davin', psNomor: 1, waktuMulai: '15:00', waktuSelesai: '16:30', durasiMenit: 90, saldo: 8000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Malik', psNomor: 2, waktuMulai: '14:30', waktuSelesai: '15:00', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'David', psNomor: 2, waktuMulai: '15:00', waktuSelesai: '15:45', durasiMenit: 45, saldo: 4000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '15:45', waktuSelesai: '16:45', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Diandra', psNomor: 1, waktuMulai: '16:30', waktuSelesai: '17:00', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Gibran', psNomor: 1, waktuMulai: '17:00', waktuSelesai: '17:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '16:45', waktuSelesai: '17:15', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Afnan', psNomor: 1, waktuMulai: '17:30', waktuSelesai: '18:00', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Repa', psNomor: 1, waktuMulai: '18:20', waktuSelesai: '19:20', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Zain', psNomor: 2, waktuMulai: '18:30', waktuSelesai: '19:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Adnan', psNomor: 2, waktuMulai: '19:30', waktuSelesai: '20:00', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '19:30', waktuSelesai: '20:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Bintang / Denis', psNomor: 1, waktuMulai: '20:30', waktuSelesai: '21:30', durasiMenit: 60, saldo: 8000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Giandra', psNomor: 2, waktuMulai: '20:00', waktuSelesai: '20:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Ari', psNomor: 1, waktuMulai: '21:30', waktuSelesai: '23:30', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Ari', psNomor: 2, waktuMulai: '23:00', waktuSelesai: '23:20', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Efan', psNomor: 2, waktuMulai: '23:00', waktuSelesai: '24:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-22'),
      Rental(nama: 'Efan', psNomor: 1, waktuMulai: '23:30', waktuSelesai: '24:00', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-22'),

      // --- 23 Ags 2026 (Minggu) - Rp 63.000 ---
      Rental(nama: 'Denis', psNomor: 1, waktuMulai: '10:00', waktuSelesai: '11:20', durasiMenit: 80, saldo: 7000, metodeBayar: 'Cash', tanggal: '2026-08-23'),
      Rental(nama: 'Fikri', psNomor: 2, waktuMulai: '11:00', waktuSelesai: '12:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-23'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '12:00', waktuSelesai: '13:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-23'),
      Rental(nama: 'Akbar', psNomor: 1, waktuMulai: '13:00', waktuSelesai: '14:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-23'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '13:00', waktuSelesai: '14:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-23'),
      Rental(nama: 'Idam', psNomor: 1, waktuMulai: '14:00', waktuSelesai: '15:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-23'),
      Rental(nama: 'Denis', psNomor: 1, waktuMulai: '15:00', waktuSelesai: '16:00', durasiMenit: 60, saldo: 8000, metodeBayar: 'Cash', tanggal: '2026-08-23'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '16:00', waktuSelesai: '17:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-23'),
      Rental(nama: 'Adnan', psNomor: 1, waktuMulai: '17:00', waktuSelesai: '17:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-23'),
      Rental(nama: 'Azril', psNomor: 2, waktuMulai: '18:00', waktuSelesai: '19:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-23'),
      Rental(nama: 'Zain', psNomor: 2, waktuMulai: '19:00', waktuSelesai: '20:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-23'),
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '19:00', waktuSelesai: '20:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-23'),
      Rental(nama: 'Kholfi', psNomor: 1, waktuMulai: '20:00', waktuSelesai: '20:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-23'),

      // ==========================================
      // MINGGU 2: 24 - 30 AGUSTUS 2026
      // ==========================================
      // --- 24 Ags 2026 (Senin) - Rp 90.000 ---
      Rental(nama: 'Malik', psNomor: 1, waktuMulai: '08:00', waktuSelesai: '08:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Abnan', psNomor: 1, waktuMulai: '08:30', waktuSelesai: '09:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Apiz', psNomor: 1, waktuMulai: '09:30', waktuSelesai: '10:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Baim', psNomor: 2, waktuMulai: '10:00', waktuSelesai: '11:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Kafi', psNomor: 1, waktuMulai: '11:00', waktuSelesai: '12:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Alinza', psNomor: 2, waktuMulai: '12:00', waktuSelesai: '13:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Eza', psNomor: 2, waktuMulai: '13:00', waktuSelesai: '13:20', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '13:30', waktuSelesai: '14:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Akbar', psNomor: 1, waktuMulai: '14:30', waktuSelesai: '15:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Ripa', psNomor: 2, waktuMulai: '14:30', waktuSelesai: '15:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Aldi', psNomor: 1, waktuMulai: '15:30', waktuSelesai: '16:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Faizi', psNomor: 1, waktuMulai: '16:30', waktuSelesai: '17:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Kafi', psNomor: 1, waktuMulai: '17:30', waktuSelesai: '19:30', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '18:00', waktuSelesai: '19:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Adnan', psNomor: 1, waktuMulai: '19:30', waktuSelesai: '20:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Ari', psNomor: 2, waktuMulai: '19:30', waktuSelesai: '21:30', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-08-24'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '20:30', waktuSelesai: '21:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-24'),

      // --- 25 Ags 2026 (Selasa) - Rp 61.000 ---
      Rental(nama: 'Gibran', psNomor: 2, waktuMulai: '09:00', waktuSelesai: '10:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-25'),
      Rental(nama: 'Ipan', psNomor: 1, waktuMulai: '10:00', waktuSelesai: '12:00', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-08-25'),
      Rental(nama: 'Ari', psNomor: 2, waktuMulai: '10:00', waktuSelesai: '10:20', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-08-25'),
      Rental(nama: 'Panji', psNomor: 2, waktuMulai: '10:20', waktuSelesai: '10:40', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-08-25'),
      Rental(nama: 'Akbar', psNomor: 2, waktuMulai: '11:00', waktuSelesai: '12:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-25'),
      Rental(nama: 'Fauzan', psNomor: 1, waktuMulai: '12:00', waktuSelesai: '13:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-25'),
      Rental(nama: 'Kopi', psNomor: 2, waktuMulai: '12:00', waktuSelesai: '13:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-25'),
      Rental(nama: 'Abnan', psNomor: 2, waktuMulai: '13:00', waktuSelesai: '13:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-25'),
      Rental(nama: 'Malik', psNomor: 1, waktuMulai: '13:30', waktuSelesai: '14:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-25'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '15:15', waktuSelesai: '15:45', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-25'),
      Rental(nama: 'Zain', psNomor: 2, waktuMulai: '16:00', waktuSelesai: '17:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-25'),
      Rental(nama: 'Ari', psNomor: 1, waktuMulai: '17:00', waktuSelesai: '18:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-25'),
      Rental(nama: 'Ari', psNomor: 1, waktuMulai: '18:00', waktuSelesai: '18:20', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-08-25'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '18:30', waktuSelesai: '19:30', durasiMenit: 60, saldo: 4000, metodeBayar: 'Cash', tanggal: '2026-08-25'),

      // --- 26 Ags 2026 (Rabu) - Rp 66.000 ---
      Rental(nama: 'Malik 2', psNomor: 1, waktuMulai: '09:00', waktuSelesai: '10:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-26'),
      Rental(nama: 'Aldi', psNomor: 2, waktuMulai: '10:00', waktuSelesai: '11:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-26'),
      Rental(nama: 'Akbar', psNomor: 1, waktuMulai: '11:00', waktuSelesai: '12:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-26'),
      Rental(nama: 'Azril', psNomor: 2, waktuMulai: '11:00', waktuSelesai: '11:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-26'),
      Rental(nama: 'Eza', psNomor: 2, waktuMulai: '12:00', waktuSelesai: '13:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-26'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '13:00', waktuSelesai: '14:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-26'),
      Rental(nama: 'Panji', psNomor: 2, waktuMulai: '13:00', waktuSelesai: '14:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-26'),
      Rental(nama: 'Kafi', psNomor: 1, waktuMulai: '14:00', waktuSelesai: '15:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-26'),
      Rental(nama: 'Adnan', psNomor: 2, waktuMulai: '15:00', waktuSelesai: '15:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-26'),
      Rental(nama: 'Panji', psNomor: 2, waktuMulai: '16:00', waktuSelesai: '17:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-26'),
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '16:00', waktuSelesai: '17:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-26'),
      Rental(nama: 'Ripa', psNomor: 2, waktuMulai: '17:00', waktuSelesai: '18:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-26'),
      Rental(nama: 'Gibran', psNomor: 1, waktuMulai: '18:00', waktuSelesai: '19:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-26'),
      Rental(nama: 'Abnan', psNomor: 2, waktuMulai: '19:00', waktuSelesai: '19:30', durasiMenit: 30, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-26'),

      // --- 27 Ags 2026 (Kamis) - Rp 70.000 ---
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '10:00', waktuSelesai: '11:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Ripa', psNomor: 2, waktuMulai: '11:00', waktuSelesai: '12:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Ale', psNomor: 1, waktuMulai: '12:00', waktuSelesai: '12:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Ale', psNomor: 2, waktuMulai: '12:30', waktuSelesai: '13:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '13:00', waktuSelesai: '15:00', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Akbar', psNomor: 2, waktuMulai: '14:00', waktuSelesai: '14:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '14:40', waktuSelesai: '15:40', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Ajril', psNomor: 2, waktuMulai: '15:45', waktuSelesai: '16:45', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Ale', psNomor: 1, waktuMulai: '16:35', waktuSelesai: '17:05', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '17:00', waktuSelesai: '18:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Kafi', psNomor: 1, waktuMulai: '17:30', waktuSelesai: '18:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '18:30', waktuSelesai: '19:00', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Faizi', psNomor: 1, waktuMulai: '18:45', waktuSelesai: '19:45', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Afnan', psNomor: 2, waktuMulai: '19:35', waktuSelesai: '20:35', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Faizi', psNomor: 1, waktuMulai: '19:50', waktuSelesai: '20:50', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Eza', psNomor: 2, waktuMulai: '20:35', waktuSelesai: '20:55', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Faizi', psNomor: 1, waktuMulai: '20:50', waktuSelesai: '21:20', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-27'),
      Rental(nama: 'Azril', psNomor: 2, waktuMulai: '21:30', waktuSelesai: '22:00', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-27'),

      // --- 28 Ags 2026 (Jumat) - Rp 40.000 ---
      Rental(nama: 'Faizi', psNomor: 2, waktuMulai: '13:00', waktuSelesai: '14:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-28'),
      Rental(nama: 'Eza', psNomor: 2, waktuMulai: '14:00', waktuSelesai: '15:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-28'),
      Rental(nama: 'Ari', psNomor: 1, waktuMulai: '14:00', waktuSelesai: '15:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-28'),
      Rental(nama: 'Ripa', psNomor: 2, waktuMulai: '14:51', waktuSelesai: '15:51', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-28'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '15:15', waktuSelesai: '16:15', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-28'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '16:15', waktuSelesai: '17:15', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-28'),
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '18:30', waktuSelesai: '19:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-28'),
      Rental(nama: 'Ari', psNomor: 1, waktuMulai: '19:30', waktuSelesai: '20:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-28'),

      // --- 29 Ags 2026 (Sabtu) - Rp 104.000 ---
      Rental(nama: 'Malik', psNomor: 2, waktuMulai: '09:00', waktuSelesai: '10:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-29'),
      Rental(nama: 'Abnan', psNomor: 1, waktuMulai: '10:00', waktuSelesai: '10:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-29'),
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '10:30', waktuSelesai: '14:30', durasiMenit: 240, saldo: 20000, metodeBayar: 'Cash', tanggal: '2026-08-29'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '13:00', waktuSelesai: '14:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-29'),
      Rental(nama: 'Sando', psNomor: 2, waktuMulai: '14:00', waktuSelesai: '14:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-29'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '14:26', waktuSelesai: '15:26', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-29'),
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '15:30', waktuSelesai: '18:30', durasiMenit: 180, saldo: 15000, metodeBayar: 'Cash', tanggal: '2026-08-29'),
      Rental(nama: 'Eza', psNomor: 2, waktuMulai: '15:30', waktuSelesai: '16:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-29'),
      Rental(nama: 'Faizi', psNomor: 2, waktuMulai: '16:30', waktuSelesai: '19:30', durasiMenit: 180, saldo: 15000, metodeBayar: 'Cash', tanggal: '2026-08-29'),
      Rental(nama: 'Ale', psNomor: 1, waktuMulai: '18:30', waktuSelesai: '19:00', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-29'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '19:00', waktuSelesai: '20:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-29'),
      Rental(nama: 'Devano', psNomor: 2, waktuMulai: '19:30', waktuSelesai: '20:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-29'),
      Rental(nama: 'Eza', psNomor: 2, waktuMulai: '20:30', waktuSelesai: '21:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-29'),
      Rental(nama: 'Alal', psNomor: 2, waktuMulai: '21:30', waktuSelesai: '23:30', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-08-29'),

      // --- 30 Ags 2026 (Minggu) - Rp 104.000 ---
      Rental(nama: 'Ale', psNomor: 2, waktuMulai: '07:00', waktuSelesai: '08:00', durasiMenit: 60, saldo: 8000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Ale', psNomor: 1, waktuMulai: '09:00', waktuSelesai: '09:40', durasiMenit: 40, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Devano', psNomor: 2, waktuMulai: '09:00', waktuSelesai: '10:00', durasiMenit: 60, saldo: 8000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Abnan', psNomor: 1, waktuMulai: '15:00', waktuSelesai: '15:30', durasiMenit: 30, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Tio', psNomor: 1, waktuMulai: '17:00', waktuSelesai: '18:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Sandro', psNomor: 2, waktuMulai: '14:30', waktuSelesai: '15:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Ale', psNomor: 2, waktuMulai: '15:30', waktuSelesai: '16:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '15:00', waktuSelesai: '16:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Tio', psNomor: 2, waktuMulai: '16:00', waktuSelesai: '16:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Baim', psNomor: 2, waktuMulai: '17:00', waktuSelesai: '17:30', durasiMenit: 30, saldo: 7000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '16:00', waktuSelesai: '17:00', durasiMenit: 60, saldo: 15000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Abnan', psNomor: 1, waktuMulai: '17:00', waktuSelesai: '18:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Azril', psNomor: 2, waktuMulai: '17:30', waktuSelesai: '18:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '18:30', waktuSelesai: '19:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Tio', psNomor: 1, waktuMulai: '18:00', waktuSelesai: '18:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Devano', psNomor: 1, waktuMulai: '18:30', waktuSelesai: '19:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Kafi', psNomor: 1, waktuMulai: '19:30', waktuSelesai: '20:00', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Ale', psNomor: 2, waktuMulai: '19:30', waktuSelesai: '20:00', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '20:00', waktuSelesai: '21:00', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '21:00', waktuSelesai: '22:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-30'),
      Rental(nama: 'Tio', psNomor: 1, waktuMulai: '21:00', waktuSelesai: '22:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-30'),

      // ==========================================
      // MINGGU 3: 31 AGUSTUS - 6 SEPTEMBER 2026
      // ==========================================
      // --- 31 Ags 2026 (Senin) - Rp 82.000 ---
      Rental(nama: 'Devano', psNomor: 1, waktuMulai: '11:00', waktuSelesai: '13:00', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Ari', psNomor: 2, waktuMulai: '13:00', waktuSelesai: '14:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '13:00', waktuSelesai: '15:00', durasiMenit: 120, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Eza', psNomor: 1, waktuMulai: '14:00', waktuSelesai: '15:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Kafi', psNomor: 2, waktuMulai: '15:00', waktuSelesai: '16:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Tio', psNomor: 1, waktuMulai: '16:00', waktuSelesai: '16:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Faizi', psNomor: 1, waktuMulai: '16:30', waktuSelesai: '17:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Ripa', psNomor: 2, waktuMulai: '16:00', waktuSelesai: '19:00', durasiMenit: 180, saldo: 15000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Faizi', psNomor: 1, waktuMulai: '16:20', waktuSelesai: '17:20', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '18:20', waktuSelesai: '19:20', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Tio', psNomor: 2, waktuMulai: '18:15', waktuSelesai: '18:45', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Devano', psNomor: 1, waktuMulai: '18:15', waktuSelesai: '19:15', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Ale', psNomor: 1, waktuMulai: '18:47', waktuSelesai: '19:47', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Azril', psNomor: 2, waktuMulai: '19:00', waktuSelesai: '19:20', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Ale', psNomor: 1, waktuMulai: '19:47', waktuSelesai: '20:17', durasiMenit: 30, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Abnan', psNomor: 1, waktuMulai: '20:00', waktuSelesai: '20:20', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Ari', psNomor: 1, waktuMulai: '20:20', waktuSelesai: '21:20', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-08-31'),
      Rental(nama: 'Ari', psNomor: 1, waktuMulai: '21:20', waktuSelesai: '21:40', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-08-31'),

      // --- 1 Sep 2026 (Selasa) - Rp 82.000 ---
      Rental(nama: 'Tio', psNomor: 1, waktuMulai: '10:10', waktuSelesai: '11:00', durasiMenit: 50, saldo: 4000, metodeBayar: 'Cash', tanggal: '2026-09-01'),
      Rental(nama: 'Devano', psNomor: 1, waktuMulai: '10:55', waktuSelesai: '12:55', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-09-01'),
      Rental(nama: 'Akbar', psNomor: 2, waktuMulai: '10:40', waktuSelesai: '11:40', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-01'),
      Rental(nama: 'Tio', psNomor: 1, waktuMulai: '13:00', waktuSelesai: '13:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-01'),
      Rental(nama: 'Azril', psNomor: 2, waktuMulai: '11:45', waktuSelesai: '12:45', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-01'),
      Rental(nama: 'Ale', psNomor: 2, waktuMulai: '12:50', waktuSelesai: '13:20', durasiMenit: 30, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-01'),
      Rental(nama: 'Devano', psNomor: 1, waktuMulai: '13:30', waktuSelesai: '14:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-01'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '14:40', waktuSelesai: '15:40', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-01'),
      Rental(nama: 'Ari', psNomor: 2, waktuMulai: '15:40', waktuSelesai: '16:00', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-09-01'),
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '15:50', waktuSelesai: '18:50', durasiMenit: 180, saldo: 15000, metodeBayar: 'Cash', tanggal: '2026-09-01'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '16:20', waktuSelesai: '17:20', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-01'),
      Rental(nama: 'Ale', psNomor: 1, waktuMulai: '16:00', waktuSelesai: '17:00', durasiMenit: 60, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-09-01'),
      Rental(nama: 'Tio', psNomor: 2, waktuMulai: '17:20', waktuSelesai: '18:00', durasiMenit: 40, saldo: 4000, metodeBayar: 'Cash', tanggal: '2026-09-01'),
      Rental(nama: 'Abnan', psNomor: 2, waktuMulai: '18:00', waktuSelesai: '18:20', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-09-01'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '19:55', waktuSelesai: '20:55', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-01'),
      Rental(nama: 'Ari', psNomor: 1, waktuMulai: '20:30', waktuSelesai: '21:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-01'),

      // --- 2 Sep 2026 (Rabu) - Rp 64.000 ---
      Rental(nama: 'Malik', psNomor: 2, waktuMulai: '09:10', waktuSelesai: '10:10', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-02'),
      Rental(nama: 'Abnan', psNomor: 1, waktuMulai: '10:30', waktuSelesai: '12:30', durasiMenit: 120, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-02'),
      Rental(nama: 'Tio', psNomor: 2, waktuMulai: '11:00', waktuSelesai: '12:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-02'),
      Rental(nama: 'Azril', psNomor: 2, waktuMulai: '12:50', waktuSelesai: '13:50', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-02'),
      Rental(nama: 'Akbar', psNomor: 1, waktuMulai: '12:50', waktuSelesai: '13:50', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-02'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '13:50', waktuSelesai: '14:50', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-02'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '15:00', waktuSelesai: '15:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-02'),
      Rental(nama: 'Ripa', psNomor: 2, waktuMulai: '15:40', waktuSelesai: '16:40', durasiMenit: 60, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-09-02'),
      Rental(nama: 'Devano', psNomor: 1, waktuMulai: '16:45', waktuSelesai: '17:45', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-02'),
      Rental(nama: 'Tio', psNomor: 2, waktuMulai: '16:45', waktuSelesai: '17:15', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-02'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '17:15', waktuSelesai: '18:25', durasiMenit: 70, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-02'),
      Rental(nama: 'Ale', psNomor: 1, waktuMulai: '18:00', waktuSelesai: '18:40', durasiMenit: 40, saldo: 4000, metodeBayar: 'Cash', tanggal: '2026-09-02'),
      Rental(nama: 'Tio', psNomor: 1, waktuMulai: '18:40', waktuSelesai: '19:00', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-09-02'),
      Rental(nama: 'Faizi', psNomor: 1, waktuMulai: '19:00', waktuSelesai: '19:20', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-09-02'),

      // --- 3 Sep 2026 (Kamis) - Rp 71.000 ---
      Rental(nama: 'Tio', psNomor: 2, waktuMulai: '10:11', waktuSelesai: '11:11', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-03'),
      Rental(nama: 'Tio', psNomor: 2, waktuMulai: '11:15', waktuSelesai: '11:55', durasiMenit: 40, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-03'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '12:30', waktuSelesai: '13:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-03'),
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '12:40', waktuSelesai: '13:40', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-03'),
      Rental(nama: 'Tio', psNomor: 1, waktuMulai: '14:20', waktuSelesai: '14:50', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-03'),
      Rental(nama: 'Abnan', psNomor: 2, waktuMulai: '14:00', waktuSelesai: '14:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-03'),
      Rental(nama: 'Akbar', psNomor: 1, waktuMulai: '15:00', waktuSelesai: '15:20', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-09-03'),
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '15:30', waktuSelesai: '17:30', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-09-03'),
      Rental(nama: 'Zain', psNomor: 2, waktuMulai: '16:00', waktuSelesai: '17:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-03'),
      Rental(nama: 'Tio', psNomor: 2, waktuMulai: '18:25', waktuSelesai: '18:55', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-03'),
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '18:30', waktuSelesai: '19:50', durasiMenit: 80, saldo: 7000, metodeBayar: 'Cash', tanggal: '2026-09-03'),
      Rental(nama: 'Ari', psNomor: 2, waktuMulai: '19:45', waktuSelesai: '20:45', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-03'),
      Rental(nama: 'Azril', psNomor: 1, waktuMulai: '20:00', waktuSelesai: '21:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-03'),
      Rental(nama: 'Faizi', psNomor: 2, waktuMulai: '21:00', waktuSelesai: '22:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-03'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '21:00', waktuSelesai: '22:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-03'),

      // --- 4 Sep 2026 (Jumat) - Rp 71.000 ---
      Rental(nama: 'Tio', psNomor: 1, waktuMulai: '10:00', waktuSelesai: '10:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-04'),
      Rental(nama: 'Eza', psNomor: 2, waktuMulai: '10:30', waktuSelesai: '11:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-04'),
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '11:00', waktuSelesai: '12:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-04'),
      Rental(nama: 'Faizi', psNomor: 2, waktuMulai: '12:00', waktuSelesai: '12:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-04'),
      Rental(nama: 'Alil dan Teman', psNomor: 1, waktuMulai: '13:00', waktuSelesai: '14:20', durasiMenit: 80, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-04'),
      Rental(nama: 'Faponso', psNomor: 1, waktuMulai: '14:30', waktuSelesai: '15:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-04'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '14:30', waktuSelesai: '14:50', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-09-04'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '15:18', waktuSelesai: '16:18', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-04'),
      Rental(nama: 'Tio', psNomor: 1, waktuMulai: '15:30', waktuSelesai: '16:00', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-04'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '16:16', waktuSelesai: '17:16', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-04'),
      Rental(nama: 'Ari', psNomor: 1, waktuMulai: '16:30', waktuSelesai: '17:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-04'),
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '17:30', waktuSelesai: '19:30', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-09-04'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '19:00', waktuSelesai: '20:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-04'),
      Rental(nama: 'Ripa', psNomor: 1, waktuMulai: '20:00', waktuSelesai: '21:00', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-09-04'),

      // --- 5 Sep 2026 (Sabtu) - Rp 59.000 ---
      Rental(nama: 'Abnan', psNomor: 2, waktuMulai: '09:10', waktuSelesai: '10:10', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-05'),
      Rental(nama: 'Tio', psNomor: 2, waktuMulai: '10:10', waktuSelesai: '10:40', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-05'),
      Rental(nama: 'Rifa', psNomor: 2, waktuMulai: '11:15', waktuSelesai: '13:15', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-09-05'),
      Rental(nama: 'Rifa', psNomor: 1, waktuMulai: '11:15', waktuSelesai: '11:45', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-05'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '12:24', waktuSelesai: '13:24', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-05'),
      Rental(nama: 'Kholfi', psNomor: 2, waktuMulai: '13:45', waktuSelesai: '14:45', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-05'),
      Rental(nama: 'Al dan Teman', psNomor: 1, waktuMulai: '14:00', waktuSelesai: '15:00', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-09-05'),
      Rental(nama: 'Tio', psNomor: 2, waktuMulai: '16:00', waktuSelesai: '16:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-05'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '16:40', waktuSelesai: '17:40', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-05'),
      Rental(nama: 'Tifa', psNomor: 2, waktuMulai: '18:30', waktuSelesai: '19:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-05'),
      Rental(nama: 'Abnan', psNomor: 2, waktuMulai: '20:00', waktuSelesai: '21:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-05'),

      // --- 6 Sep 2026 (Minggu) - Rp 57.000 ---
      Rental(nama: 'Ale', psNomor: 1, waktuMulai: '08:00', waktuSelesai: '09:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-06'),
      Rental(nama: 'Devano', psNomor: 2, waktuMulai: '08:05', waktuSelesai: '09:05', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-06'),
      Rental(nama: 'Abil', psNomor: 2, waktuMulai: '09:10', waktuSelesai: '11:10', durasiMenit: 120, saldo: 10000, metodeBayar: 'Transfer', tanggal: '2026-09-06'),
      Rental(nama: 'Dapin', psNomor: 1, waktuMulai: '09:10', waktuSelesai: '11:10', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-09-06'),
      Rental(nama: 'Tio', psNomor: 2, waktuMulai: '11:15', waktuSelesai: '11:45', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-06'),
      Rental(nama: 'Fauzi', psNomor: 2, waktuMulai: '11:50', waktuSelesai: '12:50', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-06'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '13:05', waktuSelesai: '14:05', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-06'),
      Rental(nama: 'Tio', psNomor: 1, waktuMulai: '13:00', waktuSelesai: '13:40', durasiMenit: 40, saldo: 4000, metodeBayar: 'Cash', tanggal: '2026-09-06'),
      Rental(nama: 'Akbar', psNomor: 1, waktuMulai: '13:40', waktuSelesai: '14:00', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-09-06'),
      Rental(nama: 'Fauzi', psNomor: 1, waktuMulai: '14:00', waktuSelesai: '15:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-06'),
      Rental(nama: 'Ardo', psNomor: 1, waktuMulai: '21:30', waktuSelesai: '22:00', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-06'),

      // ==========================================
      // MINGGU 4: 7 - 8 SEPTEMBER 2026
      // ==========================================
      // --- 7 Sep 2026 (Senin) - Rp 56.000 ---
      Rental(nama: 'Tio', psNomor: 2, waktuMulai: '10:00', waktuSelesai: '11:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-07'),
      Rental(nama: 'Fauzi', psNomor: 2, waktuMulai: '11:00', waktuSelesai: '11:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-07'),
      Rental(nama: 'Tio', psNomor: 2, waktuMulai: '11:30', waktuSelesai: '12:30', durasiMenit: 40, saldo: 4000, metodeBayar: 'Cash', tanggal: '2026-09-07'),
      Rental(nama: 'Ale', psNomor: 1, waktuMulai: '12:00', waktuSelesai: '12:30', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-07'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '12:30', waktuSelesai: '13:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-07'),
      Rental(nama: 'Kafi', psNomor: 2, waktuMulai: '13:30', waktuSelesai: '14:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-07'),
      Rental(nama: 'Abnan', psNomor: 1, waktuMulai: '13:00', waktuSelesai: '13:20', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-09-07'),
      Rental(nama: 'Efan', psNomor: 1, waktuMulai: '13:30', waktuSelesai: '15:30', durasiMenit: 120, saldo: 10000, metodeBayar: 'Cash', tanggal: '2026-09-07'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '15:30', waktuSelesai: '16:30', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-07'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '18:35', waktuSelesai: '19:35', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-07'),
      Rental(nama: 'Tio', psNomor: 1, waktuMulai: '19:10', waktuSelesai: '19:40', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-07'),
      Rental(nama: 'Abnan', psNomor: 1, waktuMulai: '19:40', waktuSelesai: '20:00', durasiMenit: 20, saldo: 2000, metodeBayar: 'Cash', tanggal: '2026-09-07'),
      Rental(nama: 'Ical', psNomor: 2, waktuMulai: '20:15', waktuSelesai: '20:55', durasiMenit: 40, saldo: 4000, metodeBayar: 'Cash', tanggal: '2026-09-07'),

      // --- 8 Sep 2026 (Selasa - Hari Ini) - Rp 19.000 ---
      Rental(nama: 'Tio', psNomor: 2, waktuMulai: '09:15', waktuSelesai: '09:45', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-08'),
      Rental(nama: 'Afnan', psNomor: 1, waktuMulai: '09:40', waktuSelesai: '10:10', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-08'),
      Rental(nama: 'Fauzi', psNomor: 1, waktuMulai: '10:10', waktuSelesai: '11:10', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-08'),
      Rental(nama: 'Nizam', psNomor: 2, waktuMulai: '11:00', waktuSelesai: '12:00', durasiMenit: 60, saldo: 5000, metodeBayar: 'Cash', tanggal: '2026-09-08'),
      Rental(nama: 'Ical', psNomor: 1, waktuMulai: '11:30', waktuSelesai: '12:00', durasiMenit: 30, saldo: 3000, metodeBayar: 'Cash', tanggal: '2026-09-08'),
    ];

    for (var r in rentals) {
      await db.insertRental(r);
    }

    // ==========================================
    // REKAP PENGELUARAN & OPERASIONAL BUKU
    // ==========================================
    // Minggu 1
    await db.insertExpense(Expense(
      keterangan: 'Belanja Snack Minggu 1',
      nominal: 205000,
      tanggal: '2026-08-23',
      waktu: '20:00',
    ));
    await db.insertSnackOrder(SnackOrder(
      namaPembeli: 'Total Jajan Minggu 1',
      detailItem: 'Rekap Penjualan Snack & Minuman',
      totalHarga: 33500,
      tanggal: '2026-08-23',
      waktu: '20:00',
    ));

    // Minggu 2
    await db.insertExpense(Expense(
      keterangan: 'Belanja Snack Minggu 2',
      nominal: 262000,
      tanggal: '2026-08-30',
      waktu: '20:00',
    ));

    // Minggu 3 (Sesuai Catatan Pengeluaran Minggu ke-3)
    await db.insertExpense(Expense(
      keterangan: 'Poster',
      nominal: 50000,
      tanggal: '2026-09-02',
      waktu: '12:00',
    ));
    await db.insertExpense(Expense(
      keterangan: 'Lampu 12W',
      nominal: 44000,
      tanggal: '2026-09-03',
      waktu: '14:00',
    ));
    await db.insertExpense(Expense(
      keterangan: 'Kursi / Meja',
      nominal: 100000,
      tanggal: '2026-09-05',
      waktu: '15:00',
    ));
  }
}