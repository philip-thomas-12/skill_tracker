import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'add_skill_page.dart';
import 'skill_detail_page.dart';
import 'quiz_page.dart';
import '../services/skill_service.dart';

class SkillListPage extends StatefulWidget {
  const SkillListPage({super.key});

  @override
  State<SkillListPage> createState() => _SkillListPageState();
}

class _SkillListPageState extends State<SkillListPage> {
  final SkillService _skillService = SkillService();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Development',
    'Design',
    'Business',
    'Marketing',
    'Soft Skills',
    'Languages',
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      appBar: AppBar(
        title: const Text(
          "My Skills",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: _showSearchDialog,
          ),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Main FAB for adding skills
          FloatingActionButton(
            heroTag: "skillFab",
            backgroundColor: const Color(0xFF2ECC71),
            child: const Icon(Icons.add, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSkillPage()),
              );
              // If a skill was added, show a snackbar
              if (result == true && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Skill added successfully!"),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar (if search is active)
          if (_searchQuery.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(15),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1E24),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white38, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Searching: $_searchQuery",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                ],
              ),
            ),
          
          // Skills list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _skillService.getSkills(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
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

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1E24),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.psychology,
                            color: Color(0xFF2ECC71),
                            size: 50,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "No skills added yet",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Tap the + button to add your first skill",
                          style: TextStyle(color: Colors.white38),
                        ),
                      ],
                    ),
                  );
                }

                // Filter and search skills
                var skills = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  
                  // Apply category filter
                  if (_selectedFilter != 'All' && data['category'] != _selectedFilter) {
                    return false;
                  }
                  
                  // Apply search filter
                  if (_searchQuery.isNotEmpty) {
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final category = (data['category'] ?? '').toString().toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    return name.contains(query) || category.contains(query);
                  }
                  
                  return true;
                }).toList();

                if (skills.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt_off, color: Colors.white38, size: 50),
                        const SizedBox(height: 10),
                        Text(
                          "No skills match your filters",
                          style: TextStyle(color: Colors.white38),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = 'All';
                              _searchQuery = '';
                            });
                          },
                          child: const Text(
                            "Clear filters",
                            style: TextStyle(color: Color(0xFF2ECC71)),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: skills.length,
                  itemBuilder: (context, index) {
                    final doc = skills[index];
                    final skill = doc.data() as Map<String, dynamic>;
                    final progress = (skill['progress'] ?? 0.0).toDouble();
                    final currentLevel = skill['currentLevel'] ?? 1;
                    final targetLevel = skill['targetLevel'] ?? 5;
                    final totalMinutes = skill['totalMinutes'] ?? 0;

                    return _buildSkillCard(
                      docId: doc.id,
                      skill: skill,
                      progress: progress,
                      currentLevel: currentLevel,
                      targetLevel: targetLevel,
                      totalMinutes: totalMinutes,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard({
    required String docId,
    required Map<String, dynamic> skill,
    required double progress,
    required int currentLevel,
    required int targetLevel,
    required int totalMinutes,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E24),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: progress >= 1.0 
              ? const Color(0xFF2ECC71).withOpacity(0.5) 
              : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            // Navigate to skill detail page for detailed view and practice
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SkillDetailPage(
                  skillId: docId,
                  skillName: skill['name'] ?? '',
                  category: skill['category'] ?? '',
                  difficulty: skill['difficulty'] ?? '',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  children: [
                    // Skill icon based on category
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(skill['category']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getCategoryIcon(skill['category']),
                        color: _getCategoryColor(skill['category']),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Skill info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  skill['name'] ?? "",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (progress >= 1.0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2ECC71).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    "Mastered",
                                    style: TextStyle(
                                      color: Color(0xFF2ECC71),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  skill['category'] ?? "",
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(skill['difficulty']).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  skill['difficulty'] ?? "",
                                  style: TextStyle(
                                    color: _getDifficultyColor(skill['difficulty']),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Level indicator
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "$currentLevel/$targetLevel",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Progress bar
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF2ECC71),
                                    const Color(0xFF27AE60),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Practice minutes info
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: Colors.white38, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "$totalMinutes min practiced",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                         "${(targetLevel * 60) - totalMinutes} min to master",
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Quick practice buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickPracticeButton(docId, 15, Colors.blue),
                    _buildQuickPracticeButton(docId, 30, Colors.green),
                    _buildQuickPracticeButton(docId, 60, Colors.orange),
                  ],
                ),
                
                const SizedBox(height: 5),
                
                // Quiz and delete buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Quiz button
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizPage(
                              skillName: skill['name'],
                              difficulty: skill['difficulty'],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.quiz, size: 16, color: Colors.orange),
                      label: const Text(
                        "Quiz",
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 5),
                    
                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _showDeleteDialog(context, docId, skill['name']),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build quick practice buttons
  Widget _buildQuickPracticeButton(String skillId, int minutes, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => _quickPractice(skillId, minutes),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.2),
            foregroundColor: color,
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: color.withOpacity(0.5)),
            ),
            elevation: 0,
          ),
          child: Text(
            "$minutes min",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Quick practice method
  Future<void> _quickPractice(String skillId, int minutes) async {
    try {
      await _skillService.logPractice(
        skillId: skillId,
        minutes: minutes,
        notes: "Quick practice from skill list",
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Logged $minutes minutes of practice!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context, String skillId, String skillName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1E24),
        title: const Text(
          "Delete Skill",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Are you sure you want to delete '$skillName'? All practice history will be lost.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _skillService.deleteSkill(skillId);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Skill deleted"),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1E24),
        title: const Text(
          "Search Skills",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter skill name or category...",
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF2ECC71)),
            ),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF2ECC71)),
          ),
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value;
            });
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Development':
        return Colors.blue;
      case 'Design':
        return Colors.purple;
      case 'Business':
        return Colors.orange;
      case 'Marketing':
        return Colors.pink;
      case 'Soft Skills':
        return Colors.teal;
      case 'Languages':
        return Colors.amber;
      default:
        return const Color(0xFF2ECC71);
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Development':
        return Icons.code;
      case 'Design':
        return Icons.design_services;
      case 'Business':
        return Icons.business_center;
      case 'Marketing':
        return Icons.trending_up;
      case 'Soft Skills':
        return Icons.people;
      case 'Languages':
        return Icons.language;
      default:
        return Icons.psychology;
    }
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}