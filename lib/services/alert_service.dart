import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class AlertService {
  AlertService._();
  static final AlertService instance = AlertService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _siap = false;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    _siap = true;
  }

  Future<void> bunyiLokal() async {
    await SystemSound.play(SystemSoundType.alert);
    await HapticFeedback.heavyImpact();
  }

  Future<void> batalkanSemua(int psNomor) async {
    if (!_siap) return;
    await _plugin.cancel(psNomor * 10);
    await _plugin.cancel(psNomor * 10 + 1);
  }

  Future<void> jadwalkanHabis({
    required int psNomor,
    required String nama,
    required DateTime selesai,
  }) async {
    if (!_siap) return;
    await batalkanSemua(psNomor);
    final now = DateTime.now();
    if (!selesai.isAfter(now)) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'rental_timer',
        'Timer sewa PS',
        channelDescription: 'Peringatan sisa waktu dan waktu habis',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    final lima = selesai.subtract(const Duration(minutes: 5));
    if (lima.isAfter(now)) {
      await _plugin.zonedSchedule(
        psNomor * 10,
        'Sisa 5 menit',
        'PS $psNomor ($nama) hampir habis',
        tz.TZDateTime.from(lima, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    await _plugin.zonedSchedule(
      psNomor * 10 + 1,
      'Waktu habis',
      'PS $psNomor ($nama) sudah selesai',
      tz.TZDateTime.from(selesai, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
