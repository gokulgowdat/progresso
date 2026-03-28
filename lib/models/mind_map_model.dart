class MindNode {
  String id;
  String text;
  double x;
  double y;
  List<String> childrenIds;
  String colorHex;
  String shape;
  double scale;

  MindNode({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    List<String>? childrenIds,
    this.colorHex = '0xFF2C2C2C',
    this.shape = 'round',
    this.scale = 1.0,
  }) : childrenIds = childrenIds ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'x': x,
    'y': y,
    'childrenIds': childrenIds,
    'colorHex': colorHex,
    'shape': shape,
    'scale': scale,
  };

  factory MindNode.fromJson(Map<String, dynamic> json) => MindNode(
    id: json['id'],
    text: json['text'],
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    childrenIds: List<String>.from(json['childrenIds'] ?? []),
    colorHex: json['colorHex'] ?? '0xFF2C2C2C',
    shape: json['shape'] ?? 'round',
    scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
  );
}

class MindMapData {
  String id;
  String title;
  List<MindNode> nodes;
  String layoutStyle; // NEW: Remembers the map's geometry ('balanced', 'right', 'org')

  MindMapData({
    required this.id,
    required this.title,
    required this.nodes,
    this.layoutStyle = 'balanced', // Default to evenly spread
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'layoutStyle': layoutStyle,
  };

  factory MindMapData.fromJson(Map<String, dynamic> json) => MindMapData(
    id: json['id'],
    title: json['title'],
    nodes: (json['nodes'] as List).map((n) => MindNode.fromJson(n)).toList(),
    layoutStyle: json['layoutStyle'] ?? 'balanced',
  );
}