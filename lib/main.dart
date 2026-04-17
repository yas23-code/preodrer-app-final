import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/cart/providers/cart_controller.dart';
import 'features/orders/providers/vendor_orders_provider.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> _initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iOSInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(android: androidInit, iOS: iOSInit);
  await _localNotifications.initialize(initSettings);
  
  final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
      // Request permissions natively for Android 13+
      await androidPlugin.requestNotificationsPermission();
      
      // Explicitly create the channel for Android 8+
      const channel = AndroidNotificationChannel(
        'default_channel',
        'Default',
        description: 'Default notifications channel',
        importance: Importance.max,
      );
      await androidPlugin.createNotificationChannel(channel);
  }
}

Future<void> _initFirebaseMessaging() async {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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

void showLocalNotification(String title, String body) {
  debugPrint('[LOCAL NOTIFICATION] Attempting to show: $title - $body');
  try {
    _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
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
    debugPrint('[LOCAL NOTIFICATION] Successfully called show()');
  } catch (e, st) {
    debugPrint('[LOCAL NOTIFICATION] Error showing notification: $e\n$st');
  }
}

Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // It's ok if .env isn't present in all dev environments.
  }
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await _loadEnv();
    
    await _initLocalNotifications();
    
    try {
      await Firebase.initializeApp();
      await _initFirebaseMessaging();
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }

    // ── Initialize Supabase with built-in session persistence ─────────
    // This MUST happen before runApp so the client is ready and any
    // persisted session from a previous launch is restored automatically.
    final supabaseUrl = dotenv.env[kSupabaseUrlEnvKey] ?? '';
    final supabaseAnonKey = dotenv.env[kSupabaseAnonKeyEnvKey] ?? '';
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env file.',
      );
    }
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    runApp(const ProviderScope(child: PreorderApp()));
  } catch (e, st) {
    debugPrint('App initialization failed: $e\n$st');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Failed to load app.\nError: $e',
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ),
    );
  }
}

class PreorderApp extends ConsumerStatefulWidget {
  const PreorderApp({super.key});

  @override
  ConsumerState<PreorderApp> createState() => _PreorderAppState();
}

class _PreorderAppState extends ConsumerState<PreorderApp> {
  @override
  void initState() {
    super.initState();

    try {
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessage(message);
      });

      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleMessage(message);
          });
        }
      });
    } catch (e) {
      debugPrint('FirebaseMessaging setup error: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data.containsKey('route')) {
      final route = message.data['route'] as String;
      if (route == '/home') {
        ref.invalidate(vendorOrdersProvider);
      }
      ref.read(routerProvider).go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(cartControllerProvider);
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
