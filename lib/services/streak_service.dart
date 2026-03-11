import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Update streak when user practices
  Future<void> updateStreak() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No user logged in');
      return;
    }

    print('🔥 Updating streak for user: ${user.uid}');
    final today = DateTime.now();
    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();
    
    // If document doesn't exist, create it with streak fields
    if (!userDoc.exists) {
      print('📝 Creating new user document with streak fields');
      await userRef.set({
        'currentStreak': 0,
        'longestStreak': 0,
        'lastPracticeDate': null,
        'streakMessage': "Start practicing to build a streak!",
        'createdAt': Timestamp.now(),
      }, SetOptions(merge: true));
      return;
    }
    
    // Document exists, update streak
    final data = userDoc.data() as Map<String, dynamic>;
    
    // Check if streak fields exist, if not add them
    if (!data.containsKey('currentStreak')) {
      print('📝 Adding missing streak fields to existing user document');
      await userRef.set({
        'currentStreak': 0,
        'longestStreak': 0,
        'lastPracticeDate': null,
        'streakMessage': "Start practicing to build a streak!",
      }, SetOptions(merge: true));
      return;
    }
    
    // Normal streak update logic
    final lastPractice = (data['lastPracticeDate'] as Timestamp?)?.toDate();
    final currentStreak = data['currentStreak'] ?? 0;
    final longestStreak = data['longestStreak'] ?? 0;
    
    print('📊 Current streak: $currentStreak');
    print('📅 Last practice: $lastPractice');
    
    int newStreak = 1;
    String message = "Started new streak! 🔥";
    
    if (lastPractice != null) {
      final difference = today.difference(lastPractice).inDays;
      print('📅 Days since last practice: $difference');
      
      if (difference == 1) {
        // Consecutive day
        newStreak = currentStreak + 1;
        message = "Streak continues! $newStreak days! 🔥";
        print('✅ Consecutive day! New streak: $newStreak');
      } else if (difference == 0) {
        // Same day - don't increase
        newStreak = currentStreak;
        message = "Already practiced today! 💪";
        print('⏰ Same day practice - streak unchanged: $newStreak');
      } else {
        // Missed days - reset
        newStreak = 1;
        message = "New streak started! 🔥";
        print('🔄 Streak reset to 1 (missed $difference days)');
      }
    } else {
      print('🎯 First practice ever!');
    }
    
    await userRef.set({
      'currentStreak': newStreak,
      'longestStreak': newStreak > longestStreak ? newStreak : longestStreak,
      'lastPracticeDate': Timestamp.now(),
      'streakMessage': message,
    }, SetOptions(merge: true));
    
    print('✅ Streak updated to: $newStreak');
  }

  // Get streak data stream
  Stream<DocumentSnapshot> getStreak() {
    final user = _auth.currentUser;
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

  // Reset streak (for testing)
  Future<void> resetStreak() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _firestore.collection('users').doc(user.uid).set({
      'currentStreak': 0,
      'longestStreak': 0,
      'lastPracticeDate': null,
      'streakMessage': "Start practicing to build a streak!",
    }, SetOptions(merge: true));
    
    print('🔄 Streak reset to 0');
  }
}