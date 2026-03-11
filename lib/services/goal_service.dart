import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get weekly goal progress
  Future<Map<String, dynamic>> getWeeklyProgress() async {
    final user = _auth.currentUser;
    if (user == null) return {'practiced': 0, 'goal': 300, 'percentage': 0.0, 'remaining': 300, 'completed': false};

    final now = DateTime.now();
    // Start of week (Monday)
    final startOfWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
    
    // Get user's weekly goal (default 300 minutes = 5 hours)
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    int goal = userDoc.data()?['weeklyGoal'] ?? 300;
    
    // Get all practice logs from this week
    int weeklyMinutes = 0;
    
    try {
      final skillsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('skills')
          .get();
      
      for (var skill in skillsSnapshot.docs) {
        final logsSnapshot = await skill.reference
            .collection('logs')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
            .get();
        
        for (var log in logsSnapshot.docs) {
          weeklyMinutes += (log['minutes'] ?? 0) as int;
        }
      }
    } catch (e) {
      print('Error getting weekly progress: $e');
    }
    
    double percentage = weeklyMinutes / goal;
    int remaining = (goal - weeklyMinutes).clamp(0, goal).toInt();
    
    return {
      'practiced': weeklyMinutes,
      'goal': goal,
      'percentage': percentage > 1.0 ? 1.0 : percentage,
      'remaining': remaining,
      'completed': weeklyMinutes >= goal,
    };
  }

  // Update weekly goal
  Future<void> updateWeeklyGoal(int newGoal) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _firestore.collection('users').doc(user.uid).update({
      'weeklyGoal': newGoal,
    });
  }

  // Get motivational message based on progress
  String getGoalMessage(double percentage, int practiced, int goal) {
    if (percentage >= 1.0) {
      return "🎉 Goal achieved! Amazing work! You've practiced $practiced/$goal minutes!";
    } else if (percentage >= 0.75) {
      return "🌟 Almost there! Only ${goal - practiced} minutes to go!";
    } else if (percentage >= 0.5) {
      return "💪 Halfway there! Keep going! ${goal - practiced} minutes remaining.";
    } else if (percentage >= 0.25) {
      return "📚 Good progress! ${goal - practiced} minutes left this week.";
    } else if (practiced > 0) {
      return "🎯 Great start! You need ${goal - practiced} more minutes to reach your goal.";
    } else {
      return "🎯 Set a weekly goal and start practicing!";
    }
  }

  // Get suggested goals based on user's history
  Future<List<int>> getSuggestedGoals() async {
    final user = _auth.currentUser;
    if (user == null) return [150, 300, 450, 600];
    
    // Get average weekly practice from last 4 weeks
    final now = DateTime.now();
    final fourWeeksAgo = now.subtract(const Duration(days: 28));
    
    int totalMinutes = 0;
    int weeksWithData = 0;
    
    try {
      final skillsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('skills')
          .get();
      
      for (var skill in skillsSnapshot.docs) {
        final logsSnapshot = await skill.reference
            .collection('logs')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(fourWeeksAgo))
            .get();
        
        // Group by week
        Map<int, int> weeklyMinutes = {};
        
        // FIXED: Properly handle the type conversion
        for (var log in logsSnapshot.docs) {
          final date = (log['date'] as Timestamp).toDate();
          final weekNumber = date.difference(fourWeeksAgo).inDays ~/ 7;
          
          // Get current value safely (default to 0 if null)
          int currentValue = weeklyMinutes[weekNumber] ?? 0;
          
          // Get minutes safely and ensure it's int
          int minutes = 0;
          var minutesData = log['minutes'];
          if (minutesData is int) {
            minutes = minutesData;
          } else if (minutesData is double) {
            minutes = minutesData.toInt();
          } else {
            minutes = 0;
          }
          
          // Calculate new value and assign
          weeklyMinutes[weekNumber] = currentValue + minutes;
        }
        
        // Sum up all weekly minutes for this skill
        for (var minutes in weeklyMinutes.values) {
          totalMinutes += minutes;
        }
        weeksWithData += weeklyMinutes.length;
      }
    } catch (e) {
      print('Error getting suggested goals: $e');
    }
    
    // Calculate average weekly minutes
    int avgWeekly = weeksWithData > 0 ? (totalMinutes / weeksWithData).round() : 150;
    
    // Ensure we have reasonable values
    if (avgWeekly < 30) avgWeekly = 150; // Minimum reasonable goal
    
    // Suggest goals based on average
    return [
      (avgWeekly * 0.8).round(), // Slightly less
      avgWeekly,                  // Same as average
      (avgWeekly * 1.2).round(), // Slightly more
      (avgWeekly * 1.5).round(), // Challenging
    ];
  }

  // Optional: Get current week number
  int getCurrentWeekNumber() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final days = now.difference(startOfYear).inDays;
    return (days / 7).ceil();
  }

  // Optional: Reset weekly goal to default
  Future<void> resetWeeklyGoal() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    await _firestore.collection('users').doc(user.uid).update({
      'weeklyGoal': 300,
    });
  }
}