import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'components/game.dart';
import 'components/shop.dart';
import 'iap_manager.dart';
import 'screens/level_selection_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  IAPManager.instance.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  await Supabase.initialize(
    url: 'https://cjxeuuvmqhzcupxmhvhs.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqeGV1dXZtcWh6Y3VweG1odmhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2NTkxMjIsImV4cCI6MjA3NzIzNTEyMn0.bREKQHREsCv7O16AwDXHBckqV2dN5WVwgilECOEt5Uw',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ShopManager _shopManager = ShopManager();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Angry Birds',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data?.session != null) {
            return LevelSelectionScreen(shopManager: _shopManager);
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
