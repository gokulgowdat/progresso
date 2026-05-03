import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; 
import '../services/system_controller.dart';
import '../models/skill_node.dart';
import '../widgets/timer_overlay.dart';
import '../widgets/sticky_notes_overlay.dart'; 
import '../tabs/analytics_tab.dart';
import '../tabs/tasks_tab.dart';
import '../tabs/quest_log_tab.dart'; 
import '../tabs/achievements_tab.dart'; 
import '../tabs/mind_map_tab.dart'; 

// =========================================================================
// RELATIVE SCALING ENGINE (Fixed for Mobile)
// =========================================================================
class SizeConfig {
  static double screenWidth = 1440.0; 
  static void init(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
  }
}

extension ResponsiveDouble on num {
  double get rs {
    // THE FIX: Mobile screens are naturally narrow. Do NOT shrink UI on phones!
    if (SizeConfig.screenWidth < 800) {
      return this.toDouble(); 
    }
    
    // Desktops and laptops will still scale perfectly:
    double scaleFactor = (SizeConfig.screenWidth / 1440.0).clamp(0.75, 1.0);
    return this * scaleFactor;
  }
}
// =========================================================================

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

  bool isNotesPanelOpen = false; 
  bool isWifiMode = true;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

  int get _currentMainTabIndex {
    switch (activeTab) {
      case 'domains': return 0;
      case 'tasks': return 1;
      case 'calendar': return 2;
      case 'analytics': return 3;
      case 'badges': return 4;
      default: return -1; 
    }
  }

  void _showResetWarning1(BuildContext context, SystemController system) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text("⚠️ SYSTEM WIPE INITIATED", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18.rs)),
        content: Text("Are you absolutely sure? This will delete all Domains, Quests, Mind Maps, and Stats.", style: TextStyle(color: Colors.white, fontSize: 14.rs)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: TextStyle(color: Colors.grey, fontSize: 14.rs))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showResetWarning2(context, system);
            },
            child: Text("PROCEED", style: TextStyle(color: Colors.redAccent, fontSize: 14.rs)),
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
        title: Text("🛑 FINAL WARNING", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18.rs)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("This action is IRREVERSIBLE. To permanently destroy your Vault, you must type 'WIPE' below.", style: TextStyle(color: Colors.white, fontSize: 14.rs)),
            SizedBox(height: 15.rs),
            TextField(
              controller: confirmCtrl,
              style: TextStyle(color: Colors.white, fontSize: 14.rs),
              decoration: InputDecoration(
                hintText: "Type WIPE to confirm", 
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14.rs),
                filled: true,
                fillColor: const Color(0xFF171717)
              ),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("ABORT", style: TextStyle(color: Colors.grey, fontSize: 14.rs))),
          TextButton(
            onPressed: () {
              if (confirmCtrl.text.trim().toUpperCase() == 'WIPE') {
                Navigator.pop(ctx);
                system.masterReset();
                setState(() {
                  activeTab = 'domains';
                  if(_pageController.hasClients) _pageController.jumpToPage(0);
                });
              }
            },
            child: Text("DESTROY VAULT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14.rs)),
          ),
        ],
      ),
    );
  }

  void _showDomainExportDialog(BuildContext context, SystemController system, AppColors colors) {
    List<String> selectedIds = [];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: colors.card,
            title: Text("Select Domains to Export", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 18.rs)),
            content: SizedBox(
              width: double.maxFinite,
              child: system.systemData.skills.isEmpty 
                ? Text("No domains available.", style: TextStyle(color: colors.subText, fontSize: 14.rs))
                : ListView.builder(
                shrinkWrap: true,
                itemCount: system.systemData.skills.length,
                itemBuilder: (context, index) {
                  var domain = system.systemData.skills[index];
                  return CheckboxListTile(
                    title: Text(domain.name, style: TextStyle(color: colors.text, fontSize: 14.rs)),
                    value: selectedIds.contains(domain.id),
                    activeColor: colors.accent,
                    checkColor: colors.invertText,
                    onChanged: (val) {
                      setDialogState(() {
                        if (val == true) selectedIds.add(domain.id);
                        else selectedIds.remove(domain.id);
                      });
                    }
                  );
                }
              )
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: TextStyle(color: colors.subText, fontSize: 14.rs))),
              ElevatedButton(
                onPressed: selectedIds.isEmpty ? null : () async {
                  Navigator.pop(ctx);
                  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                  if (selectedDirectory != null) {
                    system.exportSpecificDomains(selectedIds, '$selectedDirectory/domain_modules.prg');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: colors.accent, foregroundColor: colors.invertText),
                child: Text("EXPORT SELECTED", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.rs))
              )
            ]
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context); 
    final system = context.watch<SystemController>();

    if (!system.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFEBFB7E))));
    }

    final colors = AppColors(system.systemData.isDarkMode);
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        children: [
          if (isMobile) 
            _buildMobileLayout(system, colors) 
          else 
            _buildDesktopLayout(system, colors),
            
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutExpo,
            top: 0,
            bottom: 0,
            right: isNotesPanelOpen ? 0 : -MediaQuery.of(context).size.width,
            width: MediaQuery.of(context).size.width,
            child: StickyNotesOverlay(
              onClose: () => setState(() => isNotesPanelOpen = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(SystemController system, AppColors colors) {
    bool hasPhoto = system.systemData.profilePhotoUrl.isNotEmpty && File(system.systemData.profilePhotoUrl).existsSync();
    int navIndex = _currentMainTabIndex;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.card,
        leading: navIndex == -1 
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: colors.text, size: 26), 
              onPressed: () {
                setState(() {
                  activeTab = 'domains';
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_pageController.hasClients) _pageController.jumpToPage(0);
                  });
                });
              },
            )
          : null,
        title: navIndex == -1 
          ? Text("System Menu", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 18)) 
          : Text("Rank: ${system.currentStreak} 🔥", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 18)), 
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(system.isAudioPlaying ? Icons.graphic_eq : Icons.headphones, color: system.isAudioPlaying ? const Color(0xFF00BFA5) : colors.subText, size: 26), 
            onPressed: () => _showAudioDeck(context, system, colors)
          ),
          IconButton(
            icon: Icon(Icons.hub, color: activeTab == 'mindmaps' ? colors.accent : colors.subText, size: 26), 
            onPressed: () => setState(() { activeTab = 'mindmaps'; closeSlidePanel(); })
          ),
          IconButton(
            icon: Icon(Icons.sticky_note_2, color: isNotesPanelOpen ? colors.accent : colors.subText, size: 26), 
            onPressed: () => setState(() { isNotesPanelOpen = !isNotesPanelOpen; closeSlidePanel(); })
          ),
          IconButton(
            icon: Icon(Icons.settings, color: activeTab == 'settings' ? colors.accent : colors.subText, size: 26), 
            onPressed: () => setState(() { activeTab = 'settings'; closeSlidePanel(); })
          ),
          Padding(
            padding: EdgeInsets.only(right: 15.rs, left: 5.rs),
            child: InkWell(
              onTap: () => setState(() { activeTab = 'user_profile'; closeSlidePanel(); }),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: colors.inputBg,
                backgroundImage: hasPhoto ? FileImage(File(system.systemData.profilePhotoUrl)) : null,
                child: !hasPhoto ? Text(system.systemData.profileName.isNotEmpty ? system.systemData.profileName[0].toUpperCase() : "U", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 14)) : null,
              ),
            ),
          )
        ],
      ),
      
      body: navIndex == -1 
        ? Padding(
            padding: EdgeInsets.all(15.0.rs),
            child: _buildRouterContent(system, colors),
          )
        : Padding(
            padding: EdgeInsets.all(15.0.rs),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(10.rs),
                  margin: EdgeInsets.only(bottom: 15.rs),
                  decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(8.rs), border: Border.all(color: colors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("SYSTEM PROGRESS", style: TextStyle(color: colors.subText, fontSize: 12.rs, fontWeight: FontWeight.bold)),
                          Text("${system.systemData.globalProgress.toStringAsFixed(1)}%", style: TextStyle(color: colors.accent, fontSize: 14.rs, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 8.rs),
                      LinearProgressIndicator(value: system.systemData.globalProgress / 100.0, backgroundColor: colors.inputBg, color: colors.accent, minHeight: 6.rs, borderRadius: BorderRadius.circular(3.rs)),
                    ],
                  ),
                ),
                
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        activeTab = ['domains', 'tasks', 'calendar', 'analytics', 'badges'][index];
                      });
                    },
                    children: [
                      _buildDomainsLayout(system, colors),
                      const TasksTab(),
                      const QuestLogTab(),
                      const AnalyticsTab(),
                      const AchievementsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
      bottomNavigationBar: navIndex == -1 ? null : BottomNavigationBar(
        backgroundColor: colors.card,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.subText,
        currentIndex: navIndex,
        selectedFontSize: 12, 
        unselectedFontSize: 12, 
        onTap: (index) {
          _pageController.animateToPage(
            index, 
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeOutQuart
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder, size: 26), label: "Domains"),
          BottomNavigationBarItem(icon: Icon(Icons.check_box, size: 26), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.map, size: 26), label: "Log"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart, size: 26), label: "Stats"),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events, size: 26), label: "Vault"),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(SystemController system, AppColors colors) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(30.0.rs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome back, ${system.systemData.profileName}.", style: TextStyle(color: colors.text, fontSize: 26.rs, fontWeight: FontWeight.bold)),
                SizedBox(height: 5.rs),
                Text(system.currentQuote, style: TextStyle(color: colors.accent, fontSize: 14.rs, fontStyle: FontStyle.italic)),
                SizedBox(height: 20.rs),

                Container(
                  padding: EdgeInsets.all(15.rs),
                  decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(10.rs), border: Border.all(color: colors.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("GLOBAL SYSTEM PROGRESS", style: TextStyle(color: colors.subText, fontSize: 16.rs, fontWeight: FontWeight.bold)),
                          Text("${system.systemData.globalProgress.toStringAsFixed(1)}%", style: TextStyle(color: colors.accent, fontSize: 20.rs, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 10.rs),
                      LinearProgressIndicator(value: system.systemData.globalProgress / 100.0, backgroundColor: colors.inputBg, color: colors.accent, minHeight: 12.rs, borderRadius: BorderRadius.circular(6.rs)),
                    ],
                  ),
                ),
                SizedBox(height: 20.rs),

                Row(
                  children: [
                    _buildTabButton("📁 DOMAINS", "domains", colors),
                    SizedBox(width: 10.rs),
                    _buildTabButton("📅 DAILY TASKS", "tasks", colors),
                    SizedBox(width: 10.rs),
                    _buildTabButton("🗺️ QUEST LOG", "calendar", colors),
                    SizedBox(width: 10.rs),
                    _buildTabButton("📊 ANALYTICS", "analytics", colors),
                    SizedBox(width: 10.rs),
                    _buildTabButton("🏆 ACHIEVEMENTS", "badges", colors),
                  ],
                ),
                SizedBox(height: 20.rs),

                Expanded(child: _buildRouterContent(system, colors)),
              ],
            ),
          ),
        ),

        Container(
          width: 70.rs,
          decoration: BoxDecoration(color: colors.card, border: Border(left: BorderSide(color: colors.border))),
          child: Column(
            children: [
              SizedBox(height: 20.rs),
              Text("🔥", style: TextStyle(fontSize: 28.rs)),
              Text("${system.currentStreak}", style: TextStyle(color: colors.text, fontSize: 16.rs, fontWeight: FontWeight.bold)),
              
              SizedBox(height: 30.rs),
              
              IconButton(
                icon: Icon(Icons.hub, color: activeTab == 'mindmaps' ? colors.accent : colors.subText, size: 28.rs),
                tooltip: "Mind Web Panel",
                onPressed: () { setState(() { activeTab = 'mindmaps'; closeSlidePanel(); }); }
              ),

              SizedBox(height: 15.rs),

              IconButton(
                icon: Icon(Icons.sticky_note_2, color: isNotesPanelOpen ? colors.accent : colors.subText, size: 28.rs),
                tooltip: "Scratchpad (Notes)",
                onPressed: () { setState(() { isNotesPanelOpen = !isNotesPanelOpen; }); }
              ),

              SizedBox(height: 15.rs),

              IconButton(
                icon: Icon(system.isAudioPlaying ? Icons.graphic_eq : Icons.headphones, 
                           color: system.isAudioPlaying ? const Color(0xFF00BFA5) : colors.subText, size: 28.rs),
                tooltip: "Flow State Audio",
                onPressed: () => _showAudioDeck(context, system, colors),
              ),

              const Spacer(),
              
              IconButton(
                icon: Icon(Icons.help_outline, color: colors.subText, size: 28.rs),
                tooltip: "System Guide",
                onPressed: () => _showSystemGuide(context, colors),
              ),

              SizedBox(height: 15.rs),
              
              IconButton(
                icon: Icon(Icons.settings, color: activeTab == 'settings' ? colors.accent : colors.subText, size: 28.rs), 
                onPressed: () { setState(() { activeTab = 'settings'; closeSlidePanel(); }); }
              ),
              
              SizedBox(height: 20.rs),
              
              Container(
                width: 50.rs, height: 50.rs, margin: EdgeInsets.only(bottom: 20.rs),
                decoration: BoxDecoration(color: colors.inputBg, borderRadius: BorderRadius.circular(8.rs), border: Border.all(color: activeTab == 'user_profile' ? colors.accent : colors.border, width: 2.rs)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () { setState(() { activeTab = 'user_profile'; closeSlidePanel(); }); },
                  child: system.systemData.profilePhotoUrl.isNotEmpty && File(system.systemData.profilePhotoUrl).existsSync()
                      ? Image.file(
                          File(system.systemData.profilePhotoUrl), 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(child: Text(system.systemData.profileName.isNotEmpty ? system.systemData.profileName[0].toUpperCase() : "U", style: TextStyle(color: colors.text, fontSize: 24.rs, fontWeight: FontWeight.bold)))
                        )
                      : Center(child: Text(system.systemData.profileName.isNotEmpty ? system.systemData.profileName[0].toUpperCase() : "U", style: TextStyle(color: colors.text, fontSize: 24.rs, fontWeight: FontWeight.bold))),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
          height: 40.rs,
          decoration: BoxDecoration(color: isActive ? colors.accent : colors.card, borderRadius: BorderRadius.circular(5.rs), border: Border.all(color: colors.border)),
          child: Center(child: Text(title, style: TextStyle(color: isActive ? colors.invertText : colors.text, fontWeight: FontWeight.bold, fontSize: 12.rs))),
        ),
      ),
    );
  }

  Widget _buildDomainsLayout(SystemController system, AppColors colors) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile && isSubPanelOpen && currentNode != null) {
      return Container(
        decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(8.rs), border: Border.all(color: colors.border)),
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
            width: isSubPanelOpen ? 450.rs : 0, 
            margin: EdgeInsets.only(right: isSubPanelOpen ? 20.rs : 0),
            decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(8.rs), border: Border.all(color: colors.border)),
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
          padding: EdgeInsets.all(15.rs), color: colors.inputBg,
          child: Row(
            children: [
              ElevatedButton(onPressed: goUp, style: ElevatedButton.styleFrom(backgroundColor: colors.border, foregroundColor: colors.accent, elevation: 0), child: Text("< UP", style: TextStyle(fontSize: 12.rs))),
              SizedBox(width: 15.rs),
              Expanded(child: Text(node.name.toUpperCase(), style: TextStyle(color: colors.text, fontSize: 18.rs, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              IconButton(icon: Icon(Icons.close, color: colors.subText, size: 20.rs), onPressed: closeSlidePanel),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(15.rs),
          child: Row(
            children: [
              Expanded(child: TextField(controller: subInputController, style: TextStyle(color: colors.text, fontSize: 14.rs), decoration: InputDecoration(hintText: "Add Sub-Domain or Skill...", hintStyle: TextStyle(color: colors.subText, fontSize: 14.rs), filled: true, fillColor: colors.bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.rs), borderSide: BorderSide.none)))),
              SizedBox(width: 10.rs),
              ElevatedButton(onPressed: () { system.addSubNode(node, subInputController.text, 'domain'); subInputController.clear(); }, style: ElevatedButton.styleFrom(backgroundColor: colors.border, foregroundColor: const Color(0xFF2196F3), elevation: 0), child: Text("+ DIR", style: TextStyle(fontSize: 12.rs))),
              SizedBox(width: 10.rs),
              ElevatedButton(onPressed: () { system.addSubNode(node, subInputController.text, 'skill'); subInputController.clear(); }, style: ElevatedButton.styleFrom(backgroundColor: colors.border, foregroundColor: const Color(0xFF00BFA5), elevation: 0), child: Text("+ SKILL", style: TextStyle(fontSize: 12.rs))),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 15.rs),
            itemCount: node.children.length,
            itemBuilder: (context, index) {
              var child = node.children[index];
              bool isSkill = child.type == 'skill';
              bool isDone = child.completed;

              return Container(
                margin: EdgeInsets.only(bottom: 10.rs), padding: EdgeInsets.symmetric(horizontal: 10.rs, vertical: 10.rs),
                decoration: BoxDecoration(color: isDone ? colors.successBg : colors.altCard, borderRadius: BorderRadius.circular(8.rs), border: Border.all(color: isDone ? const Color(0xFF2E7D32) : colors.border)),
                child: Row(
                  children: [
                    if (isSkill) Checkbox(value: isDone, activeColor: colors.accent, onChanged: (val) => system.toggleSkill(child, val ?? false)),
                    Text(isSkill ? "⚡ " : "📁 ", style: TextStyle(fontSize: 18.rs)),
                    Expanded(child: Text(child.name, style: TextStyle(color: isDone ? colors.subText : colors.text, fontSize: 14.rs, fontWeight: isSkill ? FontWeight.normal : FontWeight.bold, decoration: isDone ? TextDecoration.lineThrough : null), overflow: TextOverflow.ellipsis)),
                    
                    if (!isSkill) 
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.rs),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("${child.progress.toStringAsFixed(1)}%", style: TextStyle(color: colors.subText, fontSize: 10.rs, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4.rs),
                              LinearProgressIndicator(value: child.progress / 100.0, backgroundColor: colors.inputBg, color: const Color(0xFF2196F3), minHeight: 4.rs, borderRadius: BorderRadius.circular(2.rs)),
                            ],
                          ),
                        ),
                      ),
                    
                    if (isSkill) SizedBox(width: 5.rs),
                    if (isSkill) ElevatedButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => TimerOverlay(skill: child))),
                      style: ElevatedButton.styleFrom(backgroundColor: colors.inputBg, foregroundColor: const Color(0xFF00BFA5), elevation: 0, padding: EdgeInsets.symmetric(horizontal: 10.rs)), 
                      child: Text("FOCUS", style: TextStyle(fontSize: 12.rs)),
                    ),
                    if (!isSkill) SizedBox(width: 5.rs),
                    if (!isSkill) ElevatedButton(
                      onPressed: () => diveDeeper(child), 
                      style: ElevatedButton.styleFrom(backgroundColor: colors.inputBg, foregroundColor: colors.accent, elevation: 0, padding: EdgeInsets.symmetric(horizontal: 10.rs)), 
                      child: Text("ACCESS", style: TextStyle(fontSize: 12.rs))
                    ),
                    IconButton(icon: Icon(Icons.edit, color: Colors.blue, size: 18.rs), onPressed: () => _showRenameDialog(context, system, child, colors)),
                    IconButton(icon: Icon(Icons.close, color: colors.danger, size: 18.rs), onPressed: () => system.deleteSubNode(node, child.id)),
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
            Expanded(child: TextField(controller: inputController, style: TextStyle(color: colors.text, fontSize: 14.rs), decoration: InputDecoration(hintText: "Initialize new main domain...", hintStyle: TextStyle(color: colors.subText, fontSize: 14.rs), filled: true, fillColor: colors.card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.rs), borderSide: BorderSide(color: colors.border))))),
            SizedBox(width: 10.rs),
            InkWell(onTap: () { system.addDomain(inputController.text); inputController.clear(); }, child: Container(width: 55.rs, height: 55.rs, decoration: BoxDecoration(color: colors.accent, borderRadius: BorderRadius.circular(5.rs)), child: Center(child: Text("+", style: TextStyle(color: colors.invertText, fontSize: 28.rs, fontWeight: FontWeight.bold))))),
          ],
        ),
        SizedBox(height: 20.rs),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 15.rs, runSpacing: 15.rs,
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
    double cardWidth = isMobile ? double.infinity : 280.rs;

    return Container(
      width: cardWidth, height: 160.rs, padding: EdgeInsets.all(15.rs),
      decoration: BoxDecoration(color: colors.altCard, borderRadius: BorderRadius.circular(8.rs), border: Border.all(color: colors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(domain.name, style: TextStyle(color: colors.text, fontSize: 18.rs, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              Container(width: 30.rs, height: 30.rs, decoration: BoxDecoration(border: Border.all(color: rankColor, width: 2.rs), borderRadius: BorderRadius.circular(5.rs)), child: Center(child: Text(rankLetter, style: TextStyle(color: rankColor, fontSize: 16.rs, fontWeight: FontWeight.bold))))
            ],
          ),
          SizedBox(height: 15.rs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Progress:", style: TextStyle(color: colors.subText, fontSize: 12.rs)),
              Text("${domain.progress.toStringAsFixed(1)}%", style: TextStyle(color: colors.accent, fontSize: 12.rs, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 5.rs),
          LinearProgressIndicator(value: domain.progress / 100.0, backgroundColor: colors.inputBg, color: colors.accent, minHeight: 6.rs, borderRadius: BorderRadius.circular(3.rs)),
          const Spacer(),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: () => openSlidePanel(domain), style: ElevatedButton.styleFrom(backgroundColor: colors.inputBg, foregroundColor: colors.accent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.rs))), child: Text("ACCESS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12.rs)))),
              SizedBox(width: 5.rs),
              Container(width: 40.rs, height: 40.rs, decoration: BoxDecoration(color: colors.inputBg, borderRadius: BorderRadius.circular(5.rs)), child: IconButton(icon: Icon(Icons.edit, color: Colors.blue, size: 20.rs), onPressed: () => _showRenameDialog(context, system, domain, colors))),
              SizedBox(width: 5.rs),
              Container(width: 40.rs, height: 40.rs, decoration: BoxDecoration(color: colors.danger, borderRadius: BorderRadius.circular(5.rs)), child: IconButton(icon: Icon(Icons.close, color: Colors.white, size: 20.rs), onPressed: () => system.deleteDomain(domain.id))),
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
        title: Text("Rename Node", style: TextStyle(color: colors.text, fontSize: 18.rs)),
        content: TextField(controller: editController, style: TextStyle(color: colors.text, fontSize: 14.rs), decoration: InputDecoration(filled: true, fillColor: colors.inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.rs), borderSide: BorderSide.none))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: TextStyle(color: colors.subText, fontSize: 14.rs))),
          TextButton(onPressed: () { if (editController.text.isNotEmpty) system.renameNode(node, editController.text); Navigator.pop(context); }, child: Text("SAVE", style: TextStyle(color: colors.accent, fontSize: 14.rs))),
        ],
      ),
    );
  }

  Widget _buildSettingsView(SystemController system, AppColors colors) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    Widget appearanceContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Dark Mode", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 14.rs)),
        SizedBox(height: 5.rs),
        Text("Toggle between Light and Dark aesthetics.", textAlign: TextAlign.center, style: TextStyle(color: colors.subText, fontSize: 12.rs)),
        SizedBox(height: 10.rs),
        Switch(value: system.systemData.isDarkMode, activeColor: colors.accent, onChanged: (val) => system.toggleTheme()),
      ],
    );

    Widget difficultyContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Hard Mode (Penalty Zone)", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 14.rs)),
        SizedBox(height: 5.rs),
        Text("Enable extreme loss aversion. Incomplete daily tasks at midnight will trigger a system lock.", textAlign: TextAlign.center, style: TextStyle(color: colors.subText, fontSize: 12.rs)),
        SizedBox(height: 15.rs),
        Switch(value: system.systemData.isPenaltyEnabled, activeColor: colors.danger, onChanged: (val) => system.togglePenaltyMode()),
      ],
    );

    TextEditingController deviceNameCtrl = TextEditingController(text: system.systemData.deviceName);

    Widget syncContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // =========================================================================
        // NEW: DEVICE IDENTITY TEXT BOX
        // =========================================================================
        TextField(
          controller: deviceNameCtrl,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.text, fontSize: 14.rs, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: "Device Radar Name",
            labelStyle: TextStyle(color: colors.subText, fontSize: 12.rs),
            suffixText: system.systemData.deviceShortId.isNotEmpty ? "#${system.systemData.deviceShortId}" : "",
            suffixStyle: TextStyle(color: colors.subText, fontWeight: FontWeight.bold, fontSize: 14.rs),
            filled: true, 
            fillColor: colors.inputBg, 
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.rs), borderSide: BorderSide.none)
          ),
          onSubmitted: (val) => system.updateDeviceName(val),
        ),
        SizedBox(height: 10.rs),
        ElevatedButton(
          onPressed: () => system.updateDeviceName(deviceNameCtrl.text),
          style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 35.rs), backgroundColor: colors.inputBg, foregroundColor: colors.accent, elevation: 0),
          child: Text("SET IDENTITY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.rs)),
        ),
        SizedBox(height: 20.rs),
        Divider(color: colors.border),
        SizedBox(height: 20.rs),
        // =========================================================================

        Container(
          decoration: BoxDecoration(
            color: colors.inputBg,
            borderRadius: BorderRadius.circular(8.rs),
            border: Border.all(color: colors.border)
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => isWifiMode = true),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.rs),
                    decoration: BoxDecoration(
                      color: isWifiMode ? colors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(7.rs)
                    ),
                    child: Center(
                      child: Text("WiFi IP", style: TextStyle(color: isWifiMode ? Colors.black : colors.subText, fontWeight: FontWeight.bold, fontSize: 12.rs))
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => isWifiMode = false),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.rs),
                    decoration: BoxDecoration(
                      color: !isWifiMode ? Colors.blueAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(7.rs)
                    ),
                    child: Center(
                      child: Text("Bluetooth", style: TextStyle(color: !isWifiMode ? Colors.white : colors.subText, fontWeight: FontWeight.bold, fontSize: 12.rs))
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        SizedBox(height: 15.rs),

        if (isWifiMode && system.syncEngine.discoveredDevices.isNotEmpty) ...[
          Container(
            constraints: BoxConstraints(maxHeight: 120.rs),
            decoration: BoxDecoration(color: colors.inputBg, borderRadius: BorderRadius.circular(8.rs)),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: system.syncEngine.discoveredDevices.length,
              itemBuilder: (context, index) {
                var device = system.syncEngine.discoveredDevices[index];
                return ListTile(
                  leading: Icon(Icons.computer, color: colors.accent, size: 20.rs),
                  title: Text(device.name, style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 14.rs)),
                  subtitle: Text(device.ip, style: TextStyle(color: colors.subText, fontSize: 10.rs)),
                  trailing: ElevatedButton(
                    onPressed: () => system.syncWithDevice(device.ip),
                    style: ElevatedButton.styleFrom(backgroundColor: colors.accent, foregroundColor: Colors.black, padding: EdgeInsets.symmetric(horizontal: 10.rs)),
                    child: Text("SYNC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.rs)),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 15.rs),
        ],

        if (!isWifiMode && system.discoveredBluetoothDevices.isNotEmpty) ...[
          Container(
            constraints: BoxConstraints(maxHeight: 120.rs),
            decoration: BoxDecoration(color: colors.inputBg, borderRadius: BorderRadius.circular(8.rs)),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: system.discoveredBluetoothDevices.length,
              itemBuilder: (context, index) {
                var device = system.discoveredBluetoothDevices[index];
                return ListTile(
                  leading: Icon(Icons.bluetooth_connected, color: Colors.blueAccent, size: 20.rs),
                  title: Text(device['name']!, style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 14.rs)),
                  subtitle: Text(device['id']!, style: TextStyle(color: colors.subText, fontSize: 10.rs)),
                  trailing: ElevatedButton(
                    onPressed: () => system.syncWithBluetoothDevice(device['id']!),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 10.rs)),
                    child: Text("PAIR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.rs)),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 15.rs),
        ],

        ElevatedButton.icon(
          onPressed: (system.isScanning || system.isBluetoothScanning) ? null : () {
            if (isWifiMode) system.runRadarScan();
            else system.runBluetoothScan();
          }, 
          icon: (system.isScanning || system.isBluetoothScanning) 
              ? SizedBox(width: 20.rs, height: 20.rs, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
              : Icon(isWifiMode ? Icons.radar : Icons.bluetooth_searching, size: 18.rs), 
          label: Text((system.isScanning || system.isBluetoothScanning) ? "SCANNING..." : (isWifiMode ? "RADAR SCAN" : "BLUETOOTH SCAN"), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.rs)),
          style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 45.rs), backgroundColor: isWifiMode ? colors.accent : Colors.blueAccent, foregroundColor: isWifiMode ? Colors.black : Colors.white, elevation: 0)
        ),
        
        if (system.syncStatusMessage.isNotEmpty && !system.syncStatusMessage.contains("SECURITY") && !system.syncStatusMessage.contains("EXPORT") && !system.syncStatusMessage.contains("IMPORT")) 
          Padding(
            padding: EdgeInsets.only(top: 15.rs), 
            child: Text(system.syncStatusMessage, textAlign: TextAlign.center, style: TextStyle(color: system.syncStatusMessage.contains("ERROR") ? colors.danger : const Color(0xFF00BFA5), fontWeight: FontWeight.bold, fontSize: 12.rs))
          ),

        SizedBox(height: 25.rs),
        Divider(color: colors.border),
        SizedBox(height: 15.rs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Designate as Master Node", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 12.rs)),
                  SizedBox(height: 4.rs),
                  Text("Master data always overwrites Slave data.", style: TextStyle(color: colors.danger, fontSize: 10.rs)),
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
          icon: Icon(Icons.upload_file, size: 18.rs),
          label: Text("EXPORT VAULT DATA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.rs)),
          style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 45.rs), backgroundColor: colors.inputBg, foregroundColor: colors.accent, elevation: 0)
        ),
        SizedBox(height: 10.rs),
        ElevatedButton.icon(
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles();
            if (result != null && result.files.single.path != null) system.importData(result.files.single.path!);
          }, 
          icon: Icon(Icons.download, size: 18.rs),
          label: Text("RESTORE FROM BACKUP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.rs)),
          style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 45.rs), backgroundColor: colors.inputBg, foregroundColor: const Color(0xFFFF9800), elevation: 0)
        ),
        
        SizedBox(height: 15.rs),
        Divider(color: colors.border),
        SizedBox(height: 10.rs),
        Text("DOMAIN MODULES", style: TextStyle(color: colors.text, fontSize: 12.rs, fontWeight: FontWeight.bold, letterSpacing: 1)),
        SizedBox(height: 10.rs),

        ElevatedButton.icon(
          onPressed: () => _showDomainExportDialog(context, system, colors), 
          icon: Icon(Icons.outbox, size: 18.rs),
          label: Text("EXPORT DOMAINS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.rs)),
          style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 45.rs), backgroundColor: colors.inputBg, foregroundColor: const Color(0xFF0EA5E9), elevation: 0)
        ),
        SizedBox(height: 10.rs),
        ElevatedButton.icon(
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles();
            if (result != null && result.files.single.path != null) system.importSpecificDomains(result.files.single.path!);
          }, 
          icon: Icon(Icons.move_to_inbox, size: 18.rs),
          label: Text("IMPORT DOMAINS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.rs)),
          style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 45.rs), backgroundColor: colors.inputBg, foregroundColor: const Color(0xFF00BFA5), elevation: 0)
        ),

        if (system.syncStatusMessage.contains("PORT") || system.syncStatusMessage.contains("IMPORT") || system.syncStatusMessage.contains("EXPORT")) 
          Padding(padding: EdgeInsets.only(top: 15.rs), child: Text(system.syncStatusMessage, textAlign: TextAlign.center, style: TextStyle(color: const Color(0xFF00BFA5), fontWeight: FontWeight.bold, fontSize: 12.rs))),
      ],
    );

    Widget resetContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("WARNING", style: TextStyle(color: colors.danger, fontWeight: FontWeight.bold, fontSize: 14.rs)),
        SizedBox(height: 5.rs),
        Text("Irreversibly purges the Vault and destroys all System Progress.", textAlign: TextAlign.center, style: TextStyle(color: colors.subText, fontSize: 12.rs)),
        SizedBox(height: 25.rs),
        ElevatedButton(
          onPressed: () => _showResetWarning1(context, system), 
          style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 45.rs), backgroundColor: colors.danger, foregroundColor: Colors.white, elevation: 0), 
          child: Text("WIPE SYSTEM", style: TextStyle(fontSize: 12.rs, fontWeight: FontWeight.bold))
        )
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        double spacing = 20.0.rs;
        int crossAxisCount = constraints.maxWidth > 1100 ? 5 : 2; 
        
        double cardWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        Widget buildSquareCard({required String title, required Widget child, Color? borderColor, Color? titleColor}) {
          return Container(
            width: cardWidth,
            height: isMobile ? null : 420.rs, 
            padding: EdgeInsets.all(25.rs),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(12.rs),
              border: Border.all(color: borderColor ?? colors.border, width: borderColor != null ? 2.rs : 1.rs),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max, 
              children: [
                Text(title, textAlign: TextAlign.center, style: TextStyle(color: titleColor ?? colors.accent, fontSize: 14.rs, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                SizedBox(height: 20.rs),
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
              Text("SYSTEM CONFIGURATION", style: TextStyle(color: colors.text, fontSize: 18.rs, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              SizedBox(height: 20.rs),
              Wrap(
                spacing: spacing, 
                runSpacing: spacing, 
                alignment: WrapAlignment.start, 
                children: [
                  buildSquareCard(title: "🎨 SYSTEM APPEARANCE", child: appearanceContent),
                  buildSquareCard(title: "⚔️ SYSTEM DIFFICULTY", child: difficultyContent, titleColor: system.systemData.isPenaltyEnabled ? colors.danger : colors.accent, borderColor: system.systemData.isPenaltyEnabled ? colors.danger : colors.border),
                  buildSquareCard(title: "📡 NETWORK SYNC", child: syncContent),
                  buildSquareCard(title: "💾 VAULT BACKUP", child: backupContent),
                  buildSquareCard(title: "⚠️ FACTORY RESET", child: resetContent, titleColor: colors.danger, borderColor: colors.danger),
                ]
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildUserProfileView(SystemController system, AppColors colors) {
    TextEditingController nameController = TextEditingController(text: system.systemData.profileName);
    TextEditingController userController = TextEditingController(text: system.systemData.username);
    TextEditingController passController = TextEditingController(); 

    bool hasPhoto = system.systemData.profilePhotoUrl.isNotEmpty && File(system.systemData.profilePhotoUrl).existsSync();
    bool isMobile = MediaQuery.of(context).size.width < 800;

    Widget buildSquareCard({required String title, required Widget child, Color? borderColor}) {
      return Container(
        width: isMobile ? double.infinity : 380.rs,
        height: isMobile ? null : 380.rs, 
        padding: EdgeInsets.all(25.rs),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(15.rs),
          border: Border.all(color: borderColor ?? colors.border, width: borderColor != null ? 2.rs : 1.rs),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2)]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: colors.text, fontSize: 16.rs, fontWeight: FontWeight.bold, letterSpacing: 2)),
            SizedBox(height: 20.rs),
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
              radius: 50.rs, backgroundColor: colors.inputBg,
              backgroundImage: hasPhoto ? FileImage(File(system.systemData.profilePhotoUrl)) : null,
              child: !hasPhoto ? Text(system.systemData.profileName.isNotEmpty ? system.systemData.profileName[0].toUpperCase() : "U", style: TextStyle(color: colors.text, fontSize: 36.rs, fontWeight: FontWeight.bold)) : null,
            ),
            Container(
              decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
              child: IconButton(
                icon: Icon(Icons.camera_alt, color: colors.invertText, size: 20.rs),
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
        SizedBox(height: 15.rs),
        Text("Level ${system.currentStreak} Awakened", style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold, fontSize: 14.rs)),
        SizedBox(height: 15.rs),
        TextField(controller: nameController, textAlign: TextAlign.center, style: TextStyle(color: colors.text, fontSize: 16.rs, fontWeight: FontWeight.bold), decoration: InputDecoration(filled: true, fillColor: colors.inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.rs), borderSide: BorderSide.none))),
        SizedBox(height: 10.rs),
        ElevatedButton(onPressed: () => system.updateProfile(nameController.text, system.systemData.profileDesc, system.systemData.profilePhotoUrl), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 40.rs), backgroundColor: colors.inputBg, foregroundColor: colors.text, elevation: 0), child: Text("UPDATE IDENTITY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.rs))),
      ],
    );

    Widget radarContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 180.rs, height: 180.rs, 
          decoration: BoxDecoration(color: colors.inputBg, shape: BoxShape.circle),
          child: CustomPaint(
            painter: StatRadarPainter(
              str: system.statSTR, intl: system.statINT, 
              agi: system.statAGI, wil: system.statWIL, 
              accentColor: colors.accent
            ),
          ),
        ),
        SizedBox(height: 25.rs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(children: [Text("STR", style: TextStyle(color: colors.subText, fontSize: 12.rs)), Text("${system.statSTR.toInt()}", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 16.rs))]),
            Column(children: [Text("INT", style: TextStyle(color: colors.subText, fontSize: 12.rs)), Text("${system.statINT.toInt()}", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 16.rs))]),
            Column(children: [Text("WIL", style: TextStyle(color: colors.subText, fontSize: 12.rs)), Text("${system.statWIL.toInt()}", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 16.rs))]),
            Column(children: [Text("AGI", style: TextStyle(color: colors.subText, fontSize: 12.rs)), Text("${system.statAGI.toInt()}", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 16.rs))]),
          ],
        )
      ],
    );

    Widget secretsContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(controller: userController, textAlign: TextAlign.center, style: TextStyle(color: colors.text, fontSize: 14.rs), decoration: InputDecoration(hintText: "New Username", hintStyle: TextStyle(color: colors.subText, fontSize: 14.rs), filled: true, fillColor: colors.inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.rs), borderSide: BorderSide.none))),
        SizedBox(height: 15.rs),
        TextField(controller: passController, textAlign: TextAlign.center, obscureText: true, style: TextStyle(color: colors.text, fontSize: 14.rs), decoration: InputDecoration(hintText: "New Password", hintStyle: TextStyle(color: colors.subText, fontSize: 14.rs), filled: true, fillColor: colors.inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.rs), borderSide: BorderSide.none))),
        SizedBox(height: 25.rs),
        ElevatedButton(onPressed: () { system.updateCredentials(userController.text, passController.text); passController.clear(); }, style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50.rs), backgroundColor: colors.inputBg, foregroundColor: const Color(0xFF00BFA5), elevation: 0), child: Text("CHANGE CREDENTIALS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.rs))),
        if (system.syncStatusMessage.contains("SECURITY")) Padding(padding: EdgeInsets.only(top: 15.rs), child: Text(system.syncStatusMessage, textAlign: TextAlign.center, style: TextStyle(color: const Color(0xFF00BFA5), fontWeight: FontWeight.bold, fontSize: 12.rs))),
      ],
    );

    Widget exitContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("Disconnect from the current session. Your progress is saved locally.", textAlign: TextAlign.center, style: TextStyle(color: colors.subText, fontSize: 12.rs)),
        SizedBox(height: 25.rs),
        ElevatedButton(onPressed: () => system.logoutUser(), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50.rs), backgroundColor: Colors.transparent, foregroundColor: colors.danger, elevation: 0, side: BorderSide(color: colors.danger, width: 2.rs)), child: Text("LOGOUT OF SYSTEM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.rs))),
      ],
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("STATUS WINDOW", style: TextStyle(color: colors.text, fontSize: 24.rs, fontWeight: FontWeight.bold, letterSpacing: 2)),
          SizedBox(height: 30.rs),
          
          Wrap(
            spacing: 20.rs,
            runSpacing: 20.rs,
            alignment: WrapAlignment.start,
            children: [
              buildSquareCard(title: "HUNTER IDENTITY", borderColor: colors.accent, child: identityContent),
              buildSquareCard(title: "ATTRIBUTE RADAR", child: radarContent),
              buildSquareCard(title: "SYSTEM SECRETS", child: secretsContent),
              buildSquareCard(title: "EXIT VAULT", borderColor: colors.danger.withOpacity(0.5), child: exitContent),
            ],
          ),
          SizedBox(height: 50.rs),
        ],
      ),
    );
  }

  void _showAudioDeck(BuildContext context, SystemController system, AppColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.rs), side: BorderSide(color: colors.accent)),
        title: Row(
          children: [
            Icon(Icons.graphic_eq, color: colors.accent, size: 24.rs),
            SizedBox(width: 10.rs),
            Text("FLOW STATE DECK", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16.rs)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("STATUS: ${system.currentTrackName}", style: TextStyle(color: system.isAudioPlaying ? const Color(0xFF00BFA5) : colors.subText, fontWeight: FontWeight.bold, fontSize: 12.rs)),
            SizedBox(height: 25.rs),
            
            ListTile(
              leading: Icon(Icons.upload_file, color: colors.accent, size: 20.rs),
              title: Text("Upload Custom Audio", style: TextStyle(color: colors.text, fontWeight: FontWeight.bold, fontSize: 14.rs)),
              trailing: IconButton(
                icon: Icon(Icons.add_circle, color: Colors.white, size: 20.rs),
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
              leading: Icon(Icons.water_drop, color: Colors.blue, size: 20.rs),
              title: Text("Heavy Rain", style: TextStyle(color: colors.text, fontSize: 14.rs)),
              trailing: IconButton(
                icon: Icon(Icons.play_circle_fill, color: Colors.white, size: 20.rs),
                onPressed: () {
                  system.playAudioStream("https://actions.google.com/sounds/v1/weather/rain_heavy_loud.ogg", "Heavy Rain");
                  Navigator.pop(ctx);
                }
              ),
            ),
            
            ListTile(
              leading: Icon(Icons.waves, color: Colors.brown, size: 20.rs),
              title: Text("Deep Space Focus", style: TextStyle(color: colors.text, fontSize: 14.rs)),
              trailing: IconButton(
                icon: Icon(Icons.play_circle_fill, color: Colors.white, size: 20.rs),
                onPressed: () {
                  system.playAudioStream("https://actions.google.com/sounds/v1/science_fiction/outer_space.ogg", "Deep Space");
                  Navigator.pop(ctx);
                }
              ),
            ),
            
            ListTile(
              leading: Icon(Icons.forest, color: Colors.green, size: 20.rs),
              title: Text("Forest Wind", style: TextStyle(color: colors.text, fontSize: 14.rs)),
              trailing: IconButton(
                icon: Icon(Icons.play_circle_fill, color: Colors.white, size: 20.rs),
                onPressed: () {
                  system.playAudioStream("https://actions.google.com/sounds/v1/weather/forest_wind_summer.ogg", "Forest Wind");
                  Navigator.pop(ctx);
                }
              ),
            ),
            
            SizedBox(height: 20.rs),
            if (system.isAudioPlaying)
              ElevatedButton.icon(
                onPressed: () {
                  system.stopAudio();
                  Navigator.pop(ctx);
                }, 
                icon: Icon(Icons.stop, size: 18.rs), 
                label: Text("TERMINATE AUDIO", style: TextStyle(fontSize: 12.rs)),
                style: ElevatedButton.styleFrom(backgroundColor: colors.danger, foregroundColor: Colors.white, minimumSize: Size(double.infinity, 45.rs)),
              )
          ],
        ),
      ),
    );
  }

  void _showSystemGuide(BuildContext context, AppColors colors) {
    Widget buildGuideSection(String title, String description) {
      return Padding(
        padding: EdgeInsets.only(bottom: 25.0.rs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: colors.accent, fontSize: 18.rs, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.rs),
            Text(description, style: TextStyle(color: colors.subText, fontSize: 14.rs, height: 1.5)),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.rs), side: BorderSide(color: colors.border)),
        child: Container(
          width: 800.rs,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(25.rs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.help_outline, color: colors.accent, size: 28.rs),
                        SizedBox(width: 10.rs),
                        Expanded(child: Text("SYSTEM MANUAL", style: TextStyle(color: colors.text, fontSize: 20.rs, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
                      ]
                    ),
                  ),
                  IconButton(icon: Icon(Icons.close, color: colors.subText, size: 24.rs), onPressed: () => Navigator.pop(ctx))
                ],
              ),
              Divider(color: colors.border, height: 30.rs),
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