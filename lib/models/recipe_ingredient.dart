class RecipeIngredient {
  final int? id;
  final int recipeId;
  final String name;
  final double? quantity;
  final String? unit;
  final int sortOrder;

  RecipeIngredient({
    this.id,
    required this.recipeId,
    required this.name,
    this.quantity,
    this.unit,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'recipe_id': recipeId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'sort_order': sortOrder,
    };
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      id: map['id'] as int?,
      recipeId: map['recipe_id'] as int,
      name: map['name'] as String,
      quantity: map['quantity'] as double?,
      unit: map['unit'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  RecipeIngredient copyWith({
    int? id,
    int? recipeId,
    String? name,
    double? quantity,
    String? unit,
    int? sortOrder,
  }) {
    return RecipeIngredient(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
