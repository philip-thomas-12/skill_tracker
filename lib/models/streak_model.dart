import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Update streak when user practices
  Future<void> updateStreak() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();
    
    if (!userDoc.exists) return;
    
    final data = userDoc.data() as Map<String, dynamic>;
    final lastPractice = (data['lastPracticeDate'] as Timestamp?)?.toDate();
    final currentStreak = data['currentStreak'] ?? 0;
    final longestStreak = data['longestStreak'] ?? 0;
    
    int newStreak = 1;
    String message = "Started new streak! 🔥";
    
    if (lastPractice != null) {
      final difference = today.difference(lastPractice).inDays;
      
      if (difference == 1) {
        // Consecutive day
        newStreak = currentStreak + 1;
        message = "Streak continues! $newStreak days! 🔥";
      } else if (difference == 0) {
        // Same day - don't increase
        newStreak = currentStreak;
        message = "Already practiced today! 💪";
      } else {
        // Missed days - reset
        newStreak = 1;
        message = "New streak started! 🔥";
      }
    }
    
    await userRef.set({
      'currentStreak': newStreak,
      'longestStreak': newStreak > longestStreak ? newStreak : longestStreak,
      'lastPracticeDate': Timestamp.now(),
      'streakMessage': message,
    }, SetOptions(merge: true));
  }

  // Get streak data stream
  Stream<DocumentSnapshot> getStreak() {
    final user = _auth.currentUser;
    // FIXED: Added missing closing parenthesis
    if (user == null) throw Exception('User not logged in');
    
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  // Get motivational message based on streak
  String getMotivationMessage(int streak) {
    if (streak == 0) {
      return "Start your journey today! 💪";
    } else if (streak == 1) {
      return "Great first day! Come back tomorrow! 🌟";
    } else if (streak < 3) {
      return "Good start! $streak days in a row! 🔥";
    } else if (streak < 7) {
      return "You're on fire! $streak day streak! 🚀";
    } else if (streak < 30) {
      return "Incredible! $streak day streak! 🏆";
    } else {
      return "LEGEND! $streak day streak! 👑";
    }
  }
}