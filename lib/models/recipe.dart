class Recipe {
  final int? id;
  final String name;
  final String? link;
  final String createdAt;
  final bool isArchived;

  // Populated from queries, not stored in model table directly
  final int ingredientCount;
  final int stepCount;

  Recipe({
    this.id,
    required this.name,
    this.link,
    required this.createdAt,
    this.isArchived = false,
    this.ingredientCount = 0,
    this.stepCount = 0,
  });

  bool get isLink => link != null && link!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'link': link,
      'created_at': createdAt,
      'is_archived': isArchived ? 1 : 0,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as int?,
      name: map['name'] as String,
      link: map['link'] as String?,
      createdAt: map['created_at'] as String,
      isArchived: (map['is_archived'] as int) == 1,
      ingredientCount: map['ingredient_count'] as int? ?? 0,
      stepCount: map['step_count'] as int? ?? 0,
    );
  }

  Recipe copyWith({
    int? id,
    String? name,
    String? link,
    String? createdAt,
    bool? isArchived,
    int? ingredientCount,
    int? stepCount,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      link: link ?? this.link,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
      ingredientCount: ingredientCount ?? this.ingredientCount,
      stepCount: stepCount ?? this.stepCount,
    );
  }
}
