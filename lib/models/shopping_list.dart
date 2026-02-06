class ShoppingList {
  final int? id;
  final String name;
  final String createdAt;
  final bool isArchived;

  // Populated from queries, not stored in model table directly
  final int itemCount;
  final int checkedCount;

  ShoppingList({
    this.id,
    required this.name,
    required this.createdAt,
    this.isArchived = false,
    this.itemCount = 0,
    this.checkedCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_at': createdAt,
      'is_archived': isArchived ? 1 : 0,
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map) {
    return ShoppingList(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: map['created_at'] as String,
      isArchived: (map['is_archived'] as int) == 1,
      itemCount: map['item_count'] as int? ?? 0,
      checkedCount: map['checked_count'] as int? ?? 0,
    );
  }

  ShoppingList copyWith({
    int? id,
    String? name,
    String? createdAt,
    bool? isArchived,
    int? itemCount,
    int? checkedCount,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
      itemCount: itemCount ?? this.itemCount,
      checkedCount: checkedCount ?? this.checkedCount,
    );
  }
}
