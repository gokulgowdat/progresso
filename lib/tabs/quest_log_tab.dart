import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_controller.dart';

class QuestLogTab extends StatefulWidget {
  const QuestLogTab({super.key});

  @override
  State<QuestLogTab> createState() => _QuestLogTabState();
}

class _QuestLogTabState extends State<QuestLogTab> {
  DateTime selectedDate = DateTime.now();
  final TextEditingController learnController = TextEditingController();
  final TextEditingController exerciseController = TextEditingController();

  String get dateString => selectedDate.toIso8601String().split('T')[0];

  @override
  Widget build(BuildContext context) {
    final system = context.watch<SystemController>();

    // --- DYNAMIC THEME COLORS ---
    final bool isDark = system.systemData.isDarkMode;
    final Color card = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFFFFF);
    final Color border = isDark ? const Color(0xFF444444) : const Color(0xFFE2E8F0);
    final Color text = isDark ? Colors.white : const Color(0xFF334155);
    final Color subText = isDark ? Colors.grey : const Color(0xFF94A3B8);
    final Color accent = isDark ? const Color(0xFFEBFB7E) : const Color(0xFF0EA5E9); 
    final Color invertText = isDark ? const Color(0xFF171717) : Colors.white;
    final Color inputBg = isDark ? const Color(0xFF171717) : const Color(0xFFEDF2F7);

    var dayTasks = system.systemData.dailyTasks.where((t) => t.date == dateString).toList();
    var completedTasks = dayTasks.where((t) => t.status == 'completed').toList();
    var postponedTasks = dayTasks.where((t) => t.status == 'postponed').toList();
    var completedSkills = system.getCompletedSkillsForDate(dateString);

    // --- MODULE 1: CALENDAR ---
    Widget calendarModule = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SYSTEM CALENDAR", style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
          child: Theme(
            data: isDark 
              ? ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: accent, onPrimary: Colors.black, surface: card, onSurface: text))
              : ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: accent, onPrimary: Colors.white, surface: card, onSurface: text)),
            child: CalendarDatePicker(
              initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100),
              onDateChanged: (newDate) => setState(() => selectedDate = newDate),
            ),
          ),
        ),
      ],
    );

    // --- MODULE 2: HEATMAP ---
    Widget heatmapModule = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("CONSISTENCY MATRIX", style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 15),
        _buildInteractiveHeatmap(system, isDark, card, border, accent, text),
      ],
    );

    // --- MODULE 3: MANUAL LOGGING ---
    Widget loggingModule = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("MANUAL LOGGING", style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
          child: Column(
            children: [
              Text("Logging time for: $dateString", style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.psychology, color: Color(0xFF00BFA5)),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: learnController, keyboardType: TextInputType.number, style: TextStyle(color: text), decoration: InputDecoration(labelText: "Learning / Work Hours", labelStyle: TextStyle(color: subText), filled: true, fillColor: inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none)))),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(Icons.fitness_center, color: Color(0xFF9C27B0)),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: exerciseController, keyboardType: TextInputType.number, style: TextStyle(color: text), decoration: InputDecoration(labelText: "Exercise Hours", labelStyle: TextStyle(color: subText), filled: true, fillColor: inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none)))),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  system.commitManualLog(dateString, double.tryParse(learnController.text) ?? 0.0, double.tryParse(exerciseController.text) ?? 0.0);
                  learnController.clear(); exerciseController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Log Committed Successfully.", style: TextStyle(color: invertText)), backgroundColor: accent));
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: accent, foregroundColor: invertText),
                child: const Text("COMMIT LOG", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ],
    );

    // --- MODULE 4: ARCHIVE SUMMARY ---
    Widget archiveModule = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("ARCHIVE: $dateString", style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20), width: double.infinity,
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("🧠 Learn Hours: ${(system.systemData.hoursWorkedDict[dateString] ?? 0.0).toStringAsFixed(2)}", style: TextStyle(color: text, fontSize: 16)),
              const SizedBox(height: 5),
              Text("🏋️ Exercise Hours: ${(system.systemData.exerciseHoursDict[dateString] ?? 0.0).toStringAsFixed(2)}", style: TextStyle(color: text, fontSize: 16)),
              Divider(color: border, height: 30),
              
              const Text("Completed Quests & Skills:", style: TextStyle(color: Color(0xFF00BFA5), fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (completedTasks.isEmpty && completedSkills.isEmpty) Text("None", style: TextStyle(color: subText, fontStyle: FontStyle.italic)),
              ...completedTasks.map((t) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(children: [const Icon(Icons.check, color: Color(0xFF00BFA5), size: 16), const SizedBox(width: 10), Expanded(child: Text(t.text, style: TextStyle(color: text, decoration: TextDecoration.lineThrough)))]) )),
              ...completedSkills.map((s) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(children: [const Icon(Icons.bolt, color: Color(0xFF00BFA5), size: 16), const SizedBox(width: 10), Expanded(child: Text("[Skill] ${s.name}", style: TextStyle(color: text, decoration: TextDecoration.lineThrough)))]) )),

              const SizedBox(height: 20),

              const Text("Postponed Quests:", style: TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (postponedTasks.isEmpty) Text("None", style: TextStyle(color: subText, fontStyle: FontStyle.italic)),
              ...postponedTasks.map((t) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(children: [const Icon(Icons.schedule, color: Color(0xFFFF9800), size: 16), const SizedBox(width: 10), Expanded(child: Text(t.text, style: TextStyle(color: subText)))]) )),
            ],
          ),
        ),
      ],
    );

    // =========================================================================
    // RESPONSIVE LAYOUT ENGINE
    // =========================================================================
    bool isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      // 📱 MOBILE LAYOUT: Vertical Stack
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            calendarModule,
            const SizedBox(height: 30),
            archiveModule,
            const SizedBox(height: 30),
            loggingModule,
            const SizedBox(height: 30),
            heatmapModule,
            const SizedBox(height: 40), // Bottom scroll clearance
          ],
        ),
      );
    } else {
      // 💻 PC DESKTOP LAYOUT: Side-by-Side Columns
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [calendarModule, const SizedBox(height: 30), heatmapModule, const SizedBox(height: 20)],
              ),
            ),
          ),
          const SizedBox(width: 30),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [loggingModule, const SizedBox(height: 30), archiveModule, const SizedBox(height: 20)],
              ),
            ),
          )
        ],
      );
    }
  }

  Widget _buildInteractiveHeatmap(SystemController system, bool isDark, Color card, Color border, Color accent, Color text) {
    List<DateTime> last84Days = List.generate(84, (index) => DateTime.now().subtract(Duration(days: 83 - index)));
    
    Color getIntensityColor(double hours) {
      if (hours == 0) return isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE2E8F0); 
      if (hours <= 1.0) return const Color(0xFF2E4C2E); 
      if (hours <= 3.0) return const Color(0xFF388E3C); 
      if (hours <= 5.0) return const Color(0xFF4CAF50); 
      return accent; 
    }

    return Container(
      width: double.infinity, // Stretch heatmap to fill card perfectly
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: last84Days.map((date) {
          String boxDateStr = date.toIso8601String().split('T')[0];
          double hoursLogged = (system.systemData.hoursWorkedDict[boxDateStr] ?? 0.0) + (system.systemData.exerciseHoursDict[boxDateStr] ?? 0.0);
          bool isSelected = boxDateStr == dateString;

          return Tooltip(
            message: "$boxDateStr: ${hoursLogged.toStringAsFixed(1)} hrs",
            child: InkWell(
              onTap: () => setState(() => selectedDate = date),
              child: Container(
                width: 25, height: 25, 
                decoration: BoxDecoration(
                  color: getIntensityColor(hoursLogged), 
                  borderRadius: BorderRadius.circular(4), 
                  border: Border.all(
                    color: isSelected ? text : (isDark ? const Color(0xFF333333) : Colors.transparent), 
                    width: isSelected ? 2 : 1
                  )
                )
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}