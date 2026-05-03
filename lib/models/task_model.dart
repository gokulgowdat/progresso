class DailyTask {
  String id;
  String text;
  String date; // Format: YYYY-MM-DD
  String status; // pending, completed, postponed, erased

  DailyTask({
    required this.id,
    required this.text,
    required this.date,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'date': date,
        'status': status,
      };

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}

// NEW: The Blueprint for infinite/recurring tasks
class RecurringTask {
  String id;
  String text;
  String alertTime; // Format "HH:mm"
  int? durationDays; // Null means 'Forever'
  String startDate; // Format: YYYY-MM-DD
  
  RecurringTask({
    required this.id,
    required this.text,
    required this.alertTime,
    this.durationDays,
    required this.startDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'alertTime': alertTime,
    'durationDays': durationDays,
    'startDate': startDate,
  };

  factory RecurringTask.fromJson(Map<String, dynamic> json) => RecurringTask(
    id: json['id'],
    text: json['text'],
    alertTime: json['alertTime'],
    durationDays: json['durationDays'],
    startDate: json['startDate'],
  );
}