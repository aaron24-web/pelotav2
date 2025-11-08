import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  await Supabase.initialize(
    url: 'https://qwvhwnsapbbnqwdrdzop.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3dmh3bnNhcGJibnF3ZHJkem9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MDI5MzIsImV4cCI6MjA3NzI3ODkzMn0.BGbq6BU45nOD_1I0HAnB_VilSs-cnZYvlBY0V2ZVGto',
  );

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    ),
  );
}