class BrandData {
  final int id;
  final String title;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const BrandData({
    required this.id,
    required this.title,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  BrandData copyWith({
    int? id,
    String? title,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return BrandData(
      id: id ?? this.id,
      title: title ?? this.title,
      isPublished: isPublished ?? this.isPublished,
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

  static bool _parseBool(dynamic v, {required bool fallback}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is num) return v.toInt() == 1;
    final s = v.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
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

  factory BrandData.fromJson(Map<String, dynamic> json) {
    // Keep this resilient: DB column naming can vary (snake_case vs camelCase).
    final publishedRaw = json['is_published'] ?? json['isPublished'] ?? json['is_published '] ?? json['isPublished '];
    return BrandData(
      id: _parseInt(json['id'], fallback: 0),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      isPublished: _parseBool(publishedRaw, fallback: false),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
      deletedAt: _parseNullableDate(json['deletedAt'] ?? json['deleted_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'is_published': isPublished ? 1 : 0,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
    };
  }
}
