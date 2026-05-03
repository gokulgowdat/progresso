import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'skill_node.dart';
import 'task_model.dart';
import 'mind_map_model.dart';

class NoteGroup {
  String id;
  String name;
  
  NoteGroup({required this.id, required this.name});
  
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory NoteGroup.fromJson(Map<String, dynamic> json) => NoteGroup(id: json['id'], name: json['name']);
}

class StickyNote {
  String id;
  String groupId;
  String title; 
  String text;
  String colorHex;
  double width;
  double height;
  double x; 
  double y; 

  StickyNote({
    required this.id,
    required this.groupId,
    this.title = "", 
    this.text = "",
    this.colorHex = '0xFFFFF59D', 
    this.width = 250.0,
    this.height = 250.0,
    this.x = 50.0,
    this.y = 50.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'groupId': groupId, 'title': title, 'text': text, 'colorHex': colorHex, 
    'width': width, 'height': height, 'x': x, 'y': y
  };

  factory StickyNote.fromJson(Map<String, dynamic> json) => StickyNote(
    id: json['id'],
    groupId: json['groupId'],
    title: json['title'] ?? "", 
    text: json['text'] ?? "",
    colorHex: json['colorHex'] ?? '0xFFFFF59D',
    width: (json['width'] ?? 250.0).toDouble(),
    height: (json['height'] ?? 250.0).toDouble(),
    x: (json['x'] ?? 50.0).toDouble(),
    y: (json['y'] ?? 50.0).toDouble(),
  );
}

class BossRaid {
  String id;
  String title;
  String deadlineDate;
  String status;

  BossRaid({required this.id, required this.title, required this.deadlineDate, this.status = 'active'});

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'deadlineDate': deadlineDate, 'status': status
  };

  factory BossRaid.fromJson(Map<String, dynamic> json) => BossRaid(
    id: json['id'], title: json['title'], deadlineDate: json['deadlineDate'], status: json['status'] ?? 'active'
  );
}

class SystemData {
  List<SkillNode> skills;
  List<DailyTask> dailyTasks;
  List<RecurringTask> recurringTasks; 
  List<BossRaid> bossRaids;
  List<MindMapData> mindMaps; 
  
  List<NoteGroup> noteGroups;
  List<StickyNote> stickyNotes;
  
  Map<String, double> hoursWorkedDict;
  Map<String, double> exerciseHoursDict;
  List<String> badgesUnlocked;

  double globalProgress;
  int lastUpdatedEpoch;

  bool isDarkMode;
  bool isCardView;
  bool isPenaltyEnabled;
  bool isPenaltyActive;

  String username;
  String passwordHash;
  bool stayLoggedIn;
  String profileName;
  String profileDesc;
  String profilePhotoUrl;
  
  bool isMasterDevice;
  String? profilePhotoBase64; 

  // DEVICE IDENTITY ENGINE
  String deviceName;
  String deviceShortId;

  SystemData({
    this.skills = const [],
    this.dailyTasks = const [],
    this.recurringTasks = const [], 
    this.bossRaids = const [],
    this.mindMaps = const [], 
    this.noteGroups = const [], 
    this.stickyNotes = const [], 
    this.hoursWorkedDict = const {},
    this.exerciseHoursDict = const {},
    this.badgesUnlocked = const [],
    this.globalProgress = 0.0,
    this.lastUpdatedEpoch = 0,
    this.isDarkMode = true,
    this.isCardView = true,
    this.isPenaltyEnabled = false,
    this.isPenaltyActive = false,
    this.username = "",
    this.passwordHash = "",
    this.stayLoggedIn = false,
    this.profileName = "Hunter",
    this.profileDesc = "Awakened Player",
    this.profilePhotoUrl = "",
    this.isMasterDevice = false,
    this.profilePhotoBase64,
    this.deviceName = "Hunter_Vault",
    this.deviceShortId = "",
  });

  Map<String, dynamic> toJson() {
    String? base64Image;
    if (profilePhotoUrl.isNotEmpty && File(profilePhotoUrl).existsSync()) {
      try {
        final bytes = File(profilePhotoUrl).readAsBytesSync();
        base64Image = base64Encode(bytes);
      } catch (e) {}
    }

    return {
      'skills': skills.map((s) => s.toJson()).toList(),
      'dailyTasks': dailyTasks.map((t) => t.toJson()).toList(),
      'recurringTasks': recurringTasks.map((r) => r.toJson()).toList(), 
      'bossRaids': bossRaids.map((r) => r.toJson()).toList(),
      'mindMaps': mindMaps.map((m) => m.toJson()).toList(), 
      'noteGroups': noteGroups.map((g) => g.toJson()).toList(), 
      'stickyNotes': stickyNotes.map((n) => n.toJson()).toList(), 
      'hoursWorkedDict': hoursWorkedDict,
      'exerciseHoursDict': exerciseHoursDict,
      'badgesUnlocked': badgesUnlocked,
      'globalProgress': globalProgress,
      'lastUpdatedEpoch': lastUpdatedEpoch,
      'isDarkMode': isDarkMode,
      'isCardView': isCardView,
      'isPenaltyEnabled': isPenaltyEnabled,
      'isPenaltyActive': isPenaltyActive,
      'username': username,
      'passwordHash': passwordHash,
      'stayLoggedIn': stayLoggedIn,
      'profileName': profileName,
      'profileDesc': profileDesc,
      'profilePhotoUrl': profilePhotoUrl, 
      'isMasterDevice': isMasterDevice,
      'profilePhotoBase64': base64Image, 
      'deviceName': deviceName,
      'deviceShortId': deviceShortId,
    };
  }

  factory SystemData.fromJson(Map<String, dynamic> json) {
    return SystemData(
      skills: (json['skills'] as List?)?.map((i) => SkillNode.fromJson(i)).toList() ?? [],
      dailyTasks: (json['dailyTasks'] as List?)?.map((i) => DailyTask.fromJson(i)).toList() ?? [],
      recurringTasks: (json['recurringTasks'] as List?)?.map((i) => RecurringTask.fromJson(i)).toList() ?? [], 
      bossRaids: (json['bossRaids'] as List?)?.map((i) => BossRaid.fromJson(i)).toList() ?? [],
      mindMaps: (json['mindMaps'] as List?)?.map((i) => MindMapData.fromJson(i)).toList() ?? [], 
      noteGroups: (json['noteGroups'] as List?)?.map((i) => NoteGroup.fromJson(i)).toList() ?? [], 
      stickyNotes: (json['stickyNotes'] as List?)?.map((i) => StickyNote.fromJson(i)).toList() ?? [], 
      hoursWorkedDict: Map<String, double>.from(json['hoursWorkedDict'] ?? {}),
      exerciseHoursDict: Map<String, double>.from(json['exerciseHoursDict'] ?? {}),
      badgesUnlocked: List<String>.from(json['badgesUnlocked'] ?? []),
      globalProgress: (json['globalProgress'] ?? 0).toDouble(),
      lastUpdatedEpoch: json['lastUpdatedEpoch'] ?? 0,
      isDarkMode: json['isDarkMode'] ?? true,
      isCardView: json['isCardView'] ?? true,
      isPenaltyEnabled: json['isPenaltyEnabled'] ?? false,
      isPenaltyActive: json['isPenaltyActive'] ?? false,
      username: json['username'] ?? "",
      passwordHash: json['passwordHash'] ?? "",
      stayLoggedIn: json['stayLoggedIn'] ?? false,
      profileName: json['profileName'] ?? "Hunter",
      profileDesc: json['profileDesc'] ?? "Awakened Player",
      profilePhotoUrl: json['profilePhotoUrl'] ?? "", 
      isMasterDevice: json['isMasterDevice'] ?? false,
      profilePhotoBase64: json['profilePhotoBase64'],
      deviceName: json['deviceName'] ?? "Hunter_Vault",
      deviceShortId: json['deviceShortId'] ?? "",
    );
  }
}