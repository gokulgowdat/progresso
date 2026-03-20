import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/skill_node.dart';
import '../services/system_controller.dart';

class TimerOverlay extends StatefulWidget {
  final SkillNode skill;
  const TimerOverlay({super.key, required this.skill});

  @override
  State<TimerOverlay> createState() => _TimerOverlayState();
}

class _TimerOverlayState extends State<TimerOverlay> {
  bool isSelectingMode = true;
  String activeModeName = "";
  int elapsedSeconds = 0;
  int targetSeconds = 0; // 0 means stopwatch (infinite)
  bool isRunning = false;
  Timer? _timer;

  final List<Map<String, dynamic>> focusModes = [
    {'name': 'Stopwatch', 'mins': 0, 'icon': '⏱️', 'desc': 'Uncapped focus. Run until stopped.'},
    {'name': 'Pomodoro', 'mins': 25, 'icon': '🍅', 'desc': '25m sprint. The classic cognitive hack.'},
    {'name': '52/17 Rule', 'mins': 52, 'icon': '🧠', 'desc': '52m focus. Proven maximum efficiency.'},
    {'name': 'Ultradian', 'mins': 90, 'icon': '🌊', 'desc': '90m flow state. Push your limits.'},
    {'name': 'Marathon', 'mins': 120, 'icon': '🔥', 'desc': '120m grind. For the relentless.'},
  ];

  void _startTimerMode(int minutes, String name) {
    setState(() {
      isSelectingMode = false;
      activeModeName = name;
      targetSeconds = minutes * 60;
      elapsedSeconds = 0;
      isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        elapsedSeconds++;
        // Stop automatically if it's a countdown and we reached the target
        if (targetSeconds > 0 && elapsedSeconds >= targetSeconds) {
          _stopAndLog();
        }
      });
    });
  }

  void _stopAndLog() {
    _timer?.cancel();
    double hours = elapsedSeconds / 3600.0;
    Provider.of<SystemController>(context, listen: false).logTime(widget.skill, hours);
    Navigator.of(context).pop();
  }

  String get timeString {
    int displaySecs = targetSeconds > 0 ? (targetSeconds - elapsedSeconds) : elapsedSeconds;
    int h = displaySecs ~/ 3600;
    int m = (displaySecs % 3600) ~/ 60;
    int s = displaySecs % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171717),
      body: Center(
        child: isSelectingMode ? _buildSelectionScreen() : _buildActiveTimerScreen(),
      ),
    );
  }

  Widget _buildSelectionScreen() {
    // Wrapped in a SingleChildScrollView to make it indestructible on small screens
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("SELECT FOCUS TECHNIQUE", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 10),
            Text("Target: ${widget.skill.name}", textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF00BFA5), fontSize: 16)),
            const SizedBox(height: 40),
            Wrap(
              spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
              children: focusModes.map((mode) {
                return InkWell(
                  onTap: () => _startTimerMode(mode['mins'], mode['name']),
                  child: Container(
                    width: 200, 
                    height: 180, // FIX: Increased height from 150 to 180
                    padding: const EdgeInsets.all(15), // FIX: Reduced padding from 20 to 15
                    decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF444444))),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(mode['icon'], style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 10),
                        Text(mode['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text(mode['desc'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 50),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontSize: 16))),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTimerScreen() {
    double progress = targetSeconds > 0 ? (elapsedSeconds / targetSeconds) : 0.0;
    // Wrapped in a SingleChildScrollView for total responsiveness
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(activeModeName.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF00BFA5), fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 3)),
            const SizedBox(height: 50),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 300, height: 300,
                  child: CircularProgressIndicator(value: targetSeconds > 0 ? progress : null, color: const Color(0xFFEBFB7E), backgroundColor: const Color(0xFF252525), strokeWidth: 10),
                ),
                Text(timeString, style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
              ],
            ),
            const SizedBox(height: 50),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () { setState(() { isRunning = !isRunning; if (isRunning) { _startTimerMode(targetSeconds ~/ 60, activeModeName); } else { _timer?.cancel(); }}); },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF252525), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
                  child: Text(isRunning ? "PAUSE" : "RESUME", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: _stopAndLog,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEBFB7E), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
                  child: const Text("FINISH & LOG", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}