import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_shell.dart';
import 'services/blocker_service.dart';
import 'theme/finora_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark navigation bar and status bar on mobile devices
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: FinoraColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final blockerService = BlockerService();

  runApp(FinoraApp(service: blockerService));
}

class FinoraApp extends StatelessWidget {
  final BlockerService service;

  const FinoraApp({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finora Fblocker',
      debugShowCheckedModeBanner: false,
      theme: FinoraTheme.darkTheme,
      home: MainShell(service: service),
    );
  }
}
