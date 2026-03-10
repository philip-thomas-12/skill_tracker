import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analytics")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSummaryCards(),
            const SizedBox(height: 32),
            const Text("Popular Skills (Seconds Spent)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(height: 300, child: _buildBarChart()),
            const SizedBox(height: 32),
            const Text("Recent Activity", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            _buildRecentActivityList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').snapshots(),
      builder: (context, userSnap) {
        final userCount = userSnap.data?.docs.length ?? 0;
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('usage_logs').snapshots(),
          builder: (context, usageSnap) {
            final logs = usageSnap.data?.docs ?? [];
            int totalSeconds = 0;
            for (var doc in logs) {
              totalSeconds += (doc['secondsSpent'] as num).toInt();
            }
            final totalHours = (totalSeconds / 3600).toStringAsFixed(1);

            return Row(
              children: [
                Expanded(child: _MetricCard(title: "Total Students", value: "$userCount", icon: Icons.people, color: Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _MetricCard(title: "Hours Learned", value: totalHours, icon: Icons.timer, color: Colors.orange)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBarChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usage_logs').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final logs = snapshot.data!.docs;
        Map<String, int> skillTime = {};

        for (var doc in logs) {
          final data = doc.data() as Map<String, dynamic>;
          final skillName = data['pathwayTitle'] as String? ?? 'Unknown';
          final seconds = (data['secondsSpent'] as num?)?.toInt() ?? 0;
          skillTime[skillName] = (skillTime[skillName] ?? 0) + seconds;
        }

        final sortedEntries = skillTime.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        final top5 = sortedEntries.take(5).toList();

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: top5.isNotEmpty ? top5.first.value.toDouble() * 1.2 : 100,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < top5.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          top5[value.toInt()].key.split(' ').first, // Show first word only
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: top5.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.value.toDouble(),
                    color: Colors.blueAccent,
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivityList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usage_logs')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final seconds = data['secondsSpent'] ?? 0;
            return ListTile(
              leading: const Icon(Icons.history, color: Colors.grey),
              title: Text("${data['pathwayTitle']}"),
              subtitle: Text("Spent $seconds seconds"),
              // trailing: Text(DateFormat('MM/dd HH:mm').format((data['timestamp'] as Timestamp).toDate())), // Needs intl
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
