import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_shell.dart';
import 'services/blocker_service.dart';
import 'services/ota_service.dart';
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
  final otaService = OtaService();

  // Check for updates in background on launch
  otaService.checkForUpdates();

  runApp(FinoraApp(service: blockerService, otaService: otaService));
}

class FinoraApp extends StatelessWidget {
  final BlockerService service;
  final OtaService otaService;

  const FinoraApp({
    super.key,
    required this.service,
    required this.otaService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finora Fblocker',
      debugShowCheckedModeBanner: false,
      theme: FinoraTheme.darkTheme,
      home: MainShell(
        service: service,
        otaService: otaService,
      ),
    );
  }
}
