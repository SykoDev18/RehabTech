import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../core/utils/logger.dart';

/// Handler para mensajes en background (debe ser top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.info('Mensaje en background: ${message.messageId}', tag: 'FCM');
}

/// Servicio de notificaciones push con FCM
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  // Constantes para preferencias
  static const String _keyDailyReminder = 'notif_daily_reminder';
  static const String _keyReminderHour = 'notif_reminder_hour';
  static const String _keyReminderMinute = 'notif_reminder_minute';
  static const String _keyTherapistMessages = 'notif_therapist_messages';
  static const String _keyProgressUpdates = 'notif_progress_updates';

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Inicializar timezone
      tz_data.initializeTimeZones();
      
      // Configurar handler de background
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Solicitar permisos
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.info(
        'Permisos de notificación: ${settings.authorizationStatus}',
        tag: 'FCM',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // Obtener token FCM
        _fcmToken = await _messaging.getToken();
        AppLogger.info('FCM Token: ${_fcmToken?.substring(0, 20)}...', tag: 'FCM');

        // Escuchar cambios de token
        _messaging.onTokenRefresh.listen((token) {
          _fcmToken = token;
          AppLogger.info('FCM Token actualizado', tag: 'FCM');
          // TODO: Enviar nuevo token al servidor
        });

        // Configurar notificaciones locales
        await _initializeLocalNotifications();

        // Escuchar mensajes en foreground
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Escuchar cuando se abre la app desde una notificación
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Verificar si la app fue abierta desde una notificación
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }
      }

      _initialized = true;
      AppLogger.info('Servicio de notificaciones inicializado', tag: 'FCM');
    } catch (e) {
      AppLogger.error('Error inicializando notificaciones: $e', tag: 'FCM');
    }
  }

  /// Inicializar notificaciones locales
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones para Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'rehabtech_reminders',
        'Recordatorios de ejercicios',
        description: 'Notificaciones para recordarte hacer tus ejercicios',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Manejar mensaje en foreground
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info('Mensaje en foreground: ${message.notification?.title}', tag: 'FCM');
    
    // Mostrar notificación local
    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'RehabTech',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Manejar cuando se abre la app desde una notificación
  void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.info('App abierta desde notificación: ${message.data}', tag: 'FCM');
    // TODO: Navegar a la pantalla correspondiente según message.data
  }

  /// Callback cuando se toca una notificación local
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info('Notificación tocada: ${response.payload}', tag: 'FCM');
    // TODO: Navegar según el payload
  }

  /// Mostrar notificación local
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'rehabtech_reminders',
      'Recordatorios de ejercicios',
      channelDescription: 'Notificaciones para recordarte hacer tus ejercicios',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Programar recordatorio diario de ejercicios
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    // Guardar preferencia
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyReminder, true);
    await prefs.setInt(_keyReminderHour, hour);
    await prefs.setInt(_keyReminderMinute, minute);

    // Cancelar recordatorios anteriores
    await _localNotifications.cancel(1);

    // Programar nuevo recordatorio
    await _localNotifications.zonedSchedule(
      1,
      '¡Hora de ejercitarte! 💪',
      'Es momento de hacer tu rutina de rehabilitación',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rehabtech_reminders',
          'Recordatorios de ejercicios',
          channelDescription: 'Notificaciones para recordarte hacer tus ejercicios',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({'type': 'daily_reminder'}),
    );

    AppLogger.info('Recordatorio diario programado: $hour:$minute', tag: 'FCM');
  }

  /// Calcular próxima instancia del horario
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// Cancelar recordatorio diario
  Future<void> cancelDailyReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDailyReminder, false);
    await _localNotifications.cancel(1);
    AppLogger.info('Recordatorio diario cancelado', tag: 'FCM');
  }

  /// Obtener configuración de recordatorio
  Future<Map<String, dynamic>> getReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_keyDailyReminder) ?? false,
      'hour': prefs.getInt(_keyReminderHour) ?? 9,
      'minute': prefs.getInt(_keyReminderMinute) ?? 0,
      'therapistMessages': prefs.getBool(_keyTherapistMessages) ?? true,
      'progressUpdates': prefs.getBool(_keyProgressUpdates) ?? true,
    };
  }

  /// Guardar preferencia de mensajes de terapeuta
  Future<void> setTherapistMessagesEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTherapistMessages, enabled);
  }

  /// Guardar preferencia de actualizaciones de progreso
  Future<void> setProgressUpdatesEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyProgressUpdates, enabled);
  }

  /// Suscribirse a un topic (ej: para notificaciones por tipo de usuario)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    AppLogger.info('Suscrito a topic: $topic', tag: 'FCM');
  }

  /// Desuscribirse de un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    AppLogger.info('Desuscrito de topic: $topic', tag: 'FCM');
  }
}
