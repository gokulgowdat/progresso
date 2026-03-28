import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_controller.dart';
import '../models/mind_map_model.dart';

class MindMapEditor extends StatefulWidget {
  final MindMapData mapData;
  final bool isReadOnly;

  const MindMapEditor({super.key, required this.mapData, this.isReadOnly = false});

  @override
  State<MindMapEditor> createState() => _MindMapEditorState();
}

class _MindMapEditorState extends State<MindMapEditor> {
  late MindMapData currentMap;
  final TransformationController _viewController = TransformationController();
  
  String? selectedNodeId;
  Set<String> collapsedNodes = {}; 

  @override
  void initState() {
    super.initState();
    currentMap = MindMapData.fromJson(widget.mapData.toJson());
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // FIX: Force the physics engine to run once on startup, even for Read-Only Domain maps!
      _autoLayoutTree(bypassReadOnly: true);
      _centerCameraOnRoot();
    });
  }

  void _centerCameraOnRoot() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      final screenSize = MediaQuery.of(context).size;
      
      // Mother Node is absolutely anchored
      double rootCenterX = 5000.0 + 100.0; 
      double rootCenterY = 5000.0 + 40.0; 

      _viewController.value = Matrix4.identity()
        ..translate(
          -rootCenterX + (screenSize.width / 2), 
          -rootCenterY + (screenSize.height / 2)
        );
    });
  }

  void _saveAndExit() {
    if (!widget.isReadOnly) context.read<SystemController>().updateMindMap(currentMap);
    Navigator.pop(context);
  }

  void _addChildNode() {
    if (selectedNodeId == null || widget.isReadOnly) return;
    setState(() {
      var parent = currentMap.nodes.firstWhere((n) => n.id == selectedNodeId);
      String newId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Default children to standard scale (1.0), avoiding inherited Epic scale
      double newScale = parent.scale == 1.8 ? 1.0 : parent.scale;
      
      currentMap.nodes.add(MindNode(id: newId, text: "New Node", x: parent.x, y: parent.y, colorHex: parent.colorHex, shape: parent.shape, scale: newScale));
      parent.childrenIds.add(newId);
      collapsedNodes.remove(parent.id); 
      selectedNodeId = newId; 
      _autoLayoutTree();
    });
  }

  void _recursiveDelete(String targetId) {
    var nodeToDelete = currentMap.nodes.where((n) => n.id == targetId).firstOrNull;
    if (nodeToDelete == null) return;
    for (var childId in nodeToDelete.childrenIds.toList()) { _recursiveDelete(childId); }
    for (var node in currentMap.nodes) { node.childrenIds.remove(targetId); }
    currentMap.nodes.removeWhere((n) => n.id == targetId);
  }

  void _deleteSelectedNode() {
    if (selectedNodeId == null || widget.isReadOnly || selectedNodeId!.startsWith('root_')) return;
    setState(() { _recursiveDelete(selectedNodeId!); selectedNodeId = null; _autoLayoutTree(); });
  }

  // ===========================================================================
  // 📐 THE DYNAMIC BOUNDING BOX MATRIX (100% COLLISION FREE)
  // ===========================================================================
  
  double _getNodeH(MindNode node) => (node.shape == 'circle' ? 120.0 : 80.0) * node.scale;
  double _getNodeW(MindNode node) => (node.shape == 'circle' ? 120.0 : 200.0) * node.scale;

  // Calculates Vertical Subtree Space
  double _getSubtreeHeight(String nodeId) {
    var node = currentMap.nodes.firstWhere((n) => n.id == nodeId);
    double nodeH = _getNodeH(node);
    
    if (node.childrenIds.isEmpty || collapsedNodes.contains(nodeId)) return nodeH;
    
    double childrenH = 0;
    for (var cid in node.childrenIds) childrenH += _getSubtreeHeight(cid);
    childrenH += (node.childrenIds.length - 1) * 20.0; // 20px gap
    
    return childrenH > nodeH ? childrenH : nodeH;
  }

  // Calculates Horizontal Subtree Space (For Org Chart)
  double _getSubtreeWidth(String nodeId) {
    var node = currentMap.nodes.firstWhere((n) => n.id == nodeId);
    double nodeW = _getNodeW(node);
    
    if (node.childrenIds.isEmpty || collapsedNodes.contains(nodeId)) return nodeW;
    
    double childrenW = 0;
    for (var cid in node.childrenIds) childrenW += _getSubtreeWidth(cid);
    childrenW += (node.childrenIds.length - 1) * 40.0; 
    
    return childrenW > nodeW ? childrenW : nodeW;
  }

  // Calculates Horizontal Reach (For Timeline Spacing)
  double _getHorizontalSubtreeWidth(String nodeId) {
    var node = currentMap.nodes.firstWhere((n) => n.id == nodeId);
    double nodeW = _getNodeW(node);
    
    if (node.childrenIds.isEmpty || collapsedNodes.contains(nodeId)) return nodeW;
    
    double maxChildW = 0;
    for (var cid in node.childrenIds) {
      double childSubW = _getHorizontalSubtreeWidth(cid);
      if (childSubW > maxChildW) maxChildW = childSubW;
    }
    
    return nodeW + 100.0 + maxChildW; // 100.0 is the horizontal gap from _layoutHorizontal
  }

  void _autoLayoutTree({bool bypassReadOnly = false, bool centerCamera = false}) {
    if (widget.isReadOnly && !bypassReadOnly) return;
    setState(() {
      Set<String> allChildren = {};
      for (var n in currentMap.nodes) { allChildren.addAll(n.childrenIds); }
      var roots = currentMap.nodes.where((n) => !allChildren.contains(n.id)).toList();
      
      for (var root in roots) {
        root.x = 5000;
        root.y = 5000;
        
        if (currentMap.layoutStyle == 'right') {
          _layoutHorizontal(root.id, root.x, root.y + (_getNodeH(root)/2), 1, true);
        } else if (currentMap.layoutStyle == 'balanced') {
          _layoutBalanced(root);
        } else if (currentMap.layoutStyle == 'org') {
          _layoutTopDown(root.id, root.x + (_getNodeW(root)/2), root.y, true);
        } else if (currentMap.layoutStyle == 'timeline') {
          _layoutTimeline(root);
        }
      }
    });

    if (centerCamera) {
      _centerCameraOnRoot();
    }
  }

  void _layoutHorizontal(String nodeId, double targetX, double targetCenterY, int direction, bool isRoot) {
    var node = currentMap.nodes.firstWhere((n) => n.id == nodeId);
    double nodeW = _getNodeW(node);
    double nodeH = _getNodeH(node);

    if (!isRoot) {
      node.x = direction == 1 ? targetX : targetX - nodeW;
      node.y = targetCenterY - (nodeH / 2);
    }

    if (node.childrenIds.isEmpty || collapsedNodes.contains(nodeId)) return;

    double totalChildHeight = 0;
    for (var cid in node.childrenIds) totalChildHeight += _getSubtreeHeight(cid);
    totalChildHeight += (node.childrenIds.length - 1) * 20.0;

    double startY = targetCenterY - (totalChildHeight / 2);

    for (var childId in node.childrenIds) {
      double childSubH = _getSubtreeHeight(childId);
      double childCenterY = startY + (childSubH / 2);
      
      double gapX = 100.0; 
      double nextX = direction == 1 ? (node.x + nodeW + gapX) : (node.x - gapX);

      _layoutHorizontal(childId, nextX, childCenterY, direction, false);
      
      startY += childSubH + 20.0;
    }
  }

  void _layoutBalanced(MindNode root) {
    if (root.childrenIds.isEmpty || collapsedNodes.contains(root.id)) return;
    
    int mid = (root.childrenIds.length / 2).ceil();
    List<String> rightChildren = root.childrenIds.sublist(0, mid);
    List<String> leftChildren = root.childrenIds.sublist(mid);

    double rootW = _getNodeW(root);
    double rootCenterY = root.y + (_getNodeH(root) / 2);

    double rightHeight = 0;
    for (var cid in rightChildren) rightHeight += _getSubtreeHeight(cid);
    rightHeight += rightChildren.isNotEmpty ? (rightChildren.length - 1) * 20.0 : 0;
    
    double startYRight = rootCenterY - (rightHeight / 2);
    for (var cid in rightChildren) {
      double childSubH = _getSubtreeHeight(cid);
      _layoutHorizontal(cid, root.x + rootW + 100.0, startYRight + (childSubH / 2), 1, false);
      startYRight += childSubH + 20.0;
    }

    double leftHeight = 0;
    for (var cid in leftChildren) leftHeight += _getSubtreeHeight(cid);
    leftHeight += leftChildren.isNotEmpty ? (leftChildren.length - 1) * 20.0 : 0;
    
    double startYLeft = rootCenterY - (leftHeight / 2);
    for (var cid in leftChildren) {
      double childSubH = _getSubtreeHeight(cid);
      _layoutHorizontal(cid, root.x - 100.0, startYLeft + (childSubH / 2), -1, false);
      startYLeft += childSubH + 20.0;
    }
  }

  void _layoutTopDown(String nodeId, double targetCenterX, double targetY, bool isRoot) {
    var node = currentMap.nodes.firstWhere((n) => n.id == nodeId);
    double nodeW = _getNodeW(node);
    double nodeH = _getNodeH(node);

    if (!isRoot) {
      node.x = targetCenterX - (nodeW / 2);
      node.y = targetY;
    }

    if (node.childrenIds.isEmpty || collapsedNodes.contains(nodeId)) return;

    double totalChildWidth = 0;
    for (var cid in node.childrenIds) totalChildWidth += _getSubtreeWidth(cid);
    totalChildWidth += (node.childrenIds.length - 1) * 40.0;

    double startX = targetCenterX - (totalChildWidth / 2);

    for (var childId in node.childrenIds) {
      double childSubW = _getSubtreeWidth(childId);
      double childCenterX = startX + (childSubW / 2);
      
      double gapY = 80.0;
      double nextY = node.y + nodeH + gapY;

      _layoutTopDown(childId, childCenterX, nextY, false);
      
      startX += childSubW + 40.0;
    }
  }

  void _layoutTimeline(MindNode root) {
    if (root.childrenIds.isEmpty || collapsedNodes.contains(root.id)) return;

    double rootW = _getNodeW(root);
    double rootCenterY = root.y + (_getNodeH(root) / 2);
    
    double currentX = root.x + rootW + 80.0;
    bool isTop = true;

    for (var childId in root.childrenIds) {
      var child = currentMap.nodes.firstWhere((n) => n.id == childId);
      double childH = _getNodeH(child);

      // Calculates exactly how much vertical space this entire branch needs
      double childSubtreeH = _getSubtreeHeight(childId);
      
      // Pushes the branch far enough away to guarantee it never touches the spine
      double yOffset = isTop ? -(childSubtreeH / 2) - 40.0 : (childSubtreeH / 2) + 40.0;

      child.x = currentX;
      child.y = rootCenterY + yOffset - (childH / 2);

      if (child.childrenIds.isNotEmpty && !collapsedNodes.contains(childId)) {
        _layoutHorizontal(child.id, child.x, child.y + (childH / 2), 1, true); 
      }
      
      // Ensures the next node is placed perfectly past the longest horizontal child
      double subtreeHorizontalWidth = _getHorizontalSubtreeWidth(childId);
      currentX += subtreeHorizontalWidth + 50.0; 
      
      isTop = !isTop;
    }
  }

  void _switchLayout(String newLayout) {
    setState(() { currentMap.layoutStyle = newLayout; });
    _autoLayoutTree(centerCamera: true);
  }

  // --- TOOL PALETTES ---
  void _showColorPalette(MindNode node) {
    final colors = ['0xFF2C2C2C', '0xFF0EA5E9', '0xFFEBFB7E', '0xFFFF5555', '0xFF00BFA5', '0xFF9C27B0', '0xFFFF9800', '0xFFFFFFFF'];
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF171717), title: const Text("Node Color", style: TextStyle(color: Colors.white)), content: Wrap(spacing: 15, runSpacing: 15, children: colors.map((c) => InkWell(onTap: () { setState(() => node.colorHex = c); Navigator.pop(context); }, child: CircleAvatar(backgroundColor: Color(int.parse(c)), radius: 20, child: node.colorHex == c ? const Icon(Icons.check, color: Colors.black) : null))).toList())));
  }

  void _showShapePalette(MindNode node) {
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF171717), title: const Text("Node Shape", style: TextStyle(color: Colors.white)), content: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(title: const Text("Pill (Round)", style: TextStyle(color: Colors.white)), onTap: () { setState(() { node.shape = 'round'; _autoLayoutTree();}); Navigator.pop(context); }), 
      ListTile(title: const Text("Rectangle", style: TextStyle(color: Colors.white)), onTap: () { setState(() {node.shape = 'rect'; _autoLayoutTree();}); Navigator.pop(context); }), 
      ListTile(title: const Text("Perfect Circle", style: TextStyle(color: Colors.white)), onTap: () { setState(() {node.shape = 'circle'; _autoLayoutTree();}); Navigator.pop(context); })
    ])));
  }

  void _showSizePalette(MindNode node) {
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF171717), title: const Text("Node Scale", style: TextStyle(color: Colors.white)), content: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(title: const Text("Small", style: TextStyle(color: Colors.white)), onTap: () { setState(() { node.scale = 0.8; _autoLayoutTree(); }); Navigator.pop(context); }), 
      ListTile(title: const Text("Normal", style: TextStyle(color: Colors.white)), onTap: () { setState(() { node.scale = 1.0; _autoLayoutTree(); }); Navigator.pop(context); }), 
      ListTile(title: const Text("Large", style: TextStyle(color: Colors.white)), onTap: () { setState(() { node.scale = 1.4; _autoLayoutTree(); }); Navigator.pop(context); }),
      ListTile(title: const Text("Epic", style: TextStyle(color: Colors.white)), onTap: () { setState(() { node.scale = 1.8; _autoLayoutTree(); }); Navigator.pop(context); })
    ])));
  }

  void _editNodeText(MindNode node) {
    if (widget.isReadOnly) return;
    TextEditingController ctrl = TextEditingController(text: node.text);
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF2C2C2C), title: const Text("Edit Node", style: TextStyle(color: Colors.white)), content: TextField(controller: ctrl, style: const TextStyle(color: Colors.white), autofocus: true), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))), TextButton(onPressed: () { setState(() { node.text = ctrl.text; _autoLayoutTree();}); Navigator.pop(context); }, child: const Text("SAVE", style: TextStyle(color: Color(0xFFEBFB7E))))]));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<SystemController>().systemData.isDarkMode;
    final Color bg = isDark ? const Color(0xFF171717) : const Color(0xFFF4F7F6);
    final Color text = isDark ? Colors.white : Colors.black;
    final Color accent = isDark ? const Color(0xFFEBFB7E) : const Color(0xFF0EA5E9);

    Set<String> visibleNodeIds = {};
    void calcVis(String id, bool isVisible) {
      if (isVisible) visibleNodeIds.add(id);
      try {
        var node = currentMap.nodes.firstWhere((n) => n.id == id);
        bool childrenVis = isVisible && !collapsedNodes.contains(id);
        for (var cid in node.childrenIds) calcVis(cid, childrenVis);
      } catch (e) {}
    }
    
    Set<String> allChildIds = {};
    for (var n in currentMap.nodes) allChildIds.addAll(n.childrenIds);
    for (var rootId in currentMap.nodes.where((n) => !allChildIds.contains(n.id)).map((n) => n.id)) calcVis(rootId, true);
    List<MindNode> visibleNodesList = currentMap.nodes.where((n) => visibleNodeIds.contains(n.id)).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: text), onPressed: _saveAndExit),
        title: Row(
          children: [
            Text(currentMap.title, style: TextStyle(color: text, fontWeight: FontWeight.bold)),
            const SizedBox(width: 15),
            if (!widget.isReadOnly)
              DropdownButton<String>(
                value: currentMap.layoutStyle,
                dropdownColor: const Color(0xFF2C2C2C),
                style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'balanced', child: Text("Balanced")),
                  DropdownMenuItem(value: 'right', child: Text("Logic Chart")),
                  DropdownMenuItem(value: 'org', child: Text("Org Chart")),
                  DropdownMenuItem(value: 'timeline', child: Text("Timeline")),
                ],
                onChanged: (val) => _switchLayout(val!),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.amber), 
            tooltip: "Auto Arrange Map", 
            onPressed: () { _autoLayoutTree(centerCamera: true); }
          ),
          const SizedBox(width: 10),
          if (!widget.isReadOnly) ...[
            ElevatedButton.icon(onPressed: _saveAndExit, icon: const Icon(Icons.save), label: const Text("SAVE"), style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black, elevation: 0)),
            const SizedBox(width: 15),
          ]
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => selectedNodeId = null), 
            child: InteractiveViewer(
              transformationController: _viewController,
              boundaryMargin: const EdgeInsets.all(5000), 
              minScale: 0.1, maxScale: 4.0, constrained: false,
              child: SizedBox(
                width: 10000, height: 10000,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: MindMapLinesPainter(nodes: visibleNodesList, collapsed: collapsedNodes, layoutStyle: currentMap.layoutStyle, lineColor: isDark ? Colors.white30 : Colors.black26)),
                    ),
                    ...visibleNodesList.map((node) {
                      bool isSelected = selectedNodeId == node.id;
                      bool hasChildren = node.childrenIds.isNotEmpty;
                      Color nodeColor = Color(int.parse(node.colorHex));
                      bool isLightColor = nodeColor.computeLuminance() > 0.5;
                      Color textColor = isLightColor ? Colors.black : Colors.white;

                      BorderRadius? rad = BorderRadius.circular(30); 
                      if (node.shape == 'rect') rad = BorderRadius.circular(4);
                      if (node.shape == 'circle') rad = BorderRadius.circular(1000); 
                      
                      double s = node.scale;
                      double actualWidth = (node.shape == 'circle' ? 120 : 200) * s;
                      double actualHeight = (node.shape == 'circle' ? 120 : 80) * s;

                      return Positioned(
                        left: node.x, top: node.y,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => selectedNodeId = node.id),
                              onDoubleTap: () => _editNodeText(node),
                              onPanUpdate: widget.isReadOnly ? null : (details) {
                                setState(() { node.x += details.delta.dx; node.y += details.delta.dy; selectedNodeId = node.id; });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: actualWidth,
                                height: actualHeight,
                                decoration: BoxDecoration(
                                  color: nodeColor,
                                  shape: BoxShape.rectangle, 
                                  borderRadius: rad,
                                  border: Border.all(color: isSelected ? accent : (isDark ? Colors.white24 : Colors.black12), width: isSelected ? 3 : 1),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(isSelected ? 0.4 : 0.2), blurRadius: 10)]
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10 * s),
                                    child: Text(node.text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14 * s), textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis),
                                  )
                                ),
                              ),
                            ),
                            if (hasChildren)
                              Positioned(
                                right: currentMap.layoutStyle == 'org' ? null : -10,
                                left: currentMap.layoutStyle == 'org' ? (actualWidth / 2) - 12 : null,
                                bottom: -10,
                                child: InkWell(
                                  onTap: () => setState(() { if (collapsedNodes.contains(node.id)) collapsedNodes.remove(node.id); else collapsedNodes.add(node.id); _autoLayoutTree(); }),
                                  child: Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: accent, border: Border.all(color: Colors.black87, width: 2)), child: Icon(collapsedNodes.contains(node.id) ? Icons.unfold_more : Icons.unfold_less, size: 14, color: Colors.black)),
                                ),
                              )
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: 20, right: 20,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF2C2C2C), foregroundColor: accent,
              onPressed: () { _centerCameraOnRoot(); },
              child: const Icon(Icons.my_location),
            )
          ),

          if (selectedNodeId != null && !widget.isReadOnly)
            Positioned(
              bottom: 40, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(30), border: Border.all(color: accent), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.add_circle, color: accent), tooltip: "Add Child", onPressed: _addChildNode),
                      Container(width: 1, height: 20, color: Colors.grey),
                      IconButton(icon: const Icon(Icons.palette, color: Colors.blueAccent), tooltip: "Color", onPressed: () => _showColorPalette(currentMap.nodes.firstWhere((n) => n.id == selectedNodeId))),
                      IconButton(icon: const Icon(Icons.category, color: Colors.purpleAccent), tooltip: "Shape", onPressed: () => _showShapePalette(currentMap.nodes.firstWhere((n) => n.id == selectedNodeId))),
                      IconButton(icon: const Icon(Icons.format_size, color: Colors.greenAccent), tooltip: "Size", onPressed: () => _showSizePalette(currentMap.nodes.firstWhere((n) => n.id == selectedNodeId))), 
                      Container(width: 1, height: 20, color: Colors.grey),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), tooltip: "Delete", onPressed: _deleteSelectedNode),
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}

class MindMapLinesPainter extends CustomPainter {
  final List<MindNode> nodes;
  final Set<String> collapsed;
  final String layoutStyle;
  final Color lineColor;

  MindMapLinesPainter({required this.nodes, required this.collapsed, required this.layoutStyle, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = lineColor..strokeWidth = 2.0..style = PaintingStyle.stroke;

    String? rootId = nodes.where((n) => n.id.startsWith('root_')).firstOrNull?.id;

    for (var parent in nodes) {
      if (collapsed.contains(parent.id)) continue; 
      for (var childId in parent.childrenIds) {
        try {
          var child = nodes.firstWhere((n) => n.id == childId);
          double pS = parent.scale; double cS = child.scale;
          var path = Path();
          
          double pW = (parent.shape == 'circle' ? 120.0 : 200.0) * pS;
          double pH = (parent.shape == 'circle' ? 120.0 : 80.0) * pS;
          double cW = (child.shape == 'circle' ? 120.0 : 200.0) * cS;
          double cH = (child.shape == 'circle' ? 120.0 : 80.0) * cS;

          if (layoutStyle == 'org') {
             Offset start = Offset(parent.x + (pW / 2), parent.y + pH); 
             Offset end = Offset(child.x + (cW / 2), child.y); 
             path.moveTo(start.dx, start.dy);
             path.cubicTo(start.dx, start.dy + 30, end.dx, end.dy - 30, end.dx, end.dy);
          } else if (layoutStyle == 'timeline') {
             if (parent.id == rootId) {
               Offset start = Offset(parent.x + pW, parent.y + (pH / 2)); 
               Offset end = Offset(child.x, child.y + (cH / 2));
               path.moveTo(start.dx, start.dy);
               path.lineTo(end.dx - 30, start.dy); 
               path.lineTo(end.dx - 30, end.dy);   
               path.lineTo(end.dx, end.dy);        
             } else {
               Offset start = Offset(parent.x + pW, parent.y + (pH / 2)); 
               Offset end = Offset(child.x, child.y + (cH / 2)); 
               path.moveTo(start.dx, start.dy);
               path.cubicTo(start.dx + 50, start.dy, end.dx - 50, end.dy, end.dx, end.dy);
             }
          } else {
             bool isLeft = child.x < parent.x;
             Offset start = Offset(isLeft ? parent.x : parent.x + pW, parent.y + (pH / 2)); 
             Offset end = Offset(isLeft ? child.x + cW : child.x, child.y + (cH / 2)); 
             path.moveTo(start.dx, start.dy);
             path.cubicTo(start.dx + (isLeft ? -50 : 50), start.dy, end.dx + (isLeft ? 50 : -50), end.dy, end.dx, end.dy);
          }
          canvas.drawPath(path, paint);
        } catch (e) {}
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}