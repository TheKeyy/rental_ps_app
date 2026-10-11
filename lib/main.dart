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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF4F46E5),
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: const Color(0xFF171923),
          outline: const Color(0xFFE1E5EF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FC),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF222638),
          displayColor: const Color(0xFF171923),
        ).copyWith(
          titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF171923)),
          titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF222638)),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF42485A)),
          labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7FC),
          foregroundColor: Color(0xFF171923),
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
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
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE7EAF2)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          labelStyle: const TextStyle(color: Color(0xFF667085), fontWeight: FontWeight.w500),
          hintStyle: const TextStyle(color: Color(0xFF98A2B3)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E5EF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE1E5EF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.6),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 46),
            foregroundColor: const Color(0xFF4F46E5),
            side: const BorderSide(color: Color(0xFFD7DAEA)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: const Color(0xFFE8E9FF),
          side: const BorderSide(color: Color(0xFFE1E5EF)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          labelStyle: const TextStyle(color: Color(0xFF475467), fontWeight: FontWeight.w600),
          secondaryLabelStyle: const TextStyle(color: Color(0xFF3730A3), fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF667085),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          minLeadingWidth: 36,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE7EAF2),
          thickness: 1,
          space: 1,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: settings.pinAktif && settings.pin.length >= 4 ? const LockScreen() : const HomeScreen(),
    );
  }
}
