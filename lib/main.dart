import 'package:ebv/provider/app_data_provider.dart';
import 'package:ebv/provider/auth_provider.dart';
import 'package:ebv/screens/home/home.dart';
import 'package:ebv/screens/auth/email_login.dart';
import 'package:ebv/screens/network_check_service.dart';
import 'package:ebv/screens/splash_screen.dart';
import 'package:ebv/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService().showNotification(message);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: Platform.isAndroid ?
    const FirebaseOptions(
      apiKey: 'AIzaSyAkph2bSUTQ_H6XeIMlu_zhoQhDXSHcBiY',
      appId: '1:856535711230:android:f718effaf8a3d8510b14af',
      messagingSenderId: '856535711230',
      projectId: 'ebvproject-47269',
    ) : null,
  );

  await NotificationService().initialize();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {

  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await NotificationService().setupFirebaseMessaging();
      await ref.read(authStateProvider.notifier).initializeAuth(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appStateNotifierProvider.notifier).initializeAppData();
      });

    } catch (error) {
      print(error);
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'EBV',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _buildHomeScreen(authState),
    );
  }

  Widget _buildHomeScreen(AuthState authState) {
    if (_isInitializing) {
      return SplashScreen();
    }

    if (authState.isLoading) {
      return SplashScreen();
    }

    if (authState.userInfo == null ) {

      return NetworkManager(child: const SignIn());
    }
    return  const Home();
  }
}