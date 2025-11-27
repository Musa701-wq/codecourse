import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:coding_tutor/ads/ads_provider.dart';
import 'package:coding_tutor/providers/auth_provider.dart';
import 'package:coding_tutor/views/splash_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'core/App_theme.dart';
import 'providers/theme_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Add comprehensive error handling
  try {
    print('🚀 Starting app initialization...');

    // 1. Initialize Firebase first
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('✅ Firebase initialized');

    // 2. Initialize App Tracking Transparency
    await initTracking();
    print('✅ App Tracking Transparency initialized');

    // 3. Initialize Mobile Ads with error handling
    await initMobileAds();
    print('✅ Mobile Ads initialized');

    print('🎉 All services initialized successfully');

  } catch (e, stackTrace) {
    print('❌ Initialization failed: $e');
    print('📋 Stack trace: $stackTrace');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> initTracking() async {
  try {
    // Wait a bit for the native side to be ready
    await Future.delayed(const Duration(milliseconds: 500));

    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    print('📱 Current tracking status: $status');

    if (status == TrackingStatus.notDetermined) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newStatus = await AppTrackingTransparency.requestTrackingAuthorization();
      print('📱 New tracking status: $newStatus');
    }
  } catch (e) {
    print('❌ App Tracking Transparency failed: $e');
    // Don't rethrow - continue without tracking
  }
}

Future<void> initMobileAds() async {
  try {
    // Initialize Mobile Ads with configuration
    await MobileAds.instance.initialize();

    // Set app configuration (optional but recommended)
    final configuration = RequestConfiguration(
      testDeviceIds: ['YOUR_TEST_DEVICE_ID'], // Add your test device ID
    );
    MobileAds.instance.updateRequestConfiguration(configuration);

    print('✅ Mobile Ads configured');
  } catch (e) {
    print('❌ Mobile Ads initialization failed: $e');
    // Don't rethrow - continue without ads
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().mode;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const SplashWrapper(),
    );
  }
}