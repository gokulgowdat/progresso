import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart'; 

// =========================================================================
// BACKGROUND ISOLATION HANDLER
// =========================================================================
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  if (notificationResponse.actionId == 'stop' || notificationResponse.actionId == 'complete') {
    FlutterLocalNotificationsPlugin().cancel(id: notificationResponse.id!);
  }
}

class NotificationEngine {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      
      // THE FIX: The correct property name in the new v5.0.2 API is '.identifier'
      final String currentTimeZone = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(currentTimeZone));

      const LinuxInitializationSettings initializationSettingsLinux = LinuxInitializationSettings(
        defaultActionName: 'Open System'
      );
      
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/launcher_icon' 
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        linux: initializationSettingsLinux,
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
        onDidReceiveNotificationResponse: (response) {
           if (response.actionId == 'stop' || response.actionId == 'complete') {
             _notificationsPlugin.cancel(id: response.id!);
           }
        }
      );
      
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }

      _isInitialized = true;
      print("SYSTEM LOG: Native Background Alarm Engine Online. Timezone: $currentTimeZone");
      
    } catch (e) {
      print("SYSTEM WARNING: OS rejected Notification Engine. Error: $e");
    }
  }

  static Future<void> showInstantNotification({required int id, required String title, required String body}) async {
    if (!_isInitialized) return;

    const AndroidNotificationDetails androidSpecs = AndroidNotificationDetails(
      'system_alerts', 'System Alerts',
      importance: Importance.max, priority: Priority.high,
    );
    const NotificationDetails platformSpecs = NotificationDetails(android: androidSpecs);

    await _notificationsPlugin.show(id: id, title: title, body: body, notificationDetails: platformSpecs);
  }

  // =========================================================================
  // THE NATIVE OS ALARM SCHEDULER
  // =========================================================================
  static Future<void> scheduleDailyRecurringQuest({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) return;

    final Int32List insistentFlag = Int32List.fromList(<int>[4]);

    final AndroidNotificationDetails alarmSpecs = AndroidNotificationDetails(
      'quest_alarms', 'Quest Alarms',
      channelDescription: 'Fires alarms for recurring daily quests.',
      importance: Importance.max,
      priority: Priority.max,
      audioAttributesUsage: AudioAttributesUsage.alarm, 
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true, 
      additionalFlags: insistentFlag, 
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('complete', 'Complete Task', showsUserInterface: true, cancelNotification: true),
        const AndroidNotificationAction('stop', 'Stop Alarm', showsUserInterface: true, cancelNotification: true),
      ]
    );

    final NotificationDetails platformSpecs = NotificationDetails(android: alarmSpecs);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: platformSpecs,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, 
    );
    
    print("ALARM SET: '$title' registered natively for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} local time.");
  }

  static Future<void> cancelTaskAlarm(int id) async {
    await _notificationsPlugin.cancel(id: id);
    print("ALARM KILLED: Alarm ID $id removed from OS.");
  }
}