import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_tracker/services/streak_service.dart'; // Add this import

class SkillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // ==================== SKILL OPERATIONS ====================

  // Add a new skill
  Future<void> addSkill({
    required String name,
    required String category,
    required String difficulty,
    int targetLevel = 5,
    int targetHours = 0,
    int hoursPerDay = 0,
    List<dynamic> syllabus = const [],
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final skillData = {
      'name': name,
      'category': category,
      'difficulty': difficulty,
      'currentLevel': 1,
      'targetLevel': targetLevel,
      'targetHours': targetHours,
      'hoursPerDay': hoursPerDay,
      'syllabus': syllabus,
      'topicProgress': {},
      'progress': 0.0,
      'totalMinutes': 0,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'userId': user.uid,
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skills')
        .add(skillData);
    
    // Also update user's total stats
    await _updateUserStats();
  }

  // Get all skills stream
  Stream<QuerySnapshot> getSkills() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skills')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get single skill stream
  Stream<DocumentSnapshot> getSkill(String skillId) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skills')
        .doc(skillId)
        .snapshots();
  }

  // Update skill
  Future<void> updateSkill({
    required String skillId,
    String? name,
    String? category,
    String? difficulty,
    int? currentLevel,
    int? targetLevel,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (category != null) updates['category'] = category;
    if (difficulty != null) updates['difficulty'] = difficulty;
    if (currentLevel != null) updates['currentLevel'] = currentLevel;
    if (targetLevel != null) updates['targetLevel'] = targetLevel;
    
    // Recalculate progress
    if (currentLevel != null || targetLevel != null) {
      final skill = await _getSkillDoc(skillId);
      final data = skill.data() as Map<String, dynamic>;
      final newCurrent = currentLevel ?? data['currentLevel'] ?? 1;
      final newTarget = targetLevel ?? data['targetLevel'] ?? 5;
      updates['progress'] = newCurrent / newTarget;
    }
    
    updates['updatedAt'] = Timestamp.now();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skills')
        .doc(skillId)
        .update(updates);
  }

  // Delete skill
  Future<void> deleteSkill(String skillId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Delete all practice logs first
    final logs = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skills')
        .doc(skillId)
        .collection('logs')
        .get();
    
    for (var log in logs.docs) {
      await log.reference.delete();
    }

    // Delete the skill
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skills')
        .doc(skillId)
        .delete();

    // Update user stats
    await _updateUserStats();
  }

  // ==================== PRACTICE LOGGING ====================

  // Log practice time for a skill
  Future<void> logPractice({
    required String skillId,
    required int minutes,
    String? notes,
    String? topicName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    print('📝 Logging practice: $minutes minutes for skill: $skillId');

    // Add practice log
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skills')
        .doc(skillId)
        .collection('logs')
        .add({
          'minutes': minutes,
          'notes': notes ?? '',
          'topicName': topicName ?? '',
          'date': Timestamp.now(),
        });

    // Update skill total minutes
    final skillRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skills')
        .doc(skillId);
    
    Map<String, dynamic> updates = {
      'totalMinutes': FieldValue.increment(minutes),
      'updatedAt': Timestamp.now(),
    };
    if (topicName != null && topicName.isNotEmpty) {
      updates['topicProgress.$topicName'] = FieldValue.increment(minutes);
    }
    await skillRef.update(updates);

    // Check if level should increase (every 60 minutes = 1 level)
    final skill = await skillRef.get();
    final data = skill.data() as Map<String, dynamic>;
    final totalMinutes = (data['totalMinutes'] ?? 0) as int;
    final currentLevel = data['currentLevel'] ?? 1;
    final targetLevel = data['targetLevel'] ?? 5;
    final skillName = data['name'] ?? 'Unknown Skill';
    
    // Log to global history collection
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .add({
          'skillId': skillId,
          'skillName': skillName,
          'topicName': topicName ?? '',
          'minutes': minutes,
          'notes': notes ?? '',
          'date': Timestamp.now(),
        });

    // Simple leveling: every 60 minutes = 1 level
    int newLevel = 1 + (totalMinutes ~/ 60);
    newLevel = newLevel.clamp(1, targetLevel) as int;
    
    if (newLevel != currentLevel) {
      await skillRef.update({
        'currentLevel': newLevel,
        'progress': newLevel / targetLevel,
      });
    }

    // Update user stats
    await _updateUserStats();
    
    // ========== STREAK SERVICE INTEGRATION ==========
    // Update streak after successful practice
    try {
      print('🔥 Calling StreakService.updateStreak()');
      final streakService = StreakService();
      await streakService.updateStreak();
      print('✅ Streak updated successfully after practice');
    } catch (e) {
      // Log error but don't fail the practice logging
      print('❌ Error updating streak: $e');
    }
    // ================================================
  }

  // Get practice logs for a skill
  Stream<QuerySnapshot> getPracticeLogs(String skillId) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skills')
        .doc(skillId)
        .collection('logs')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // ==================== DOCUMENTS & NOTES ====================
  
  // Upload a note/file for a specific topic
  Future<void> uploadTopicNote({
    required String skillId,
    required String topicName,
    required String customName,
    required String downloadUrl,
    required String storagePath,
    required String fileType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Add document to subcollection
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skills')
        .doc(skillId)
        .collection('notes')
        .add({
      'topicName': topicName,
      'name': customName,
      'url': downloadUrl,
      'path': storagePath,
      'type': fileType, // 'image' or 'document'
      'createdAt': Timestamp.now(),
    });
  }

  // Get notes for a topic
  Stream<QuerySnapshot> getTopicNotes(String skillId, String topicName) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skills')
        .doc(skillId)
        .collection('notes')
        .where('topicName', isEqualTo: topicName)
        // Removed orderBy('createdAt', descending: true) to avoid needing a composite index
        .snapshots();
  }

  // Delete a note
  Future<void> deleteTopicNote(String skillId, String noteId, String storagePath) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Delete from Firestore
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skills')
        .doc(skillId)
        .collection('notes')
        .doc(noteId)
        .delete();
  }

  // ==================== USER STATS ====================

  // Get user stats
  Stream<DocumentSnapshot> getUserStats() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots();
  }

  // Update user stats (call this after any skill change)
  Future<void> _updateUserStats() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Get all skills
    final skillsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skills')
        .get();

    final skills = skillsSnapshot.docs;
    
    if (skills.isEmpty) {
      await _firestore.collection('users').doc(user.uid).set({
        'skills': 0,
        'minutes': 0,
        'progress': 0.0,
        'hours': 0,
        'done': 0,
      }, SetOptions(merge: true));
      return;
    }

    // Calculate stats
    int totalMinutes = 0;
    double totalProgress = 0.0;
    
    for (var skill in skills) {
      final data = skill.data();
      totalMinutes += (data['totalMinutes'] ?? 0) as int;
      totalProgress += (data['progress'] ?? 0.0).toDouble();
    }

    int skillCount = skills.length;
    double avgProgress = skillCount > 0 ? totalProgress / skillCount : 0.0;
    int hours = (totalMinutes / 60).round();
    int donePercent = (avgProgress * 100).round();

    // Update user document
    await _firestore.collection('users').doc(user.uid).set({
      'skills': skillCount,
      'minutes': totalMinutes,
      'progress': avgProgress,
      'hours': hours,
      'done': donePercent,
    }, SetOptions(merge: true));
  }

  // ==================== HELPER METHODS ====================

  Future<DocumentSnapshot> _getSkillDoc(String skillId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('skills')
        .doc(skillId)
        .get();
  }

  // ==================== TEST METHOD ====================
  // Temporary method to test streak manually
  Future<void> testStreakManually() async {
    try {
      print('🧪 Testing streak manually...');
      final streakService = StreakService();
      await streakService.updateStreak();
      print('✅ Test streak completed');
    } catch (e) {
      print('❌ Test streak failed: $e');
    }
  }
}