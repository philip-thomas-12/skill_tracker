
class LearningSession {
  final String id;
  final String skillId;
  final String userId;
  final DateTime date;
  final double durationInHours;
  final String? notes;

  LearningSession({
    required this.id,
    required this.skillId,
    required this.userId,
    required this.date,
    required this.durationInHours,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'skillId': skillId,
      'userId': userId,
      'date': date.toIso8601String(),
      'durationInHours': durationInHours,
      'notes': notes,
    };
  }

  factory LearningSession.fromMap(Map<String, dynamic> map, String documentId) {
    return LearningSession(
      id: documentId,
      skillId: map['skillId'] ?? '',
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date']),
      durationInHours: (map['durationInHours'] ?? 0).toDouble(),
      notes: map['notes'],
    );
  }
}
