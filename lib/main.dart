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
      final mulai = RentalTime.startOf(rental);
      final selesai = RentalTime.endOf(rental);
      if (!selesai.isAfter(now)) continue;
      // Keep future reservations and sessions that are still running across midnight.
      if (mulai.isBefore(now) && selesai.isBefore(now)) continue;
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: settings.pinAktif && settings.pin.length >= 4 ? const LockScreen() : const HomeScreen(),
    );
  }
}
