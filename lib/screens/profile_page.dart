import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:intl/intl.dart';
import '../login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    bool? clearCredentials = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Do you want to clear saved credentials?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Keep")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Clear")),
        ],
      ),
    );

    if (clearCredentials == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('password');
    }

    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1014),
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text("Not logged in", style: TextStyle(color: Colors.white)))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                var data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                String fullName = data['fullName'] ?? user.displayName ?? 'User';
                String email = user.email ?? 'No Email';
                int leaderboardPoints = data['leaderboardPoints'] ?? 0;

                // Parse activity heatmap data
                Map<DateTime, int> heatmapDataset = {};
                if (data['dailyActivity'] != null) {
                  Map<String, dynamic> activity = data['dailyActivity'] as Map<String, dynamic>;
                  activity.forEach((key, value) {
                    try {
                      DateTime date = DateTime.parse(key);
                      // Use only year, month, day to keep it exact
                      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
                      heatmapDataset[normalizedDate] = (value as num).toInt();
                    } catch (_) {}
                  });
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: const BoxDecoration(
                          color: Colors.white12,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Colors.white54, size: 60),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child: Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildInfoCard("Skills Tracked", data['skills']?.toString() ?? "0", Icons.code),
                    const SizedBox(height: 10),
                    _buildInfoCard("Total Minutes", data['minutes']?.toString() ?? "0", Icons.timer),
                    const SizedBox(height: 10),
                    _buildInfoCard("Current Streak", "${data['currentStreak'] ?? 0} days", Icons.local_fire_department),
                    const SizedBox(height: 10),
                    _buildInfoCard("Total Points", leaderboardPoints.toString(), Icons.emoji_events),
                    
                    const SizedBox(height: 40),
                    const Text(
                      "Activity Heatmap",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1E24),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: HeatMap(
                        datasets: heatmapDataset,
                        colorMode: ColorMode.opacity,
                        showText: false,
                        scrollable: true,
                        size: 30,
                        colorsets: const {
                          1: Color(0xFF2ECC71),
                        },
                        onClick: (value) {
                          final count = heatmapDataset[DateTime(value.year, value.month, value.day)] ?? 0;
                          final dateStr = DateFormat('MMM d, yyyy').format(value);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(count > 0 ? "Practiced $count mins on $dateStr" : "No practice on $dateStr"),
                              backgroundColor: count > 0 ? const Color(0xFF2ECC71) : Colors.white24,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E24),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2ECC71), size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
