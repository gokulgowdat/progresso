import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/task_model.dart';

class NotificationEngine {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      const LinuxInitializationSettings initializationSettingsLinux = LinuxInitializationSettings(
        defaultActionName: 'Open System'
      );
      
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/launcher_icon'
      );

      const WindowsInitializationSettings initializationSettingsWindows = WindowsInitializationSettings(
        appName: 'Progresso HQ', 
        appUserModelId: 'com.gokulgowdat.progressohq',
        guid: 'A3A69A1C-1A69-42E3-A5B4-6987E84B1F2D', 
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        linux: initializationSettingsLinux,
        android: initializationSettingsAndroid,
        windows: initializationSettingsWindows,
      );

      await _notificationsPlugin.initialize(
        settings: initializationSettings,
      );
      _isInitialized = true;
      print("SYSTEM LOG: Notification Engine Online.");
      
    } catch (e) {
      // THE ARMOR PLATE: If Wine/Windows rejects the notification hook, we catch it here.
      // We leave _isInitialized as false, so the app knows not to try sending alerts, 
      // but WE DO NOT CRASH.
      print("SYSTEM WARNING: OS rejected Notification Engine. Running in silent mode. Error: $e");
    }
  }

  static Future<void> showInstantNotification({required int id, required String title, required String body}) async {
    // If the engine failed to initialize (e.g., in Bottles), silently abort the alert so it doesn't crash.
    if (!_isInitialized) {
      print("SYSTEM WARNING: Alert suppressed (Engine offline) -> $title");
      return; 
    }

    const LinuxNotificationDetails linuxPlatformChannelSpecifics = LinuxNotificationDetails();
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'hunter_system_alerts', 'System Alerts',
      channelDescription: 'Alerts for daily quests and system updates',
      importance: Importance.max, priority: Priority.high,
    );
    const WindowsNotificationDetails windowsPlatformChannelSpecifics = WindowsNotificationDetails();
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      linux: linuxPlatformChannelSpecifics, 
      android: androidPlatformChannelSpecifics,
      windows: windowsPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  static Future<void> scheduleTaskReminder(DailyTask task) async {
    await showInstantNotification(
      id: task.id.hashCode,
      title: "🗓️ Quest Logged: ${task.date}",
      body: "The System has recorded your plan to: ${task.text}",
    );
  }
}