class Topic {
  final String id;
  final String name;
  final String category;
  final DateTime cachedAt;

  Topic({
    required this.id,
    required this.name,
    this.category = 'General',
    DateTime? cachedAt,
  }) : this.cachedAt = cachedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'cached_at': cachedAt.toIso8601String(),
    };
  }

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      cachedAt: map['cached_at'] != null
          ? DateTime.tryParse(map['cached_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Topic(id: "$id", name: "$name", category: "$category")';
  }
}
