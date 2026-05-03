import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_controller.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  // Feature 4 Toggles
  String metricType = "both"; // 'learn', 'exercise', or 'both'
  String graphType = "bar";   // 'bar' or 'line'
  String rangeType = "week";  // 'week', 'month', or 'year'

  final Color learnColor = const Color(0xFF00BFA5); // Teal
  final Color exerciseColor = const Color(0xFF9C27B0); // Purple

  @override
  Widget build(BuildContext context) {
    final system = context.watch<SystemController>();
    
    // --- DYNAMIC THEME COLORS ---
    final bool isDark = system.systemData.isDarkMode;
    final Color card = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFFFFF);
    final Color border = isDark ? const Color(0xFF444444) : const Color(0xFFE2E8F0);
    final Color text = isDark ? Colors.white : const Color(0xFF334155);
    final Color subText = isDark ? Colors.grey : const Color(0xFF94A3B8);
    final Color accent = isDark ? const Color(0xFFEBFB7E) : const Color(0xFF0EA5E9); 
    final Color invertText = isDark ? const Color(0xFF171717) : Colors.white;

    // 1. Determine Time Range
    int daysToLookBack = rangeType == 'week' ? 7 : (rangeType == 'month' ? 30 : 365);
    List<DateTime> dates = List.generate(daysToLookBack, (i) => DateTime.now().subtract(Duration(days: (daysToLookBack - 1) - i)));
    
    // 2. Prepare Dual Data Arrays
    List<double> learnValues = [];
    List<double> exerciseValues = [];
    List<String> labels = [];
    double maxVal = 0.1; // Baseline to prevent division by zero

    // 3. Process Data based on Range
    if (rangeType == 'year') {
      List<double> monthlyLearnSums = List.filled(12, 0.0);
      List<double> monthlyExerciseSums = List.filled(12, 0.0);
      
      for (var date in dates) {
        String dateStr = date.toIso8601String().split('T')[0];
        monthlyLearnSums[date.month - 1] += system.systemData.hoursWorkedDict[dateStr] ?? 0.0;
        monthlyExerciseSums[date.month - 1] += system.systemData.exerciseHoursDict[dateStr] ?? 0.0;
      }
      
      learnValues = monthlyLearnSums;
      exerciseValues = monthlyExerciseSums;
      labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      
    } else {
      // Week or Month
      for (var date in dates) {
        String dateStr = date.toIso8601String().split('T')[0];
        learnValues.add(system.systemData.hoursWorkedDict[dateStr] ?? 0.0);
        exerciseValues.add(system.systemData.exerciseHoursDict[dateStr] ?? 0.0);
        
        if (rangeType == 'week') {
          labels.add(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][date.weekday - 1]);
        } else {
          labels.add(date.day.toString()); 
        }
      }
    }

    // 4. Find the absolute maximum value to scale the Y-Axis properly
    for (int i = 0; i < learnValues.length; i++) {
      if ((metricType == 'learn' || metricType == 'both') && learnValues[i] > maxVal) maxVal = learnValues[i];
      if ((metricType == 'exercise' || metricType == 'both') && exerciseValues[i] > maxVal) maxVal = exerciseValues[i];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("EFFORT DISTRIBUTION ANALYTICS", style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 20),
        
        // --- TOGGLES ROW ---
        Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            // Target Toggles
            _buildToggleGroup(["LEARN", "BOTH", "EXERCISE"], [
              () => setState(() => metricType = "learn"),
              () => setState(() => metricType = "both"),
              () => setState(() => metricType = "exercise")
            ], [metricType == "learn", metricType == "both", metricType == "exercise"], [learnColor, accent, exerciseColor], card, border, text, invertText),
            
            // Graph Type Toggles
            _buildToggleGroup(["📊 BAR", "📈 LINE"], [
              () => setState(() => graphType = "bar"),
              () => setState(() => graphType = "line")
            ], [graphType == "bar", graphType == "line"], [accent, accent], card, border, text, invertText),
            
            // Range Toggles
            _buildToggleGroup(["WEEK", "MONTH", "YEAR"], [
              () => setState(() => rangeType = "week"),
              () => setState(() => rangeType = "month"),
              () => setState(() => rangeType = "year")
            ], [rangeType == "week", rangeType == "month", rangeType == "year"], [accent, accent, accent], card, border, text, invertText),
          ],
        ),
        
        const SizedBox(height: 20),

        // --- LEGEND ---
        if (metricType == 'both') 
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(width: 12, height: 12, color: learnColor),
              const SizedBox(width: 5),
              Text("Learn/Work", style: TextStyle(color: subText, fontSize: 12)),
              const SizedBox(width: 15),
              Container(width: 12, height: 12, color: exerciseColor),
              const SizedBox(width: 5),
              Text("Exercise", style: TextStyle(color: subText, fontSize: 12)),
            ],
          ),
        
        const SizedBox(height: 10),

        // --- THE CHART AREA ---
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
            child: graphType == 'bar' 
                ? _buildDualBarChart(learnValues, exerciseValues, labels, maxVal, text, subText, accent) 
                : _buildDualLineChart(learnValues, exerciseValues, labels, maxVal, subText),
          ),
        ),
      ],
    );
  }

  // UI Builder for Toggle Buttons
  Widget _buildToggleGroup(List<String> titles, List<VoidCallback> actions, List<bool> states, List<Color> activeColors, Color card, Color border, Color text, Color invertText) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(titles.length, (index) {
        bool isActive = states[index];
        return InkWell(
          onTap: actions[index],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? activeColors[index] : card,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(titles[index], style: TextStyle(color: isActive ? invertText : text, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        );
      }),
    );
  }

  // --- DUAL BAR CHART IMPLEMENTATION ---
  Widget _buildDualBarChart(List<double> learnValues, List<double> exerciseValues, List<String> labels, double maxVal, Color text, Color subText, Color accent) {
    // Dynamic bar width based on how many items we are displaying
    double barWidth = rangeType == 'week' ? (metricType == 'both' ? 20 : 40) 
                    : rangeType == 'year' ? (metricType == 'both' ? 12 : 25) 
                    : (metricType == 'both' ? 4 : 8); // Month view is tightly packed

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(labels.length, (index) {
        double lHeight = (learnValues[index] / maxVal);
        double eHeight = (exerciseValues[index] / maxVal);
        
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Display numeric value on top (Only if it's Week or Year to prevent clutter)
              if (rangeType != 'month' && metricType != 'both') 
                Text(metricType == 'learn' ? (learnValues[index] > 0 ? "${learnValues[index].toStringAsFixed(1)}h" : "") 
                     : (exerciseValues[index] > 0 ? "${exerciseValues[index].toStringAsFixed(1)}h" : ""), 
                     style: TextStyle(color: text, fontSize: 10)),
                     
              const SizedBox(height: 5),
              
              // The Bars
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Learn Bar
                    if (metricType == 'learn' || metricType == 'both')
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: barWidth,
                        height: learnValues[index] == 0 ? 2 : (250 * lHeight), 
                        decoration: BoxDecoration(color: learnColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                      ),
                      
                    if (metricType == 'both') const SizedBox(width: 2), // Gap between side-by-side bars
                    
                    // Exercise Bar
                    if (metricType == 'exercise' || metricType == 'both')
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: barWidth,
                        height: exerciseValues[index] == 0 ? 2 : (250 * eHeight), 
                        decoration: BoxDecoration(color: exerciseColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              // X-Axis Labels
              Text(labels[index], style: TextStyle(color: index == labels.length - 1 && rangeType != 'year' ? accent : subText, fontSize: rangeType == 'month' ? 8 : 10)),
            ],
          ),
        );
      }),
    );
  }

  // --- DUAL LINE CHART IMPLEMENTATION ---
  Widget _buildDualLineChart(List<double> learnValues, List<double> exerciseValues, List<String> labels, double maxVal, Color subText) {
    List<List<double>> activeSeries = [];
    List<Color> activeColors = [];

    if (metricType == 'learn' || metricType == 'both') {
      activeSeries.add(learnValues);
      activeColors.add(learnColor);
    }
    if (metricType == 'exercise' || metricType == 'both') {
      activeSeries.add(exerciseValues);
      activeColors.add(exerciseColor);
    }

    return CustomPaint(
      painter: MultiLineChartPainter(seriesList: activeSeries, colors: activeColors, maxVal: maxVal),
      child: Column(
        children: [
          const Spacer(),
          // X-Axis Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.map((l) => Text(l, style: TextStyle(color: subText, fontSize: rangeType == 'month' ? 8 : 10))).toList(),
          )
        ],
      ),
    );
  }
}

// --- CUSTOM PAINTER FOR MULTIPLE OVERLAPPING CURVY LINES ---
class MultiLineChartPainter extends CustomPainter {
  final List<List<double>> seriesList;
  final List<Color> colors;
  final double maxVal;

  MultiLineChartPainter({required this.seriesList, required this.colors, required this.maxVal});

  @override
  void paint(Canvas canvas, Size size) {
    if (seriesList.isEmpty || seriesList[0].isEmpty) return;

    double drawHeight = size.height - 30; // Leave room for the text labels at the bottom
    double stepX = size.width / (seriesList[0].length > 1 ? seriesList[0].length - 1 : 1);

    for (int s = 0; s < seriesList.length; s++) {
      final values = seriesList[s];
      
      final paint = Paint()
        ..color = colors[s]
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      double prevX = 0.0;
      double prevY = 0.0;

      for (int i = 0; i < values.length; i++) {
        double x = i * stepX;
        // Calculate y coordinate (0 is at the top of the canvas, so we invert it)
        double y = drawHeight - ((values[i] / maxVal) * drawHeight);
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          // THE FIX: Calculate horizontal anchor points halfway between the current and previous nodes
          double cpX = prevX + (x - prevX) / 2;
          
          // Draw a smooth Bezier Curve instead of a sharp straight line
          path.cubicTo(cpX, prevY, cpX, y, x, y);
        }
        
        // Save current points for the next iteration
        prevX = x;
        prevY = y;
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}