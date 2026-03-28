import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_controller.dart';
import '../models/system_data.dart'; 

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  DateTime selectedDate = DateTime.now();
  final TextEditingController taskInputController = TextEditingController();

  String get dateString => selectedDate.toIso8601String().split('T')[0];

  String get displayDate {
    DateTime today = DateTime.now();
    DateTime tomorrow = today.add(const Duration(days: 1));
    DateTime yesterday = today.subtract(const Duration(days: 1));

    String s = dateString;
    if (s == today.toIso8601String().split('T')[0]) return "TODAY";
    if (s == tomorrow.toIso8601String().split('T')[0]) return "TOMORROW";
    if (s == yesterday.toIso8601String().split('T')[0]) return "YESTERDAY";
    return s;
  }

  Future<void> _pickDate(bool isDark, Color accent, Color card, Color text) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: isDark 
            ? ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: accent, onPrimary: Colors.black, surface: card, onSurface: text))
            : ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: accent, onPrimary: Colors.white, surface: card, onSurface: text)),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _showPostponeDialog(SystemController system, String taskId, bool isDark, Color card, Color text, Color accent) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: card,
          title: Text("Postpone Task", style: TextStyle(color: text, fontWeight: FontWeight.bold)),
          content: const Text("When would you like to tackle this?", style: TextStyle(color: Colors.grey)),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () {
                String tmrw = DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0];
                system.postponeTask(taskId, tmrw);
                Navigator.pop(context);
              },
              child: Text("TOMORROW", style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); 
                _pickDate(isDark, accent, card, text).then((_) {
                  system.postponeTask(taskId, dateString);
                });
              },
              child: const Text("PICK DATE...", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  // REFACTORED: Professional Milestone Dialog
  void _showAddMilestoneDialog(SystemController system, bool isDark, Color card, Color inputBg, Color text, Color subText, Color accent) {
    TextEditingController titleCtrl = TextEditingController();
    DateTime raidEnd = DateTime.now().add(const Duration(days: 7));
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: card,
          title: Text("DEFINE MILESTONE", style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl, 
                style: TextStyle(color: text), 
                decoration: InputDecoration(hintText: "Milestone Objective...", hintStyle: TextStyle(color: subText), filled: true, fillColor: inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none))
              ),
              const SizedBox(height: 20),
              Text("Target Deadline:", style: TextStyle(color: subText)),
              TextButton(
                onPressed: () async {
                  DateTime? p = await showDatePicker(
                    context: context, initialDate: raidEnd, firstDate: DateTime.now(), lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: isDark 
                          ? ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: accent, onPrimary: Colors.black, surface: card, onSurface: text))
                          : ThemeData.light().copyWith(colorScheme: ColorScheme.light(primary: accent, onPrimary: Colors.white, surface: card, onSurface: text)),
                        child: child!,
                      );
                    }
                  );
                  if (p != null) setDialogState(() => raidEnd = p);
                },
                child: Text(raidEnd.toIso8601String().split('T')[0], style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: TextStyle(color: subText))),
            ElevatedButton(
              onPressed: () { 
                system.addBossRaid(titleCtrl.text, raidEnd.toIso8601String().split('T')[0]); 
                Navigator.pop(context); 
              }, 
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, elevation: 0), 
              child: const Text("INITIATE", style: TextStyle(fontWeight: FontWeight.bold))
            ),
          ],
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<SystemController>();
    
    final bool isDark = system.systemData.isDarkMode;
    final Color card = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFFFFF);
    final Color altCard = isDark ? const Color(0xFF252525) : const Color(0xFFF9FAFB);
    final Color border = isDark ? const Color(0xFF444444) : const Color(0xFFE2E8F0);
    final Color text = isDark ? Colors.white : const Color(0xFF334155);
    final Color subText = isDark ? Colors.grey : const Color(0xFF94A3B8);
    final Color accent = isDark ? const Color(0xFFEBFB7E) : const Color(0xFF0EA5E9); 
    final Color invertText = isDark ? const Color(0xFF171717) : Colors.white;
    final Color successBg = isDark ? const Color(0xFF1F331F) : const Color(0xFFECFDF5);
    final Color postponeBg = isDark ? const Color(0xFF332A1F) : const Color(0xFFFFF7ED);
    final Color inputBg = isDark ? const Color(0xFF171717) : const Color(0xFFEDF2F7);

    // =========================================================================
    // EXTREME LOSS AVERSION: REFACTORED ACCOUNTABILITY LOCK
    // =========================================================================
    if (system.systemData.isPenaltyActive) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A0505) : const Color(0xFFFEF2F2), 
          borderRadius: BorderRadius.circular(10), 
          border: Border.all(color: const Color(0xFFFF5555), width: 3)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_clock, color: Color(0xFFFF5555), size: 80),
            const SizedBox(height: 20),
            const Text("ACCOUNTABILITY LOCK", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFF5555), fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 3)),
            const SizedBox(height: 10),
            Text("You missed your mandatory daily tasks yesterday.", textAlign: TextAlign.center, style: TextStyle(color: subText, fontSize: 14)),
            const SizedBox(height: 40),
            Text("REQUIRED ACTION:\nComplete 100 Pushups & Study 1 Extra Hour.", textAlign: TextAlign.center, style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () => system.clearPenaltyZone(),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5555), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20), elevation: 0),
              child: const Text("I HAVE COMPLETED THE REVIEW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            )
          ],
        ),
      );
    }

    var activeTasks = system.systemData.dailyTasks.where((t) => t.date == dateString).toList();
    var activeRaids = system.systemData.bossRaids.where((r) => r.status == 'active').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =====================================================================
        // STRATEGIC MILESTONES (Formerly Boss Raids)
        // =====================================================================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("STRATEGIC MILESTONES", style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ElevatedButton(
              onPressed: () => _showAddMilestoneDialog(system, isDark, card, inputBg, text, subText, accent), 
              style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, elevation: 0), 
              child: const Text("+ NEW MILESTONE", style: TextStyle(fontWeight: FontWeight.bold))
            )
          ],
        ),
        const SizedBox(height: 15),
        if (activeRaids.isEmpty) Text("No active milestones. Set a strategic target to begin.", style: TextStyle(color: subText, fontStyle: FontStyle.italic)),
        if (activeRaids.isNotEmpty)
          SizedBox(
            height: 125,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: activeRaids.length,
              itemBuilder: (context, index) {
                var raid = activeRaids[index];
                int daysLeft = DateTime.parse(raid.deadlineDate).difference(DateTime.now()).inDays;
                
                return Container(
                  width: 250, margin: const EdgeInsets.only(right: 15), padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(10), border: Border.all(color: accent, width: 2)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(raid.title, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Text(daysLeft >= 0 ? "$daysLeft DAYS REMAINING" : "DEADLINE MISSED", style: TextStyle(color: daysLeft >= 0 ? accent : const Color(0xFFFF5555), fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: ElevatedButton(onPressed: () => system.resolveRaid(raid.id, 'won'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5), foregroundColor: Colors.white, elevation: 0, padding: EdgeInsets.zero), child: const Text("ACHIEVED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                          const SizedBox(width: 5),
                          Expanded(child: ElevatedButton(onPressed: () => system.resolveRaid(raid.id, 'failed'), style: ElevatedButton.styleFrom(backgroundColor: border, foregroundColor: text, elevation: 0, padding: EdgeInsets.zero), child: const Text("ABANDON", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        
        const SizedBox(height: 25),
        Divider(color: border),
        const SizedBox(height: 15),

        // =====================================================================
        // STANDARD TASK BOARD
        // =====================================================================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("DAILY TASKS", style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            
            Container(
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.chevron_left, color: text), onPressed: () => setState(() => selectedDate = selectedDate.subtract(const Duration(days: 1)))),
                  InkWell(
                    onTap: () => _pickDate(isDark, accent, card, text), 
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: Text(displayDate, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1))),
                  ),
                  IconButton(icon: Icon(Icons.chevron_right, color: text), onPressed: () => setState(() => selectedDate = selectedDate.add(const Duration(days: 1)))),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: taskInputController, style: TextStyle(color: text),
                decoration: InputDecoration(hintText: "Add a task for $displayDate...", hintStyle: TextStyle(color: subText), filled: true, fillColor: inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none)),
                onSubmitted: (value) { system.addDailyTask(value, dateString); taskInputController.clear(); }
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () { system.addDailyTask(taskInputController.text, dateString); taskInputController.clear(); }, 
              child: Container(width: 55, height: 55, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(5)), child: Center(child: Text("+", style: TextStyle(color: invertText, fontSize: 28, fontWeight: FontWeight.bold)))),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Expanded(
          child: activeTasks.isEmpty
              ? Center(child: Text(displayDate == "TODAY" ? "No tasks assigned for today. You are caught up." : "No data found for $dateString.", style: TextStyle(color: subText, fontStyle: FontStyle.italic)))
              : ListView.builder(
                  itemCount: activeTasks.length,
                  itemBuilder: (context, index) {
                    var task = activeTasks[index];
                    bool isCompleted = task.status == 'completed';
                    bool isPostponed = task.status == 'postponed';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isCompleted ? successBg : isPostponed ? postponeBg : altCard, 
                        borderRadius: BorderRadius.circular(8), 
                        border: Border.all(color: isCompleted ? const Color(0xFF2E7D32) : isPostponed ? const Color(0xFFFF9800) : border)
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isCompleted, activeColor: accent, checkColor: invertText, 
                            onChanged: isPostponed ? null : (val) { system.updateTaskStatus(task.id, val == true ? 'completed' : 'pending'); }
                          ),
                          Expanded(
                            child: Text(
                              task.text, 
                              style: TextStyle(color: isCompleted || isPostponed ? subText : text, fontSize: 16, decoration: isCompleted || isPostponed ? TextDecoration.lineThrough : null)
                            )
                          ),
                          
                          if (!isCompleted && !isPostponed) 
                            IconButton(icon: const Icon(Icons.schedule, size: 20), color: const Color(0xFFFF9800), tooltip: "Postpone", onPressed: () => _showPostponeDialog(system, task.id, isDark, card, text, accent)),
                            
                          IconButton(icon: const Icon(Icons.delete_outline, size: 20), color: const Color(0xFFFF5555), tooltip: "Erase", onPressed: () => system.deleteTask(task.id)),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}