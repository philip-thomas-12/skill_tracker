class Skill {
  final String id;
  final String userId;
  final String name;
  final String category;
  final double targetHours;
  final double completedHours;

  Skill({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.targetHours,
    this.completedHours = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'category': category,
      'targetHours': targetHours,
      'completedHours': completedHours,
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map, String documentId) {
    return Skill(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      targetHours: (map['targetHours'] ?? 0).toDouble(),
      completedHours: (map['completedHours'] ?? 0).toDouble(),
    );
  }
}
