import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // TODO: handle background message if needed.
}

Future<void> _initFirebaseMessaging() async {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iOSInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(android: androidInit, iOS: iOSInit);
  await _localNotifications.initialize(initSettings);

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  });
}

Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // It's ok if .env isn't present in all dev environments.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnv();
  await Firebase.initializeApp();
  await _initFirebaseMessaging();

  runApp(const ProviderScope(child: PreorderApp()));
}

class PreorderApp extends ConsumerWidget {
  const PreorderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: PreorderTheme.light(),
      darkTheme: PreorderTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

