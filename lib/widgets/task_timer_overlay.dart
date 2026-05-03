import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_controller.dart';

class TaskTimerOverlay extends StatefulWidget {
  final String taskName;
  const TaskTimerOverlay({super.key, required this.taskName});

  @override
  State<TaskTimerOverlay> createState() => _TaskTimerOverlayState();
}

class _TaskTimerOverlayState extends State<TaskTimerOverlay> {
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isRunning = false;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() { _secondsElapsed++; });
      });
    }
    setState(() { _isRunning = !_isRunning; });
  }

  void _stopAndSave() {
    _timer?.cancel();
    if (_secondsElapsed > 0) {
      double hoursLogged = _secondsElapsed / 3600.0;
      context.read<SystemController>().logGlobalTime(hoursLogged);
    }
    Navigator.pop(context);
  }

  String get _formattedTime {
    int h = _secondsElapsed ~/ 3600;
    int m = (_secondsElapsed % 3600) ~/ 60;
    int s = _secondsElapsed % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.read<SystemController>().systemData.isDarkMode;
    final accent = isDark ? const Color(0xFFEBFB7E) : const Color(0xFF0EA5E9);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF171717) : const Color(0xFFF4F7F6),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("CURRENT FOCUS", style: TextStyle(color: Colors.grey[500], fontSize: 16, letterSpacing: 2)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(widget.taskName, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 60),
            
            Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _isRunning ? accent : Colors.grey[800]!, width: 4),
                boxShadow: _isRunning ? [BoxShadow(color: accent.withOpacity(0.2), blurRadius: 30, spreadRadius: 10)] : []
              ),
              child: Center(
                child: Text(_formattedTime, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 48, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ),
            ),
            
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'play_pause',
                  backgroundColor: _isRunning ? Colors.grey[800] : accent,
                  foregroundColor: _isRunning ? Colors.white : Colors.black,
                  onPressed: _toggleTimer,
                  child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 30),
                ),
                const SizedBox(width: 20),
                FloatingActionButton(
                  heroTag: 'stop_save',
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  onPressed: _stopAndSave,
                  child: const Icon(Icons.stop, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text("Press Stop to log hours to Global Stats and exit.", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}