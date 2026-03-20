import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  String _errorMessage = "";

  void _authenticate(SystemController system) {
    setState(() => _errorMessage = "");
    
    if (system.hasAccount()) {
      bool success = system.loginUser(_userController.text, _passController.text);
      if (!success) setState(() => _errorMessage = "Access Denied. Invalid credentials.");
    } else {
      bool success = system.registerUser(_userController.text, _passController.text);
      if (!success) setState(() => _errorMessage = "Fields cannot be empty.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<SystemController>();
    bool hasAccount = system.hasAccount();

    return Scaffold(
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF444444)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasAccount ? "SYSTEM LOGIN" : "INITIALIZE SYSTEM",
                style: const TextStyle(color: Color(0xFFEBFB7E), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _userController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Username",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF171717),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Password",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF171717),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 15),
                Text(_errorMessage, style: const TextStyle(color: Color(0xFFFF5555), fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _authenticate(system),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFFEBFB7E),
                  foregroundColor: const Color(0xFF171717),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
                child: Text(hasAccount ? "ACCESS SYSTEM" : "CREATE ACCOUNT", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}