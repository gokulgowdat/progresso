import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; 
import '../services/system_controller.dart';
import '../models/skill_node.dart';
import '../widgets/timer_overlay.dart';
import '../tabs/analytics_tab.dart';
import '../tabs/tasks_tab.dart';
import '../tabs/quest_log_tab.dart'; 
import '../tabs/achievements_tab.dart'; 
import '../tabs/mind_map_tab.dart'; 

class AppColors {
  final bool isDark;
  AppColors(this.isDark);

  Color get bg => isDark ? const Color(0xFF171717) : const Color(0xFFF4F7F6); 
  Color get card => isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFFFFF);
  Color get altCard => isDark ? const Color(0xFF252525) : const Color(0xFFF9FAFB);
  Color get border => isDark ? const Color(0xFF444444) : const Color(0xFFE2E8F0);
  Color get text => isDark ? Colors.white : const Color(0xFF334155);
  Color get subText => isDark ? Colors.grey : const Color(0xFF94A3B8);
  Color get accent => isDark ? const Color(0xFFEBFB7E) : const Color(0xFF0EA5E9); 
  Color get invertText => isDark ? const Color(0xFF171717) : Colors.white;
  Color get inputBg => isDark ? const Color(0xFF171717) : const Color(0xFFEDF2F7);
  Color get successBg => isDark ? const Color(0xFF1F331F) : const Color(0xFFECFDF5);
  Color get danger => const Color(0xFFFF5555);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String activeTab = 'domains'; 
  
  bool isSubPanelOpen = false;
  SkillNode? activeDomainNode;
  List<SkillNode> pathHistory = [];

  SkillNode? get currentNode => pathHistory.isEmpty ? activeDomainNode : pathHistory.last;

  void openSlidePanel(SkillNode rootDomain) {
    setState(() {
      activeDomainNode = rootDomain;
      pathHistory = [rootDomain];
      isSubPanelOpen = true;
    });
  }

  void closeSlidePanel() {
    setState(() {
      isSubPanelOpen = false;
      pathHistory.clear();
      activeDomainNode = null;
    });
  }

  void diveDeeper(SkillNode node) {
    setState(() => pathHistory.add(node));
  }

  void goUp() {
    setState(() {
      if (pathHistory.length > 1) {
        pathHistory.removeLast();
      } else {
        closeSlidePanel(); 
      }
    });
  }

  // ===========================================================================
  // 🛑 TWO-FACTOR DESTRUCTION PROTOCOL (WARNING DIALOGS)
  // ===========================================================================
  void _showResetWarning1(BuildContext context, SystemController system) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("⚠️ SYSTEM WIPE INITIATED", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text("Are you absolutely sure? This will delete all Domains, Quests, Mind Maps, and Stats.", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showResetWarning2(context, system); // Trigger the final safety lock
            },
            child: const Text("PROCEED", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showResetWarning2(BuildContext context, SystemController system) {
    TextEditingController confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("🛑 FINAL WARNING", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("This action is IRREVERSIBLE. To permanently destroy your Vault, you must type 'WIPE' below.", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 15),
            TextField(
              controller: confirmCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Type WIPE to confirm", 
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF171717)
              ),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ABORT", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              if (confirmCtrl.text.trim().toUpperCase() == 'WIPE') {
                Navigator.pop(ctx);
                system.masterReset();
                setState(() => activeTab = 'domains');
              }
            },
            child: const Text("DESTROY VAULT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final system = context.watch<SystemController>();

    if (!system.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFEBFB7E))));
    }

    final colors = AppColors(system.systemData.isDarkMode);
    bool isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return _buildMobileLayout(system, colors);
    } else {
      return _buildDesktopLayout(system, colors);
    }
  }

  // ===========================================================================
  // 📱 MOBILE LAYOUT
  // ===========================================================================
  Widget _buildMobileLayout(SystemController system, AppColors colors) {
    int getSelectedIndex() {
      switch (activeTab) {
        case 'domains': return 0;
        case 'tasks': return 1;
        case 'calendar': return 2;
        case 'analytics': return 3;
        case 'badges': return 4;
        default: return 0; 
      }
    }

    bool hasPhoto = system.systemData.profilePhotoUrl.isNotEmpty && File(system.systemData.profilePhotoUrl).existsSync();

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.card,
        title: Text("Rank: ${system.currentStreak} 🔥", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(system.isAudioPlaying ? Icons.graphic_eq : Icons.headphones, color: system.isAudioPlaying ? const Color(0xFF00BFA5) : colors.subText), 
            tooltip: "Flow State Audio",
            onPressed: () => _showAudioDeck(context, system, colors)
          ),
          IconButton(
            icon: Icon(Icons.hub, color: activeTab == 'mindmaps' ? colors.accent : colors.subText), 
            tooltip: "Mind Web",
            onPressed: () => setState(() { activeTab = 'mindmaps'; closeSlidePanel(); })
          ),
          IconButton(
            icon: Icon(Icons.help_outline, color: colors.subText), 
            tooltip: "System Guide",
            onPressed: () => _showSystemGuide(context, colors)
          ),
          IconButton(
            icon: Icon(Icons.settings, color: activeTab == 'settings' ? colors.accent : colors.subText), 
            onPressed: () => setState(() { activeTab = 'settings'; closeSlidePanel(); })
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15, left: 5),
            child: InkWell(
              onTap: () => setState(() { activeTab = 'user_profile'; closeSlidePanel(); }),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: colors.inputBg,
                backgroundImage: hasPhoto ? FileImage(File(system.systemData.profilePhotoUrl)) : null,
                child: !hasPhoto ? Text(system.systemData.profileName.isNotEmpty ? system.systemData.profileName[0].toUpperCase() : "U", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)) : null,
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("SYSTEM PROGRESS", style: TextStyle(color: colors.subText, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text("${system.systemData.globalProgress.toStringAsFixed(1)}%", style: TextStyle(color: colors.accent, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: system.systemData.globalProgress / 100.0, backgroundColor: colors.inputBg, color: colors.accent, minHeight: 6, borderRadius: BorderRadius.circular(3)),
                ],
              ),
            ),
            Expanded(child: _buildRouterContent(system, colors)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: colors.card,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.subText,
        currentIndex: getSelectedIndex(),
        onTap: (index) {
          setState(() {
            if (index == 0) activeTab = 'domains';
            if (index == 1) activeTab = 'tasks';
            if (index == 2) activeTab = 'calendar';
            if (index == 3) activeTab = 'analytics';
            if (index == 4) activeTab = 'badges';
            closeSlidePanel();
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: "Domains"),
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Log"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: "Vault"),
        ],
      ),
    );
  }

  // ===========================================================================
  // 💻 DESKTOP LAYOUT
  // ===========================================================================
  Widget _buildDesktopLayout(SystemController system, AppColors colors) {
    return Scaffold(
      backgroundColor: colors.bg,
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome back, ${system.systemData.profileName}.", style: TextStyle(color: colors.text, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(system.currentQuote, style: TextStyle(color: colors.accent, fontSize: 14, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("GLOBAL SYSTEM PROGRESS", style: TextStyle(color: colors.subText, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("${system.systemData.globalProgress.toStringAsFixed(1)}%", style: TextStyle(color: colors.accent, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: system.systemData.globalProgress / 100.0, backgroundColor: colors.inputBg, color: colors.accent, minHeight: 12, borderRadius: BorderRadius.circular(6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      _buildTabButton("📁 DOMAINS", "domains", colors),
                      const SizedBox(width: 10),
                      _buildTabButton("📅 DAILY TASKS", "tasks", colors),
                      const SizedBox(width: 10),
                      _buildTabButton("🗺️ QUEST LOG", "calendar", colors),
                      const SizedBox(width: 10),
                      _buildTabButton("📊 ANALYTICS", "analytics", colors),
                      const SizedBox(width: 10),
                      _buildTabButton("🏆 ACHIEVEMENTS", "badges", colors),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Expanded(child: _buildRouterContent(system, colors)),
                ],
              ),
            ),
          ),

          Container(
            width: 70,
            decoration: BoxDecoration(color: colors.card, border: Border(left: BorderSide(color: colors.border))),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text("🔥", style: TextStyle(fontSize: 28)),
                Text("${system.currentStreak}", style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
                
                const SizedBox(height: 30),
                
                IconButton(
                  icon: Icon(Icons.hub, color: activeTab == 'mindmaps' ? colors.accent : colors.subText, size: 28),
                  tooltip: "Mind Web Panel",
                  onPressed: () { setState(() { activeTab = 'mindmaps'; closeSlidePanel(); }); }
                ),

                const SizedBox(height: 15),

                IconButton(
                  icon: Icon(system.isAudioPlaying ? Icons.graphic_eq : Icons.headphones, 
                             color: system.isAudioPlaying ? const Color(0xFF00BFA5) : colors.subText, size: 28),
                  tooltip: "Flow State Audio",
                  onPressed: () => _showAudioDeck(context, system, colors),
                ),

                const Spacer(),
                
                IconButton(
                  icon: Icon(Icons.help_outline, color: colors.subText, size: 28),
                  tooltip: "System Guide",
                  onPressed: () => _showSystemGuide(context, colors),
                ),

                const SizedBox(height: 15),
                
                IconButton(
                  icon: Icon(Icons.settings, color: activeTab == 'settings' ? colors.accent : colors.subText, size: 28), 
                  onPressed: () { setState(() { activeTab = 'settings'; closeSlidePanel(); }); }
                ),
                
                const SizedBox(height: 20),
                
                Container(
                  width: 50, height: 50, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: colors.inputBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: activeTab == 'user_profile' ? colors.accent : colors.border, width: 2)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () { setState(() { activeTab = 'user_profile'; closeSlidePanel(); }); },
                    child: system.systemData.profilePhotoUrl.isNotEmpty && File(system.systemData.profilePhotoUrl).existsSync()
                        ? Image.file(
                            File(system.systemData.profilePhotoUrl), 
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(child: Text(system.systemData.profileName.isNotEmpty ? system.systemData.profileName[0].toUpperCase() : "U", style: TextStyle(color: colors.text, fontSize: 24, fontWeight: FontWeight.bold)))
                          )
                        : Center(child: Text(system.systemData.profileName.isNotEmpty ? system.systemData.profileName[0].toUpperCase() : "U", style: TextStyle(color: colors.text, fontSize: 24, fontWeight: FontWeight.bold))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ROUTER ---
  Widget _buildRouterContent(SystemController system, AppColors colors) {
    if (activeTab == 'domains') return _buildDomainsLayout(system, colors);
    if (activeTab == 'tasks') return const TasksTab();
    if (activeTab == 'calendar') return const QuestLogTab(); 
    if (activeTab == 'analytics') return const AnalyticsTab(); 
    if (activeTab == 'badges') return const AchievementsTab(); 
    if (activeTab == 'mindmaps') return const MindMapTab(); 
    if (activeTab == 'settings') return _buildSettingsView(system, colors);
    if (activeTab == 'user_profile') return _buildUserProfileView(system, colors); 
    return const SizedBox();
  }

  Widget _buildTabButton(String title, String tabId, AppColors colors) {
    bool isActive = activeTab == tabId;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() { activeTab = tabId; closeSlidePanel(); }),
        child: Container(
          height: 40,
          decoration: BoxDecoration(color: isActive ? colors.accent : colors.card, borderRadius: BorderRadius.circular(5), border: Border.all(color: colors.border)),
          child: Center(child: Text(title, style: TextStyle(color: isActive ? colors.invertText : colors.text, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  // ===========================================================================
  // DOMAINS LOGIC
  // ===========================================================================
  Widget _buildDomainsLayout(SystemController system, AppColors colors) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile && isSubPanelOpen && currentNode != null) {
      return Container(
        decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
        child: _buildSubPanelContent(system, colors),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobile)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart,
            width: isSubPanelOpen ? 450 : 0, 
            margin: EdgeInsets.only(right: isSubPanelOpen ? 20 : 0),
            decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
            clipBehavior: Clip.hardEdge,
            child: isSubPanelOpen && currentNode != null ? _buildSubPanelContent(system, colors) : const SizedBox(),
          ),
        Expanded(child: _buildRootDomainsGrid(system, colors)),
      ],
    );
  }

  Widget _buildSubPanelContent(SystemController system, AppColors colors) {
    final node = currentNode!;
    final TextEditingController subInputController = TextEditingController();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15), color: colors.inputBg,
          child: Row(
            children: [
              ElevatedButton(onPressed: goUp, style: ElevatedButton.styleFrom(backgroundColor: colors.border, foregroundColor: colors.accent, elevation: 0), child: const Text("< UP")),
              const SizedBox(width: 15),
              Expanded(child: Text(node.name.toUpperCase(), style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold))),
              IconButton(icon: Icon(Icons.close, color: colors.subText), onPressed: closeSlidePanel),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Expanded(child: TextField(controller: subInputController, style: TextStyle(color: colors.text), decoration: InputDecoration(hintText: "Add Sub-Domain or Skill...", hintStyle: TextStyle(color: colors.subText), filled: true, fillColor: colors.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none)))),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: () { system.addSubNode(node, subInputController.text, 'domain'); subInputController.clear(); }, style: ElevatedButton.styleFrom(backgroundColor: colors.border, foregroundColor: const Color(0xFF2196F3), elevation: 0), child: const Text("+ DIR")),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: () { system.addSubNode(node, subInputController.text, 'skill'); subInputController.clear(); }, style: ElevatedButton.styleFrom(backgroundColor: colors.border, foregroundColor: const Color(0xFF00BFA5), elevation: 0), child: const Text("+ SKILL")),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: node.children.length,
            itemBuilder: (context, index) {
              var child = node.children[index];
              bool isSkill = child.type == 'skill';
              bool isDone = child.completed;

              return Container(
                margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(color: isDone ? colors.successBg : colors.altCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: isDone ? const Color(0xFF2E7D32) : colors.border)),
                child: Row(
                  children: [
                    if (isSkill) Checkbox(value: isDone, activeColor: colors.accent, onChanged: (val) => system.toggleSkill(child, val ?? false)),
                    Text(isSkill ? "⚡ " : "📁 ", style: const TextStyle(fontSize: 18)),
                    Expanded(child: Text(child.name, style: TextStyle(color: isDone ? colors.subText : colors.text, fontSize: 16, fontWeight: isSkill ? FontWeight.normal : FontWeight.bold, decoration: isDone ? TextDecoration.lineThrough : null))),
                    
                    if (!isSkill) 
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("${child.progress.toStringAsFixed(1)}%", style: TextStyle(color: colors.subText, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(value: child.progress / 100.0, backgroundColor: colors.inputBg, color: const Color(0xFF2196F3), minHeight: 4, borderRadius: BorderRadius.circular(2)),
                            ],
                          ),
                        ),
                      ),
                    
                    if (isSkill) const SizedBox(width: 5),
                    if (isSkill) ElevatedButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => TimerOverlay(skill: child))),
                      style: ElevatedButton.styleFrom(backgroundColor: colors.inputBg, foregroundColor: const Color(0xFF00BFA5), elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 10)), 
                      child: const Text("FOCUS"),
                    ),
                    if (!isSkill) const SizedBox(width: 5),
                    if (!isSkill) ElevatedButton(
                      onPressed: () => diveDeeper(child), 
                      style: ElevatedButton.styleFrom(backgroundColor: colors.inputBg, foregroundColor: colors.accent, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 10)), 
                      child: const Text("ACCESS")
                    ),
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 18), onPressed: () => _showRenameDialog(context, system, child, colors)),
                    IconButton(icon: Icon(Icons.close, color: colors.danger, size: 18), onPressed: () => system.deleteSubNode(node, child.id)),
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildRootDomainsGrid(SystemController system, AppColors colors) {
    final TextEditingController inputController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: TextField(controller: inputController, style: TextStyle(color: colors.text), decoration: InputDecoration(hintText: "Initialize new main domain...", hintStyle: TextStyle(color: colors.subText), filled: true, fillColor: colors.card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide(color: colors.border))))),
            const SizedBox(width: 10),
            InkWell(onTap: () { system.addDomain(inputController.text); inputController.clear(); }, child: Container(width: 55, height: 55, decoration: BoxDecoration(color: colors.accent, borderRadius: BorderRadius.circular(5)), child: Center(child: Text("+", style: TextStyle(color: colors.invertText, fontSize: 28, fontWeight: FontWeight.bold))))),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 15, runSpacing: 15,
              alignment: WrapAlignment.start,
              children: system.systemData.skills.map((domain) {
                return _buildInlineDomainCard(domain, system, colors);
              }).toList(),
            )
          ),
        ),
      ],
    );
  }

  Widget _buildInlineDomainCard(SkillNode domain, SystemController system, AppColors colors) {
    String rankLetter = 'E'; Color rankColor = colors.danger;
    if (domain.progress >= 100) { rankLetter = 'S'; rankColor = const Color(0xFFFFB300); }
    else if (domain.progress >= 80) { rankLetter = 'A'; rankColor = colors.accent; }
    else if (domain.progress >= 60) { rankLetter = 'B'; rankColor = const Color(0xFF2196F3); }
    else if (domain.progress >= 40) { rankLetter = 'C'; rankColor = const Color(0xFF9C27B0); }
    else if (domain.progress >= 20) { rankLetter = 'D'; rankColor = const Color(0xFFFF9800); }

    bool isMobile = MediaQuery.of(context).size.width < 800;
    double cardWidth = isMobile ? double.infinity : 280;

    return Container(
      width: cardWidth, height: 160, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: colors.altCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(domain.name, style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              Container(width: 30, height: 30, decoration: BoxDecoration(border: Border.all(color: rankColor, width: 2), borderRadius: BorderRadius.circular(5)), child: Center(child: Text(rankLetter, style: TextStyle(color: rankColor, fontSize: 16, fontWeight: FontWeight.bold))))
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Progress:", style: TextStyle(color: colors.subText, fontSize: 12)),
              Text("${domain.progress.toStringAsFixed(1)}%", style: TextStyle(color: colors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(value: domain.progress / 100.0, backgroundColor: colors.inputBg, color: colors.accent, minHeight: 6, borderRadius: BorderRadius.circular(3)),
          const Spacer(),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: () => openSlidePanel(domain), style: ElevatedButton.styleFrom(backgroundColor: colors.inputBg, foregroundColor: colors.accent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))), child: const Text("ACCESS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)))),
              const SizedBox(width: 5),
              Container(width: 40, height: 40, decoration: BoxDecoration(color: colors.inputBg, borderRadius: BorderRadius.circular(5)), child: IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => _showRenameDialog(context, system, domain, colors))),
              const SizedBox(width: 5),
              Container(width: 40, height: 40, decoration: BoxDecoration(color: colors.danger, borderRadius: BorderRadius.circular(5)), child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => system.deleteDomain(domain.id))),
            ],
          )
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, SystemController system, SkillNode node, AppColors colors) {
    TextEditingController editController = TextEditingController(text: node.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.card,
        title: Text("Rename Node", style: TextStyle(color: colors.text)),
        content: TextField(controller: editController, style: TextStyle(color: colors.text), decoration: InputDecoration(filled: true, fillColor: colors.inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: TextStyle(color: colors.subText))),
          TextButton(onPressed: () { if (editController.text.isNotEmpty) system.renameNode(node, editController.text); Navigator.pop(context); }, child: Text("SAVE", style: TextStyle(color: colors.accent))),
        ],
      ),
    );
  }

// ===========================================================================
  // ⚙️ SETTINGS PANEL
  // ===========================================================================
  Widget _buildSettingsView(SystemController system, AppColors colors) {
    TextEditingController ipController = TextEditingController();
    bool isMobile = MediaQuery.of(context).size.width < 800;

    Widget appearanceContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Dark Mode", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text("Toggle between Light and Dark aesthetics.", textAlign: TextAlign.center, style: TextStyle(color: colors.subText, fontSize: 12)),
        const SizedBox(height: 10),
        Switch(value: system.systemData.isDarkMode, activeColor: colors.accent, onChanged: (val) => system.toggleTheme()),
      ],
    );

    Widget difficultyContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Hard Mode (Penalty Zone)", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text("Enable extreme loss aversion. Incomplete daily tasks at midnight will trigger a system lock.", textAlign: TextAlign.center, style: TextStyle(color: colors.subText, fontSize: 12)),
        const SizedBox(height: 15),
        Switch(value: system.systemData.isPenaltyEnabled, activeColor: colors.danger, onChanged: (val) => system.togglePenaltyMode()),
      ],
    );

    Widget syncContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (system.syncEngine.discoveredDevices.isNotEmpty) ...[
          Text("DISCOVERED VAULTS", style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(color: colors.inputBg, borderRadius: BorderRadius.circular(8)),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: system.syncEngine.discoveredDevices.length,
              itemBuilder: (context, index) {
                var device = system.syncEngine.discoveredDevices[index];
                return ListTile(
                  leading: Icon(Icons.computer, color: colors.accent),
                  title: Text(device.name, style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
                  subtitle: Text(device.ip, style: TextStyle(color: colors.subText, fontSize: 10)),
                  trailing: ElevatedButton(
                    onPressed: () => system.syncWithDevice(device.ip),
                    style: ElevatedButton.styleFrom(backgroundColor: colors.accent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 10)),
                    child: const Text("SYNC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),
        ],
        
        ElevatedButton.icon(
          onPressed: system.isScanning ? null : () => system.runRadarScan(), 
          icon: system.isScanning ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.radar), 
          label: Text(system.isScanning ? "SCANNING..." : "RADAR SCAN", style: const TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: colors.accent, foregroundColor: Colors.black, elevation: 0)
        ),
        
        if (system.syncStatusMessage.isNotEmpty && !system.syncStatusMessage.contains("SECURITY") && !system.syncStatusMessage.contains("EXPORT")) 
          Padding(
            padding: const EdgeInsets.only(top: 15), 
            child: Text(system.syncStatusMessage, textAlign: TextAlign.center, style: TextStyle(color: system.syncStatusMessage.contains("ERROR") ? colors.danger : const Color(0xFF00BFA5), fontWeight: FontWeight.bold, fontSize: 12))
          ),

        const SizedBox(height: 25),
        Divider(color: colors.border),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Designate as Master Node", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Master data always overwrites Slave data.", style: TextStyle(color: colors.danger, fontSize: 10)),
                ],
              ),
            ),
            Switch(
              value: system.systemData.isMasterDevice, 
              activeColor: colors.danger, 
              onChanged: (val) {
                setState(() {
                  system.systemData.isMasterDevice = val;
                  system.recalculateSystem();
                });
              }
            ),
          ],
        ),
      ],
    );

    Widget backupContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
            if (selectedDirectory != null) system.exportData('$selectedDirectory/vault_backup.prg');
          }, 
          icon: const Icon(Icons.upload_file),
          label: const Text("EXPORT VAULT DATA", style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: colors.inputBg, foregroundColor: colors.accent, elevation: 0)
        ),
        const SizedBox(height: 15),
        ElevatedButton.icon(
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles();
            if (result != null && result.files.single.path != null) system.importData(result.files.single.path!);
          }, 
          icon: const Icon(Icons.download),
          label: const Text("RESTORE FROM BACKUP", style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: colors.inputBg, foregroundColor: const Color(0xFFFF9800), elevation: 0)
        ),
        if (system.syncStatusMessage.contains("PORT") || system.syncStatusMessage.contains("IMPORT") || system.syncStatusMessage.contains("EXPORT")) 
          Padding(padding: const EdgeInsets.only(top: 15), child: Text(system.syncStatusMessage, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF00BFA5), fontWeight: FontWeight.bold))),
      ],
    );

    Widget resetContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("WARNING", style: TextStyle(color: colors.danger, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text("Irreversibly purges the Vault and destroys all System Progress.", textAlign: TextAlign.center, style: TextStyle(color: colors.subText, fontSize: 12)),
        const SizedBox(height: 25),
        ElevatedButton(
          onPressed: () => _showResetWarning1(context, system), 
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: colors.danger, foregroundColor: Colors.white, elevation: 0), 
          child: const Text("WIPE SYSTEM")
        )
      ],
    );

    // =========================================================================
    // THE DYNAMIC LAYOUT BUILDER
    // =========================================================================
    return LayoutBuilder(
      builder: (context, constraints) {
        double spacing = 20.0;
        int crossAxisCount = constraints.maxWidth > 1100 ? 5 : 2; 
        
        // FIX: Safely calculate width without using double.infinity
        double cardWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        Widget buildSquareCard({required String title, required Widget child, Color? borderColor, Color? titleColor}) {
          return Container(
            width: cardWidth,
            // FIX: Auto-height on mobile (null), fixed height (400) on desktop grids
            height: isMobile ? null : 400, 
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor ?? colors.border, width: borderColor != null ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              // FIX: Shrink-wrap the column vertically on mobile
              mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max, 
              children: [
                Text(title, textAlign: TextAlign.center, style: TextStyle(color: titleColor ?? colors.accent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 20),
                // FIX: Remove 'Expanded' on mobile so the layout can naturally size itself without crashing
                if (isMobile)
                  child
                else
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(child: child),
                    ),
                  ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("SYSTEM CONFIGURATION", style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 20),
              Wrap(
                spacing: spacing, 
                runSpacing: spacing, 
                alignment: WrapAlignment.start, 
                children: [
                  buildSquareCard(title: "🎨 SYSTEM APPEARANCE", child: appearanceContent),
                  buildSquareCard(title: "⚔️ SYSTEM DIFFICULTY", child: difficultyContent, titleColor: system.systemData.isPenaltyEnabled ? colors.danger : colors.accent, borderColor: system.systemData.isPenaltyEnabled ? colors.danger : colors.border),
                  buildSquareCard(title: "📡 WI-FI AUTO-SYNC", child: syncContent),
                  buildSquareCard(title: "💾 VAULT BACKUP (.PRG)", child: backupContent),
                  buildSquareCard(title: "⚠️ FACTORY RESET", child: resetContent, titleColor: colors.danger, borderColor: colors.danger),
                ]
              )
            ],
          ),
        );
      }
    );
  }
  // ===========================================================================
  // 🧑 PROFILE PANEL
  // ===========================================================================
  Widget _buildUserProfileView(SystemController system, AppColors colors) {
    TextEditingController nameController = TextEditingController(text: system.systemData.profileName);
    TextEditingController userController = TextEditingController(text: system.systemData.username);
    TextEditingController passController = TextEditingController(); 

    bool hasPhoto = system.systemData.profilePhotoUrl.isNotEmpty && File(system.systemData.profilePhotoUrl).existsSync();
    bool isMobile = MediaQuery.of(context).size.width < 800;

    Widget buildSquareCard({required String title, required Widget child, Color? borderColor}) {
      return Container(
        width: isMobile ? double.infinity : 380,
        height: isMobile ? null : 380, 
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor ?? colors.border, width: borderColor != null ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: SingleChildScrollView(child: child),
              ),
            ),
          ],
        ),
      );
    }

    Widget identityContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50, backgroundColor: colors.inputBg,
              backgroundImage: hasPhoto ? FileImage(File(system.systemData.profilePhotoUrl)) : null,
              child: !hasPhoto ? Text(system.systemData.profileName.isNotEmpty ? system.systemData.profileName[0].toUpperCase() : "U", style: TextStyle(color: colors.text, fontSize: 36, fontWeight: FontWeight.bold)) : null,
            ),
            Container(
              decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
              child: IconButton(
                icon: Icon(Icons.camera_alt, color: colors.invertText, size: 20),
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null && result.files.single.path != null) {
                    system.updateProfile(system.systemData.profileName, system.systemData.profileDesc, result.files.single.path!);
                  }
                },
              ),
            )
          ],
        ),
        const SizedBox(height: 15),
        Text("Level ${system.currentStreak} Awakened", style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 15),
        TextField(controller: nameController, textAlign: TextAlign.center, style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold), decoration: InputDecoration(filled: true, fillColor: colors.inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: () => system.updateProfile(nameController.text, system.systemData.profileDesc, system.systemData.profilePhotoUrl), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40), backgroundColor: colors.inputBg, foregroundColor: colors.text, elevation: 0), child: const Text("UPDATE IDENTITY", style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    );

    Widget radarContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 180, height: 180, 
          decoration: BoxDecoration(color: colors.inputBg, shape: BoxShape.circle),
          child: CustomPaint(
            painter: StatRadarPainter(
              str: system.statSTR, intl: system.statINT, 
              agi: system.statAGI, wil: system.statWIL, 
              accentColor: colors.accent
            ),
          ),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(children: [Text("STR", style: TextStyle(color: colors.subText, fontSize: 12)), Text("${system.statSTR.toInt()}", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 16))]),
            Column(children: [Text("INT", style: TextStyle(color: colors.subText, fontSize: 12)), Text("${system.statINT.toInt()}", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 16))]),
            Column(children: [Text("WIL", style: TextStyle(color: colors.subText, fontSize: 12)), Text("${system.statWIL.toInt()}", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 16))]),
            Column(children: [Text("AGI", style: TextStyle(color: colors.subText, fontSize: 12)), Text("${system.statAGI.toInt()}", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 16))]),
          ],
        )
      ],
    );

    Widget secretsContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(controller: userController, textAlign: TextAlign.center, style: TextStyle(color: colors.text), decoration: InputDecoration(hintText: "New Username", hintStyle: TextStyle(color: colors.subText), filled: true, fillColor: colors.inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
        const SizedBox(height: 15),
        TextField(controller: passController, textAlign: TextAlign.center, obscureText: true, style: TextStyle(color: colors.text), decoration: InputDecoration(hintText: "New Password", hintStyle: TextStyle(color: colors.subText), filled: true, fillColor: colors.inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
        const SizedBox(height: 25),
        ElevatedButton(onPressed: () { system.updateCredentials(userController.text, passController.text); passController.clear(); }, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: colors.inputBg, foregroundColor: const Color(0xFF00BFA5), elevation: 0), child: const Text("CHANGE CREDENTIALS", style: TextStyle(fontWeight: FontWeight.bold))),
        if (system.syncStatusMessage.contains("SECURITY")) Padding(padding: const EdgeInsets.only(top: 15), child: Text(system.syncStatusMessage, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF00BFA5), fontWeight: FontWeight.bold))),
      ],
    );

    Widget exitContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Disconnect from the current session. Your progress is saved locally.", textAlign: TextAlign.center, style: TextStyle(color: colors.subText, fontSize: 12)),
        const SizedBox(height: 25),
        ElevatedButton(onPressed: () => system.logoutUser(), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.transparent, foregroundColor: colors.danger, elevation: 0, side: BorderSide(color: colors.danger, width: 2)), child: const Text("LOGOUT OF SYSTEM", style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("STATUS WINDOW", style: TextStyle(color: colors.text, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 30),
          
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.start,
            children: [
              buildSquareCard(title: "HUNTER IDENTITY", borderColor: colors.accent, child: identityContent),
              buildSquareCard(title: "ATTRIBUTE RADAR", child: radarContent),
              buildSquareCard(title: "SYSTEM SECRETS", child: secretsContent),
              buildSquareCard(title: "EXIT VAULT", borderColor: colors.danger.withOpacity(0.5), child: exitContent),
            ],
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🎧 FLOW STATE AUDIO DECK 
  // ===========================================================================
  void _showAudioDeck(BuildContext context, SystemController system, AppColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: colors.accent)),
        title: Row(
          children: [
            Icon(Icons.graphic_eq, color: colors.accent),
            const SizedBox(width: 10),
            Text("FLOW STATE DECK", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("STATUS: ${system.currentTrackName}", style: TextStyle(color: system.isAudioPlaying ? const Color(0xFF00BFA5) : colors.subText, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            
            ListTile(
              leading: Icon(Icons.upload_file, color: colors.accent),
              title: Text("Upload Custom Audio", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.white),
                onPressed: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
                  if (result != null && result.files.single.path != null) {
                    system.playLocalAudio(result.files.single.path!, result.files.single.name);
                    Navigator.pop(ctx);
                  }
                }
              ),
            ),
            Divider(color: colors.border),
            
            ListTile(
              leading: const Icon(Icons.water_drop, color: Colors.blue),
              title: Text("Heavy Rain", style: TextStyle(color: colors.text)),
              trailing: IconButton(
                icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                onPressed: () {
                  system.playAudioStream("https://actions.google.com/sounds/v1/weather/rain_heavy_loud.ogg", "Heavy Rain");
                  Navigator.pop(ctx);
                }
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.waves, color: Colors.brown),
              title: Text("Deep Space Focus", style: TextStyle(color: colors.text)),
              trailing: IconButton(
                icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                onPressed: () {
                  system.playAudioStream("https://actions.google.com/sounds/v1/science_fiction/outer_space.ogg", "Deep Space");
                  Navigator.pop(ctx);
                }
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.forest, color: Colors.green),
              title: Text("Forest Wind", style: TextStyle(color: colors.text)),
              trailing: IconButton(
                icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                onPressed: () {
                  system.playAudioStream("https://actions.google.com/sounds/v1/weather/forest_wind_summer.ogg", "Forest Wind");
                  Navigator.pop(ctx);
                }
              ),
            ),
            
            const SizedBox(height: 20),
            if (system.isAudioPlaying)
              ElevatedButton.icon(
                onPressed: () {
                  system.stopAudio();
                  Navigator.pop(ctx);
                }, 
                icon: const Icon(Icons.stop), 
                label: const Text("TERMINATE AUDIO"),
                style: ElevatedButton.styleFrom(backgroundColor: colors.danger, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
              )
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 📖 SYSTEM GUIDE DIALOG (NEW)
  // ===========================================================================
  void _showSystemGuide(BuildContext context, AppColors colors) {
    Widget buildGuideSection(String title, String description) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: colors.accent, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(color: colors.subText, fontSize: 14, height: 1.5)),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: colors.border)),
        child: Container(
          width: 800,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, color: colors.accent, size: 28),
                      const SizedBox(width: 10),
                      Text("SYSTEM MANUAL", style: TextStyle(color: colors.text, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ]
                  ),
                  IconButton(icon: Icon(Icons.close, color: colors.subText), onPressed: () => Navigator.pop(ctx))
                ],
              ),
              Divider(color: colors.border, height: 30),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildGuideSection("📁 Domains & Skills", "The core structure of your progression. Create high-level Domains (e.g., 'Computer Science', 'Physical Health') and break them down into actionable Skills. Click 'ACCESS' to dive deeper into a Domain hierarchy. Checking off Skills increases your Domain mastery percentage."),
                      buildGuideSection("⏱️ Focus Engine", "Inside a Domain, click 'FOCUS' next to a Skill to launch the Timer. Deep work hours logged here permanently level up your Core Attributes (STR for physical, INT for learning) visible on your Status Radar in your profile."),
                      buildGuideSection("📅 Daily Tasks & Strategic Milestones", "Daily Tasks: Log your daily requirements. If you fail to complete them and 'Hard Mode' is enabled, your System will enter an Accountability Lock.\nStrategic Milestones: Set massive, time-boxed goals with a strict deadline. You must mark them as Achieved before the clock runs out."),
                      buildGuideSection("🧠 The Mind Web", "Visualize your thoughts and plans. The System automatically generates a read-only map of your current Domains. You can also forge Custom Maps using 4 distinct physics engines: Balanced (Radial), Logic Chart (Right-aligned), Org Chart (Top-down), and Timeline."),
                      buildGuideSection("🎧 Flow State Audio", "Click the Headphones icon on the right to access ambient background audio. You can play built-in focus tracks (Rain, Brown Noise) or click 'Upload Custom Audio' to loop your own MP3 or OGG files locally."),
                      buildGuideSection("🏆 Analytics & Vault", "Track your progression over time. The System automatically awards Badges as you hit global milestones, complete tasks, and log focus hours. Your current continuous 'Streak' (🔥) is displayed at the top of the sidebar."),
                      buildGuideSection("⚠️ Hard Mode (Accountability Lock)", "Found in the Settings tab. If enabled, missing a pending Daily Task at midnight will trigger an Accountability Lock the following day, requiring you to commit to an action before regaining access to your tools."),
                    ],
                  ),
                ),
              )
            ]
          )
        )
      )
    );
  }
}

class StatRadarPainter extends CustomPainter {
  final double str, intl, agi, wil;
  final Color accentColor;
  StatRadarPainter({required this.str, required this.intl, required this.agi, required this.wil, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    double cx = size.width / 2; double cy = size.height / 2;
    double radius = size.width / 2 - 25; 

    // Scaled Radar Buffer. 
    // Forces a minimum max scale of 50, and always adds a 25% empty buffer ring so stats never touch the edge perfectly.
    double highestStat = [str, intl, agi, wil, 10.0].reduce((a, b) => a > b ? a : b);
    double maxStat = highestStat < 50.0 ? 50.0 : highestStat * 1.25;

    final gridPaint = Paint()..color = Colors.grey.withOpacity(0.2)..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, cy - radius), Offset(cx, cy + radius), gridPaint); 
    canvas.drawLine(Offset(cx - radius, cy), Offset(cx + radius, cy), gridPaint); 
    canvas.drawCircle(Offset(cx, cy), radius * 0.5, gridPaint);
    canvas.drawCircle(Offset(cx, cy), radius, gridPaint);

    Offset pStr = Offset(cx, cy - (str / maxStat) * radius);
    Offset pInt = Offset(cx + (intl / maxStat) * radius, cy);
    Offset pWil = Offset(cx, cy + (wil / maxStat) * radius);
    Offset pAgi = Offset(cx - (agi / maxStat) * radius, cy);

    final shapePath = Path()..moveTo(pStr.dx, pStr.dy)..lineTo(pInt.dx, pInt.dy)..lineTo(pWil.dx, pWil.dy)..lineTo(pAgi.dx, pAgi.dy)..close();
    canvas.drawPath(shapePath, Paint()..color = accentColor.withOpacity(0.3)..style = PaintingStyle.fill);
    canvas.drawPath(shapePath, Paint()..color = accentColor..strokeWidth = 2..style = PaintingStyle.stroke);

    final textStyle = TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 10);
    _drawLabel(canvas, "STR", Offset(cx, cy - radius - 12), textStyle);
    _drawLabel(canvas, "INT", Offset(cx + radius + 15, cy), textStyle);
    _drawLabel(canvas, "WIL", Offset(cx, cy + radius + 12), textStyle);
    _drawLabel(canvas, "AGI", Offset(cx - radius - 15, cy), textStyle);
  }

  void _drawLabel(Canvas c, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(c, Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2));
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}