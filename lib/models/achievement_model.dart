import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int threshold;
  final String type; // 'skill', 'practice', 'streak', 'level', 'quiz'

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.threshold,
    required this.type,
  });

  static List<Achievement> getAllAchievements() {
    return [
      // ========== SKILL-BASED ACHIEVEMENTS ==========
      Achievement(
        id: 'first_skill',
        title: 'First Step',
        description: 'Added your first skill',
        icon: Icons.emoji_events,
        color: Colors.amber,
        threshold: 1,
        type: 'skill',
      ),
      Achievement(
        id: 'skill_collector_5',
        title: 'Skill Collector',
        description: 'Added 5 different skills',
        icon: Icons.collections_bookmark,
        color: Colors.blue,
        threshold: 5,
        type: 'skill',
      ),
      Achievement(
        id: 'skill_master_10',
        title: 'Skill Master',
        description: 'Added 10 different skills',
        icon: Icons.stars,
        color: Colors.purple,
        threshold: 10,
        type: 'skill',
      ),
      
      // ========== PRACTICE-BASED ACHIEVEMENTS ==========
      Achievement(
        id: 'practice_100',
        title: 'Dedicated Learner',
        description: 'Practiced 100 minutes total',
        icon: Icons.timer,
        color: Colors.green,
        threshold: 100,
        type: 'practice',
      ),
      Achievement(
        id: 'practice_500',
        title: 'Practice Warrior',
        description: 'Practiced 500 minutes total',
        icon: Icons.av_timer,
        color: Colors.teal,
        threshold: 500,
        type: 'practice',
      ),
      Achievement(
        id: 'practice_1000',
        title: 'Practice Legend',
        description: 'Practiced 1000 minutes total',
        icon: Icons.timelapse,
        color: Colors.orange,
        threshold: 1000,
        type: 'practice',
      ),
      Achievement(
        id: 'practice_5000',
        title: 'Practice Master',
        description: 'Practiced 5000 minutes total',
        icon: Icons.timer_off,
        color: Colors.red,
        threshold: 5000,
        type: 'practice',
      ),
      
      // ========== STREAK-BASED ACHIEVEMENTS ==========
      Achievement(
        id: 'streak_3',
        title: 'Getting Started',
        description: '3 day practice streak',
        icon: Icons.local_fire_department,
        color: Colors.orange,
        threshold: 3,
        type: 'streak',
      ),
      Achievement(
        id: 'streak_7',
        title: 'Week Warrior',
        description: '7 day practice streak',
        icon: Icons.local_fire_department,
        color: Colors.orange,
        threshold: 7,
        type: 'streak',
      ),
      Achievement(
        id: 'streak_14',
        title: 'Two Weeks Strong',
        description: '14 day practice streak',
        icon: Icons.whatshot,
        color: Colors.deepOrange,
        threshold: 14,
        type: 'streak',
      ),
      Achievement(
        id: 'streak_30',
        title: 'Monthly Master',
        description: '30 day practice streak',
        icon: Icons.whatshot,
        color: Colors.red,
        threshold: 30,
        type: 'streak',
      ),
      Achievement(
        id: 'streak_60',
        title: 'Two Month Legend',
        description: '60 day practice streak',
        icon: Icons.emoji_nature,
        color: Colors.purple,
        threshold: 60,
        type: 'streak',
      ),
      Achievement(
        id: 'streak_100',
        title: 'Streak Legend',
        description: '100 day practice streak',
        icon: Icons.emoji_nature,
        color: Colors.purple,
        threshold: 100,
        type: 'streak',
      ),
      
      // ========== LEVEL-BASED ACHIEVEMENTS ==========
      Achievement(
        id: 'level_5',
        title: 'Getting Started',
        description: 'Reached level 5 in any skill',
        icon: Icons.trending_up,
        color: Colors.lightGreen,
        threshold: 5,
        type: 'level',
      ),
      Achievement(
        id: 'level_10',
        title: 'Skill Enthusiast',
        description: 'Reached level 10 in any skill',
        icon: Icons.rocket_launch,
        color: Colors.cyan,
        threshold: 10,
        type: 'level',
      ),
      Achievement(
        id: 'level_25',
        title: 'Expert',
        description: 'Reached level 25 in any skill',
        icon: Icons.military_tech,
        color: Colors.amber,
        threshold: 25,
        type: 'level',
      ),
      Achievement(
        id: 'level_50',
        title: 'Master',
        description: 'Reached level 50 in any skill',
        icon: Icons.workspace_premium,
        color: Colors.amber,
        threshold: 50,
        type: 'level',
      ),
      Achievement(
        id: 'level_100',
        title: 'Grand Master',
        description: 'Reached level 100 in any skill',
        icon: Icons.emoji_events,
        color: Colors.amber,
        threshold: 100,
        type: 'level',
      ),
      
      // ========== QUIZ-BASED ACHIEVEMENTS ==========
      Achievement(
        id: 'quiz_first',
        title: 'Quiz Taker',
        description: 'Completed your first quiz',
        icon: Icons.quiz,
        color: Colors.indigo,
        threshold: 1,
        type: 'quiz',
      ),
      Achievement(
        id: 'quiz_perfect',
        title: 'Quiz Master',
        description: 'Got 100% on a quiz',
        icon: Icons.auto_awesome,
        color: Colors.pink,
        threshold: 1,
        type: 'quiz_perfect',
      ),
      Achievement(
        id: 'quiz_5',
        title: 'Quiz Enthusiast',
        description: 'Completed 5 quizzes',
        icon: Icons.school,
        color: Colors.deepPurple,
        threshold: 5,
        type: 'quiz',
      ),
      Achievement(
        id: 'quiz_10',
        title: 'Quiz Champion',
        description: 'Completed 10 quizzes',
        icon: Icons.school,
        color: Colors.deepPurple,
        threshold: 10,
        type: 'quiz',
      ),
      Achievement(
        id: 'quiz_25',
        title: 'Quiz Legend',
        description: 'Completed 25 quizzes',
        icon: Icons.menu_book,
        color: Colors.deepPurple,
        threshold: 25,
        type: 'quiz',
      ),
      Achievement(
        id: 'topic_complete',
        title: 'Topic Master',
        description: 'Completed a syllabus topic',
        icon: Icons.assignment_turned_in,
        color: Colors.cyanAccent,
        threshold: 1,
        type: 'special',
      ),
      
      // ========== SPECIAL ACHIEVEMENTS ==========
      Achievement(
        id: 'complete_profile',
        title: 'All Set',
        description: 'Completed your profile setup',
        icon: Icons.person,
        color: Colors.teal,
        threshold: 1,
        type: 'special',
      ),
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Practiced before 8 AM',
        icon: Icons.wb_sunny,
        color: Colors.yellow,
        threshold: 1,
        type: 'special',
      ),
      Achievement(
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Practiced after 10 PM',
        icon: Icons.nightlight,
        color: Colors.deepPurple,
        threshold: 1,
        type: 'special',
      ),
      Achievement(
        id: 'weekend_warrior',
        title: 'Weekend Warrior',
        description: 'Practiced on both Saturday and Sunday',
        icon: Icons.calendar_month,
        color: Colors.green,
        threshold: 1,
        type: 'special',
      ),
    ];
  }

  // Get achievements by type
  static List<Achievement> getByType(String type) {
    return getAllAchievements().where((a) => a.type == type).toList();
  }

  // Get achievement by ID
  static Achievement? getById(String id) {
    try {
      return getAllAchievements().firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get total number of achievements
  static int get totalCount => getAllAchievements().length;

  // Get color for achievement type
  static Color getTypeColor(String type) {
    switch (type) {
      case 'skill':
        return Colors.blue;
      case 'practice':
        return Colors.green;
      case 'streak':
        return Colors.orange;
      case 'level':
        return Colors.purple;
      case 'quiz':
        return Colors.indigo;
      case 'quiz_perfect':
        return Colors.pink;
      case 'special':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Get icon for achievement type
  static IconData getTypeIcon(String type) {
    switch (type) {
      case 'skill':
        return Icons.code;
      case 'practice':
        return Icons.timer;
      case 'streak':
        return Icons.local_fire_department;
      case 'level':
        return Icons.trending_up;
      case 'quiz':
        return Icons.quiz;
      case 'quiz_perfect':
        return Icons.auto_awesome;
      case 'special':
        return Icons.star;
      default:
        return Icons.emoji_events;
    }
  }
}