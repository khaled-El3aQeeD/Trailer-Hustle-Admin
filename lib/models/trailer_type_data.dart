class TrailerTypeData {
  final int id;
  final String title;
  final String manufacturer;
  final String model;
  final double? rating;
  final bool isPublished;
  final int? addedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const TrailerTypeData({
    required this.id,
    required this.title,
    required this.manufacturer,
    required this.model,
    required this.rating,
    required this.isPublished,
    required this.addedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  TrailerTypeData copyWith({
    int? id,
    String? title,
    String? manufacturer,
    String? model,
    double? rating,
    bool? isPublished,
    int? addedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return TrailerTypeData(
      id: id ?? this.id,
      title: title ?? this.title,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      rating: rating ?? this.rating,
      isPublished: isPublished ?? this.isPublished,
      addedBy: addedBy ?? this.addedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static int _parseInt(dynamic v, {required int fallback}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static int? _parseNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _parseNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    if (v is DateTime) return v.toUtc();
    return DateTime.tryParse(v.toString())?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static DateTime? _parseNullableDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v.toUtc();
    return DateTime.tryParse(v.toString())?.toUtc();
  }

  factory TrailerTypeData.fromJson(Map<String, dynamic> json) {
    // Keep this resilient: DB column naming can vary (snake_case vs camelCase).
    final manufacturer = (json['manufacturer'] ?? json['make'] ?? '').toString();
    final model = (json['model'] ?? '').toString();
    final rating = _parseNullableDouble(json['rating'] ?? json['trailer_rating'] ?? json['trailerRating']);

    return TrailerTypeData(
      id: _parseInt(json['id'], fallback: 0),
      title: (json['title'] ?? '').toString(),
      manufacturer: manufacturer,
      model: model,
      rating: rating,
      isPublished: _parseInt(json['is_published'], fallback: 0) == 1,
      addedBy: _parseNullableInt(json['added_by']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      deletedAt: _parseNullableDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'manufacturer': manufacturer,
      'model': model,
      'rating': rating,
      'is_published': isPublished ? 1 : 0,
      'added_by': addedBy,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
    };
  }
}
