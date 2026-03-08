class TrailerRatingData {
  final int id;
  final int trailerId;
  final int businessId;
  final String? comment;
  final double? ratingAverage;
  final int overallQuality;
  final int durability;
  final int easeOfUse;
  final int factoryFeature;
  final int finishQuality;
  final int maintenance;
  final int safety;
  final int towing;
  final int valueOfMoney;
  final int additional;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TrailerRatingData({
    required this.id,
    required this.trailerId,
    required this.businessId,
    required this.comment,
    required this.ratingAverage,
    required this.overallQuality,
    required this.durability,
    required this.easeOfUse,
    required this.factoryFeature,
    required this.finishQuality,
    required this.maintenance,
    required this.safety,
    required this.towing,
    required this.valueOfMoney,
    required this.additional,
    required this.createdAt,
    required this.updatedAt,
  });

  TrailerRatingData copyWith({
    int? id,
    int? trailerId,
    int? businessId,
    String? comment,
    double? ratingAverage,
    int? overallQuality,
    int? durability,
    int? easeOfUse,
    int? factoryFeature,
    int? finishQuality,
    int? maintenance,
    int? safety,
    int? towing,
    int? valueOfMoney,
    int? additional,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrailerRatingData(
      id: id ?? this.id,
      trailerId: trailerId ?? this.trailerId,
      businessId: businessId ?? this.businessId,
      comment: comment ?? this.comment,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      overallQuality: overallQuality ?? this.overallQuality,
      durability: durability ?? this.durability,
      easeOfUse: easeOfUse ?? this.easeOfUse,
      factoryFeature: factoryFeature ?? this.factoryFeature,
      finishQuality: finishQuality ?? this.finishQuality,
      maintenance: maintenance ?? this.maintenance,
      safety: safety ?? this.safety,
      towing: towing ?? this.towing,
      valueOfMoney: valueOfMoney ?? this.valueOfMoney,
      additional: additional ?? this.additional,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    if (v is DateTime) return v.toUtc();
    return DateTime.tryParse(v.toString())?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  static int _parseInt(dynamic v, {required int fallback}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static double? _parseNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory TrailerRatingData.fromJson(Map<String, dynamic> json) {
    T? pick<T>(List<String> keys) {
      for (final k in keys) {
        if (json.containsKey(k)) return json[k] as T?;
      }
      return null;
    }

    return TrailerRatingData(
      id: _parseInt(json['id'], fallback: 0),
      trailerId: _parseInt(pick<dynamic>(['trailerId', 'trailer_id', 'trailerid']), fallback: 0),
      businessId: _parseInt(pick<dynamic>(['businessId', 'business_id', 'businessid']), fallback: 0),
      comment: pick<dynamic>(['comment', 'review', 'notes'])?.toString(),
      ratingAverage: _parseNullableDouble(pick<dynamic>(['ratingAverage', 'rating_average', 'ratingAvg', 'avgRating'])),
      overallQuality: _parseInt(pick<dynamic>(['overallQuality', 'overall_quality', 'overall'] ), fallback: 0),
      durability: _parseInt(json['durability'], fallback: 0),
      easeOfUse: _parseInt(pick<dynamic>(['easeOfUse', 'ease_of_use']), fallback: 0),
      factoryFeature: _parseInt(pick<dynamic>(['factoryFeature', 'factory_feature']), fallback: 0),
      finishQuality: _parseInt(pick<dynamic>(['finishQuality', 'finish_quality']), fallback: 0),
      maintenance: _parseInt(pick<dynamic>(['maintenance']), fallback: 0),
      safety: _parseInt(pick<dynamic>(['safety']), fallback: 0),
      towing: _parseInt(pick<dynamic>(['towing']), fallback: 0),
      valueOfMoney: _parseInt(pick<dynamic>(['valueOfMoney', 'value_of_money']), fallback: 0),
      additional: _parseInt(json['additional'], fallback: 0),
      createdAt: _parseDate(pick<dynamic>(['createdAt', 'created_at'])),
      updatedAt: _parseDate(pick<dynamic>(['updatedAt', 'updated_at'])),
    );
  }
}
