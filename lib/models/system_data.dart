import 'task_model.dart';
import 'skill_node.dart';

class BossRaid {
  String id;
  String title;
  String deadlineDate;
  String status; // 'active', 'won', 'failed'

  BossRaid({required this.id, required this.title, required this.deadlineDate, this.status = 'active'});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'deadlineDate': deadlineDate, 'status': status};
  factory BossRaid.fromJson(Map<String, dynamic> json) => BossRaid(
    id: json['id'], title: json['title'], deadlineDate: json['deadlineDate'], status: json['status'] ?? 'active'
  );
}

class SystemData {
  List<SkillNode> skills;
  double globalProgress;
  Map<String, double> hoursWorkedDict;
  Map<String, double> exerciseHoursDict;
  List<String> badgesUnlocked;
  List<DailyTask> dailyTasks;
  List<BossRaid> bossRaids; 

  String username;
  String passwordHash;
  bool stayLoggedIn;
  String profileName;
  String profileDesc;
  String profilePhotoUrl;
  bool isDarkMode;
  bool isCardView;

  int lastUpdatedEpoch;
  bool isPenaltyActive; 
  bool isPenaltyEnabled; // NEW: Controls whether the penalty system is active (Hard Mode)

  SystemData({
    List<SkillNode>? skills,
    this.globalProgress = 0.0,
    Map<String, double>? hoursWorkedDict,
    Map<String, double>? exerciseHoursDict,
    List<String>? badgesUnlocked,
    List<DailyTask>? dailyTasks,
    List<BossRaid>? bossRaids,
    this.username = '',
    this.passwordHash = '',
    this.stayLoggedIn = false,
    this.profileName = 'Hunter',
    this.profileDesc = 'Awaiting configuration...',
    this.profilePhotoUrl = '',
    this.isDarkMode = true,
    this.isCardView = true,
    this.lastUpdatedEpoch = 0,
    this.isPenaltyActive = false, 
    this.isPenaltyEnabled = true, // Defaults to Hard Mode
  })  : skills = skills ?? [],
        hoursWorkedDict = hoursWorkedDict ?? {},
        exerciseHoursDict = exerciseHoursDict ?? {},
        badgesUnlocked = badgesUnlocked ?? [],
        dailyTasks = dailyTasks ?? [],
        bossRaids = bossRaids ?? [];

  Map<String, dynamic> toJson() => {
        'skills': skills.map((x) => x.toJson()).toList(),
        'globalProgress': globalProgress,
        'hoursWorkedDict': hoursWorkedDict,
        'exerciseHoursDict': exerciseHoursDict,
        'badgesUnlocked': badgesUnlocked,
        'dailyTasks': dailyTasks.map((x) => x.toJson()).toList(),
        'bossRaids': bossRaids.map((x) => x.toJson()).toList(), 
        'username': username,
        'passwordHash': passwordHash,
        'stayLoggedIn': stayLoggedIn,
        'profileName': profileName,
        'profileDesc': profileDesc,
        'profilePhotoUrl': profilePhotoUrl,
        'isDarkMode': isDarkMode,
        'isCardView': isCardView,
        'lastUpdatedEpoch': lastUpdatedEpoch,
        'isPenaltyActive': isPenaltyActive, 
        'isPenaltyEnabled': isPenaltyEnabled, // Save Toggle State
      };

  factory SystemData.fromJson(Map<String, dynamic> json) {
    Map<String, double> parseMap(dynamic mapData) {
      if (mapData == null) return {};
      Map<String, double> result = {};
      (mapData as Map<String, dynamic>).forEach((key, value) {
        result[key] = (value as num).toDouble();
      });
      return result;
    }

    return SystemData(
      skills: json['skills'] != null ? List<SkillNode>.from(json['skills'].map((x) => SkillNode.fromJson(x))) : [],
      globalProgress: (json['globalProgress'] ?? 0.0).toDouble(),
      hoursWorkedDict: parseMap(json['hoursWorkedDict']),
      exerciseHoursDict: parseMap(json['exerciseHoursDict']),
      badgesUnlocked: json['badgesUnlocked'] != null ? List<String>.from(json['badgesUnlocked']) : [],
      dailyTasks: json['dailyTasks'] != null ? List<DailyTask>.from(json['dailyTasks'].map((x) => DailyTask.fromJson(x))) : [],
      bossRaids: json['bossRaids'] != null ? List<BossRaid>.from(json['bossRaids'].map((x) => BossRaid.fromJson(x))) : [], 
      username: json['username'] ?? '',
      passwordHash: json['passwordHash'] ?? '',
      stayLoggedIn: json['stayLoggedIn'] ?? false,
      profileName: json['profileName'] ?? 'Hunter',
      profileDesc: json['profileDesc'] ?? 'Awaiting configuration...',
      profilePhotoUrl: json['profilePhotoUrl'] ?? '',
      isDarkMode: json['isDarkMode'] ?? true,
      isCardView: json['isCardView'] ?? true,
      lastUpdatedEpoch: json['lastUpdatedEpoch'] ?? 0,
      isPenaltyActive: json['isPenaltyActive'] ?? false, 
      isPenaltyEnabled: json['isPenaltyEnabled'] ?? true, // Load Toggle State
    );
  }
}