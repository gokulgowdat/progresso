import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'skill_node.dart';
import 'task_model.dart';
import 'mind_map_model.dart';

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
  List<BossRaid> bossRaids;
  List<MindMapData> mindMaps; 
  
  Map<String, double> hoursWorkedDict;
  Map<String, double> exerciseHoursDict;
  List<String> badgesUnlocked;

  double globalProgress;
  int lastUpdatedEpoch;

  bool isDarkMode;
  bool isCardView;
  bool isPenaltyEnabled;
  bool isPenaltyActive;

  // Identity & Auth
  String username;
  String passwordHash;
  bool stayLoggedIn;
  String profileName;
  String profileDesc;
  String profilePhotoUrl;
  
  // Cross-Device Sync Variables
  bool isMasterDevice;
  String? profilePhotoBase64; 

  SystemData({
    this.skills = const [],
    this.dailyTasks = const [],
    this.bossRaids = const [],
    this.mindMaps = const [], 
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
  });

  Map<String, dynamic> toJson() {
    // Convert local photo to Base64 code for network transport
    String? base64Image;
    if (profilePhotoUrl.isNotEmpty && File(profilePhotoUrl).existsSync()) {
      try {
        final bytes = File(profilePhotoUrl).readAsBytesSync();
        base64Image = base64Encode(bytes);
      } catch (e) {
        print("Failed to encode image");
      }
    }

    return {
      'skills': skills.map((s) => s.toJson()).toList(),
      'dailyTasks': dailyTasks.map((t) => t.toJson()).toList(),
      'bossRaids': bossRaids.map((r) => r.toJson()).toList(),
      'mindMaps': mindMaps.map((m) => m.toJson()).toList(), 
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
      'profilePhotoUrl': profilePhotoUrl, // FIX: Actually save the path!
      'isMasterDevice': isMasterDevice,
      'profilePhotoBase64': base64Image, 
    };
  }

  factory SystemData.fromJson(Map<String, dynamic> json) {
    return SystemData(
      skills: (json['skills'] as List?)?.map((i) => SkillNode.fromJson(i)).toList() ?? [],
      dailyTasks: (json['dailyTasks'] as List?)?.map((i) => DailyTask.fromJson(i)).toList() ?? [],
      bossRaids: (json['bossRaids'] as List?)?.map((i) => BossRaid.fromJson(i)).toList() ?? [],
      mindMaps: (json['mindMaps'] as List?)?.map((i) => MindMapData.fromJson(i)).toList() ?? [], 
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
      profilePhotoUrl: json['profilePhotoUrl'] ?? "", // FIX: Actually load the path!
      isMasterDevice: json['isMasterDevice'] ?? false,
      profilePhotoBase64: json['profilePhotoBase64'],
    );
  }
}