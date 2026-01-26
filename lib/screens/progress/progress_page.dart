import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../models/session_model.dart';
import '../../app_theme.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    final dbService = DatabaseService(userId: user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: StreamBuilder<List<LearningSession>>(
        stream: dbService.allSessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Could not load progress"));
          }

          final sessions = snapshot.data ?? [];
          final last7DaysStats = _calculateLast7Days(sessions);
          final totalHours = sessions.fold(0.0, (sum, item) => sum + item.durationInHours);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                   child: Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Column(
                       children: [
                         const Text("Total Learning Time", style: TextStyle(fontSize: 16)),
                         const SizedBox(height: 8),
                         Text(
                           "${totalHours.toStringAsFixed(1)} hrs",
                           style: TextStyle(
                             fontSize: 32, 
                             fontWeight: FontWeight.bold,
                             color: Theme.of(context).primaryColor,
                           ),
                         ),
                       ],
                     ),
                   ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Last 7 Days",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 12, right: 16, left: 0),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _getMaxY(last7DaysStats),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              // tooltipBgColor: Colors.blueAccent, // Deprecated in newer versions, check version
                              getTooltipColor: (group) => AppTheme.primaryColor,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  rod.toY.toStringAsFixed(1),
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < last7DaysStats.length) {
                                     return Padding(
                                       padding: const EdgeInsets.only(top: 8.0),
                                       child: Text(
                                         DateFormat('E').format(last7DaysStats[index].date),
                                         style: const TextStyle(fontSize: 12),
                                       ),
                                     );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barGroups: last7DaysStats.asMap().entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.hours,
                                  color: AppTheme.primaryColor,
                                  width: 16,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_DailyStat> _calculateLast7Days(List<LearningSession> sessions) {
    // Generate last 7 days keys
    final now = DateTime.now();
    final List<_DailyStat> stats = [];
    
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      stats.add(_DailyStat(date: day, hours: 0));
    }

    for (var session in sessions) {
      for (var stat in stats) {
        if (_isSameDay(session.date, stat.date)) {
          stat.hours += session.durationInHours;
        }
      }
    }
    return stats;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  double _getMaxY(List<_DailyStat> stats) {
    double max = 0;
    for (var s in stats) {
      if (s.hours > max) max = s.hours;
    }
    return max == 0 ? 5 : max + 2; // Default scale if empty or nice padding
  }
}

class _DailyStat {
  final DateTime date;
  double hours;
  _DailyStat({required this.date, required this.hours});
}
