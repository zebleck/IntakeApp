class DailyFocus {
  final int? id;
  final String date;
  final int rating;

  DailyFocus({
    this.id,
    required this.date,
    required this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'rating': rating,
    };
  }

  factory DailyFocus.fromMap(Map<String, dynamic> map) {
    return DailyFocus(
      id: map['id'] as int?,
      date: map['date'] as String,
      rating: map['rating'] as int,
    );
  }

  DailyFocus copyWith({
    int? id,
    String? date,
    int? rating,
  }) {
    return DailyFocus(
      id: id ?? this.id,
      date: date ?? this.date,
      rating: rating ?? this.rating,
    );
  }
}
