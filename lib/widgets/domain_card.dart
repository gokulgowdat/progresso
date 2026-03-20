import 'package:flutter/material.dart';
import '../models/skill_node.dart';

class DomainCard extends StatelessWidget {
  final SkillNode domain;
  final VoidCallback onAccess;
  final VoidCallback onEdit; // NEW
  final VoidCallback onDelete;

  const DomainCard({
    super.key,
    required this.domain,
    required this.onAccess,
    required this.onEdit, // NEW
    required this.onDelete,
  });

  Map<String, dynamic> _getRank(double progress) {
    if (progress >= 100) return {'letter': 'S', 'color': const Color(0xFFFFB300)};
    if (progress >= 80) return {'letter': 'A', 'color': const Color(0xFF00BFA5)};
    if (progress >= 60) return {'letter': 'B', 'color': const Color(0xFF2196F3)};
    if (progress >= 40) return {'letter': 'C', 'color': const Color(0xFF9C27B0)};
    if (progress >= 20) return {'letter': 'D', 'color': const Color(0xFFFF9800)};
    return {'letter': 'E', 'color': const Color(0xFFFF5555)};
  }

  @override
  Widget build(BuildContext context) {
    final rank = _getRank(domain.progress);

    return Container(
      width: 280,
      height: 160,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF444444)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(domain.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(border: Border.all(color: rank['color'], width: 2), borderRadius: BorderRadius.circular(5)),
                child: Center(child: Text(rank['letter'], style: TextStyle(color: rank['color'], fontSize: 16, fontWeight: FontWeight.bold))),
              )
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Progress:", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("${domain.progress.toStringAsFixed(1)}%", style: const TextStyle(color: Color(0xFFEBFB7E), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(value: domain.progress / 100.0, backgroundColor: const Color(0xFF171717), color: const Color(0xFFEBFB7E), minHeight: 6, borderRadius: BorderRadius.circular(3)),
          const Spacer(),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccess,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3A3A3A), foregroundColor: const Color(0xFFEBFB7E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
                  child: const Text("ACCESS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(width: 5),
              // NEW: The Edit Button!
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(5)),
                child: IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: onEdit),
              ),
              const SizedBox(width: 5),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFFF5555), borderRadius: BorderRadius.circular(5)),
                child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: onDelete),
              ),
            ],
          )
        ],
      ),
    );
  }
}