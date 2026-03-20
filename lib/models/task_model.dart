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

  // Convert to JSON for saving
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'date': date,
        'status': status,
      };

  // Create from JSON when loading
  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}