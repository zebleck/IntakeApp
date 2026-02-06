class RecipeStep {
  final int? id;
  final int recipeId;
  final int stepNumber;
  final String instruction;

  RecipeStep({
    this.id,
    required this.recipeId,
    required this.stepNumber,
    required this.instruction,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'recipe_id': recipeId,
      'step_number': stepNumber,
      'instruction': instruction,
    };
  }

  factory RecipeStep.fromMap(Map<String, dynamic> map) {
    return RecipeStep(
      id: map['id'] as int?,
      recipeId: map['recipe_id'] as int,
      stepNumber: map['step_number'] as int,
      instruction: map['instruction'] as String,
    );
  }

  RecipeStep copyWith({
    int? id,
    int? recipeId,
    int? stepNumber,
    String? instruction,
  }) {
    return RecipeStep(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      stepNumber: stepNumber ?? this.stepNumber,
      instruction: instruction ?? this.instruction,
    );
  }
}
