import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_progress_model.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateProgress(String userId, String pathwayId, List<String> completedItems) async {
    final docRef = _firestore.collection('user_progress').doc('${userId}_$pathwayId');
    
    // Calculate status
    // Note: To be precise we'd need total items count, but for now we'll just set to in_progress
    // or we can pass total items to this method.
    // For simplicity: if completedItems > 0 -> in_progress. 
    // real app would check if completedItems.length == totalItems -> completed.
    
    String status = completedItems.isNotEmpty ? 'in_progress' : 'not_started';

    final data = {
      'userId': userId,
      'pathwayId': pathwayId,
      'completedSyllabusItems': completedItems,
      'status': status, // Logic to set to 'completed' should be handled in UI or here if total count known
      'lastAccessed': FieldValue.serverTimestamp(),
    };

    await docRef.set(data, SetOptions(merge: true));
  }

  Stream<UserProgress?> getProgressStream(String userId, String pathwayId) {
    return _firestore.collection('user_progress').doc('${userId}_$pathwayId').snapshots().map((doc) {
      if (doc.exists) {
        return UserProgress.fromMap(doc.data()!);
      }
      return null;
    });
  }
}
