class Word {
  final int? id;
  final String english;
  final String turkish;
  final String phonetic;
  final String syncStatus; // 'synced' or 'pending'
  final DateTime createdAt;

  Word({
    this.id,
    required this.english,
    required this.turkish,
    this.phonetic = '',
    this.syncStatus = 'synced',
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  // Create a copy with some overridden fields
  Word copyWith({
    int? id,
    String? english,
    String? turkish,
    String? phonetic,
    String? syncStatus,
    DateTime? createdAt,
  }) {
    return Word(
      id: id ?? this.id,
      english: english ?? this.english,
      turkish: turkish ?? this.turkish,
      phonetic: phonetic ?? this.phonetic,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert to Map for Database insertion/update
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'english': english.trim(),
      'turkish': turkish.trim(),
      'phonetic': phonetic.trim(),
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create Word from Map from SQLite
  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'] as int?,
      english: map['english'] as String? ?? '',
      turkish: map['turkish'] as String? ?? '',
      phonetic: map['phonetic'] as String? ?? '',
      syncStatus: map['sync_status'] as String? ?? 'synced',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Word(id: $id, english: "$english", turkish: "$turkish", phonetic: "$phonetic", syncStatus: "$syncStatus")';
  }
}
