import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/system_controller.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  // 1. Ensure Flutter bindings are ready before doing any heavy lifting
  WidgetsFlutterBinding.ensureInitialized(); 

  try {
    // 2. Instantiate and explicitly await the initialization BEFORE launching the UI.
    // This pulls the risk OUT of the widget tree so we can catch Windows-specific crashes.
    final systemController = SystemController();
    await systemController.initializeSystem(); 

    // 3. If it succeeds, boot the Vault normally
    runApp(
      ChangeNotifierProvider.value(
        value: systemController, // Using .value because we created it above
        child: const ProgressoSystem(),
      ),
    );
  } catch (e, stackTrace) {
    // 4. THE EMERGENCY DIAGNOSTIC SCREEN
    // If anything fails (like a Windows file path error), it boots this instead of freezing.
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF171717),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "⚠️ WINDOWS BOOT FAILURE", 
                  style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 20),
                const Text("Exception:", style: TextStyle(color: Colors.white70, fontSize: 18)),
                Text(e.toString(), style: const TextStyle(color: Color(0xFFEBFB7E), fontFamily: 'monospace')),
                const SizedBox(height: 20),
                const Text("Stack Trace:", style: TextStyle(color: Colors.white70, fontSize: 18)),
                Text(stackTrace.toString(), style: const TextStyle(color: Colors.grey, fontFamily: 'monospace')),
              ],
            ),
          ),
        ),
      )
    );
  }
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
          // Since we awaited initialization BEFORE runApp, this should theoretically
          // never be false now, but we keep the gatekeeper just in case.
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