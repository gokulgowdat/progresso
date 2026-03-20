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
            icon: Icon(Icons.settings, color: activeTab == 'settings' ? colors.accent : colors.subText), 
            onPressed: () => setState(() { activeTab = 'settings'; closeSlidePanel(); })
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15, left: 10),
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
                const Spacer(),
                
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
            child: system.systemData.isCardView 
              ? Wrap(
                  spacing: 15, runSpacing: 15,
                  alignment: WrapAlignment.start,
                  children: system.systemData.skills.map((domain) {
                    return _buildInlineDomainCard(domain, system, colors);
                  }).toList(),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: system.systemData.skills.length,
                  itemBuilder: (context, index) {
                    final domain = system.systemData.skills[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: colors.altCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(domain.name, style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Progress: ${domain.progress.toStringAsFixed(1)}%", style: TextStyle(color: colors.subText, fontSize: 12)),
                              const SizedBox(height: 5),
                              LinearProgressIndicator(value: domain.progress / 100.0, backgroundColor: colors.inputBg, color: colors.accent, minHeight: 4, borderRadius: BorderRadius.circular(2)),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(onPressed: () => openSlidePanel(domain), style: ElevatedButton.styleFrom(backgroundColor: colors.inputBg, foregroundColor: colors.accent, elevation: 0), child: const Text("ACCESS")),
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showRenameDialog(context, system, domain, colors)),
                            IconButton(icon: Icon(Icons.close, color: colors.danger), onPressed: () => system.deleteDomain(domain.id)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
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
  // ⚙️ THE STRICT GEOMETRIC SETTINGS PANEL
  // ===========================================================================
  Widget _buildSettingsView(SystemController system, AppColors colors) {
    TextEditingController ipController = TextEditingController();
    bool isMobile = MediaQuery.of(context).size.width < 800;
    bool isCard = system.systemData.isCardView && !isMobile;

    // The Universal Square Card Generator
    Widget buildSquareCard({required String title, required Widget child, Color? borderColor, Color? titleColor}) {
      return Container(
        width: isMobile ? double.infinity : 350,
        height: isMobile ? null : 350, // Fixed perfect square height
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor ?? colors.border, width: borderColor != null ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: titleColor ?? colors.accent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 20),
            Expanded(
              // Center the content both vertically and horizontally inside the square
              child: Center(
                child: SingleChildScrollView(child: child),
              ),
            ),
          ],
        ),
      );
    }

    Widget appearanceContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Dark Mode", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text("Toggle between Light and Dark aesthetics.", textAlign: TextAlign.center, style: TextStyle(color: colors.subText, fontSize: 12)),
        const SizedBox(height: 10),
        Switch(value: system.systemData.isDarkMode, activeColor: colors.accent, onChanged: (val) => system.toggleTheme()),
        const SizedBox(height: 20),
        Divider(color: colors.border),
        const SizedBox(height: 20),
        Text("Card View", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text("Toggle grid layout versus list layout.", textAlign: TextAlign.center, style: TextStyle(color: colors.subText, fontSize: 12)),
        const SizedBox(height: 10),
        Switch(value: system.systemData.isCardView, activeColor: colors.accent, onChanged: (val) => system.toggleViewMode()),
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
        Text("YOUR SYSTEM IP:", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(system.syncEngine.localIp, style: const TextStyle(color: Color(0xFF00BFA5), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        const SizedBox(height: 20),
        TextField(controller: ipController, textAlign: TextAlign.center, style: TextStyle(color: colors.text), decoration: InputDecoration(hintText: "Enter Target IP...", hintStyle: TextStyle(color: colors.subText), filled: true, fillColor: colors.inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
        const SizedBox(height: 15),
        ElevatedButton(onPressed: () => system.syncWithDevice(ipController.text), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: colors.accent, foregroundColor: colors.invertText, elevation: 0), child: const Text("INITIATE SYNC", style: TextStyle(fontWeight: FontWeight.bold))),
        if (system.syncStatusMessage.isNotEmpty && !system.syncStatusMessage.contains("SECURITY") && !system.syncStatusMessage.contains("PORT")) 
          Padding(padding: const EdgeInsets.only(top: 15), child: Text(system.syncStatusMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
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
        ElevatedButton(onPressed: () { system.masterReset(); setState(() => activeTab = 'domains'); }, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: colors.danger, foregroundColor: Colors.white, elevation: 0), child: const Text("WIPE SYSTEM"))
      ],
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("SYSTEM CONFIGURATION", style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 20),
          if (isCard)
            Wrap(
              spacing: 20, 
              runSpacing: 20, 
              alignment: WrapAlignment.start, // Ensures perfect grid alignment on the left
              children: [
                buildSquareCard(title: "🎨 SYSTEM APPEARANCE", child: appearanceContent),
                buildSquareCard(title: "⚔️ SYSTEM DIFFICULTY", child: difficultyContent, titleColor: system.systemData.isPenaltyEnabled ? colors.danger : colors.accent, borderColor: system.systemData.isPenaltyEnabled ? colors.danger : colors.border),
                buildSquareCard(title: "📡 WI-FI AUTO-SYNC", child: syncContent),
                buildSquareCard(title: "💾 VAULT BACKUP (.PRG)", child: backupContent),
                buildSquareCard(title: "⚠️ FACTORY RESET", child: resetContent, titleColor: colors.danger, borderColor: colors.danger),
              ]
            )
          else
            Column(
              children: [
                buildSquareCard(title: "🎨 SYSTEM APPEARANCE", child: appearanceContent), const SizedBox(height: 15),
                buildSquareCard(title: "⚔️ SYSTEM DIFFICULTY", child: difficultyContent, titleColor: system.systemData.isPenaltyEnabled ? colors.danger : colors.accent, borderColor: system.systemData.isPenaltyEnabled ? colors.danger : colors.border), const SizedBox(height: 15),
                buildSquareCard(title: "📡 WI-FI AUTO-SYNC", child: syncContent), const SizedBox(height: 15),
                buildSquareCard(title: "💾 VAULT BACKUP (.PRG)", child: backupContent), const SizedBox(height: 15),
                buildSquareCard(title: "⚠️ FACTORY RESET", child: resetContent, titleColor: colors.danger, borderColor: colors.danger),
              ]
            )
        ],
      ),
    );
  }

  // ===========================================================================
  // 🧑 THE PERFECT SQUARE "STATUS WINDOW" PROFILE PANEL
  // ===========================================================================
  Widget _buildUserProfileView(SystemController system, AppColors colors) {
    TextEditingController nameController = TextEditingController(text: system.systemData.profileName);
    TextEditingController userController = TextEditingController(text: system.systemData.username);
    TextEditingController passController = TextEditingController(); 

    bool hasPhoto = system.systemData.profilePhotoUrl.isNotEmpty && File(system.systemData.profilePhotoUrl).existsSync();
    bool isMobile = MediaQuery.of(context).size.width < 800;

    // The Universal Square Card Generator (Profile Version)
    Widget buildSquareCard({required String title, required Widget child, Color? borderColor}) {
      return Container(
        width: isMobile ? double.infinity : 380,
        height: isMobile ? null : 380, // Perfect square height
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
              radius: 50, backgroundColor: colors.inputBg, // Slightly smaller to fit square perfectly
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
          width: 180, height: 180, // Sized perfectly for the 380 square box
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
}

// --- CUSTOM RADAR CHART PAINTER ---
class StatRadarPainter extends CustomPainter {
  final double str, intl, agi, wil;
  final Color accentColor;
  StatRadarPainter({required this.str, required this.intl, required this.agi, required this.wil, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    double cx = size.width / 2; double cy = size.height / 2;
    double radius = size.width / 2 - 25; 

    double maxStat = [str, intl, agi, wil, 10.0].reduce((a, b) => a > b ? a : b);

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