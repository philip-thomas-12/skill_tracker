import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../services/achievement_service.dart';
import '../models/achievement_model.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final AchievementService _achievementService = AchievementService();
  String _selectedFilter = 'All';
  
  final List<String> _filters = [
    'All',
    'Skill',
    'Practice',
    'Streak',
    'Level',
    'Quiz',
    'Special',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      appBar: AppBar(
        title: const Text(
          "Achievements",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Filter button
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white70),
            color: const Color(0xFF1C1E24),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) {
              return _filters.map((filter) {
                return PopupMenuItem(
                  value: filter,
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: _selectedFilter == filter 
                          ? const Color(0xFF2ECC71) 
                          : Colors.white,
                      fontWeight: _selectedFilter == filter 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _achievementService.getUserAchievements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "No achievements data",
                style: TextStyle(color: Colors.white38),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          List<String> unlockedIds = List<String>.from(data['achievements'] ?? []);
          
          // Get all achievements with status
          var allAchievements = AchievementService.getAchievementsWithStatus(unlockedIds);
          
          // Apply filter
          if (_selectedFilter != 'All') {
            allAchievements = allAchievements.where((item) {
              final achievement = item['achievement'] as Achievement;
              return achievement.type.toLowerCase().contains(_selectedFilter.toLowerCase());
            }).toList();
          }
          
          int unlockedCount = allAchievements.where((a) => a['isUnlocked']).length;
          int totalCount = allAchievements.length;

          return Column(
            children: [
              // Stats header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Achievements",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$unlockedCount/$totalCount Unlocked",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: totalCount > 0 ? unlockedCount / totalCount : 0,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 4,
                          ),
                        ),
                        Text(
                          "${totalCount > 0 ? ((unlockedCount / totalCount) * 100).toInt() : 0}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Active filter indicator
              if (_selectedFilter != 'All')
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1E24),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.filter_list, color: Color(0xFF2ECC71), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "Filter: $_selectedFilter",
                        style: const TextStyle(color: Color(0xFF2ECC71), fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                        onPressed: () {
                          setState(() {
                            _selectedFilter = 'All';
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Achievements grid
              Expanded(
                child: allAchievements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_alt_off,
                              color: Colors.white24,
                              size: 50,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "No achievements match filter",
                              style: TextStyle(color: Colors.white38),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFilter = 'All';
                                });
                              },
                              child: const Text(
                                "Clear Filter",
                                style: TextStyle(color: Color(0xFF2ECC71)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: allAchievements.length,
                        itemBuilder: (context, index) {
                          final item = allAchievements[index];
                          final achievement = item['achievement'] as Achievement;
                          final isUnlocked = item['isUnlocked'] as bool;

                          return _buildAchievementCard(achievement, isUnlocked);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E24),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isUnlocked 
              ? achievement.color 
              : Colors.white10,
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Achievement content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with glow effect if unlocked
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUnlocked 
                        ? achievement.color.withOpacity(0.2)
                        : Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    achievement.icon,
                    color: isUnlocked 
                        ? achievement.color 
                        : Colors.white24,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.title,
                  style: TextStyle(
                    color: isUnlocked ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: isUnlocked ? Colors.white70 : Colors.white24,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                
                // Type indicator
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isUnlocked 
                        ? achievement.color.withOpacity(0.2)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    achievement.type[0].toUpperCase() + achievement.type.substring(1),
                    style: TextStyle(
                      color: isUnlocked ? achievement.color : Colors.white38,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Locked overlay or Share button
          if (!isUnlocked)
            const Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.lock,
                color: Colors.white38,
                size: 16,
              ),
            )
          else
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(
                  Icons.share,
                  color: Colors.white54,
                  size: 18,
                ),
                onPressed: () {
                  String shareMessage = "I'm thrilled to share that I just unlocked the '${achievement.title}' achievement in Skill Tracker! 🏆\n\n"
                      "Dedication and consistent practice pay off. I've been using Skill Tracker to map my learning journey and stay consistent with my goals.\n\n"
                      "Achievement unlocked: ${achievement.title} - ${achievement.description}\n\n"
                      "#LearningJourney #SkillTracker #ContinuousLearning #GrowthMindset #AchievementUnlocked";
                      
                  Share.share(shareMessage);
                },
                tooltip: "Share Achievement",
              ),
            ),
        ],
      ),
    );
  }
}