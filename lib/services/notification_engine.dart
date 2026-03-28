import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/task_model.dart';

class NotificationEngine {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    // Linux Initialization
    const LinuxInitializationSettings initializationSettingsLinux = LinuxInitializationSettings(defaultActionName: 'Open System');
    
    // FIX: Changed 'ic_launcher' to 'launcher_icon' to match your Android manifest
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings = InitializationSettings(
      linux: initializationSettingsLinux,
      android: initializationSettingsAndroid,
    );

    // FIX: The parameter name in v18+ is 'settings', not 'initializationSettings'
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );
    _isInitialized = true;
  }

  static Future<void> showInstantNotification({required int id, required String title, required String body}) async {
    const LinuxNotificationDetails linuxPlatformChannelSpecifics = LinuxNotificationDetails();
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'hunter_system_alerts', 'System Alerts',
      channelDescription: 'Alerts for daily quests and system updates',
      importance: Importance.max, priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      linux: linuxPlatformChannelSpecifics, 
      android: androidPlatformChannelSpecifics
    );

    // Using the v18+ Named Parameter syntax for the show() function
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  // Simulates a scheduled notification
  static Future<void> scheduleTaskReminder(DailyTask task) async {
    await showInstantNotification(
      id: task.id.hashCode,
      title: "🗓️ Quest Logged: ${task.date}",
      body: "The System has recorded your plan to: ${task.text}",
    );
  }
}