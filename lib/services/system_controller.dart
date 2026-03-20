import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../models/system_data.dart';
import '../models/skill_node.dart';
import '../models/task_model.dart';
import '../models/badge_model.dart';
import 'storage_engine.dart';
import 'sync_engine.dart';

class ProgressResult {
  final double completed;
  final double total;
  ProgressResult(this.completed, this.total);
}

class SystemController extends ChangeNotifier {
  final StorageEngine _storage = StorageEngine();
  final SyncEngine syncEngine = SyncEngine();
  
  SystemData systemData = SystemData();
  bool isInitialized = false;
  
  bool isLoggedIn = false;
  String currentQuote = "";
  String syncStatusMessage = "";

  final List<String> quoteLibrary = [
    "\"I'll leave tomorrow's problems to tomorrow's me.\" - Saitama",
    "\"Human strength lies in the ability to change yourself.\" - Saitama",
    "\"If you don't want to get beaten, get stronger.\" - Sung Jin-Woo",
    "\"I alone level up.\" - Sung Jin-Woo",
    "\"To win, you must be willing to sacrifice everything.\" - Ayanokoji Kiyotaka",
    "\"Equality is a false concept, but our inequality allows us to grow.\" - Ayanokoji Kiyotaka",
    "\"He who conquers himself is the mightiest warrior.\" - Confucius",
    "\"Discipline equals freedom.\" - Jocko Willink",
    "\"Don't stop when you're tired. Stop when you're done.\" - David Goggins",
    "\"He who sweats more in training bleeds less in war.\" - Spartan Proverb",
    "\"No matter how hard or impossible it is, never lose sight of your goal.\" - Monkey D. Luffy",
    "\"A dropout will beat a genius through hard work.\" - Rock Lee",
    "\"Blood, sweat, and respect. First two you give, last one you earn.\" - Dwayne Johnson",
    "\"I hated every minute of training, but I said, 'Don't quit. Suffer now and live the rest of your life as a champion.'\" - Muhammad Ali"
  ];

  final List<SystemBadge> badgeLibrary = [
    SystemBadge(id: "sys_init", icon: "🌱", title: "Genesis", description: "Initialize the system."),
    SystemBadge(id: "sys_first_task", icon: "📝", title: "To-Do", description: "Write your first quest."),
    SystemBadge(id: "sys_focus", icon: "⏱️", title: "Deep Work", description: "Launch the Focus Timer for the first time."),
    SystemBadge(id: "sys_postpone", icon: "🕰️", title: "Tactical Delay", description: "Postpone a task to a better date."),
    SystemBadge(id: "gp_1", icon: "🥉", title: "F-Rank", description: "Reach 1% Global Progress."),
    SystemBadge(id: "gp_5", icon: "🥉", title: "E-Rank", description: "Reach 5% Global Progress."),
    SystemBadge(id: "gp_10", icon: "🥈", title: "D-Rank", description: "Reach 10% Global Progress."),
    SystemBadge(id: "gp_15", icon: "🥈", title: "C-Rank", description: "Reach 15% Global Progress."),
    SystemBadge(id: "gp_20", icon: "🥇", title: "B-Rank", description: "Reach 20% Global Progress."),
    SystemBadge(id: "gp_30", icon: "🥇", title: "A-Rank", description: "Reach 30% Global Progress."),
    SystemBadge(id: "gp_40", icon: "💎", title: "S-Rank", description: "Reach 40% Global Progress."),
    SystemBadge(id: "gp_50", icon: "💎", title: "Halfway", description: "Reach 50% Global Progress."),
    SystemBadge(id: "gp_60", icon: "🌟", title: "SS-Rank", description: "Reach 60% Global Progress."),
    SystemBadge(id: "gp_70", icon: "🌟", title: "SSS-Rank", description: "Reach 70% Global Progress."),
    SystemBadge(id: "gp_80", icon: "👑", title: "National Level", description: "Reach 80% Global Progress."),
    SystemBadge(id: "gp_90", icon: "👑", title: "Monarch", description: "Reach 90% Global Progress."),
    SystemBadge(id: "gp_99", icon: "🌌", title: "The Limit", description: "Reach 99% Global Progress."),
    SystemBadge(id: "gp_100", icon: "♾️", title: "Absolute", description: "Reach 100% Global Progress."),
    SystemBadge(id: "dm_1", icon: "📜", title: "Specialist", description: "Master 1 complete domain (100%)."),
    SystemBadge(id: "dm_2", icon: "📜", title: "Dualist", description: "Master 2 domains."),
    SystemBadge(id: "dm_3", icon: "📜", title: "Triad", description: "Master 3 domains."),
    SystemBadge(id: "dm_4", icon: "📜", title: "Quartet", description: "Master 4 domains."),
    SystemBadge(id: "dm_5", icon: "🎖️", title: "Vanguard", description: "Master 5 domains."),
    SystemBadge(id: "dm_6", icon: "🎖️", title: "Hexagon", description: "Master 6 domains."),
    SystemBadge(id: "dm_7", icon: "🎖️", title: "Heptagon", description: "Master 7 domains."),
    SystemBadge(id: "dm_8", icon: "🎖️", title: "Octagon", description: "Master 8 domains."),
    SystemBadge(id: "dm_9", icon: "🎖️", title: "Enigma", description: "Master 9 domains."),
    SystemBadge(id: "dm_10", icon: "🏅", title: "Expert", description: "Master 10 domains."),
    SystemBadge(id: "dm_15", icon: "🏅", title: "Elite", description: "Master 15 domains."),
    SystemBadge(id: "dm_20", icon: "🏆", title: "Master", description: "Master 20 domains."),
    SystemBadge(id: "dm_25", icon: "🏆", title: "Grandmaster", description: "Master 25 domains."),
    SystemBadge(id: "dm_50", icon: "👑", title: "God of Knowledge", description: "Master 50 domains."),
    SystemBadge(id: "t_1", icon: "✅", title: "Squire", description: "Complete 1 Quest."),
    SystemBadge(id: "t_5", icon: "✅", title: "Recruit", description: "Complete 5 Quests."),
    SystemBadge(id: "t_10", icon: "✅", title: "Page", description: "Complete 10 Quests."),
    SystemBadge(id: "t_25", icon: "✅", title: "Grunt", description: "Complete 25 Quests."),
    SystemBadge(id: "t_50", icon: "✅", title: "Mercenary", description: "Complete 50 Quests."),
    SystemBadge(id: "t_100", icon: "✅", title: "Soldier", description: "Complete 100 Quests."),
    SystemBadge(id: "t_250", icon: "⚔️", title: "Veteran", description: "Complete 250 Quests."),
    SystemBadge(id: "t_500", icon: "⚔️", title: "Knight", description: "Complete 500 Quests."),
    SystemBadge(id: "t_750", icon: "⚔️", title: "Captain", description: "Complete 750 Quests."),
    SystemBadge(id: "t_1000", icon: "🛡️", title: "Commander", description: "Complete 1,000 Quests."),
    SystemBadge(id: "t_1500", icon: "🛡️", title: "General", description: "Complete 1,500 Quests."),
    SystemBadge(id: "t_2500", icon: "🛡️", title: "Warlord", description: "Complete 2,500 Quests."),
    SystemBadge(id: "t_5000", icon: "🏰", title: "Conqueror", description: "Complete 5,000 Quests."),
    SystemBadge(id: "t_10000", icon: "👑", title: "Emperor", description: "Complete 10,000 Quests."),
    SystemBadge(id: "l_1", icon: "🧠", title: "Student", description: "Log 1 Learn Hour."),
    SystemBadge(id: "l_5", icon: "🧠", title: "Reader", description: "Log 5 Learn Hours."),
    SystemBadge(id: "l_10", icon: "🧠", title: "Pupil", description: "Log 10 Learn Hours."),
    SystemBadge(id: "l_25", icon: "🧠", title: "Apprentice", description: "Log 25 Learn Hours."),
    SystemBadge(id: "l_50", icon: "📖", title: "Scholar", description: "Log 50 Learn Hours."),
    SystemBadge(id: "l_100", icon: "📖", title: "Academic", description: "Log 100 Learn Hours."),
    SystemBadge(id: "l_250", icon: "📖", title: "Philosopher", description: "Log 250 Learn Hours."),
    SystemBadge(id: "l_500", icon: "📚", title: "Thinker", description: "Log 500 Learn Hours."),
    SystemBadge(id: "l_750", icon: "📚", title: "Intellect", description: "Log 750 Learn Hours."),
    SystemBadge(id: "l_1000", icon: "💡", title: "Polymath", description: "Log 1,000 Learn Hours."),
    SystemBadge(id: "l_1500", icon: "💡", title: "Genius", description: "Log 1,500 Learn Hours."),
    SystemBadge(id: "l_2500", icon: "👁️", title: "Sage", description: "Log 2,500 Learn Hours."),
    SystemBadge(id: "l_5000", icon: "👁️", title: "Oracle", description: "Log 5,000 Learn Hours."),
    SystemBadge(id: "l_10000", icon: "🌌", title: "Omniscient", description: "Log 10,000 Learn Hours."),
    SystemBadge(id: "e_1", icon: "🏋️", title: "Jogger", description: "Log 1 Exercise Hour."),
    SystemBadge(id: "e_5", icon: "🏋️", title: "Runner", description: "Log 5 Exercise Hours."),
    SystemBadge(id: "e_10", icon: "🏋️", title: "Athlete", description: "Log 10 Exercise Hours."),
    SystemBadge(id: "e_25", icon: "🏋️", title: "Lifter", description: "Log 25 Exercise Hours."),
    SystemBadge(id: "e_50", icon: "🥊", title: "Gym Rat", description: "Log 50 Exercise Hours."),
    SystemBadge(id: "e_100", icon: "🥊", title: "Warrior", description: "Log 100 Exercise Hours."),
    SystemBadge(id: "e_250", icon: "🥊", title: "Fighter", description: "Log 250 Exercise Hours."),
    SystemBadge(id: "e_500", icon: "🦾", title: "Spartan", description: "Log 500 Exercise Hours."),
    SystemBadge(id: "e_750", icon: "🦾", title: "Gladiator", description: "Log 750 Exercise Hours."),
    SystemBadge(id: "e_1000", icon: "🦍", title: "Beast", description: "Log 1,000 Exercise Hours."),
    SystemBadge(id: "e_1500", icon: "🦍", title: "Monster", description: "Log 1,500 Exercise Hours."),
    SystemBadge(id: "e_2500", icon: "🗿", title: "Titan", description: "Log 2,500 Exercise Hours."),
    SystemBadge(id: "e_5000", icon: "🗿", title: "Hercules", description: "Log 5,000 Exercise Hours."),
    SystemBadge(id: "e_10000", icon: "⚡", title: "God of War", description: "Log 10,000 Exercise Hours."),
    SystemBadge(id: "s_3", icon: "🔥", title: "Spark", description: "3 Day Streak."),
    SystemBadge(id: "s_7", icon: "🔥", title: "Ember", description: "7 Day Streak."),
    SystemBadge(id: "s_14", icon: "🔥", title: "Flame", description: "14 Day Streak."),
    SystemBadge(id: "s_21", icon: "🔥", title: "Campfire", description: "21 Day Streak."),
    SystemBadge(id: "s_30", icon: "🔥", title: "Blaze", description: "30 Day Streak."),
    SystemBadge(id: "s_50", icon: "☄️", title: "Wildfire", description: "50 Day Streak."),
    SystemBadge(id: "s_75", icon: "☄️", title: "Inferno", description: "75 Day Streak."),
    SystemBadge(id: "s_100", icon: "☄️", title: "Century", description: "100 Day Streak."),
    SystemBadge(id: "s_150", icon: "🌋", title: "Magma", description: "150 Day Streak."),
    SystemBadge(id: "s_200", icon: "🌋", title: "Eruption", description: "200 Day Streak."),
    SystemBadge(id: "s_365", icon: "☀️", title: "One Year", description: "365 Day Streak."),
    SystemBadge(id: "s_500", icon: "☀️", title: "Comet", description: "500 Day Streak."),
    SystemBadge(id: "s_750", icon: "🌟", title: "Supernova", description: "750 Day Streak."),
    SystemBadge(id: "s_1000", icon: "🌌", title: "Millennium", description: "1,000 Day Streak."),
    SystemBadge(id: "h_10", icon: "⏳", title: "Time Ticker", description: "Log 10 Total Hours."),
    SystemBadge(id: "h_50", icon: "⏳", title: "Dedicated", description: "Log 50 Total Hours."),
    SystemBadge(id: "h_100", icon: "⏳", title: "Committed", description: "Log 100 Total Hours."),
    SystemBadge(id: "h_250", icon: "⌛", title: "Driven", description: "Log 250 Total Hours."),
    SystemBadge(id: "h_500", icon: "⌛", title: "Relentless", description: "Log 500 Total Hours."),
    SystemBadge(id: "h_1000", icon: "⌛", title: "Obsessed", description: "Log 1,000 Total Hours."),
    SystemBadge(id: "h_2000", icon: "🕰️", title: "Veteran", description: "Log 2,000 Total Hours."),
    SystemBadge(id: "h_3000", icon: "🕰️", title: "Expert", description: "Log 3,000 Total Hours."),
    SystemBadge(id: "h_4000", icon: "🕰️", title: "Master", description: "Log 4,000 Total Hours."),
    SystemBadge(id: "h_5000", icon: "⚙️", title: "Machine", description: "Log 5,000 Total Hours."),
    SystemBadge(id: "h_7500", icon: "⚙️", title: "Cyborg", description: "Log 7,500 Total Hours."),
    SystemBadge(id: "h_10000", icon: "💎", title: "Ten Thousand", description: "Log 10,000 Total Hours."),
    SystemBadge(id: "h_15000", icon: "💎", title: "Immortal", description: "Log 15,000 Total Hours."),
    SystemBadge(id: "h_20000", icon: "👑", title: "Time Lord", description: "Log 20,000 Total Hours."),
  ];

  Future<void> initializeSystem() async {
    systemData = await _storage.loadState();
    if(quoteLibrary.isNotEmpty) currentQuote = quoteLibrary[Random().nextInt(quoteLibrary.length)];
    if (hasAccount() && systemData.stayLoggedIn) isLoggedIn = true;
    _autoPostponeAndCheckPenalty();
    _evaluateRaids();               
    await syncEngine.startHosting(systemData);
    recalculateSystem();
    isInitialized = true;
    notifyListeners();
  }

  // --- THE PENALTY ZONE LOGIC ---
  void _autoPostponeAndCheckPenalty() {
    String today = DateTime.now().toIso8601String().split('T')[0];
    bool failedTaskDetected = false;

    for (var task in systemData.dailyTasks) {
      if (task.status == 'pending' && task.date.compareTo(today) < 0) {
        failedTaskDetected = true; 
        task.date = today; 
      }
    }
    // ONLY lock the user out if they have Hard Mode enabled
    if (failedTaskDetected && systemData.isPenaltyEnabled) {
      systemData.isPenaltyActive = true; 
    }
  }

  void clearPenaltyZone() {
    systemData.isPenaltyActive = false;
    recalculateSystem();
  }

  // NEW: Toggle Hard Mode
  void togglePenaltyMode() {
    systemData.isPenaltyEnabled = !systemData.isPenaltyEnabled;
    if (!systemData.isPenaltyEnabled) {
      systemData.isPenaltyActive = false; // Instantly disable lockout if turning off
    }
    recalculateSystem();
  }

  // --- RPG STATUS WINDOW MATH ---
  double get statSTR => systemData.exerciseHoursDict.values.fold(0.0, (a, b) => a + b);
  double get statINT => systemData.hoursWorkedDict.values.fold(0.0, (a, b) => a + b);
  double get statAGI => systemData.dailyTasks.where((t) => t.status == 'completed').length.toDouble();
  double get statWIL => currentStreak.toDouble() * 5.0; 

  // --- BOSS RAIDS LOGIC ---
  void addBossRaid(String title, String deadline) {
    if (title.isNotEmpty) {
      systemData.bossRaids.add(BossRaid(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title, deadlineDate: deadline));
      recalculateSystem();
    }
  }

  void resolveRaid(String id, String status) {
    systemData.bossRaids.firstWhere((r) => r.id == id).status = status;
    recalculateSystem();
  }

  void _evaluateRaids() {
    String today = DateTime.now().toIso8601String().split('T')[0];
    for (var raid in systemData.bossRaids) {
      if (raid.status == 'active' && raid.deadlineDate.compareTo(today) < 0) {
        raid.status = 'failed'; 
      }
    }
  }

  String _hashPassword(String password) => sha256.convert(utf8.encode(password)).toString();
  bool hasAccount() => systemData.username.isNotEmpty && systemData.passwordHash.isNotEmpty;
  
  bool registerUser(String username, String password) {
    if (username.isEmpty || password.isEmpty) return false;
    systemData.username = username;
    systemData.passwordHash = _hashPassword(password);
    systemData.stayLoggedIn = true;
    isLoggedIn = true;
    _storage.saveState(systemData);
    notifyListeners();
    return true;
  }

  bool loginUser(String username, String password) {
    if (username == systemData.username && _hashPassword(password) == systemData.passwordHash) {
      systemData.stayLoggedIn = true;
      isLoggedIn = true;
      _storage.saveState(systemData);
      notifyListeners();
      return true;
    }
    return false;
  }

  void logoutUser() {
    systemData.stayLoggedIn = false;
    isLoggedIn = false;
    _storage.saveState(systemData);
    notifyListeners();
  }

  void masterReset() {
    systemData = SystemData();
    isLoggedIn = false;
    _storage.saveState(systemData); 
    notifyListeners();
  }

  void updateCredentials(String newUsername, String newPassword) {
    if (newUsername.isNotEmpty && newPassword.isNotEmpty) {
      systemData.username = newUsername;
      systemData.passwordHash = _hashPassword(newPassword);
      syncStatusMessage = "SECURITY: Credentials updated successfully.";
      _storage.saveState(systemData);
      notifyListeners();
    }
  }

  void updateProfile(String name, String desc, String photoUrl) {
    systemData.profileName = name;
    systemData.profileDesc = desc;
    systemData.profilePhotoUrl = photoUrl;
    recalculateSystem();
  }

  void toggleTheme() { systemData.isDarkMode = !systemData.isDarkMode; recalculateSystem(); }
  void toggleViewMode() { systemData.isCardView = !systemData.isCardView; recalculateSystem(); }

  // --- IMPORT / EXPORT ENGINE ---
  Future<void> exportData(String path) async {
    try {
      final file = File(path);
      final jsonString = jsonEncode(systemData.toJson());
      await file.writeAsString(jsonString);
      syncStatusMessage = "EXPORT SUCCESS: Saved to $path";
      notifyListeners();
    } catch (e) {
      syncStatusMessage = "EXPORT ERROR: $e";
      notifyListeners();
    }
  }

  Future<void> importData(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        syncStatusMessage = "IMPORT ERROR: File not found.";
        notifyListeners();
        return;
      }
      final jsonString = await file.readAsString();
      systemData = SystemData.fromJson(jsonDecode(jsonString));
      _storage.saveState(systemData);
      syncStatusMessage = "IMPORT SUCCESS: Vault restored.";
      recalculateSystem();
    } catch (e) {
      syncStatusMessage = "IMPORT ERROR: Invalid .PRG file.";
      notifyListeners();
    }
  }

  int get currentStreak {
    int streak = 0;
    DateTime checkDate = DateTime.now();
    String dateStr = checkDate.toIso8601String().split('T')[0];

    double hoursToday = (systemData.hoursWorkedDict[dateStr] ?? 0.0) + (systemData.exerciseHoursDict[dateStr] ?? 0.0);
    if (hoursToday == 0.0) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      dateStr = checkDate.toIso8601String().split('T')[0];
      if (((systemData.hoursWorkedDict[dateStr] ?? 0.0) + (systemData.exerciseHoursDict[dateStr] ?? 0.0)) == 0.0) return 0;
    }

    while (true) {
      dateStr = checkDate.toIso8601String().split('T')[0];
      double h = (systemData.hoursWorkedDict[dateStr] ?? 0.0) + (systemData.exerciseHoursDict[dateStr] ?? 0.0);
      if (h > 0.0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else { break; }
    }
    return streak;
  }

  void _evaluateAchievements() {
    List<String> newlyUnlocked = [];
    void unlock(String id) { if (!systemData.badgesUnlocked.contains(id)) newlyUnlocked.add(id); }

    if (systemData.skills.isNotEmpty) unlock("sys_init");
    if (systemData.dailyTasks.isNotEmpty) unlock("sys_first_task");
    if (systemData.dailyTasks.any((t) => t.status == 'postponed')) unlock("sys_postpone");

    int sCount = 0;
    for (var node in systemData.skills) {
      if (node.progress >= 100) sCount++;
    }
    
    var gp = [1, 5, 10, 15, 20, 30, 40, 50, 60, 70, 80, 90, 99, 100];
    for (var v in gp) { if (systemData.globalProgress >= v) unlock("gp_$v"); }

    var dm = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 50];
    for (var v in dm) { if (sCount >= v) unlock("dm_$v"); }

    int tCount = systemData.dailyTasks.where((task) => task.status == 'completed').length;
    var tArr = [1, 5, 10, 25, 50, 100, 250, 500, 750, 1000, 1500, 2500, 5000, 10000];
    for (var v in tArr) { if (tCount >= v) unlock("t_$v"); }

    double lh = systemData.hoursWorkedDict.values.fold(0.0, (sum, val) => sum + val);
    var lArr = [1, 5, 10, 25, 50, 100, 250, 500, 750, 1000, 1500, 2500, 5000, 10000];
    for (var v in lArr) { if (lh >= v) unlock("l_$v"); }

    double eh = systemData.exerciseHoursDict.values.fold(0.0, (sum, val) => sum + val);
    var eArr = [1, 5, 10, 25, 50, 100, 250, 500, 750, 1000, 1500, 2500, 5000, 10000];
    for (var v in eArr) { if (eh >= v) unlock("e_$v"); }

    double totalH = lh + eh;
    var hArr = [10, 50, 100, 250, 500, 1000, 2000, 3000, 4000, 5000, 7500, 10000, 15000, 20000];
    for (var v in hArr) { if (totalH >= v) unlock("h_$v"); }

    int str = currentStreak;
    var sArr = [3, 7, 14, 21, 30, 50, 75, 100, 150, 200, 365, 500, 750, 1000];
    for (var v in sArr) { if (str >= v) unlock("s_$v"); }

    if (newlyUnlocked.isNotEmpty) {
      systemData.badgesUnlocked.addAll(newlyUnlocked);
    }
  }

  ProgressResult _calculateNodeProgress(SkillNode node) {
    if (node.type == 'skill') {
      node.progress = node.completed ? 100.0 : 0.0;
      return ProgressResult(node.completed ? 1.0 : 0.0, 1.0);
    } else {
      double comp = 0, tot = 0;
      for (var child in node.children) {
        var res = _calculateNodeProgress(child);
        comp += res.completed;
        tot += res.total;
      }
      node.progress = tot == 0 ? 0.0 : (comp / tot) * 100.0;
      return ProgressResult(comp, tot);
    }
  }

  void renameNode(SkillNode node, String newName) {
    node.name = newName;
    recalculateSystem();
  }

  void recalculateSystem() {
    double globalComp = 0;
    double globalTot = 0;
    for (var node in systemData.skills) {
      var res = _calculateNodeProgress(node);
      globalComp += res.completed;
      globalTot += res.total;
    }
    systemData.globalProgress = globalTot == 0 ? 0.0 : (globalComp / globalTot) * 100.0;
    _evaluateAchievements();
    _evaluateRaids();
    systemData.lastUpdatedEpoch = DateTime.now().millisecondsSinceEpoch;
    if (syncEngine.isHosting) syncEngine.startHosting(systemData); 
    _storage.saveState(systemData);
    notifyListeners();
  }

  void addDomain(String name) { if (name.trim().isNotEmpty) { systemData.skills.add(SkillNode(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, type: 'domain')); recalculateSystem(); } }
  void deleteDomain(String id) { systemData.skills.removeWhere((node) => node.id == id); recalculateSystem(); }
  void addSubNode(SkillNode parent, String name, String type) { if (name.trim().isNotEmpty) { parent.children.add(SkillNode(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, type: type)); recalculateSystem(); } }
  void deleteSubNode(SkillNode parent, String childId) { parent.children.removeWhere((node) => node.id == childId); recalculateSystem(); }
  
  void toggleSkill(SkillNode skill, bool isCompleted) { 
    skill.completed = isCompleted; 
    if (isCompleted) {
      skill.dateCompleted = DateTime.now().toIso8601String().split('T')[0];
    } else {
      skill.dateCompleted = null;
    }
    recalculateSystem(); 
  }

  List<SkillNode> getCompletedSkillsForDate(String dateStr) {
    List<SkillNode> completedSkills = [];
    void traverse(List<SkillNode> nodes) {
      for (var node in nodes) {
        if (node.type == 'skill' && node.completed && node.dateCompleted == dateStr) {
          completedSkills.add(node);
        }
        traverse(node.children);
      }
    }
    traverse(systemData.skills);
    return completedSkills;
  }

  void addDailyTask(String text, String targetDate) { if (text.trim().isNotEmpty) { systemData.dailyTasks.add(DailyTask(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text, date: targetDate, status: 'pending')); recalculateSystem(); } }
  void updateTaskStatus(String id, String newStatus) { systemData.dailyTasks.firstWhere((t) => t.id == id).status = newStatus; recalculateSystem(); }
  void deleteTask(String id) { systemData.dailyTasks.removeWhere((t) => t.id == id); recalculateSystem(); }
  void postponeTask(String id, String targetDate) {
    var task = systemData.dailyTasks.firstWhere((t) => t.id == id);
    task.status = 'postponed'; 
    systemData.dailyTasks.add(DailyTask(id: DateTime.now().millisecondsSinceEpoch.toString(), text: task.text, date: targetDate, status: 'pending'));
    recalculateSystem();
  }

  void commitManualLog(String dateStr, double learnHrs, double exerciseHrs) {
    if (learnHrs > 0) systemData.hoursWorkedDict[dateStr] = (systemData.hoursWorkedDict[dateStr] ?? 0.0) + learnHrs;
    if (exerciseHrs > 0) systemData.exerciseHoursDict[dateStr] = (systemData.exerciseHoursDict[dateStr] ?? 0.0) + exerciseHrs;
    recalculateSystem();
  }

  void logTime(SkillNode skill, double hoursWorked) {
    if (hoursWorked <= 0) return;
    String today = DateTime.now().toIso8601String().split('T')[0];
    skill.timeLogged += hoursWorked;
    skill.dateLogged = today;
    systemData.hoursWorkedDict[today] = (systemData.hoursWorkedDict[today] ?? 0.0) + hoursWorked;
    if (!systemData.badgesUnlocked.contains("sys_focus")) systemData.badgesUnlocked.add("sys_focus");
    recalculateSystem(); 
  }

  Future<void> syncWithDevice(String targetIp) async {
    syncStatusMessage = "Establishing connection to $targetIp...";
    notifyListeners();
    SystemData? remoteData = await syncEngine.fetchRemoteData(targetIp);
    if (remoteData == null) {
      syncStatusMessage = "ERROR: Device not found or blocked by firewall.";
    } else {
      if (remoteData.lastUpdatedEpoch > systemData.lastUpdatedEpoch) {
        systemData = remoteData;
        syncStatusMessage = "SYNC SUCCESS: Loaded newer data from remote device.";
      } else {
        syncStatusMessage = "SYNC COMPLETE: Local data is already up-to-date.";
      }
    }
    recalculateSystem();
  }
}