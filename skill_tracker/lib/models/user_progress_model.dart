import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgress {
  String userId;
  String pathwayId;
  String status; // 'not_started', 'in_progress', 'completed'
  int secondsSpent;
  List<String> completedSyllabusItems; // IDs or Indices of completed items
  DateTime? lastAccessed;

  UserProgress({
    required this.userId,
    required this.pathwayId,
    required this.status,
    this.secondsSpent = 0,
    required this.completedSyllabusItems,
    this.lastAccessed,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pathwayId': pathwayId,
      'status': status,
      'secondsSpent': secondsSpent,
      'completedSyllabusItems': completedSyllabusItems,
      'lastAccessed': lastAccessed != null ? Timestamp.fromDate(lastAccessed!) : FieldValue.serverTimestamp(),
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      userId: map['userId'] ?? '',
      pathwayId: map['pathwayId'] ?? '',
      status: map['status'] ?? 'not_started',
      secondsSpent: map['secondsSpent'] ?? 0,
      completedSyllabusItems: List<String>.from(map['completedSyllabusItems'] ?? []),
      lastAccessed: (map['lastAccessed'] as Timestamp?)?.toDate(),
    );
  }
}
