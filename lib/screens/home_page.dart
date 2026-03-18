import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/streak_service.dart';
import '../services/goal_service.dart';
import '../services/achievement_service.dart';
import '../models/achievement_model.dart';
import '../widgets/achievement_popup.dart';
import 'add_skill_page.dart';
import 'skill_list_page.dart';
import 'package:intl/intl.dart';
import '../services/skill_service.dart';
import '../login_page.dart';
import 'profile_page.dart';
import 'leaderboard_page.dart';
import 'achievements_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  
  // Achievement variables
  List<String> _newAchievements = [];
  Achievement? _currentPopupAchievement;

  // Services
  final GoalService _goalService = GoalService();

  @override
  void initState() {
    super.initState();
    // Refresh user's global stats so they appear properly on Leaderboard
    SkillService().refreshUserStats();
  }

  // --- LOGOUT FUNCTION WITH DIALOG ---
  Future<void> logout() async {
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

    // Clear saved credentials if user chooses
    if (clearCredentials == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('password');
    }

    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    // Navigate back to login page
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  // Achievement methods
  void _checkForNewAchievements(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return;
    
    final data = snapshot.data() as Map<String, dynamic>;
    List<String> newAchievements = List<String>.from(data['newAchievements'] ?? []);
    
    // Only process if there are new achievements and none are currently showing
    if (newAchievements.isNotEmpty && _newAchievements.isEmpty) {
      // Show first achievement popup
      _showNextAchievementPopup(newAchievements);
    }
    
    // Update state only if the list changed
    if (_newAchievements.length != newAchievements.length || 
        !_newAchievements.every((id) => newAchievements.contains(id))) {
      setState(() {
        _newAchievements = newAchievements;
      });
    }
  }

  void _showNextAchievementPopup(List<String> achievementIds) {
    if (achievementIds.isEmpty) return;
    
    final achievement = Achievement.getAllAchievements()
        .firstWhere((a) => a.id == achievementIds.first);
    
    setState(() {
      _currentPopupAchievement = achievement;
    });
  }

  void _dismissAchievementPopup() async {
    final currentId = _currentPopupAchievement?.id;
    if (currentId != null) {
      // Remove from new achievements list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .update({
        'newAchievements': FieldValue.arrayRemove([currentId]),
      });
      
      setState(() {
        _newAchievements.remove(currentId);
        _currentPopupAchievement = null;
      });
      
      // Show next achievement if any
      if (_newAchievements.isNotEmpty) {
        _showNextAchievementPopup(_newAchievements);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final List<Widget> pages = [
      _buildExactDashboard(user),
      const SkillListPage(),
      const AchievementsPage(),
      const LeaderboardPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      body: Stack(
        children: [
          pages[selectedIndex],
          // Achievement popup
          if (_currentPopupAchievement != null)
            AchievementPopup(
              achievement: _currentPopupAchievement!,
              onDismiss: _dismissAchievementPopup,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "homeFab",
        backgroundColor: const Color(0xFF2ECC71),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSkillPage()),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1014),
        title: const Text("Skill Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildExactDashboard(User? user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text(
              'No user data found',
              style: TextStyle(color: Colors.white38),
            ),
          );
        }

        var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        
        // FIXED: Use post frame callback to check achievements after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkForNewAchievements(snapshot.data!);
        });
        
        // Get streak from data
        int streak = data['currentStreak'] ?? 0;
        String streakMessage = data['streakMessage'] ?? "Start practicing to build a streak!";

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pass user, streak, and data to header
                _buildHeader(user, streak, data),
                
                
                // Add streak message if streak exists
                if (streak > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 20),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.whatshot, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            streakMessage,
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (streak == 0) const SizedBox(height: 20),
                
                // Add Weekly Goal Card Here
                _buildWeeklyGoalCard(),
                
                const SizedBox(height: 20),
                
                // Total Skills Progression
                _buildTotalSkillsProgression(user?.uid),
                
                const SizedBox(height: 20),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          _card(
                            height: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${data['hours'] ?? 12} hrs",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold),
                                ),
                                const Text("Practice time this week",
                                    style: TextStyle(
                                        color: Colors.white38, fontSize: 10)),
                                const SizedBox(height: 8),
                                Expanded(child: LineChart(_miniChart())),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          _card(
                            height: 65,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('MMM yyyy').format(DateTime.now()),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                const Icon(Icons.calendar_month,
                                    color: Colors.white38, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _miniStat(data['skills'].toString(), "Skills Tracked"),
                    const SizedBox(width: 10),
                    _miniStat(data['minutes'].toString(), "Total Minutes"),
                    const SizedBox(width: 10),
                    _miniStat("${data['done'] ?? 75}%", "Completion"),
                  ],
                ),
                const SizedBox(height: 20),
                _buildHistoryTimeline(user?.uid),
              ],
            ),
          ),
        );
      },
    );
  }

  // Streak badge widget
  Widget _buildStreakBadge(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            "$streak day streak",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Header with streak display
  Widget _buildHeader(User? user, int streak, Map<String, dynamic> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          const Icon(Icons.blur_on, color: Colors.white, size: 28),
          const SizedBox(width: 8),
          Text("skilltracker",
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Streak Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: streak > 0 
                        ? [Colors.orange, Colors.deepOrange]
                        : [Colors.grey, Colors.grey],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      streak > 0 ? Icons.local_fire_department : Icons.lens,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      streak > 0 ? "$streak d" : "0", // Shortened to save space
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end, 
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data['fullName'] ?? user?.displayName ?? 'User',
                      style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 13, 
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      "Community",
                      style: TextStyle(color: Colors.white38, fontSize: 9),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
          child: Container(
            height: 35,
            width: 35,
            decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
            child: const Icon(Icons.person, color: Colors.white54, size: 20),
          ),
        ),
      ],
    );
  }


  
  Widget _card({required Widget child, double? height}) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _miniStat(String val, String label) {
    return Expanded(
      child: _card(
        child: Column(
          children: [
            Text(val,
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // Weekly Goal Card Widget
  Widget _buildWeeklyGoalCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _goalService.getWeeklyProgress(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _card(
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
            ),
          );
        }
        
        final data = snapshot.data!;
        int practiced = data['practiced'];
        int goal = data['goal'];
        double percentage = data['percentage'];
        bool completed = data['completed'];
        
        String message = _goalService.getGoalMessage(percentage, practiced, goal);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: completed
                  ? [Colors.purple.withOpacity(0.3), const Color(0xFF1C1E24)]
                  : [const Color(0xFF2ECC71).withOpacity(0.2), const Color(0xFF1C1E24)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: completed ? Colors.purple : const Color(0xFF2ECC71).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        completed ? Icons.emoji_events : Icons.flag,
                        color: completed ? Colors.purple : const Color(0xFF2ECC71),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Weekly Goal",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: completed ? Colors.purple.withOpacity(0.2) : const Color(0xFF2ECC71).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$practiced/$goal min",
                      style: TextStyle(
                        color: completed ? Colors.purple : const Color(0xFF2ECC71),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Progress bar
              Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: completed
                              ? [Colors.purple, Colors.pink]
                              : [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Row(
                children: [
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: completed ? Colors.purple : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (completed)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: _showSetGoalDialog,
                      icon: const Icon(Icons.flag, size: 16),
                      label: const Text("Set New Goal"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                )
              else if (practiced == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: _showSetGoalDialog,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text("Set Your Goal"),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2ECC71),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalSkillsProgression(String? uid) {
    if (uid == null) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('skills')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        int totalCompletedMinutes = 0;
        int totalTargetHours = 0;
        
        for (var doc in snapshot.data!.docs) {
          final skill = doc.data() as Map<String, dynamic>;
          totalCompletedMinutes += (skill['totalMinutes'] as num? ?? 0).toInt();
          totalTargetHours += (skill['targetHours'] as num? ?? 10).toInt();
        }
        
        int totalCompletedHours = totalCompletedMinutes ~/ 60;
        double overallProgress = totalTargetHours > 0 ? totalCompletedHours / totalTargetHours : 0.0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1E24),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Overall Progression",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    "$totalCompletedHours hrs completed",
                    style: const TextStyle(color: Color(0xFF2ECC71), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "of $totalTargetHours hrs total",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: overallProgress.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSetGoalDialog() {
    int selectedGoal = 300;
    bool loading = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1E24),
          title: const Text(
            "Set Weekly Goal",
            style: TextStyle(color: Colors.white),
          ),
          content: loading
              ? const SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "How many minutes do you want to practice each week?",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    
                    // Goal presets
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [150, 300, 450, 600].map((minutes) {
                        return FilterChip(
                          label: Text(
                            "$minutes min",
                            style: TextStyle(
                              color: selectedGoal == minutes ? Colors.black : Colors.white70,
                            ),
                          ),
                          selected: selectedGoal == minutes,
                          onSelected: (selected) {
                            setState(() {
                              selectedGoal = minutes;
                            });
                          },
                          backgroundColor: Colors.white10,
                          selectedColor: const Color(0xFF2ECC71),
                          checkmarkColor: Colors.black,
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Custom goal input
                    Row(
                      children: [
                        const Text(
                          "Custom: ",
                          style: TextStyle(color: Colors.white38),
                        ),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Enter minutes",
                              hintStyle: const TextStyle(color: Colors.white38),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              final int? minutes = int.tryParse(value);
                              if (minutes != null && minutes > 0) {
                                setState(() {
                                  selectedGoal = minutes;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() => loading = true);
                      await _goalService.updateWeeklyGoal(selectedGoal);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Weekly goal set to $selectedGoal minutes!"),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
              ),
              child: const Text(
                "Save",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineItem(Color col, String title, String sub, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(Icons.circle_outlined, color: col, size: 14),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text(
                title, 
                style: const TextStyle(color: Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                sub, 
                style: const TextStyle(color: Colors.white38, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          time, 
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ]),
    );
  }

  Widget _buildHistoryTimeline(String? uid) {
    if (uid == null) return const SizedBox();
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('history')
          .orderBy('date', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _card(
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
            ),
          );
        }
        
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _card(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Skill Log Timeline", style: TextStyle(color: Colors.white38, fontSize: 12)),
                SizedBox(height: 15),
                Center(
                  child: Text("No practice logged yet", style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          );
        }
        
        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Skill Log Timeline", style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 15),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final minutes = data['minutes'] ?? 0;
                final skillName = data['skillName'] ?? 'Unknown';
                final topicName = data['topicName'] ?? '';
                final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                
                String timeStr = DateFormat('h:mm a - MMM d').format(date);
                String title = "$minutes min $skillName";
                String sub = topicName.isNotEmpty ? topicName : "General Practice";
                
                return _timelineItem(const Color(0xFF2ECC71), title, sub, timeStr);
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  LineChartData _miniChart() {
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: const [FlSpot(0, 1), FlSpot(1, 3), FlSpot(2, 2), FlSpot(3, 4)],
          isCurved: true,
          color: Colors.purpleAccent,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData:
              BarAreaData(show: true, color: Colors.purpleAccent.withOpacity(0.1)),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF0F1014),
      currentIndex: selectedIndex,
      onTap: (i) => setState(() => selectedIndex = i),
      selectedItemColor: const Color(0xFF2ECC71),
      unselectedItemColor: Colors.white24,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: ""),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: ""),
        BottomNavigationBarItem(icon: Icon(Icons.star_outline_rounded), label: ""),
        BottomNavigationBarItem(icon: Icon(Icons.leaderboard_rounded), label: ""),
      ],
    );
  }
}