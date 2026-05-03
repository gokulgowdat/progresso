import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_controller.dart';
import '../models/mind_map_model.dart';
import '../screens/mind_map_editor.dart';

class MindMapTab extends StatelessWidget {
  const MindMapTab({super.key});

  void _showCreateMapDialog(BuildContext context, SystemController system, Color card, Color text, Color accent) {
    TextEditingController titleCtrl = TextEditingController(text: "Strategic Plan ${system.systemData.mindMaps.length + 1}");
    String selectedLayout = 'balanced';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: card,
          title: Text("Forge New Mind Web", style: TextStyle(color: text, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: titleCtrl, style: TextStyle(color: text), decoration: const InputDecoration(labelText: "Map Title")),
              const SizedBox(height: 20),
              Text("Select Map Style:", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              const SizedBox(height: 10),
              RadioListTile(title: Text("Balanced (Radial)", style: TextStyle(color: text)), activeColor: accent, value: 'balanced', groupValue: selectedLayout, onChanged: (val) => setState(() => selectedLayout = val.toString())),
              RadioListTile(title: Text("Logic Chart (Right)", style: TextStyle(color: text)), activeColor: accent, value: 'right', groupValue: selectedLayout, onChanged: (val) => setState(() => selectedLayout = val.toString())),
              RadioListTile(title: Text("Org Chart (Top-Down)", style: TextStyle(color: text)), activeColor: accent, value: 'org', groupValue: selectedLayout, onChanged: (val) => setState(() => selectedLayout = val.toString())),
              RadioListTile(title: Text("Timeline (Spine)", style: TextStyle(color: text)), activeColor: accent, value: 'timeline', groupValue: selectedLayout, onChanged: (val) => setState(() => selectedLayout = val.toString())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
            ElevatedButton(onPressed: () { system.createMindMap(titleCtrl.text, selectedLayout); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black), child: const Text("CREATE")),
          ],
        )
      )
    );
  }

  void _showRenameMapDialog(BuildContext context, SystemController system, MindMapData map, Color card, Color text, Color accent) {
    TextEditingController titleCtrl = TextEditingController(text: map.title);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: card,
        title: Text("Rename Mind Web", style: TextStyle(color: text, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: titleCtrl, 
          style: TextStyle(color: text), 
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter new title...",
            hintStyle: TextStyle(color: Colors.grey[600]),
          )
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () { 
              if (titleCtrl.text.trim().isNotEmpty) {
                map.title = titleCtrl.text.trim();
                system.updateMindMap(map); 
              }
              Navigator.pop(ctx); 
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black), 
            child: const Text("SAVE")
          ),
        ],
      )
    );
  }
  @override
  Widget build(BuildContext context) {
    final system = context.watch<SystemController>();
    final isDark = system.systemData.isDarkMode;
    final Color cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final Color text = isDark ? Colors.white : Colors.black;
    final Color accent = isDark ? const Color(0xFFEBFB7E) : const Color(0xFF0EA5E9);

    bool isMobile = MediaQuery.of(context).size.width < 800;

    Widget viewDomainsBtn = ElevatedButton.icon(
      onPressed: () { 
        MindMapData domainMap = system.generateDomainMindMap(); 
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => MindMapEditor(mapData: domainMap, isReadOnly: true))); 
      },
      icon: const Icon(Icons.account_tree), 
      label: const Text("VIEW DOMAINS"), 
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), foregroundColor: Colors.white),
    );

    Widget newMapBtn = ElevatedButton.icon(
      onPressed: () => _showCreateMapDialog(context, system, cardColor, text, accent),
      icon: const Icon(Icons.add_chart), 
      label: const Text("NEW MAP"), 
      style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.black),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          Text("MIND WEB PANEL", style: TextStyle(color: text, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: viewDomainsBtn),
              const SizedBox(width: 10),
              Expanded(child: newMapBtn),
            ],
          )
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("MIND WEB PANEL", style: TextStyle(color: text, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
              Row(
                children: [
                  viewDomainsBtn,
                  const SizedBox(width: 10),
                  newMapBtn,
                ],
              )
            ],
          ),
        ],
        
        const SizedBox(height: 20),
        Expanded(
          child: system.systemData.mindMaps.isEmpty 
            ? const Center(child: Text("No Custom Maps forged yet.", style: TextStyle(color: Colors.grey)))
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.0),
                itemCount: system.systemData.mindMaps.length,
                itemBuilder: (context, index) {
                  var map = system.systemData.mindMaps[index];
                  return Card(
                    color: cardColor, elevation: 4, clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => MindMapEditor(mapData: map))),
                      child: Stack(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(map.layoutStyle == 'org' ? Icons.account_tree : (map.layoutStyle == 'timeline' ? Icons.linear_scale : Icons.hub), size: 40, color: accent),
                                  const SizedBox(height: 10),
                                  Text(map.title, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 5),
                                  Text(map.layoutStyle.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1)),
                                ],
                              ),
                            ),
                          ),
                          
                          Positioned(
                            top: 0, right: 0, 
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18), 
                                  onPressed: () => _showRenameMapDialog(context, system, map, cardColor, text, accent)
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18), 
                                  onPressed: () => system.deleteMindMap(map.id)
                                ),
                              ],
                            )
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}