import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/skill_model.dart';
import '../models/session_model.dart';

class DatabaseService {
  final String userId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DatabaseService({required this.userId});

  // Collection References
  CollectionReference get _skillsRef => _db.collection('users').doc(userId).collection('skills');
  CollectionReference get _sessionsRef => _db.collection('users').doc(userId).collection('sessions');

  // --- Skills ---

  // Get Skills Stream
  Stream<List<Skill>> get skills {
    return _skillsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Skill.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Add Skill
  Future<void> addSkill(String name, String category, double targetHours) async {
    await _skillsRef.add({
      'userId': userId,
      'name': name,
      'category': category,
      'targetHours': targetHours,
      'completedHours': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete Skill
  Future<void> deleteSkill(String skillId) async {
    await _skillsRef.doc(skillId).delete();
  }

  // --- Sessions ---

  // Log Learning Session
  Future<void> logSession(String skillId, double duration, String? notes) async {
    // Batch write to ensure both session is added and skill is updated
    WriteBatch batch = _db.batch();

    // 1. Create session doc
    DocumentReference sessionDoc = _sessionsRef.doc();
    batch.set(sessionDoc, {
      'skillId': skillId,
      'userId': userId,
      'date': DateTime.now().toIso8601String(),
      'durationInHours': duration,
      'notes': notes,
    });

    // 2. Update skill completed hours
    DocumentReference skillDoc = _skillsRef.doc(skillId);
    batch.update(skillDoc, {
      'completedHours': FieldValue.increment(duration),
    });

    await batch.commit();
  }

  // Get Sessions for a Skill (Optional for history)
  Stream<List<LearningSession>> getSessionsForSkill(String skillId) {
    return _sessionsRef
        .where('skillId', isEqualTo: skillId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return LearningSession.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get All Sessions (For Progress Page)
  Stream<List<LearningSession>> get allSessions {
    return _sessionsRef
        .orderBy('date', descending: true)
        // Limit to recent 100 or so to avoid huge reads, or filter by date range if needed
        .limit(100) 
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return LearningSession.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
