class SkillNode {
  String id;
  String name;
  String type; // 'domain' or 'skill'
  bool completed;
  double progress;
  double timeLogged;
  String dateLogged;
  String? dateCompleted; // NEW: Remembers when you finished a skill!
  List<SkillNode> children;

  SkillNode({
    required this.id,
    required this.name,
    required this.type,
    this.completed = false,
    this.progress = 0.0,
    this.timeLogged = 0.0,
    this.dateLogged = '',
    this.dateCompleted,
    List<SkillNode>? children,
  }) : children = children ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'completed': completed,
        'progress': progress,
        'timeLogged': timeLogged,
        'dateLogged': dateLogged,
        'dateCompleted': dateCompleted,
        'children': children.map((x) => x.toJson()).toList(),
      };

  factory SkillNode.fromJson(Map<String, dynamic> json) => SkillNode(
        id: json['id'],
        name: json['name'],
        type: json['type'],
        completed: json['completed'] ?? false,
        progress: (json['progress'] ?? 0.0).toDouble(),
        timeLogged: (json['timeLogged'] ?? 0.0).toDouble(),
        dateLogged: json['dateLogged'] ?? '',
        dateCompleted: json['dateCompleted'],
        children: json['children'] != null
            ? List<SkillNode>.from(json['children'].map((x) => SkillNode.fromJson(x)))
            : [],
      );
}