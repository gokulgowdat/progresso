import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/system_controller.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(
    ChangeNotifierProvider(
      create: (context) => SystemController()..initializeSystem(),
      child: const ProgressoSystem(),
    ),
  );
}

class ProgressoSystem extends StatelessWidget {
  const ProgressoSystem({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Progresso - Core System Terminal',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF171717),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEBFB7E),
          surface: Color(0xFF2C2C2C),
        ),
      ),
      home: Consumer<SystemController>(
        builder: (context, system, child) {
          if (!system.isInitialized) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFEBFB7E))));
          }
          // The Gatekeeper Logic!
          return system.isLoggedIn ? const DashboardScreen() : const LoginScreen();
        },
      ),
    );
  }
}