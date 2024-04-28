import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'providers/playlist_provider.dart';
import 'widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'providers/user_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MyApp extends StatelessWidget {
  static final fiam = FirebaseInAppMessaging.instance;
  final RemoteMessage? initialMessage;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  MyApp({super.key, this.initialMessage});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (ctx) => PlaylistProvider()),
          ChangeNotifierProvider(create: (ctx) => UserProvider()),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          home: kIsWeb
              ? AppStoreRedirectPage(navigatorKey: navigatorKey)
              : _layoutBuilder(),
          routes: _buildRoutes(),
          theme: _buildThemeData(context),
        ),
      ),
    );
  }

  Map<String, Widget Function(BuildContext)> _buildRoutes() {
    return {
      '/login': (context) => const LoginForm(),
      '/signup': (context) => const SignUpPage(),
      '/home': (context) => const HomePage(),
      '/video_playlists': (context) => PlaylistsPage(),
      '/job_board': (context) => const JobBoardPage(),
      '/calendar': (context) => const CalendarPage(),
      '/settings': (context) => const SettingsPage(),
      '/conferences': (context) => const EventsPage(),
    };
  }

  ThemeData _buildThemeData(BuildContext context) {
    return ThemeData(
      useMaterial3: false,
      fontFamily: 'Roboto',
      textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Roboto'),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color.fromARGB(255, 30, 33, 36),
      ),
    );
  }

  Widget _layoutBuilder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const maxWebWidth = 1920.0;
        if (constraints.maxWidth > maxWebWidth) {
          return _centeredConstrainedBox(maxWebWidth);
        }
        return _buildStreamBuilder();
      },
    );
  }

  Widget _centeredConstrainedBox(double maxWidth) {
    return Container(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: _buildStreamBuilder(),
        ),
      ),
    );
  }

  StreamBuilder<User?> _buildStreamBuilder() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        } else {
          if (snapshot.hasData) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null && user.emailVerified) {
              return const HomePage();
            } else {
              return const EmailVerificationPage();
            }
          } else {
            return const InitialPage();
          }
        }
      },
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await attemptInitialization();
}

Future<void> attemptInitialization({int retryCount = 0}) async {
  try {
    await _initializeFirebase();
    await _initializeMessaging();
    await dotenv.load(fileName: '.env');
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).then((_) {
      runApp(MyApp());
    });
  } catch (e) {
    const maxRetries = 3;
    if (retryCount >= maxRetries) {
      runApp(ErrorApp(e));
    } else {
      print('Error initializing app, attempt ${retryCount + 1}: $e');
      await Future.delayed(const Duration(seconds: 2));
      return attemptInitialization(retryCount: retryCount + 1);
    }
  }
}

class ErrorApp extends StatelessWidget {
  final dynamic error;

  const ErrorApp(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('Failed to initialize app: $error'),
        ),
      ),
    );
  }
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }
}

Future<void> _initializeMessaging() async {
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _removeBadge();
    });
    FirebaseMessaging.instance.onTokenRefresh.listen(_updateUserToken);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      checkBadgeSupportAndShow();
    });
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _updateUserToken(token);
    }

    await _requestMessagingPermission();
  }
}

Future<void> checkBadgeSupportAndShow() async {
  bool isSupported = await FlutterAppBadger.isAppBadgeSupported();
  if (isSupported) {
    FlutterAppBadger.updateBadgeCount(1);
  }
}

void _removeBadge() {
  FlutterAppBadger.removeBadge();
}

Future<void> _updateUserToken(String newToken) async {
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (userId.isNotEmpty) {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'fcmToken': newToken,
    }, SetOptions(merge: true));
  }
}

Future<void> _requestMessagingPermission() async {
  if (!kIsWeb) {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Got a message in the background: ${message.messageId}');
}
