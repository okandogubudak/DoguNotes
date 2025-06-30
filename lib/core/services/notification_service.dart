import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPermissions();
    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    // Android 13+ notification permissions
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // iOS permissions
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
    final payload = notificationResponse.payload;
    if (payload != null) {
      // Navigate to specific note or screen based on payload
      print('Notification tapped with payload: $payload');
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationImportance importance = NotificationImportance.defaultImportance,
  }) async {
    if (!_isInitialized) await initialize();

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'notes_channel',
      'Notes Notifications',
      channelDescription: 'Notifications for note reminders and updates',
      importance: _mapImportance(importance),
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF7DD3FC),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationImportance importance = NotificationImportance.defaultImportance,
  }) async {
    if (!_isInitialized) await initialize();

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'scheduled_notes_channel',
      'Scheduled Notes',
      channelDescription: 'Scheduled notifications for note reminders',
      importance: _mapImportance(importance),
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF7DD3FC),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> showDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Daily reminder notifications',
      importance: Importance.defaultImportance,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF7DD3FC),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.daily,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  Future<List<ActiveNotification>> getActiveNotifications() async {
    final activeNotifications = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.getActiveNotifications();
    return activeNotifications ?? [];
  }

  // Notification templates for common use cases
  Future<void> showNoteReminderNotification({
    required String noteTitle,
    required String noteId,
  }) async {
    await showNotification(
      id: noteId.hashCode,
      title: 'Not Hatırlatıcısı',
      body: 'Notunuz: $noteTitle',
      payload: 'note_reminder:$noteId',
      importance: NotificationImportance.high,
    );
  }

  Future<void> showBackupSuccessNotification() async {
    await showNotification(
      id: 1001,
      title: 'Yedekleme Tamamlandı',
      body: 'Notlarınız başarıyla yedeklendi',
      importance: NotificationImportance.low,
    );
  }

  Future<void> showBackupFailedNotification() async {
    await showNotification(
      id: 1002,
      title: 'Yedekleme Başarısız',
      body: 'Notlar yedeklenirken bir hata oluştu',
      importance: NotificationImportance.high,
    );
  }

  Future<void> showStorageWarningNotification() async {
    await showNotification(
      id: 1003,
      title: 'Depolama Uyarısı',
      body: 'Cihazınızın depolama alanı azalıyor',
      importance: NotificationImportance.high,
    );
  }

  Future<void> scheduleNoteReminder({
    required String noteId,
    required String noteTitle,
    required DateTime reminderTime,
  }) async {
    await scheduleNotification(
      id: noteId.hashCode,
      title: 'Not Hatırlatıcısı',
      body: noteTitle,
      scheduledDate: reminderTime,
      payload: 'note_reminder:$noteId',
      importance: NotificationImportance.high,
    );
  }

  Importance _mapImportance(NotificationImportance importance) {
    switch (importance) {
      case NotificationImportance.min:
        return Importance.min;
      case NotificationImportance.low:
        return Importance.low;
      case NotificationImportance.defaultImportance:
        return Importance.defaultImportance;
      case NotificationImportance.high:
        return Importance.high;
      case NotificationImportance.max:
        return Importance.max;
    }
  }
}

enum NotificationImportance {
  min,
  low,
  defaultImportance,
  high,
  max,
} 