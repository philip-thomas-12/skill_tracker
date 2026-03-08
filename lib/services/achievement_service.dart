import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/achievement_model.dart';

class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check and unlock achievements
  Future<void> checkAndUnlockAchievements() async {
    final user = _auth.currentUser;
    if (user == null) return;

    print('🏆 Checking achievements for user: ${user.uid}');
    
    // Get user data
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return;
    
    final userData = userDoc.data() as Map<String, dynamic>;
    List<String> unlockedAchievements = List<String>.from(userData['achievements'] ?? []);
    
    // Get all skills
    final skillsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skills')
        .get();
    
    final skills = skillsSnapshot.docs;
    
    // Calculate stats
    int totalSkills = skills.length;
    int totalMinutes = 0;
    int maxLevel = 0;
    
    for (var skill in skills) {
      final data = skill.data();
      totalMinutes += (data['totalMinutes'] ?? 0) as int;
      int level = data['currentLevel'] ?? 1;
      if (level > maxLevel) maxLevel = level;
    }
    
    int streak = userData['currentStreak'] ?? 0;
    
    // Get quiz stats (you'll need to add these fields when quiz is completed)
    int quizzesTaken = userData['quizzesTaken'] ?? 0;
    bool hasPerfectQuiz = userData['hasPerfectQuiz'] ?? false;
    
    // Check each achievement
    List<String> newlyUnlocked = [];
    
    for (var achievement in Achievement.getAllAchievements()) {
      if (unlockedAchievements.contains(achievement.id)) continue;
      
      bool shouldUnlock = false;
      
      switch (achievement.type) {
        case 'skill':
          shouldUnlock = totalSkills >= achievement.threshold;
          break;
        case 'practice':
          shouldUnlock = totalMinutes >= achievement.threshold;
          break;
        case 'streak':
          shouldUnlock = streak >= achievement.threshold;
          break;
        case 'level':
          shouldUnlock = maxLevel >= achievement.threshold;
          break;
        case 'quiz':
          shouldUnlock = quizzesTaken >= achievement.threshold;
          break;
        case 'quiz_perfect':
          shouldUnlock = hasPerfectQuiz;
          break;
      }
      
      if (shouldUnlock) {
        unlockedAchievements.add(achievement.id);
        newlyUnlocked.add(achievement.id);
        print('🎉 New achievement unlocked: ${achievement.title}');
      }
    }
    
    // Update Firestore if new achievements unlocked
    if (newlyUnlocked.isNotEmpty) {
      await _firestore.collection('users').doc(user.uid).update({
        'achievements': unlockedAchievements,
        'lastUnlockedAchievements': newlyUnlocked,
        'updatedAt': Timestamp.now(),
      });
      
      // Store the newly unlocked achievements in a temporary field for showing popups
      await _firestore.collection('users').doc(user.uid).update({
        'newAchievements': FieldValue.arrayUnion(newlyUnlocked),
      });
    }
  }

  // Get user achievements stream
  Stream<DocumentSnapshot> getUserAchievements() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  // Get all achievements with unlocked status
  static List<Map<String, dynamic>> getAchievementsWithStatus(
    List<String> unlockedIds,
  ) {
    final allAchievements = Achievement.getAllAchievements();
    
    return allAchievements.map((achievement) {
      return {
        'achievement': achievement,
        'isUnlocked': unlockedIds.contains(achievement.id),
      };
    }).toList();
  }

  // Clear new achievements notification
  Future<void> clearNewAchievements() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _firestore.collection('users').doc(user.uid).update({
      'newAchievements': [],
    });
  }

  // Increment quiz count (call this when quiz is completed)
  Future<void> incrementQuizCount(bool isPerfect) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final userRef = _firestore.collection('users').doc(user.uid);
    
    await userRef.update({
      'quizzesTaken': FieldValue.increment(1),
    });
    
    if (isPerfect) {
      await userRef.update({
        'hasPerfectQuiz': true,
      });
    }
    
    // Check achievements after updating quiz stats
    await checkAndUnlockAchievements();
  }
}