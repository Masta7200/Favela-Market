import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows system notifications (status bar / lock screen) on Android and iOS.
///
/// The payload of each notification is an order id; tapping the
/// notification calls [onOrderTapped] so the app can open that order.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static void Function(String orderId)? onOrderTapped;

  /// Order id from the notification that launched the app (cold start).
  static String? launchOrderId;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'deliveries',
    'Livraisons',
    description: 'Nouvelles livraisons et mises à jour des commandes',
    importance: Importance.max,
  );

  static bool get _isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> init() async {
    if (!_isSupported || _initialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final orderId = response.payload;
        if (orderId != null && orderId.isNotEmpty) {
          onOrderTapped?.call(orderId);
        }
      },
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) launchOrderId = payload;
    }

    _initialized = true;
  }

  /// Asks the user for permission (Android 13+ and iOS).
  static Future<void> requestPermission() async {
    if (!_isSupported) return;
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String? orderId,
  }) async {
    if (!_isSupported || !_initialized) return;

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      payload: orderId,
    );
  }

  static Future<void> cancelAll() async {
    if (!_isSupported || !_initialized) return;
    await _plugin.cancelAll();
  }
}
