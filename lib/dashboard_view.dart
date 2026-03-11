import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _buildProgressSection(data['progress'] ?? 0.79),
              const SizedBox(height: 20),
              _buildTimeAndCalendar(data['hours'] ?? 12),
              const SizedBox(height: 20),
              _buildStats(data),
              const SizedBox(height: 20),
              _buildTimelineSection(),
            ],
          ),
        );
      },
    );
  }

  // --- UI Component Builders ---

  Widget _buildProgressSection(double percent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1C1E24), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CircularPercentIndicator(
            radius: 50.0, lineWidth: 10.0, percent: percent,
            center: Text("${(percent * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            progressColor: const Color(0xFF2ECC71), backgroundColor: Colors.white10,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Still Goal", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("Insights", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTimeAndCalendar(int hrs) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: const Color(0xFF1C1E24), borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$hrs hrs", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Text("Weekly Practice", style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: const Color(0xFF1C1E24), borderRadius: BorderRadius.circular(20)),
            child: const Center(child: Text("Nov 2023", style: TextStyle(color: Colors.grey))),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(Map data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _miniStat("8", "Tracked"),
        _miniStat("234", "Minutes"),
        _miniStat("75%", "Done"),
      ],
    );
  }

  Widget _miniStat(String val, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(color: const Color(0xFF1C1E24), borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1C1E24), borderRadius: BorderRadius.circular(20)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Log Timeline", style: TextStyle(color: Colors.grey, fontSize: 12)),
          SizedBox(height: 10),
          ListTile(
            leading: Icon(Icons.circle, color: Colors.orange, size: 12),
            title: Text("UI/UX Design", style: TextStyle(fontSize: 14)),
            trailing: Text("11:00", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}