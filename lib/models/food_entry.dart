class FoodEntry {
  final int? id;
  final String date;
  final String name;
  final double? quantity;
  final String? unit;
  final String loggedAt;
  final int? recipeId;
  final String? recipeName;
  final String? comment;

  FoodEntry({
    this.id,
    required this.date,
    required this.name,
    this.quantity,
    this.unit,
    required this.loggedAt,
    this.recipeId,
    this.recipeName,
    this.comment,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'logged_at': loggedAt,
      'recipe_id': recipeId,
      'comment': comment,
    };
  }

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      name: map['name'] as String,
      quantity: map['quantity'] as double?,
      unit: map['unit'] as String?,
      loggedAt: map['logged_at'] as String,
      recipeId: map['recipe_id'] as int?,
      recipeName: map['recipe_name'] as String?,
      comment: map['comment'] as String?,
    );
  }

  FoodEntry copyWith({
    int? id,
    String? date,
    String? name,
    double? quantity,
    String? unit,
    String? loggedAt,
    int? recipeId,
    String? recipeName,
    String? comment,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      loggedAt: loggedAt ?? this.loggedAt,
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      comment: comment ?? this.comment,
    );
  }
}
