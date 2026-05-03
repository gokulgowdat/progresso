import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'package:path_provider/path_provider.dart'; 
import '../models/system_data.dart';
import '../models/skill_node.dart';
import '../models/task_model.dart';
import '../models/badge_model.dart';
import 'storage_engine.dart';
import 'sync_engine.dart';
import 'notification_engine.dart'; 
import '../models/mind_map_model.dart';

class ProgressResult {
  final double completed;
  final double total;
  ProgressResult(this.completed, this.total);
}

class SystemController extends ChangeNotifier {
  final StorageEngine _storage = StorageEngine();
  final SyncEngine syncEngine = SyncEngine();
  
  final AudioPlayer audioPlayer = AudioPlayer();
  String currentTrackName = "Offline";
  bool isAudioPlaying = false;
  
  SystemData systemData = SystemData();
  bool isInitialized = false;
  
  bool isLoggedIn = false;
  String currentQuote = "";
  String syncStatusMessage = "";

  Set<String> expandedDomainNodes = {};

  // =========================================================================
  // BULLETPROOF AUDIO ENGINE INITIALIZATION
  // =========================================================================
  SystemController() {
    audioPlayer.onPlayerComplete.listen((_) {
      if (isAudioPlaying) {
        audioPlayer.seek(Duration.zero);
        audioPlayer.resume();
      }
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

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
    
    await NotificationEngine.init();

    if (systemData.noteGroups.isEmpty) {
      systemData.noteGroups = [NoteGroup(id: 'group_general', name: 'General')];
    }

    if(quoteLibrary.isNotEmpty) currentQuote = quoteLibrary[Random().nextInt(quoteLibrary.length)];
    if (hasAccount() && systemData.stayLoggedIn) isLoggedIn = true;
    
    _autoPostponeAndCheckPenalty(); 
    _evaluateRaids();               
    await syncEngine.startHosting(systemData);
    recalculateSystem();
    isInitialized = true;
    notifyListeners();

    _fireDailyBriefing();

    // =========================================================================
    // NATIVE OS ALARM REGISTRATION (Restores alarms if phone reboots)
    // =========================================================================
    for (var blueprint in systemData.recurringTasks) {
      if (blueprint.alertTime.contains(':')) {
        int h = int.parse(blueprint.alertTime.split(':')[0]);
        int m = int.parse(blueprint.alertTime.split(':')[1]);
        
        NotificationEngine.scheduleDailyRecurringQuest(
          id: blueprint.id.hashCode,
          title: "⏰ QUEST ALERT",
          body: "Time to execute: ${blueprint.text}",
          hour: h,
          minute: m,
        );
      }
    }
  }

  // =========================================================================
  // DEVICE IDENTITY ENGINE
  // =========================================================================
  
  void updateDeviceName(String newName) {
    if (newName.trim().isNotEmpty) {
      systemData.deviceName = newName.trim();
      
      // If this device doesn't have a unique hardware tag yet, generate one.
      if (systemData.deviceShortId.isEmpty) {
        systemData.deviceShortId = _generateShortTag();
      }
      
      syncStatusMessage = "IDENTITY UPDATED: Broadcasting as ${systemData.deviceName} #${systemData.deviceShortId}";
      _storage.saveState(systemData);
      notifyListeners();
    }
  }

  String _generateShortTag() {
    const chars = '0123456789ABCDEF';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  String get fullDeviceIdentity {
    if (systemData.deviceShortId.isEmpty) {
      systemData.deviceShortId = _generateShortTag();
      _storage.saveState(systemData);
    }
    return "${systemData.deviceName} #${systemData.deviceShortId}";
  }

  // =========================================================================
  // MINT STICKY NOTES ENGINE
  // =========================================================================

  void addNoteGroup(String name) {
    if (name.trim().isEmpty) return;
    systemData.noteGroups.add(NoteGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(), 
      name: name
    ));
    recalculateSystem();
  }

  void deleteNoteGroup(String groupId) {
    if (systemData.noteGroups.length <= 1) return; 
    systemData.noteGroups.removeWhere((g) => g.id == groupId);
    systemData.stickyNotes.removeWhere((n) => n.groupId == groupId); 
    recalculateSystem();
  }

  void addStickyNote(String groupId, {double x = 50, double y = 50}) {
    systemData.stickyNotes.add(StickyNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      groupId: groupId,
      x: x,
      y: y,
    ));
    recalculateSystem();
  }

  void updateStickyNoteSilent(String id, {String? title, String? text, String? colorHex, double? width, double? height, double? x, double? y}) {
    var index = systemData.stickyNotes.indexWhere((n) => n.id == id);
    if (index != -1) {
      if (title != null) systemData.stickyNotes[index].title = title;
      if (text != null) systemData.stickyNotes[index].text = text;
      if (colorHex != null) systemData.stickyNotes[index].colorHex = colorHex;
      if (width != null) systemData.stickyNotes[index].width = width;
      if (height != null) systemData.stickyNotes[index].height = height;
      if (x != null) systemData.stickyNotes[index].x = x;
      if (y != null) systemData.stickyNotes[index].y = y;
    }
  }

  void saveNotesToVault() {
    _storage.saveState(systemData);
  }

  void deleteStickyNote(String id) {
    systemData.stickyNotes.removeWhere((n) => n.id == id);
    recalculateSystem();
  }

  // =========================================================================
  // AUDIO ENGINE LOGIC
  // =========================================================================

  Future<void> playAudioStream(String url, String trackName) async {
    await audioPlayer.stop();
    await audioPlayer.play(UrlSource(url));
    await audioPlayer.setReleaseMode(ReleaseMode.loop); 
    currentTrackName = trackName;
    isAudioPlaying = true;
    notifyListeners();
  }

  Future<void> playLocalAudio(String filePath, String trackName) async {
    await audioPlayer.stop();
    await audioPlayer.play(DeviceFileSource(filePath));
    await audioPlayer.setReleaseMode(ReleaseMode.loop); 
    currentTrackName = trackName;
    isAudioPlaying = true;
    notifyListeners();
  }

  Future<void> stopAudio() async {
    await audioPlayer.stop();
    currentTrackName = "Offline";
    isAudioPlaying = false;
    notifyListeners();
  }

  void _fireDailyBriefing() {
    String today = DateTime.now().toIso8601String().split('T')[0];
    int tasksToday = systemData.dailyTasks.where((t) => t.date == today && t.status == 'pending').length;
    
    if (tasksToday > 0) {
      NotificationEngine.showInstantNotification(
        id: 0, 
        title: "🔥 System Awake. Rank: $currentStreak", 
        body: "You have $tasksToday pending Quests for today. Time to hunt."
      );
    }
  }

  void _injectRecurringTasksForToday() {
    String today = DateTime.now().toIso8601String().split('T')[0];
    DateTime todayDate = DateTime.parse(today);

    if (systemData.recurringTasks.isEmpty) return;

    for (var blueprint in systemData.recurringTasks) {
      DateTime startDate = DateTime.parse(blueprint.startDate);
      
      if (blueprint.durationDays != null) {
        if (todayDate.difference(startDate).inDays >= blueprint.durationDays!) {
          continue; 
        }
      }

      bool alreadyExistsToday = systemData.dailyTasks.any(
        (task) => task.date == today && task.id == "recur_${blueprint.id}_$today"
      );

      if (!alreadyExistsToday) {
        String newTaskId = "recur_${blueprint.id}_$today";
        var newTask = DailyTask(id: newTaskId, text: blueprint.text, date: today, status: 'pending');
        
        systemData.dailyTasks = List.from(systemData.dailyTasks)..add(newTask);
      }
    }
  }

  void _autoPostponeAndCheckPenalty() {
    _injectRecurringTasksForToday();

    String today = DateTime.now().toIso8601String().split('T')[0];
    bool failedTaskDetected = false;

    for (var task in systemData.dailyTasks) {
      if (task.status == 'pending' && task.date.compareTo(today) < 0) {
        failedTaskDetected = true; 
        task.date = today; 
      }
    }
    
    if (failedTaskDetected && systemData.isPenaltyEnabled) {
      systemData.isPenaltyActive = true; 
      NotificationEngine.showInstantNotification(
        id: 99, 
        title: "☠️ PENALTY ZONE ACTIVATED", 
        body: "You failed to complete yesterday's quests."
      );
    }
  }

  void clearPenaltyZone() {
    systemData.isPenaltyActive = false;
    recalculateSystem();
  }

  void togglePenaltyMode() {
    systemData.isPenaltyEnabled = !systemData.isPenaltyEnabled;
    if (!systemData.isPenaltyEnabled) {
      systemData.isPenaltyActive = false;
    }
    recalculateSystem();
  }

  double get statSTR => systemData.exerciseHoursDict.values.fold(0.0, (a, b) => a + b);
  double get statINT => systemData.hoursWorkedDict.values.fold(0.0, (a, b) => a + b);
  double get statAGI => systemData.dailyTasks.where((t) => t.status == 'completed').length.toDouble();
  double get statWIL => currentStreak.toDouble() * 5.0; 

  void addBossRaid(String title, String deadline) {
    if (title.isNotEmpty) {
      systemData.bossRaids.add(BossRaid(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title, deadlineDate: deadline));
      recalculateSystem();
    }
  }

  // =========================================================================
  // TASK EDITING & GLOBAL FOCUS ENGINE
  // =========================================================================

  void editDailyTask(String id, String newText, String date) {
    if (newText.trim().isEmpty) return;
    
    var index = systemData.dailyTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      systemData.dailyTasks[index].text = newText;
    } else if (id.startsWith('recur_')) {
      systemData.dailyTasks.add(DailyTask(id: id, text: newText, date: date, status: 'pending'));
    }
    recalculateSystem();
  }

  void editBossRaid(String id, String newTitle, String newDeadline) {
    if (newTitle.trim().isEmpty) return;
    
    var index = systemData.bossRaids.indexWhere((r) => r.id == id);
    if (index != -1) {
      systemData.bossRaids[index].title = newTitle;
      systemData.bossRaids[index].deadlineDate = newDeadline;
      recalculateSystem();
    }
  }

  void logGlobalTime(double hoursWorked) {
    if (hoursWorked <= 0) return;
    
    String today = DateTime.now().toIso8601String().split('T')[0];
    systemData.hoursWorkedDict[today] = (systemData.hoursWorkedDict[today] ?? 0.0) + hoursWorked;
    
    if (!systemData.badgesUnlocked.contains("sys_focus")) {
      systemData.badgesUnlocked.add("sys_focus");
    }
    recalculateSystem(); 
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

  Future<void> updateProfile(String name, String desc, String photoUrl) async {
    systemData.profileName = name;
    systemData.profileDesc = desc;
    
    if (photoUrl.isNotEmpty && photoUrl != systemData.profilePhotoUrl && !photoUrl.contains('permanent_avatar')) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final newPath = '${directory.path}/permanent_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final newFile = await File(photoUrl).copy(newPath);
        systemData.profilePhotoUrl = newFile.path;
      } catch (e) {
        print("Failed to save permanent image: $e");
        systemData.profilePhotoUrl = photoUrl;
      }
    } else if (photoUrl.isEmpty) {
      systemData.profilePhotoUrl = "";
    }
    
    recalculateSystem();
  }

  void toggleTheme() {
    systemData.isDarkMode = !systemData.isDarkMode;
    recalculateSystem();
  }

  void toggleViewMode() {
    systemData.isCardView = !systemData.isCardView;
    recalculateSystem();
  }

  // =========================================================================
  // EXPORT / IMPORT ENGINE 
  // =========================================================================

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
      final decoded = jsonDecode(jsonString);

      if (decoded is Map<String, dynamic> && decoded.containsKey('type') && decoded['type'] == 'partial_domain_backup') {
        syncStatusMessage = "IMPORT ERROR: This is a Domain Module backup. Use the Domain Import button below.";
        notifyListeners();
        return;
      }

      systemData = SystemData.fromJson(decoded);
      _storage.saveState(systemData);
      syncStatusMessage = "IMPORT SUCCESS: Vault restored.";
      recalculateSystem();
    } catch (e) {
      syncStatusMessage = "IMPORT ERROR: Invalid .PRG file.";
      notifyListeners();
    }
  }

  Future<void> exportSpecificDomains(List<String> domainIds, String path) async {
    try {
      final file = File(path);
      var exportList = systemData.skills.where((d) => domainIds.contains(d.id)).toList();
      
      Map<String, dynamic> payload = {
        'type': 'partial_domain_backup',
        'domains': exportList.map((d) => d.toJson()).toList(),
      };

      await file.writeAsString(jsonEncode(payload));
      syncStatusMessage = "EXPORT SUCCESS: Domain Modules saved.";
      notifyListeners();
    } catch (e) {
      syncStatusMessage = "EXPORT ERROR: $e";
      notifyListeners();
    }
  }

  Future<void> importSpecificDomains(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        syncStatusMessage = "IMPORT ERROR: File not found.";
        notifyListeners();
        return;
      }
      final jsonString = await file.readAsString();
      final decoded = jsonDecode(jsonString);

      if (decoded is Map<String, dynamic> && decoded['type'] == 'partial_domain_backup') {
        List<dynamic> domainsList = decoded['domains'];
        int count = 0;
        for (var d in domainsList) {
          systemData.skills.add(SkillNode.fromJson(d));
          count++;
        }
        _storage.saveState(systemData);
        syncStatusMessage = "IMPORT SUCCESS: $count Domain(s) integrated.";
        recalculateSystem();
      } else {
        syncStatusMessage = "IMPORT ERROR: Invalid Domain Module file. Is this a full backup?";
        notifyListeners();
      }
    } catch (e) {
      syncStatusMessage = "IMPORT ERROR: Failed to parse .PRG file.";
      notifyListeners();
    }
  }

  // =========================================================================

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
    void unlock(String id) {
      if (!systemData.badgesUnlocked.contains(id)) {
        newlyUnlocked.add(id);
      }
    }

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
      double comp = 0;
      double tot = 0;
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
    
    if (syncEngine.isHosting) {
      syncEngine.startHosting(systemData); 
    }
    
    _storage.saveState(systemData);
    notifyListeners();
  }

  void addDomain(String name) {
    if (name.trim().isNotEmpty) {
      systemData.skills.add(SkillNode(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, type: 'domain'));
      recalculateSystem();
    }
  }

  void deleteDomain(String id) {
    systemData.skills.removeWhere((node) => node.id == id);
    recalculateSystem();
  }

  void addSubNode(SkillNode parent, String name, String type) {
    if (name.trim().isNotEmpty) {
      parent.children.add(SkillNode(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, type: type));
      recalculateSystem();
    }
  }

  void deleteSubNode(SkillNode parent, String childId) {
    parent.children.removeWhere((node) => node.id == childId);
    recalculateSystem();
  }
  
  void toggleSkill(SkillNode skill, bool isCompleted) {
    skill.completed = isCompleted;
    if (isCompleted) {
      skill.dateCompleted = DateTime.now().toIso8601String().split('T')[0];
    } else {
      skill.dateCompleted = null;
    }
    recalculateSystem();
  }

  void toggleDomainNode(String nodeId) {
    if (expandedDomainNodes.contains(nodeId)) {
      expandedDomainNodes.remove(nodeId); 
    } else {
      expandedDomainNodes.add(nodeId);    
    }
    notifyListeners(); 
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

  List<DailyTask> getTasksForDate(String targetDate) {
    DateTime target = DateTime.parse(targetDate);
    
    List<DailyTask> tasks = systemData.dailyTasks.where(
      (t) => t.date == targetDate && t.status != 'erased'
    ).toList();

    for (var blueprint in systemData.recurringTasks) {
      DateTime start = DateTime.parse(blueprint.startDate);

      if (target.compareTo(start) >= 0) { 
        if (blueprint.durationDays != null) {
          if (target.difference(start).inDays >= blueprint.durationDays!) {
            continue; 
          }
        }

        String expectedId = "recur_${blueprint.id}_$targetDate";
        bool alreadyMaterialized = systemData.dailyTasks.any((t) => t.id == expectedId);

        if (!alreadyMaterialized) {
          tasks.add(DailyTask(id: expectedId, text: blueprint.text, date: targetDate, status: 'pending'));
        }
      }
    }
    return tasks;
  }

  void addDailyTask(String text, String targetDate) {
    if (text.trim().isNotEmpty) {
      var newTask = DailyTask(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text, date: targetDate, status: 'pending');
      systemData.dailyTasks.add(newTask);
      
      String today = DateTime.now().toIso8601String().split('T')[0];
      if (targetDate != today) {
        // NotificationEngine.scheduleTaskReminder(newTask); // Deprecated in favor of exact alarms
      }
      
      recalculateSystem();
    }
  }

  void addRecurringTask(String text, String alertTime, int? durationDays) {
    if (text.trim().isEmpty) return;
    String today = DateTime.now().toIso8601String().split('T')[0];
    
    String newId = DateTime.now().millisecondsSinceEpoch.toString();
    systemData.recurringTasks.add(RecurringTask(
      id: newId,
      text: text,
      alertTime: alertTime,
      durationDays: durationDays,
      startDate: today,
    ));
    _injectRecurringTasksForToday();
    recalculateSystem();
    
    if (alertTime.contains(':')) {
      int h = int.parse(alertTime.split(':')[0]);
      int m = int.parse(alertTime.split(':')[1]);
      NotificationEngine.scheduleDailyRecurringQuest(
        id: newId.hashCode,
        title: "⏰ QUEST ALERT",
        body: "Time to execute: $text",
        hour: h,
        minute: m,
      );
    }
  }

  void updateTaskStatus(String id, String newStatus, String date, String text) {
    var index = systemData.dailyTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      systemData.dailyTasks[index].status = newStatus;
    } else {
      systemData.dailyTasks.add(DailyTask(id: id, text: text, date: date, status: newStatus));
    }
    recalculateSystem();
  }

  void deleteTask(String id, String date, String text) {
    var index = systemData.dailyTasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      if (id.startsWith('recur_')) {
        systemData.dailyTasks[index].status = 'erased';
      } else {
        systemData.dailyTasks.removeAt(index);
      }
    } else {
      if (id.startsWith('recur_')) {
        systemData.dailyTasks.add(DailyTask(id: id, text: text, date: date, status: 'erased'));
      }
    }
    recalculateSystem();
  }

  void deleteRecurringBlueprint(String fullTaskId) {
    List<String> parts = fullTaskId.split('_');
    if (parts.length >= 2) {
      String blueprintId = parts[1];
      systemData.recurringTasks.removeWhere((r) => r.id == blueprintId);
      systemData.dailyTasks.removeWhere((t) => t.id.startsWith('recur_${blueprintId}_') && t.status == 'pending');
      recalculateSystem();
      
      NotificationEngine.cancelTaskAlarm(blueprintId.hashCode);
    }
  }

  void postponeTask(DailyTask task, String targetDate) {
    var index = systemData.dailyTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      systemData.dailyTasks[index].status = 'postponed'; 
    } else {
      systemData.dailyTasks.add(DailyTask(id: task.id, text: task.text, date: task.date, status: 'postponed'));
    }
    
    systemData.dailyTasks.add(DailyTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(), 
      text: task.text, 
      date: targetDate, 
      status: 'pending'
    ));
    
    recalculateSystem();
  }

  void commitManualLog(String dateStr, double learnHrs, double exerciseHrs) {
    if (learnHrs > 0) {
      systemData.hoursWorkedDict[dateStr] = (systemData.hoursWorkedDict[dateStr] ?? 0.0) + learnHrs;
    }
    if (exerciseHrs > 0) {
      systemData.exerciseHoursDict[dateStr] = (systemData.exerciseHoursDict[dateStr] ?? 0.0) + exerciseHrs;
    }
    recalculateSystem();
  }

  void logTime(SkillNode skill, double hoursWorked) {
    if (hoursWorked <= 0) return;
    
    String today = DateTime.now().toIso8601String().split('T')[0];
    skill.timeLogged += hoursWorked;
    skill.dateLogged = today;
    
    systemData.hoursWorkedDict[today] = (systemData.hoursWorkedDict[today] ?? 0.0) + hoursWorked;
    
    if (!systemData.badgesUnlocked.contains("sys_focus")) {
      systemData.badgesUnlocked.add("sys_focus");
    }
    recalculateSystem(); 
  }

  bool isScanning = false;
  
  // =========================================================================
  // BLUETOOTH SYNC ENGINE (Pending Native Implementation)
  // =========================================================================
  
  bool isBluetoothScanning = false;
  List<Map<String, String>> discoveredBluetoothDevices = []; 

  Future<void> runBluetoothScan() async {
    isBluetoothScanning = true;
    syncStatusMessage = "Initializing Bluetooth hardware...";
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 2));
    
    isBluetoothScanning = false;
    // Clear out the old fake UI mockup data
    discoveredBluetoothDevices = []; 
    
    syncStatusMessage = "BLUETOOTH OFFLINE: Native Bluetooth bridging feature is not yet implemented. Use WiFi Sync for now.";
    notifyListeners();
  }

  Future<void> syncWithBluetoothDevice(String deviceId) async {
    syncStatusMessage = "BLUETOOTH ERROR: Hardware bridge offline.";
    notifyListeners();
  }

  Future<void> runRadarScan() async {
    isScanning = true;
    syncStatusMessage = "Scanning local network for other Vaults...";
    notifyListeners();
    
    await syncEngine.scanNetwork();
    
    isScanning = false;
    if (syncEngine.discoveredDevices.isEmpty) {
      syncStatusMessage = "No active Vaults found on this network.";
    } else {
      syncStatusMessage = "Scan complete. Found ${syncEngine.discoveredDevices.length} Vault(s).";
    }
    notifyListeners();
  }

  Future<void> syncWithDevice(String targetIp) async {
    syncStatusMessage = "Establishing connection...";
    notifyListeners();
    
    SystemData? remoteData = await syncEngine.fetchRemoteData(targetIp);
    
    if (remoteData == null) {
      syncStatusMessage = "ERROR: Connection failed. Device may be offline.";
    } else {
      bool shouldOverwrite = false;
      
      if (remoteData.isMasterDevice && !systemData.isMasterDevice) {
        shouldOverwrite = true; 
        syncStatusMessage = "SYNC SUCCESS: Overwritten by Master Node.";
      } else if (!remoteData.isMasterDevice && systemData.isMasterDevice) {
        shouldOverwrite = false; 
        syncStatusMessage = "SYNC BLOCKED: This device is the Master Node. Push disabled from Slave.";
      } else if (remoteData.lastUpdatedEpoch > systemData.lastUpdatedEpoch) {
        shouldOverwrite = true; 
        syncStatusMessage = "SYNC SUCCESS: Neural link established. Vault updated.";
      } else {
        syncStatusMessage = "SYNC COMPLETE: Your local data is already the most recent.";
      }

      if (shouldOverwrite) {
        // =====================================================================
        // THE FIX: SHIELD THE LOCAL DEVICE IDENTITY BEFORE OVERWRITING!
        // =====================================================================
        bool wasLocalMaster = systemData.isMasterDevice;
        String localDeviceName = systemData.deviceName;
        String localDeviceShortId = systemData.deviceShortId;

        if (remoteData.profilePhotoBase64 != null && remoteData.profilePhotoBase64!.isNotEmpty) {
          try {
            final directory = await getApplicationDocumentsDirectory();
            final imagePath = '${directory.path}/synced_avatar.jpg';
            final imageFile = File(imagePath);
            await imageFile.writeAsBytes(base64Decode(remoteData.profilePhotoBase64!));
            remoteData.profilePhotoUrl = imagePath; 
          } catch (e) {
            print("Image Reconstruction Failed: $e");
          }
        } else {
          remoteData.profilePhotoUrl = systemData.profilePhotoUrl; 
        }

        // Apply the new data
        systemData = remoteData;
        
        // Restore the unique local identity variables
        systemData.isMasterDevice = wasLocalMaster;
        systemData.deviceName = localDeviceName;
        systemData.deviceShortId = localDeviceShortId;
      }
    }
    recalculateSystem();
  }

  void createMindMap(String title, String layout) {
    String newId = DateTime.now().millisecondsSinceEpoch.toString();
    MindMapData newMap = MindMapData(
      id: newId,
      title: title.isEmpty ? "New Mind Web" : title,
      layoutStyle: layout,
      nodes: [
        MindNode(id: 'root_$newId', text: title.isEmpty ? "Central Idea" : title, x: 5000, y: 5000, colorHex: '0xFF0EA5E9', shape: 'rect', scale: 1.8)
      ] 
    );
    systemData.mindMaps.add(newMap);
    recalculateSystem();
  }

  void updateMindMap(MindMapData updatedMap) {
    int index = systemData.mindMaps.indexWhere((m) => m.id == updatedMap.id);
    if (index != -1) {
      systemData.mindMaps[index] = updatedMap;
      recalculateSystem();
    }
  }

  void deleteMindMap(String id) {
    systemData.mindMaps.removeWhere((m) => m.id == id);
    recalculateSystem();
  }

  MindMapData generateDomainMindMap() {
    List<MindNode> mapNodes = [];
    String rootId = 'root_system_matrix';
    
    mapNodes.add(MindNode(
      id: rootId, 
      text: 'HUNTER SYSTEM', 
      x: 5000, y: 5000, 
      colorHex: '0xFFEBFB7E', 
      shape: 'rect', 
      scale: 1.8
    ));

    void traverse(SkillNode node, String parentId) {
      String safeId = 'node_${node.id}';
      
      mapNodes.firstWhere((n) => n.id == parentId).childrenIds.add(safeId);

      String color = '0xFF2C2C2C'; 
      if (node.type == 'domain') color = '0xFF0EA5E9'; 
      if (node.progress >= 100.0 || node.completed) color = '0xFF00BFA5'; 

      bool isExpanded = expandedDomainNodes.contains(safeId);
      bool hasChildren = node.children.isNotEmpty;
      
      String displayText = node.name;
      if (node.type == 'domain' && hasChildren && !isExpanded) {
        displayText = "$displayText [+]";
      }

      mapNodes.add(MindNode(
        id: safeId,
        text: displayText,
        x: 5000, y: 5000, 
        colorHex: color,
        shape: node.type == 'domain' ? 'rect' : 'round',
        scale: node.type == 'domain' ? 1.2 : 1.0,
      ));

      if (node.type != 'domain' || isExpanded) {
        for (var child in node.children) {
          traverse(child, safeId);
        }
      }
    }

    for (var domain in systemData.skills) {
      traverse(domain, rootId); 
    }

    return MindMapData(id: 'auto_domain_map', title: 'System Domain Matrix', layoutStyle: 'balanced', nodes: mapNodes);
  }
}