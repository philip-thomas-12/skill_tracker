class LearningMaterial {
  String type; // 'video', 'article', 'quiz', 'pdf', 'doc'
  String title;
  String url;
  String content;

  LearningMaterial({
    required this.type,
    required this.title,
    required this.url,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'url': url,
      'content': content,
    };
  }

  factory LearningMaterial.fromMap(Map<String, dynamic> map) {
    return LearningMaterial(
      type: map['type'] ?? 'article',
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      content: map['content'] ?? '',
    );
  }
}

class SyllabusItem {
  String title;
  String description;
  String? materialUrl;
  String? materialType; // 'video', 'pdf', 'doc', etc.

  SyllabusItem({
    required this.title,
    required this.description,
    this.materialUrl,
    this.materialType,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'materialUrl': materialUrl,
      'materialType': materialType,
    };
  }

  factory SyllabusItem.fromMap(Map<String, dynamic> map) {
    return SyllabusItem(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      materialUrl: map['materialUrl'],
      materialType: map['materialType'],
    );
  }
}

class Pathway {
  String id;
  String title;
  String description;
  String category;
  String difficulty; // 'Beginner', 'Intermediate', 'Advanced'
  List<LearningMaterial> materials;
  List<SyllabusItem> syllabus;

  Pathway({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.materials,
    required this.syllabus,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'materials': materials.map((m) => m.toMap()).toList(),
      'syllabus': syllabus.map((s) => s.toMap()).toList(),
    };
  }

  factory Pathway.fromMap(Map<String, dynamic> map, String id) {
    return Pathway(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      difficulty: map['difficulty'] ?? 'Beginner',
      materials: (map['materials'] as List<dynamic>?)
              ?.map((item) => LearningMaterial.fromMap(item))
              .toList() ??
          [],
      syllabus: (map['syllabus'] as List<dynamic>?)
              ?.map((item) => SyllabusItem.fromMap(item))
              .toList() ??
          [],
    );
  }
}
