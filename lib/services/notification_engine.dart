import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/task_model.dart';

class NotificationEngine {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    // 1. Linux Initialization
    const LinuxInitializationSettings initializationSettingsLinux = LinuxInitializationSettings(
      defaultActionName: 'Open System'
    );
    
    // 2. Android Initialization (Matching your manifest)
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/launcher_icon'
    );

    // 3. WINDOWS INITIALIZATION (Fixed: Added the required 'appUserModelId')
    const WindowsInitializationSettings initializationSettingsWindows = WindowsInitializationSettings(
      appName: 'Progresso HQ', 
      appUserModelId: 'com.gokulgowdat.progressohq', // <-- The final key Windows was demanding
    );

    // 4. Combine all platform settings into the master payload
    const InitializationSettings initializationSettings = InitializationSettings(
      linux: initializationSettingsLinux,
      android: initializationSettingsAndroid,
      windows: initializationSettingsWindows,
    );

    // Initialize the plugin with the master settings
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

    // Add Windows specific details so the alerts display properly in the Windows Action Center
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

  // Simulates a scheduled notification
  static Future<void> scheduleTaskReminder(DailyTask task) async {
    await showInstantNotification(
      id: task.id.hashCode,
      title: "🗓️ Quest Logged: ${task.date}",
      body: "The System has recorded your plan to: ${task.text}",
    );
  }
}