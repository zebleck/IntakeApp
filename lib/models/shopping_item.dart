class ShoppingItem {
  final int? id;
  final int listId;
  final String name;
  final double? quantity;
  final String? unit;
  final bool isChecked;
  final int sortOrder;

  ShoppingItem({
    this.id,
    required this.listId,
    required this.name,
    this.quantity,
    this.unit,
    this.isChecked = false,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'list_id': listId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'is_checked': isChecked ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] as int?,
      listId: map['list_id'] as int,
      name: map['name'] as String,
      quantity: map['quantity'] as double?,
      unit: map['unit'] as String?,
      isChecked: (map['is_checked'] as int) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  ShoppingItem copyWith({
    int? id,
    int? listId,
    String? name,
    double? quantity,
    String? unit,
    bool? isChecked,
    int? sortOrder,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isChecked: isChecked ?? this.isChecked,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
