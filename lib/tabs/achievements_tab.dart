import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_controller.dart';

class AchievementsTab extends StatelessWidget {
  const AchievementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final system = context.watch<SystemController>();
    final allBadges = system.badgeLibrary;
    final unlockedIds = system.systemData.badgesUnlocked;

    // --- DYNAMIC THEME COLORS ---
    final bool isDark = system.systemData.isDarkMode;
    final Color card = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFFFFF);
    final Color altCard = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF9FAFB);
    final Color lockedCard = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF1F5F9);
    final Color border = isDark ? const Color(0xFF444444) : const Color(0xFFE2E8F0);
    final Color text = isDark ? Colors.white : const Color(0xFF334155);
    final Color subText = isDark ? Colors.grey : const Color(0xFF94A3B8);
    final Color accent = isDark ? const Color(0xFFEBFB7E) : const Color(0xFF0EA5E9);
    final Color tooltipText = isDark ? Colors.black : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "HUNTER ACHIEVEMENTS (${unlockedIds.length}/${allBadges.length})", 
          style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)
        ),
        const SizedBox(height: 20),
        
        // The Chess.com Style Compact Grid!
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: card, 
              borderRadius: BorderRadius.circular(10), 
              border: Border.all(color: border)
            ),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 110, // Perfect small boxes
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.0, // Perfect Squares
              ),
              itemCount: allBadges.length,
              itemBuilder: (context, index) {
                final badge = allBadges[index];
                final isUnlocked = unlockedIds.contains(badge.id);

                return Tooltip(
                  // The Tooltip saves space by showing the description only when hovered!
                  message: "${badge.title}\n${badge.description}",
                  textStyle: TextStyle(color: tooltipText, fontWeight: FontWeight.bold, fontSize: 12),
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(5)),
                  waitDuration: const Duration(milliseconds: 200),
                  
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isUnlocked ? altCard : lockedCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUnlocked ? accent : border,
                        width: isUnlocked ? 2 : 1,
                      ),
                      boxShadow: isUnlocked ? [
                        BoxShadow(color: accent.withOpacity(0.15), blurRadius: 10, spreadRadius: 1)
                      ] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isUnlocked ? badge.icon : '🔒',
                          style: TextStyle(
                            fontSize: 32, 
                            color: isUnlocked ? text : subText.withOpacity(0.4)
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            badge.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // Keeps the box perfectly sized
                            style: TextStyle(
                              color: isUnlocked ? text : subText,
                              fontWeight: FontWeight.bold,
                              fontSize: 10, // Small text for compact grid
                            ),
                          ),
                        ),
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
}