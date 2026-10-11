import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'database/db_helper.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'services/alert_service.dart';
import 'services/rental_time.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.instance.load();
  await AlertService.instance.init();
  await _restoreRentalNotifications();
  runApp(const MyApp());
}

Future<void> _restoreRentalNotifications() async {
  try {
    final now = DateTime.now();
    final yesterday = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
    final rentals = await DatabaseHelper.instance.getRentalsFromDate(yesterday);

    for (final rental in rentals) {
      if (rental.id == null) continue;
      final selesai = RentalTime.endOf(rental);
      if (!selesai.isAfter(now)) continue;
      try {
        await AlertService.instance.jadwalkanHabis(
          rentalId: rental.id!,
          psNomor: rental.psNomor,
          nama: rental.nama,
          selesai: selesai,
        );
      } catch (e) {
        debugPrint('Gagal memulihkan pengingat sewa ID ${rental.id}: $e');
      }
    }
  } catch (e) {
    debugPrint('Gagal memulihkan notifikasi rental: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: settings.namaWarung,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F7FB),
          foregroundColor: Color(0xFF171923),
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF171923),
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE8EAF2)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E4ED)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E4ED)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.6),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          ),
        ),
        useMaterial3: true,
      ),
      home: settings.pinAktif && settings.pin.length >= 4 ? const LockScreen() : const HomeScreen(),
    );
  }
}
